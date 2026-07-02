const std = @import("std");
pub const Archetype = @import("archetype.zig");
pub const World = @import("World.zig");

/// a unique id which stores some useful info about the object
pub const ObjectId = packed struct(u64) {
    /// the key of the bundle corresponding to this object
    key: u16,
    /// the generation number of this object within its archetype
    generation: u16,
    /// the index of this object within its archetype
    index: u32,
};

pub fn typeHash(comptime T: type) usize {
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
    try std.testing.expect(typeHash(u32) == typeHash(u32));
    try std.testing.expect(typeHash(u32) != typeHash(f32));
    // struct tests
    const Dummy = struct { x: u32 };
    try std.testing.expect(typeHash(u32) != typeHash(struct { x: u32 }));
    try std.testing.expect(typeHash(struct { x: u32 }) != typeHash(struct { x: u32 }));
    try std.testing.expect(typeHash(Dummy) != typeHash(struct { x: u32 }));
    try std.testing.expect(typeHash(Dummy) == typeHash(Dummy));

    // ZST tests
    try std.testing.expect(typeHash(void) == typeHash(void));
    try std.testing.expect(typeHash(void) != typeHash(struct {}));

    // alias tests
    const Name = []const u8;
    try std.testing.expect(typeHash(Name) == typeHash([]const u8));

    // generic type tests
    try std.testing.expect(typeHash(std.ArrayList(u32)) == typeHash(std.ArrayList(u32)));
}

test "object" {
    _ = Archetype;
    _ = World;
}
