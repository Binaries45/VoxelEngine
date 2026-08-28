const std = @import("std");
const Io = std.Io;

const ve = @import("VoxelEngine");
const DefaultPlugins = ve.DefaultPlugins;

const Mesh = ve.Mesh;
const Transform = ve.Transform;

pub fn main(init: std.process.Init) !void {
    var app = ve.App.init(init.arena.allocator());
    defer app.deinit();
    app.addPlugin(DefaultPlugins);

    const cube = app.newEntity("cube");
    app.set(cube, Mesh, Mesh.cube);
    app.set(cube, Transform, Transform {
        .translation = .{0.0, 0.0, 0.0},
        .scale = .{1.0, 1.0, 1.0},
        .rotation = .{0.0, 0.0, 0.0, 0.0}
    });
    try app.run();

    // TODO : spawn cube mesh
    //        spawn camera
    //        run app and render
    //        also add rendering plugin that handles the above
}
