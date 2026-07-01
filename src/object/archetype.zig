//! an archetype, storing all objects with the same structure

const std = @import("std");
const object = @import("object.zig");
const ObjectID = object.ObjectID;

// given the type of some component bundle,
// construct an archetype storing the component data
pub fn Archetype(comptime T: type) type {
    const has_fields = @typeInfo(T).@"struct".fields.len > 0;
    const ST = if (has_fields) T else struct { _pad: u0 = 0 };

    return struct {
        /// the archetype key
        key: u16,
        /// all component data
        data: std.MultiArrayList(ST) = .empty,
        /// the current generation of `data[i]`.
        /// when `data[i]` is freed and then reused, this value is incremented
        generations: std.ArrayList(u16) = .empty,
        /// tracks whether data[i] is free or not
        freed: std.DynamicBitSetUnmanaged = .{},
        /// tracks all indices in `data` which have been freed
        recycle: std.ArrayList(u32) = .empty,

        // todo : track pending deletions, as well as all updated fields of `data`

        const Arch = @This();

        pub fn deinit(self: *Arch, alloc: std.mem.Allocator) void {
            self.data.deinit(alloc);
            self.generations.deinit(alloc);
            self.freed.deinit(alloc);
        }

        fn toStorage(value: T) ST {
            return if (has_fields) value else .{};
        }

        fn fromStorage(value: ST) T {
            return if (has_fields) value else .{};
        }

        /// create a new object and add it to `self` returning its id
        pub fn new(self: *Arch, alloc: std.mem.Allocator, value: T) !ObjectID {
            const data = &self.data;
            const generations = &self.generations;
            const freed = &self.freed;
            const recycle = &self.recycle;
            
            // recycle old indices if possible
            if (recycle.pop()) |i| {
                freed.unset(i);
                // todo : remove from pending deletion when we track it
                const gen = generations.items[i] + 1;
                generations.items[i] = gen;
                data.set(i, toStorage(value));
                return ObjectID{
                    .generation = gen,
                    .index = i,
                    .key = self.key,
                };
            }
            
            try data.ensureUnusedCapacity(alloc, 1);
            try freed.resize(alloc, data.capacity, false);
            try generations.ensureUnusedCapacity(alloc, 1);
            // todo : resize pending deletions in the same way as freed
            
            const index = data.len;
            data.appendAssumeCapacity(toStorage(value));
            freed.unset(index);
            generations.appendAssumeCapacity(0);

            return .{
                .key = self.key,
                .generation = 0,
                .index = @intCast(index),
            };
        }

        fn validate(self: *const Arch, id: ObjectID, comptime fn_name: []const u8) ObjectID {
            const freed = &self.freed;
            const generations = &self.generations;

            if(id.key != self.key) {
                @panic(fn_name ++ "() called with object not from this archetype");
            }

            if(id.generation != generations.items[id.index]) {
                @panic(fn_name ++ "() called with an object that has already been freed");
            }
            
            if(freed.isSet(id.index)) {
                @panic(fn_name ++ "() called with an object that has already been freed");
            }

            return id;
        }

        /// get the value of a specific field of the object with the given id
        pub fn get(self: *const Arch, id: ObjectID, comptime field: std.meta.FieldEnum(T)) @FieldType(T, @tagName(field)) {
            const data = &self.data;
            const valid = self.validate(id, "get");
            return data.items(field)[valid.index];
        }

        /// get the value of the object with the given id
        pub fn getValue(self: *const Arch, id: ObjectID) T {
            const data = &self.data;
            const valid = self.validate(id, "getValue");
            return data.get(valid.index);
        }
    };
}

test "archetypes" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var arch: Archetype(struct {
        name: []const u8,
        age: u8,
    }) = .{.key = 0};

    defer arch.deinit(alloc);

    const jojo = try arch.new(alloc, .{
        .name = "Josuke Higashikata",
        .age = 19,
    });

    try std.testing.expect(std.mem.eql(u8, arch.get(jojo, .name), "Josuke Higashikata"));
    try std.testing.expect(arch.get(jojo, .age) == 19);
}
