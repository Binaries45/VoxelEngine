const std = @import("std");

/// returns a vector of size N containing elements of type T
pub inline fn Vec(comptime N: comptime_int, comptime T: type) type {
    // todo : ensure vector is made from int or float type
    return @Vector(N, T);
}

/// compute the dot product of two vectors
pub inline fn dot(comptime N: comptime_int, comptime T: type, a: Vec(N, T), b: Vec(N, T)) T {
    return @reduce(.Add, a * b);
}

/// return the magnitude or "length" of a vector
///
/// only supports vectors of floating point values
pub inline fn magnitude(comptime N: comptime_int, comptime T: type, v: Vec(N, T)) T {
    return @sqrt(dot(N, T, v, v));
}

/// computes a new vector equal in direction to `v` but with a magnitude of `1`
///
/// only supports vectors of floating point values due to the use of the `magnitude` function
pub inline fn normalize(comptime N: comptime_int, comptime T: type, v: Vec(N, T)) Vec(N, T) {
    return v / @as(Vec(N, T), @splat(magnitude(N, T, v)));
}

/// computes the cross product between two three dimensional vectors
pub fn cross(comptime T: type, a: Vec(3, T), b: Vec(3, T)) Vec(3, T) {
    return .{
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    };
}

// todo : write tests
test "dot product" {
    const a = Vec(3, i32) { 1, 0, 0 };
    const b = Vec(3, i32) { 0, 1, 0 };
    try std.testing.expect(dot(3, i32, a, b) == 0);

    // todo : other tests
}

test "magnitude" {
    const v1 = Vec(3, f32) {1, 0, 0};
    const m1 = magnitude(3, f32, v1);
    try std.testing.expect(m1 == 1.0);

    const v2 = Vec(3, f32) {1, 0, 1};
    const m2 = magnitude(3, f32, v2);
    try std.testing.expect(m2 == @sqrt(2.0));
}

test "normalize" {
    const v1 = Vec(3, f32) {3, 0, 0};
    const n1 = normalize(3, f32, v1);
    try std.testing.expect(@reduce(.And, n1 == Vec(3, f32) {1, 0, 0}));

    // todo : other tests
}

test "cross product" {
    const a = Vec(3, f32) {1, 0, 0};
    const b = Vec(3, f32) {0, 1, 0};
    const c = cross(f32, a, b);
    try std.testing.expect(@reduce(.And, c == Vec(3, f32) {0, 0, 1}));

    // todo : other tests
}