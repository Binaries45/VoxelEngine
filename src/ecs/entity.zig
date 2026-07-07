const std = @import("std");
const ComponentId = @import("Components.zig").ComponentId;
const componentIdOf = @import("Components.zig").componentIdOf;

/// a unique id which stores some useful info about the object
pub const Entity = packed struct(u64) {
    /// the key of the bundle corresponding to this object
    key: u16,
    /// the generation number of this object within its archetype
    generation: u16,
    /// the index of this object within its archetype
    index: u32,
};

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
