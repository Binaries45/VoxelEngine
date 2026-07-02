//! an archetype, storing all objects with the same structure

const std = @import("std");
const object = @import("object.zig");
const ObjectId = object.ObjectId;

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

        /// initialize a new Archetype with the given key
        pub fn init(key: u16) Arch {
            return .{ .key = key };
        }

        pub fn deinit(self: *Arch, alloc: std.mem.Allocator) void {
            self.data.deinit(alloc);
            self.generations.deinit(alloc);
            self.freed.deinit(alloc);
            self.recycle.deinit(alloc);
        }

        fn toStorage(value: T) ST {
            return if (has_fields) value else .{};
        }

        fn fromStorage(value: ST) T {
            return if (has_fields) value else .{};
        }

        /// create a new object and add it to `self` returning its id
        pub fn new(self: *Arch, alloc: std.mem.Allocator, value: T) !ObjectId {
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
                return ObjectId{
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

        fn validate(self: *const Arch, id: ObjectId, comptime fn_name: []const u8) void {
            const freed = &self.freed;
            const generations = &self.generations;

            if (id.key != self.key) {
                @panic(fn_name ++ "() called with object not from this archetype");
            }

            if (id.generation != generations.items[id.index]) {
                @panic(fn_name ++ "() called with an object that has already been freed");
            }

            if (freed.isSet(id.index)) {
                @panic(fn_name ++ "() called with an object that has already been freed");
            }
        }

        /// get the value of a specific field of the object with the given id
        pub fn get(self: *const Arch, id: ObjectId, comptime field: std.meta.FieldEnum(T)) @FieldType(T, @tagName(field)) {
            const data = &self.data;
            self.validate(id, "get");
            return data.items(field)[id.index];
        }

        /// get the value of the object with the given id
        pub fn getValue(self: *const Arch, id: ObjectId) T {
            const data = &self.data;
            self.validate(id, "getValue");
            return data.get(id.index);
        }

        /// free an object, opening its slot for new data
        pub fn free(self: *Arch, alloc: std.mem.Allocator, id: ObjectId) !void {
            self.validate(id, "remove");
            const freed = &self.freed;
            const recycle = &self.recycle;

            try recycle.append(alloc, id.index);
            freed.set(id.index);
        }
    };
}

/// a vtable for helping handle type erased archetypes
pub const ArchetypeVTable = struct {
    ptr: *anyopaque,
    vtable: *const VTable,
};

const VTable = struct {
    deinit: *const fn(a: *anyopaque, alloc: std.mem.Allocator) void,
    free: *const fn(a: *anyopaque, alloc: std.mem.Allocator, id: ObjectId) void,
    validate: *const fn(a: *anyopaque, id: ObjectId) void,
    get: *const fn(a: *anyopaque, id: ObjectId, field: u32, out: *anyopaque) void,
    getValue: *const fn(a: *anyopaque, id: ObjectId, out: *anyopaque) void,
};

fn generateImpl(comptime T: type) *const VTable {
    return &struct{
        const vt = VTable {
            .deinit = struct {
                pub fn deinit(a: *anyopaque, alloc: std.mem.Allocator) void {
                    const arch: *Archetype(T) = @ptrCast(@alignCast(a));
                    arch.deinit(alloc);
                    alloc.destroy(arch);
                }
            }.deinit,
            .free = struct {
                pub fn free(a: *anyopaque, alloc: std.mem.Allocator, id: ObjectId) void {
                    const arch: *Archetype(T) = @ptrCast(@alignCast(a));
                    arch.free(alloc, id) catch
                        @panic("failed free for archetype containing" ++ @typeName(T));
                }
            }.free,
            .validate = struct {
                pub fn validate(a: *anyopaque, id: ObjectId) void {
                    const arch: *Archetype(T) = @ptrCast(@alignCast(a));
                    arch.validate(id, "VTable.validate");
                }
            }.validate,
            .get = struct {
                pub fn get(a: *anyopaque, id: ObjectId, field: u32, out: *anyopaque) void {
                    const arch: *Archetype(T) = @ptrCast(@alignCast(a));
                    const fields = @typeInfo(T).@"struct".fields;
                    if(comptime fields.len == 0) @compileError("cannot get field of struct with no fields");
                    switch(field) {
                        inline 0...fields.len - 1 => |i| {
                            const f: std.meta.FieldEnum(T) = @enumFromInt(i);
                            const FT = @FieldType(T, @tagName(f));
                            const res: *FT = @ptrCast(@alignCast(out));
                            res.* = arch.get(id, f);
                        },
                        else => unreachable,
                    }
                }
            }.get,
            .getValue = struct {
                pub fn getValue(a: *anyopaque, id: ObjectId, out: *anyopaque) void {
                    const arch: *Archetype(T) = @ptrCast(@alignCast(a));
                    const res: *T = @ptrCast(@alignCast(out));
                    res.* = arch.getValue(id);
                }
            }.getValue,
        };
    }.vt;
}

/// generate an archetype vtable from the given type and pointer
pub fn generateVTable(comptime T: type, ptr: *anyopaque) ArchetypeVTable {
    return .{
        .ptr = ptr,
        .vtable = generateImpl(T),
    };
}

test "new data" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var arch: Archetype(struct {
        name: []const u8,
        age: u8,
    }) = .init(0);

    defer arch.deinit(alloc);

    const joskue = try arch.new(alloc, .{
        .name = "Josuke Higashikata",
        .age = 19,
    });

    try std.testing.expect(std.mem.eql(u8, arch.get(joskue, .name), "Josuke Higashikata"));
    try std.testing.expect(arch.get(joskue, .age) == 19);
}

test "freeing data" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const Person = struct {
        name: []const u8,
        age: u8,
    };

    var arch: Archetype(Person) = .init(0);
    defer arch.deinit(alloc);

    const keicho = try arch.new(alloc, .{
        .name = "Keicho Nijimura",
        .age = 18,
    });

    try std.testing.expect(keicho.generation == 0);    
    try std.testing.expect(keicho.index == 0);

    try arch.free(alloc, keicho);

    const okuyasu = try arch.new(alloc, .{
        .name = "Okuyasu Nijimura",
        .age = 16,
    });

    try std.testing.expect(okuyasu.generation == 1);    
    try std.testing.expect(okuyasu.index == 0);
}

test "getting fields" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const Person = struct {
        name: []const u8,
        age: u8,
    };

    var arch: Archetype(Person) = .init(0);
    defer arch.deinit(alloc);

    const hazamada = try arch.new(alloc, .{
        .name = "Toshikazu Hazamada",
        .age = 17,
    });

    const name = arch.get(hazamada, .name);    
    const age = arch.get(hazamada, .age);

    try std.testing.expect(std.mem.eql(u8, name, "Toshikazu Hazamada"));
    try std.testing.expect(age == 17);    
}

test "getting data" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const Person = struct {
        name: []const u8,
        age: u8,
    };

    var arch: Archetype(Person) = .init(0);
    defer arch.deinit(alloc);

    const tonio = try arch.new(alloc, .{
        .name = "Tonio Trussardi",
        .age = 29,
    });

    const val = arch.getValue(tonio);
    try std.testing.expect(std.mem.eql(u8, val.name, "Tonio Trussardi"));
    try std.testing.expect(val.age == 29);  
}
