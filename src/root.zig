pub const math = @import("math/math.zig");
pub const App = @import("app/App.zig");
pub const entity = @import("ecs/entity.zig");
pub const systems = @import("systems/systems.zig");

test "engine" {
    _ = math;
    _ = entity;
    _ = App;
    _ = systems;
}
