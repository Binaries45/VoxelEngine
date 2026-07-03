pub const math = @import("math/math.zig");
pub const App = @import("app/App.zig");
pub const object = @import("object/object.zig");
pub const systems = @import("systems/systems.zig");

test "engine" {
    _ = math;
    _ = object;
    _ = App;
    _ = systems;
}
