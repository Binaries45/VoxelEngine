//! 

const std = @import("std");
const Allocator = std.mem.Allocator;

const Camera = @import("rendering/Camera.zig");

const VG = @This();

/// a voxel, you can put any value in the place of `kind`, 
/// but 0 is reserved for an empty voxel
const Voxel = struct {
    kind: u8 = 0,
};

/// the edge length of the grid
size: usize,
/// voxel data
voxels: []Voxel,

pub fn init(alloc: Allocator, size: usize) !VG {
    return .{
        .size = size,
        .voxels = try alloc.alloc(Voxel, size * size * size),
    };
}

pub fn deinit(g: *VG, alloc: Allocator) void {
    alloc.free(g.voxels);
}

pub fn index(g: *VG, x: usize, y: usize, z: usize) usize {
    return x + y * g.size + z * g.size * g.size;
}

pub fn get(g: *VG, x: usize, y: usize, z: usize) usize {
    return g.voxels[g.index(x, y, z)];
}

pub fn set(g: *VG, x: usize, y: usize, z: usize, value: u8) void {
    g.voxels[g.index(x, y, z)] = .{ .kind = value };
}

// TODO : maybe renderer interface, i think were gonna start by rendering with triangles instead of raycasting cause im more familiar with triangles
