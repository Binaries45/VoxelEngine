const std = @import("std");
const ecs = @import("root.zig").ecs;
const Plugin = @import("app/Plugin.zig");
const rendering = @import("rendering.zig");
const pipeline = rendering.pipeline;

const sokol = @import("sokol");
const sapp = sokol.app;
const slog = sokol.log;

const App = @This();

alloc: std.mem.Allocator,
world: *ecs.world_t,

/// global app pointer
var app_ptr: ?*App = null;

pub fn init(alloc: std.mem.Allocator) App {
    return .{
        .alloc = alloc,
        .world = ecs.init(),
    };
}

pub fn deinit(app: *App) void {
    _ = ecs.fini(app.world);
}

pub fn step(app: *App) void {
    _ = ecs.progress(app.world, 0);
}

pub fn run(app: *App) !void {
    app_ptr = app;
 
    const tick = struct {
        export fn tick() void {
            app_ptr.?.step();
            pipeline.frame();
        }
    }.tick;

    sapp.run(.{
        .init_cb = pipeline.init,
        .frame_cb = tick,
        .cleanup_cb = pipeline.cleanup,
        .width = 1920,
        .height = 1080,
        .depth_format = .NONE,
        .icon = .{ .sokol_default = true },
        .window_title = "triangle.zig",
        .logger = .{ .func = slog.func },
    });
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

/// create and return a new entity
pub fn newEntity(app: *App, name: [*:0]const u8) ecs.entity_t {
    return ecs.new_entity(app.world, name);
}

/// destroy an entity
pub fn destroy(app: *App, entity: u64) void {
    ecs.delete(app.world, entity);
}

pub fn addPlugin(app: *App, plugin: type) void {
    Plugin.validate(plugin);
    plugin.build(app);
}

/// set the value of a component for some entity
pub fn set(app: *App, entity: u64, T: type, component: T) void {
    _ = ecs.set(app.world, entity, T, component);
}

/// remove a component from an entity
pub fn remove(app: *App, entity: u64, T: type) void {
    ecs.remove(app.world, entity, T);
}

/// returns whether the given entity has the given component
pub fn has(app: *App, entity: u64, T: type) bool {
    const component = ecs.id(T);
    return ecs.has_id(app.world, entity, component);
}

/// get the value of a component for the given entity
pub fn get(app: *App, entity: u64, T: type) ?*const T {
    return ecs.get(app.world, entity, T);
}
