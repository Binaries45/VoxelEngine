//! the world in which our entities live, responsible for handling
//! all component & resource related data

// we will store archetypes as AutoArrayHashMap mapping ArchetypeKey -> *anyopaque,
// and then using the type id to cast the pointer into the correct archetype

const std = @import("std");

// todo : track entities and their location in the archetype tables

/// archetype storage, mapping ArchetypeKey -> *anyopaque,
/// where *anyopaque is of the type *Archetype().
archetypes: std.AutoArrayHashMapUnmanaged(usize, *anyopaque),