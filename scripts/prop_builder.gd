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
# - Every prop is assembled from bricks at stud pitch (pillar 1).
# - Courses are staggered like real brickwork; it is most of what
#   makes a wall read as built rather than extruded.
# - Props must survive being torn brick-by-brick, so no prop may rely
#   on a single mesh for its silhouette.
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

	# gambrel roof - four slabs
	var wall_top := 6.0 * H + H
	for sgn in [-1.0, 1.0]:
		st.add_brick(5, d, 0.22, red, Vector3(sgn * 2.95, wall_top + 0.9, 0),
			Vector3(0, 0, sgn * -1.02))
		st.add_brick(6, d, 0.22, red, Vector3(sgn * 1.2, wall_top + 2.3, 0),
			Vector3(0, 0, sgn * -0.39))

	# big white doors on the -Z face
	st.add_brick(4, 1, H * 5.0, white, Vector3(-1.1, H * 2.5, -hd - 0.2))
	st.add_brick(4, 1, H * 5.0, white, Vector3(1.1, H * 2.5, -hd - 0.2))
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
		st.add_brick(2, 1, H * 2.0, BrickLib.C_TRANS, Vector3(-hw - 0.15, H * 2.6, zz))
		st.add_brick(2, 1, H * 2.0, BrickLib.C_TRANS, Vector3(hw + 0.15, H * 2.6, zz))
	st.add_brick(2, 1, H * 4.0, BrickLib.C_BROWN, Vector3(0, H * 2.0, -hd - 0.15))

	# gable roof
	var top := 5.0 * H
	for sgn in [-1.0, 1.0]:
		st.add_brick(8, d + 2, 0.22, roof, Vector3(sgn * 1.55, top + 1.0, 0),
			Vector3(0, 0, sgn * -0.62))
	# chimney
	st.add_brick(2, 2, H * 3.0, BrickLib.C_BROWN, Vector3(1.6, top + 1.9, 2.0))

	# porch
	for xx in [-hw + 0.3, hw - 0.3]:
		st.add_brick(1, 1, H * 4.0, body, Vector3(xx, H * 2.0, -hd - 1.4))
	st.add_brick(w, 4, 0.2, body, Vector3(0, H * 4.2, -hd - 0.8))
	st.finish()
	return st


static func silo(pos: Vector3) -> Structure:
	var st := Structure.new()
	st.position = pos
	var n := 10
	var r := 1.5
	var courses := 7
	for c in range(courses):
		var y: float = float(c) * H + H * 0.5
		var stag: float = 0.0
		if c % 2 == 1:
			stag = TAU / float(n) * 0.5
		for i in range(n):
			var a: float = TAU * float(i) / float(n) + stag
			var p := Vector3(cos(a) * r, y, sin(a) * r)
			st.add_brick(2, 1, H, BrickLib.C_LGREY, p, Vector3(0, -a, 0))
	# dome cap
	for i in range(n):
		var a: float = TAU * float(i) / float(n)
		var p := Vector3(cos(a) * r * 0.72, float(courses) * H + 0.35, sin(a) * r * 0.72)
		st.add_brick(2, 1, H, BrickLib.C_LGREY, p, Vector3(0.42, -a, 0))
	st.add_brick(2, 2, 0.25, BrickLib.C_DGREY, Vector3(0, float(courses) * H + 0.75, 0))
	st.finish()
	return st


static func water_tower(pos: Vector3) -> Structure:
	var st := Structure.new()
	st.position = pos
	var legs := 4
	for i in range(legs):
		var a: float = TAU * float(i) / float(legs) + PI * 0.25
		var p := Vector3(cos(a) * 1.5, 2.2, sin(a) * 1.5)
		st.add_brick(1, 1, 4.4, BrickLib.C_DGREY, p, Vector3(0, -a, 0), false)
	var n := 8
	for c in range(3):
		for i in range(n):
			var a: float = TAU * float(i) / float(n) + float(c) * 0.2
			var p := Vector3(cos(a) * 1.7, 4.6 + float(c) * H, sin(a) * 1.7)
			st.add_brick(2, 1, H, BrickLib.C_LGREEN, p, Vector3(0, -a, 0))
	st.add_brick(6, 6, 0.3, BrickLib.C_DGREY, Vector3(0, 6.5, 0))
	st.finish()
	return st


static func tree(pos: Vector3, scale_f: float = 1.0) -> Structure:
	var st := Structure.new()
	st.position = pos
	st.add_brick(1, 1, 2.0 * scale_f, BrickLib.C_BROWN, Vector3(0, 1.0 * scale_f, 0), Vector3.ZERO, false)
	var g := BrickLib.C_GREEN
	st.add_brick(4, 4, H, g, Vector3(0, 2.2 * scale_f, 0))
	st.add_brick(3, 3, H, g, Vector3(0.2, 2.2 * scale_f + H, -0.1))
	st.add_brick(2, 2, H, BrickLib.C_LGREEN, Vector3(-0.15, 2.2 * scale_f + H * 2.0, 0.15))
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
		if i < posts:
			var m := dir * (float(i) * 2.0 + 1.0)
			st.add_brick(4, 1, 0.16, BrickLib.C_WHITE, Vector3(m.x, 0.95, m.z), Vector3(0, yaw + PI * 0.5, 0), false)
			st.add_brick(4, 1, 0.16, BrickLib.C_WHITE, Vector3(m.x, 0.55, m.z), Vector3(0, yaw + PI * 0.5, 0), false)
	st.finish()
	return st


static func pickup(pos: Vector3, color: Color, yaw: float = 0.0) -> Structure:
	var st := Structure.new()
	st.position = pos
	st.rotation.y = yaw
	st.add_brick(8, 4, 0.2, BrickLib.C_DGREY, Vector3(0, 0.42, 0), Vector3.ZERO, false)
	st.add_brick(5, 4, H * 1.6, color, Vector3(-0.7, 0.95, 0))
	st.add_brick(4, 4, H * 1.4, BrickLib.C_TRANS, Vector3(0.5, 1.35, 0))
	st.add_brick(4, 4, H * 0.9, color, Vector3(1.5, 0.85, 0))
	for sx in [-1.2, 1.2]:
		for sz in [-1.0, 1.0]:
			st.add_brick(1, 1, 0.55, BrickLib.C_BLACK, Vector3(sx, 0.3, sz), Vector3(0, 0, PI * 0.5), false)
	st.finish()
	return st


static func drive_in_screen(pos: Vector3, yaw: float = 0.0) -> Structure:
	var st := Structure.new()
	st.position = pos
	st.rotation.y = yaw
	for c in range(9):
		_wall(st, Vector3(-5.0, float(c) * H, 0), Vector3(1, 0, 0), 20, 1, BrickLib.C_WHITE, 5, 1)
	for xx in [-4.6, 4.6]:
		st.add_brick(1, 1, 5.6, BrickLib.C_DGREY, Vector3(xx, 2.8, -0.6), Vector3.ZERO, false)
	st.add_brick(22, 2, H, BrickLib.C_RED, Vector3(0, 9.0 * H + 0.3, 0))
	st.finish()
	return st


static func windmill(pos: Vector3) -> Structure:
	var st := Structure.new()
	st.position = pos
	for c in range(4):
		var n := 4
		var r: float = 1.1 - float(c) * 0.2
		for i in range(n):
			var a: float = TAU * float(i) / float(n) + float(c) * 0.3
			st.add_brick(2, 1, H * 2.0, BrickLib.C_LGREY,
				Vector3(cos(a) * r, float(c) * H * 2.0 + H, sin(a) * r), Vector3(0, -a, 0))
	for i in range(6):
		var a: float = TAU * float(i) / 6.0
		st.add_brick(4, 1, 0.14, BrickLib.C_WHITE,
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
	st.add_brick(1, 1, 0.24, BrickLib.C_WHITE, Vector3(hw + 0.24, H * 4.2, 0), Vector3.ZERO, false)
	st.add_brick(6, 6, 0.24, BrickLib.C_DGREY, Vector3(0, H * 6.2, 0))
	st.finish()
	return st
# [BS:BUILD:TOWN:END]
