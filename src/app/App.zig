const std = @import("std");
const ecs = @import("zflecs");
const Plugin = @import("Plugin.zig");

const App = @This();

alloc: std.mem.Allocator,
world: *ecs.world_t,

// TODO
//     plugins.
//     add plugins.

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
    // TODO :
    // - progress the app until we find a need to terminate
    //   - this will either be an error or some kind of program zignal to end
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

pub fn newEntity(app: *App, name: [*:0]const u8) ecs.entity_t {
    return ecs.new_entity(app.world, name);
}

pub fn addPlugin(app: *App, comptime plugin: anytype) void {
    Plugin.validate(plugin);
    @TypeOf(plugin).build(app);
}
