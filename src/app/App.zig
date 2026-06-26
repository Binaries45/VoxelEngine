const std = @import("std");

const App = @This();

alloc: std.mem.Allocator,

pub fn init(alloc: std.mem.Allocator) App {
    return .{
        .alloc = alloc,
    };
}

pub fn run(app: *App) !void {
    _ = app;
    // todo : actually run the app
}

// old app code from a previous engine project
// const sapp = @import("sokol").app;
// const sg = @import("sokol").gfx;
// const Color = sg.Color;
// const color = @import("../rendering/color.zig");
//
// const Renderer = @import("../rendering/Renderer.zig").Renderer;
//
// pub const AppSettings = struct {
//     width: i32 = 640,
//     height: i32 = 480,
//     title: [*c]const u8 = "My App",
//     clear_color: Color = color.rgb(50, 50, 50),
// };
//
// pub const App = @This();
//
// width: i32,
// height: i32,
// title: [*c]const u8,
// renderer: Renderer = .{},
// // icon: todo
//
// const Self = @This();
//
// /// global pointer to self, should only be used by functions
// /// called within `run` as it is null until `run` is called
// var ptr: ?*Self = null; // I hate this but I gotta do what I gotta do
//
// /// initialize a new app
// pub fn init(settings: AppSettings) App {
//     return .{
//         .height = settings.height,
//         .width = settings.width,
//         .title = settings.title,
//         .renderer = .{ .clear_color = settings.clear_color }
//     };
// }
//
// fn init_cb() callconv(.c) void {
//     ptr.?.renderer.init();
// }
//
// fn frame_cb() callconv(.c) void {
//     const self = ptr.?;
//     const delta = sapp.frameDuration();
//     self.update(delta);
//     self.render();
// }
//
// fn cleanup_cb() callconv(.c) void {
//     ptr.?.renderer.shutdown();
// }
//
// fn update(self: *Self, delta: f64) void {
//     _ = self;
//     _ = delta;
// }
//
// fn render(self: *Self) void {
//     self.renderer.beginFrame();
//     self.renderer.endFrame();
// }
//
// /// run the app
// pub fn run(self: *Self) void {
//     ptr = self;
//
//     sapp.run(.{
//         .init_cb = init_cb,
//         .frame_cb = frame_cb,
//         .cleanup_cb = cleanup_cb,
//         .window_title = self.title,
//         .width = self.width,
//         .height = self.height,
//     });
// }

