# ============================================================================
# [BS:WORLD:TERRAIN]
# Purpose: How high the ground is, on the CPU side.
# Invariants:
# - THIS FILE AND shaders/ground_height.gdshaderinc MUST AGREE, term for term.
#   The ground MESH is displaced in the vertex shader; the COLLIDER, the prop
#   placement and the stud spawns come from here. Drift between them means the
#   world you see is not the world you stand on, and nothing in the game
#   reports it - props sink into hillsides, the player walks on air over a
#   dip. tools/terrain_probe.gd renders the shader's output as colour and
#   compares it against this at several hundred points, because a formula that
#   lives in two languages cannot be checked any other way.
# - EVERY PLACEMENT GOES THROUGH height(). A prop positioned at y = 0 is a
#   prop buried in, or floating over, the first hill it meets.
# - Pure trigonometry, no noise: see the shader for why agreement would
#   otherwise be unachievable by construction.
# ============================================================================
class_name Terrain
extends RefCounted


static func height(x: float, z: float) -> float:
	var h := 0.0
	h += 4.80 * sin(x * 0.0215 + 0.7) * cos(z * 0.0150)
	h += 2.20 * sin((x * 0.6 + z) * 0.0210 + 2.1)
	h += 2.00 * sin(z * 0.0520 - 1.2) * cos(x * 0.0430)
	return h


static func height_at(p: Vector3) -> float:
	return height(p.x, p.z)


# Surface normal from finite differences, so it can never disagree with
# height() the way a hand-derived analytic gradient can.
static func normal(x: float, z: float, e: float = 0.5) -> Vector3:
	var dx := height(x + e, z) - height(x - e, z)
	var dz := height(x, z + e) - height(x, z - e)
	return Vector3(-dx, 2.0 * e, -dz).normalized()


# [BS:WORLD:TERRAIN:END]
