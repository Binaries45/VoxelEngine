//! The world in which all of our entities live

const std = @import("std");
const Storage = @import("Storage.zig");
const Components = @import("Components.zig");
const archetype = @import("archetype.zig");
const Archetype = archetype.Archetype;
const Archetypes = archetype.Archetypes;

// TODO : entities
// TODO : resources
// TODO : bundles
// ...
alloc: std.mem.Allocator,
components: Components,
storage: Storage,
archetypes: Archetypes,

/// initialize a new world
pub fn init(alloc: std.mem.Allocator) !@This() {
    return .{
        .alloc = alloc,
        .storage = try .init(alloc),
        .components = try .init(alloc),
        .archetypes = try .init(alloc),
    };
}
