# Builds the Wakita farm town out of bricks.
class_name PropBuilder
extends RefCounted

const S := 0.5      # stud pitch      (BrickLib.STUD)
const H := 0.6      # brick height    (BrickLib.BRICK_H)


# A staggered brick wall running along `dir` from the `start` corner.
# ============================================================================
# [BS:BUILD:TOWN]
# Purpose: The farm town prop set - every structure the funnel can take apart.
# Invariants:
# - Every prop is assembled from real parts at stud pitch (pillar 1).
# - Courses are staggered like real brickwork; it is most of what
#   makes a wall read as built rather than extruded.
# - Props must survive being torn brick-by-brick, so no prop may rely
#   on a single mesh for its silhouette.
# - A ROOF IS MADE OF SLOPE BRICKS, NOT OF TILTED SLABS. Every roof in this
#   file used to be a box rotated by a hand-picked angle, which is the single
#   loudest tell that a model was not built from parts - "a game with mega
#   blocks in it" was the note, and the roofs were most of it. Roofs go
#   through _stepped_roof, which lays real slope courses stepping in one stud
#   and up one course at a time, exactly as the part is used in a real model.
# - ROUND THINGS ARE ROUND PARTS. Trunks, silo caps, wheels, barrels, tyres
#   and tower legs are cylinders and cones, not rings of little boxes.
# - SMOOTH SURFACES ARE TILES. A drive-in screen, a bench seat or a road sign
#   with studs on it reads as unfinished; that is what tiles are for.
# - Part variety costs a draw call per kind per prop (see BS:DESTRUCTION:
#   STRUCTURE), so a prop uses a small deliberate palette, not everything.
# - THE SET HAS TO SAY WHERE IT IS, not just what it is. A barn and a silo make
#   any farm anywhere; the Great Plains specifically are utility poles marching
#   to a flat horizon, a grain elevator on the skyline, a lattice aermotor with
#   a tail vane, barbed wire on leaning posts, and trees only in shelterbelt
#   rows. The director's note on the first hybrid build was that it did not
#   scream Oklahoma - it had a white picket fence and a Dutch windmill in it,
#   which are the wrong continent twice over. A prop that could stand in any
#   farmyard on earth is doing half its job.
# ============================================================================
static func _wall(st: Structure, start: Vector3, dir: Vector3, length_studs: int,
		courses: int, color: Color, brick_len: int = 4, depth: int = 2) -> void:
	var total := float(length_studs) * S
	var rot := Vector3.ZERO
	if absf(dir.z) > 0.5:
		rot.y = PI * 0.5
	for c in range(courses):
		var y: float = start.y + float(c) * H + H * 0.5
		var along := 0.0
		var first := true
		while along < total - 0.001:
			var bl := brick_len
			if first and c % 2 == 1:
				bl = maxi(1, brick_len / 2)      # stagger the courses
			var remain := int(round((total - along) / S))
			if remain < bl:
				bl = remain
			if bl <= 0:
				break
			var centre := start + dir * (along + float(bl) * S * 0.5)
			centre.y = y
			st.add_brick(bl, depth, H, color, centre, rot)
			along += float(bl) * S
			first = false


# A roof, built the way a roof is built: courses of slope bricks, each one
# stud further in and one course higher, with the gable ends filled in behind
# them so the staircase reads as a solid wall rather than a set of floating
# shelves. `sections` is a list of [courses, rise] so one call can do a barn's
# gambrel - a steep lower pitch and a shallow upper one - as well as a plain
# gable. Slopes descend toward +Z by default, so each side is yawed a quarter
# turn to face outward.
static func _stepped_roof(st: Structure, half_w: int, length: int, base_y: float,
		sections: Array, color: Color, z_centre: float = 0.0) -> void:
	# Each course is TWO studs deep - one stud of slope, one of studded flat -
	# and steps in by one, so the course above lands squarely on the flat and
	# hides its studs. That is how the real part stacks, and the two sides meet
	# exactly at the ridge after half_w - 1 courses.
	var max_courses := half_w - 1
	var course := 0
	var y := base_y
	for sec in sections:
		var rise: float = sec[1]
		for i in range(int(sec[0])):
			if course >= max_courses:
				break
			var outer := half_w - course        # outer edge, in studs
			for sgn in [-1.0, 1.0]:
				var x: float = sgn * (float(outer) - 1.0) * S
				# The slope courses stop one stud short of each end so the
				# gable filler below can close the triangle without fighting
				# them for the same space.
				st.add_part(BrickLib.PART_SLOPE, maxi(1, length - 2), 2, rise, color,
					Vector3(x, y + rise * 0.5, z_centre),
					Vector3(0, sgn * PI * 0.5, 0))
			# Gable ends: one brick per course spanning what is left of the
			# width, at each end of the run.
			for zs in [-1.0, 1.0]:
				st.add_brick(outer * 2, 1, rise, color,
					Vector3(0, y + rise * 0.5,
						z_centre + zs * (float(length) - 1.0) * S * 0.5))
			y += rise
			course += 1
	# The ridge cap. A tile, because the top of a roof is smooth. Two studs
	# ACROSS the roof and the full length ALONG it - it used to be the other
	# way round, and a 10-metre plate stuck out sideways over the barn.
	st.add_part(BrickLib.PART_TILE, 2, length, BrickLib.PLATE_H, color,
		Vector3(0, y + BrickLib.PLATE_H * 0.5, z_centre))


static func barn(pos: Vector3) -> Structure:
	var st := Structure.new()
	st.position = pos
	var w := 14
	var d := 20
	var hw := float(w) * S * 0.5
	var hd := float(d) * S * 0.5
	var red := BrickLib.C_RED
	var white := BrickLib.C_WHITE

	for i in range(4):
		var courses := 6
		match i:
			0: _wall(st, Vector3(-hw, 0, -hd), Vector3(1, 0, 0), w, courses, red)
			1: _wall(st, Vector3(-hw, 0, hd), Vector3(1, 0, 0), w, courses, red)
			2: _wall(st, Vector3(-hw, 0, -hd), Vector3(0, 0, 1), d, courses, red)
			3: _wall(st, Vector3(hw, 0, -hd), Vector3(0, 0, 1), d, courses, red)

	# white trim course on top of the walls
	_wall(st, Vector3(-hw, 6.0 * H, -hd), Vector3(1, 0, 0), w, 1, white, 4, 2)
	_wall(st, Vector3(-hw, 6.0 * H, hd), Vector3(1, 0, 0), w, 1, white, 4, 2)

	# A GAMBREL, in slope bricks: a steep lower pitch and a shallow upper one,
	# which is the shape that makes a barn a barn. It used to be four slabs
	# tipped at 1.02 and 0.39 radians - numbers chosen to look right from one
	# angle, with sharp box edges wherever they met.
	var wall_top := 6.0 * H + H
	# Two steep courses then five shallow: the real gambrel break. The roof is
	# one stud wider and two studs longer than the wall centre-lines, because
	# _wall straddles the corner it is given - the walls stand a stud proud of
	# hw/hd, and a roof sized to hw left a band of bare studded wall-top
	# showing all the way round.
	_stepped_roof(st, w / 2 + 1, d + 2, wall_top, [[3, H * 1.4], [4, H * 0.55]], red)

	# big white doors on the -Z face, under an arch
	st.add_brick(4, 1, H * 5.0, white, Vector3(-1.1, H * 2.5, -hd - 0.2))
	st.add_brick(4, 1, H * 5.0, white, Vector3(1.1, H * 2.5, -hd - 0.2))
	st.add_part(BrickLib.PART_ARCH, 10, 1, H * 2.0, white,
		Vector3(0, H * 6.0, -hd - 0.2))
	st.finish()
	return st


static func farmhouse(pos: Vector3) -> Structure:
	var st := Structure.new()
	st.position = pos
	var w := 12
	var d := 14
	var hw := float(w) * S * 0.5
	var hd := float(d) * S * 0.5
	var body := BrickLib.C_WHITE
	var roof := BrickLib.C_DGREY

	_wall(st, Vector3(-hw, 0, -hd), Vector3(1, 0, 0), w, 5, body)
	_wall(st, Vector3(-hw, 0, hd), Vector3(1, 0, 0), w, 5, body)
	_wall(st, Vector3(-hw, 0, -hd), Vector3(0, 0, 1), d, 5, body)
	_wall(st, Vector3(hw, 0, -hd), Vector3(0, 0, 1), d, 5, body)

	# windows
	for zz in [-1.5, 1.5]:
		for sx in [-1.0, 1.0]:
			st.add_brick(2, 1, H * 2.0, BrickLib.C_TRANS,
				Vector3(sx * (hw + 0.15), H * 2.6, zz))
			# A cheese slope sill under each window. Cheap, and it is the kind
			# of one-part detail that separates a built model from a box.
			st.add_part(BrickLib.PART_CHEESE, 2, 1, BrickLib.PLATE_H * 1.4,
				BrickLib.C_WHITE,
				Vector3(sx * (hw + 0.22), H * 2.6 - H, zz),
				Vector3(0, sx * PI * 0.5, 0), false)
	st.add_brick(2, 1, H * 4.0, BrickLib.C_BROWN, Vector3(0, H * 2.0, -hd - 0.15))

	# Eaves first: a course of inverted slopes standing one stud proud of the
	# wall. This is the part that makes a roof look like it was seated on a
	# house rather than balanced on it, and it is invisible until it is missing.
	var top := 5.0 * H
	for sgn in [-1.0, 1.0]:
		# No studs on the eave: it lives under the roof, and the only thing
		# exposed studs can do there is show through the join.
		st.add_part(BrickLib.PART_SLOPE_INV, d + 2, 1, BrickLib.PLATE_H * 1.6, roof,
			Vector3(sgn * (hw + S * 0.5), top + BrickLib.PLATE_H * 0.8, 0),
			Vector3(0, sgn * PI * 0.5, 0), false)
	# gable roof in slope courses
	# A plain 45-degree gable: one brick of rise per stud of run. Sized to the
	# outside of the walls, not to hw - see the barn.
	_stepped_roof(st, w / 2 + 1, d + 2, top + BrickLib.PLATE_H * 1.6, [[6, H]], roof)

	# chimney, tall enough to clear the ridge, capped with a tile
	st.add_brick(2, 2, H * 6.0, BrickLib.C_BROWN, Vector3(1.6, top + H * 3.0, 2.0))
	st.add_part(BrickLib.PART_TILE, 2, 2, BrickLib.PLATE_H, BrickLib.C_DGREY,
		Vector3(1.6, top + H * 6.0 + BrickLib.PLATE_H * 0.5, 2.0))

	# porch: round posts, a tiled deck, and its own little slope roof
	for xx in [-hw + 0.3, hw - 0.3]:
		st.add_part(BrickLib.PART_ROUND, 1, 1, H * 4.0, body,
			Vector3(xx, H * 2.0, -hd - 1.4), Vector3.ZERO, false)
	st.add_part(BrickLib.PART_TILE, w, 4, 0.2, body, Vector3(0, H * 4.2, -hd - 0.8))
	for i in range(2):
		st.add_part(BrickLib.PART_SLOPE, w, 2, H * 0.5, roof,
			Vector3(0, H * 4.3 + H * 0.5 * float(i) + H * 0.25,
				-hd - 0.9 + S * float(i)), Vector3(0, PI, 0))
	st.finish()
	return st


static func silo(pos: Vector3) -> Structure:
	var st := Structure.new()
	st.position = pos
	# A DRUM OF ROUND BRICKS. This was ten little boxes per course arranged in
	# a ring, staggered course to course, and every one of them had two corners
	# sticking out past the circle - so the silo read as a castellated tower of
	# blocks rather than as a cylinder.
	# PLATE-THICK COURSES. A silo is ribbed, so a stack of thin rings is both
	# the right silhouette and enough pieces to be worth tearing down - this
	# one doubles as the set piece's heavy gate (BS:CONTENT:ABILITY_GATE), and
	# at four thick rings the gate came apart in three grabs.
	var courses := 21
	var ch := BrickLib.PLATE_H
	for c in range(courses):
		st.add_part(BrickLib.PART_ROUND, 6, 6, ch, BrickLib.C_LGREY,
			Vector3(0, float(c) * ch + ch * 0.5, 0), Vector3.ZERO, c == courses - 1)
	# A CONE roof, which is what a silo has. The cap used to be the same ring
	# of wall bricks tipped inward by 0.42 radians, and it read as a crown of
	# blocks balanced on a drum rather than as a roof.
	var cap_y := 4.2
	st.add_part(BrickLib.PART_CONE, 7, 7, 1.1, BrickLib.C_DGREY,
		Vector3(0, cap_y + 0.55, 0))
	st.add_part(BrickLib.PART_ROUND, 1, 1, 0.32, BrickLib.C_DGREY,
		Vector3(0, cap_y + 1.26, 0))
	st.finish()
	return st


static func water_tower(pos: Vector3) -> Structure:
	var st := Structure.new()
	st.position = pos
	var legs := 4
	for i in range(legs):
		var a: float = TAU * float(i) / float(legs) + PI * 0.25
		var p := Vector3(cos(a) * 1.5, 2.2, sin(a) * 1.5)
		# Round legs. A water tower stands on poles, and four square posts was
		# the reason this prop read as scaffolding.
		st.add_part(BrickLib.PART_ROUND, 1, 1, 4.4, BrickLib.C_DGREY, p,
			Vector3(0, -a, 0), false)
	# Cross-bracing, in tiles. Four bare legs looked like the tank was hovering
	# over them; the braces are what make it read as a structure.
	for i in range(legs):
		var a0: float = TAU * float(i) / float(legs) + PI * 0.25
		var a1: float = TAU * float(i + 1) / float(legs) + PI * 0.25
		var p0 := Vector3(cos(a0) * 1.5, 0.0, sin(a0) * 1.5)
		var p1 := Vector3(cos(a1) * 1.5, 0.0, sin(a1) * 1.5)
		var mid := (p0 + p1) * 0.5
		var span := p0.distance_to(p1)
		var yaw := atan2(p1.x - p0.x, p1.z - p0.z)
		for band in [1.4, 3.0]:
			st.add_part(BrickLib.PART_TILE, int(round(span / S)), 1, 0.16,
				BrickLib.C_DGREY, Vector3(mid.x, band, mid.z),
				Vector3(0, yaw + PI * 0.5, 0), false)
	# The tank: stacked round bricks, not a ring of boxes.
	for c in range(8):
		st.add_part(BrickLib.PART_ROUND, 8, 8, H * 0.5, BrickLib.C_LGREEN,
			Vector3(0, 4.6 + float(c) * H * 0.5, 0), Vector3.ZERO, false)
	st.add_part(BrickLib.PART_CONE, 8, 8, 0.9, BrickLib.C_DGREY, Vector3(0, 7.45, 0))
	st.finish()
	return st


# Bend rises up the tree: the trunk is planted, the canopy moves, the top tuft
# moves most. This is the weight TT paint into a plant mesh - here the
# generator emits it, because the generator IS our modelling tool.
static func tree(pos: Vector3, scale_f: float = 1.0) -> Structure:
	var st := Structure.new()
	st.position = pos
	# The trunk is PLANTED. Bend is per brick and a brick cannot taper, so any
	# bend at all here slides the trunk's base along the ground.
	# A ROUND trunk. A tree with a square trunk is the single most obvious
	# thing in a field of them, and there are a lot of them in this field.
	st.add_part(BrickLib.PART_ROUND, 2, 2, 2.0 * scale_f, BrickLib.C_BROWN,
		Vector3(0, 1.0 * scale_f, 0), Vector3.ZERO, false, 0.0)
	var g := BrickLib.C_GREEN
	st.add_brick(5, 5, H, g, Vector3(0, 2.2 * scale_f, 0), Vector3.ZERO, true, 0.40)
	st.add_brick(4, 4, H, g, Vector3(0.2, 2.2 * scale_f + H, -0.1), Vector3.ZERO, true, 0.62)
	st.add_part(BrickLib.PART_ROUND, 3, 3, H, g,
		Vector3(0.05, 2.2 * scale_f + H * 2.0, 0.05), Vector3.ZERO, true, 0.80)
	# The tuft is a cone: it gives the canopy a top instead of ending on a
	# flat square, and it takes the most bend of anything on the tree.
	st.add_part(BrickLib.PART_CONE, 3, 3, H * 1.8, BrickLib.C_LGREEN,
		Vector3(0.0, 2.2 * scale_f + H * 3.4, 0.0), Vector3.ZERO, true, 1.0)
	st.finish()
	return st


static func fence_run(from: Vector3, to: Vector3) -> Structure:
	# BARBED WIRE ON WEATHERED POSTS. This was a white picket fence, which is
	# New England suburbia - out on the plains it is a leaning wooden post and
	# three strands of wire, and nothing else. The director's note on the first
	# hybrid build was that the world did not read as Oklahoma, and a white
	# picket fence in frame is one of the reasons.
	var st := Structure.new()
	st.position = from
	var delta := to - from
	var length := delta.length()
	var dir := delta.normalized()
	var yaw := atan2(dir.x, dir.z)
	var posts := int(length / 2.4)
	for i in range(posts + 1):
		var p := dir * (float(i) * 2.4)
		# Posts lean. A dead-straight fence line reads as a fence you bought;
		# a leaning one reads as a fence that has been standing in the wind.
		var lean: float = fmod(float(i) * 0.37, 0.18) - 0.09
		st.add_part(BrickLib.PART_ROUND, 1, 1, 1.35, BrickLib.C_BROWN,
			Vector3(p.x, 0.66, p.z), Vector3(lean, yaw, lean * 0.6), false)
		if i < posts:
			var m := dir * (float(i) * 2.4 + 1.2)
			# Three strands. Galvanised, so LIGHT grey - barbed wire really is,
			# and near-black strands tore off into a blizzard of dark confetti
			# that read as holes punched in the field.
			for h in [1.15, 0.82, 0.49]:
				st.add_part(BrickLib.PART_TILE, 5, 1, 0.07, BrickLib.C_LGREY,
					Vector3(m.x, h, m.z), Vector3(0, yaw + PI * 0.5, 0), false)
	st.finish()
	return st


# A line of utility poles marching to a flat horizon. See the PLACE invariant
# on BS:BUILD:TOWN - this prop exists to answer "where", not "what".
static func power_line(from: Vector3, to: Vector3) -> Structure:
	var st := Structure.new()
	st.position = from
	var delta := to - from
	var length := delta.length()
	var dir := delta.normalized()
	var yaw := atan2(dir.x, dir.z)
	var spans := maxi(1, int(length / 14.0))
	for i in range(spans + 1):
		var p := dir * (float(i) * 14.0)
		# The pole, and the crossarm with its insulators.
		st.add_part(BrickLib.PART_ROUND, 1, 1, 7.2, BrickLib.C_BROWN,
			Vector3(p.x, 3.6, p.z), Vector3(0, yaw, 0), false)
		# `yaw` puts a tile's long axis ACROSS the run; `yaw + PI/2` puts it
		# along. The crossarm had the wire's rotation and lay parallel to the
		# line it was supposed to be carrying.
		st.add_part(BrickLib.PART_TILE, 6, 1, 0.22, BrickLib.C_BROWN,
			Vector3(p.x, 6.85, p.z), Vector3(0, yaw, 0), false)
		for sx in [-0.85, 0.0, 0.85]:
			var off := Vector3(cos(yaw) * sx, 0, -sin(yaw) * sx)
			st.add_part(BrickLib.PART_ROUND, 1, 1, 0.28, BrickLib.C_LGREY,
				Vector3(p.x + off.x, 7.1, p.z + off.z), Vector3.ZERO, false)
		if i < spans:
			# The wires. TWO SEGMENTS PER SPAN, each a full half-span long and
			# tilted, so the line sags between poles instead of being drawn
			# taut - and so it actually REACHES the poles. A single 7.5m tile
			# in a 14m span left three metres of air at each end and read as a
			# plank floating in the sky, which is what the first render showed.
			var d0 := float(i) * 14.0
			var tilt := atan2(0.30, 7.0)
			for sx2 in [-0.85, 0.0, 0.85]:
				var off2 := Vector3(cos(yaw) * sx2, 0, -sin(yaw) * sx2)
				for half in range(2):
					var c := dir * (d0 + 3.5 + float(half) * 7.0)
					st.add_part(BrickLib.PART_TILE, 14, 1, 0.06, BrickLib.C_DGREY,
						Vector3(c.x + off2.x, 6.88, c.z + off2.z),
						Vector3(0, yaw + PI * 0.5, tilt * (1.0 if half == 0 else -1.0)),
						false)
	st.finish()
	return st


# A barn OPEN AT BOTH ENDS - a tunnel you can drive through. The ordinary barn
# is closed on all four sides with doors on one face; this one is two side
# walls and a roof, sized so a pickup clears it. See BS:CONTENT:SCENES.
static func open_barn(pos: Vector3, yaw: float = 0.0) -> Structure:
	var st := Structure.new()
	st.position = pos
	st.rotation.y = yaw
	var w := 12
	var d := 30
	var courses := 10
	var hw := float(w) * S * 0.5
	var hd := float(d) * S * 0.5
	var red := BrickLib.C_RED
	# Side walls only, and long: at 12 x 30 studs the opening is two and a half
	# times deeper than it is wide, which is what makes it read as a tunnel you
	# run THROUGH rather than an arch you step past. The first pass was 12 x 20
	# and rendered as a gateway - the field beyond filled the whole opening.
	_wall(st, Vector3(-hw, 0, -hd), Vector3(0, 0, 1), d, courses, red)
	_wall(st, Vector3(hw, 0, -hd), Vector3(0, 0, 1), d, courses, red)
	# White trim: a band right round the top, sides and both open ends, so the
	# ends read as a framed DOORWAY. Two earlier tries read wrong head-on - a
	# band that stopped flush at the opening looked like a white patch stuck to
	# each corner, and full-height corner boards turned the barn into a gazebo
	# with two bright columns. Trim that runs horizontally frames the hole;
	# trim that runs vertically competes with it.
	var trim_y := float(courses) * H
	for sx in [-hw, hw]:
		_wall(st, Vector3(sx, trim_y, -hd), Vector3(0, 0, 1), d, 1,
			BrickLib.C_WHITE, 4, 2)
	for sz in [-hd + S, hd - S]:
		st.add_brick(w + 2, 2, H, BrickLib.C_WHITE,
			Vector3(0, trim_y + H * 0.5, sz), Vector3.ZERO, false)
	# The roof runs the other way from a normal barn: its ridge follows the
	# tunnel, so both ends stay open.
	_stepped_roof(st, w / 2 + 1, d + 2, float(courses + 1) * H,
		[[3, H * 1.4], [3, H * 0.55]], red)
	st.finish()
	return st


# The projection booth and snack bar at a drive-in. Small, square, and the only
# thing between the cars and the road.
static func booth(pos: Vector3, yaw: float = 0.0) -> Structure:
	var st := Structure.new()
	st.position = pos
	st.rotation.y = yaw
	var w := 8
	var d := 6
	var hw := float(w) * S * 0.5
	var hd := float(d) * S * 0.5
	var body := BrickLib.C_TAN
	_wall(st, Vector3(-hw, 0, -hd), Vector3(1, 0, 0), w, 5, body)
	_wall(st, Vector3(-hw, 0, hd), Vector3(1, 0, 0), w, 5, body)
	_wall(st, Vector3(-hw, 0, -hd), Vector3(0, 0, 1), d, 5, body)
	_wall(st, Vector3(hw, 0, -hd), Vector3(0, 0, 1), d, 5, body)
	# The serving window, and a flat felt roof.
	st.add_brick(4, 1, H * 2.0, BrickLib.C_TRANS, Vector3(0, H * 3.0, -hd - 0.15))
	st.add_part(BrickLib.PART_TILE, w + 2, d + 2, BrickLib.PLATE_H, BrickLib.C_DGREY,
		Vector3(0, 5.0 * H + BrickLib.PLATE_H * 0.5, 0))
	st.add_part(BrickLib.PART_ROUND, 1, 1, 1.4, BrickLib.C_LGREY,
		Vector3(hw - 0.4, 5.0 * H + 0.7, hd - 0.4), Vector3.ZERO, false)
	st.finish()
	return st


# A STORM CELLAR: the sloped double doors set into the ground beside a
# farmhouse. Nothing says tornado country faster, and the film this game is
# built on opens on a family going down into one. Built, not copied - a cellar
# door is a real object, and Docs/ATTRIBUTION.md forbids taking anything from
# the film itself.
static func storm_cellar(pos: Vector3, yaw: float = 0.0) -> Structure:
	var st := Structure.new()
	st.position = pos
	st.rotation.y = yaw
	# The concrete surround, sitting just proud of the field.
	for sz in [-1.0, 1.0]:
		st.add_brick(7, 1, 0.34, BrickLib.C_LGREY, Vector3(0, 0.17, sz * 1.1), Vector3.ZERO, false)
	for sx in [-1.0, 1.0]:
		st.add_brick(1, 5, 0.34, BrickLib.C_LGREY, Vector3(sx * 1.6, 0.17, 0), Vector3.ZERO, false)
	# Two leaves, sloping up to a ridge in the middle.
	for sx2 in [-1.0, 1.0]:
		st.add_part(BrickLib.PART_SLOPE, 5, 3, 0.5, BrickLib.C_BROWN,
			Vector3(sx2 * 0.75, 0.45, 0), Vector3(0, sx2 * PI * 0.5, 0))
	# The handle, and the block the doors are barred with.
	st.add_part(BrickLib.PART_TILE, 1, 2, 0.12, BrickLib.C_DGREY,
		Vector3(0, 0.78, 0.55), Vector3.ZERO, false)
	st.finish()
	return st


# A grain elevator: the concrete headhouse-and-silos block that stands on the
# skyline of every plains town, visible from further away than anything else.
static func grain_elevator(pos: Vector3, yaw: float = 0.0) -> Structure:
	var st := Structure.new()
	st.position = pos
	st.rotation.y = yaw
	var cells := 4
	var courses := 40
	var ch := 0.42
	for c in range(cells):
		var x: float = (float(c) - float(cells - 1) * 0.5) * 2.6
		# Each cell is a stack of plate-thick rings, so the funnel can take it
		# down in courses like the silo rather than in four lumps.
		for k in range(courses):
			st.add_part(BrickLib.PART_ROUND, 5, 5, ch, BrickLib.C_LGREY,
				Vector3(x, ch * 0.5 + float(k) * ch, 0), Vector3.ZERO, k == courses - 1)
	# The headhouse on top, where the leg and the spouts live. An elevator is
	# far taller than it is wide - that is the whole silhouette, and at ten
	# metres on a twelve-metre footprint it read as a squat bank of tanks.
	var top := float(courses) * ch
	st.add_brick(int(float(cells) * 5.4), 5, 3.0, BrickLib.C_LGREY,
		Vector3(0, top + 1.5, 0))
	st.add_part(BrickLib.PART_TILE, int(float(cells) * 5.4), 5, BrickLib.PLATE_H,
		BrickLib.C_DGREY, Vector3(0, top + 3.1, 0))
	st.finish()
	return st


static func pickup(pos: Vector3, color: Color, yaw: float = 0.0,
		chase: bool = false) -> Structure:
	var st := Structure.new()
	st.position = pos
	st.rotation.y = yaw
	st.add_brick(8, 4, 0.2, BrickLib.C_DGREY, Vector3(0, 0.42, 0), Vector3.ZERO, false)
	st.add_brick(5, 4, H * 1.6, color, Vector3(-0.7, 0.95, 0))
	# A tiled load bed, because a flatbed is smooth.
	st.add_part(BrickLib.PART_TILE, 5, 4, BrickLib.PLATE_H, BrickLib.C_DGREY,
		Vector3(-0.7, 1.52, 0))
	st.add_brick(4, 4, H * 1.4, color, Vector3(0.5, 1.35, 0))
	# A raked windscreen out of a slope, sitting on the cab and falling toward
	# the front of the truck. This one part does more for "that is a truck"
	# than anything else on the model.
	st.add_part(BrickLib.PART_SLOPE, 4, 2, H * 1.0, BrickLib.C_TRANS,
		Vector3(1.0, 2.07, 0), Vector3(0, PI * 0.5, 0))
	st.add_brick(4, 4, H * 0.9, color, Vector3(1.5, 0.85, 0))
	for sx in [-1.2, 1.2]:
		for sz in [-1.0, 1.0]:
			# Round wheels, with the axle across the truck. The old wheels
			# were boxes AND were spun about the wrong axis; a box hid it.
			st.add_part(BrickLib.PART_ROUND, 1, 1, 0.4, BrickLib.C_BLACK,
				Vector3(sx, 0.3, sz), Vector3(PI * 0.5, 0, 0), false)
	if chase:
		# A CHASE RIG. A convoy of beaten-up trucks bristling with masts,
		# whips and a dish is the visual signature of storm chasing, and a
		# plain farm pickup carries none of it. Instrument cases ride in the
		# bed; the mast and the anemometer go on the roof.
		st.add_part(BrickLib.PART_TILE, 4, 4, BrickLib.PLATE_H, BrickLib.C_DGREY,
			Vector3(0.5, 2.12, 0))
		st.add_part(BrickLib.PART_ROUND, 1, 1, 2.4, BrickLib.C_LGREY,
			Vector3(0.5, 3.3, 0), Vector3.ZERO, false)
		# Cups on the anemometer, and a pair of whips leaning back.
		for i in range(3):
			var a: float = TAU * float(i) / 3.0
			st.add_part(BrickLib.PART_ROUND, 1, 1, 0.2, BrickLib.C_WHITE,
				Vector3(0.5 + cos(a) * 0.42, 4.4, sin(a) * 0.42), Vector3.ZERO, false)
		for sz2 in [-0.7, 0.7]:
			st.add_part(BrickLib.PART_ROUND, 1, 1, 1.6, BrickLib.C_BLACK,
				Vector3(-0.2, 2.9, sz2), Vector3(0.34, 0, 0), false)
		# The dish, tipped up at the sky.
		st.add_part(BrickLib.PART_CONE, 3, 3, 0.4, BrickLib.C_WHITE,
			Vector3(-1.3, 2.35, 0), Vector3(-0.9, 0, 0), false)
		# Instrument cases in the bed.
		for i2 in range(2):
			st.add_brick(2, 3, 0.5, BrickLib.C_YELLOW,
				Vector3(-1.5 + float(i2) * 0.9, 1.8, 0))
	st.finish()
	return st


static func drive_in_screen(pos: Vector3, yaw: float = 0.0) -> Structure:
	var st := Structure.new()
	st.position = pos
	st.rotation.y = yaw
	# The screen face is TILED. A cinema screen with a grid of studs across it
	# was the loudest wrong note in the whole set.
	for c in range(9):
		st.add_part(BrickLib.PART_TILE, 20, 1, H, BrickLib.C_WHITE,
			Vector3(0, float(c) * H + H * 0.5, 0))
	for xx in [-4.6, 4.6]:
		st.add_part(BrickLib.PART_ROUND, 1, 1, 5.6, BrickLib.C_DGREY,
			Vector3(xx, 2.8, -0.6), Vector3.ZERO, false)
	st.add_brick(22, 2, H, BrickLib.C_RED, Vector3(0, 9.0 * H + 0.3, 0))
	st.finish()
	return st


static func windmill(pos: Vector3) -> Structure:
	# AN AERMOTOR, not a Dutch mill. This was a tapering round tower with six
	# long sails, which is Holland; the windmill on a plains farm is a splayed
	# lattice steel tower with a many-bladed fan and a tail vane keeping it
	# pointed into the wind, pumping water for stock. It is one of the most
	# recognisable silhouettes out there and it was the wrong one.
	var st := Structure.new()
	st.position = pos
	var tower := 9.0
	var legs := 4
	var steps := 7
	for i in range(legs):
		var a: float = TAU * float(i) / float(legs) + PI * 0.25
		for k in range(steps):
			var t0: float = float(k) / float(steps)
			var t1: float = float(k + 1) / float(steps)
			# The legs splay: wide at the ground, gathered at the platform.
			var r0: float = lerpf(1.45, 0.34, t0)
			var r1: float = lerpf(1.45, 0.34, t1)
			var y0: float = t0 * tower
			var y1: float = t1 * tower
			var mid := Vector3(cos(a) * (r0 + r1) * 0.5, (y0 + y1) * 0.5,
				sin(a) * (r0 + r1) * 0.5)
			# Lean each segment along the leg, so the tower tapers instead of
			# stepping. atan of the horizontal run over the rise.
			var lean := atan2(r0 - r1, y1 - y0)
			st.add_part(BrickLib.PART_ROUND, 1, 1, (y1 - y0) * 1.06,
				BrickLib.C_LGREY, mid, Vector3(sin(a) * lean, -a, cos(a) * lean), false)
	# Horizontal bracing rings. A lattice tower without them reads as four
	# sticks leaning together.
	for k in range(1, 4):
		var t: float = float(k) / 4.0
		var r: float = lerpf(1.45, 0.34, t)
		for i in range(legs):
			var a2: float = TAU * (float(i) + 0.5) / float(legs) + PI * 0.25
			st.add_part(BrickLib.PART_TILE, int(maxf(2.0, r * 4.4)), 1, 0.1,
				BrickLib.C_LGREY,
				Vector3(cos(a2) * r * 0.92, t * tower, sin(a2) * r * 0.92),
				Vector3(0, -a2 + PI * 0.5, 0), false)
	# DIAGONAL BRACING. Four legs and some horizontal rings still read as a
	# stack of tubes; the Xs between them are what make it a lattice.
	for k in range(4):
		var t0: float = float(k) / 4.0
		var t1: float = float(k + 1) / 4.0
		var r0: float = lerpf(1.45, 0.34, t0)
		var r1: float = lerpf(1.45, 0.34, t1)
		for i in range(legs):
			var a4: float = TAU * (float(i) + 0.5) / float(legs) + PI * 0.25
			var run: float = (r0 + r1) * 0.5 * 1.5
			var rise: float = (t1 - t0) * tower
			for sgn in [-1.0, 1.0]:
				st.add_part(BrickLib.PART_TILE,
					int(maxf(3.0, sqrt(run * run + rise * rise) * 2.0)), 1, 0.08,
					BrickLib.C_LGREY,
					Vector3(cos(a4) * (r0 + r1) * 0.5, (t0 + t1) * 0.5 * tower,
						sin(a4) * (r0 + r1) * 0.5),
					Vector3(0, -a4 + PI * 0.5, sgn * atan2(rise, run)), false)

	# The fan: a hub, a ring of blades, and the tail vane behind it.
	var hub := Vector3(0, tower + 0.55, 0.0)
	st.add_part(BrickLib.PART_ROUND, 2, 2, 0.3, BrickLib.C_DGREY,
		hub, Vector3(PI * 0.5, 0, 0), false)
	for i in range(12):
		var a3: float = TAU * float(i) / 12.0
		st.add_part(BrickLib.PART_TILE, 3, 1, 0.07, BrickLib.C_WHITE,
			hub + Vector3(cos(a3) * 0.78, sin(a3) * 0.78, 0.02),
			Vector3(0, 0, a3 + PI * 0.5), false)
	st.add_part(BrickLib.PART_TILE, 5, 1, 0.1, BrickLib.C_LGREY,
		hub + Vector3(0, -0.1, 1.35), Vector3(PI * 0.5, 0, 0), false)
	st.finish()
	return st


# The gag prop. Smashing it is the joke; see BS:COMEDY:GAGS.
static func outhouse(pos: Vector3) -> Structure:
	var st := Structure.new()
	st.position = pos
	var w := 4
	var d := 4
	var hw := float(w) * S * 0.5
	var hd := float(d) * S * 0.5
	var wood := BrickLib.C_BROWN
	_wall(st, Vector3(-hw, 0, -hd), Vector3(1, 0, 0), w, 6, wood, 2)
	_wall(st, Vector3(-hw, 0, hd), Vector3(1, 0, 0), w, 6, wood, 2)
	_wall(st, Vector3(-hw, 0, -hd), Vector3(0, 0, 1), d, 6, wood, 2)
	st.add_brick(4, 1, H * 5.0, BrickLib.C_TAN, Vector3(hw + 0.1, H * 2.5, 0), Vector3(0, PI * 0.5, 0))
	st.add_part(BrickLib.PART_ROUND, 1, 1, 0.24, BrickLib.C_WHITE,
		Vector3(hw + 0.24, H * 4.2, 0), Vector3(PI * 0.5, 0, 0), false)
	# A little lean-to roof: two slope courses, so even the gag prop is built.
	for i in range(2):
		st.add_part(BrickLib.PART_SLOPE, 5, 2, H * 0.5, BrickLib.C_DGREY,
			Vector3(0, H * 6.0 + H * 0.5 * float(i) + H * 0.25,
				S * (1.0 - float(i))), Vector3(0, PI, 0))
	st.finish()
	return st

# --- small smashable furniture ------------------------------------------
# The cheap stuff that removes dead time. In a LEGO game you are never more
# than a couple of paces from something that breaks, and that is what makes
# SMASH the default verb instead of an occasional one.

static func mailbox(pos: Vector3, yaw: float = 0.0) -> Structure:
	var st := Structure.new()
	st.position = pos
	st.rotation.y = yaw
	for i in range(2):
		st.add_part(BrickLib.PART_ROUND, 1, 1, 0.55, BrickLib.C_BROWN,
			Vector3(0, 0.275 + 0.55 * float(i), 0), Vector3.ZERO, false)
	# The box is a round brick on its side - a mailbox has a barrel top.
	st.add_part(BrickLib.PART_ROUND, 2, 2, 0.9, BrickLib.C_DGREY,
		Vector3(0, 1.28, 0), Vector3(PI * 0.5, 0, 0), false)
	st.add_part(BrickLib.PART_TILE, 1, 1, 0.16, BrickLib.C_RED,
		Vector3(0.36, 1.36, 0), Vector3(0, 0, PI * 0.5), false)
	st.finish()
	return st


static func bin(pos: Vector3) -> Structure:
	var st := Structure.new()
	st.position = pos
	# Six thin rings, not three thick ones: a smashable wants to come apart
	# into a handful of pieces, and that is the whole reason to hit it.
	for c in range(6):
		st.add_part(BrickLib.PART_ROUND, 2, 2, H * 0.35, BrickLib.C_GREEN,
			Vector3(0, float(c) * H * 0.35 + H * 0.175, 0), Vector3.ZERO, false)
	st.add_part(BrickLib.PART_TILE, 3, 3, 0.18, BrickLib.C_DGREY,
		Vector3(0, 6.0 * H * 0.35 + 0.09, 0))
	st.finish()
	return st


static func crate(pos: Vector3, yaw: float = 0.0, stacked: bool = false) -> Structure:
	var st := Structure.new()
	st.position = pos
	st.rotation.y = yaw
	# Four panels and a lid, not one solid block. A real crate is built this
	# way, and a two-part prop cannot survive three bites however small the
	# bite is - part count is the floor. See BS:PLAYER:SMASH.
	_crate_box(st, Vector3(0, 0.35, 0), 0.0, BrickLib.C_TAN, BrickLib.C_BROWN)
	if stacked:
		_crate_box(st, Vector3(0.1, 1.15, -0.08), 0.4, BrickLib.C_BROWN, BrickLib.C_TAN)
	st.finish()
	return st


# One crate: four walls and a lid, at `yaw`.
static func _crate_box(st: Structure, centre: Vector3, yaw: float,
		body: Color, lid: Color) -> void:
	for i in range(4):
		var a: float = yaw + PI * 0.5 * float(i)
		var off := Vector3(sin(a) * S, 0.0, cos(a) * S)
		st.add_brick(3, 1, 0.7, body, centre + off, Vector3(0, a, 0), false)
	st.add_part(BrickLib.PART_TILE, 3, 3, BrickLib.PLATE_H, lid,
		centre + Vector3(0, 0.45, 0), Vector3(0, yaw, 0))


static func hay_bale(pos: Vector3, yaw: float = 0.0) -> Structure:
	var st := Structure.new()
	st.position = pos
	st.rotation.y = yaw
	# A hay bale is a cylinder lying down, not eight blocks in a circle. Four
	# short rolls rather than two long ones: the silhouette is identical and it
	# gives a smash something to take a bite out of.
	for i in range(4):
		st.add_part(BrickLib.PART_ROUND, 3, 3, 0.28, BrickLib.C_YELLOW,
			Vector3(0, 0.75, -0.42 + 0.28 * float(i)), Vector3(PI * 0.5, 0, 0), false)
	st.finish()
	return st


static func road_sign(pos: Vector3, yaw: float = 0.0) -> Structure:
	var st := Structure.new()
	st.position = pos
	st.rotation.y = yaw
	st.add_part(BrickLib.PART_ROUND, 1, 1, 1.9, BrickLib.C_LGREY,
		Vector3(0, 0.95, 0), Vector3.ZERO, false)
	st.add_part(BrickLib.PART_TILE, 4, 1, 0.5, BrickLib.C_WHITE, Vector3(0, 2.0, 0))
	st.finish()
	return st


static func bench(pos: Vector3, yaw: float = 0.0) -> Structure:
	var st := Structure.new()
	st.position = pos
	st.rotation.y = yaw
	st.add_part(BrickLib.PART_TILE, 6, 2, 0.18, BrickLib.C_BROWN, Vector3(0, 0.55, 0))
	st.add_part(BrickLib.PART_TILE, 6, 1, 0.5, BrickLib.C_BROWN, Vector3(0, 0.85, -0.22))
	for sx in [-1.1, 1.1]:
		st.add_brick(1, 2, 0.5, BrickLib.C_DGREY, Vector3(sx, 0.27, 0), Vector3.ZERO, false)
	st.finish()
	return st


static func barrel(pos: Vector3, colour: Color = BrickLib.C_BLUE) -> Structure:
	var st := Structure.new()
	st.position = pos
	for c in range(6):
		st.add_part(BrickLib.PART_ROUND, 2, 2, H * 0.5, colour,
			Vector3(0, float(c) * H * 0.5 + H * 0.25, 0), Vector3.ZERO, c == 5)
	st.finish()
	return st


static func trough(pos: Vector3, yaw: float = 0.0) -> Structure:
	var st := Structure.new()
	st.position = pos
	st.rotation.y = yaw
	st.add_part(BrickLib.PART_TILE, 6, 3, 0.2, BrickLib.C_LGREY, Vector3(0, 0.3, 0))
	for sz in [-0.65, 0.65]:
		st.add_part(BrickLib.PART_TILE, 6, 1, 0.4, BrickLib.C_LGREY, Vector3(0, 0.6, sz))
	st.finish()
	return st


static func crop_patch(pos: Vector3) -> Structure:
	var st := Structure.new()
	st.position = pos
	for i in range(7):
		var a: float = TAU * float(i) / 7.0
		var r: float = 0.7 + fmod(float(i) * 0.7, 0.8)
		# A crop stalk is nearly all tip - it should whip, not lean.
		var stalk_h := 0.9 + fmod(float(i), 3.0) * 0.15
		st.add_brick(1, 1, stalk_h, BrickLib.C_LGREEN,
			Vector3(cos(a) * r, 0.5, sin(a) * r), Vector3.ZERO, false, 0.85)
		# A cheese slope for the head of the stalk, which whips hardest.
		st.add_part(BrickLib.PART_CHEESE, 1, 1, 0.22, BrickLib.C_YELLOW,
			Vector3(cos(a) * r, 0.5 + stalk_h * 0.5 + 0.11, sin(a) * r),
			Vector3(0, a, 0), false, 1.0)
	st.finish()
	return st


static func tyre_stack(pos: Vector3) -> Structure:
	var st := Structure.new()
	st.position = pos
	# Tyres are discs. Six little boxes in a ring never was one.
	for c in range(4):
		st.add_part(BrickLib.PART_ROUND, 3, 3, 0.24, BrickLib.C_BLACK,
			Vector3(0.0, 0.12 + float(c) * 0.24, 0.0),
			Vector3(0, float(c) * 0.3, 0), false)
	st.finish()
	return st


# One call that returns a piece of scenery chosen by index, so the scatter in
# main.gd stays a placement problem rather than a giant match statement.
static func furniture(kind: int, pos: Vector3, yaw: float) -> Structure:
	match kind % 10:
		0: return mailbox(pos, yaw)
		1: return bin(pos)
		2: return crate(pos, yaw, false)
		3: return crate(pos, yaw, true)
		4: return hay_bale(pos, yaw)
		5: return road_sign(pos, yaw)
		6: return bench(pos, yaw)
		7: return barrel(pos, BrickLib.C_BLUE if kind % 20 < 10 else BrickLib.C_RED)
		8: return trough(pos, yaw)
		_: return crop_patch(pos)


# [BS:BUILD:TOWN:END]
