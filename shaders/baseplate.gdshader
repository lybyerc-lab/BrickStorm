// [BS:RENDER:BASEPLATE]
// Purpose: The ground is a LEGO baseplate, not a lawn.
// Invariants:
// - THE GROUND IS HALF THE FRAME AND IT WAS A SMOOTH PLANE. That single fact
//   did more to make the world read as "a game with blocks in it" than
//   anything on top of it: nothing a brick stands on was itself a brick.
// - The studs are SHADED, not modelled. A 420m plane of real stud geometry is
//   millions of triangles for a thing the player never sees in silhouette;
//   perturbing the normal on a grid costs one texture-free fragment function
//   and reads correctly from a gameplay camera.
// - The grid is locked to the WORLD, at the real stud pitch, so the ground
//   lines up with everything built on it. A baseplate whose studs do not
//   match the bricks is worse than no baseplate.
// - Studs FADE OUT with distance. Up close they are the point; at 80m they
//   are aliasing, and a shimmering horizon is exactly the artefact TT kill
//   with their LOD factor.
shader_type spatial;

uniform vec3 base_color : source_color = vec3(0.42, 0.58, 0.26);
uniform float stud_pitch = 0.5;
uniform float stud_radius = 0.155;
uniform float fade_start = 26.0;
uniform float fade_end = 85.0;
uniform float p_roughness : hint_range(0.0, 1.0) = 0.62;
uniform float p_specular : hint_range(0.0, 1.0) = 0.35;

varying vec3 v_world;


void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


void fragment() {
	// Distance to the centre of this cell's stud, in stud-pitch units.
	vec2 cell = fract(v_world.xz / stud_pitch) - 0.5;
	float r = length(cell) * stud_pitch;
	float edge = stud_radius;

	float dist = length(v_world - CAMERA_POSITION_WORLD);
	float near = 1.0 - clamp((dist - fade_start) / (fade_end - fade_start), 0.0, 1.0);

	// A stud is a CYLINDER: a flat top, a hard rim, and a short side. Shading
	// it as a dome gives soft blobs that read as dimples in the plate rather
	// than studs standing on it, which is exactly how the first version
	// looked. The tilt is confined to a narrow ring at the rim.
	float aa = max(fwidth(r), 1e-5);
	float top = 1.0 - smoothstep(edge - aa, edge + aa, r);
	float rim = smoothstep(edge * 0.60, edge - aa, r) * top;
	vec2 dirn = normalize(cell + vec2(1e-6));
	vec3 n = normalize(vec3(dirn.x * rim * 1.15, 1.0, dirn.y * rim * 1.15));
	NORMAL = normalize(mix(vec3(0.0, 1.0, 0.0), n, near));

	// A stud sits ON the plate, so it casts a hint of contact just outside its
	// own footprint. Without it the studs float.
	float skirt = (1.0 - top) * (1.0 - smoothstep(edge, edge * 1.34, r));

	// The seam between plates, so the baseplate reads as a plate and not as
	// wallpaper. One line every 16 studs, the size of a real 16x16 plate.
	vec2 seam = abs(fract(v_world.xz / (stud_pitch * 16.0)) - 0.5);
	float seam_l = 1.0 - smoothstep(0.487, 0.5, max(seam.x, seam.y));

	vec3 col = base_color
		* (1.0 + top * near * 0.10)
		* (1.0 - skirt * near * 0.13)
		* mix(1.0, 0.93, (1.0 - seam_l) * near);
	ALBEDO = col;
	ROUGHNESS = p_roughness;
	SPECULAR = p_specular;
	METALLIC = 0.0;
}
// [BS:RENDER:BASEPLATE:END]
