


const std = @import("std");

const Column = @This();

/// the layout of an individual component
layout: Layout,
/// the raw component data for this column
raw: RawArray,

// todo : track things like when something is added, changed,
//        and what makes the changes. this could come in handly
//        in the future for filtering queries on only changed data

/// sotres the size of a type (may be expanded to store alignment in the future)
const Layout = struct {
    size: usize,
};

/// an array of raw component data
const RawArray = struct {
    // todo : maybe consider tracking component size and alignment
    data: []u8,
    /// the total storage capacity of the array
    capacity: usize = 0,
    /// the number of components stored in the array
    len: usize = 0,
};

/// return a column for the given type
pub fn init(comptime T: type, alloc: std.mem.Allocator) !Column {
    return .{
        .raw = .{ .data = try alloc.alloc(u8, 0) },
        .layout = .{ .size = @sizeOf(T) },
    };
}

pub fn initCapacity(comptime T: type, alloc: std.mem.Allocator, cap: usize) !Column {
    return .{
        .raw = .{
            .data = try alloc.alloc(u8, cap * @sizeOf(T)),
            .capacity = cap,
        },
        .layout = .{ .size = @sizeOf(T) },
    };
}

pub fn deinit(self: Column, alloc: std.mem.Allocator) void {
    alloc.free(self.raw.data);
}

fn grow(self: *Column, alloc: std.mem.Allocator) !void {
    const capacity = @max(self.raw.capacity * 2, 1);
    const size = self.layout.size;

    if (self.raw.capacity == 0) {
        self.raw.data = try alloc.alloc(u8, capacity * size);
    } else {
        self.raw.data = try alloc.realloc(self.raw.data, capacity * size);
    }

    self.raw.capacity = capacity;
}

/// append raw bytes to the column
pub fn appendRaw(self: *Column, alloc: std.mem.Allocator, bytes: []const u8) !void {
    const size = self.layout.size;
    if (std.debug.runtime_safety) {
        if (bytes.len != size) @panic("byte length does not match component size");
    }
    if (self.raw.len >= self.raw.capacity) try self.grow(alloc);
    const offset = self.raw.len * size;
    @memcpy(self.raw.data[offset .. offset + size], bytes);
    self.raw.len += 1;
}

/// append a new element to the column
pub fn append(self: *Column, comptime T: type, alloc: std.mem.Allocator, value: T) !void {
    const bytes = std.mem.asBytes(&value);
    try self.appendRaw(alloc, bytes);
}

/// swap remove an element from the column
pub fn remove(self: *Column, i: usize) void {
    const size = self.layout.size;
    const pos = size * i;
    if (i != self.raw.len - 1) {
        const src = (self.raw.len - 1) * size;
        @memcpy(self.raw.data[pos..pos + size], self.raw.data[src..src + size]);
        @memset(self.raw.data[src..src + size], undefined);
    }
    self.raw.len -= 1;
}

/// get a value of the speciified type at the given index
pub fn get(self: *Column, comptime T: type, i: usize) T {
    const offset = self.layout.size * i;
    return std.mem.bytesToValue(T, &self.raw.data[offset]);
}

/// get a pointer to the value at index `i`
pub fn getPtr(self: *const Column, comptime T: type, i: usize) *T {
    const offset = self.layout.size * i;
    return @ptrCast(@alignCast(&self.raw.data[offset]));
}

test "Column" {
    var gpa = std.heap.DebugAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    
    var col = try Column.initCapacity(u32, alloc, 1);    
    defer col.deinit(alloc);

    try col.append(u32, alloc, 42);
    try col.append(u32, alloc, 21);

    try std.testing.expect(col.raw.capacity == 2);
    try std.testing.expect(col.raw.len == 2);

    try std.testing.expect(col.get(u32, 0) == 42);
    try std.testing.expect(col.getPtr(u32, 1).* == 21);

    col.remove(0);

    try std.testing.expect(col.raw.len == 1);
    try std.testing.expect(col.raw.capacity == 2);

    try std.testing.expect(col.get(u32, 0) == 21);
}
