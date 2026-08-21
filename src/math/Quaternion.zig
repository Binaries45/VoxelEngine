const Vector = @import("Vector.zig");
const Vec = Vector.Vec;
const helpers = @import("helpers.zig");

/// create a quaternion with the given element type
pub fn Quat(T: type) type {
    if (!helpers.isScalar(T)) @compileError("Element type must be an integer or float");
    return Vec(4, T);
}

fn QuatInfo(Q: type) type {
    const I = @typeInfo(Q);
    if (I != .vector) @compileError(@typeName(Q) ++ " is not a valid Quaternion");
    return struct {
        const T = I.vector.child;
    };
}

// from matrix
// rotate vector
// multiplication
// inverse

/// compute the dot product of a quaternion
pub fn dot(a: anytype, b: anytype) QuatInfo(@TypeOf(a, b)).T {
    return @reduce(.Add, a * b);
}

// normalize

test "quaternion dot product" {}
