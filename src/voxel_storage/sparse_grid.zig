//! sparse grid voxel storage.
//!
//! note : this storage is not intended for serious use, it has very expensive rendering costs and mostly just exists as a proof of concept

const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayHashMap = std.array_hash_map.Custom;

const math = @import("../math.zig");
const iVec3 = math.iVec3; 

const Voxel = struct {
    // TODO : material representation

};

const Grid = @This();

alloc: Allocator,
voxels: ArrayHashMap(iVec3, Voxel, std.array_hash_map.AutoContext(iVec3), false),

pub fn init(alloc: Allocator) Grid {
    return .{
        .alloc = alloc,
        .voxels = .empty,
    };
}

pub fn deinit(g: *Grid) void {
    g.voxels.deinit(g.alloc);
}

/// add a voxel to the grid 
pub fn addVoxel(g: *Grid, v: Voxel, pos: iVec3) !void {
   try g.voxels.put(g.alloc, pos, v); 
}

/// remove a volxel at the given position
pub fn deleteVoxel(g: *Grid, pos: iVec3) void {
    _ = g.voxels.swapRemove(pos);
}

// TODO : per voxel rendering, generate each cube mesh, render,
