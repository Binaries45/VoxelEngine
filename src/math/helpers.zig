pub fn isScalar(comptime T: type) bool {
    const TI = @typeInfo(T);
    return (TI == .int
        or TI == .comptime_int
        or TI == .float
        or TI == .comptime_float
    );
}
