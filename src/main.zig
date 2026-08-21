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

pub fn main(init: std.process.Init) !void {
    // ecs.add_pair(world, bob, ecs.id(Eats), ecs.id(Apples));
    var app = ve.App.init(init.arena.allocator());
    defer app.deinit();
    app.addComponents(.{ Position, Velocity });
    app.addTags(.{ Eats, Apples });
    app.addSystem("move system", ecs.OnUpdate, move_system);

    const bob = app.newEntity("Bob");

    app.set(bob, Position, .{ .vec = fVec3{ 0, 0, 0 } });
    app.set(bob, Velocity, .{ .vec = fVec3{ 1, 2, 3 } });

    app.step();
    app.step();

    const p = ecs.get(app.world, bob, Position).?;
    std.debug.print("Bob's position is: ({d}, {d}, {d})\n", .{ p.vec[0], p.vec[1], p.vec[2] });
}
