const std = @import("std");
const component = @import("component.zig");
const ArchetypeStorage = component.ArchetypeStorage;

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

