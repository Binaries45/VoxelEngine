const sg = @import("sokol").gfx;
const sglue = @import("sokol").glue;
const slog = @import("sokol").log;
const Color = @import("sokol").gfx.Color;

// todo : make this more flexible and easy to use
//  for when we set up a real rendering pipeline
pass: sg.PassAction = .{},
clear_color: Color = .{},

pub const Renderer = @This();

/// initialize the renderer
pub fn init(self: *Renderer) void {
    self.pass.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = self.clear_color,
    };

    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });
}

/// begin drawing the next frame
pub fn beginFrame(self: *Renderer) void {
    sg.beginPass(.{
        .swapchain = sglue.swapchain(),
        .action = self.pass,
    });
}

/// end drawing of the next frame, and commit it
pub fn endFrame(_: *Renderer) void {
    sg.endPass();
    sg.commit();
}

/// end rendering
pub fn shutdown(_: Renderer) void {
    sg.shutdown();
}
