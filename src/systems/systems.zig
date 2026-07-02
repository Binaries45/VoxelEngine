const query = @import("query.zig");

pub const Query = query.Query;

/// stores all reflection data of a system
pub const SystemInfo = struct {
    /// a pointer to the system function
    f: *const anyopaque,
    /// info on each parameter of the system
    params: []ParamInfo,
    /// true if return type is !void, false otherwise
    fallible: bool = false,
};

/// all valid system parameter kinds
pub const SystemParam = enum {
    query,
    resource,
    commands,
};

/// info on some system parameter
pub const ParamInfo = union(SystemParam) {
    query: QueryInfo,
    resource: ResourceInfo,
    commands,

    pub const QueryInfo = struct {};

    pub const ResourceInfo = struct {};
};

/// inspect a system and return all info relevant for the app & scheduler
pub fn inspectSystem(comptime s: anytype) SystemInfo {
    if (@typeInfo(@TypeOf(s)) != .@"fn") @compileError("expected function");
    const info = @typeInfo(@TypeOf(s)).@"fn";
    var params: [info.params.len]ParamInfo = undefined;
    inline for (info.params, 0..) |p, i| {
        if (!@hasDecl(p.type.?, "param")) {
            @compileLog(@typeInfo(p.type.?));
            @compileError("invalid system parameter type: " ++ @typeName(p.type.?));
        }
        params[i] = switch (p.type.?.param) {
            // todo : get relevant info on each param
            .query => ParamInfo{ .query = .{} },
            .resource => ParamInfo{ .resource = .{} },
            .commands => ParamInfo{ .commands },
        };
    }

    // todo : !void errors becuase ! is parsed as logical not lol, I'll fix this later
    // const fallible = if (info.return_type.? == !void) true else blk: {
    //     if (info.return_type.? != void) @compileError("return type of system must be void or !void");
    //     break :blk false;
    // };

    return .{
        .f = &s,
        .params = &params,
        // .fallible = fallible,
    };
}

// TODO :
//   queries
//   resources
//   command buffer

test "systems" {
    _ = query;
}

test "system inspection" {
    const system = struct {
        fn system(q: Query(.{ u32, f32 })) void {
            _ = q;
        }
    }.system;

    const info = inspectSystem(system);
    _ = info;
}
