//! Sparse Voxel Octree

const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const SVO = @This();

alloc: Allocator,
nodes: ArrayList(Node),
/// edge length of the world in voxels (must be a power of 2)
size: u32,

pub const Node = struct {
    /// mask of all children which contain a voxel, 
    /// each bit represents one active child
    children: u8 = 0,
    /// index into the SVO world, indicating the start of its child payload
    /// the data will be in the range base..(base + children.popcount)
    base: u32 = 0,
    is_leaf: bool = false,
    // TODO : material / voxel type for this node
};

pub fn init(alloc: Allocator) !SVO { 
    var svo: SVO = .{
        .alloc = alloc,
        .nodes = .empty,
    };

    try svo.nodes.append(alloc, .{});

    return svo;
}

pub fn deinit(s: *SVO) void {
    s.nodes.deinit(s.alloc);
}

pub fn root(s: *SVO) *Node {
    return &s.nodes.items[0];
}
