const std = @import("std");

// todo : build as library (for when things are working)
pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("VoxelEngine", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    const zflecs = b.dependency("zflecs", .{
        .target = target,
        .optimize = optimize,
    });
    const zflecs_mod = zflecs.module("root");
    mod.addImport("zflecs", zflecs_mod);

    // idk if this is needed for others,
    // but I get a fuck ton of linker errors on my machine
    // when not linking these explicitly
    mod.linkSystemLibrary("asound", .{});
    mod.linkSystemLibrary("GL", .{});
    mod.linkSystemLibrary("X11", .{});
    mod.linkSystemLibrary("Xi", .{});
    mod.linkSystemLibrary("Xcursor", .{});

    const dep_sokol = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
    });

    const mod_sokol = dep_sokol.module("sokol");

    mod.addImport("sokol", mod_sokol);


    const exe = b.addExecutable(.{
        .name = "VoxelEngine",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "VoxelEngine", .module = mod },
            },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
