const std = @import("std");
const Io = std.Io;

const ve = @import("VoxelEngine");
const ecs = ve.ecs;
const fVec3 = ve.math.fVec3;

/// NOTE : we have to wrap these in structs otherwise flecs will register them as the same type,
/// maybe in the future we can have a way for the engine to auto-wrap these to reduce headaches later.
const Position = struct { vec: fVec3 };
const Velocity = struct { vec: fVec3 };
const Eats = struct {};
const Apples = struct {};

fn move_system(positions: []Position, velocities: []const Velocity) void {
    for (positions, velocities) |*p, v| p.vec += v.vec;
}

// Optionally, systems can receive the components iterator (usually not necessary)
fn move_system_with_it(it: *ecs.iter_t, positions: []Position, velocities: []const Velocity) void {
    const type_str = ecs.table_str(it.world, it.table).?;
    std.debug.print("Move entities with [{s}]\n", .{type_str});
    defer ecs.os.free(type_str);

    for (positions, velocities) |*p, v| p.vec += v.vec;
}

pub fn main(init: std.process.Init) !void {
    // const bob = ecs.new_entity(world, "Bob");
    // _ = ecs.set(world, bob, Position, .{ .vec = fVec3{0, 0, 0} });
    // _ = ecs.set(world, bob, Velocity, .{ .vec = fVec3{1, 2, 3} });
    // ecs.add_pair(world, bob, ecs.id(Eats), ecs.id(Apples));

    // _ = ecs.progress(world, 0);
    // _ = ecs.progress(world, 0);

    // const p = ecs.get(world, bob, Position).?;
    // std.debug.print("Bob's position is ({d}, {d}, {d})\n", .{ p.vec[0], p.vec[1], p.vec[2] });
    var app = ve.App.init(init.arena.allocator());
    defer app.deinit();
    app.addComponents(.{ Position, Velocity });
    app.addTags(.{ Eats, Apples });
    app.addSystem("move system", ecs.OnUpdate, move_system);
    app.addSystem("move system with iterator", ecs.OnUpdate, move_system_with_it);
    // TODO : spawn entities
    // TODO : progress
    try app.run();
}
