const std = @import("std");

const table = @import("storage/table.zig");
pub const Table = table.Table;
pub const Tables = table.Tables;
pub const TalbeId = table.TableId;

pub const Column = @import("storage/Column.zig");

alloc: std.mem.Allocator,
tables: Tables,
