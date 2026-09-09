# Proves the foliage actually moves and the buildings actually do not.
#
# A screenshot cannot show motion, and the gameplay capture cannot isolate it -
# the storm, the debris and the player are all moving too. So: a locked camera,
# one tree and one barn side by side, no storm, two frames half a second apart.
# The tree's pixels must change. The barn's must not.
extends SceneTree

const OUT := "/home/user/brickstorm_shots/wind"


func _initialize() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var root3d := Node3D.new()
	root.add_child(root3d)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.15, 0.16, 0.18)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.62, 0.6)
	e.ambient_light_energy = 1.0
	env.environment = e
	root3d.add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	root3d.add_child(sun)

	# Tree on the left, barn on the right, both at the origin plane.
	var tree := PropBuilder.tree(Vector3(-6, 0, 0), 1.4)
	var barn := PropBuilder.barn(Vector3(7, 0, 0))
	root3d.add_child(tree)
	root3d.add_child(barn)

	# No storm anywhere near: what moves here is the ambient breeze alone.
	Structure.set_storm(Vector3(0, 0, 9999.0), 1.0)

	var cam := Camera3D.new()
	root3d.add_child(cam)
	await process_frame                 # must be in the tree before look_at
	cam.global_position = Vector3(0, 5.0, 16.0)
	cam.look_at(Vector3(0, 2.5, 0), Vector3.UP)
	cam.current = true

	var calm: Array = []
	for k in range(6):
		calm.append(await _grab("wind_calm_%d" % k))
		for i in range(10):
			await process_frame

	var w := (calm[0] as Image).get_width()
	var h := (calm[0] as Image).get_height()
	var tree_diff := _sweep(calm, 0, int(w * 0.45), 0, h)
	var barn_diff := _sweep(calm, int(w * 0.55), w, 0, h)
	# Second phase: put the storm right next to the tree. The storm has to move
	# foliage harder than a calm-day breeze does, or the wind field is not
	# actually reading the storm at all.
	Structure.set_storm(Vector3(-6, 0, 8.0), 60.0)
	await process_frame
	var blown: Array = []
	for k in range(6):
		blown.append(await _grab("wind_storm_%d" % k))
		for i in range(10):
			await process_frame
	var storm_diff := _sweep(blown, 0, int(w * 0.45), 0, h)

	print("WINDPROBE swept: breeze_tree=%.1f%% storm_tree=%.1f%% barn=%.1f%%"
		% [tree_diff, storm_diff, barn_diff])
	var fails: Array[String] = []
	if tree_diff < 2.0:
		fails.append("foliage did not move in the breeze")
	if barn_diff > 0.5:
		fails.append("the barn moved (%.3f%%)" % barn_diff)
	if storm_diff <= tree_diff * 2.0:
		fails.append("the storm moves foliage only %.1fx a calm day - not enough to read"
			% (storm_diff / maxf(tree_diff, 0.001)))
	if fails.is_empty():
		print("WINDPROBE OK")
	else:
		for f in fails:
			print("WINDPROBE FAIL: " + f)
	quit()


func _grab(name: String) -> Image:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png("%s/%s.png" % [OUT, name])
	return img


# How far the thing SWEPT, not how many edge pixels flickered. A frame-to-frame
# difference saturates the moment motion exceeds a pixel or two, which made a
# violent storm measure only 1.9x a calm breeze. This takes the union of the
# silhouette across frames minus its intersection, as a fraction of the mean
# silhouette - it keeps growing with amplitude.
const BG := Color(0.15, 0.16, 0.18)


func _is_solid(c: Color) -> bool:
	return absf(c.r - BG.r) + absf(c.g - BG.g) + absf(c.b - BG.b) > 0.03


func _sweep(frames: Array, x0: int, x1: int, y0: int, y1: int) -> float:
	var union := 0
	var inter := 0
	var total := 0
	for y in range(y0, y1, 2):
		for x in range(x0, x1, 2):
			var any := false
			var all := true
			for f in frames:
				if _is_solid((f as Image).get_pixel(x, y)):
					any = true
					total += 1
				else:
					all = false
			if any:
				union += 1
			if all:
				inter += 1
	var mean_area := float(total) / maxf(float(frames.size()), 1.0)
	if mean_area < 1.0:
		return 0.0
	return 100.0 * float(union - inter) / mean_area
