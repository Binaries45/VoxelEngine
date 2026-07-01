//! the world in which our entities live, responsible for handling
//! all component & resource related data

const std = @import("std");
const archetype = @import("archetype.zig");
const ObjectId = @import("object.zig").ObjectID;
const typeId = @import("object.zig").typeId; 

const World = @This();

alloc: std.mem.Allocator,

/// the registry of all unique archetype types, containing a mapping of each archetype hash to its index in `archetypes`
registry: Registry,

/// todo : a list of all archetypes in use by the world
archetypes: std.ArrayList(*anyopaque),

/// a registry mapping bundle type hashes to archetype storage keys
pub const Registry = struct {
    map: std.AutoArrayHashMapUnmanaged(usize, u16) = .{},
    next: u16 = 0,

    pub fn getOrCreate(r: *Registry, alloc: std.mem.Allocator, hash: usize) !u16 {
        if (r.map.get(hash)) |id| return id;

        const key = r.next;
        r.next += 1;

        try r.map.putNoClobber(alloc, hash, key);
        return key;
    }
};


/// generate a hash of the given bundle type by combining all type hashes of its fields
pub fn bundleHash(comptime B: type) usize {
    return comptime blk: {
        if (@typeInfo(B) != .@"struct") @compileError("expected struct type");
        const info = @typeInfo(B).@"struct";

        var seen: [info.fields.len]type = undefined;
        var count: usize = 0;
        var k: usize = 0;

        for (info.fields, 0..) |f, i| {
            for (seen[0..count]) |s| if (s == f.type)
                    @compileError("Bundle cannot have multiple fields of the same type");

            seen[count] = f.type;
            count += 1;

            for (info.fields[0..i]) |prev| {
                if (typeId(f.type) == typeId(prev.type))
                    @compileError(
                        "Hash collision between "
                        ++ @typeName(f.type)
                        ++ " and "
                        ++ @typeName(prev.type)
                    );
            }

            k ^= typeId(f.type);
        }
        break :blk k;
    };
}

/// spawn an entity from the given bundle, returning its ID
pub fn spawn(w: *World, bundle: anytype) !ObjectId {
    const hash = bundleHash(@TypeOf(bundle));
    const key = try w.registry.getOrCreate(w.alloc, hash);

    _ = key;

    // todo : add data to the correct archetype
    // todo : get generation and index
    // todo : construct and return the id
    return error.todo;
}

// todo : despawn an object

test "archetype keys" {
    const a = .{
        @as(u8, 42),
        @as(f32, 3.14),
    };

    const b = .{
        @as(f32, 2.718),
        @as(u8, 21),
    };

    const c = .{
        @as([]const u8, "hello"),
        @as(u8, 100),
    };

    const key_a = bundleHash(@TypeOf(a));
    const key_b = bundleHash(@TypeOf(b));
    const key_c = bundleHash(@TypeOf(c));

    try std.testing.expect(key_a == typeId(u8) ^ typeId(f32));
    try std.testing.expect(key_a == key_b);
    try std.testing.expect(key_a != key_c);
}
