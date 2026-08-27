const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const shd = @import("../shaders/cube.glsl.zig");

const math = @import("../math.zig");
const Matrix = math.Matrix;
const Vector = math.Vector;
const fMat4 = math.fMat4;

const Vertex = @import("Vertex.zig");
const Mesh = @import("Mesh.zig");

/// global renderer state
pub const state = struct {
    var bind: sg.Bindings = .{};
    var pip: sg.Pipeline = .{};
    var rx: f32 = 0.0;
    var ry: f32 = 0.0;
    var pass_action: sg.PassAction = .{};
    const view: math.fMat4 = Matrix.lookat(.{ 0.0, 1.5, 6.0 }, @splat(0.0), .{ 0.0, 1.0, 0.0 });
};

pub export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    // create vertex buffer with triangle vertices
    state.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(Mesh.cube.vertices),
    });

    state.bind.index_buffer = sg.makeBuffer(.{
        .usage = .{ .index_buffer = true },
        .data = sg.asRange(Mesh.cube.indices.?),
    });

    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.2, .a = 1.0 },
    };

    // create a shader and pipeline object
    state.pip = sg.makePipeline(.{
        .shader = sg.makeShader(shd.cubeShaderDesc(sg.queryBackend())),
        .layout = init: {
            var l = sg.VertexLayoutState{};
            l.buffers[0].stride = @sizeOf(Vertex);

            l.attrs[shd.ATTR_cube_position].format = .FLOAT3;
            l.attrs[shd.ATTR_cube_position].offset = @offsetOf(Vertex, "pos");

            l.attrs[shd.ATTR_cube_color0].format = .FLOAT4;
            l.attrs[shd.ATTR_cube_color0].offset = @offsetOf(Vertex, "color");
            break :init l;
        },
        .index_type = .UINT32,
        .depth = .{
            .compare = .LESS_EQUAL,
            .write_enabled = true,
        },
        .cull_mode = .BACK,
        .face_winding = .CCW,
    });
}

pub export fn frame() void {
    // default pass-action clears to grey
    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });
    sg.applyPipeline(state.pip);
    sg.applyBindings(state.bind);
    const dt: f32 = @floatCast(sapp.frameDuration() * 60);
    state.rx += 1.0 * dt;
    state.ry += 2.0 * dt;
    const vs_params = computeVsParams(state.rx, state.ry);
    sg.applyUniforms(shd.UB_vs_params, sg.asRange(&vs_params));
    sg.draw(0, Mesh.cube.indices.?.len, 1);
    sg.endPass();
    sg.commit();
}

pub export fn cleanup() void {
    sg.shutdown();
}

fn computeVsParams(rx: f32, ry: f32) shd.VsParams {
    const rxm = Matrix.rotate(f32, rx, .{ 1.0, 0.0, 0.0 });
    const rym = Matrix.rotate(f32, ry, .{ 0.0, 1.0, 0.0 });
    const model = Matrix.mul(rxm, rym);
    const aspect = sapp.widthf() / sapp.heightf();
    const proj = Matrix.perspective(60.0, aspect, 0.01, 10.0);
    const mvp = Matrix.mul(Matrix.mul(proj, state.view), model);
    return shd.VsParams{ .mvp = @bitCast(mvp) };
}
