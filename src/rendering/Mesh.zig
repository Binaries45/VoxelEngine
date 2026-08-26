//! mesh

const std = @import("std");
const math = @import("../math.zig");
const fVec3 = math.fVec3;
const fvec4 = math.fVec4;

const sokol = @import("sokol");
const sg = sokol.gfx;

const Vertex = @import("Vertex.zig");

const Mesh = @This();

vertices: []const Vertex,
// if this is null, draw straight from vertices
indices: ?[]const u32,

pub const triangle: Mesh = .{
    .vertices = &.{
        Vertex{ .pos = fVec3{0.0, 0.5, 0.0}, .color = .{1.0, 0.0, 0.0, 1.0} },
        Vertex{ .pos = fVec3{0.5, -0.5, 0.0}, .color = .{0.0, 1.0, 0.0, 1.0} },
        Vertex{ .pos = fVec3{-0.5, -0.5, 0.0}, .color = .{0.0, 0.0, 1.0, 1.0} },
    },
    .indices = null,
};

