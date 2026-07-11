const std = @import("std");
const ArrayList = std.ArrayList;
const entity = @import("../entity.zig");
const Entity = entity.Entity;
const ComponentId = @import("../Components.zig").ComponentId;
const componentIdOf = @import("../Components.zig").componentIdOf;
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
        inline for (Components, 0..) |C, i| ids[i] = componentIdOf(C);
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

    /// swap remove the entity at the given row, as well as its components,
    /// returns the entity that was swapped into row, or null if no swap was made;
    pub fn remove(self: *Table, row: usize) ?Entity {
        if (std.debug.runtime_safety and row >= self.entities.items.len) @panic("row out of bounds");
    
        for (self.columns.values()) |*col| col.remove(row);
        
        _ = self.entities.swapRemove(row);

        if (row < self.entities.items.len) return self.entities.items[row];

        return null;
    }

    /// get a pointer to the column corresponding to `id`
    pub fn getColumn(self: *Table, id: ComponentId) ?*Column {
        return self.columns.getPtr(id);
    }

    /// returns true if self contains a column corresponding to `id`
    pub fn hasColumn(self: *Table, id: ComponentId) bool {
        return self.columns.contains(id);
    }

    /// append a new bundle to the table, returning the location of the entity within the table
    pub fn addRow(self: *Table, alloc: std.mem.Allocator, entity_id: Entity, bundle: anytype) !usize {
        const BT = @TypeOf(bundle);
        const info = @typeInfo(BT);
        if (info != .@"struct") @compileError("expected struct type");

        const index = self.entities.items.len;

        inline for (info.@"struct".fields) |f| {
            const CT = f.type;
            const id = componentIdOf(CT);

            const col = self.getColumn(id) orelse @panic("Table does not support components of type " ++ @typeName(CT));
            try col.append(CT, alloc, @field(bundle, f.name));
        }

        try self.entities.append(alloc, entity_id);
        return index;
    }

    /// get the full data for some given entity
    pub fn getData(self: *Table, comptime T: type, row: usize) ?T {
        const info = @typeInfo(T);
        if (info != .@"struct") @compileError("expected struct type");

        var res: T = undefined;

        inline for (info.@"struct".fields) |f| {
            const id = componentIdOf(f.type);
            const col = self.getColumn(id) orelse @panic("attempted to get type not contained by table: " ++ @typeName(f.type));
            @field(res, f.name) = col.get(f.type, row) orelse return null;
        }
        
        return res;
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

    // initialize and return an empty `Tables` to be populated later
    pub fn init(alloc: std.mem.Allocator) !Tables {
        return .{
            .table_ids = try .init(alloc, &.{}, &.{}),
            .tables = try .initCapacity(alloc, 0),
        };
    }
};

test "component id hashing" {
    const a = [_]ComponentId{ componentIdOf(u32), componentIdOf(f32), componentIdOf(*anyopaque) };
    const b = [_]ComponentId{ componentIdOf(*anyopaque), componentIdOf(u32), componentIdOf(f32) };

    try std.testing.expect(HashCtx.eql(.{}, @constCast(&a), @constCast(&b)));
}

test "table initialization" {
    var gpa = std.heap.DebugAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var table: Table = try .init(alloc, @constCast(&[_]type{ []const u8, u8 }));
    defer table.deinit(alloc);

    _ = try table.addRow(alloc, @bitCast(@as(u64, 0)), .{
        @as([]const u8, "Bruno Bucciarati"),
        @as(u8, 20),
    });

    _ = try table.addRow(alloc, @bitCast(@as(u64, 0)), .{
        @as([]const u8, "Leone Abacchio"),
        @as(u8, 21),
    });

    _ = try table.addRow(alloc, @bitCast(@as(u64, 0)), .{
        @as([]const u8, "Panacotta Fugo"),
        @as(u8, 16),
    });

    const Person = struct {
        name: []const u8,
        age: u8,
    };

    const bucciarati = table.getData(Person, 0) orelse unreachable;
    const abacchio = table.getData(Person, 1) orelse unreachable;
    const fugo = table.getData(Person, 2) orelse unreachable;

    try std.testing.expect(std.mem.eql(u8, bucciarati.name, "Bruno Bucciarati"));
    try std.testing.expect(bucciarati.age == 20);
    try std.testing.expect(std.mem.eql(u8, abacchio.name, "Leone Abacchio"));
    try std.testing.expect(abacchio.age == 21);
    try std.testing.expect(std.mem.eql(u8, fugo.name, "Panacotta Fugo"));
    try std.testing.expect(fugo.age == 16);

    _ = table.remove(1); // Diavolo was here

    const bucciarati2 = table.getData(Person, 0) orelse unreachable;    
    const fugo2 = table.getData(Person, 1) orelse unreachable;    
    try std.testing.expect(std.mem.eql(u8, bucciarati2.name, "Bruno Bucciarati"));
    try std.testing.expect(bucciarati2.age == 20);
    try std.testing.expect(std.mem.eql(u8, fugo2.name, "Panacotta Fugo"));
    try std.testing.expect(fugo2.age == 16);
}
