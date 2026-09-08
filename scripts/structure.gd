# A brick-built structure that the funnel can take apart.
#
# Untorn bricks are cheap visuals under one static collider. A brick only becomes
# a real RigidBody3D at the moment it is torn loose - so the scene costs almost
# nothing until the tornado arrives, and then only the flying pieces simulate.
class_name Structure
extends Node3D

var entries: Array[Dictionary] = []
var torn_count: int = 0
var collider: CollisionShape3D = null

var _bmin := Vector3(1e9, 1e9, 1e9)
var _bmax := Vector3(-1e9, -1e9, -1e9)


# ============================================================================
# [BS:DESTRUCTION:STRUCTURE]
# Purpose: A brick-built structure: cheap visuals until torn, rigid bodies after.
# Invariants:
# - Untorn bricks are NOT physics bodies. Hundreds of frozen
#   RigidBody3D would eat a phone alive.
# - One static collider covers the whole structure, and is disabled
#   once it is mostly rubble - walking through a pile of loose bricks
#   is the correct behaviour.
# ============================================================================
func add_brick(sw: int, sd: int, h: float, color: Color, pos: Vector3, rot: Vector3 = Vector3.ZERO, studs: bool = true) -> void:
	var v := BrickLib.brick_visual(sw, sd, h, color, studs)
	v.position = pos
	v.rotation = rot
	add_child(v)
	entries.append({"node": v, "sw": sw, "sd": sd, "h": h, "color": color, "torn": false})

	var half := Vector3(sw * BrickLib.STUD, h, sd * BrickLib.STUD) * 0.5
	_bmin = Vector3(minf(_bmin.x, pos.x - half.x), minf(_bmin.y, pos.y - half.y), minf(_bmin.z, pos.z - half.z))
	_bmax = Vector3(maxf(_bmax.x, pos.x + half.x), maxf(_bmax.y, pos.y + half.y), maxf(_bmax.z, pos.z + half.z))


# One box collider for the whole structure. Removed once it is mostly rubble,
# because walking through a pile of loose bricks is the correct behaviour.
# [BS:DESTRUCTION:STRUCTURE:END]
func finish() -> void:
	if entries.is_empty():
		return
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	var size := _bmax - _bmin
	shape.size = Vector3(maxf(size.x, 0.2), maxf(size.y, 0.2), maxf(size.z, 0.2))
	cs.shape = shape
	cs.position = (_bmin + _bmax) * 0.5
	body.add_child(cs)
	add_child(body)
	collider = cs


func is_rubble() -> bool:
	return entries.is_empty() or float(torn_count) / float(entries.size()) > 0.55


# Tear every brick within `radius` of a world point. Returns the new debris bodies.
# ============================================================================
# [BS:DESTRUCTION:TEAR]
# Purpose: Promotion of a visual brick to a simulated one at the moment it is torn.
# Invariants:
# - The tear budget is per-frame and capped by the caller: an
#   unbounded tear spikes the frame on a phone.
# - Debris bodies inherit the visual brick's exact world transform,
#   so a structure never visibly jumps as it comes apart.
# ============================================================================
func tear(world_center: Vector3, radius: float, debris_parent: Node3D, max_count: int) -> Array:
	var out: Array = []
	if torn_count >= entries.size():
		return out
	var r2 := radius * radius
	for e in entries:
		if out.size() >= max_count:
			break
		if e["torn"]:
			continue
		var n: Node3D = e["node"]
		if not is_instance_valid(n):
			e["torn"] = true
			torn_count += 1
			continue
		var xf := n.global_transform
		if xf.origin.distance_squared_to(world_center) > r2:
			continue

		e["torn"] = true
		torn_count += 1
		var b := BrickLib.brick_body(e["sw"], e["sd"], e["h"], e["color"])
		debris_parent.add_child(b)
		b.global_transform = xf
		out.append(b)
		n.queue_free()

	if collider != null and is_rubble():
		collider.disabled = true
	return out
# [BS:DESTRUCTION:TEAR:END]
