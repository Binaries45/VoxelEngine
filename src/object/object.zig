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

/// a bit set acting as a mask of component ids
pub const TypeIdBitset = u128;

var next_id: u32 = 0;

/// returns the component id corresponding to a bit to be set in the TypeId
pub fn componentId(comptime T: type) u32 {
    const S = struct {
        const t = T;
        var id: ?u32 = null;
    };
    if (S.id) |id| return id;
    const id = next_id;
    next_id += 1;
    S.id = id;
    return id;
}

/// returns a full mask of the components making up T
pub fn typeId(comptime T: type) TypeIdBitset {
    if (@typeInfo(T) != .@"struct") @compileError("expected struct type");
    const info = @typeInfo(T).@"struct";
    var mask: TypeIdBitset = 0;
    inline for (info.fields) |f| {
        const id = componentId(f.type);
        mask |= @as(TypeIdBitset, 1) << @as(u7, @intCast(id));
    }

    return mask;
}

test "component ids" {
    try std.testing.expect(componentId(u32) == componentId(u32));
    try std.testing.expect(componentId(u32) != componentId(f32));

    // struct tests
    const Dummy = struct { x: u32 };
    try std.testing.expect(componentId(u32) != componentId(struct { x: u32 }));
    try std.testing.expect(componentId(struct { x: u32 }) != componentId(struct { x: u32 }));
    try std.testing.expect(componentId(Dummy) != componentId(struct { x: u32 }));
    try std.testing.expect(componentId(Dummy) == componentId(Dummy));

    // ZST tests
    try std.testing.expect(componentId(void) == componentId(void));
    try std.testing.expect(componentId(void) != componentId(struct {}));

    // alias tests
    const Name = []const u8;
    try std.testing.expect(componentId(Name) == componentId([]const u8));

    // generic type tests
    try std.testing.expect(componentId(std.ArrayList(u32)) == componentId(std.ArrayList(u32)));
}

test "object" {
    _ = Archetype;
    _ = World;
}
