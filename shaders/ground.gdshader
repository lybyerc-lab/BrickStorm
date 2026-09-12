// [BS:RENDER:GROUND]
// Purpose: The ground: Oklahoma farmland, sculpted-looking, and NOT a brick.
// Invariants:
// - THE GROUND IS NOT SMASHABLE, SO IT IS NOT PLASTIC. North Star pillar 1 was
//   revised by director decision on 2026-09-10: whatever breaks is brick-built,
//   whatever does not is free. This replaced a 420m studded baseplate, and
//   losing that baseplate is the point rather than a regression. In the demo,
//   minifigs and vehicles read as moulded plastic precisely BECAUSE they sit
//   against sculpted rock and plaster that are not. Ours was plastic all the
//   way down, so nothing had anything to read against.
// - IT IS A SECTION GRID, AND THAT IS THE WHOLE POINT OF THIS FILE. The
//   director's note on the first hybrid build was that it did not scream
//   Oklahoma - and it did not: one continuous lawn-green field with random
//   patches on it reads as English countryside, or a golf course. The Great
//   Plains are surveyed on a grid, so the land is enormous geometric blocks of
//   DIFFERENT crops, separated by dead-straight dirt roads, with the plough
//   rows running visibly across each block. That geometry is the single
//   strongest signal of where this is, and it costs one fragment function.
// - THE PALETTE IS WHEAT, SAGE AND RED DIRT, not grass. Oklahoma's soil is
//   famously red, and storm season is gold stubble and dust. Emerald green is
//   the wrong continent.
// - PROCEDURAL, SO IT DOES NOT RUN OUT. The crop squares this replaces were
//   sixteen meshes scattered once within 150m of the origin, while the storm
//   travels 600m - so the back two thirds of every round was featureless. A
//   world-locked function has no such edge.
// - THE FINE GRAIN FADES WITH DISTANCE. Up close it is the point; at 150m it is
//   aliasing, and a shimmering horizon is the artefact TT kill with their LOD
//   factor. Same lesson the baseplate's studs taught.
shader_type spatial;

// The ground has HEIGHT, and this is the only place the mesh learns it. The
// same function places the collider, the props and the studs from
// scripts/terrain.gd; tools/terrain_probe.gd gates the two against each other,
// because a formula living in two languages has no other way to be checked.
#include "res://shaders/ground_height.gdshaderinc"

// Desaturated but NOT darkened. An early pass took saturation out by lowering
// value with it and the frame median fell from 93 to 66 - the one thing pillar
// 2 forbids outright. Colourfulness comes down; brightness stays.
uniform vec3 wheat_color : source_color = vec3(0.80, 0.70, 0.40);
uniform vec3 stubble_color : source_color = vec3(0.72, 0.65, 0.47);
uniform vec3 corn_color : source_color = vec3(0.51, 0.61, 0.34);
uniform vec3 pasture_color : source_color = vec3(0.60, 0.63, 0.42);
uniform vec3 dirt_color : source_color = vec3(0.67, 0.45, 0.33);
uniform vec3 road_color : source_color = vec3(0.70, 0.53, 0.40);

uniform float field_pitch = 48.0;
uniform float road_width = 4.5;
uniform float fade_start = 45.0;
uniform float fade_end = 150.0;
uniform float p_roughness : hint_range(0.0, 1.0) = 0.72;
uniform float p_specular : hint_range(0.0, 1.0) = 0.20;

varying vec3 v_world;


float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}


float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}


float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 3; i++) {
		v += vnoise(p) * amp;
		p *= 2.03;
		amp *= 0.5;
	}
	return v;
}


// Which crop is planted in this section. Five kinds, so neighbouring blocks
// rarely match and the grid reads as a patchwork rather than a chessboard.
vec3 crop_of(vec2 cell) {
	float r = hash21(cell + 3.17);
	if (r < 0.30) {
		return wheat_color;
	} else if (r < 0.50) {
		return corn_color;
	} else if (r < 0.70) {
		return stubble_color;
	} else if (r < 0.87) {
		return pasture_color;
	}
	return dirt_color;                       // ploughed and bare
}


void vertex() {
	// Displace in WORLD space. The mesh slides under the player, so its model
	// origin moves; sampling by world position is what keeps the hills nailed
	// to the ground instead of travelling with the player.
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	w.y = bs_ground_h(w.xz);
	v_world = w;
	VERTEX = (inverse(MODEL_MATRIX) * vec4(w, 1.0)).xyz;

	// Normal from finite differences of the same function, so the lighting can
	// never disagree with the shape the way a hand-derived gradient can.
	float e = 2.0;
	float hx = bs_ground_h(w.xz + vec2(e, 0.0)) - bs_ground_h(w.xz - vec2(e, 0.0));
	float hz = bs_ground_h(w.xz + vec2(0.0, e)) - bs_ground_h(w.xz - vec2(0.0, e));
	NORMAL = normalize(vec3(-hx, 2.0 * e, -hz));
}


void fragment() {
	vec2 w = v_world.xz;
	float dist = length(v_world - CAMERA_POSITION_WORLD);
	float near = 1.0 - clamp((dist - fade_start) / (fade_end - fade_start), 0.0, 1.0);

	// Offset by half a pitch so the section roads fall at +/-24m rather than
	// through the origin. The storm runs down x = 0, and a road there would be
	// destroyed on every pass and never seen intact; off-centre, the player
	// travels a field with a road and its power line to either side.
	vec2 cell = floor((w + field_pitch * 0.5) / field_pitch);
	vec2 inside = (w + field_pitch * 0.5) - cell * field_pitch;

	// The section roads: a dirt strip along both edges of every block.
	float half_road = road_width * 0.5;
	float edge = min(min(inside.x, field_pitch - inside.x),
					 min(inside.y, field_pitch - inside.y));
	float on_road = 1.0 - smoothstep(half_road - 1.2, half_road + 0.4, edge);

	vec3 crop = crop_of(cell);

	// PLOUGH ROWS. Each block is worked in one of two directions, and the rows
	// are what make a field read as farmed rather than as a coloured rectangle.
	float dir = step(0.5, hash21(cell + 9.61));
	float along = mix(inside.x, inside.y, dir);
	float rows = sin(along * 6.2831853 / 1.6);
	crop *= 1.0 + rows * 0.055 * near;

	// Headland: the turned, scruffier margin where the machinery comes about.
	float headland = 1.0 - smoothstep(half_road, half_road + 5.0, edge);
	crop = mix(crop, mix(crop, dirt_color, 0.45), headland * 0.6);

	vec3 base = mix(crop, road_color, on_road);

	// Tonal break-up, in VALUE not hue, so the surface stops being one flat
	// tone without the palette drifting.
	float mottle = fbm(w * 0.62) - 0.5;
	float grain = (vnoise(w * 5.7) - 0.5) * near;
	base *= 1.0 + mottle * 0.22 + grain * 0.12;

	ALBEDO = clamp(base, vec3(0.0), vec3(1.0));
	ROUGHNESS = p_roughness;
	SPECULAR = p_specular;
	METALLIC = 0.0;
	// No rim term. A grazing-angle response on a 420m plane lights the entire
	// horizon, which is the specular blowout already recorded for terrain_mat.
	RIM = 0.0;
}
// [BS:RENDER:GROUND:END]
