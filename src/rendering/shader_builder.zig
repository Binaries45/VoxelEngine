//! build time code for compiling shaders to zig that can be imported

const std = @import("std");
const sokol = @import("sokol");
const Build = std.Build;

pub const Slang = packed struct(u11) {
    glsl410: bool = false,
    glsl430: bool = false,
    glsl300es: bool = false,
    glsl310es: bool = false,
    hlsl4: bool = false,
    hlsl5: bool = false,
    metal_macos: bool = false,
    metal_ios: bool = false,
    metal_sim: bool = false,
    wgsl: bool = false,
    spirv_vk: bool = false,
};

pub const ShaderOpts = struct {
    shdc_dep: ?*Build.Dependency = null,
    input: []const u8,
    output: []const u8,
    reflection: bool = false,
    slang: Slang,
};

/// given the path to some .glsl shader, generate a .zig file 
/// and write it to the output path, 
/// returns the step for building the shader
pub fn buildShader(
    b: *Build, 
    opts: ShaderOpts,
) !*Build.Step {
    const dep_sokol = b.dependency("sokol", .{});
    const dep_shdc = dep_sokol.builder.dependency("shdc", .{});

    return sokol.shdc.createSourceFile(b, .{
        .shdc_dep = dep_shdc,
        .input = opts.input,
        .output = opts.output,
        .reflection = opts.reflection,
        .slang = .{
            .glsl410 = opts.slang.glsl410,
            .glsl430 = opts.slang.glsl430,
            .glsl310es = opts.slang.glsl310es,
            .glsl300es = opts.slang.glsl300es,
            .metal_macos = opts.slang.metal_macos,
            .hlsl5 = opts.slang.hlsl5,
            .wgsl = opts.slang.wgsl,
            .spirv_vk = opts.slang.spirv_vk,
        },
    });
}
