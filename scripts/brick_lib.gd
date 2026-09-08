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
	m.roughness = 0.36
	m.metallic = 0.0
	m.metallic_specular = 0.48
	_mats[key] = m
	return m

# Ground and fields are NOT plastic. Sharing the glossy brick material with a
# 420m plane turns the whole floor into a mirror and puts a specular sun the
# size of a building in the middle of the frame.
static func terrain_mat(c: Color) -> StandardMaterial3D:
	var key: int = c.to_rgba32() ^ 0x5f5f5f5f
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	m.metallic = 0.0
	m.metallic_specular = 0.0
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

	# Real minifig proportions: legs ~1.5 bricks, torso ~1.5, head ~1, and the
	# arms hang OUTSIDE the torso. Getting the arms wrong buries them inside the
	# body and the silhouette stops reading as a minifig at all.
	var hips := brick_visual(2, 1, 0.16, legs, false)
	hips.position = Vector3(0, 0.68, 0)
	hips.scale = Vector3(0.94, 1.0, 0.92)
	root.add_child(hips)

	for side in [-1.0, 1.0]:
		var hip := Node3D.new()
		hip.name = "HipR" if side > 0.0 else "HipL"
		hip.position = Vector3(side * 0.22, 0.64, 0)
		root.add_child(hip)
		var leg := brick_visual(1, 1, 0.60, legs, false)
		leg.position = Vector3(0, -0.30, 0)
		leg.scale = Vector3(0.80, 1.0, 0.92)
		hip.add_child(leg)
		var foot := brick_visual(1, 1, 0.09, C_BLACK, false)
		foot.position = Vector3(0, -0.61, 0.05)
		foot.scale = Vector3(0.84, 1.0, 1.20)
		hip.add_child(foot)

	# torso tapers slightly toward the neck, like the real part
	var t := brick_visual(2, 1, 0.56, shirt, false)
	t.position = Vector3(0, 0.99, 0)
	root.add_child(t)
	var neck := brick_visual(1, 1, 0.10, shirt, false)
	neck.position = Vector3(0, 1.30, 0)
	neck.scale = Vector3(0.9, 1.0, 0.8)
	root.add_child(neck)

	for side in [-1.0, 1.0]:
		var sh := Node3D.new()
		sh.name = "ShoulderR" if side > 0.0 else "ShoulderL"
		sh.position = Vector3(side * 0.52, 1.16, 0)
		root.add_child(sh)
		var a := brick_visual(1, 1, 0.40, shirt, false)
		a.position = Vector3(0, -0.20, 0)
		a.scale = Vector3(0.56, 1.0, 0.72)
		a.rotation = Vector3(0, 0, side * -0.20)
		sh.add_child(a)
		var hand := MeshInstance3D.new()
		var hm := CylinderMesh.new()
		hm.top_radius = 0.085
		hm.bottom_radius = 0.085
		hm.height = 0.12
		hm.radial_segments = 8
		hand.mesh = hm
		hand.material_override = mat(skin)
		hand.position = Vector3(side * 0.06, -0.42, 0.04)
		hand.rotation = Vector3(0.6, 0, 0)
		sh.add_child(hand)

	var head := MeshInstance3D.new()
	var hmesh := CylinderMesh.new()
	hmesh.top_radius = 0.195
	hmesh.bottom_radius = 0.195
	hmesh.height = 0.38
	hmesh.radial_segments = 16
	head.mesh = hmesh
	head.material_override = mat(skin)
	head.position = Vector3(0, 1.54, 0)
	head.name = "Head"
	root.add_child(head)
	_add_face(head, 0.204)

	# Hair caps the head and overlaps it - a box floating above the skull is
	# the single most obvious tell that a model is not a minifig.
	var h := brick_visual(2, 2, 0.20, hair, false)
	h.position = Vector3(0, 1.76, 0)
	h.scale = Vector3(0.44, 1.0, 0.44)
	root.add_child(h)
	return root


# The classic two-dots-and-a-smile. Nothing else makes a shape read as a
# minifig this cheaply - without a face it is a yellow cylinder on a box.
static func _add_face(head: MeshInstance3D, r: float) -> void:
	var ink := mat(C_BLACK)
	for ex in [-0.082, 0.082]:
		var eye := MeshInstance3D.new()
		var em := CylinderMesh.new()
		em.top_radius = 0.036
		em.bottom_radius = 0.036
		em.height = 0.020
		em.radial_segments = 14
		eye.mesh = em
		eye.material_override = ink
		eye.position = Vector3(ex, 0.052, r)
		eye.rotation = Vector3(PI * 0.5, 0, 0)
		head.add_child(eye)

	for i in range(5):
		var f: float = (float(i) / 4.0) * 2.0 - 1.0        # -1 .. 1
		var dot := MeshInstance3D.new()
		var dm := CylinderMesh.new()
		dm.top_radius = 0.023
		dm.bottom_radius = 0.023
		dm.height = 0.020
		dm.radial_segments = 12
		dot.mesh = dm
		dot.material_override = ink
		# ends ride up: a smile, not a frown
		dot.position = Vector3(f * 0.078, -0.070 + absf(f) * 0.040, r)
		dot.rotation = Vector3(PI * 0.5, 0, 0)
		head.add_child(dot)
# [BS:BUILD:MINIFIG:END]
