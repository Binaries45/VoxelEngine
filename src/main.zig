const std = @import("std");
const Io = std.Io;

const ve = @import("VoxelEngine");
const DefaultPlugins = ve.DefaultPlugins;

const Mesh = ve.Mesh;
const Transform = ve.Transform;

// TODO : find a home for this stuff ------------
const SVO = @import("SVO.zig");
const VoxelGrid = @import("VoxelGrid.zig");
// ----------------------------------------------

// TODO : 
//      switch to world resource, this will provide the necessary rendering code to use
//          - for example, an svo will give its own render impl, 
//            and if we want maybe we will switch to svdag which will
//            also have its own impl, making each world a drop in replacement
//      get a better renderer api (this will likely come as a part of the above idea)
//      voxels wont be entities anymore, instead entities will simply be rendered as voxels

pub fn main(init: std.process.Init) !void {
    var app = ve.App.init(init.arena.allocator());
    defer app.deinit();
    app.addPlugin(DefaultPlugins);
    app.addComponents(.{ VoxelGrid });
    app.addResource(VoxelGrid, try VoxelGrid.init(app.alloc, 16));

    try app.run();
}
