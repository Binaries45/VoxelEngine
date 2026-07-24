const std = @import("std");
const ecs = @import("zflecs");

const App = @This();

alloc: std.mem.Allocator,
world: *ecs.world_t,

// TODO
//     plugins.
//     add plugins
//     add systems
//     add components
//     add tags
//     ...  

pub fn init(alloc: std.mem.Allocator) App {
    return .{
        .alloc = alloc,
        .world = ecs.init(),
    };
}

pub fn deinit(app: *App) void {
    _ = ecs.fini(app.world);
}

pub fn run(app: *App) !void {
    _ = app;
    // todo : actually run the app
}

/// add the given components to the ecs
pub fn addComponents(app: *App, comptime components: anytype) void {
    inline for (components) |C| ecs.COMPONENT(app.world, C);
}

/// add the given tags to the ecs
pub fn addTags(app: *App, comptime tags: anytype) void {
    inline for (tags) |T| ecs.TAG(app.world, T);
}

/// add the given systems to the ecs
pub fn addSystem(app: *App, name: [*:0]const u8, phase: ecs.entity_t, comptime fn_system: anytype) void {
    _ = ecs.ADD_SYSTEM(app.world, name, phase, fn_system);
}
