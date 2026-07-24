//! a plugin is a bundle of features that can be added to the app.
//! All plugins must have a function called `build`
//!  which will construct and add all necessary data from the plugin to the ecs

const std = @import("std");

const Plugin = @This();

// TODO : any plugin related stuff we need

/// checks to ensure the given plugin has the required implemenatations, causes a compile error if it does not.
pub fn validate(comptime plugin: anytype) void {
    if (!std.meta.hasFn(@TypeOf(plugin), "build")) @compileError("All plugins must have a build function");    
    // TODO : ensure build has the right signature, taking in a pointer to the app
}
