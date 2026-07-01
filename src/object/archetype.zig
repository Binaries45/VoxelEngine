//! an archetype, storing all objects with the same structure:
//!
//! ```
//! const Name = []const u8;
//! // given the above definition of name, the following
//! // two types would be stored under the same archetype
//! const Thing1 = struct {
//!     name: Name
//! };
//!
//! const Thing2 = struct {
//!     name: []const u8
//! };
//! ```

const std = @import("std");
const typeId = @import("object.zig").typeId;

// given the type of some component bundle,
// construct an archetype storing the component data
pub fn Archetype(comptime T: type) type {
    const has_fields = @typeInfo(T).@"struct".fields.len > 0;
    const ST = if (has_fields) T else struct {_pad: u0 = 0};

    return struct {
        /// all component data
        data: std.MultiArrayList(ST) = .empty,
        /// the current generation of `data[i]`.
        /// when `data[i]` is freed and then reused, this value is incremented
        generations: std.ArrayList(u16) = .empty,
        /// trackes whether data[i] is free or not
        freed: std.DynamicBitSetUnmanaged = .{},

        pub fn deinit(self: *@This(), alloc: std.mem.Allocator) void {
            self.data.deinit(alloc);
            self.generations.deinit(alloc);
            self.freed.deinit(alloc);
        }

        
    };
}

test "archetypes" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const Player = struct {
        name: []const u8,
        age: u8,
    };

    var arch: Archetype(Player) = .{};
    defer arch.deinit(alloc);
    try arch.data.append(alloc, .{
        .name = "Josuke Higashikata",
        .age = 19,
    });

    try std.testing.expect(std.mem.eql(u8, arch.data.get(0).name, "Josuke Higashikata"));
    try std.testing.expect(arch.data.get(0).age == 19);
}
