# Proves studs are not swallowed by the shadow of the brick they sit on.
#
# A stud stands 6cm proud of a large flat caster, so the shadow map's depth at
# its texel IS the brick top and the stud's own top is classified as shadowed.
# Every stud in the game rendered as a dark disc lit only by ambient. It looked
# like a material bug, then like specular aliasing, then like the sky ambient -
# three wrong theories - because up close it was invisible and only appeared at
# gameplay distance with shadows on. This renders exactly that case.
extends SceneTree

const OUT := "/home/user/brickstorm_shots/wind"


func _initialize() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var r := Node3D.new()
	root.add_child(r)

	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.13, 0.17, 0.16)
	sm.sky_horizon_color = Color(0.72, 0.66, 0.36)
	sm.ground_bottom_color = Color(0.30, 0.34, 0.24)
	sm.ground_horizon_color = Color(0.62, 0.58, 0.38)
	sky.sky_material = sm
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_sky_contribution = 1.0
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	e.ambient_light_energy = 2.6
	we.environment = e
	r.add_child(we)

	# Shadows ON. That is the whole point of the test.
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-46, 38, 0)
	sun.light_energy = 1.45
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.shadow_enabled = true
	r.add_child(sun)

	var st := Structure.new()
	for x in range(4):
		for z in range(3):
			st.add_brick(2, 2, BrickLib.BRICK_H, BrickLib.C_WHITE,
				Vector3(float(x), 0.3, float(z)))
	st.finish()
	r.add_child(st)

	var cam := Camera3D.new()
	r.add_child(cam)
	await process_frame
	cam.global_position = Vector3(1.5, 6.0, 9.0)
	cam.look_at(Vector3(1.5, 0.4, 1.0), Vector3.UP)
	cam.current = true
	for i in range(14):
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png("%s/studs.png" % OUT)

	# Work inside the brick only. The background is green (g > r); the brick is
	# white, so anything neutral-or-warm inside its silhouette is brick, lit or
	# not. A shadowed stud shows up as a large dark population on a plate that
	# should be almost entirely bright.
	# Find the brick first - it is the only near-white thing in frame - then
	# judge only inside its own bounding box. Counting the whole frame lets the
	# bright horizon band swamp the measurement, which is a mistake this probe
	# made on its first run and which made it report the same number whether
	# the bug was present or not.
	var x0 := img.get_width()
	var y0 := img.get_height()
	var x1 := 0
	var y1 := 0
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			if c.r + c.g + c.b > 2.1 and c.b > 0.55:
				x0 = mini(x0, x); y0 = mini(y0, y)
				x1 = maxi(x1, x); y1 = maxi(y1, y)
	if x1 <= x0 or y1 <= y0:
		print("STUDPROBE FAIL: no brick in frame")
		quit()
		return
	var lit := 0
	var dim := 0
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var c := img.get_pixel(x, y)
			if c.g > c.r + 0.02:
				continue                       # background showing through
			var l := c.r + c.g + c.b
			if l > 2.1:
				lit += 1
			elif l > 0.35:
				dim += 1
	var ratio := 100.0 * float(dim) / maxf(float(lit + dim), 1.0)
	print("STUDPROBE lit=%d dim=%d shadowed=%.1f%%" % [lit, dim, ratio])
	if ratio > 12.0:
		print("STUDPROBE FAIL: %.1f%% of the brick is in shadow - the studs are"
			% ratio + " being shadowed by the brick they stand on")
	else:
		print("STUDPROBE OK")
	quit()
