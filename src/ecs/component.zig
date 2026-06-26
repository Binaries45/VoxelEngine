const std = @import("std");

/// todo : meaningful comment
pub fn ComponentStorage(comptime T: type) type {
    return struct {
        total_rows: *usize,
        data: std.ArrayList(T) = .empty,

        const Self = @This();

        pub fn deinit(self: Self, alloc: std.mem.Allocator) void {
            self.data.deinit(alloc);
        }

        pub fn set(self: *Self, alloc: std.mem.Allocator, row: u32, value: T) error{OutOfMemory}!void {
            if (self.data.items.len <= row)
                try self.data.appendNTimes(alloc, undefined, self.data.items.len + 1 - row);
            self.data.items[row] = value;
        }

        pub fn remove(self: *Self, row: u32) void {
            if (self.data.items.len > row) _ = self.data.swapRemove(row);
        }

        pub inline fn get(self: Self, row: u32) T {
            return self.data.items[row];
        }

        pub inline fn copy(dst: *Self, allocator: std.mem.Allocator, src_row: u32, dst_row: u32, src: *Self) error{OutOfMemory}!void {
            try dst.set(allocator, dst_row, src.get(src_row));
        }
    };
}

/// type erased component storage
pub const ErasedStorage = struct {
    ptr: *anyopaque,

    deinit: fn(self: *anyopaque, alloc: std.mem.Allocator) void,
    remove: fn(self: *anyopaque, row: u32) void,
    cloneType: fn(self: *anyopaque, alloc: std.mem.Allocator) error{OutOfMemory}!void,
    copy: fn(dst: *anyopaque, alloc: std.mem.Allocator, src_row: u32, dst_row: u32, src: *anyopaque) error{OutOfMemory}!void,

    /// cast ErasedStorage into ComponentStorage(T)
    pub fn cast(ptr: *anyopaque, comptime T: type) *ComponentStorage(T) {
        return @ptrCast(@alignCast(ptr));
    }
};

/// todo : meaningful comment
pub const ArchetypeStorage = struct {
    alloc: std.mem.Allocator,
    /// the hash of all components making up this archetype
    hash: u64,
    /// a mapping of table rows to entity ids,
    /// which also serves as a counter for the
    /// total number of rows reserved in the archetype table
    entities: std.ArrayList(u64) = .empty,
    /// a mapping of component name -> type-erased *ComponentStorage(Component)
    components: std.StringArrayHashMapUnmanaged(ErasedStorage),

    /// compute the hash of self
    pub fn calculateHash(self: *ArchetypeStorage) void {
        self.hash = 0;
        var iter = self.components.iterator();
        while (iter.next()) |e| {
            const name = e.key_ptr.*;
            self.hash ^= std.hash_map.hashString(name);
        }
    }

    pub fn deinit(self: *ArchetypeStorage) void {
        for(self.components.values()) |erased| {
            erased.deinit(erased.ptr, self.alloc);
        }
        self.entities.deinit(self.alloc);
        self.components.deinit(self.alloc);
    }

    /// reserve a new row for the given entity,
    /// returning the row index on success
    pub fn new(self: *ArchetypeStorage, entity: u64) !u32 {
        const index = self.entities.items.len;
        try self.entities.append(self.alloc, entity);
        return @intCast(index);
    }

    /// removes the last added entity, undoing the effect of new()
    pub fn undoNew(self: *ArchetypeStorage) void {
        _ = self.entities.pop();
    }

    pub fn set(self: *ArchetypeStorage, row: u32, name: []const u8, component: anytype) !void {
        const erased = self.components.get(name).?;
        var storage = ErasedStorage.cast(erased.ptr, @TypeOf(component));
        try storage.set(self.alloc, row, component);
    }

    pub fn remove(self: *ArchetypeStorage, row: u32) !void {
        _ = self.entities.swapRemove(row);
        for(self.components.values()) |c| {
            c.remove(c.ptr, row);
        }
    }
};
