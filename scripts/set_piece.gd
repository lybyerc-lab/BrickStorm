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
