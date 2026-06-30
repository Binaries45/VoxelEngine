// note : the goal with archetype storage and the object function is to store
//        all similar types in an archetype table as a struct of arrays,
//        we're gonna have to do some wacky comptime stuff to construct this
//        storage and create these types, also archetypes will have to be
//        type-erased so that we can then store all archetypes in our world

const std = @import("std");
pub const Archetype = @import("archetype.zig");
pub const World = @import("World.zig");

/// a unique id which stores some useful info about the object
pub const ObjectID = packed struct(u64) {
    _rem: u64 = 0,
};

pub fn typeId(comptime T: type) usize {
    return comptime blk: {
        const name = @typeName(T);
        var h: u64 = 14695981039346656037;
        for (name) |c| {
            h ^= c;
            h *%= 1099511628211;
        }
        break :blk h;
    };
}

test "type ids" {
    try std.testing.expect(typeId(u32) == typeId(u32));
    try std.testing.expect(typeId(u32) != typeId(f32));

    // struct tests
    const Dummy = struct { x: u32 };
    try std.testing.expect(typeId(u32) != typeId(struct { x: u32 }));
    try std.testing.expect(typeId(struct { x: u32 }) != typeId(struct { x: u32 }));
    try std.testing.expect(typeId(Dummy) != typeId(struct { x: u32 }));
    try std.testing.expect(typeId(Dummy) == typeId(Dummy));

    // ZST tests
    try std.testing.expect(typeId(void) == typeId(void));
    try std.testing.expect(typeId(void) != typeId(struct {}));

    // alias tests
    const Name = []const u8;
    try std.testing.expect(typeId(Name) == typeId([]const u8));

    // generic type tests
    try std.testing.expect(typeId(std.ArrayList(u32)) == typeId(std.ArrayList(u32)));
}

test "object" {
    _ = Archetype;
    _ = World;
}
