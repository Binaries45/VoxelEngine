pub const entity = @import("ecs/entity.zig");
pub const Components = @import("ecs/Components.zig");
pub const archetype = @import("ecs/archetype.zig");
pub const Storage = @import("ecs/Storage.zig");
pub const World = @import("ecs/World.zig");

test "ecs" {
    _ = entity;
    _ = Components;
    _ = archetype;
    _ = Storage;
    _ = World;
}
