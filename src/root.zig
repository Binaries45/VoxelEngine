
pub const Vector = @import("math/Vector.zig");
const Vec = Vector.Vec;

pub const Vec2f = Vec(2, f32);
pub const Vec3f = Vec(3, f32);
pub const Vec4f = Vec(4, f32);

pub const Vec2i = Vec(2, i32);
pub const Vec3i = Vec(3, i32);
pub const Vec4i = Vec(4, i32);

// pub const Matrix = @import("math/Matrix.zig");

test "engine" {
    _ = Vector;
    // _ = Matrix;
}