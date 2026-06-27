const std = @import("std");
const component = @import("component.zig");
const ArchetypeStorage = component.ArchetypeStorage;
const ComponentStorage = component.ComponentStorage;
const ErasedStorage = component.ErasedStorage;

/// entity storage for our ecs
/// the implementations is taken from here,
///     https://devlog.hexops.org/categories/build-an-ecs/
/// , but will be evolved in the future to better suit the engine and its uses
const Entities = @This();

pub const void_archetype_hash = std.math.maxInt(u64);
const Entity = u64;

alloc: std.mem.Allocator,
/// The id of the next entity to be created
next_id: u64 = 0,
entities: std.AutoHashMapUnmanaged(Entity, Pointer) = .{},
archetypes: std.AutoArrayHashMapUnmanaged(u64, ArchetypeStorage) = .{},

pub const Pointer = struct {
    arch_index: u16,
    row_index: u32,
};

pub fn init(alloc: std.mem.Allocator) !Entities {
    var entities = Entities { .alloc = alloc };

    try entities.archetypes.put(alloc, void_archetype_hash, .{
        .alloc = alloc,
        .components = .{},
        .hash = void_archetype_hash,
    });

    return entities;
}

pub fn deinit(entities: *Entities) void {
    entities.entities.deinit(entities.alloc);
    var iter = entities.archetypes.iterator();
    while(iter.next()) |e| {
        e.value_ptr.deinit();
    }
    entities.archetypes.deinit(entities.alloc);
}

pub fn initErasedStorage(self: *Entities, total_rows: *usize, comptime C: type) !ErasedStorage {
    const new_ptr = try self.alloc.create(ComponentStorage(C));
    new_ptr.* = ComponentStorage(C) { .total_rows = total_rows };

    const fns = struct {
        pub fn deinit(erased: *anyopaque, alloc: std.mem.Allocator) void {
            var ptr = ErasedStorage.cast(erased, C);
            ptr.deinit(alloc);
            alloc.destroy(ptr);
        }

        pub fn remove(erased: *anyopaque, row: u32) void {
            var ptr = ErasedStorage.cast(erased, C);
            ptr.remove(row);
        }

        pub fn cloneType(erased: ErasedStorage, rows: *usize, alloc: std.mem.Allocator, retval: *ErasedStorage) !void {
            const new_clone = try alloc.create(ComponentStorage(C));
            new_clone.* = ComponentStorage(C) { .total_rows = rows };
            var tmp = erased;
            tmp.ptr = new_clone;
            retval.* = tmp.ptr;
        }

        pub fn copy(dst_erased: *anyopaque, alloc: std.mem.Allocator, src_row: u32, dst_row: u32, src_erased: *anyopaque) !void {
            var dst = ErasedStorage.cast(dst_erased, C);
            const src = ErasedStorage.cast(src_erased, C);
            return dst.copy(alloc, src_row, dst_row, src);
        }
    };

    return ErasedStorage {
        .ptr = new_ptr,
        .deinit = fns.deinit,
        .remove = fns.remove,
        .cloneType = fns.cloneType,
        .copy = fns.copy,
    };
}

pub fn new(self: *Entities) !Entity {
    const id = self.next_id;
    self.next_id += 1;

    var void_arch = self.archetypes.getPtr(void_archetype_hash).?;
    const row = try void_arch.new(id);
    const ptr = Pointer {
        .arch_index = 0,
        .row_index = row,
    };

    self.entities.put(self.alloc, id, ptr) catch |err| {
        void_arch.undoNew();
        return err;
    };

    return id;
}