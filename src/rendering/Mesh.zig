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
        Vertex{ .pos = .{0.0, 0.5, 0.0}, .color = .{1.0, 0.0, 0.0, 1.0} },
        Vertex{ .pos = .{0.5, -0.5, 0.0}, .color = .{0.0, 1.0, 0.0, 1.0} },
        Vertex{ .pos = .{-0.5, -0.5, 0.0}, .color = .{0.0, 0.0, 1.0, 1.0} },
    },
    .indices = null,
};

pub const cube: Mesh = .{
    .vertices = &.{
        Vertex{ .pos = .{-0.5, -0.5, 0.5}, .color = .{0.0, 1.0, 1.0, 1.0} },
        Vertex{ .pos = .{0.5, -0.5, 0.5}, .color = .{1.0, 0.0, 1.0, 1.0} },
        Vertex{ .pos = .{0.5, 0.5, 0.5}, .color = .{1.0, 1.0, 0.0, 1.0} },
        Vertex{ .pos = .{-0.5, 0.5, 0.5}, .color = .{0.0, 0.0, 0.0, 1.0} },

        Vertex{ .pos = .{-0.5, -0.5, -0.5}, .color = .{0.0, 1.0, 1.0, 1.0} },
        Vertex{ .pos = .{0.5, -0.5, -0.5}, .color = .{1.0, 0.0, 1.0, 1.0} },
        Vertex{ .pos = .{0.5, 0.5, -0.5}, .color = .{1.0, 1.0, 0.0, 1.0} },
        Vertex{ .pos = .{-0.5, 0.5, -0.5}, .color = .{0.0, 0.0, 0.0, 1.0} },
    },
    .indices = &.{
        // front
        0, 1, 2,    0, 2, 3,
        // Right
        1, 5, 6,    1, 6, 2,
        // Back
        5, 4, 7,    5, 7, 6,
        // Left
        4, 0, 3,    4, 3, 7,
        // Top
        3, 2, 6,    3, 6, 7,
        // Bottom
        4, 5, 1,    4, 1, 0
    },
};
