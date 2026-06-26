const std = @import("std");
const Io = std.Io;

const ve = @import("VoxelEngine");

pub fn main(init: std.process.Init) !void {
    var app = ve.App.init(init.arena.allocator());
    try app.run();
}