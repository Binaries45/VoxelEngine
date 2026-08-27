const std = @import("std");
const builtin = @import("builtin");
const Vector = @import("Vector.zig");
const helpers = @import("helpers.zig");
const Vec = Vector.Vec;

const arch = builtin.cpu.arch;
const has_avx = if (arch == .x86_64) std.Target.x86.featureSetHas(builtin.cpu.features, .avx) else false;
const has_fma = if (arch == .x86_64) std.Target.x86.featureSetHas(builtin.cpu.features, .fma) else false;

/// return an CxR column major vector with C columns of size R containing elements of type T
pub fn Mat(C: comptime_int, R: comptime_int, T: type) type {
    if (C > 4) @compileError("Matrices cannot have more than 4 columns");
    if (R > 4) @compileError("Matrices cannot have more than 4 rows");
    if (!helpers.isScalar(T)) @compileError("Element type must be an integer or float");
    return [C]@Vector(R, T);
}

/// returns info on the type of M if M is a matrix type, otherwise returns null
fn matInfo(M: type) ?type {
    // TODO : compile error instead of null
    const c = if (@typeInfo(M) == .array) @typeInfo(M).array else return null;
    const v = if (@typeInfo(c.child) == .vector) @typeInfo(c.child).vector else return null;

    return struct {
        const cols = c.len;
        const rows = v.len;
        const T = v.child;
    };
}

/// return the type of a matrix
fn MatType(M: type) type {
    const I = matInfo(M) orelse @compileError("Expected matrix type");
    return Mat(I.cols, I.rows, I.T);
}

/// return the zero matrix with the given size and element type
pub fn zero(C: comptime_int, R: comptime_int, T: type) Mat(C, R, T) {
    return @splat(@splat(@as(T, 0)));
}

/// return the identity matrix with the given size and element type
pub fn identity(M: type) M {
    const I = matInfo(M) orelse @compileError("Expected matrix type");
    var res: M = zero(I.cols, I.cols, I.T);
    inline for (0..I.cols) |i| res[i][i] = @as(I.T, 1);
    return res;
}

// todo : transpose via @shuffle, might be faster :P
/// transpose a matrix from row-major to column-major
pub fn transpose(m: anytype) MatTransposeType(@TypeOf(m)) {
    const I = matInfo(@TypeOf(m)) orelse @compileError("Expected matrix type");
    var res: MatTransposeType(@TypeOf(m)) = undefined;

    inline for (0..I.cols) |c| inline for (0..I.rows) |r| {
        res[r][c] = m[c][r];
    };

    return res;
}

fn MatTransposeType(M: type) type {
    const I = matInfo(M) orelse @compileError("Expected matrix type");
    return Mat(I.rows, I.cols, I.T);
}

fn MulRetTy(T: type, U: type) type {
    const TI = @typeInfo(T);
    const UI = @typeInfo(U);
    const TM = matInfo(T);
    const UM = matInfo(U);
    // mat x mat
    if (TM) |tm| if (UM) |um| {
        if (tm.T != um.T)
            @compileError("element types must match, got " ++ @typeName(tm.T) ++ " and " ++ @typeName(um.T));
        if (tm.cols != um.rows) @compileError("Matrix dimensions are incompatible for multiplication");
        return Mat(um.cols, tm.rows, tm.T);
    };

    // mat x vec
    if (TM) |m| if (UI == .vector) {
        if (m.T != UI.vector.child)
            @compileError("element types must match, got " ++ @typeName(m.T) ++ " and " ++ @typeName(UI.vector.child));

        return @Vector(UI.vector.len, UI.vector.child);
    };
    if (UM) |m| if (TI == .vector) {
        if (m.T != TI.vector.child)
            @compileError("element types must match, got " ++ @typeName(m.T) ++ " and " ++ @typeName(TI.vector.child));

        return @Vector(TI.vector.len, TI.vector.child);
    };

    // mat x scalar
    if (TM) |m| if (helpers.isScalar(U)) {
        if (m.T != U)
            @compileError("element types must match, got " ++ @typeName(m.T) ++ " and " ++ @typeName(U));

        return Mat(m.cols, m.rows, m.T);
    };
    if (UM) |m| if (helpers.isScalar(T)) {
        if (m.T != T)
            @compileError("element types must match, got " ++ @typeName(m.T) ++ " and " ++ @typeName(T));

        return Mat(m.cols, m.rows, m.T);
    };
    @compileError("invalid types for multiplication " ++ @typeName(T) ++ " and " ++ @typeName(U));
}

/// multiply a matrix by a matrix, vector, or scalar
pub fn mul(a: anytype, b: anytype) MulRetTy(@TypeOf(a), @TypeOf(b)) {
    const Ta = @TypeOf(a);
    const Tb = @TypeOf(b);
    // const AI = @typeInfo(Ta);
    // const BI = @typeInfo(Tb);
    const AM = matInfo(Ta);
    const BM = matInfo(Tb);
    if (AM) |_| if (BM) |_| {
        return mulMat(a, b);
    };
    if (AM) |_|
        @compileError("todo");
    // todo : mat x vec and mat x scalar
}

/// multiply two matrices
fn mulMat(a: anytype, b: anytype) MulRetTy(@TypeOf(a), @TypeOf(b)) {
    const AM = matInfo(@TypeOf(a)) orelse @compileError("Expected matrix type, got " ++ @TypeOf(a));
    const BM = matInfo(@TypeOf(b)) orelse @compileError("Expected matrix type, got " ++ @TypeOf(b));

    var res: MulRetTy(@TypeOf(a), @TypeOf(b)) = undefined;
    inline for (0..BM.cols) |i| {
        const v0 = Vector.swizzle(b[i], .{0} ** AM.rows);
        res[i] = v0 * a[0];

        inline for (1..AM.cols) |j| {
            const vj = Vector.swizzle(b[i], .{j} ** AM.rows);
            res[i] = mulAdd(vj, a[j], res[i]);
        }
    }

    return res;
}

fn mulMatVec(m: anytype, v: anytype) MulRetTy(@TypeOf(m), @TypeOf(v)) {
    // todo : mat x vec
}

fn mulVecMat(m: anytype, v: anytype) MulRetTy(@TypeOf(m), @TypeOf(v)) {
    // todo : vec x mat
}

fn mulMatScalar(m: anytype, s: anytype) MulRetTy(@TypeOf(m), @TypeOf(s)) {
    // todo
}

fn mulAdd(v0: anytype, v1: anytype, v2: anytype) @TypeOf(v0, v1, v2) {
    if (arch == .x86_64 and has_avx and has_fma)
        return @mulAdd(@TypeOf(v0, v1, v2), v0, v1, v2);
    return v0 * v1 + v2;
}

pub fn lookat(eye: Vec(3, f32), center: Vec(3, f32), up: Vec(3, f32)) Mat(4, 4, f32) {
    var res = zero(4, 4, f32);

    const f = Vector.normalize(center - eye);
    const s = Vector.normalize(Vector.cross(f, up));
    const u = Vector.cross(s, f);

    res[0][0] = s[0];
    res[0][1] = u[0];
    res[0][2] = -f[0];

    res[1][0] = s[1];
    res[1][1] = u[1];
    res[1][2] = -f[1];

    res[2][0] = s[2];
    res[2][1] = u[2];
    res[2][2] = -f[2];

    res[3][0] = -Vector.dot(s, eye);
    res[3][1] = -Vector.dot(u, eye);
    res[3][2] = Vector.dot(f, eye);
    res[3][3] = 1.0; 

    return res;
}

/// return a perspective matrix from the given parameters
pub fn perspective(fov: f32, aspect: f32, near: f32, far: f32) Mat(4, 4, f32) {
    const M = Mat(4, 4, f32);
    var res = identity(M);
    const t = std.math.tan(fov * (std.math.pi / 360.0));
    
    res[0][0] = 1.0 / t;
    res[1][1] = aspect / t;
    res[2][3] = -1.0;
    res[2][2] = (near + far) / (near - far);
    res[3][2] = (2.0 * near * far) / (near - far);
    res[3][3] = 0.0; 
    
    return res;
}

/// TODO : meaningful comment 
pub fn rotate(T: type, angle: f32, uniform: Vec(3, T)) Mat(4, 4, T) {
    const M = Mat(4, 4, T);

    var res = identity(M);

    const axis = Vector.normalize(uniform);
    const sin_theta = std.math.sin(std.math.degreesToRadians(angle));
    const cos_theta = std.math.cos(std.math.degreesToRadians(angle));
    const cos_value = 1.0 - cos_theta;

    res[0][0] = (axis[0] * axis[0] * cos_value) + cos_theta;
    res[0][1] = (axis[0] * axis[1] * cos_value) + (axis[2] * sin_theta);
    res[0][2] = (axis[0] * axis[2] * cos_value) - (axis[1] * sin_theta);
    res[1][0] = (axis[1] * axis[0] * cos_value) - (axis[2] * sin_theta);
    res[1][1] = (axis[1] * axis[1] * cos_value) + cos_theta;
    res[1][2] = (axis[1] * axis[2] * cos_value) + (axis[0] * sin_theta);
    res[2][0] = (axis[2] * axis[0] * cos_value) + (axis[1] * sin_theta);
    res[2][1] = (axis[2] * axis[1] * cos_value) - (axis[0] * sin_theta);
    res[2][2] = (axis[2] * axis[2] * cos_value) + cos_theta;

    return res; 
}

// TODO : matrix from quaternion

test "matrix transpose" {
    const m: Mat(3, 4, f32) = .{
        .{ 1, 2, 3, 4 },
        .{ 1, 2, 3, 4 },
        .{ 1, 2, 3, 4 },
    };
    const t = transpose(m);
    try std.testing.expect(@reduce(.And, t[0] == Vec(3, f32){ 1, 1, 1 }));
    try std.testing.expect(@reduce(.And, t[1] == Vec(3, f32){ 2, 2, 2 }));
    try std.testing.expect(@reduce(.And, t[2] == Vec(3, f32){ 3, 3, 3 }));
    try std.testing.expect(@reduce(.And, t[3] == Vec(3, f32){ 4, 4, 4 }));
}

test "matrix matrix multiplication" {
    const i: Mat(4, 4, f32) = identity(Mat(4, 4, f32));
    const a: Mat(4, 4, f32) = .{
        .{ 1, 2, 3, 4 },
        .{ 1, 2, 3, 4 },
        .{ 1, 2, 3, 4 },
        .{ 1, 2, 3, 4 },
    };

    const axi = mul(a, i);
    try std.testing.expect(@reduce(.And, axi[0] == Vec(4, f32){ 1, 2, 3, 4 }));
    try std.testing.expect(@reduce(.And, axi[1] == Vec(4, f32){ 1, 2, 3, 4 }));
    try std.testing.expect(@reduce(.And, axi[2] == Vec(4, f32){ 1, 2, 3, 4 }));
    try std.testing.expect(@reduce(.And, axi[3] == Vec(4, f32){ 1, 2, 3, 4 }));

    const b: Mat(3, 3, f32) = .{
        .{ 3, 2, 1 },
        .{ 3, 2, 1 },
        .{ 3, 2, 1 },
    };

    const b2 = mul(b, b);
    try std.testing.expect(@reduce(.And, b2[0] == Vec(3, f32){ 18, 12, 6 }));
    try std.testing.expect(@reduce(.And, b2[1] == Vec(3, f32){ 18, 12, 6 }));
    try std.testing.expect(@reduce(.And, b2[2] == Vec(3, f32){ 18, 12, 6 }));
}

test "matrix vector multiplication" {}

test "matrix scalar multiplication" {}
