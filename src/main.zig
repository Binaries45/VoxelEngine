const std = @import("std");
const Io = std.Io;

const ve = @import("VoxelEngine");
const DefaultPlugins = ve.DefaultPlugins;

const Mesh = ve.Mesh;
const Transform = ve.Transform;

// TODO : 
//      switch to world resource, this will provide the necessary rendering code to use
//          - for example, an svo will give its own render impl, 
//            and if we want maybe we will switch to svdag which will
//            also have its own impl, making each world a drop in replacement
//      get a better renderer api (this will likely come as a part of the above idea)

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
}
