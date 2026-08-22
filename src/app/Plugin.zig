//! a plugin is a bundle of features that can be added to the app.
//! All plugins must have a function called `build`
//! which will construct and add all necessary data from the plugin to the ecs

const std = @import("std");
const App = @import("../App.zig");

const Plugin = @This();

// TODO : any plugin related stuff we need

/// checks to ensure the given plugin has the required implemenatations, causes a compile error if it does not.
pub fn validate(P: type) void {
    if (!std.meta.hasFn(P, "build")) @compileError("All plugins must have a build function");
    const build = @typeInfo(@TypeOf(@field(P, "build"))).@"fn";

    if (build.params.len != 1)
        @compileError("build is expected to have only one parameter");
    if (build.return_type != void)
        @compileError("build is expected to have a return type of void");

    const param = build.params[0];
    if (param.type != *App)
        @compileError("build is expected to take in a value of the type *App, found " ++ @typeName(param.type));
}
