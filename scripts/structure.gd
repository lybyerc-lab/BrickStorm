# A brick-built structure that the funnel can take apart.
class_name Structure
extends Node3D

# ============================================================================
# [BS:DESTRUCTION:STRUCTURE]
# Purpose: A brick-built structure: batched visuals until torn, bodies after.
# Invariants:
# - An untorn structure is ONE DRAW CALL PER PART KIND IT USES, plus one for
#   its studs - not one per brick. Every instance of a kind shares one
#   MultiMesh (the unit part, per-instance scale and colour). Before this, a
#   corridor of 150 structures issued roughly twelve thousand draw calls and
#   ran at 9 fps; see Docs/PLAYTEST_VS_LEGO_INDY.md.
# - THE COST OF PART VARIETY IS PAID HERE, so keep a prop's palette of kinds
#   small and deliberate. A prop built from all eight kinds costs nine draw
#   calls instead of two. Reaching for a cheese slope where a tile would do is
#   not free, and a MultiMesh is only allocated for a kind the prop actually
#   uses, so an unused kind costs nothing at all.
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
# One MultiMeshInstance3D per part kind actually used, keyed by kind.
var _part_mmi: Dictionary = {}
var _stud_mmi: MultiMeshInstance3D = null

const SHADER_PATH := "res://shaders/brick.gdshader"
const STUD_SHADER_PATH := "res://shaders/stud.gdshader"

static var _batch_mat: ShaderMaterial = null
static var _stud_mat: ShaderMaterial = null


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
	add_part(BrickLib.PART_BRICK, sw, sd, h, color, pos, rot, studs, bend)


# The general form. A slope, a tile, an arch and a round brick all place the
# same way a box does - same stud pitch, same footprint, same tear behaviour -
# so a prop can reach for the right part without any new placement machinery.
# `sd` is the part's depth in studs and, for a slope, the direction it falls:
# slopes descend toward +Z before `rot` is applied.
func add_part(kind: int, sw: int, sd: int, h: float, color: Color, pos: Vector3,
		rot: Vector3 = Vector3.ZERO, studs: bool = true, bend: float = 0.0) -> void:
	entries.append({
		"kind": kind,
		"sw": sw, "sd": sd, "h": h, "color": color, "pos": pos, "rot": rot,
		"bend": bend,
		"studs": studs, "torn": false, "stud_from": 0, "stud_count": 0,
		"slot": 0,
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
	# Group by part kind first: each kind gets its own MultiMesh, because a
	# MultiMesh draws one mesh. Kinds a prop never uses are never allocated.
	var by_kind: Dictionary = {}
	var stud_total := 0
	for i in range(entries.size()):
		var e: Dictionary = entries[i]
		var k: int = e["kind"]
		if not by_kind.has(k):
			by_kind[k] = []
		e["slot"] = by_kind[k].size()
		by_kind[k].append(i)
		if e["studs"]:
			var slots: Array = BrickLib.part_stud_slots(k, int(e["sw"]), int(e["sd"]))
			e["stud_from"] = stud_total
			e["stud_count"] = slots.size()
			stud_total += slots.size()

	var sm: MultiMesh = null
	if stud_total > 0:
		sm = MultiMesh.new()
		sm.transform_format = MultiMesh.TRANSFORM_3D
		sm.use_colors = true
		sm.mesh = BrickLib.stud_mesh()
		sm.instance_count = stud_total

	for k in by_kind.keys():
		var idxs: Array = by_kind[k]
		var bm := MultiMesh.new()
		bm.transform_format = MultiMesh.TRANSFORM_3D
		bm.use_colors = true
		bm.mesh = BrickLib.part_mesh(k)
		bm.instance_count = idxs.size()
		for slot in range(idxs.size()):
			var e: Dictionary = entries[idxs[slot]]
			var size := Vector3(e["sw"] * BrickLib.STUD, e["h"], e["sd"] * BrickLib.STUD)
			var xf := _brick_xform(e)
			bm.set_instance_transform(slot, xf * Transform3D(Basis().scaled(size), Vector3.ZERO))
			# Bend goes in the INSTANCE colour's alpha only. e["color"] stays
			# opaque because tear() hands it to the debris bodies, and a leaf
			# brick with alpha 0 would come off the tree invisible.
			var ec: Color = e["color"]
			bm.set_instance_color(slot, Color(ec.r, ec.g, ec.b, e.get("bend", 0.0)))

			if sm != null and e["studs"]:
				var j: int = e["stud_from"]
				for u in BrickLib.part_stud_slots(k, int(e["sw"]), int(e["sd"])):
					# Stud slots arrive in unit-part space, so a slope puts its
					# row on the ledge and a tile asks for none at all.
					var local := Vector3(u.x * size.x,
						e["h"] * 0.5 + BrickLib.STUD_H * 0.5, u.z * size.z)
					sm.set_instance_transform(j, xf * Transform3D(Basis(), local))
					sm.set_instance_color(j, Color(ec.r, ec.g, ec.b, e.get("bend", 0.0)))
					j += 1

		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = bm
		mmi.material_override = _material()
		add_child(mmi)
		_part_mmi[k] = mmi

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
	var mmi: MultiMeshInstance3D = _part_mmi.get(e["kind"], null)
	if mmi != null:
		mmi.multimesh.set_instance_transform(int(e["slot"]), zero)
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


# Set once, when this structure has paid out its finish bonus. A structure can
# cross the rubble threshold on any tear from any source, and the bonus must
# land exactly once - see BS:ECONOMY:FINISH_BONUS.
var paid_finish: bool = false


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
# Cubic world units one player smash may remove. Roughly half a 2x2 brick,
# which is one ring off a barrel or one course off a bin. It lives here rather
# than in main.gd because tools/smash_probe.gd has to bite with exactly the
# number the game bites with - a probe that hard-codes its own copy is testing
# itself.
const SMASH_BITE := 0.35


# The bounding volume of one part, in cubic world units. This is what a
# volume-bounded bite is measured against, and it is deliberately the bounding
# box rather than the true volume of a cone or a cylinder: the budget is a
# game-feel number, and making it depend on which part kind a builder reached
# for is exactly the coupling `volume_budget` exists to remove.
static func _entry_volume(e: Dictionary) -> float:
	return float(e["sw"]) * BrickLib.STUD * float(e["h"]) \
		* float(e["sd"]) * BrickLib.STUD


# `volume_budget` above zero turns this from "tear whatever is in range, up to
# max_count bricks" into A BITE: the parts nearest the strike point come away
# first, and only until that much volume has been removed.
#
# Why volume and not a brick count: the count is what coupled the pace of the
# game to how a model happens to be built. max_count is 10, which is larger
# than any small prop, so every barrel, bin, crate and hay bale in the world
# came apart in ONE hit - and since a hit that finds nothing logs no SMASH
# event, rebuilding those props from round parts (barrel 21 pieces to 6) halved
# the measured player-verb rate without anyone touching the verb. See
# Docs/PLAYTEST_VS_LEGO_INDY.md, follow-up 2, and tools/smash_probe.gd.
#
# A budget cannot remove a fraction of a part, so a prop built from fewer parts
# than the number of hits wanted will still clear early. Part count is the
# floor; the budget is the ceiling. Both are needed.
func tear(world_center: Vector3, radius: float, debris_parent: Node3D, max_count: int,
		strength: float = 1.0, volume_budget: float = -1.0) -> Array:
	var out: Array = []
	if heavy and strength < HEAVY_STRENGTH:
		return out
	if torn_count >= entries.size():
		return out
	var r2 := radius * radius
	var order: Array = []
	for i in range(entries.size()):
		var e: Dictionary = entries[i]
		if e["torn"]:
			continue
		var xf := global_transform * _brick_xform(e)
		var d2 := xf.origin.distance_squared_to(world_center)
		if d2 > r2:
			continue
		order.append([d2, i])
	if volume_budget > 0.0:
		# Nearest-first, so what comes away is the part of the model you
		# actually hit rather than whichever bricks happen to sit early in the
		# entry list. The funnel deliberately does NOT sort: its tear pattern
		# and the economy on top of it are tuned against the existing order,
		# and this change is scoped to the player's smash.
		order.sort_custom(func(a, b): return a[0] < b[0])
	var spent := 0.0
	for c in order:
		if out.size() >= max_count:
			break
		var i: int = c[1]
		var e: Dictionary = entries[i]
		var vol := _entry_volume(e)
		# Always take at least one part - a bite smaller than the smallest
		# piece would make the prop indestructible - then stop before going
		# over budget.
		if volume_budget > 0.0 and not out.is_empty() and spent + vol > volume_budget:
			break
		spent += vol
		var xf := global_transform * _brick_xform(e)

		e["torn"] = true
		torn_count += 1
		_hide_instance(i)
		var b := BrickLib.brick_body(e["sw"], e["sd"], e["h"], e["color"], e["kind"])
		debris_parent.add_child(b)
		b.global_transform = xf
		out.append(b)

	if collider != null and is_rubble():
		collider.disabled = true
	return out
# [BS:DESTRUCTION:TEAR:END]
