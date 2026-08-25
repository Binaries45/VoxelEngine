pub const math = @import("math.zig");
pub const App = @import("App.zig");
pub const rendering = @import("rendering.zig");

pub const ecs = @import("zflecs");

test "engine" {
    _ = math;
    _ = App;
    _ = rendering;
}
