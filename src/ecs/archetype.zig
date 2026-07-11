//! an archetype, storing all objects with the same structure

const std = @import("std");
const ArrayList = std.ArrayList;
const entity = @import("entity.zig");
const Entity = entity.Entity;
const TableId = @import("Storage.zig").TalbeId;

pub const ArchetypeId = u32;
pub const ArchetypeEntity = struct {
    entity: Entity,
    // TODO : track table row here too  
};

/// TODO : meaningful comment
pub const Archetype = struct {
    id: ArchetypeId,
    /// the id of the underlying table of this archetype
    table_id: TableId,
    /// all entities in the archetype
    entities: ArrayList(ArchetypeEntity),
};

pub const Archetypes = struct {
    archetypes: ArrayList(Archetype),
    // TODO : mapping of components to archetype
    // TODO : mapping of single component to all archetypes containing it
    
    pub fn init(alloc: std.mem.Allocator) !Archetypes {
        return .{
            .archetypes = try .initCapacity(alloc, 0)
        };
    }
};
