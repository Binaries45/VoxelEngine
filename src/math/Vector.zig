const std = @import("std");
const helpers = @import("helpers.zig");

/// returns a vector of size N containing elements of type T
pub inline fn Vec(comptime N: comptime_int, comptime T: type) type {
    if (N > 4) @compileError("Vectors cannot have length exceeding 4");
    if (!helpers.isScalar(T)) @compileError("Element type must be an integer or float");
    return @Vector(N, T);
}

/// compute the dot product of two vectors
pub inline fn dot(a: anytype, b: anytype) vecInfo(@TypeOf(a, b)).child {
    const AI = vecInfo(@TypeOf(a));
    const BI = vecInfo(@TypeOf(b));
    if (AI.len != BI.len) @compileError("dot product requires two vectors of the same dimension");
    return @reduce(.Add, a * b);
}

/// return the magnitude or "length" of a vector
///
/// only supports vectors of floating point values
pub inline fn magnitude(v: anytype) vecInfo(@TypeOf(v)).child {
    return @sqrt(dot(v, v));
}

/// computes a new vector equal in direction to `v` but with a magnitude of `1`
///
/// only supports vectors of floating point values due to the use of the `magnitude` function
pub inline fn normalize(v: anytype) @TypeOf(v) {
    return v / @as(@TypeOf(v), @splat(magnitude(v)));
}

/// computes the cross product between two three dimensional vectors
pub fn cross(a: anytype, b: anytype) @TypeOf(a, b) {
    const AI = vecInfo(@TypeOf(a));
    const BI = vecInfo(@TypeOf(b));
    if (AI.len != 3 or BI.len != 3)
        @compileError("cross product requires three dimensional vectors");
    return .{
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    };
}

/// returns info on the type of V if V is a vector type, otherwise returns null
pub fn vecInfo(comptime V: type) std.builtin.Type.Vector {
    const VI = @typeInfo(V);
    if (VI != .vector) @compileError(@typeName(V) ++ " is not a vector type");
    return VI.vector;
}

/// create a new vector from the given one by reordering or duplicating elements
pub inline fn swizzle(v: anytype, comptime mask: [vecInfo(@TypeOf(v)).len]i32) @TypeOf(v) {
    return @shuffle(vecInfo(@TypeOf(v)).child, v, undefined, mask);
}

// todo : scalar ops, increase / decrease dimensions

// todo : write tests
test "vector dot product" {
    const a = Vec(3, i32){ 1, 0, 0 };
    const b = Vec(3, i32){ 0, 1, 0 };
    try std.testing.expect(dot(a, b) == 0);

    // todo : other tests
}

test "vector magnitude" {
    const v1 = Vec(3, f32){ 1, 0, 0 };
    const m1 = magnitude(v1);
    try std.testing.expect(m1 == 1.0);

    const v2 = Vec(3, f32){ 1, 0, 1 };
    const m2 = magnitude(v2);
    try std.testing.expect(m2 == @sqrt(2.0));
}

test "vector normalize" {
    const v1 = Vec(3, f32){ 3, 0, 0 };
    const n1 = normalize(v1);
    try std.testing.expect(@reduce(.And, n1 == Vec(3, f32){ 1, 0, 0 }));

    // todo : other tests
}

test "vector cross product" {
    const a = Vec(3, f32){ 1, 0, 0 };
    const b = Vec(3, f32){ 0, 1, 0 };
    const c = cross(a, b);
    try std.testing.expect(@reduce(.And, c == Vec(3, f32){ 0, 0, 1 }));

    // todo : other tests
}

test "vector swizzle" {
    const a = Vec(4, f32){ 1, 2, 3, 4 };
    const xs = swizzle(a, .{ 0, 0, 0, 0 });
    const rev = swizzle(a, .{ 3, 2, 1, 0 });
    try std.testing.expect(@reduce(.And, xs == Vec(4, f32){ 1, 1, 1, 1 }));
    try std.testing.expect(@reduce(.And, rev == Vec(4, f32){ 4, 3, 2, 1 }));
}
