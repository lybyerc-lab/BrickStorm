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

static var _box_mesh: Mesh = null
const SHADER_PATH := "res://shaders/brick.gdshader"
const STUD_SHADER_PATH := "res://shaders/stud.gdshader"

static var _batch_mat: ShaderMaterial = null
static var _stud_mat: ShaderMaterial = null


# A chamfered unit cube, not a BoxMesh. See BrickLib.brick_mesh - the sharp
# edges of a plain box are most of why the world read as generic blocks.
static func _unit_box() -> Mesh:
	if _box_mesh == null:
		_box_mesh = BrickLib.brick_mesh()
	return _box_mesh


# Every building, fence, tree and vehicle in the world draws through THIS
# material, not BrickLib.mat() - so any change to how plastic looks has to
# land here or it does not land at all. It used to hand-copy BrickLib's
# numbers, and they silently drifted apart.
static func _material() -> ShaderMaterial:
	if _batch_mat == null:
		_batch_mat = ShaderMaterial.new()
		_batch_mat.shader = load(SHADER_PATH)
		_batch_mat.set_shader_parameter("p_roughness", BrickLib.PLASTIC_ROUGHNESS)
		_batch_mat.set_shader_parameter("p_metallic", BrickLib.PLASTIC_METALLIC)
		_batch_mat.set_shader_parameter("p_specular", BrickLib.PLASTIC_SPECULAR)
		_batch_mat.set_shader_parameter("p_rim", BrickLib.PLASTIC_RIM)
		_batch_mat.set_shader_parameter("p_rim_tint", BrickLib.PLASTIC_RIM_TINT)
		# Taken from Tornado, never retyped here.
		_batch_mat.set_shader_parameter("storm_tangent", Tornado.WIND_TANGENT)
		_batch_mat.set_shader_parameter("storm_inward", Tornado.WIND_INWARD)
		_batch_mat.set_shader_parameter("storm_peak", Tornado.WIND_PEAK)
	return _batch_mat


# Studs are vertex-coloured like the boxes, but rim-free.
static func _stud_material() -> ShaderMaterial:
	if _stud_mat == null:
		_stud_mat = ShaderMaterial.new()
		_stud_mat.shader = load(STUD_SHADER_PATH)
		_stud_mat.set_shader_parameter("p_roughness", 0.62)
		_stud_mat.set_shader_parameter("p_metallic", 0.0)
		_stud_mat.set_shader_parameter("p_specular", 0.30)
		_stud_mat.set_shader_parameter("p_rim", 0.0)
		_stud_mat.set_shader_parameter("p_rim_tint", 0.5)
	return _stud_mat


# Push the storm into the one shared material. One call moves every plant in
# the world, because they all draw through this material.
static func set_storm(centre: Vector3, reach: float) -> void:
	var m := _material()
	m.set_shader_parameter("storm_pos", centre)
	m.set_shader_parameter("storm_reach", reach)


# `bend` is how much this brick moves in the wind: 0 is rigid, which is every
# building in the game, and foliage rises toward 1 at the tips. See the shader.
func add_brick(sw: int, sd: int, h: float, color: Color, pos: Vector3,
		rot: Vector3 = Vector3.ZERO, studs: bool = true, bend: float = 0.0) -> void:
	entries.append({
		"sw": sw, "sd": sd, "h": h, "color": color, "pos": pos, "rot": rot,
		"bend": bend,
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
		# Bend goes in the INSTANCE colour's alpha only. e["color"] stays
		# opaque because tear() hands it to the debris bodies, and a leaf
		# brick with alpha 0 would come off the tree invisible.
		var ec: Color = e["color"]
		bm.set_instance_color(i, Color(ec.r, ec.g, ec.b, e.get("bend", 0.0)))

		if sm != null and e["studs"]:
			var k: int = e["stud_from"]
			for x in range(int(e["sw"])):
				for z in range(int(e["sd"])):
					var px: float = (float(x) + 0.5) * BrickLib.STUD - size.x * 0.5
					var pz: float = (float(z) + 0.5) * BrickLib.STUD - size.z * 0.5
					var local := Vector3(px, e["h"] * 0.5 + BrickLib.STUD_H * 0.5, pz)
					sm.set_instance_transform(k, xf * Transform3D(Basis(), local))
					sm.set_instance_color(k, Color(ec.r, ec.g, ec.b, e.get("bend", 0.0)))
					k += 1

	_box_mmi = MultiMeshInstance3D.new()
	_box_mmi.multimesh = bm
	_box_mmi.material_override = _material()
	add_child(_box_mmi)

	if sm != null:
		_stud_mmi = MultiMeshInstance3D.new()
		_stud_mmi.multimesh = sm
		# Studs take the rim-free stud material, not the full plastic one -
		# see BrickLib.stud_mat. They are too small to survive a fresnel term
		# at gameplay distance.
		_stud_mmi.material_override = _stud_material()
		# STUDS DO NOT CAST SHADOWS. They are the smallest curved geometry in
		# the game and they sit at the shadow map's precision limit, so they
		# shadow THEMSELVES - which renders every stud as a dark dithered disc
		# lit only by ambient. It looked like the studs were black; they were
		# in their own shadow. They still receive shadows, and not casting also
		# takes thousands of tiny casters out of the shadow pass.
		_stud_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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
# ============================================================================
# [BS:CONTENT:ABILITY_GATE]
# Purpose: Scenery that only a strong character can shift.
# Invariants:
# - A heavy structure resists BOTH Jo and the funnel. Surviving the storm is
#   the point: a gate the tornado clears for you is not a gate, and the level
#   loses its shape the moment the weather solves it.
# - Strength is a number so a future third character can sit between the two
#   without another boolean.
# - This is the ONLY thing making the character swap matter right now. If it
#   is ever bypassed - by a vehicle, by a bigger smash, by the storm - the
#   swap goes back to being decorative.
# ============================================================================
var heavy: bool = false
const HEAVY_STRENGTH := 2.0
# [BS:CONTENT:ABILITY_GATE:END]


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
func tear(world_center: Vector3, radius: float, debris_parent: Node3D, max_count: int,
		strength: float = 1.0) -> Array:
	var out: Array = []
	if heavy and strength < HEAVY_STRENGTH:
		return out
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
