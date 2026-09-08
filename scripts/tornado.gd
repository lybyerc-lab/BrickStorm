# The funnel.
#
# It is the only thing in the world not made of bricks - it reads as a force,
# not an object (Docs/GAME_CONCEPT.md §9). It wanders the level on a path,
# tears scenery apart, drags loose debris up its own spiral, and pushes the
# player around. It is a moving resource node, not an enemy.
class_name Tornado
extends Node3D

# ============================================================================
# [BS:ECONOMY:RISK_BANDS]
# Purpose: Concentric value bands around the funnel - the core of the economy.
# Invariants:
# - Value rises monotonically toward the funnel. A band nearer the
#   centre is never worth less.
# - These thresholds are the SINGLE source of truth for both the
#   multiplier and the rings drawn on the ground. Do not duplicate
#   them in the HUD or the world.
# - The bands must stay legible on the ground (North Star pillar 5).
# ============================================================================
const BAND_YELLOW := 34.0
const BAND_ORANGE := 22.0
const BAND_RED    := 12.0

# [BS:ECONOMY:RISK_BANDS:END]

@export var damage_radius: float = 8.0
@export var suction_radius: float = 26.0
@export var lift_radius: float = 6.0
@export var move_speed: float = 4.6

var debris_root: Node3D = null
# Cows and other moving actors. They get dragged exactly like debris and are
# never converted, damaged, or removed (Design Law #1).
var critter_root: Node3D = null

var _segments: Array = []
var _rings: Array = []
var _skirt: MultiMeshInstance3D = null
var _waypoints: PackedVector3Array = PackedVector3Array()
var _wp: int = 0
var _t: float = 0.0
var _wobble := Vector3.ZERO


func _ready() -> void:
	_build_funnel()
	_build_rings()
	_build_skirt()


# ============================================================================
# [BS:STORM:FUNNEL_VISUAL]
# Purpose: The segmented, writhing funnel - the one thing not made of bricks.
# Invariants:
# - It must read as a FORCE, not an object (pillar 3). It never gets
#   a face, a health bar, or a name.
# - Narrow at the ground, flaring into the wall cloud.
# ============================================================================
func _build_funnel() -> void:
	var seg_count := 18
	var height := 30.0
	for i in range(seg_count):
		var f: float = float(i) / float(seg_count - 1)
		var seg_h: float = height / float(seg_count) * 1.25
		# narrow at the ground, flaring into the wall cloud
		var r_bot: float = 1.8 + pow(f, 1.9) * 8.0
		var r_top: float = 1.8 + pow(f + 1.0 / float(seg_count), 1.9) * 8.0

		var cm := CylinderMesh.new()
		cm.bottom_radius = r_bot
		cm.top_radius = r_top
		cm.height = seg_h
		cm.radial_segments = 14
		cm.rings = 0

		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		var shade: float = 0.16 + f * 0.30
		m.albedo_color = Color(shade * 0.80, shade * 0.86, shade, 0.62 - f * 0.20)

		var mi := MeshInstance3D.new()
		mi.mesh = cm
		mi.material_override = m
		var holder := Node3D.new()
		holder.position = Vector3(0, f * height + seg_h * 0.5, 0)
		holder.add_child(mi)
		add_child(holder)
		_segments.append({"node": holder, "f": f, "spin": 2.4 + f * 1.5})
# [BS:STORM:FUNNEL_VISUAL:END]


func _build_rings() -> void:
	var defs := [
		{"r": BAND_YELLOW, "c": Color(0.98, 0.82, 0.16, 0.30)},
		{"r": BAND_ORANGE, "c": Color(0.95, 0.50, 0.10, 0.38)},
		{"r": BAND_RED,    "c": Color(0.92, 0.16, 0.13, 0.48)},
	]
	for d in defs:
		var tm := TorusMesh.new()
		tm.inner_radius = d["r"] - 0.28
		tm.outer_radius = d["r"] + 0.28
		tm.rings = 40
		tm.ring_segments = 5

		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = d["c"]

		var mi := MeshInstance3D.new()
		mi.mesh = tm
		mi.material_override = m
		mi.position = Vector3(0, 0.08, 0)
		add_child(mi)
		_rings.append(mi)


# A skirt of tumbling debris orbiting the base - the thing that sells the scale.
# ============================================================================
# [BS:STORM:SKIRT]
# Purpose: Debris skirt orbiting the base - what sells the scale.
# Invariants:
# - One MultiMesh. This is decoration and must never become a
#   gameplay collider.
# ============================================================================
func _build_skirt() -> void:
	var count := 46
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var bm := BoxMesh.new()
	bm.size = Vector3(0.42, 0.30, 0.42)
	mm.mesh = bm
	mm.instance_count = count
	_skirt = MultiMeshInstance3D.new()
	_skirt.multimesh = mm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.34, 0.30, 0.26)
	_skirt.material_override = m
	add_child(_skirt)
# [BS:STORM:SKIRT:END]


func set_path(points: PackedVector3Array) -> void:
	_waypoints = points
	_wp = 0
	if points.size() > 0:
		global_position = points[0]


func funnel_pos() -> Vector3:
	return global_position + _wobble


func band_of(p: Vector3) -> int:
	var d := _flat_dist(p)
	if d <= BAND_RED:
		return 3
	if d <= BAND_ORANGE:
		return 2
	if d <= BAND_YELLOW:
		return 1
	return 0


static func band_multiplier(b: int) -> int:
	match b:
		3: return 5
		2: return 3
		1: return 2
		_: return 1


func _flat_dist(p: Vector3) -> float:
	var c := funnel_pos()
	return Vector2(p.x - c.x, p.z - c.z).length()


# Wind is mostly tangential with an inward bite, falling off with distance.
# ============================================================================
# [BS:STORM:WIND_FIELD]
# Purpose: Wind sampled at a world point; mostly tangential with an inward bite.
# Invariants:
# - Falls off with distance and is zero beyond reach, so wind never
#   acts on something the player cannot see is in danger.
# - This is the only wind source. Do not add a second field.
# ============================================================================
func wind_at(p: Vector3) -> Vector3:
	var c := funnel_pos()
	var to_c := Vector3(c.x - p.x, 0.0, c.z - p.z)
	var d := to_c.length()
	if d < 0.05:
		return Vector3.ZERO
	var inward := to_c / d
	var tangent := Vector3(-inward.z, 0.0, inward.x)
	var reach := suction_radius * 1.7
	if d > reach:
		return Vector3.ZERO
	var falloff: float = clampf(1.0 - d / reach, 0.0, 1.0)
	falloff = falloff * falloff
	return (tangent * 0.78 + inward * 0.62).normalized() * falloff * 30.0
# [BS:STORM:WIND_FIELD:END]


func _process(delta: float) -> void:
	_t += delta
	_wobble = Vector3(sin(_t * 1.7) * 1.1, 0.0, cos(_t * 1.31) * 1.1)

	for s in _segments:
		var n: Node3D = s["node"]
		n.rotation.y += s["spin"] * delta
		var f: float = s["f"]
		# the funnel writhes: each segment leans a little, more so up high
		n.position.x = sin(_t * 1.4 + f * 5.0) * f * 2.6 + _wobble.x
		n.position.z = cos(_t * 1.1 + f * 4.2) * f * 2.6 + _wobble.z

	for mi in _rings:
		mi.position.x = _wobble.x
		mi.position.z = _wobble.z

	_animate_skirt()


func _animate_skirt() -> void:
	if _skirt == null:
		return
	var mm := _skirt.multimesh
	for i in range(mm.instance_count):
		var fi := float(i)
		var a: float = _t * (2.2 + fmod(fi, 5.0) * 0.35) + fi * 0.9
		var r: float = 2.6 + fmod(fi * 1.7, 5.0)
		var y: float = fmod(fi * 0.83 + _t * (1.4 + fmod(fi, 3.0) * 0.5), 7.0) + 0.3
		var b := Basis().rotated(Vector3.UP, a * 2.0).rotated(Vector3.RIGHT, a * 1.4)
		var pos := Vector3(cos(a) * r + _wobble.x, y, sin(a) * r + _wobble.z)
		mm.set_instance_transform(i, Transform3D(b, pos))


func _physics_process(delta: float) -> void:
	_advance_path(delta)
	_drag_debris()


# ============================================================================
# [BS:STORM:PATH]
# Purpose: The funnel's wander through the level.
# Invariants:
# - The funnel obeys drama, not meteorology (North Star: not a
#   weather simulator).
# - It loops, so a level never runs out of storm.
# ============================================================================
func _advance_path(delta: float) -> void:
	if _waypoints.size() < 2:
		return
	var target := _waypoints[_wp]
	var to_t := Vector3(target.x - global_position.x, 0.0, target.z - global_position.z)
	if to_t.length() < 3.0:
		_wp = (_wp + 1) % _waypoints.size()
		target = _waypoints[_wp]
		to_t = Vector3(target.x - global_position.x, 0.0, target.z - global_position.z)
	if to_t.length() > 0.01:
		global_position += to_t.normalized() * move_speed * delta


# Loose bricks spiral up the funnel and get thrown clear at the top.
# [BS:STORM:PATH:END]
func _drag_debris() -> void:
	var c := funnel_pos()
	for root in [debris_root, critter_root]:
		if root != null:
			_drag_in(root, c)


# ============================================================================
# [BS:STORM:DEBRIS_VORTEX]
# Purpose: Forces applied to loose debris and to protected critters.
# Invariants:
# - THESE ARE ACCELERATIONS, NOT FORCES - the mass factor cancels.
#   Anything much above gravity (22) throws bricks clean off the map
#   and the loot never piles up where the player is. This has already
#   been a bug once; keep debris ORBITING.
# - Critters are dragged by exactly this code and are never converted,
#   damaged, or removed. See BS:LAW:NO_HARM.
# - Velocity is capped so a brick cannot accelerate without bound.
# ============================================================================
func _drag_in(root: Node3D, c: Vector3) -> void:
	for child in root.get_children():
		var b := child as RigidBody3D
		if b == null or b.freeze:
			continue
		var to_c := Vector3(c.x - b.global_position.x, 0.0, c.z - b.global_position.z)
		var d := to_c.length()
		if d > suction_radius:
			continue
		var inward := to_c / maxf(d, 0.05)
		var tangent := Vector3(-inward.z, 0.0, inward.x)
		var pull: float = clampf(1.0 - d / suction_radius, 0.0, 1.0)
		# Debris must ORBIT, not escape. Forces here are accelerations (the
		# mass factor cancels), so anything much above gravity throws bricks
		# clean off the map and the loot never piles up where the player is.
		if b.linear_velocity.length() > 24.0:
			continue
		var lift: float = 19.0 * pull
		if b.global_position.y > 15.0:
			lift = -8.0                      # thrown clear over the top
		var f := tangent * (25.0 * pull) + inward * (12.0 * pull) + Vector3.UP * lift
		b.apply_central_force(f * b.mass)
		b.apply_torque(Vector3(pull * 4.0, pull * 9.0, pull * 3.0))
# [BS:STORM:DEBRIS_VORTEX:END]
