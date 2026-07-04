
const std = @import("std");
const ArrayList = std.ArrayList;
const entity = @import("../entity.zig");
const Entity = entity.Entity;
const Column = @import("Column.zig");

pub const TableId = u32;

pub const Table = struct {
    /// a mapping of component ids to raw columns
    columns: std.array_hash_map.Auto(u32, Column),
    /// all entities with components in this table
    entities: ArrayList(Entity),
};

const HashCtx = struct {
    pub fn hash(_: HashCtx, k: []u32) u32 {
        const bytes = std.mem.sliceAsBytes(k);
        return std.hash.Wyhash.hash(0, bytes);
    }

    pub fn eql(_: HashCtx, a: []u32, b: []u32) bool {
        const ha = hash(a);
        const hb = hash(b);

        return ha == hb;
    }
};

/// storage for all `Table`s
pub const Tables = struct {
    tables: ArrayList(Table),
    table_ids: std.array_hash_map.Custom([]u32, TableId, HashCtx, false)
};
