# Hand-authored set pieces.
#
# Everything else in the corridor is scattered by BS:WORLD:STREAM. This file is
# the opposite: every object is placed by hand, in relation to the others, to
# teach a verb and land a joke. It exists to answer whether the missing
# ingredient in this game is density or INTENT.
class_name SetPiece
extends RefCounted

const S := 0.5
const H := 0.6

# ============================================================================
# [BS:CONTENT:HOG_LOT]
# Purpose: A ~60 second authored farmyard. Three collectibles, three verbs.
# Invariants:
# - Each sensor ball teaches a DIFFERENT verb, and the level is the tutorial:
#     ball 1 is inside the haystack  -> SMASH
#     ball 2 is atop the water tower -> BUILD the steps, then JUMP
#     ball 3 is behind the heavy gate-> SWAP to Bill
#   If a future edit makes two balls reachable the same way, the piece has
#   lost its point and one of them should move.
# - The yard is COMPOSED: one entrance, a barn closing the far side, fences
#   framing the space. A player must be able to read where to go without a
#   marker. Scattering these objects randomly would defeat the whole exercise.
# - The gag has a setup and a payoff. A cow visible on the barn roof is absurd
#   on sight; landing unhurt and walking off is the punchline, and it teaches
#   North Star Law 1 in the process.
# - Layout is authored in LOCAL coordinates around an origin so the piece can
#   be dropped anywhere in the corridor.
# ============================================================================
static func hog_lot(origin: Vector3) -> Dictionary:
	var st: Array[Structure] = []
	var o := origin

	# --- the barn closes the far side and gives the yard a back wall --------
	st.append(PropBuilder.barn(o + Vector3(0, 0, 19)))

	# --- fences frame the space and leave exactly one way in ---------------
	st.append(PropBuilder.fence_run(o + Vector3(-15, 0, -3), o + Vector3(-15, 0, 15)))
	st.append(PropBuilder.fence_run(o + Vector3(15, 0, -3), o + Vector3(15, 0, 15)))
	st.append(PropBuilder.fence_run(o + Vector3(-15, 0, -3), o + Vector3(-6, 0, -3)))
	st.append(PropBuilder.fence_run(o + Vector3(6, 0, -3), o + Vector3(15, 0, -3)))

	# --- BALL 1: buried in the haystack. Teaches SMASH. --------------------
	# Placed just inside the entrance so the first thing a player does in this
	# yard is hit something and be rewarded for it.
	for i in range(4):
		var a := TAU * float(i) / 4.0
		st.append(PropBuilder.hay_bale(o + Vector3(-8.0 + cos(a) * 1.6, 0, 5.0 + sin(a) * 1.6), a))
	st.append(PropBuilder.crate(o + Vector3(-6.4, 0, 3.2), 0.4, true))

	# --- BALL 2: on the water tower. Teaches BUILD, then JUMP. -------------
	# The tower is deliberately across the yard from the haystack, so the
	# player crosses the space and sees the gate on the way.
	st.append(PropBuilder.water_tower(o + Vector3(10, 0, 6)))
	# the rubble that becomes the steps sits at its foot, unmissable
	st.append(PropBuilder.crate(o + Vector3(7.6, 0, 3.4), 1.1, false))
	st.append(PropBuilder.tyre_stack(o + Vector3(8.8, 0, 2.2)))

	# --- BALL 3: behind the heavy gate. Teaches the character SWAP. --------
	# A collapsed silo jammed across an alcove in the corner. Jo bounces off
	# it; only Bill shifts it. Set as `heavy` by the caller.
	var gate := PropBuilder.silo(o + Vector3(-11, 0, 14))
	st.append(gate)
	st.append(PropBuilder.barrel(o + Vector3(-13.2, 0, 12.4), BrickLib.C_RED))

	# --- deliberate dressing along the route, not scattered ---------------
	st.append(PropBuilder.trough(o + Vector3(2, 0, 9), 0.0))
	st.append(PropBuilder.bench(o + Vector3(-3, 0, 1), 0.2))
	st.append(PropBuilder.mailbox(o + Vector3(5.5, 0, -2.2), 3.0))
	st.append(PropBuilder.bin(o + Vector3(-5.0, 0, 12.5)))
	st.append(PropBuilder.crop_patch(o + Vector3(12.5, 0, 12.0)))
	st.append(PropBuilder.tree(o + Vector3(-17, 0, 8), 1.15))
	st.append(PropBuilder.tree(o + Vector3(17.5, 0, 2), 0.95))
	st.append(PropBuilder.road_sign(o + Vector3(0, 0, -4.5), 0.0))

	return {
		"structures": st,
		"gate": gate,
		# ball positions, in the order they are meant to be found
		"balls": [
			o + Vector3(-8.0, 1.1, 5.0),     # in the haystack
			o + Vector3(10.0, 5.4, 6.0),     # atop the water tower
			o + Vector3(-11.0, 1.0, 16.6),   # behind the gate
		],
		"build_pos": o + Vector3(7.4, 0, 3.6),
		# steps assembled by the build, climbing toward the tower
		"steps": [
			o + Vector3(8.2, 0, 4.6),
			o + Vector3(8.9, 0, 5.4),
			o + Vector3(9.5, 0, 6.2),
		],
		"cow_pos": o + Vector3(0, 6.6, 19),  # on the barn roof. Obviously.
		"origin": o,
	}
# [BS:CONTENT:HOG_LOT:END]


# ============================================================================
# [BS:CONTENT:BUILD_STEPS]
# Purpose: The bricks the build spot assembles - a staircase to the tower.
# Invariants:
# - Each step is its own body with its own collider, so the player can jump
#   from one to the next. A single ramp collider would be a slope the player
#   slides off.
# - Step rise stays under the jump apex. Jump is 9.4 m/s against 22 gravity,
#   so about 2.0 m of clearance; 1.2 m steps leave real margin.
# ============================================================================
static func step_block(pos: Vector3, height: float) -> Structure:
	var st := Structure.new()
	st.position = pos
	var courses := maxi(1, int(round(height / H)))
	for c in range(courses):
		st.add_brick(4, 4, H, BrickLib.C_TAN if c % 2 == 0 else BrickLib.C_BROWN,
			Vector3(0, float(c) * H + H * 0.5, 0))
	st.finish()
	return st
# [BS:CONTENT:BUILD_STEPS:END]


# ============================================================================
# [BS:CONTENT:SCENES]
# Purpose: The hand-composed scenes the storm walks into, dropped along the
#   corridor at intervals. These exist to answer "what world am I in" the way
#   a screenshot cannot: by being a PLACE with an arrangement, not a scatter.
# Invariants:
# - EVERY SCENE IS COMPOSED, LIKE THE HOG LOT. One way in, something closing
#   the far side, and the interesting thing placed where a player will meet it
#   rather than where a hash put it. If a scene would survive having its
#   objects shuffled, it is not a scene.
# - They are dressed from the SAME props as the rest of the world. A scene that
#   needs bespoke geometry is a diorama, and the funnel has to be able to take
#   it apart like anything else.
# - Nothing here is copied from the film. Docs/ATTRIBUTION.md forbids taking
#   any asset, model, texture or layout from it, and these are ordinary
#   objects - a drive-in, a barn, a field of cattle - arranged by hand.
# - Local coordinates around an origin, so a scene can be dropped anywhere.
# - A SCENE MUST STILL FEED THE STORM. Composition arranges things where a
#   player will meet them, which is near the middle; the funnel weaves out to
#   42m. Measured 2026-09-11, the first version of these scenes dropped bricks
#   torn from 411-429 to 175-230 across four rounds each way, and a per-10m
#   dump showed why: the barn run yielded 18 bricks over the stretch where
#   procedural ground gives 150-240. Every scene therefore calls _surround(),
#   which fills the reserved area's FULL WIDTH with field clutter outside the
#   composition. See tools/reach_probe.gd for the measurement.
# ============================================================================


# Field clutter across the whole width of a scene's reserved area, kept clear
# of the composed middle so it dresses the scene rather than joining it.
#
# This is not procedural scatter sneaking into authored ground: it is part of
# the scene, authored, deterministic in the scene's own frame, and it exists
# because a composition that only occupies the middle twenty metres starves a
# storm that spends most of its time further out.
static func _surround(o: Vector3, variant: int, keep_clear: float = 21.0) -> Array[Structure]:
	var st: Array[Structure] = []
	# Deterministic, and keyed to WHICH SCENE rather than to world position, so
	# a given scene looks the same wherever it lands - that is what makes it a
	# place rather than a roll - while the three do not share one clutter field.
	# Without the variant all three carried identical surrounds, which is the
	# same periodicity that made the procedural corridor read as samey.
	var vr := 1.0 + float(variant) * 0.37
	for i in range(26):
		var side: float = 1.0 if (i + variant) % 2 == 0 else -1.0
		var x: float = side * (keep_clear + fmod(float(i) * 7.3 * vr, 19.0))
		var z: float = 1.0 + fmod(float(i) * 13.7 * vr + float(variant) * 5.0, 36.0)
		var p := o + Vector3(x, 0, z)
		# Mostly crop, because this is a field; a few solid things so the
		# stretch pays a FINISH bonus as well as loose bricks.
		if (i + variant) % 5 == 4:
			st.append(PropBuilder.hay_bale(p, fmod(float(i), 3.0)))
		elif (i + variant) % 7 == 3:
			st.append(PropBuilder.tree(p, 0.9 + fmod(float(i), 4.0) * 0.12))
		else:
			st.append(PropBuilder.crop_patch(p))
	return st

# THE DRIVE-IN. Rows of cars facing a screen, a booth behind them, speaker
# posts down every row. The storm coming through it is the shot.
static func drive_in(origin: Vector3) -> Dictionary:
	var st: Array[Structure] = []
	var o := origin

	# The screen closes the far side and is the thing you see from the road.
	st.append(PropBuilder.drive_in_screen(o + Vector3(0, 0, 30), 0.0))

	# Three ranks of cars, all facing it, staggered so the back rows can see.
	var colours := [BrickLib.C_BLUE, BrickLib.C_RED, BrickLib.C_WHITE,
		BrickLib.C_YELLOW, BrickLib.C_LGREEN]
	for row in range(3):
		var rz: float = 10.0 + float(row) * 7.0
		var count := 5 - row
		for i in range(count):
			var x: float = (float(i) - float(count - 1) * 0.5) * 7.0 + float(row % 2) * 3.0
			# Facing the screen, which is +Z from here.
			st.append(PropBuilder.pickup(o + Vector3(x, 0, rz),
				colours[(row * 3 + i) % colours.size()], 0.0, row == 0 and i == 0))
			# A speaker post between every pair of bays.
			st.append(PropBuilder.mailbox(o + Vector3(x + 3.5, 0, rz - 1.4), PI * 0.5))

	# The booth sits behind the cars, between them and the way in.
	st.append(PropBuilder.booth(o + Vector3(-9, 0, 2), 0.0))
	st.append(PropBuilder.bin(o + Vector3(-5.6, 0, 1.2)))
	st.append(PropBuilder.bench(o + Vector3(-5.0, 0, 4.0), 0.0))

	# Fences frame the lot and leave one entrance, dead centre.
	st.append(PropBuilder.fence_run(o + Vector3(-20, 0, 0), o + Vector3(-5, 0, 0)))
	st.append(PropBuilder.fence_run(o + Vector3(5, 0, 0), o + Vector3(20, 0, 0)))
	st.append(PropBuilder.fence_run(o + Vector3(-20, 0, 0), o + Vector3(-20, 0, 28)))
	st.append(PropBuilder.fence_run(o + Vector3(20, 0, 0), o + Vector3(20, 0, 28)))
	st.append(PropBuilder.road_sign(o + Vector3(2.5, 0, -3.0), 0.0))
	st.append(PropBuilder.power_line(o + Vector3(-24, 0, -2), o + Vector3(-24, 0, 32)))

	st.append_array(_surround(o, 0))
	return {
		"structures": st,
		# On top of the screen, because of course it is.
		"cows": [o + Vector3(3.0, 6.4, 30.0)],
		"origin": o,
	}


# THE BARN RUN. A barn open at both ends, a truck parked pointing at it, and
# hay stacked inside to burst through. The ram verb already exists; this is
# the first place in the game built to invite it.
static func barn_run(origin: Vector3) -> Dictionary:
	var st: Array[Structure] = []
	var o := origin

	st.append(PropBuilder.open_barn(o + Vector3(0, 0, 16), 0.0))

	# The truck, parked square with the opening and well back, so the run at
	# it is a decision rather than an accident.
	st.append(PropBuilder.pickup(o + Vector3(0, 0, -6), BrickLib.C_RED, 0.0, true))

	# Hay inside, on the centreline. This is what makes going through it
	# better than going round.
	for i in range(4):
		st.append(PropBuilder.hay_bale(o + Vector3(0, 0, 10.0 + float(i) * 4.0), 0.0))
	st.append(PropBuilder.crate(o + Vector3(-2.2, 0, 13.0), 0.3, true))
	st.append(PropBuilder.crate(o + Vector3(2.2, 0, 20.0), 1.1, false))

	# Fences funnel toward the opening, so the run reads before it is taken.
	st.append(PropBuilder.fence_run(o + Vector3(-14, 0, -2), o + Vector3(-4, 0, 5)))
	st.append(PropBuilder.fence_run(o + Vector3(14, 0, -2), o + Vector3(4, 0, 5)))
	# And something worth arriving at on the far side.
	st.append(PropBuilder.silo(o + Vector3(-9, 0, 30)))
	st.append(PropBuilder.water_tower(o + Vector3(9, 0, 32)))
	st.append(PropBuilder.tree(o + Vector3(-16, 0, 22), 1.2))
	st.append(PropBuilder.tree(o + Vector3(16, 0, 26), 1.0))

	st.append_array(_surround(o, 1))
	return {
		"structures": st,
		"cows": [o + Vector3(0.0, 0.0, 24.0), o + Vector3(-3.0, 0.0, 27.0)],
		"origin": o,
	}


# THE COW FIELD. A fenced pasture and a herd, and nothing else in the way.
# The flying cow is the single most quoted image the film has, and Law 1 -
# cows fly, cows land, cows are never destroyed - is what makes it a joke
# rather than a casualty. This is the scene that exists to land it.
static func cow_field(origin: Vector3) -> Dictionary:
	var st: Array[Structure] = []
	var o := origin

	# A big open pasture, deliberately empty of cover, so the herd is the only
	# thing in frame when the funnel arrives.
	for sx in [-1.0, 1.0]:
		st.append(PropBuilder.fence_run(o + Vector3(sx * 18, 0, -2), o + Vector3(sx * 18, 0, 30)))
	st.append(PropBuilder.fence_run(o + Vector3(-18, 0, 30), o + Vector3(18, 0, 30)))
	st.append(PropBuilder.fence_run(o + Vector3(-18, 0, -2), o + Vector3(-4, 0, -2)))
	st.append(PropBuilder.fence_run(o + Vector3(4, 0, -2), o + Vector3(18, 0, -2)))

	# The farm end: a windmill pumping to a trough, which is what the fence is
	# actually for.
	st.append(PropBuilder.windmill(o + Vector3(-13, 0, 24)))
	st.append(PropBuilder.trough(o + Vector3(-9, 0, 22), PI * 0.5))
	st.append(PropBuilder.trough(o + Vector3(-9, 0, 25), PI * 0.5))
	st.append(PropBuilder.hay_bale(o + Vector3(11, 0, 20), 0.4))
	st.append(PropBuilder.hay_bale(o + Vector3(13.5, 0, 23), 1.2))
	st.append(PropBuilder.storm_cellar(o + Vector3(15, 0, 4), 0.0))
	st.append(PropBuilder.road_sign(o + Vector3(1.5, 0, -4.0), 0.0))

	var herd: Array = []
	for i in range(9):
		var a: float = TAU * float(i) / 9.0
		herd.append(o + Vector3(cos(a) * (5.0 + fmod(float(i) * 3.7, 6.0)), 0.0,
			14.0 + sin(a) * (5.0 + fmod(float(i) * 2.3, 5.0))))
	st.append_array(_surround(o, 2))
	return {"structures": st, "cows": herd, "origin": o}
# [BS:CONTENT:SCENES:END]
