const std = @import("std");
const Io = std.Io;

const VoxelEngine = @import("VoxelEngine");

pub fn main(init: std.process.Init) !void {
     _ = init;
    std.debug.print("hello, World!", .{});
}