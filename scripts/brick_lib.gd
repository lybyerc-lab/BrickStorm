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
	# The brick is a square profile through the generic part builder. It used
	# to be a hand-written "six inset faces, twelve edge chamfers, eight corner
	# triangles", and _prism_mesh is that same construction generalised to any
	# profile - the two were measured against each other before this one was
	# deleted: same 44 triangles, same 5.750 surface area, same 0.9929 volume,
	# same bounds. See tools/part_probe.gd, which still asserts those numbers.
	# Keeping both would have meant two copies of the chamfer rules, and this
	# project has already been bitten by exactly that with the plastic material.
	if _brick_mesh == null:
		_brick_mesh = part_mesh(PART_BRICK)
	return _brick_mesh


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		n: Vector3) -> void:
	# Both triangles split along a-c. There used to be a `flip` branch that
	# chose between (a,b,c)+(a,c,d) and (a,c,b)+(a,d,c); those are the same two
	# triangles in opposite order, and wind_cw re-orders them anyway, so it was
	# dead code that only made the winding look hand-managed.
	_tri(st, a, b, c, n)
	_tri(st, a, c, d, n)


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	var p := [a, b, c]
	for i in wind_cw(a, b, c, n):
		st.set_normal(n)
		st.set_uv(Vector2(p[i].x + 0.5, p[i].z + 0.5))
		st.add_vertex(p[i])
# [BS:BUILD:CHAMFER:END]


# ============================================================================
# [BS:BUILD:WINDING]
# Purpose: The single place that decides which way round a triangle goes.
# Invariants:
# - GODOT'S FRONT FACE IS CLOCKWISE SEEN FROM THE FRONT. Not counter-clockwise.
#   Every generated mesh in this game - brick, head, torso - was wound the
#   other way, so back-face culling threw away the surface nearest the camera
#   and drew the FAR one instead. It never looked obviously broken because a
#   closed convex part still fills its silhouette, but the depth, the
#   silhouette and the lighting were all coming off the wrong surface, and both
#   printed parts had empirical "offsets" in their shaders that were really
#   compensating for this. Proven by tools/winding_probe.gd, which renders one
#   quad wound each way and reports which survives culling, and then puts a
#   marker inside a real brick to show it is see-through.
# - WINDING IS DERIVED FROM THE OUTWARD NORMAL, NEVER TRACKED BY HAND. Doing it
#   by hand got 16 of the brick's 44 triangles backwards, and then turned the
#   head inside out a second time from a single sign change.
# - Every mesh builder in this file goes through here. That is the point: the
#   convention was wrong in three separate copies of the same three lines, and
#   one place cannot drift from itself.
# ============================================================================
static func wind_cw(p0: Vector3, p1: Vector3, p2: Vector3, n: Vector3) -> Array:
	# (p1-p0) x (p2-p0) points along n exactly when the vertices run
	# counter-clockwise seen from the +n side, which is the order Godot culls.
	if (p1 - p0).cross(p2 - p0).dot(n) > 0.0:
		return [0, 2, 1]
	return [0, 1, 2]
# [BS:BUILD:WINDING:END]

# ============================================================================
# [BS:BUILD:PARTS]
# Purpose: The part library. A LEGO model is not made of boxes - it is made of
#   slopes, tiles, arches, round bricks and cones, and the shapes ARE the look.
# Invariants:
# - EVERY PART IS A UNIT PART. It lives in the [-0.5, 0.5] cube and is scaled
#   per instance, exactly like the brick, so all parts of one kind still batch
#   into a single MultiMesh. A part that needed its own mesh per size would
#   multiply the draw calls the batching exists to remove.
# - ONE CHAMFER IMPLEMENTATION. Every straight-sided part comes out of
#   _prism_mesh, which generalises what the brick mesh used to do by hand:
#   inset faces, a chamfer strip along every sharp edge, and a patch at every
#   corner. The brick itself is now a square profile through the same builder,
#   so there is no second copy of the chamfer rules to drift.
# - THE SLOPE ANGLE IS NOT DECORATION. BRICK_H / STUD is 0.6 / 0.5 = 1.2, which
#   is the real 9.6mm / 8mm ratio, so a unit wedge scaled one stud deep by one
#   brick tall lands on the real part's angle without a magic number.
# - Studs follow the part, not the bounding box. A slope carries one row on its
#   top ledge, a tile and a cheese slope carry none, a round brick carries one
#   in the middle. Studding a slope over its whole footprint is exactly the
#   tell that a roof was faked from boxes.
# ============================================================================
const PART_BRICK     := 0
const PART_SLOPE     := 1
const PART_SLOPE_INV := 2
const PART_CHEESE    := 3
const PART_TILE      := 4
const PART_ROUND     := 5
const PART_CONE      := 6
const PART_ARCH      := 7
const PART_COUNT     := 8

# How much of a slope's depth stays flat at the top. This is the ledge the
# studs sit on and it is what separates a slope brick from a cheese slope.
# HALF, because a real 45-degree slope brick is TWO studs deep: one stud of
# slope and one stud of studded flat behind it. That flat stud is what the
# next course up sits on when a roof is stepped, and it is the reason a LEGO
# roof has no exposed studs anywhere on its face. At a third of the depth the
# courses stepped in one stud and left every ledge showing, which is what a
# roof faked out of slabs looks like - just with more steps.
const SLOPE_LEDGE := 0.5
# A tile's top edge is visibly rounder than a brick's - that rounding is the
# whole reason a tiled floor reads as tiled and not as a wall lying down.
const TILE_CHAMFER := 0.09
const CONE_TOP := 0.24
const ROUND_SEG := 16

static var _part_meshes: Array = []


static func part_name(kind: int) -> String:
	match kind:
		PART_BRICK: return "brick"
		PART_SLOPE: return "slope"
		PART_SLOPE_INV: return "inverted slope"
		PART_CHEESE: return "cheese slope"
		PART_TILE: return "tile"
		PART_ROUND: return "round brick"
		PART_CONE: return "cone"
		PART_ARCH: return "arch"
	return "unknown"


static func part_mesh(kind: int) -> ArrayMesh:
	if _part_meshes.is_empty():
		_part_meshes.resize(PART_COUNT)
	if kind < 0 or kind >= PART_COUNT:
		kind = PART_BRICK
	if _part_meshes[kind] != null:
		return _part_meshes[kind]
	var m: ArrayMesh = null
	match kind:
		PART_BRICK:
			m = _prism_mesh(_square_profile(), CHAMFER, false)
		PART_TILE:
			m = _prism_mesh(_square_profile(), TILE_CHAMFER, false)
		PART_SLOPE:
			m = _prism_mesh(_slope_profile(SLOPE_LEDGE, false), CHAMFER, false)
		PART_SLOPE_INV:
			m = _prism_mesh(_slope_profile(SLOPE_LEDGE, true), CHAMFER, false)
		PART_CHEESE:
			m = _prism_mesh(_slope_profile(0.0, false), CHAMFER, false)
		PART_ARCH:
			m = _prism_mesh(_arch_profile(), CHAMFER, true)
		PART_ROUND:
			m = _revolve_mesh(0.5, 0.5)
		PART_CONE:
			m = _revolve_mesh(0.5, CONE_TOP)
	_part_meshes[kind] = m
	return m


# Where the studs go, in unit-part space: x and z in [-0.5, 0.5], y at the top.
# Structure multiplies these by the instance size, so one table serves a 1x1
# and a 6x2 of the same kind.
static func part_stud_slots(kind: int, sw: int, sd: int) -> Array:
	var out: Array = []
	match kind:
		PART_TILE, PART_CHEESE:
			return out                      # smooth parts. That is the point.
		PART_ROUND, PART_CONE:
			out.append(Vector3(0.0, 0.5, 0.0))
			return out
		PART_SLOPE:
			# ONE ROW, on the ledge - not a full footprint of studs.
			var z := -0.5 + SLOPE_LEDGE * 0.5
			for x in range(sw):
				out.append(Vector3((float(x) + 0.5) / float(sw) - 0.5, 0.5, z))
			return out
	for x in range(sw):
		for z in range(sd):
			out.append(Vector3((float(x) + 0.5) / float(sw) - 0.5, 0.5,
				(float(z) + 0.5) / float(sd) - 0.5))
	return out


# --- profiles ---------------------------------------------------------------
# A profile is a list of [Vector2(u, y), smooth]. It runs counter-clockwise, so
# the outward normal of the edge leaving a vertex is (d.y, -d.x). `smooth`
# marks a vertex where the surface carries on round rather than turning a
# corner: no chamfer strip is cut there and the two faces share a normal, which
# is how the arch's underside stays a curve instead of a run of facets.

static func _square_profile() -> Array:
	return [
		[Vector2(-0.5, -0.5), false], [Vector2(0.5, -0.5), false],
		[Vector2(0.5, 0.5), false], [Vector2(-0.5, 0.5), false],
	]


# High at -Z, falling to the bottom front edge at +Z. `ledge` is the flat run
# kept at the top; at 0 it is a cheese slope. Inverted mirrors it in y, giving
# the part that goes under an eave: full studded top, cutaway underneath.
static func _slope_profile(ledge: float, inverted: bool) -> Array:
	var pts: Array = []
	if inverted:
		pts = [
			Vector2(-0.5, -0.5), Vector2(0.5 - ledge, -0.5),
			Vector2(0.5, 0.5), Vector2(-0.5, 0.5),
		]
	else:
		pts = [
			Vector2(-0.5, -0.5), Vector2(0.5, -0.5),
			Vector2(-0.5 + ledge, 0.5), Vector2(-0.5, 0.5),
		]
	var out: Array = []
	for p in pts:
		# Drop a vertex that a zero ledge has collapsed onto its neighbour,
		# otherwise the cheese slope carries a zero-length top edge and the
		# chamfer strip built on it is degenerate.
		if not out.is_empty() and (out[-1][0] as Vector2).distance_to(p) < 1e-5:
			continue
		out.append([p, false])
	return out


# An arch brick: solid legs, an elliptical opening between them. This one is
# extruded along Z, because an arch spans its LENGTH and length is x.
static func _arch_profile() -> Array:
	var rx := 0.30                    # half the opening, in x
	var rh := 0.74                    # opening height
	var out: Array = []
	out.append([Vector2(-0.5, -0.5), false])
	var seg := 14
	for k in range(seg + 1):
		var th: float = PI - PI * float(k) / float(seg)
		# The springing points are corners; everything between them is one
		# continuous curve.
		out.append([Vector2(cos(th) * rx, -0.5 + sin(th) * rh), k > 0 and k < seg])
	out.append([Vector2(0.5, -0.5), false])
	out.append([Vector2(0.5, 0.5), false])
	out.append([Vector2(-0.5, 0.5), false])
	return out


# --- builders ---------------------------------------------------------------

static func _prism_pt(u: float, y: float, t: float, span_x: bool) -> Vector3:
	return Vector3(u, y, t) if span_x else Vector3(t, y, u)


static func _prism_n(nu: float, ny: float, span_x: bool) -> Vector3:
	return Vector3(nu, ny, 0.0) if span_x else Vector3(0.0, ny, nu)


# The generic chamfered extrusion. `profile` is in (u, y); it is swept along
# the remaining horizontal axis from -0.5 to +0.5. This is the brick's old
# "six faces, twelve edges, eight corners" written once for any profile.
static func _prism_mesh(profile: Array, c: float, span_x: bool) -> ArrayMesh:
	var n := profile.size()
	var pos: Array = []
	var smooth: Array = []
	for e in profile:
		pos.append(e[0] as Vector2)
		smooth.append(bool(e[1]))
	# Force counter-clockwise so the edge normals below point outward. Getting
	# this wrong turns the whole part inside out, and it is exactly the class
	# of mistake BS:BUILD:WINDING exists to make impossible to make by hand.
	var area := 0.0
	for i in range(n):
		var a: Vector2 = pos[i]
		var b: Vector2 = pos[(i + 1) % n]
		area += a.x * b.y - b.x * a.y
	if area < 0.0:
		pos.reverse()
		smooth.reverse()

	var dir: Array = []
	var en: Array = []
	for i in range(n):
		var d: Vector2 = (pos[(i + 1) % n] - pos[i]).normalized()
		dir.append(d)
		en.append(Vector2(d.y, -d.x))
	var bis: Array = []
	for i in range(n):
		var b: Vector2 = (en[(i - 1 + n) % n] + en[i])
		bis.append(en[i] if b.length() < 1e-6 else b.normalized())

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var t := 0.5 - c
	var axis: Vector3 = Vector3(0, 0, 1) if span_x else Vector3(1, 0, 0)

	# Start and end of each edge's flat run, and the normal at each end.
	var sa: Array = []
	var sb: Array = []
	for i in range(n):
		var j := (i + 1) % n
		sa.append(pos[i] if smooth[i] else pos[i] + dir[i] * c)
		sb.append(pos[j] if smooth[j] else pos[j] - dir[i] * c)

	# Lateral faces.
	for i in range(n):
		var j := (i + 1) % n
		var na: Vector3 = _prism_n(bis[i].x, bis[i].y, span_x) if smooth[i] \
			else _prism_n(en[i].x, en[i].y, span_x)
		var nb: Vector3 = _prism_n(bis[j].x, bis[j].y, span_x) if smooth[j] \
			else _prism_n(en[i].x, en[i].y, span_x)
		var p0 := _prism_pt(sa[i].x, sa[i].y, -t, span_x)
		var p1 := _prism_pt(sb[i].x, sb[i].y, -t, span_x)
		var p2 := _prism_pt(sb[i].x, sb[i].y, t, span_x)
		var p3 := _prism_pt(sa[i].x, sa[i].y, t, span_x)
		_emit_tri(st, p0, p1, p2, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, na, nb, nb)
		_emit_tri(st, p0, p2, p3, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, na, nb, na)

	# Chamfer strip along every sharp edge that runs the length of the part.
	for i in range(n):
		if smooth[i]:
			continue
		var pa: Vector2 = sb[(i - 1 + n) % n]
		var pb: Vector2 = sa[i]
		if pa.distance_to(pb) < 1e-6:
			continue
		var nn := _prism_n(bis[i].x, bis[i].y, span_x)
		var q0 := _prism_pt(pa.x, pa.y, -t, span_x)
		var q1 := _prism_pt(pb.x, pb.y, -t, span_x)
		var q2 := _prism_pt(pb.x, pb.y, t, span_x)
		var q3 := _prism_pt(pa.x, pa.y, t, span_x)
		_emit_tri(st, q0, q1, q2, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, nn, nn, nn)
		_emit_tri(st, q0, q2, q3, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, nn, nn, nn)

	# Where the cap outline turns each corner: the intersection of the two
	# neighbouring edges offset inward by the chamfer. NOT each edge's own
	# endpoint pushed in - that only lands in the same place when the corner is
	# a right angle, which is why it worked on the brick and produced a cap
	# outline that crossed itself on every slope. The triangulator rejected
	# those outright and the fallback fan then filled a shape that was not the
	# part. Miter points also collapse the corner patch to the single triangle
	# the brick always had.
	var miter: Array = []
	for i in range(n):
		var e1: Vector2 = en[(i - 1 + n) % n]
		var e2: Vector2 = en[i]
		var d1: float = (pos[i] as Vector2).dot(e1) - c
		var d2: float = (pos[i] as Vector2).dot(e2) - c
		var det: float = e1.x * e2.y - e1.y * e2.x
		if absf(det) < 1e-6:
			miter.append(pos[i] - e2 * c)      # the edges run on; no corner
		else:
			miter.append(Vector2((d1 * e2.y - d2 * e1.y) / det,
				(e1.x * d2 - e2.x * d1) / det))

	for s_end in [-1.0, 1.0]:
		# Typed explicitly: an untyped loop variable makes every expression it
		# touches a Variant and GDScript then refuses to infer the locals below.
		var s: float = s_end
		var cap_n: Vector3 = axis * s
		# Strip joining each lateral face to the end cap.
		for i in range(n):
			var j := (i + 1) % n
			var m0: Vector2 = miter[i]
			var m1: Vector2 = miter[j]
			var nn: Vector3 = (_prism_n(en[i].x, en[i].y, span_x) + cap_n).normalized()
			var q0 := _prism_pt(m0.x, m0.y, s * 0.5, span_x)
			var q1 := _prism_pt(m1.x, m1.y, s * 0.5, span_x)
			var q2 := _prism_pt(sb[i].x, sb[i].y, s * t, span_x)
			var q3 := _prism_pt(sa[i].x, sa[i].y, s * t, span_x)
			_emit_tri(st, q0, q1, q2, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, nn, nn, nn)
			_emit_tri(st, q0, q2, q3, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, nn, nn, nn)
		# The triangle closing each sharp corner, where the cap, the two cap
		# strips and the edge chamfer all run out. A smooth vertex has no edge
		# chamfer, so the two strips already meet and there is nothing to fill.
		for i in range(n):
			if smooth[i]:
				continue
			var pa: Vector2 = sb[(i - 1 + n) % n]
			var pb: Vector2 = sa[i]
			if pa.distance_to(pb) < 1e-6:
				continue
			var m: Vector2 = miter[i]
			var nn: Vector3 = (_prism_n(bis[i].x, bis[i].y, span_x) + cap_n).normalized()
			_emit_tri(st,
				_prism_pt(m.x, m.y, s * 0.5, span_x),
				_prism_pt(pb.x, pb.y, s * t, span_x),
				_prism_pt(pa.x, pa.y, s * t, span_x),
				Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, nn, nn, nn)

		# The cap itself: the profile mitred inward by the chamfer.
		var poly := PackedVector2Array()
		for i in range(n):
			var m: Vector2 = miter[i]
			if poly.size() > 0 and (poly[poly.size() - 1] as Vector2).distance_to(m) < 1e-6:
				continue
			poly.append(m)
		if poly.size() > 2 and (poly[0] as Vector2).distance_to(poly[poly.size() - 1]) < 1e-6:
			poly.remove_at(poly.size() - 1)
		var idx := Geometry2D.triangulate_polygon(poly)
		if idx.is_empty():
			# A fan across a shape the triangulator rejected fills the wrong
			# area, so this is an error, not a warning to be scrolled past.
			push_error("part cap outline is not a simple polygon (%d pts): %s"
				% [poly.size(), poly])
		for k in range(0, idx.size(), 3):
			var q0 := _prism_pt(poly[idx[k]].x, poly[idx[k]].y, s * 0.5, span_x)
			var q1 := _prism_pt(poly[idx[k + 1]].x, poly[idx[k + 1]].y, s * 0.5, span_x)
			var q2 := _prism_pt(poly[idx[k + 2]].x, poly[idx[k + 2]].y, s * 0.5, span_x)
			_emit_tri(st, q0, q1, q2, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO,
				cap_n, cap_n, cap_n)

	# NO generate_tangents(). These parts carry no UVs - nothing samples a
	# texture on them and there are no normal maps - and asking SurfaceTool to
	# derive tangents from all-zero UVs CORRUPTS THE NORMALS it was given. That
	# is not a theory: it is what left the torso print invisible for two rounds
	# of debugging. See BS:BUILD:TORSO.
	return st.commit()


# A round brick or a cone: the same sweep, with the top radius as the only
# difference between them. Chamfered at both rims like every other part.
static func _revolve_mesh(r_bot: float, r_top: float) -> ArrayMesh:
	var c := CHAMFER
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# The side runs from the bottom rim to the top rim; the chamfers take a
	# bite out of each end, following the side's own slope so the taper of a
	# cone stays straight.
	var side := Vector2(r_top - r_bot, 1.0).normalized()
	var rings := [
		[-0.5, r_bot - c],
		[-0.5 + c * absf(side.y), r_bot + side.x * c],
		[0.5 - c * absf(side.y), r_top - side.x * c],
		[0.5, r_top - c],
	]
	for ri in range(rings.size() - 1):
		var y0: float = rings[ri][0]
		var q0: float = rings[ri][1]
		var y1: float = rings[ri + 1][0]
		var q1: float = rings[ri + 1][1]
		# Outward normal of this band, perpendicular to its own slope.
		var t2 := Vector2(q1 - q0, y1 - y0)
		var nr := Vector2(t2.y, -t2.x).normalized()
		for i in range(ROUND_SEG):
			var a0 := TAU * float(i) / float(ROUND_SEG)
			var a1 := TAU * float(i + 1) / float(ROUND_SEG)
			var p00 := Vector3(sin(a0) * q0, y0, cos(a0) * q0)
			var p10 := Vector3(sin(a1) * q0, y0, cos(a1) * q0)
			var p11 := Vector3(sin(a1) * q1, y1, cos(a1) * q1)
			var p01 := Vector3(sin(a0) * q1, y1, cos(a0) * q1)
			var n0 := Vector3(sin(a0) * nr.x, nr.y, cos(a0) * nr.x).normalized()
			var n1 := Vector3(sin(a1) * nr.x, nr.y, cos(a1) * nr.x).normalized()
			_emit_tri(st, p00, p10, p11, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, n0, n1, n1)
			_emit_tri(st, p00, p11, p01, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, n0, n1, n0)
	for top in [false, true]:
		var y: float = 0.5 if top else -0.5
		var r: float = (r_top - c) if top else (r_bot - c)
		var nn := Vector3(0, 1.0 if top else -1.0, 0)
		for i in range(ROUND_SEG):
			var a0 := TAU * float(i) / float(ROUND_SEG)
			var a1 := TAU * float(i + 1) / float(ROUND_SEG)
			_emit_tri(st, Vector3(0, y, 0),
				Vector3(sin(a0) * r, y, cos(a0) * r),
				Vector3(sin(a1) * r, y, cos(a1) * r),
				Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, nn, nn, nn)
	# No generate_tangents() here either, for the same reason.
	return st.commit()
# [BS:BUILD:PARTS:END]


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
static func brick_visual(sw: int, sd: int, h: float, color: Color, with_studs: bool = true,
		kind: int = PART_BRICK) -> Node3D:
	var root := Node3D.new()
	var size := Vector3(sw * STUD, h, sd * STUD)

	# The shared chamfered part, scaled - not a BoxMesh. The minifig and the
	# loose debris are built from these, and they have to be moulded plastic
	# for the same reason every other brick does.
	var mi := MeshInstance3D.new()
	mi.mesh = part_mesh(kind)
	mi.scale = size
	mi.material_override = mat(color)
	root.add_child(mi)

	var slots := part_stud_slots(kind, sw, sd)
	if with_studs and not slots.is_empty():
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = stud_mesh()
		mm.instance_count = slots.size()
		var i := 0
		for u in slots:
			# Slots come back in unit-part space, so the same table serves a
			# 1x1 and a 6x2 of the same kind.
			var t := Transform3D(Basis(), Vector3(u.x * size.x,
				h * 0.5 + STUD_H * 0.5, u.z * size.z))
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
static func brick_body(sw: int, sd: int, h: float, color: Color,
		kind: int = PART_BRICK) -> RigidBody3D:
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
	# The collider stays a box whatever the part is. A slope tumbling as a box
	# is invisible in a debris cloud, and a convex hull per part kind would put
	# real physics cost on the one thing the funnel spawns hundreds of.
	body.add_child(brick_visual(sw, sd, h, color, true, kind))
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
# The cow, as a visual. It lives here rather than inside main's _make_cow so
# that anything which needs to SHOW a cow - the game, a scene probe - draws the
# same animal. See BS:WORLD:CRITTERS for the rules that protect it.
static func cow_visual() -> Node3D:
	var v := Node3D.new()
	var body := brick_visual(3, 2, 0.6, C_WHITE)
	body.position = Vector3(0, 0.75, 0)
	v.add_child(body)
	var head := brick_visual(1, 1, 0.5, C_WHITE, false)
	head.position = Vector3(0.85, 0.85, 0)
	v.add_child(head)
	for sx in [-0.45, 0.45]:
		for sz in [-0.28, 0.28]:
			var leg := brick_visual(1, 1, 0.5, C_BLACK, false)
			leg.position = Vector3(sx, 0.25, sz)
			v.add_child(leg)
	var patch := brick_visual(1, 1, 0.12, C_BLACK, false)
	patch.position = Vector3(-0.2, 1.06, 0.2)
	v.add_child(patch)
	# HOLSTEIN PATCHES ON THE FLANKS, not only the spine. Rendered in the
	# pasture, a cow with one patch on its back read as a small white table:
	# from a road, and from the air with the funnel throwing it past at head
	# height, what a cow shows is its SIDE. The flying cow is the single most
	# quoted image the film has, so it has to be recognisable in silhouette at
	# fifty metres, not only in a close-up.
	for sz in [-1.0, 1.0]:
		var flank := brick_visual(2, 1, 0.34, C_BLACK, false)
		flank.position = Vector3(-0.12, 0.86, sz * 0.5)
		flank.scale = Vector3(1.0, 1.0, 0.12)
		v.add_child(flank)
	# Muzzle and ears: the head was a plain white cube, which is what made the
	# animal read as furniture end-on.
	var muzzle := brick_visual(1, 1, 0.26, C_TAN, false)
	muzzle.position = Vector3(1.14, 0.80, 0)
	muzzle.scale = Vector3(0.4, 1.0, 0.8)
	v.add_child(muzzle)
	for sz2 in [-1.0, 1.0]:
		var ear := brick_visual(1, 1, 0.14, C_BLACK, false)
		ear.position = Vector3(0.80, 1.06, sz2 * 0.24)
		ear.scale = Vector3(0.4, 1.0, 0.5)
		v.add_child(ear)
	var tail := brick_visual(1, 1, 0.55, C_BLACK, false)
	tail.position = Vector3(-0.80, 0.72, 0)
	tail.scale = Vector3(0.24, 1.0, 0.24)
	v.add_child(tail)
	return v


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

	# THE RIG IS SPLIT AT THE WAIST. Everything below hangs off Pelvis and
	# everything above off Upper, and the two can be driven against each other.
	# A minifig cannot bend a knee or an elbow - the parts are rigid - so ALL
	# of a walk's character comes from WHERE THE MOTION ORIGINATES, and a flat
	# rig with the torso, the shoulders and the hips as siblings has nothing to
	# lead from. See BS:PLAYER:WALK_CYCLE.
	var pelvis := Node3D.new()
	pelvis.name = "Pelvis"
	pelvis.position = Vector3(0, hip_y, 0)
	root.add_child(pelvis)
	var upper := Node3D.new()
	upper.name = "Upper"
	upper.position = Vector3(0, hip_y, 0)
	root.add_child(upper)

	# --- legs: a hip block and two legs, short and wide ---------------------
	var hips := brick_visual(2, 1, leg_h * 0.30, legs, false)
	hips.position = Vector3(0, -leg_h * 0.15, 0)
	hips.scale = Vector3(1.0, 1.0, torso_d / STUD)
	pelvis.add_child(hips)

	for side in [-1.0, 1.0]:
		var hip := Node3D.new()
		hip.name = "HipR" if side > 0.0 else "HipL"
		hip.position = Vector3(side * torso_w * 0.25, -leg_h * 0.30, 0)
		pelvis.add_child(hip)
		var leg := brick_visual(1, 1, leg_h * 0.70, legs, false)
		leg.position = Vector3(0, -leg_h * 0.35, 0)
		leg.scale = Vector3(0.92, 1.0, torso_d / STUD)
		hip.add_child(leg)
		# CLOWN FEET, and a unit bug. This was (torso_d + 3.0) / STUD, which
		# mixes world units with millimetres: torso_d is 0.5 world units, so
		# the foot came out (0.5 + 3.0) / 0.5 = 7.0 - a 1x1 part stretched to
		# SEVEN STUDS deep, half a metre of shoe fore and aft. The 3.0 was
		# meant to be 3mm of overhang past the leg. Reported from a phone as
		# clown feet, and the side render shows a black slab under the figure.
		var foot := brick_visual(1, 1, 1.6 * mm, C_BLACK, false)
		foot.position = Vector3(0, -leg_h * 0.70 + 0.8 * mm, 1.2 * mm)
		foot.scale = Vector3(0.96, 1.0, (torso_d + 3.0 * mm) / STUD)
		hip.add_child(foot)

	# --- torso: a TRAPEZOID, narrow at the neck, flaring to the waist -------
	# Three stacked sections approximate the flare. A plain box is the shape a
	# generic blocky avatar has, and it reads as one.
	# Two sections, not three, and a gentle taper. Three made visible steps and
	# the torso read as a stack of slabs rather than one flaring part.
	# ONE tapered part with its artwork printed on the front - see
	# BS:BUILD:TORSO. It used to be two stacked boxes, which left a visible
	# step across the chest and had nowhere to print.
	var torso := MeshInstance3D.new()
	torso.mesh = torso_mesh()
	torso.scale = Vector3(torso_w, torso_h, torso_d * 2.0)
	torso.position = Vector3(0, torso_h * 0.5, 0)
	torso.name = "Torso"
	torso.material_override = torso_material(shirt, C_BROWN, C_TAN)
	upper.add_child(torso)

	# The neck bracket, visible under the chin on the real part.
	# The neck is a peg the head sits ON, and on the real part you barely see
	# it. At full width it reads as a skin-coloured collar.
	var neck := brick_visual(1, 1, 2.4 * mm, skin, false)
	neck.position = Vector3(0, torso_h - 0.4 * mm, 0)
	neck.scale = Vector3(0.40, 1.0, 0.40)
	upper.add_child(neck)

	# --- arms: hung OUTSIDE the torso, angled out and forward ---------------
	for side in [-1.0, 1.0]:
		var sh := Node3D.new()
		sh.name = "ShoulderR" if side > 0.0 else "ShoulderL"
		# OUTSIDE the torso. At 0.46 of the torso width the arms sat inside its
		# own footprint and were invisible - the silhouette stopped reading as
		# a minifig, which is the one thing the arms are for.
		# The socket sits just outside the torso edge. On the real part the
		# torso is 16mm across and the arms take the figure to about 22mm, so
		# each arm overlaps the torso slightly and stands ~3mm proud - it does
		# not float clear of it.
		sh.position = Vector3(side * (torso_w * 0.5 + 1.0 * mm),
			torso_h * 0.80, 0)
		upper.add_child(sh)
		# A MINIFIG ARM IS SLENDER AND NEARLY VERTICAL. This was 5.9mm wide and
		# flared 0.20 radians outward, which made the pair read as shoulder
		# pads or wings rather than as arms - clearest in a front render, where
		# they stood away from the body with daylight between. The real part is
		# about 4mm across and hangs with only a slight outward set and a small
		# forward angle.
		var a := brick_visual(1, 1, 12.2 * mm, shirt, false)
		a.position = Vector3(0, -6.1 * mm, 0)
		a.scale = Vector3(0.52, 1.0, 0.62)
		a.rotation = Vector3(0.10, 0, side * -0.07)
		sh.add_child(a)
		# A minifig hand is a C-shaped clip, not a peg.
		var hand := Node3D.new()
		hand.position = Vector3(side * 1.1 * mm, -12.9 * mm, 1.8 * mm)
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
	head.position = Vector3(0, head_y - hip_y, 0)
	head.name = "Head"
	upper.add_child(head)

	# The stud on top of the head - the single most identifying feature a
	# minifig has. Hidden under most hair, visible under a hat and bare.
	var hstud := MeshInstance3D.new()
	hstud.mesh = stud_mesh()
	hstud.material_override = mat(skin)
	hstud.position = Vector3(0, head_y - hip_y + head_h * 0.5 + STUD_H * 0.5, 0)
	hstud.name = "HeadStud"
	upper.add_child(hstud)

	# Hair caps the head and overlaps it.
	# Hair sits ON the head and stops just above the brows. Dropped any lower
	# it cuts across the eyes and reads as a welding visor, which is what it
	# was doing - the brows are 2.9mm down from the crown, so the hair's
	# underside has to stay above that.
	# HAIR FOLLOWS THE SKULL. This was a 2x1 BRICK perched on a round head -
	# 0.88 wide against a 0.75 diameter skull and only 0.44 deep, so it
	# overhung left and right, left the crown bare front and back, and had four
	# corners hanging in the air. Reported from a phone as a toupee, which is
	# exactly what a rectangular slab on a cylinder looks like.
	#
	# Two round courses instead: a mass that wraps the skull down to just above
	# the brows, and a slightly smaller crown on top. Symmetric front to back,
	# because hair reads as hair from every angle and a fringe that guesses
	# which way the face points would be wrong half the time.
	var hair_r := head_r * 1.06
	var brow_floor := head_y - hip_y + head_h * 0.5 - 2.6 * mm   # stay above the brows
	var mass := brick_visual(1, 1, 3.4 * mm, hair, false, PART_ROUND)
	mass.scale = Vector3(hair_r * 2.0 / STUD, 1.0, hair_r * 2.0 / STUD)
	mass.position = Vector3(0, brow_floor + 1.7 * mm, 0)
	upper.add_child(mass)
	var crown := brick_visual(1, 1, 2.2 * mm, hair, false, PART_ROUND)
	crown.scale = Vector3(hair_r * 1.74 / STUD, 1.0, hair_r * 1.74 / STUD)
	crown.position = Vector3(0, brow_floor + 3.4 * mm + 1.1 * mm, 0)
	upper.add_child(crown)

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
	# Smooth-shaded parts carry a normal per vertex, so the face normal used to
	# decide the winding is their average. Same rule as the brick, same helper -
	# this used to be its own copy of the test, with its own sign, and that is
	# how the convention managed to be wrong in three places at once.
	var face_n := (n0 + n1 + n2).normalized()
	var pos := [p0, p1, p2]
	var uv := [t0, t1, t2]
	var nrm := [n0, n1, n2]
	for i in wind_cw(p0, p1, p2, face_n):
		st.set_normal(nrm[i])
		st.set_uv(uv[i])
		st.add_vertex(pos[i])


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


# ============================================================================
# [BS:BUILD:TORSO]
# Purpose: The torso - one tapered part, with its printing.
# Invariants:
# - ONE PART, NOT A STACK. Two boxes stacked to fake a taper leave a visible
#   step across the chest. The real part is a single trapezoid: full width at
#   the waist, cut back at the shoulders.
# - PRINTS ARE INK-LINE ARTWORK. Every LEGO torso print is bold black outlines
#   with flat fills inside - no shading, no gradients. The demo's Indy is a
#   jacket, a shirt V, a satchel strap and pocket seams, all drawn in heavy
#   line. Soft airbrushed detail reads as a video-game texture; line art reads
#   as a printed part.
# - PRINTED ON THE FRONT FACE ONLY, selected by the local normal in the
#   shader. The back and sides are plain plastic, exactly like the real part.
# - Laid out in real minifig millimetres, like the face.
# ============================================================================
const TORSO_W_MM := 16.0
const TORSO_H_MM := 15.4
const TORSO_TEX := 256

static var _torso_mesh: ArrayMesh = null


static func torso_mesh() -> ArrayMesh:
	if _torso_mesh != null:
		return _torso_mesh
	var c := 0.06
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Rings: waist (full width) up to shoulders (cut back), with a chamfer at
	# each end so the part reads as moulded like every other brick.
	var rings := [
		[-0.5, 1.00, 0.90],
		[-0.5 + c, 1.00, 1.00],
		[0.10, 0.97, 1.00],
		[0.5 - c, 0.88, 1.00],
		[0.5, 0.88, 0.90],
	]
	for ri in range(rings.size() - 1):
		_torso_band(st, rings[ri], rings[ri + 1])
	# Caps.
	for top in [false, true]:
		var rr: Array = rings[-1] if top else rings[0]
		var y: float = rr[0]
		var hw: float = rr[1] * 0.5
		var hd: float = rr[2] * 0.25
		var n := Vector3(0, 1.0 if top else -1.0, 0)
		var q := [Vector3(-hw, y, -hd), Vector3(hw, y, -hd),
				  Vector3(hw, y, hd), Vector3(-hw, y, hd)]
		_emit_tri(st, q[0], q[1], q[2], Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, n, n, n)
		_emit_tri(st, q[0], q[2], q[3], Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, n, n, n)
	# NO generate_tangents() here. This mesh carries no real UVs - the print is
	# addressed from local position in the shader - and asking SurfaceTool to
	# derive tangents from degenerate all-zero UVs corrupts the normals it was
	# given, which killed the front-face test and left the torso unprinted.
	# There is no normal map on this part, so there is nothing to want tangents
	# for either.
	_torso_mesh = st.commit()
	return _torso_mesh


static func _torso_band(st: SurfaceTool, r0: Array, r1: Array) -> void:
	var a := _torso_profile(r0)
	var b := _torso_profile(r1)
	for i in range(a.size()):
		var j := (i + 1) % a.size()
		var p0: Vector3 = a[i][0]
		var p1: Vector3 = a[j][0]
		var p2: Vector3 = b[j][0]
		var p3: Vector3 = b[i][0]
		var n0: Vector3 = a[i][1]
		var n1: Vector3 = a[j][1]
		_emit_tri(st, p0, p1, p2, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, n0, n1, n1)
		_emit_tri(st, p0, p2, p3, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, n0, n1, n0)


# The cross-section is a ROUNDED RECTANGLE with exact per-vertex normals, not a
# superellipse. A rounded blob's front normal only points at +Z along a narrow
# central strip, so the shader's front-face test passed on a sliver and the
# print showed as a band at the collar. A real torso is a flat-fronted part
# with cut corners, and a flat front is what a print needs.
static func _torso_profile(r: Array) -> Array:
	var y: float = r[0]
	var hw: float = float(r[1]) * 0.5
	var hd: float = float(r[2]) * 0.25
	var rc: float = minf(hw, hd) * 0.42          # corner radius
	var out: Array = []
	var faces := [
		[Vector3(0, 0, 1), Vector2(-1, 1), Vector2(1, 1)],      # front
		[Vector3(1, 0, 0), Vector2(1, 1), Vector2(1, -1)],      # right
		[Vector3(0, 0, -1), Vector2(1, -1), Vector2(-1, -1)],   # back
		[Vector3(-1, 0, 0), Vector2(-1, -1), Vector2(-1, 1)],   # left
	]
	for fi in range(4):
		var n: Vector3 = faces[fi][0]
		var c0: Vector2 = faces[fi][1]
		var c1: Vector2 = faces[fi][2]
		# The flat run of this face, inset by the corner radius at each end.
		var p_a := Vector3(c0.x * hw, y, c0.y * hd) - Vector3(sign(c0.x) * rc, 0, 0) * absf(n.z) \
			- Vector3(0, 0, sign(c0.y) * rc) * absf(n.x)
		var p_b := Vector3(c1.x * hw, y, c1.y * hd) - Vector3(sign(c1.x) * rc, 0, 0) * absf(n.z) \
			- Vector3(0, 0, sign(c1.y) * rc) * absf(n.x)
		out.append([p_a, n])
		out.append([p_b, n])
		# Corner arc into the next face.
		var nn: Vector3 = faces[(fi + 1) % 4][0]
		var cx: float = c1.x * (hw - rc)
		var cz: float = c1.y * (hd - rc)
		for k in range(1, 3):
			var t := float(k) / 3.0
			var dir := n.lerp(nn, t).normalized()
			out.append([Vector3(cx + dir.x * rc, y, cz + dir.z * rc), dir])
	return out


static func torso_texture(shirt: Color, strap: Color, under: Color) -> ImageTexture:
	var key := "torso_%d_%d" % [shirt.to_rgba32(), strap.to_rgba32()]
	if _mats.has(key):
		return _mats[key]
	var n := TORSO_TEX
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(shirt)
	var ppm := float(n) / TORSO_W_MM          # pixels per millimetre
	var ink := C_BLACK
	# The jacket has to separate clearly from the shirt or the whole print
	# collapses into one flat colour at any distance.
	var jacket := shirt.darkened(0.45)

	# Jacket panels either side of the opening.
	_tpoly(img, [[0.4, 0.0], [5.6, 0.0], [7.3, 7.2], [6.9, 15.4], [0.4, 15.4]], ppm, jacket)
	_tpoly(img, [[15.6, 0.0], [10.4, 0.0], [8.7, 7.2], [9.1, 15.4], [15.6, 15.4]], ppm, jacket)

	# The shirt showing through a wide V, with lapels outlined over it.
	_tpoly(img, [[5.6, 0.0], [10.4, 0.0], [8.7, 7.4], [7.3, 7.4]], ppm, under)
	_tline(img, [[5.6, 0.0], [7.3, 7.4]], ppm, 0.34, ink)
	_tline(img, [[10.4, 0.0], [8.7, 7.4]], ppm, 0.34, ink)
	# Lapel folds - the line that says "collar" rather than "hole".
	_tline(img, [[4.3, 0.0], [7.0, 4.4]], ppm, 0.34, ink)
	_tline(img, [[11.7, 0.0], [9.0, 4.4]], ppm, 0.34, ink)
	# Shirt placket and buttons, below the V where the strap does not cover.
	_tline(img, [[8.0, 7.4], [8.0, 13.4]], ppm, 0.26, ink)
	for i in range(3):
		_tdisc(img, 8.0, 8.6 + float(i) * 1.9, 0.34, ppm, ink)
	# Jacket hem seams.
	_tline(img, [[6.9, 7.4], [6.9, 15.4]], ppm, 0.26, ink)
	_tline(img, [[9.1, 7.4], [9.1, 15.4]], ppm, 0.26, ink)

	# The strap, drawn as a band with an outline on each edge - the single most
	# recognisable thing on the demo's Indy.
	_tband(img, [4.0, 0.0], [12.4, 15.4], 2.1, ppm, strap, ink)

	# Chest pockets with flaps.
	for px in [2.2, 11.3]:
		_trect(img, px, 8.4, 2.6, 3.0, ppm, jacket.lightened(0.10), ink)
		_trect(img, px - 0.2, 7.7, 3.0, 0.9, ppm, jacket.lightened(0.18), ink)

	# Belt.
	_trect(img, 0.4, 13.6, 15.2, 1.5, ppm, jacket.darkened(0.30), ink)
	_trect(img, 6.9, 13.5, 2.2, 1.7, ppm, C_TAN, ink)

	var tex := ImageTexture.create_from_image(img)
	_mats[key] = tex
	return tex


static func _tpx(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


static func _trect(img: Image, x: float, y: float, w: float, h: float,
		ppm: float, fill: Color, ink: Color) -> void:
	var x0 := int(x * ppm)
	var y0 := int(y * ppm)
	var x1 := int((x + w) * ppm)
	var y1 := int((y + h) * ppm)
	var t := int(maxf(0.28 * ppm, 1.0))
	for yy in range(y0, y1):
		for xx in range(x0, x1):
			var edge: bool = xx < x0 + t or xx >= x1 - t or yy < y0 + t or yy >= y1 - t
			_tpx(img, xx, yy, ink if edge else fill)


static func _tdisc(img: Image, x: float, y: float, r: float, ppm: float, c: Color) -> void:
	var rr := int(r * ppm)
	for dy in range(-rr, rr + 1):
		for dx in range(-rr, rr + 1):
			if dx * dx + dy * dy <= rr * rr:
				_tpx(img, int(x * ppm) + dx, int(y * ppm) + dy, c)


static func _tline(img: Image, pts: Array, ppm: float, w: float, c: Color) -> void:
	var a := Vector2(float(pts[0][0]), float(pts[0][1])) * ppm
	var b := Vector2(float(pts[1][0]), float(pts[1][1])) * ppm
	var steps := int(maxf(a.distance_to(b), 1.0))
	var rr := int(maxf(w * ppm * 0.5, 1.0))
	for i in range(steps + 1):
		var p := a.lerp(b, float(i) / float(steps))
		for dy in range(-rr, rr + 1):
			for dx in range(-rr, rr + 1):
				if dx * dx + dy * dy <= rr * rr:
					_tpx(img, int(p.x) + dx, int(p.y) + dy, c)


static func _tband(img: Image, a: Array, b: Array, w: float, ppm: float,
		fill: Color, ink: Color) -> void:
	_tline(img, [a, b], ppm, w + 0.55, ink)
	_tline(img, [a, b], ppm, w, fill)


static func _tpoly(img: Image, pts: Array, ppm: float, c: Color) -> void:
	var ys: Array = []
	for p in pts:
		ys.append(float(p[1]) * ppm)
	var y0 := int(ys.min())
	var y1 := int(ys.max())
	for y in range(y0, y1 + 1):
		var xs: Array = []
		for i in range(pts.size()):
			var p1 := Vector2(float(pts[i][0]), float(pts[i][1])) * ppm
			var p2 := Vector2(float(pts[(i + 1) % pts.size()][0]),
				float(pts[(i + 1) % pts.size()][1])) * ppm
			if (p1.y <= float(y) and p2.y > float(y)) or (p2.y <= float(y) and p1.y > float(y)):
				xs.append(p1.x + (float(y) - p1.y) / (p2.y - p1.y) * (p2.x - p1.x))
		xs.sort()
		var i2 := 0
		while i2 + 1 < xs.size():
			for x in range(int(xs[i2]), int(xs[i2 + 1]) + 1):
				_tpx(img, x, y, c)
			i2 += 2


static func torso_material(shirt: Color, strap: Color, under: Color) -> ShaderMaterial:
	var key := "torsomat_%d_%d" % [shirt.to_rgba32(), strap.to_rgba32()]
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/torso.gdshader")
	m.set_shader_parameter("print_tex", torso_texture(shirt, strap, under))
	m.set_shader_parameter("base_color", shirt)
	m.set_shader_parameter("p_roughness", PLASTIC_ROUGHNESS)
	m.set_shader_parameter("p_specular", PLASTIC_SPECULAR)
	m.set_shader_parameter("p_rim", PLASTIC_RIM * 0.5)
	_mats[key] = m
	return m
# [BS:BUILD:TORSO:END]
