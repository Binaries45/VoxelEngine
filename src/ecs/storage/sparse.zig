
const std = @import("std");
const ArrayList = std.ArrayList;

/// todo : the rest of the impl lol, this might not be needed anyways
pub fn SparseSet(comptime V: type) type {
    return struct {
        /// mapping from a dense index to a value
        ///
        /// dense[sparse[i]] == value for 'i'
        dense: ArrayList(V),
    };
}
