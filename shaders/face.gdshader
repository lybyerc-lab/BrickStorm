// [BS:RENDER:FACE]
// Purpose: Print the face onto the head, with the wrap computed from POSITION.
// Invariants:
// - THE UV IS DERIVED IN THE SHADER, NOT AUTHORED ON THE MESH. Hand-rolling
//   cylindrical UVs went wrong twice - once putting the face on the back of
//   the head, once crushing the whole 0.25..0.75 range into a sliver at the
//   front - and both times the per-vertex dump looked correct, because the
//   error was in how the range wrapped between vertices rather than in any
//   single one. atan2 of the local position cannot have that class of bug.
// - u = 0.5 is dead ahead, +Z. THIS RIG FACES +Z: player._animate_walk aims it
//   with atan2(x, z), not Godot's usual -Z.
// - The seam lands at the BACK of the head, where nothing is printed.
// - The face texture is drawn in real minifig millimetres, see
//   BrickLib.face_texture, so it stays correct if the head is ever resized.
shader_type spatial;

uniform sampler2D face_tex : source_color, filter_linear_mipmap;
uniform float p_roughness : hint_range(0.0, 1.0) = 0.30;
uniform float p_specular : hint_range(0.0, 1.0) = 0.62;
uniform float p_rim : hint_range(0.0, 1.0) = 0.27;

varying vec3 v_local;

void vertex() {
	v_local = VERTEX;
}

void fragment() {
	// The head mesh is a unit-radius barrel of unit height, so the local
	// position gives the wrap directly.
	// The half-turn offset is BACK, and the reason it ever looked wrong is now
	// understood: the mesh was wound inside-out, so the fragment in front of
	// you was the far surface at z < 0, and atan already read half a turn
	// round. Dropping the offset cancelled that and the face landed correctly
	// for entirely the wrong reason. With the winding fixed (BS:BUILD:WINDING)
	// the near surface is the one shaded, and this offset is what puts +Z -
	// dead ahead - at u = 0.5, which is where face_texture draws the face and
	// where the mesh's own authored UVs put it too.
	float u = fract(atan(v_local.x, v_local.z) / 6.28318530718 + 0.5);
	float v = 0.5 - v_local.y;
	ALBEDO = texture(face_tex, vec2(u, clamp(v, 0.0, 1.0))).rgb;
	ROUGHNESS = p_roughness;
	SPECULAR = p_specular;
	RIM = p_rim;
	RIM_TINT = 0.5;
	METALLIC = 0.0;
}
// [BS:RENDER:FACE:END]
