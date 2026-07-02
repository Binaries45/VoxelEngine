
const SystemParam = @import("systems.zig").SystemParam;

/// construct a query from some type params
pub fn Query(comptime Ts: anytype) type {
    return struct {
        /// marker constant used for reflection to
        /// determine if this type is in fact a query
        pub const param: SystemParam = .query;
        pub const Types = Ts;
        // todo : other important data for runtime,
        // this will be an iterator over its captured data
    };
}
