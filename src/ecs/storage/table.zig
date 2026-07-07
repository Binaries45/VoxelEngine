const std = @import("std");
const ArrayList = std.ArrayList;
const entity = @import("../entity.zig");
const Entity = entity.Entity;
const ComponentId = entity.ComponentId;
const ComponentIdOf = entity.componentIdOf;
const Column = @import("Column.zig");

pub const TableId = u64;

/// soa storage for the components of some entities
pub const Table = struct {
    const ColumnMap = std.array_hash_map.Auto(ComponentId, Column);
    /// a mapping of component ids to raw columns
    columns: ColumnMap,
    /// all entities with components in this table,
    entities: ArrayList(Entity),

    /// initalize a new `Table` with space for the given components
    pub fn init(alloc: std.mem.Allocator, comptime Components: []type) !Table {
        var ids: [Components.len]ComponentId = undefined;
        inline for (Components, 0..) |C, i| ids[i] = ComponentIdOf(C);
        var columns: [Components.len]Column = undefined;
        inline for (Components, 0..) |C, i| columns[i] = try Column.init(C, alloc);

        const column_map: ColumnMap = try .init(alloc, &ids, &columns);

        return .{ .columns = column_map, .entities = try .initCapacity(alloc, 1) };
    }

    pub fn deinit(self: *Table, alloc: std.mem.Allocator) void {
        for (self.columns.values()) |*c| c.deinit(alloc);
        self.columns.deinit(alloc);
        self.entities.deinit(alloc);
    }

    /// swap remove the entity at the given row, as well as its components
    // TODO : maybe return the entity that was swapped in as the replacement
    pub fn remove(self: *Table, row: usize) void {
        if (std.debug.runtime_safety and row >= self.entities.len) @panic("row out of bounds");
        for (self.columns.values()) |*col| col.remove(row);
        self.entities.swapRemove(row);
    }

    /// get a pointer to the column corresponding to `id`
    pub fn getColumn(self: *Table, id: ComponentId) ?*Column {
        return self.columns.getPtr(id);
    }

    /// returns true if self contains a column corresponding to `id`
    pub fn hasColumn(self: *Table, id: ComponentId) bool {
        return self.columns.contains(id);
    }
};

const HashCtx = struct {
    fn sort(k: []ComponentId) []ComponentId {
        std.mem.sort(ComponentId, k, {}, std.sort.asc(ComponentId));
        return k;
    }

    pub fn hash(_: HashCtx, k: []ComponentId) u32 {
        const bytes = std.mem.sliceAsBytes(sort(k));
        return @truncate(std.hash.Wyhash.hash(0, bytes));
    }

    pub fn eql(_: HashCtx, a: []ComponentId, b: []ComponentId) bool {
        return std.mem.eql(ComponentId, sort(a), sort(b));
    }
};

/// storage for all `Table`s
pub const Tables = struct {
    tables: ArrayList(Table),
    /// a mapping of component signatures to a given table id
    table_ids: std.array_hash_map.Custom([]ComponentId, TableId, HashCtx, false),

    // todo : acutal control for adding things into tables

    // initialize and return an empty `Tables` to be populated later
    pub fn init(alloc: std.mem.Allocator) !Tables {
        return .{
            .table_ids = try .init(alloc, &.{}, &.{}),
            .tables = try .initCapacity(alloc, 0),
        };
    }
};

test "component id hashing" {
    const a = [_]ComponentId{ ComponentIdOf(u32), ComponentIdOf(f32), ComponentIdOf(*anyopaque) };
    const b = [_]ComponentId{ ComponentIdOf(*anyopaque), ComponentIdOf(u32), ComponentIdOf(f32) };

    try std.testing.expect(HashCtx.eql(.{}, @constCast(&a), @constCast(&b)));
}

test "table initialization" {
    var gpa = std.heap.DebugAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var table: Table = try .init(alloc, @constCast(&[_]type{ []const u8, u8 }));
    defer table.deinit(alloc);

    // TODO : insert some jojo part 5 characters into the table, ensure their values stay correct, remove some and check again, also try getting columns and iterating them, and checking for columns.

    // TODO : we will also need a way to allocate a row in the table, and memcpy the raw component data from a new type directly into there.
}
