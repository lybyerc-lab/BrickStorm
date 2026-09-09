// The material every brick in the world draws through, and the wind that
// moves the ones that are supposed to move.
//
// Two jobs in one shader because they have to share a material: the plastic
// look (see BrickLib.apply_plastic - the values come from there, so there is
// still ONE definition) and the vertex wind (see Docs/TT_ENGINE_NOTES.md 12).
//
// BEND IS PER BRICK, IN THE INSTANCE COLOUR'S ALPHA. Zero means rigid, which
// is every building, fence and vehicle in the game. Foliage is authored with
// bend rising toward the tips, exactly as TT paint it into their plant meshes.
// A brick displaces RIGIDLY - it is a LEGO brick, it does not shear.
// [BS:RENDER:WIND]
// Purpose: The vertex wind that moves foliage, and nothing else.
// Invariants:
// - BEND IS PER BRICK, IN THE INSTANCE COLOUR'S ALPHA. Zero means rigid, which
//   is every building, fence and vehicle in the game. Only foliage is authored
//   with a bend weight, and it rises toward the tips.
// - A brick displaces RIGIDLY. It is a LEGO brick; it does not shear.
// - THE STORM HERE MUST BE THE STORM IN Tornado.wind_at. Same shape, same
//   constants, passed in rather than retyped. If they diverge the foliage
//   leans one way while the player is pushed another and the world stops
//   being one place. --selftest asserts they agree.
// - The storm's field is a function of position ALONE, so on its own it leans
//   a plant over and holds it there. Turbulence scaled by local wind magnitude
//   is what turns a lean into motion - nothing on a calm day, violent at the
//   funnel. tools/wind_probe.gd measures it and fails if the storm moves
//   foliage less than twice as far as the breeze does.
// - The ambient breeze is sampled in WORLD space so every plant agrees on the
//   wind and a gust sweeps across a field, instead of each plant wobbling on
//   its own timer. That is the whole point of TT's scrolling wind texture; see
//   Docs/TT_ENGINE_NOTES.md section 12.
// --- plastic, mirrored from BrickLib -------------------------------------
uniform float p_roughness : hint_range(0.0, 1.0) = 0.30;
uniform float p_metallic : hint_range(0.0, 1.0) = 0.0;
uniform float p_specular : hint_range(0.0, 1.0) = 0.62;
uniform float p_rim : hint_range(0.0, 1.0) = 0.55;
uniform float p_rim_tint : hint_range(0.0, 1.0) = 0.45;

// --- the storm, mirrored from Tornado.wind_at ----------------------------
// If these stop agreeing with the physics the foliage leans one way while the
// player is pushed another. --selftest asserts they agree.
uniform vec3 storm_pos = vec3(0.0, 0.0, 0.0);
uniform float storm_reach = 60.0;
uniform float storm_tangent = 0.78;
uniform float storm_inward = 0.62;
uniform float storm_peak = 30.0;

// --- the ambient breeze --------------------------------------------------
// TT sample a scrolling texture in WORLD space so every plant agrees on the
// wind and a gust sweeps across a field instead of each plant wobbling on its
// own timer. This is the same idea evaluated analytically - two octaves rather
// than a texture, because it needs no asset and no sampler in a vertex shader.
uniform vec2 breeze_dir = vec2(0.87, 0.5);
uniform float breeze_strength = 0.22;
uniform float wind_scale = 0.020;


vec2 breeze_at(vec2 wp, float t) {
	float a = dot(wp, vec2(0.7071, 0.7071)) * 0.055 - t * 1.6;
	float b = dot(wp, vec2(-0.4472, 0.8944)) * 0.021 - t * 0.9;
	float g = sin(a) * 0.6 + sin(b) * 0.4;
	return breeze_dir * (0.55 + 0.45 * g);
}


// The storm's own field. Deliberately the same shape as Tornado.wind_at:
// tangential plus inward, normalised, falling off with the square of distance.
vec2 storm_at(vec2 wp) {
	vec2 to_c = storm_pos.xz - wp;
	float d = length(to_c);
	if (d < 0.05 || d > storm_reach) {
		return vec2(0.0);
	}
	vec2 inward = to_c / d;
	vec2 tangent = vec2(-inward.y, inward.x);
	float f = clamp(1.0 - d / storm_reach, 0.0, 1.0);
	f = f * f;
	return normalize(tangent * storm_tangent + inward * storm_inward) * f * storm_peak;
}


void vertex() {
	float bend = COLOR.a;
	if (bend > 0.001) {
		// Per-plant seed from the instance origin: no two plants sway alike,
		// and it costs nothing because the origin is already in MODEL_MATRIX.
		vec3 origin = MODEL_MATRIX[3].xyz;
		float seed = fract(sin(dot(origin.xz, vec2(12.9898, 78.233))) * 43758.545);
		float t = TIME + seed * 6.2831;

		vec2 w = breeze_at(origin.xz, t) * breeze_strength;
		// A tangential twitch so a plant is never a pendulum on one axis.
		w += vec2(-breeze_dir.y, breeze_dir.x) * sin(t * 2.3) * breeze_strength * 0.35;
		// The storm's field is a function of POSITION only, so on its own it
		// just leans a plant over and holds it there. Air near a funnel is not
		// steady, and a lean is not motion: the turbulence scales with the
		// local wind magnitude, so it is nothing on a calm day and violent at
		// the funnel's edge. TT scale their tangential jitter by wind
		// magnitude for the same reason.
		vec2 sw = storm_at(origin.xz) * wind_scale;
		float mag = length(sw);
		vec2 perp = vec2(-sw.y, sw.x);
		sw += perp * sin(t * 7.0) * mag * 0.9;
		sw *= 0.72 + 0.38 * sin(t * 5.0);
		w += sw;

		w *= bend;
		VERTEX.xz += w;
		// A bending stalk does not get longer. TT drop the tip by a quarter of
		// the horizontal throw for the same reason.
		VERTEX.y -= length(w) * 0.25;
	}
}


void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = p_roughness;
	METALLIC = p_metallic;
	SPECULAR = p_specular;
	RIM = p_rim;
	RIM_TINT = p_rim_tint;
}
// [BS:RENDER:WIND:END]
