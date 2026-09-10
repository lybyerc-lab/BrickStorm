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
	var st := Structure.new()
	st.position = from
	var delta := to - from
	var length := delta.length()
	var dir := delta.normalized()
	var yaw := atan2(dir.x, dir.z)
	var posts := int(length / 2.0)
	for i in range(posts + 1):
		var p := dir * (float(i) * 2.0)
		st.add_brick(1, 1, 1.2, BrickLib.C_WHITE, Vector3(p.x, 0.6, p.z), Vector3(0, yaw, 0), false)
		# A picket is pointed. Two cheese slopes back to back is how you point
		# one, and it costs a single extra part per post.
		for cs in [-1.0, 1.0]:
			st.add_part(BrickLib.PART_CHEESE, 1, 1, 0.22, BrickLib.C_WHITE,
				Vector3(p.x, 1.31, p.z), Vector3(0, yaw + (0.0 if cs > 0.0 else PI), 0), false)
		if i < posts:
			var m := dir * (float(i) * 2.0 + 1.0)
			# Rails are tiles: a fence rail has no studs on it.
			st.add_part(BrickLib.PART_TILE, 4, 1, 0.16, BrickLib.C_WHITE, Vector3(m.x, 0.95, m.z), Vector3(0, yaw + PI * 0.5, 0), false)
			st.add_part(BrickLib.PART_TILE, 4, 1, 0.16, BrickLib.C_WHITE, Vector3(m.x, 0.55, m.z), Vector3(0, yaw + PI * 0.5, 0), false)
	st.finish()
	return st


static func pickup(pos: Vector3, color: Color, yaw: float = 0.0) -> Structure:
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
	var st := Structure.new()
	st.position = pos
	# A tapering round tower. Four boxes per course arranged in a square was
	# never going to read as a mill.
	for c in range(4):
		var wide := 6 - c
		st.add_part(BrickLib.PART_ROUND, wide, wide, H * 2.0, BrickLib.C_LGREY,
			Vector3(0, float(c) * H * 2.0 + H, 0))
	st.add_part(BrickLib.PART_CONE, 3, 3, 0.7, BrickLib.C_DGREY, Vector3(0, 8.0 * H + 0.35, 0))
	for i in range(6):
		var a: float = TAU * float(i) / 6.0
		# Sail slats are tiles - flat, smooth, no studs.
		st.add_part(BrickLib.PART_TILE, 4, 1, 0.14, BrickLib.C_WHITE,
			Vector3(cos(a) * 1.0, 5.4 + sin(a) * 1.0, 0.6), Vector3(0, 0, a), false)
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
