# A brick-built structure that the funnel can take apart.
class_name Structure
extends Node3D

# ============================================================================
# [BS:DESTRUCTION:STRUCTURE]
# Purpose: A brick-built structure: batched visuals until torn, bodies after.
# Invariants:
# - An untorn structure is TWO draw calls, not two per brick. All box bodies
#   share one MultiMesh (unit cube, per-instance scale and colour) and all
#   studs share another. Before this, a corridor of 150 structures issued
#   roughly twelve thousand draw calls and ran at 9 fps; see
#   Docs/PLAYTEST_VS_LEGO_INDY.md.
# - Per-instance colour needs `use_colors` on the MultiMesh AND
#   `vertex_color_use_as_albedo` on the material. Setting one without the
#   other silently renders everything white.
# - A torn brick is hidden by zeroing its instance scale, never by rebuilding
#   the MultiMesh - a rebuild per brick would be worse than what this replaced.
# - One static collider covers the whole structure, removed once it is mostly
#   rubble, because walking through a pile of loose bricks is correct.
# ============================================================================
var entries: Array[Dictionary] = []
var torn_count: int = 0
var collider: CollisionShape3D = null

var _bmin := Vector3(1e9, 1e9, 1e9)
var _bmax := Vector3(-1e9, -1e9, -1e9)
var _box_mmi: MultiMeshInstance3D = null
var _stud_mmi: MultiMeshInstance3D = null

static var _box_mesh: BoxMesh = null
static var _batch_mat: StandardMaterial3D = null


static func _unit_box() -> BoxMesh:
	if _box_mesh == null:
		_box_mesh = BoxMesh.new()
		_box_mesh.size = Vector3.ONE
	return _box_mesh


static func _material() -> StandardMaterial3D:
	if _batch_mat == null:
		_batch_mat = StandardMaterial3D.new()
		_batch_mat.vertex_color_use_as_albedo = true
		_batch_mat.roughness = 0.36
		_batch_mat.metallic = 0.0
		_batch_mat.metallic_specular = 0.48
	return _batch_mat


func add_brick(sw: int, sd: int, h: float, color: Color, pos: Vector3,
		rot: Vector3 = Vector3.ZERO, studs: bool = true) -> void:
	entries.append({
		"sw": sw, "sd": sd, "h": h, "color": color, "pos": pos, "rot": rot,
		"studs": studs, "torn": false, "stud_from": 0, "stud_count": 0,
	})
	var half := Vector3(sw * BrickLib.STUD, h, sd * BrickLib.STUD) * 0.5
	_bmin = Vector3(minf(_bmin.x, pos.x - half.x), minf(_bmin.y, pos.y - half.y), minf(_bmin.z, pos.z - half.z))
	_bmax = Vector3(maxf(_bmax.x, pos.x + half.x), maxf(_bmax.y, pos.y + half.y), maxf(_bmax.z, pos.z + half.z))


func _brick_xform(e: Dictionary) -> Transform3D:
	var b := Basis.from_euler(e["rot"])
	return Transform3D(b, e["pos"])


func finish() -> void:
	if entries.is_empty():
		return
	_build_batches()

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


func _build_batches() -> void:
	var stud_total := 0
	for e in entries:
		if e["studs"]:
			e["stud_from"] = stud_total
			e["stud_count"] = int(e["sw"]) * int(e["sd"])
			stud_total += e["stud_count"]

	var bm := MultiMesh.new()
	bm.transform_format = MultiMesh.TRANSFORM_3D
	bm.use_colors = true
	bm.mesh = _unit_box()
	bm.instance_count = entries.size()

	var sm: MultiMesh = null
	if stud_total > 0:
		sm = MultiMesh.new()
		sm.transform_format = MultiMesh.TRANSFORM_3D
		sm.use_colors = true
		sm.mesh = BrickLib.stud_mesh()
		sm.instance_count = stud_total

	for i in range(entries.size()):
		var e: Dictionary = entries[i]
		var size := Vector3(e["sw"] * BrickLib.STUD, e["h"], e["sd"] * BrickLib.STUD)
		var xf := _brick_xform(e)
		bm.set_instance_transform(i, xf * Transform3D(Basis().scaled(size), Vector3.ZERO))
		bm.set_instance_color(i, e["color"])

		if sm != null and e["studs"]:
			var k: int = e["stud_from"]
			for x in range(int(e["sw"])):
				for z in range(int(e["sd"])):
					var px: float = (float(x) + 0.5) * BrickLib.STUD - size.x * 0.5
					var pz: float = (float(z) + 0.5) * BrickLib.STUD - size.z * 0.5
					var local := Vector3(px, e["h"] * 0.5 + BrickLib.STUD_H * 0.5, pz)
					sm.set_instance_transform(k, xf * Transform3D(Basis(), local))
					sm.set_instance_color(k, e["color"])
					k += 1

	_box_mmi = MultiMeshInstance3D.new()
	_box_mmi.multimesh = bm
	_box_mmi.material_override = _material()
	add_child(_box_mmi)

	if sm != null:
		_stud_mmi = MultiMeshInstance3D.new()
		_stud_mmi.multimesh = sm
		_stud_mmi.material_override = _material()
		add_child(_stud_mmi)


func _hide_instance(i: int) -> void:
	var e: Dictionary = entries[i]
	var zero := Transform3D(Basis().scaled(Vector3.ZERO), e["pos"])
	if _box_mmi != null:
		_box_mmi.multimesh.set_instance_transform(i, zero)
	if _stud_mmi != null and e["studs"]:
		for k in range(int(e["stud_from"]), int(e["stud_from"]) + int(e["stud_count"])):
			_stud_mmi.multimesh.set_instance_transform(k, zero)
# [BS:DESTRUCTION:STRUCTURE:END]


func is_rubble() -> bool:
	return entries.is_empty() or float(torn_count) / float(entries.size()) > 0.55


# ============================================================================
# [BS:DESTRUCTION:TEAR]
# Purpose: Promotion of a batched brick to a simulated one when torn loose.
# Invariants:
# - The tear budget is per-frame and capped by the caller: an unbounded tear
#   spikes the frame on a phone.
# - Debris bodies inherit the brick's exact world transform, so a structure
#   never visibly jumps as it comes apart.
# ============================================================================
func tear(world_center: Vector3, radius: float, debris_parent: Node3D, max_count: int) -> Array:
	var out: Array = []
	if torn_count >= entries.size():
		return out
	var r2 := radius * radius
	for i in range(entries.size()):
		if out.size() >= max_count:
			break
		var e: Dictionary = entries[i]
		if e["torn"]:
			continue
		var xf := global_transform * _brick_xform(e)
		if xf.origin.distance_squared_to(world_center) > r2:
			continue

		e["torn"] = true
		torn_count += 1
		_hide_instance(i)
		var b := BrickLib.brick_body(e["sw"], e["sd"], e["h"], e["color"])
		debris_parent.add_child(b)
		b.global_transform = xf
		out.append(b)

	if collider != null and is_rubble():
		collider.disabled = true
	return out
# [BS:DESTRUCTION:TEAR:END]
