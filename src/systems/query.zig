
const std = @import("std");
const SystemParam = @import("systems.zig").SystemParam;
const object = @import("../object/object.zig");
const TypeIdBitset = object.TypeIdBitset;
const componentId = object.componentId;

/// construct a query from some type params
pub fn Query(comptime Ts: type) type {
    comptime {
        const info = @typeInfo(Ts).@"struct";
        for (info.fields) |f| {
            const f_info = @typeInfo(f.type);
            if (f_info != .pointer or f_info.pointer.size != .one) {
                @compileError("Query fields must be sinle item pointers (*T or *const T)");
            }
        }
    }

    return struct {
        /// marker constant used for reflection to
        /// determine if this type is in fact a query
        pub const param: SystemParam = .query;
        pub const Types = Ts;
        // todo : other important data for runtime,
        // this will be an iterator over its captured data

        // todo : expect all types to be *T or *const T, for either writing or reading data.
        // todo : how can we make sure all types of data vand archetypes are resolved at comptime?
    };
}

test "query type" {
    const Q = Query(struct { *u32, *const f32, *[]const u8 });
    std.debug.print("Query Of: {s}\n", .{@typeName(Q.Types)});
}
