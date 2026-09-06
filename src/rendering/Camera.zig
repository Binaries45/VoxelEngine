//! Camera

const std = @import("std");
const math = @import("../math.zig");
const Vec = math.fVec3;
const Mat = math.fMat4;

const Camera = @This();

pos: Vec,
target: Vec,
fov: f32,
aspect: f32,
near: f32,
far: f32,

pub fn view(c: *Camera) Mat {
    return math.Matrix.lookat(c.pos, c.target, .{0.0, 1.0, 0.0, 0.0});
}

pub fn proj(c: *Camera) Mat {
    return math.Matrix.perspective(c.fov, c.aspect, c.near, c.far);
}

// TODO : implement the inverse function to get this to work
// pub fn invViewProj(c: *Camera) Mat {
//     const vp = math.Matrix.mul(c.proj(), c.view());
//     return math.Matrix.inverse(vp);
// }

