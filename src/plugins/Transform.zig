const App = @import("../App.zig");
const math = @import("../math.zig");
const Vector = math.Vector;
const Quaternion = math.Quaternion;
const Vec = Vector.Vec;
const Quat = Quaternion.Quat;

pub const Transform = struct {
    translation: Vec(3, f32),
    rotation: Quat(f32),
    scale: Vec(3, f32),
};

pub fn build(app: *App) void {
    app.addComponents(.{ Transform });  
}
