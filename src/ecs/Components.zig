//! TODO : meaningful comment

const std = @import("std");
const ArrayList = std.ArrayList;
const entity = @import("entity.zig");

/// a mapping of ComponentId -> ComponentInfo
components: ArrayList(?ComponentInfo),

pub const ComponentId = u32;
var next_id: u32 = 0;

/// returns the component id corresponding to a bit to be set in the TypeId
pub fn componentIdOf(comptime T: type) ComponentId {
    const S = struct {
        const t = T;
        var id: ?ComponentId = null;
    };
    if (S.id) |id| return id;
    const id = next_id;
    if (next_id > 128) @panic("too many components!");
    next_id += 1;
    S.id = id;
    return id;
}

/// information regarding a given component
pub const ComponentInfo = struct {
    id: ComponentId,

    pub fn fromType(comptime T: type) ComponentInfo {
        return .{
            .id = componentIdOf(T),
        };
    }
};

/// initialize an empty `Components` 
pub fn init(alloc: std.mem.Allocator) !@This() {
    return .{
        .components = try .initCapacity(alloc, 0),
    };
}

/// add some component info to self
pub fn addInfo(self: *@This(), alloc: std.mem.Allocator, info: ComponentInfo) !void {
    if (info.id >= self.components.len) {
        const diff = (info.id - self.components.len) + 1;
        self.components.appendNTimes(alloc, null, diff);
    }
    self.components.items[info.id] = info;
}

/// get the component info of a given type
pub fn infoOf(self: *@This(), comptime T: type) ?ComponentInfo {
    const id = componentIdOf(T);
    std.debug.assert(id < self.components.len);
    return self.components.items[id];
}

/// get the component info of a given component id
pub fn infoOfId(self: *@This(), id: ComponentId) ?ComponentInfo {
    std.debug.assert(id < self.components.items.len);
    return self.components.items[id];
}
