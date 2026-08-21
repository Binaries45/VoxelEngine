const std = @import("std");
const Io = std.Io;

const ve = @import("VoxelEngine");
const ecs = ve.ecs;
const fVec3 = ve.math.fVec3;

// maybe in the future we can have a way for the engine to auto-wrap these to reduce headaches later.
const Position = struct { vec: fVec3 };
const Velocity = struct { vec: fVec3 };

const MovePlugin = struct {
    pub fn build(app: *ve.App) void {
        app.addComponents(.{ Position, Velocity });
        app.addSystem("move system", ecs.OnUpdate, move_system);
    }
    
    fn move_system(positions: []Position, velocities: []const Velocity) void {
        for (positions, velocities) |*p, v| p.vec += v.vec;
    }
};

pub fn main(init: std.process.Init) !void {
    var app = ve.App.init(init.arena.allocator());
    defer app.deinit();
    app.addPlugin(MovePlugin{});

    const alice = app.newEntity("Alice");
    app.set(alice, Position, .{ .vec = fVec3{ 0, 0, 0 } });
    app.set(alice, Velocity, .{ .vec = fVec3{ 2, 2, -1 } });

    const bob = app.newEntity("Bob");
    app.set(bob, Position, .{ .vec = fVec3{ 0, 0, 0 } });
    app.set(bob, Velocity, .{ .vec = fVec3{ 1, 2, 3 } });

    app.step();
    app.step();

    const pa = app.get(alice, Position).?;
    const pb = app.get(bob, Position).?;
    std.debug.print("Alice's position is: ({d}, {d}, {d})\n", .{ pa.vec[0], pa.vec[1], pa.vec[2] });
    std.debug.print("Bob's position is: ({d}, {d}, {d})\n", .{ pb.vec[0], pb.vec[1], pb.vec[2] });
}
