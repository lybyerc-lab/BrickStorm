// [BS:RENDER:GROUND]
// Purpose: The ground: sculpted-looking, textured, and NOT a brick.
// Invariants:
// - THE GROUND IS NOT SMASHABLE, SO IT IS NOT PLASTIC. North Star pillar 1 was
//   revised by director decision on 2026-09-10: whatever breaks is brick-built,
//   whatever does not is free. This replaces a 420m studded baseplate, and
//   losing that baseplate is the point rather than a regression. In LEGO
//   Indiana Jones the environment is sculpted rock, plaster and cobbles, and
//   the minifigs and vehicles read as moulded plastic precisely BECAUSE they
//   sit against something that is not. Ours was plastic all the way down, so
//   nothing had anything to read against.
// - IT CARRIES SURFACE DETAIL, and that is measured, not decorative. Our
//   frames came in at 23-29% flat single-tone 8x8 tiles against the demo's
//   12.5-18%; the ground is half of every frame and it was one flat colour
//   with a stud grid stamped on it. Value noise costs nothing, needs no
//   texture asset, and is what breaks up the tile statistic.
// - SATURATION BELONGS TO THE PLASTIC. Pillar 2, clarified the same day:
//   bricks stay punchy, terrain sits lower and earthier so the bricks have
//   something to be bright against. Measured 0.71-0.76 for us against
//   0.21-0.46 for the demo's daylight exteriors - the world was competing with
//   its own bricks. Value stays high; only colourfulness comes down. This is
//   not permission to darken the world.
// - THE FINE GRAIN FADES WITH DISTANCE. Up close it is the point; at 90m it is
//   aliasing, and a shimmering horizon is the artefact TT kill with their LOD
//   factor. Same lesson the baseplate's studs taught.
shader_type spatial;

// Desaturated but NOT darkened. The first pass took saturation out by
// lowering value with it, and the frame median fell from 93 to 66 - which
// is the one thing pillar 2 forbids outright. Colourfulness comes down;
// brightness stays where it was.
uniform vec3 soil_color : source_color = vec3(0.56, 0.60, 0.41);
uniform vec3 grass_color : source_color = vec3(0.62, 0.71, 0.44);
uniform vec3 dry_color : source_color = vec3(0.72, 0.70, 0.53);
// The grain has to survive out to where the frame actually is. At a 30m
// fade it was gone across almost the whole picture and the ground measured
// FLATTER than the baseplate it replaced.
uniform float fade_start = 45.0;
uniform float fade_end = 150.0;
// The baseplate this replaced ran 0.62 / 0.35. Dropping specular to 0.12
// and pushing roughness to 0.78 took a surprising amount of light out of
// half the frame on its own, on top of the albedo change - the world came
// out olive and gloomy, which pillar 2 forbids in as many words.
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


// Three octaves is enough: one for field-sized patches, one for metre-scale
// mottling, one for the grain that only reads underfoot.
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


void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


void fragment() {
	vec2 w = v_world.xz;
	float dist = length(v_world - CAMERA_POSITION_WORLD);
	float near = 1.0 - clamp((dist - fade_start) / (fade_end - fade_start), 0.0, 1.0);

	// Field-sized patches: which parts of this land are grass and which are
	// worked or worn to soil.
	float patch = fbm(w * 0.035);
	// Metre-scale mottling, and the grain that only survives close up.
	float mottle = fbm(w * 0.62) - 0.5;
	float grain = (vnoise(w * 5.7) - 0.5) * near;

	vec3 base = mix(soil_color, grass_color, smoothstep(0.35, 0.62, patch));
	base = mix(base, dry_color, smoothstep(0.68, 0.92, patch));
	// Tonal break-up, in VALUE not in hue: the surface stops being one flat
	// tone without the palette drifting.
	base *= 1.0 + mottle * 0.30 + grain * 0.14;

	ALBEDO = clamp(base, vec3(0.0), vec3(1.0));
	ROUGHNESS = p_roughness;
	SPECULAR = p_specular;
	METALLIC = 0.0;
	// No rim term. A grazing-angle response on a 420m plane lights the entire
	// horizon, which is the specular blowout already recorded for terrain_mat.
	RIM = 0.0;
}
// [BS:RENDER:GROUND:END]
