
const App = @import("App.zig");

const TransformPlugin = @import("plugins/Transform.zig");
const RenderingPlugin = @import("rendering.zig");

pub fn build(app: *App) void {
    app.addPlugin(TransformPlugin);
    app.addPlugin(RenderingPlugin);
}
