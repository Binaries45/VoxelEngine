pub const Vector = @import("math/Vector.zig");
const Vec = Vector.Vec;

pub const fVec2 = Vec(2, f32);
pub const fVec3 = Vec(3, f32);
pub const fVec4 = Vec(4, f32);

pub const iVec2 = Vec(2, i32);
pub const iVec3 = Vec(3, i32);
pub const iVec4 = Vec(4, i32);

pub const Matrix = @import("math/Matrix.zig");
const Mat = Matrix.Mat;

pub const fMat2 = Mat(2, 2, f32);
pub const fMat3 = Mat(3, 3, f32);
pub const fMat4 = Mat(4, 4, f32);

pub const iMat2 = Mat(2, 2, i32);
pub const iMat3 = Mat(3, 3, i32);
pub const iMat4 = Mat(4, 4, i32);

pub const Quaternion = @import("math/Quaternion.zig");
const Quat = Quaternion.Quat;

pub const iQuat = Quat(i32);
pub const fQuat = Quat(f32);

test "math" {
    _ = Vector;
    _ = Matrix;
    _ = Quat;
}
