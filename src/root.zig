pub const math = @import("math/math.zig");
pub const App = @import("app/App.zig");
pub const ecs = @import("ecs.zig");
pub const systems = @import("systems/systems.zig");
pub const flecs = @import("zflecs");

test "engine" {
    _ = math;
    _ = ecs;
    _ = App;
    _ = systems;
}
