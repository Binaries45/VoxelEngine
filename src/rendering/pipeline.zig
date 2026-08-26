const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const shd = @import("../shaders/triangle.glsl.zig");

const Vertex = @import("Vertex.zig");
const Mesh = @import("Mesh.zig");

/// global renderer state
pub const state = struct {
    var bind: sg.Bindings = .{};
    var pip: sg.Pipeline = .{};
};

pub export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    // create vertex buffer with triangle vertices
    state.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(Mesh.triangle.vertices),
    });

    // create a shader and pipeline object
    state.pip = sg.makePipeline(.{
        .shader = sg.makeShader(shd.triangleShaderDesc(sg.queryBackend())),
        .layout = init: {
            var l = sg.VertexLayoutState{};
            l.buffers[0].stride = @sizeOf(Vertex);

            l.attrs[shd.ATTR_triangle_position].format = .FLOAT3;
            l.attrs[shd.ATTR_triangle_position].offset = @offsetOf(Vertex, "pos");

            l.attrs[shd.ATTR_triangle_color0].format = .FLOAT4;
            l.attrs[shd.ATTR_triangle_color0].offset = @offsetOf(Vertex, "color");
            break :init l;
        },
    });
}

pub export fn frame() void {
    // default pass-action clears to grey
    sg.beginPass(.{ .swapchain = sglue.swapchain() });
    sg.applyPipeline(state.pip);
    sg.applyBindings(state.bind);
    sg.draw(0, 3, 1);
    sg.endPass();
    sg.commit();
}

pub export fn cleanup() void {
    sg.shutdown();
}
