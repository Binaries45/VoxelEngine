const std = @import("std");
pub const Archetype = @import("archetype.zig");
pub const World = @import("World.zig");
pub const table = @import("storage/table.zig");
pub const Column = @import("storage/Column.zig");

/// a unique id which stores some useful info about the object
pub const Entity = packed struct(u64) {
    /// the key of the bundle corresponding to this object
    key: u16,
    /// the generation number of this object within its archetype
    generation: u16,
    /// the index of this object within its archetype
    index: u32,
};

/// a bit set acting as a mask of component ids
pub const TypeIdBitset = u128;
pub const ComponentId = u32;

// TODO : component info for runtime component creation without relying on types
//        (store id, size, align, and maybe a free/drop fn)

var next_id: u32 = 0;

/// returns the component id corresponding to a bit to be set in the TypeId
pub fn componentIdOf(comptime T: type) ComponentId {
    const S = struct {
        const t = T;
        var id: ?ComponentId = null;
    };
    if (S.id) |id| return id;
    const id = next_id;
    if (next_id > 128) @panic("too many components!");
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
        const id = componentIdOf(f.type);
        mask |= @as(TypeIdBitset, 1) << @as(u7, @intCast(id));
    }

    return mask;
}

/// generate a canonical type representation to allow anonymous structs to be spawned without error
pub fn CanonicalType(comptime T: type) type {
    if (@typeInfo(T) != .@"struct") @compileError("expected struct type");
    const info = @typeInfo(T).@"struct";
    const Attributes = std.builtin.Type.StructField.Attributes;

    var names: [info.fields.len][]const u8 = undefined;
    var types: [info.fields.len]type = undefined;
    var attrs: [info.fields.len]Attributes = undefined;

    inline for (info.fields, 0..) |f, i| {
        names[i] = f.name;
        types[i] = f.type;
        attrs[i] = Attributes{
            .@"align" = f.alignment,
            .@"comptime" = false,
            .default_value_ptr = null,
        };
    }

    return @Struct(.auto, null, &names, &types, &attrs);
}

test "component ids" {
    try std.testing.expect(componentIdOf(u32) == componentIdOf(u32));
    try std.testing.expect(componentIdOf(u32) != componentIdOf(f32));

    // struct tests
    const Dummy = struct { x: u32 };
    try std.testing.expect(componentIdOf(u32) != componentIdOf(struct { x: u32 }));
    try std.testing.expect(componentIdOf(struct { x: u32 }) != componentIdOf(struct { x: u32 }));
    try std.testing.expect(componentIdOf(Dummy) != componentIdOf(struct { x: u32 }));
    try std.testing.expect(componentIdOf(Dummy) == componentIdOf(Dummy));

    // ZST tests
    try std.testing.expect(componentIdOf(void) == componentIdOf(void));
    try std.testing.expect(componentIdOf(void) != componentIdOf(struct {}));

    // alias tests
    const Name = []const u8;
    try std.testing.expect(componentIdOf(Name) == componentIdOf([]const u8));

    // generic type tests
    try std.testing.expect(componentIdOf(std.ArrayList(u32)) == componentIdOf(std.ArrayList(u32)));
}

test "object" {
    _ = Archetype;
    _ = World;
    _ = table;
    _ = Column;
}
