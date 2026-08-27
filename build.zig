const std = @import("std");
const builtin = @import("builtin");
const shader_build = @import("./src/rendering/shader_builder.zig");

// todo : build as library (for when things are working)
pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("VoxelEngine", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    // ECS --------------------------------------
    const zflecs = b.dependency("zflecs", .{
        .target = target,
        .optimize = optimize,
    });
    const zflecs_mod = zflecs.module("root");
    mod.addImport("zflecs", zflecs_mod);
    // ------------------------------------------

    // SOKOL ------------------------------------
    // idk if this is needed for others,
    // but I get a fuck ton of linker errors on my machine
    // when not linking these explicitly

    
    if (builtin.os.tag == .linux) {
        mod.linkSystemLibrary("asound", .{});
        mod.linkSystemLibrary("GL", .{});
        mod.linkSystemLibrary("X11", .{});
        mod.linkSystemLibrary("Xi", .{});
        mod.linkSystemLibrary("Xcursor", .{});
    }

    const dep_sokol = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
    });

    const mod_sokol = dep_sokol.module("sokol");

    mod.addImport("sokol", mod_sokol);
    // ------------------------------------------

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

    // BUILD SHADERS ----------------------------
    const buildShader = shader_build.buildShader;

    const shaders: []const []const u8 = &.{
        "triangle",
        "cube",
    };

    for (shaders) |s| {
        exe.step.dependOn(try buildShader(b, .{
            .input = b.fmt("src/shaders/{s}.glsl", .{s}),
            .output = b.fmt("src/shaders/{s}.glsl.zig", .{s}),
            .reflection = true,
            .shdc_dep = b.dependency("shdc", .{}),
            .slang = .{
                .glsl410 = true,
                .metal_macos = true,
                .hlsl5 = true,
                .wgsl = true,
                .spirv_vk = true,  
            },
        }
        )); 
    }

    // ------------------------------------------

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
