# The corridor's division into sub-areas, and their lifecycle.
#
# This is the SINGLE authority on where one part of the world ends and the next
# begins. Before it existed, three systems each answered that question their own
# way: the streamer with a bare float frontier, the set piece with open-coded
# arithmetic against a magic Z, and the camera and audio not at all. See
# Docs/TT_ENGINE_NOTES.md section 8.
class_name AreaMap
extends RefCounted

const LETTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

var areas: Array[SubArea] = []
# Z at which the next area begins. Areas tile the corridor with no gap and no
# overlap; --selftest asserts it.
var frontier: float = 0.0
var depth: float = 34.0

var _next_index: int = 0
# Areas placed by hand before the streamer reaches them, keyed by nothing in
# particular - they are simply consulted when deciding what to create next.
var _pending_authored: Array[SubArea] = []


func _name_for(i: int) -> String:
	# A, B, ... Z, A2, B2, ... - the lettered scheme TT use, extended so a long
	# run does not collide.
	var cycle := i / LETTERS.length()
	var letter := LETTERS[i % LETTERS.length()]
	return letter if cycle == 0 else "%s%d" % [letter, cycle + 1]


# Reserve a stretch of corridor for hand-authored content. Must be called
# before the streamer reaches it; returns the area so the caller can set its
# framing hints.
func reserve(z_start: float, area_depth: float, area_id: String) -> SubArea:
	var a := SubArea.new()
	a.id = area_id
	a.kind = SubArea.Kind.AUTHORED
	a.z0 = z_start
	a.depth = area_depth
	_pending_authored.append(a)
	return a


func _claim_authored_at(z: float) -> SubArea:
	for i in range(_pending_authored.size()):
		var a := _pending_authored[i]
		# An authored area is taken as soon as the frontier reaches it. Its own
		# z0 wins over the tiling grid - hand-placed content sits where it was
		# placed, and the procedural run resumes after it.
		if z + depth > a.z0:
			_pending_authored.remove_at(i)
			return a
	return null


# Create areas until the corridor is covered up to front_z. `populate` is
# called with each newly created PROCEDURAL area; authored areas are never
# passed to it, which is the whole of the reservation rule.
func ensure_ahead(front_z: float, populate: Callable) -> int:
	var made := 0
	while frontier < front_z:
		var a := _claim_authored_at(frontier)
		if a != null:
			# Close any gap between the grid and the hand-placed area so the
			# tiling stays continuous.
			if a.z0 > frontier:
				var filler := _new_procedural(frontier, a.z0 - frontier)
				populate.call(filler)
				made += 1
			a.index = _next_index
			_next_index += 1
			areas.append(a)
			frontier = a.z1()
		else:
			var p := _new_procedural(frontier, depth)
			populate.call(p)
			made += 1
			frontier = p.z1()
	return made


func _new_procedural(z_start: float, area_depth: float) -> SubArea:
	var a := SubArea.new()
	a.kind = SubArea.Kind.PROCEDURAL
	a.z0 = z_start
	a.depth = area_depth
	a.index = _next_index
	a.id = _name_for(_next_index)
	_next_index += 1
	areas.append(a)
	return a


func area_at(z: float) -> SubArea:
	for a in areas:
		if a.contains_z(z):
			return a
	return null


# Register a structure with the area that contains it. Adoption is TOTAL: a
# structure placed outside every area falls to the nearest one. Ownership is
# what the reclaim lifecycle keys on, so a structure nothing owns is a leak
# that lives until the process exits.
func adopt(st: Node3D) -> void:
	var a := area_at(st.global_position.z)
	if a == null:
		a = nearest(st.global_position.z)
	if a != null:
		a.structures.append(st)


func nearest(z: float) -> SubArea:
	var best: SubArea = null
	var best_d := INF
	for a in areas:
		var d: float = 0.0 if a.contains_z(z) else minf(absf(z - a.z0), absf(z - a.z1()))
		if d < best_d:
			best_d = d
			best = a
	return best


# Retire every area that lies entirely behind the cutoff, returning the
# structures that should be freed.
#
# A structure the funnel has THROWN forward is not freed with its birth area -
# it is handed to the area it is now in. Freeing it on its birth area's
# schedule would delete debris that is still on screen ahead of the storm.
func retire_behind(cutoff_z: float) -> Array:
	var doomed: Array = []
	var keep: Array[SubArea] = []
	for a in areas:
		if a.z1() >= cutoff_z:
			keep.append(a)
			continue
		for st in a.structures:
			if not is_instance_valid(st):
				continue
			if st.global_position.z >= cutoff_z:
				var host := area_at(st.global_position.z)
				if host != null and host != a:
					host.structures.append(st)
					continue
			doomed.append(st)
	areas = keep
	return doomed


# Drop freed or wandered entries. Called after structures are queued for
# deletion so an area's list does not grow without bound.
func compact() -> void:
	for a in areas:
		var live: Array = []
		for st in a.structures:
			if is_instance_valid(st):
				live.append(st)
		a.structures = live


# The framing bias in effect at z, blended across every area whose range of
# effect reaches it. Areas do not overlap, but their ranges of effect do, so
# the strongest influence wins rather than the sum - two adjacent hints must
# not add up to a camera further back than either one asked for.
func framing_at(z: float) -> Vector2:
	var out := Vector2.ZERO
	for a in areas:
		if is_zero_approx(a.cam_back_bias) and is_zero_approx(a.cam_height_bias):
			continue
		var w := a.framing_weight(z)
		if w <= 0.0:
			continue
		out.x = maxf(out.x, a.cam_back_bias * w)
		out.y = maxf(out.y, a.cam_height_bias * w)
	return out


# True when the areas tile [start, frontier) with no gap and no overlap.
# --selftest asserts this; a gap is a hole the streamer never fills and an
# overlap is content generated twice.
func is_contiguous() -> bool:
	for i in range(1, areas.size()):
		if not is_equal_approx(areas[i].z0, areas[i - 1].z1()):
			return false
	return areas.is_empty() or is_equal_approx(areas[-1].z1(), frontier)
