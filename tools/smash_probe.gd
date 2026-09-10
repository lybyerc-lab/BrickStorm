# How many smashes does a prop take?
#
# The four-round playthrough measured SMASH/min falling from 6.3 to a mean of
# 3.4 after the props were rebuilt from round parts. The suspicion was that
# fewer, larger parts meant a prop reached is_rubble() in one hit where it used
# to take three - and since a hit that finds nothing logs no SMASH event, the
# verb rate fell out of a change that was only ever about silhouette.
#
# This measures it directly: the same prop, at the same size, subdivided
# coarsely and finely, counting hits to rubble. If those two numbers differ,
# then how a model is built is silently setting the pace of the game, and no
# amount of art work can be done without moving it.
extends SceneTree

const S := 0.5
const H := 0.6

# Hit, hit, gone. Fewer than three and a prop is a single SMASH event.
const MIN_HITS := 3


func _initialize() -> void:
	_run()


# Structures must be in the tree AND have had a frame before global_transform
# means anything; without it every brick reports its local position and the
# radius test is measured against the wrong points. The first run of this probe
# printed a full set of numbers with that error on every single call.


# A drum of `courses` round bricks, always 1.8 units tall and 2 studs across,
# so total volume is fixed and only the granularity changes.
static func _drum(courses: int) -> Structure:
	var st := Structure.new()
	var ch := 1.8 / float(courses)
	for c in range(courses):
		st.add_part(BrickLib.PART_ROUND, 2, 2, ch, BrickLib.C_BLUE,
			Vector3(0, float(c) * ch + ch * 0.5, 0), Vector3.ZERO, false)
	st.finish()
	return st


# One smash, exactly as BS:PLAYER:SMASH issues it - including the bite, which
# is taken from Structure rather than restated here. The first version of this
# probe called tear() with its own five arguments, so volume_budget defaulted
# to off and the probe reported no change after the fix had landed.
func _smash(st: Structure, at: Vector3, reach: float, parent: Node3D) -> int:
	return st.tear(at, reach, parent, 10, Structure.HEAVY_STRENGTH,
		Structure.SMASH_BITE).size()


func _hits_to_rubble(st: Structure, reach: float, parent: Node3D) -> int:
	var hits := 0
	# A smash that tears nothing logs no SMASH event, so stop counting the
	# moment one comes back empty - that is what the player experiences.
	while not st.is_rubble() and hits < 200:
		var got := _smash(st, st.global_position + Vector3(0, 0.9, 0), reach, parent)
		if got == 0:
			break
		hits += 1
	return hits


func _run() -> void:
	var r := Node3D.new()
	root.add_child(r)
	var parent := Node3D.new()
	r.add_child(parent)
	await process_frame
	var reach := 3.4                       # Player.smash_radius(), Jo
	var bad := 0

	print("prop                     parts  hits-to-rubble")
	var props := {
		"barrel (as shipped)": PropBuilder.barrel(Vector3.ZERO),
		"bin": PropBuilder.bin(Vector3.ZERO),
		"crate": PropBuilder.crate(Vector3.ZERO),
		"hay bale": PropBuilder.hay_bale(Vector3.ZERO),
		"tyre stack": PropBuilder.tyre_stack(Vector3.ZERO),
		"mailbox": PropBuilder.mailbox(Vector3.ZERO),
	}
	for name in props:
		var st: Structure = props[name]
		r.add_child(st)
		await process_frame
		var n := st.entries.size()
		var hits := _hits_to_rubble(st, reach, parent)
		print("%-24s %5d  %d" % [name, n, hits])
		# A smashable that dies in one hit is one SMASH event, and that event
		# is the player verb the whole comparison against LEGO turns on. Three
		# is the floor: hit, hit, gone.
		if hits < MIN_HITS:
			print("   FAIL: clears in %d hit(s); a smashable needs at least %d"
				% [hits, MIN_HITS])
			bad += 1
		r.remove_child(st)
		st.queue_free()

	# The controlled pair: identical volume, different subdivision.
	print("")
	print("same drum, same volume, different granularity:")
	# Only granularities whose parts are SMALLER than the bite can be
	# decoupled from each other - a budget cannot take a fraction of a part, so
	# a prop built from three lumps takes three hits whatever the budget is.
	# The coarse case is printed as a floor rather than counted as a failure,
	# because it is a property of the model, not of this code.
	var results: Array = []
	var drum_volume := 1.8
	for courses in [3, 6, 12, 21]:
		var st := _drum(courses)
		r.add_child(st)
		await process_frame
		var hits := _hits_to_rubble(st, reach, parent)
		var part_vol := drum_volume / float(courses)
		var coarse: bool = part_vol > Structure.SMASH_BITE
		if not coarse:
			results.append(hits)
		print("  %2d courses -> %2d parts, %2d hits%s" % [courses,
			st.entries.size(), hits,
			"   (coarser than the bite - part count is the floor)" if coarse else ""])
		r.remove_child(st)
		st.queue_free()
	var lo: int = results.min()
	var hi: int = results.max()
	print("")
	if hi > lo + 1:
		print("FAIL: the same prop takes %d hits built coarsely and %d built"
			% [lo, hi] + " finely, so part granularity is setting the pace of"
			+ " the game")
		bad += 1
	if lo < MIN_HITS:
		print("FAIL: the drum clears in %d hit(s) at some granularity" % lo)
		bad += 1
	print("SMASHPROBE %s" % ("OK" if bad == 0 else "FAIL (%d)" % bad))
	quit()
