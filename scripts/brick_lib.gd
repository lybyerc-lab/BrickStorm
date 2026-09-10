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
static var _brick_mesh: ArrayMesh = null


# ============================================================================
# [BS:BUILD:CHAMFER]
# Purpose: The brick mesh. A LEGO brick is injection-moulded, so every edge
#   carries a small chamfer, and that chamfer is the whole reason a brick reads
#   as moulded plastic rather than as a primitive.
# Invariants:
# - A BARE BoxMesh IS WHY THE WORLD LOOKED LIKE MEGA BLOKS. Sharp edges give a
#   single flat tone per face and no transition between them; the chamfer
#   catches a different light angle from either face it joins, so an edge reads
#   as an edge from any direction. This is the cheapest LEGO signal there is.
# - The chamfer is PROPORTIONAL, not absolute. Every brick in the world shares
#   one mesh so they can batch into a single MultiMesh, and that mesh is scaled
#   per instance - an absolute chamfer would need per-size meshes and would
#   multiply the draw calls the batching exists to remove.
# - Keep it small. Past about 6% the bricks start to look like soap.
# ============================================================================
const CHAMFER := 0.035


static func brick_mesh() -> ArrayMesh:
	if _brick_mesh != null:
		return _brick_mesh
	var c := CHAMFER
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Six inset faces, twelve edge chamfers, eight corner triangles.
	for axis in range(3):
		for dir in [-1.0, 1.0]:
			var n := Vector3.ZERO
			n[axis] = dir
			var u := Vector3.ZERO
			u[(axis + 1) % 3] = 1.0
			var v := Vector3.ZERO
			v[(axis + 2) % 3] = 1.0
			var centre := n * 0.5
			var q := [
				centre + (u * -1.0 + v * -1.0) * (0.5 - c),
				centre + (u * 1.0 + v * -1.0) * (0.5 - c),
				centre + (u * 1.0 + v * 1.0) * (0.5 - c),
				centre + (u * -1.0 + v * 1.0) * (0.5 - c),
			]
			_quad(st, q[0], q[1], q[2], q[3], n, bool(dir > 0.0))

	# Edge chamfers: for each pair of axes, the four edges they share.
	for a in range(3):
		for b in range(a + 1, 3):
			var other := 3 - a - b
			for sa in [-1.0, 1.0]:
				for sb in [-1.0, 1.0]:
					var na := Vector3.ZERO
					na[a] = sa
					var nb := Vector3.ZERO
					nb[b] = sb
					var e := Vector3.ZERO
					e[other] = 1.0
					var p0 := na * 0.5 + nb * (0.5 - c) - e * (0.5 - c)
					var p1 := na * 0.5 + nb * (0.5 - c) + e * (0.5 - c)
					var p2 := na * (0.5 - c) + nb * 0.5 + e * (0.5 - c)
					var p3 := na * (0.5 - c) + nb * 0.5 - e * (0.5 - c)
					var nn := (na + nb).normalized()
					_quad(st, p0, p1, p2, p3, nn, bool(sa * sb > 0.0))

	# Corners.
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var s3 := Vector3(sx, sy, sz)
				var a0 := Vector3(sx * 0.5, sy * (0.5 - c), sz * (0.5 - c))
				var b0 := Vector3(sx * (0.5 - c), sy * 0.5, sz * (0.5 - c))
				var c0 := Vector3(sx * (0.5 - c), sy * (0.5 - c), sz * 0.5)
				var nn := s3.normalized()
				var flip: bool = sx * sy * sz < 0.0
				_tri(st, a0, b0, c0, nn, flip)

	st.generate_tangents()
	_brick_mesh = st.commit()
	return _brick_mesh


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		n: Vector3, flip: bool) -> void:
	if flip:
		_tri(st, a, b, c, n, false)
		_tri(st, a, c, d, n, false)
	else:
		_tri(st, a, c, b, n, false)
		_tri(st, a, d, c, n, false)


# Winding is DERIVED, not asserted. Hand-tracking the orientation of 44
# triangles across six faces, twelve edges and eight corners got 16 of them
# backwards, and a backwards face means you see straight through the brick.
# The part is convex and every face here is supplied with its true outward
# normal, so the geometry can simply be asked which way round it goes.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		n: Vector3, _flip: bool) -> void:
	var p1 := b
	var p2 := c
	if (b - a).cross(c - a).dot(n) < 0.0:
		p1 = c
		p2 = b
	for p in [a, p1, p2]:
		st.set_normal(n)
		st.set_uv(Vector2(p.x + 0.5, p.z + 0.5))
		st.add_vertex(p)
# [BS:BUILD:CHAMFER:END]

# ============================================================================
# [BS:RENDER:PLASTIC]
# Purpose: The one material every brick in the game uses. It is ABS plastic.
# Invariants:
# - RIM IS THE FRESNEL TERM, and it is the difference between plastic and
#   painted cardboard. A dielectric throws back far more light at grazing
#   angles than head-on; without it a brick reads as a flat-shaded box no
#   matter how the lights are placed. TT scale their specular by an explicit
#   fresnel factor for exactly this reason - see Docs/TT_ENGINE_NOTES.md 10.
# - It belongs to BRICKS ONLY. The ground is not plastic; giving a 420m plane
#   a grazing-angle response lights the whole horizon. See terrain_mat, and the
#   specular blowout recorded in Docs/DECISION_LOG.md.
# - rim_tint stays near the middle. At 0 the rim takes the light's colour and
#   every brick gets a white edge; at 1 it takes the albedo and vanishes on
#   dark bricks. The point is a lit EDGE that is still recognisably the
#   brick's own colour.
# - Roughness is low enough to hold a highlight and high enough that the
#   highlight is a soft patch rather than a mirrored dot. Plastic, not chrome.
# ============================================================================
# The ONE definition of what plastic looks like. Structure's MultiMesh batch
# material cannot call mat() - it needs vertex colours, not an albedo - so it
# calls this instead. Before this existed the two hand-copied the same four
# numbers, which meant giving bricks a fresnel term changed the minifig and
# the loose debris and left every building in the game untouched.
# The numbers themselves, so the StandardMaterial3D path and the shader path
# can both be checked against the same source rather than against each other.
const PLASTIC_ROUGHNESS := 0.30
const PLASTIC_METALLIC := 0.0
const PLASTIC_SPECULAR := 0.62
const PLASTIC_RIM := 0.55
const PLASTIC_RIM_TINT := 0.45


static func apply_plastic(m: StandardMaterial3D) -> void:
	m.roughness = PLASTIC_ROUGHNESS
	m.metallic = PLASTIC_METALLIC
	m.metallic_specular = PLASTIC_SPECULAR
	m.rim_enabled = true
	m.rim = PLASTIC_RIM
	m.rim_tint = PLASTIC_RIM_TINT


# Studs get their own material, and it is NOT the full plastic one.
#
# A stud is the smallest curved thing in the game. From a gameplay camera it is
# a few pixels across, and a few pixels of low-roughness curved surface with a
# strong fresnel term is a specular ALIAS: the highlight lands on a sub-pixel
# sliver, the renderer samples the sky reflection instead of the albedo, and
# every stud reads as a dark dithered disc. Up close they looked perfect, which
# is what made this hard to find - it only happens at distance.
#
# TT solve exactly this by scaling specular with a LOD factor so distant
# geometry loses its highlight (Docs/TT_ENGINE_NOTES.md 10). We have no
# per-distance specular on StandardMaterial3D, so the studs simply do not take
# the fresnel: they are rougher and rim-free, and they read as the brick's
# colour from every distance. The flat top still catches the sun.
static func stud_mat(c: Color) -> StandardMaterial3D:
	var key: int = c.to_rgba32() ^ 0x2a2a2a2a
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.62
	m.metallic = 0.0
	m.metallic_specular = 0.30
	m.rim_enabled = false
	# The same reason studs use a dedicated shader in Structure: a stud stands
	# 6cm proud of the brick that casts it into shadow, and its own top reads
	# as shadowed. See shaders/stud.gdshader.
	m.set_flag(BaseMaterial3D.FLAG_DONT_RECEIVE_SHADOWS, true)
	_mats[key] = m
	return m


static func mat(c: Color) -> StandardMaterial3D:
	var key: int = c.to_rgba32()
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	apply_plastic(m)
	_mats[key] = m
	return m
# [BS:RENDER:PLASTIC:END]

# Ground and fields are NOT plastic. Sharing the glossy brick material with a
# 420m plane turns the whole floor into a mirror and puts a specular sun the
# size of a building in the middle of the frame. No rim here either: a
# grazing-angle response on a plane that reaches the horizon IS the horizon.
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

	# The shared chamfered cube, scaled - not a BoxMesh. The minifig and the
	# loose debris are built from these, and they have to be moulded plastic
	# for the same reason every other brick does.
	var mi := MeshInstance3D.new()
	mi.mesh = brick_mesh()
	mi.scale = size
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
		mmi.material_override = stud_mat(color)
		# See Structure.finish: studs self-shadow into dark dithered discs.
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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

	# CANONICAL MINIFIG PROPORTIONS, in the same millimetres as the bricks.
	# Getting these wrong is why the character read as a Roblox avatar: it was
	# 2.91 brick-heights tall where a minifig is 4.17, and its head was half
	# the size it should be. A minifig is SHORT-LEGGED WITH A BIG HEAD - that
	# silhouette is the character. Measured against the demo, see
	# Docs/TT_GAMES_REFERENCE.md.
	var mm := STUD / 8.0                 # our metres per real millimetre
	var leg_h := 17.6 * mm               # hips + legs
	var torso_h := 15.4 * mm
	var head_h := 9.6 * mm
	var head_r := 6.0 * mm               # 12mm diameter - three quarters the torso
	var torso_w := 16.0 * mm
	var torso_d := 8.0 * mm

	var hip_y := leg_h
	var torso_y := hip_y + torso_h * 0.5
	var head_y := hip_y + torso_h + head_h * 0.45   # the head sits down on the neck

	# --- legs: a hip block and two legs, short and wide ---------------------
	var hips := brick_visual(2, 1, leg_h * 0.30, legs, false)
	hips.position = Vector3(0, hip_y - leg_h * 0.15, 0)
	hips.scale = Vector3(1.0, 1.0, torso_d / STUD)
	root.add_child(hips)

	for side in [-1.0, 1.0]:
		var hip := Node3D.new()
		hip.name = "HipR" if side > 0.0 else "HipL"
		hip.position = Vector3(side * torso_w * 0.25, hip_y - leg_h * 0.30, 0)
		root.add_child(hip)
		var leg := brick_visual(1, 1, leg_h * 0.70, legs, false)
		leg.position = Vector3(0, -leg_h * 0.35, 0)
		leg.scale = Vector3(0.92, 1.0, torso_d / STUD)
		hip.add_child(leg)
		var foot := brick_visual(1, 1, 1.6 * mm, C_BLACK, false)
		foot.position = Vector3(0, -leg_h * 0.70 + 0.8 * mm, 1.2 * mm)
		foot.scale = Vector3(0.96, 1.0, (torso_d + 3.0) / STUD)
		hip.add_child(foot)

	# --- torso: a TRAPEZOID, narrow at the neck, flaring to the waist -------
	# Three stacked sections approximate the flare. A plain box is the shape a
	# generic blocky avatar has, and it reads as one.
	# Two sections, not three, and a gentle taper. Three made visible steps and
	# the torso read as a stack of slabs rather than one flaring part.
	var sections := [
		[0.62, 1.00, 0.31],     # body    - height fraction, width fraction, y centre
		[0.40, 0.90, 0.80],     # shoulders, cut back
	]
	for sec in sections:
		var seg := brick_visual(2, 1, torso_h * float(sec[0]), shirt, false)
		seg.position = Vector3(0, hip_y + torso_h * float(sec[2]), 0)
		seg.scale = Vector3(float(sec[1]), 1.0, torso_d / STUD)
		root.add_child(seg)

	# The neck bracket, visible under the chin on the real part.
	# The neck is a peg the head sits ON, and on the real part you barely see
	# it. At full width it reads as a skin-coloured collar.
	var neck := brick_visual(1, 1, 2.4 * mm, skin, false)
	neck.position = Vector3(0, hip_y + torso_h - 0.4 * mm, 0)
	neck.scale = Vector3(0.40, 1.0, 0.40)
	root.add_child(neck)

	# --- arms: hung OUTSIDE the torso, angled out and forward ---------------
	for side in [-1.0, 1.0]:
		var sh := Node3D.new()
		sh.name = "ShoulderR" if side > 0.0 else "ShoulderL"
		# OUTSIDE the torso. At 0.46 of the torso width the arms sat inside its
		# own footprint and were invisible - the silhouette stopped reading as
		# a minifig, which is the one thing the arms are for.
		sh.position = Vector3(side * (torso_w * 0.5 + 1.6 * mm),
			hip_y + torso_h * 0.80, 0)
		root.add_child(sh)
		var a := brick_visual(1, 1, 11.0 * mm, shirt, false)
		a.position = Vector3(0, -5.5 * mm, 0)
		a.scale = Vector3(0.74, 1.0, 0.80)
		a.rotation = Vector3(0.10, 0, side * -0.20)
		sh.add_child(a)
		# A minifig hand is a C-shaped clip, not a peg.
		var hand := Node3D.new()
		hand.position = Vector3(side * 1.6 * mm, -11.8 * mm, 1.8 * mm)
		hand.rotation = Vector3(0.55, 0, 0)
		sh.add_child(hand)
		for seg2 in range(5):
			var ang: float = -PI * 0.72 + float(seg2) * (PI * 1.44 / 4.0)
			var piece := MeshInstance3D.new()
			piece.mesh = brick_mesh()
			piece.scale = Vector3(0.9 * mm, 3.0 * mm, 0.9 * mm)
			piece.position = Vector3(sin(ang) * 1.9 * mm, 0.0, cos(ang) * 1.9 * mm)
			piece.rotation = Vector3(0, ang, 0)
			piece.material_override = mat(skin)
			hand.add_child(piece)

	# --- head: a BIG rounded cylinder --------------------------------------
	var head := MeshInstance3D.new()
	head.mesh = head_mesh()
	# head_mesh() is a unit-RADIUS barrel (diameter 2), so the scale is the
	# radius, not the diameter. Doubling it made the head twice as wide as it
	# was tall and squeezed the printed face into a narrow band, because the
	# texture stretches with the geometry.
	head.scale = Vector3(head_r, head_h, head_r)
	head.material_override = face_material(skin)
	head.position = Vector3(0, head_y, 0)
	head.name = "Head"
	root.add_child(head)

	# The stud on top of the head - the single most identifying feature a
	# minifig has. Hidden under most hair, visible under a hat and bare.
	var hstud := MeshInstance3D.new()
	hstud.mesh = stud_mesh()
	hstud.material_override = mat(skin)
	hstud.position = Vector3(0, head_y + head_h * 0.5 + STUD_H * 0.5, 0)
	hstud.name = "HeadStud"
	root.add_child(hstud)

	# Hair caps the head and overlaps it.
	# Hair sits ON the head and stops just above the brows. Dropped any lower
	# it cuts across the eyes and reads as a welding visor, which is what it
	# was doing - the brows are 2.9mm down from the crown, so the hair's
	# underside has to stay above that.
	var cap := brick_visual(2, 1, 4.0 * mm, hair, false)
	cap.position = Vector3(0, head_y + head_h * 0.5 + 0.6 * mm, 0)
	cap.scale = Vector3(0.88, 1.0, 0.88)
	root.add_child(cap)

	return root


# ============================================================================
# [BS:BUILD:MINIFIG:END]
# [BS:BUILD:FACE]
# Purpose: The minifig face, PRINTED onto the head rather than stuck to it.
# Invariants:
# - IT IS A TEXTURE, NOT GEOMETRY. Built as geometry the features float off a
#   curved surface, cast their own little shadows, and poke past the head's
#   silhouette at the edges - which is exactly what ours did. A real minifig
#   face is pad-printed and perfectly flat, and so is the demo's.
# - BROWS CARRY THE EXPRESSION. Without them a minifig looks vacant no matter
#   what the mouth does. The demo's Indy is brows first, everything else after.
# - Small features. The 1978 smiley has huge dot eyes; every modern face, and
#   every face in the demo, uses small eyes with a pupil and a highlight.
# - Drawn into the middle of the wrap so it lands on the FRONT of the head.
#   The rest of the wrap stays plain skin - the back of a head is blank.
# ============================================================================
# The head is built here rather than taken from CylinderMesh so that the UVs
# are OURS: u = 0.5 is dead ahead (-Z), which is where the face gets printed.
# Relying on the primitive's own UV origin put the face on the back of the
# head. It also lets the top and bottom edges carry a chamfer, like every other
# moulded part in the game.
static var _head_mesh: ArrayMesh = null


static func head_mesh() -> ArrayMesh:
	if _head_mesh != null:
		return _head_mesh
	var seg := 28
	var c := 0.055                      # edge chamfer, as a fraction of height
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Rings: bottom rim, bottom chamfer, body, top chamfer, top rim.
	var rings := [
		[-0.5, 0.90], [-0.5 + c, 0.985], [0.0, 1.0], [0.5 - c, 0.985], [0.5, 0.90],
	]
	for ri in range(rings.size() - 1):
		var y0: float = rings[ri][0]
		var r0: float = rings[ri][1]
		var y1: float = rings[ri + 1][0]
		var r1: float = rings[ri + 1][1]
		for i in range(seg):
			var a0 := TAU * float(i) / float(seg)
			var a1 := TAU * float(i + 1) / float(seg)
			# Angle 0 points at +Z, so u = 0.5 lands on the front of the head.
			# THIS RIG FACES +Z, not Godot's usual -Z: _animate_walk aims it
			# with atan2(x, z). Mapping the face to -Z printed it on the back
			# of the head, and all that showed from the front was the seam.
			var p00 := Vector3(sin(a0) * r0, y0, cos(a0) * r0)
			var p10 := Vector3(sin(a1) * r0, y0, cos(a1) * r0)
			var p11 := Vector3(sin(a1) * r1, y1, cos(a1) * r1)
			var p01 := Vector3(sin(a0) * r1, y1, cos(a0) * r1)
			var u0 := 0.5 + (a0 / TAU if a0 <= PI else (a0 - TAU) / TAU)
			var u1 := 0.5 + (a1 / TAU if a1 <= PI else (a1 - TAU) / TAU)
			if i == seg - 1:
				u1 = u0 + 1.0 / float(seg)
			var v0 := 0.5 - y0
			var v1 := 0.5 - y1
			# Normals matter here as much as UVs: SurfaceTool fixes the vertex
			# format from the FIRST vertex, so a barrel written without normals
			# makes every later set_normal() a silent no-op and the caps come
			# out unlit. Write both, every vertex, from the start.
			var n0 := Vector3(sin(a0), 0.0, cos(a0))
			var n1 := Vector3(sin(a1), 0.0, cos(a1))
			_head_quad(st, p00, p10, p11, p01,
				Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1),
				n0, n1, n1, n0)

	# Caps.
	for top in [false, true]:
		var y: float = 0.5 if top else -0.5
		var n := Vector3(0, 1.0 if top else -1.0, 0)
		for i in range(seg):
			var a0 := TAU * float(i) / float(seg)
			var a1 := TAU * float(i + 1) / float(seg)
			var pa := Vector3(sin(a0) * 0.90, y, cos(a0) * 0.90)
			var pb := Vector3(sin(a1) * 0.90, y, cos(a1) * 0.90)
			var pc := Vector3(0, y, 0)
			_emit_tri(st, pc, pa, pb,
				Vector2(0.02, 0.02), Vector2(0.02, 0.02), Vector2(0.02, 0.02),
				n, n, n)

	st.generate_tangents()
	_head_mesh = st.commit()
	return _head_mesh


static func _head_quad(st: SurfaceTool, a: Vector3, b: Vector3, cc: Vector3, d: Vector3,
		ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2,
		na: Vector3, nb: Vector3, nc: Vector3, nd: Vector3) -> void:
	# Winding derived from the normal, not tracked by hand. Flipping the head's
	# facing direction by one sign inverted every triangle and turned the head
	# inside out - the identical mistake already recorded for the brick mesh,
	# made a second time. Deriving it means a sign change can never do this.
	_emit_tri(st, a, b, cc, ua, ub, uc, na, nb, nc)
	_emit_tri(st, a, cc, d, ua, uc, ud, na, nc, nd)


static func _emit_tri(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3,
		t0: Vector2, t1: Vector2, t2: Vector2,
		n0: Vector3, n1: Vector3, n2: Vector3) -> void:
	var face_n := (n0 + n1 + n2).normalized()
	var order := [[p0, t0, n0], [p1, t1, n1], [p2, t2, n2]]
	if (p1 - p0).cross(p2 - p0).dot(face_n) < 0.0:
		order = [[p0, t0, n0], [p2, t2, n2], [p1, t1, n1]]
	for e in order:
		st.set_normal(e[2])
		st.set_uv(e[1])
		st.add_vertex(e[0])


# The texture wraps the whole head, so its aspect has to match the head's:
# u spans the circumference (pi * 12mm) and v spans the height (9.6mm). At
# 256x128 the pixels were twice as tall as they were wide and every feature
# came out stretched. 512x128 makes them square.
const FACE_W := 512
const FACE_H := 128
const HEAD_MM := 12.0                  # head diameter, real minifig
const HEAD_H_MM := 9.6


static func face_texture(skin: Color) -> ImageTexture:
	var key := "face_%d" % skin.to_rgba32()
	if _mats.has(key):
		return _mats[key]
	var img := Image.create(FACE_W, FACE_H, false, Image.FORMAT_RGBA8)
	img.fill(skin)

	# Everything below is in real minifig millimetres, converted once. Laying a
	# face out in pixels means re-guessing it every time the texture changes
	# size, and the proportions are the whole point.
	var ppm := float(FACE_H) / HEAD_H_MM        # pixels per millimetre
	var cx := FACE_W * 0.5
	var ink := C_BLACK

	# Vertical layout, measured from the top of the head.
	var brow_y := 2.9 * ppm
	var eye_y := 4.1 * ppm
	var mouth_y := 6.7 * ppm
	var eye_dx := 2.5 * ppm

	for side in [-1.0, 1.0]:
		# Brow: a bar with the outer end lifted. This is what gives a minifig
		# an expression - the demo's Indy is brows first.
		var bx: float = cx + side * eye_dx
		var half := 1.7 * ppm
		for i in range(30):
			var t := float(i) / 29.0
			var x := int(bx + (t - 0.5) * half * 2.0)
			var lift: float = -t * 0.45 * ppm if side > 0.0 else -(1.0 - t) * 0.45 * ppm
			_dot(img, x, int(brow_y + lift), int(maxf(0.22 * ppm, 1.0)), ink)

		# Eye: small, with a pupil highlight. The huge dot eye is the 1978 face.
		var ex: float = cx + side * eye_dx
		_disc(img, ex, eye_y, 0.80 * ppm, ink)
		_disc(img, ex + 0.22 * ppm, eye_y - 0.26 * ppm, 0.24 * ppm, Color(1, 1, 1, 1))

	# Mouth: a thin curve, ends lifted.
	for i in range(56):
		var t2 := float(i) / 55.0
		var f := t2 * 2.0 - 1.0
		_dot(img, int(cx + f * 1.9 * ppm), int(mouth_y - f * f * 0.55 * ppm),
			int(maxf(0.16 * ppm, 1.0)), ink)

	# Stubble, which is most of what makes the demo's Indy read as Indy.
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260910
	for i in range(240):
		var a := rng.randf() * TAU
		var rr := 1.6 + rng.randf() * 1.5
		var sx := cx + cos(a) * rr * ppm * 1.25
		var sy := mouth_y - 0.2 * ppm + sin(a) * rr * ppm * 0.62
		if sy < eye_y + 0.9 * ppm or sy > HEAD_H_MM * ppm - 0.4 * ppm:
			continue
		if absf(sx - cx) > 3.1 * ppm:
			continue
		_dot(img, int(sx), int(sy), 1, Color(ink.r, ink.g, ink.b, 0.62))

	var tex := ImageTexture.create_from_image(img)
	_mats[key] = tex
	return tex


static func _dot(img: Image, x: int, y: int, r: int, c: Color) -> void:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if dx * dx + dy * dy > r * r:
				continue
			var px := x + dx
			var py := y + dy
			if px < 0 or py < 0 or px >= img.get_width() or py >= img.get_height():
				continue
			if c.a >= 1.0:
				img.set_pixel(px, py, c)
			else:
				img.set_pixel(px, py, img.get_pixel(px, py).lerp(c, c.a))


static func _disc(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	_dot(img, int(cx), int(cy), int(r), c)


static func face_material(skin: Color) -> ShaderMaterial:
	var key := "facemat_%d" % skin.to_rgba32()
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/face.gdshader")
	m.set_shader_parameter("face_tex", face_texture(skin))
	m.set_shader_parameter("p_roughness", PLASTIC_ROUGHNESS)
	m.set_shader_parameter("p_specular", PLASTIC_SPECULAR)
	m.set_shader_parameter("p_rim", PLASTIC_RIM * 0.5)   # a face is not a mirror
	_mats[key] = m
	return m
# [BS:BUILD:FACE:END]
