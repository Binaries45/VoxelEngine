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
    return struct {
        entities: std.ArrayList(usize) = .empty,
        data: std.MultiArrayList(T) = .empty,

        pub fn deinit(self: *@This(), alloc: std.mem.Allocator) void {
            self.entities.deinit(alloc);
            self.data.deinit(alloc);
        }
    };
}

/// generate an archetype key, which is a hash of all type ids in the given bundle B
pub fn key(comptime B: type) usize {
    if (@typeInfo(B) != .@"struct") @compileError("expected struct type");
    const info = @typeInfo(B).@"struct";

    comptime var seen: [info.fields.len]type = undefined;
    comptime var count: usize = 0;

    var k: usize = 0;
    inline for(info.fields) |f| {
        comptime {
            for(seen[0..count]) |s| {
                if (s == f.type) @compileError(
                    "Bundle cannot have multiple fields of the same type"
                );
            }
            seen[count] = f.type;
            count += 1;
        }
        k ^= typeId(f.type);
    }
    return k;
}

test "archetype keys" {
    const a = .{
        @as(u8, 42),
        @as(f32, 3.14),
    };

    const b = .{
        @as(f32, 2.718),
        @as(u8, 21),
    };

    const c = .{
        @as([]const u8, "hello"),
        @as(u8, 100),
    };

    const key_a = key(@TypeOf(a));
    const key_b = key(@TypeOf(b));
    const key_c = key(@TypeOf(c));

    try std.testing.expect(key_a == typeId(u8) ^ typeId(f32));
    try std.testing.expect(key_a == key_b);
    try std.testing.expect(key_a != key_c);
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