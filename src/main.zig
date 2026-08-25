const std = @import("std");
const Io = std.Io;

const ve = @import("VoxelEngine");
const rendering = ve.rendering;
const Mesh = rendering.Mesh;

pub fn main(init: std.process.Init) !void {
    var app = ve.App.init(init.arena.allocator());
    defer app.deinit();
    app.addComponents(.{Mesh});

    const triangle = app.newEntity("triangle");
    app.set(triangle, Mesh, Mesh.triangle);
    ve.rendering.pipeline.run();
    // app.run();

    // TODO : spawn cube mesh
    //        spawn camera
    //        run app and render
    //        also add rendering plugin that handles the above
}
