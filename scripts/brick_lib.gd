# BRICKSTORM - brick construction library
#
# Everything in the world is built from real brick shapes at a real stud pitch.
# If it cannot be built from parts, it is not in the game (see Docs/GAME_CONCEPT.md §9).
class_name BrickLib
extends RefCounted

# ============================================================================
# [BS:BUILD:PALETTE]
# Purpose: Stud pitch, brick heights and the classic colour palette.
# Invariants:
# - Real LEGO proportions scaled 62.5x: 8mm stud pitch, 9.6mm brick.
# - A minifig must land near 1.5m so it reads against a farmhouse.
# - Palette stays bright and saturated. The SKY carries the dread,
#   not the shading (North Star pillar 2).
# ============================================================================
# --- dimensions (metres) -----------------------------------------------------
# Real LEGO: 8mm stud pitch, 9.6mm brick height, 3.2mm plate. Scaled up 62.5x
# so a minifig lands near 1.5m and reads correctly against a farmhouse.
const STUD    := 0.5
const BRICK_H := 0.6
const PLATE_H := 0.2
const STUD_R  := 0.155
const STUD_H  := 0.12

# --- classic palette ---------------------------------------------------------
const C_RED    := Color(0.72, 0.11, 0.11)
const C_YELLOW := Color(0.96, 0.76, 0.09)
const C_BLUE   := Color(0.05, 0.35, 0.66)
const C_GREEN  := Color(0.14, 0.44, 0.19)
const C_LGREEN := Color(0.35, 0.60, 0.24)
const C_WHITE  := Color(0.94, 0.94, 0.92)
const C_LGREY  := Color(0.63, 0.65, 0.64)
const C_DGREY  := Color(0.31, 0.33, 0.34)
const C_BROWN  := Color(0.36, 0.22, 0.13)
const C_TAN    := Color(0.83, 0.72, 0.51)
const C_BLACK  := Color(0.11, 0.11, 0.12)
const C_TRANS  := Color(0.55, 0.78, 0.88)

# [BS:BUILD:PALETTE:END]

static var _mats: Dictionary = {}
static var _stud_mesh: CylinderMesh = null

static func mat(c: Color) -> StandardMaterial3D:
	var key: int = c.to_rgba32()
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.62
	m.metallic = 0.0
	m.metallic_specular = 0.25
	_mats[key] = m
	return m

static func stud_mesh() -> CylinderMesh:
	if _stud_mesh == null:
		var cm := CylinderMesh.new()
		cm.top_radius = STUD_R
		cm.bottom_radius = STUD_R
		cm.height = STUD_H
		cm.radial_segments = 10
		cm.rings = 0
		_stud_mesh = cm
	return _stud_mesh


# Visual brick: a box plus a MultiMesh of studs on its top face.
# One extra draw call per brick instead of one per stud.
# ============================================================================
# [BS:BUILD:BRICK]
# Purpose: The visual brick: a box plus a MultiMesh of studs on its top face.
# Invariants:
# - Studs are visible on top surfaces. True brick construction is
#   North Star pillar 1 - a box without studs is not a brick.
# - One MultiMesh per brick, not one mesh per stud: an 8-stud brick
#   costs 2 draw calls, not 9.
# ============================================================================
static func brick_visual(sw: int, sd: int, h: float, color: Color, with_studs: bool = true) -> Node3D:
	var root := Node3D.new()
	var size := Vector3(sw * STUD, h, sd * STUD)

	var box := BoxMesh.new()
	box.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = box
	mi.material_override = mat(color)
	root.add_child(mi)

	if with_studs:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = stud_mesh()
		mm.instance_count = sw * sd
		var i := 0
		for x in sw:
			for z in sd:
				var px: float = (float(x) + 0.5) * STUD - size.x * 0.5
				var pz: float = (float(z) + 0.5) * STUD - size.z * 0.5
				var t := Transform3D(Basis(), Vector3(px, h * 0.5 + STUD_H * 0.5, pz))
				mm.set_instance_transform(i, t)
				i += 1
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = mat(color)
		root.add_child(mmi)

	return root


# A brick that has been torn loose: real rigid body, flung by the funnel.
# [BS:BUILD:BRICK:END]
# ============================================================================
# [BS:LAW:NO_HARM]
# Purpose: Enforcement point for North Star Law 1 - nothing that moves is destroyed.
# Invariants:
# - Debris is on collision layer 4 and masks only the world (layer 1).
#   It CANNOT collide with the player (layer 2) or critters (layer 8).
# - This is why a new hazard cannot hurt an actor by existing. Do not
#   widen this mask to 'make debris feel weightier'.
# - A brick becomes a body only when torn. See BS:DESTRUCTION:TEAR.
# ============================================================================
static func brick_body(sw: int, sd: int, h: float, color: Color) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.mass = maxf(0.4, sw * sd * 0.22)
	body.linear_damp = 0.55
	body.angular_damp = 0.40
	body.continuous_cd = false
	body.max_contacts_reported = 0
	body.contact_monitor = false
	# Collision layer 4 = debris. Debris does not collide with the player;
	# Design Law #1 - nothing that moves is ever harmed by falling scenery.
	body.collision_layer = 4
	body.collision_mask = 1

	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(sw * STUD, h, sd * STUD)
	cs.shape = shape
	body.add_child(cs)
	body.add_child(brick_visual(sw, sd, h, color))
	return body


# The collectible stud: the classic 1x1 round plate silhouette.
# [BS:LAW:NO_HARM:END]
# ============================================================================
# [BS:BUILD:STUD]
# Purpose: The collectible stud - a 1x1 round plate silhouette.
# Invariants:
# - Must read as currency at a glance from the game camera.
# ============================================================================
static func stud_visual(color: Color) -> Node3D:
	var root := Node3D.new()
	var base := CylinderMesh.new()
	base.top_radius = 0.20
	base.bottom_radius = 0.20
	base.height = 0.10
	base.radial_segments = 12
	base.rings = 0
	var mi := MeshInstance3D.new()
	mi.mesh = base
	mi.material_override = mat(color)
	root.add_child(mi)

	var top := MeshInstance3D.new()
	top.mesh = stud_mesh()
	top.material_override = mat(color)
	top.position = Vector3(0, 0.10, 0)
	root.add_child(top)
	return root


# Minifig, built the way a minifig is actually built.
# [BS:BUILD:STUD:END]
# ============================================================================
# [BS:BUILD:MINIFIG]
# Purpose: Minifig assembly, built the way a minifig is actually built.
# Invariants:
# - Proportions stay minifig-correct: it is the scale reference for
#   the whole world.
# ============================================================================
static func minifig(shirt: Color, legs: Color, hair: Color, skin: Color = Color(0.96, 0.80, 0.19)) -> Node3D:
	var root := Node3D.new()

	var l := brick_visual(2, 1, 0.62, legs, false)
	l.position = Vector3(0, 0.31, 0)
	root.add_child(l)

	var t := brick_visual(2, 1, 0.52, shirt, false)
	t.position = Vector3(0, 0.88, 0)
	root.add_child(t)

	# arms
	for side in [-1.0, 1.0]:
		var a := brick_visual(1, 1, 0.46, shirt, false)
		a.position = Vector3(side * 0.36, 0.90, 0)
		a.rotation = Vector3(0, 0, side * -0.18)
		root.add_child(a)
		var hand := MeshInstance3D.new()
		var hm := CylinderMesh.new()
		hm.top_radius = 0.10
		hm.bottom_radius = 0.10
		hm.height = 0.14
		hm.radial_segments = 8
		hand.mesh = hm
		hand.material_override = mat(skin)
		hand.position = Vector3(side * 0.44, 0.66, 0.05)
		root.add_child(hand)

	# head
	var head := MeshInstance3D.new()
	var hmesh := CylinderMesh.new()
	hmesh.top_radius = 0.21
	hmesh.bottom_radius = 0.21
	hmesh.height = 0.40
	hmesh.radial_segments = 12
	head.mesh = hmesh
	head.material_override = mat(skin)
	head.position = Vector3(0, 1.34, 0)
	root.add_child(head)

	var pip := MeshInstance3D.new()
	pip.mesh = stud_mesh()
	pip.material_override = mat(skin)
	pip.position = Vector3(0, 1.56, 0)
	root.add_child(pip)

	# hair / cap
	var h := brick_visual(2, 2, 0.22, hair, false)
	h.position = Vector3(0, 1.62, 0)
	h.scale = Vector3(0.52, 1.0, 0.52)
	root.add_child(h)

	return root
# [BS:BUILD:MINIFIG:END]
