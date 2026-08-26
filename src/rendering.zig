//! rendering plugin

pub const Vertex = @import("rendering/Vertex.zig");
pub const Mesh = @import("rendering/Mesh.zig");
pub const App = @import("App.zig");
pub const pipeline = @import("rendering/pipeline.zig");

pub fn build(app: *App) void {
    app.addComponents(.{ Mesh });
}
