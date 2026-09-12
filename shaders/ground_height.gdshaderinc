// [BS:RENDER:TERRAIN]
// Purpose: The ONE definition of how high the ground is at a point.
// Invariants:
// - THIS FILE AND scripts/terrain.gd MUST AGREE, term for term. The mesh is
//   displaced here, on the GPU; the collider, the prop placement and the stud
//   spawns are computed there, on the CPU. If they drift, the world you see is
//   not the world you stand on - props sink, the player walks on air, and
//   nothing in the game reports a fault. tools/terrain_probe.gd renders this
//   function's output as colour and compares it against the GDScript twin at
//   several hundred points, which is the only way to check a formula that
//   exists in two languages. Same reason BS:RENDER:WIND is gated against the
//   physics wind.
// - PURE SIN AND COS, NO NOISE. A hash-based noise function cannot be made
//   bit-identical across GLSL and GDScript, so agreement would be
//   unachievable by construction. Every term here is trigonometry for that
//   reason, not for looks.
// - GENTLE, BUT VISIBLE. Tuned against measured targets, not by eye: 9.3m of
//   relief along the corridor's centreline over a round, 4.5m across its
//   width, and an 18% worst grade - about ten degrees, well inside the 45
//   degrees a CharacterBody3D will walk. The first set of coefficients gave
//   4.6m along and under 2m across, which rendered as indistinguishable from
//   flat: the whole point is that the field stops reading as a floor.
// ============================================================================

float bs_ground_h(vec2 p) {
	float h = 0.0;
	h += 4.80 * sin(p.x * 0.0215 + 0.7) * cos(p.y * 0.0150);
	h += 2.20 * sin((p.x * 0.6 + p.y) * 0.0210 + 2.1);
	h += 2.00 * sin(p.y * 0.0520 - 1.2) * cos(p.x * 0.0430);
	return h;
}

// [BS:RENDER:TERRAIN:END]
