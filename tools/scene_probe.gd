# Renders each hand-composed scene from above and from the road, so a SCENE can
# be judged as a composition rather than as a list of props.
#
# The test a scene has to pass is not "does it contain a drive-in" but "can a
# player read where to go without a marker" - which is a question about
# arrangement, and only a picture answers it.
#
# It also asserts the one thing a headless gate CANNOT see: that a scene which
# builds actually DRAWS. --selftest counts structures and parts, and every one
# of those counts stays right if the geometry ends up behind the camera, inside
# the ground, or scaled to nothing. So each scene's road view is differenced
# against an empty frame of the same ground, and a scene that changes less than
# MIN_COVER of the picture fails.
#
# THE COMPARATOR IS VALIDATED BEFORE IT IS TRUSTED. Two empty frames are taken
# several frames apart and differenced first: if the ground turns out to drift
# between frames, or the read-back returns something that is not the picture,
# that difference is not zero and the probe fails ITSELF rather than reporting
# a number nobody should believe. A brightness-thresholded mask and a PNG byte
# comparison have both lied to this project before.
extends SceneTree

const ROAD_EYE := Vector3(0, 7, -30)
const ROAD_AIM := Vector3(0, 2, 14)
# A scene has to change at least this much of the road view to count as drawn.
# MEASURED, not guessed: the three scenes cover 0.040 / 0.028 / 0.023 of the
# road frame, and a scene that fails to draw covers essentially none of it, so
# the separation is between 0.023 and 0. The first threshold here was 0.04,
# picked before measuring anything, and it failed two scenes that were drawing
# perfectly well - a threshold set above the thing it is meant to admit tests
# nothing except the author's guess.
const MIN_COVER := 0.010
# ...and the empty frame has to be this stable, or the number above is noise.
const MAX_DRIFT := 0.005
const EPS := 0.02


func _initialize() -> void:
	_run()


static func _out_dir(preferred: String) -> String:
	if DirAccess.make_dir_recursive_absolute(preferred) == OK:
		return preferred
	return "user://probe"


func _run() -> void:
	var out := _out_dir("/home/user/brickstorm_shots/scenes")
	var r := Node3D.new()
	root.add_child(r)

	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.36, 0.47, 0.60)
	sm.sky_horizon_color = Color(0.78, 0.80, 0.74)
	sm.ground_bottom_color = Color(0.42, 0.40, 0.30)
	sm.ground_horizon_color = Color(0.66, 0.62, 0.48)
	sky.sky_material = sm
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_sky_contribution = 1.0
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	e.ambient_light_energy = 0.75
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_white = 1.6
	we.environment = e
	r.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-44, 36, 0)
	sun.light_energy = 0.35
	sun.shadow_enabled = true
	r.add_child(sun)

	# The real ground shader, so a scene is judged on the land it sits on.
	var pm := PlaneMesh.new()
	pm.size = Vector2(420, 420)
	var ground := MeshInstance3D.new()
	ground.mesh = pm
	var gm := ShaderMaterial.new()
	gm.shader = load("res://shaders/ground.gdshader")
	ground.material_override = gm
	r.add_child(ground)

	var cam := Camera3D.new()
	r.add_child(cam)
	await process_frame
	cam.current = true

	# The empty frame, and the comparator's own check.
	cam.global_position = ROAD_EYE
	cam.look_at(ROAD_AIM, Vector3.UP)
	for i0 in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	var empty1 := root.get_texture().get_image()
	for i1 in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	var empty2 := root.get_texture().get_image()
	var drift := _diff(empty1, empty2)
	print("comparator  empty-vs-empty drift=%.4f (must be < %.4f)" % [drift, MAX_DRIFT])
	if drift >= MAX_DRIFT:
		print("SCENEPROBE FAILED: the empty frame is not stable, so any coverage")
		print("  number measured against it is meaningless. Fix the instrument.")
		quit(1)
		return
	empty1.save_png("%s/_empty.png" % out)
	var fails: Array[String] = []

	for name in ["drive_in", "barn_run", "cow_field"]:
		var sc: Dictionary = {}
		match name:
			"drive_in": sc = SetPiece.drive_in(Vector3.ZERO)
			"barn_run": sc = SetPiece.barn_run(Vector3.ZERO)
			_: sc = SetPiece.cow_field(Vector3.ZERO)
		var holder := Node3D.new()
		r.add_child(holder)
		for st in sc["structures"]:
			holder.add_child(st)
		# The herd matters to how a scene reads - an empty pasture is not the
		# cow field, it is a fence.
		for cp in sc.get("cows", []):
			var cow := BrickLib.cow_visual()
			holder.add_child(cow)
			cow.global_position = cp
		var parts := 0
		for st2 in sc["structures"]:
			parts += (st2 as Structure).entries.size()
		# From the road, at the entrance, which is how a player meets it; and
		# from above, which is how its composition reads.
		var cover := 0.0
		for shot in [["road", ROAD_EYE, ROAD_AIM],
					 ["above", Vector3(2, 52, -20), Vector3(0, 0, 15)]]:
			cam.global_position = shot[1]
			cam.look_at(shot[2], Vector3.UP)
			for i in range(6):
				await process_frame
			await RenderingServer.frame_post_draw
			var img := root.get_texture().get_image()
			img.save_png("%s/%s_%s.png" % [out, name, shot[0]])
			if shot[0] == "road":
				cover = _diff(empty1, img)
		print("scene %-10s structures=%d parts=%d cows=%d cover=%.3f"
			% [name, sc["structures"].size(), parts, sc.get("cows", []).size(), cover])
		if cover < MIN_COVER:
			fails.append("%s changes only %.3f of the road view - it builds but"
				% [name, cover] + " it does not draw")
		r.remove_child(holder)
		holder.queue_free()
	print("SCENEPROBE done -> %s" % out)
	if not fails.is_empty():
		for f in fails:
			print("  FAIL  %s" % f)
		print("SCENEPROBE FAILED (%d)" % fails.size())
		quit(1)
		return
	print("SCENEPROBE OK")
	quit()


# Fraction of sampled pixels that differ. Sampled every other pixel in each
# axis - a quarter of a million samples is plenty to see a barn, and reading
# a million pixels one at a time from GDScript is not.
static func _diff(a: Image, b: Image) -> float:
	if a.get_width() != b.get_width() or a.get_height() != b.get_height():
		return 1.0
	var n := 0
	var d := 0
	var y := 0
	while y < a.get_height():
		var x := 0
		while x < a.get_width():
			var pa := a.get_pixel(x, y)
			var pb := b.get_pixel(x, y)
			n += 1
			if absf(pa.r - pb.r) > EPS or absf(pa.g - pb.g) > EPS or absf(pa.b - pb.b) > EPS:
				d += 1
			x += 2
		y += 2
	return float(d) / maxf(float(n), 1.0)
