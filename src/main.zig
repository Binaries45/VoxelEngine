const std = @import("std");
const Io = std.Io;

const ve = @import("VoxelEngine");
const math = ve.math;
const fVec3 = math.fVec3;

const DefaultPlugins = ve.DefaultPlugins;

const Mesh = ve.Mesh;
const Transform = ve.Transform;

const VoxelGrid = ve.VoxelGrid;

// TODO : find a home for this stuff ------------
const SVO = @import("SVO.zig");
// ----------------------------------------------

// TODO : 
//      switch to world resource, this will provide the necessary rendering code to use
//          - for example, an svo will give its own render impl, 
//            and if we want maybe we will switch to svdag which will
//            also have its own impl, making each world a drop in replacement
//      get a better renderer api (this will likely come as a part of the above idea)
//      voxels wont be entities anymore, instead entities will simply be rendered as voxels

pub const VoxelKind = enum(u8) {
    stone = 1,
};

pub fn VoxelColor(kind: VoxelKind) fVec3 {
    return switch (kind) {
        .stone => .{0.5, 0.5, 0.5},
    };
}

pub fn main(init: std.process.Init) !void {
    var app = ve.App.init(init.arena.allocator());
    defer app.deinit();
    app.addPlugin(DefaultPlugins);
    app.addComponents(.{ VoxelGrid });
    app.addResource(VoxelGrid, try VoxelGrid.init(app.alloc, 8));

    const grid = app.getResourceMut(VoxelGrid).?;
    grid.set(0, 0, 0, @intFromEnum(VoxelKind.stone));
    grid.set(1, 1, 1, @intFromEnum(VoxelKind.stone));
    grid.set(2, 2, 2, @intFromEnum(VoxelKind.stone));

    try app.run();
}
