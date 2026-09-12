# How much of each scene the storm can actually reach.
#
# The storm runs down the corridor weaving on x, with a damage radius of 9.5m.
# A scene can be full of parts and still starve it, if the parts are arranged
# for the CAMERA - spread wide so the composition reads - rather than for the
# funnel. Four measured rounds put bricks torn at 175-230 against 383-410 for
# the procedural ground the scenes replaced, so this asks, per scene, what
# fraction of its parts a passing funnel is ever within reach of.
#
# THE FIRST VERSION OF THIS PROBE WAS WRONG and reported 1.2% / 0.0% / 5.0%.
# It built every scene at z=0 and sampled the funnel's path from z=-24, so it
# measured ONE arbitrary alignment of the storm's weave - the phase that
# happens to occur in the first twelve seconds - and called it the answer. The
# weave is 22m of sine on x with two more terms on top; a scene at z=327 meets
# a completely different part of it. What a scene must be judged on is the
# SPREAD over the positions it can actually land at, so the origin is swept
# across the corridor and the distribution reported.
extends SceneTree

const REACH := 9.5          # Tornado.damage_radius
const DRIFT := 22.0         # Tornado.corridor_drift


func _initialize() -> void:
	# The funnel's x at a given z, sampled the way it actually weaves. The
	# weave is time-driven, so this walks the same integration the storm does.
	var xs: Array = []
	var zs: Array = []
	var t := 0.0
	var z := -24.0
	while t < 320.0:
		var pace: float = 1.05 + 0.20 * sin(t * 0.043) + 0.10 * sin(t * 0.017 + 1.3)
		z += 3.0 * pace * (1.0 / 60.0)
		var x: float = sin(t * 0.16) * DRIFT + cos(t * 0.071) * DRIFT * 0.4 \
			+ sin(t * 0.0237 + 2.1) * DRIFT * 0.5
		xs.append(x)
		zs.append(z)
		t += 1.0 / 60.0

	print("")
	print("%-10s %7s   %-28s %s" % ["scene", "parts", "reachable % over 160 placements", "verdict"])
	for nm in ["drive_in", "barn_run", "cow_field"]:
		var sc: Dictionary = {}
		match nm:
			"drive_in": sc = SetPiece.drive_in(Vector3.ZERO)
			"barn_run": sc = SetPiece.barn_run(Vector3.ZERO)
			_: sc = SetPiece.cow_field(Vector3.ZERO)
		# Flatten the scene to world-space part positions once.
		var pts: Array[Vector3] = []
		for st in sc["structures"]:
			var s := st as Structure
			for e in s.entries:
				pts.append(s.position + Basis.from_euler(s.rotation) * e["pos"])
			s.queue_free()

		# Then slide it along the corridor. Scenes land every SCENE_EVERY
		# metres from an origin that depends on where the run started, so any
		# offset is possible; 160 of them characterise the scene.
		var fracs: Array[float] = []
		for k in range(160):
			var off: float = 120.0 + float(k) * 5.0
			var hit := 0
			for wp in pts:
				var pz: float = wp.z + off
				var best := 1e9
				for i in range(zs.size()):
					var dz: float = zs[i] - pz
					if absf(dz) > REACH:
						continue
					var d: float = sqrt(dz * dz + pow(xs[i] - wp.x, 2.0))
					best = minf(best, d)
					if best <= REACH:
						break
				if best <= REACH:
					hit += 1
			fracs.append(float(hit) / maxf(float(pts.size()), 1.0))
		# The four placements a real round actually uses, before sorting
		# destroys the offset ordering. The cadence is fixed and the weave is
		# time-driven, so EVERY round meets these same four alignments - which
		# is why the spread above is not the number that decides anything.
		var real := ""
		for off_real in [335.0, 500.0, 665.0, 830.0]:
			var k2 := int((off_real - 120.0) / 5.0)
			if k2 >= 0 and k2 < fracs.size():
				real += "%5.1f" % (fracs[k2] * 100.0)
		var fixed := fracs.duplicate()
		fixed.sort()
		var lo: float = fixed[0]
		var med: float = fixed[fixed.size() / 2]
		var hi: float = fixed[fixed.size() - 1]
		print("%-10s %6d   min %4.1f med %4.1f max %4.1f  | real placements:%s"
			% [nm, pts.size(), lo * 100.0, med * 100.0, hi * 100.0, real])
	quit()
