
const std = @import("std");

const Column = @This();

/// the raw component data for this column
raw: RawArray,

// todo : track things like when something is added, changed,
//        and what makes the changes. this could come in handly
//        in the future for filtering queries on only changed data

/// an array of raw component data
const RawArray = struct {
    // todo : maybe consider tracking component size and alignment
    data: []u8,
    /// the number of components in the array
    length: usize = 0,
    /// the total storage capacity of the array
    capacity: usize = 0,
    // todo : append, remove and other ops
};
