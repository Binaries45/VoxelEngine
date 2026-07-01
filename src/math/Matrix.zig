const std = @import("std");
const builtin = @import("builtin");
const Vector = @import("Vector.zig");
const helpers = @import("helpers.zig");
const Vec = Vector.Vec;

const arch = builtin.cpu.arch;
const has_avx = if(arch == .x86_64) std.Target.x86.featureSetHas(builtin.cpu.features, .avx) else false;
const has_fma = if(arch == .x86_64) std.Target.x86.featureSetHas(builtin.cpu.features, .fma) else false;

/// return an CxR column major vector with C columns of size R containing elements of type T
pub fn Mat(comptime C: comptime_int, comptime R: comptime_int, comptime T: type) type {
    if (C > 4) @compileError("Matrices cannot have more than 4 columns");
    if (R > 4) @compileError("Matrices cannot have more than 4 rows");
    if (!helpers.isScalar(T)) @compileError("Element type must be an integer or float");
    return [C]@Vector(R, T);
}

/// returns info on the type of M if M is a matrix type, otherwise returns null
fn matInfo(comptime M: type) ?type {
    const c = if (@typeInfo(M) == .array) @typeInfo(M).array
    else return null;
    const v = if (@typeInfo(c.child) == .vector) @typeInfo(c.child).vector
    else return null;

    return struct {
        const cols = c.len;
        const rows = v.len;
        const T = v.child;
    };
}

/// return the type of a matrix
fn MatType(comptime M: type) type {
    const I = matInfo(M) orelse @compileError("Expected matrix type");
    return Mat(I.cols, I.rows, I.T);
}

/// return the zero matrix with the given size and element type
pub fn zero(comptime C: comptime_int, comptime R: comptime_int, comptime T: type) Mat(C,R,T) {
    return @splat(@splat(@as(T, 0)));
}

/// return the identity matrix with the given size and element type
pub fn identity(comptime M: type) M {
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

    inline for(0..I.cols) |c| inline for(0..I.rows) |r| {
        res[r][c] = m[c][r];
    };

    return res;
}

fn MatTransposeType(comptime M: type) type {
    const I = matInfo(M) orelse @compileError("Expected matrix type");
    return Mat(I.rows, I.cols, I.T);
}

fn MulRetTy(comptime T: type, comptime U: type) type {
    const TI = @typeInfo(T);
    const UI = @typeInfo(U);
    const TM = matInfo(T);
    const UM = matInfo(U);
    // mat x mat
    if (TM) |tm| if (UM) |um| {
        if(tm.T != um.T)
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
    inline for(0..BM.cols) |i| {
        const v0 = Vector.swizzle(b[i], .{0} ** AM.rows);
        res[i] = v0 * a[0];

        inline for(1..AM.cols) |j| {
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
    if(arch == .x86_64 and has_avx and has_fma)
        return @mulAdd(@TypeOf(v0, v1, v2), v0, v1, v2);
    return v0 * v1 + v2;
}

// todo : matrix from quaternion

test "matrix transpose" {
    const m: Mat(3, 4, f32) = .{
        .{1, 2, 3, 4},
        .{1, 2, 3, 4},
        .{1, 2, 3, 4},
    };
    const t = transpose(m);
    try std.testing.expect(@reduce(.And, t[0] == Vec(3, f32) {1, 1, 1}));
    try std.testing.expect(@reduce(.And, t[1] == Vec(3, f32) {2, 2, 2}));
    try std.testing.expect(@reduce(.And, t[2] == Vec(3, f32) {3, 3, 3}));
    try std.testing.expect(@reduce(.And, t[3] == Vec(3, f32) {4, 4, 4}));
}

test "matrix matrix multiplication" {
    const i: Mat(4, 4, f32) = identity(Mat(4, 4, f32));
    const a: Mat(4, 4, f32) = .{
        .{1, 2, 3, 4},
        .{1, 2, 3, 4},
        .{1, 2, 3, 4},
        .{1, 2, 3, 4},
    };

    const axi = mul(a, i);
    try std.testing.expect(@reduce(.And, axi[0] == Vec(4, f32) {1, 2, 3, 4}));
    try std.testing.expect(@reduce(.And, axi[1] == Vec(4, f32) {1, 2, 3, 4}));
    try std.testing.expect(@reduce(.And, axi[2] == Vec(4, f32) {1, 2, 3, 4}));
    try std.testing.expect(@reduce(.And, axi[3] == Vec(4, f32) {1, 2, 3, 4}));
    
    const b: Mat(3, 3, f32) = .{
        .{3, 2, 1},
        .{3, 2, 1},
        .{3, 2, 1},
    };

    const b2 = mul(b, b);
    try std.testing.expect(@reduce(.And, b2[0] == Vec(3, f32) {18, 12, 6}));
    try std.testing.expect(@reduce(.And, b2[1] == Vec(3, f32) {18, 12, 6}));
    try std.testing.expect(@reduce(.And, b2[2] == Vec(3, f32) {18, 12, 6}));
}

test "matrix vector multiplication" {

}

test "matrix scalar multiplication" {

}
