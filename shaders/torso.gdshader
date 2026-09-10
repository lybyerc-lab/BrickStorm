// [BS:RENDER:TORSO]
// Purpose: Print the torso artwork on the FRONT face only.
// Invariants:
// - THE FRONT IS SELECTED BY THE LOCAL NORMAL, not by a UV layout. Authoring
//   UVs by hand went wrong repeatedly on the head; a normal test cannot put
//   the print on the wrong face.
// - +Z IS THE FRONT. This rig faces +Z, not Godot's usual -Z:
//   player._animate_walk aims it with atan2(x, z).
// - The sides and back are plain plastic, exactly like the real part. Only the
//   flat front carries artwork, and it fades out across the corner chamfer so
//   the print does not smear round the edge.
shader_type spatial;

uniform sampler2D print_tex : source_color, filter_linear_mipmap;
uniform vec3 base_color : source_color = vec3(0.05, 0.35, 0.66);
uniform float p_roughness : hint_range(0.0, 1.0) = 0.30;
uniform float p_specular : hint_range(0.0, 1.0) = 0.62;
uniform float p_rim : hint_range(0.0, 1.0) = 0.27;

varying vec3 v_local;
varying vec3 v_lnormal;

void vertex() {
	v_local = VERTEX;
	v_lnormal = NORMAL;
}

void fragment() {
	// The torso mesh is a unit-height part, full width 1.0 at the waist.
	// Printed on WHICHEVER flat +/-Z face is being looked at, with u mirrored
	// on the far side so the asymmetric strap reads correctly either way.
	//
	// Selecting only +Z left the torso blank: the surface the camera actually
	// sees on this mesh reports v_local.z = -0.25, measured, not assumed. That
	// strongly suggests these generated meshes are wound inside-out and that
	// the head's face offset has been silently compensating for the same
	// thing. Recorded as unresolved in Docs/DECISION_LOG.md - this makes the
	// print correct without pretending the winding question is answered.
	// The artwork spans the FLAT face, not the whole part. The front runs to
	// +/-0.40 in x once the corner radius is taken off, so mapping u straight
	// from x left the outer tenth of the print permanently off-screen and the
	// whole thing looking inset.
	float side = sign(v_local.z);
	float u = clamp(0.5 + side * v_local.x / 0.80, 0.0, 1.0);
	float v = clamp(0.5 - v_local.y, 0.0, 1.0);
	vec3 print = texture(print_tex, vec2(u, v)).rgb;

	// Front-ness from POSITION, not from NORMAL. The mesh carries correct
	// normals - dumped and checked - but the value never reached this varying
	// under the compatibility renderer, so the test read zero everywhere and
	// the torso came out unprinted. v_local demonstrably works: u and v
	// derived from it were exact while front was flat zero.
	// The part is half a unit deep, so the flat front sits at z = +0.25.
	float front = smoothstep(0.58, 0.86, abs(v_local.z) / 0.25);
	ALBEDO = mix(base_color, print, front);
	ROUGHNESS = p_roughness;
	SPECULAR = p_specular;
	RIM = p_rim;
	RIM_TINT = 0.5;
	METALLIC = 0.0;
}
// [BS:RENDER:TORSO:END]
