// TODO : LABEL ---------------------------------
pub const App = @import("App.zig");
pub const ecs = @import("zflecs");
// ----------------------------------------------

// MODULES --------------------------------------
pub const math = @import("math.zig");
// ----------------------------------------------

// Component Types ------------------------------
pub const Mesh = @import("rendering.zig").Mesh;
pub const Transform = @import("plugins/Transform.zig").Transform;
// ----------------------------------------------

// PLUGINS --------------------------------------
pub const DefaultPlugins = @import("Plugins.zig");
// ----------------------------------------------

test "engine" {
    _ = math;
    _ = App;
}
