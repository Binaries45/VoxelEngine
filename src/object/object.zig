// note : the goal with archetype storage and the object function is to store
//        all similar types in an archetype table as a struct of arrays,
//        we're gonna have to do some wacky comptime stuff to construct this
//        storage and create these types, also archetypes will have to be
//        type-erased so that we can then store all archetypes in our world

const std = @import("std");
pub const Archetype = @import("Archetype.zig");

pub fn Object(comptime T: type) type {
    // todo : implement this once we know how archetypes will be stored
    _ = T;
    return struct {};
}

/// return a unique usize for the given type
pub fn typeId(comptime T: type) usize {
    return @intFromPtr(&struct {
        pub const t: type = T;
        pub const id: u8 = 0;
    }.id);
}

test "object" {
    _ = Archetype;
}

test "type ids" {
    try std.testing.expect(typeId(u32) == typeId(u32));
    try std.testing.expect(typeId(u32) != typeId(f32));

    // struct tests
    const Dummy = struct { x: u32 };
    try std.testing.expect(typeId(u32) != typeId(struct{ x: u32 }));
    try std.testing.expect(typeId(struct{ x: u32 }) != typeId(struct{ x: u32 }));
    try std.testing.expect(typeId(Dummy) != typeId(struct{ x: u32 }));
    try std.testing.expect(typeId(Dummy) == typeId(Dummy));

    // ZST tests
    try std.testing.expect(typeId(void) == typeId(void));
    try std.testing.expect(typeId(void) != typeId(struct{}));

    // alias tests
    const Name = []const u8;
    try std.testing.expect(typeId(Name) == typeId([]const u8));
}