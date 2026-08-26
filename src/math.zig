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

/// taken from : 
/// https://github.com/floooh/sokol-zig/blob/6c0ba44e7c001354a476e43c78f571534144008b/examples/instancing.zig#L171 
fn xorshift32() u32 {
    const static = struct {
        var x: u32 = 0x12345678;
    };
    var x = static.x;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    static.x = x;
    return x;
}

/// return a random u32 in the given range
pub fn rand(min: u32, max: u32) u32 {
    return ((xorshift32() & 0xFFFF) * (max - min) + min);
}

/// return a random f32 in the given range
pub fn frand(min: f32, max: f32) f32 {
    const float = @as(f32, @floatFromInt(xorshift32() & 0xFFFF)) / 0x10000; 
    return float * (max - min) + min;
}

test "math" {
    _ = Vector;
    _ = Matrix;
    _ = Quat;
}
