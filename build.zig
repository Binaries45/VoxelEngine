const std = @import("std");

const sokol = @import("sokol");

const Shader = struct {
    name: []const u8,
    has_shader: bool = false,
    needs_compute: bool = false,
};

// todo : more dynamic shader detection and compilation
const shaders = [_]Shader{
    .{ .name = "triangle", .has_shader = true },
};

/// build all shaders defined in the shaders constant to their own module
/// and add it as an import to the given module
fn build_shaders(b: *std.Build, dep_sokol: *std.Build.Dependency, mod: *std.Build.Module) !void {
    const mod_sokol = dep_sokol.module("sokol");
    const dep_shdc = dep_sokol.builder.dependency("shdc", .{});

    for (shaders) |shader| {
        if (!shader.has_shader) continue;

        const input_path = b.fmt("src/shaders/{s}.glsl", .{shader.name});
        const output_path = b.fmt("shader_{s}.glsl.zig", .{shader.name});

        const shd_mod = try sokol.shdc.createModule(b, shader.name, mod_sokol, .{
            .shdc_dep = dep_shdc,
            .input = input_path,
            .output = output_path,
            .slang = .{ .hlsl5 = true, },
        });

        mod.addImport(output_path, shd_mod);
    }
}

// todo : build as library (for when things are working)
pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const mod = b.addModule("VoxelEngine", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    const dep_sokol = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
        // todo : add this (we will need to get our own cimgui impl)
        // .with_sokol_imgui = true,
    });
    const mod_sokol = dep_sokol.module("sokol");
    mod.addImport("sokol", mod_sokol);

    const zflecs = b.dependency("zflecs", .{
        .target = target,
        .optimize = optimize,
    });
    const zflecs_mod = zflecs.module("root");
    mod.addImport("zflecs", zflecs_mod);

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

    try build_shaders(b, dep_sokol, mod);
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
