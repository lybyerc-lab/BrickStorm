// Emits the DIFFERENCE between the GPU's ground height at one world point and
// a CPU-supplied height, amplified, so an 8-bit framebuffer can resolve a
// disagreement of millimetres.
//
// The first version of this encoded absolute height into greyscale over a 16m
// range. That is 0.063m per code at best and 0.25m in practice once the
// framebuffer's transfer curve is taken into account - so dropping an entire
// term from the height function moved the worst sample by only 0.672m and
// PASSED a 0.75m tolerance. Measuring the residual instead of the value makes
// the encoding's precision irrelevant.
shader_type spatial;
render_mode unshaded, cull_disabled;

#include "res://shaders/ground_height.gdshaderinc"

uniform vec2 probe_point = vec2(0.0, 0.0);
uniform float cpu_h = 0.0;
uniform float gain = 20.0;

void fragment() {
	float d = bs_ground_h(probe_point) - cpu_h;
	ALBEDO = vec3(clamp(0.5 + d * gain, 0.0, 1.0));
}
