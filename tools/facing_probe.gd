extends SceneTree
func _initialize() -> void:
	_run()
func _run() -> void:
	var r := Node3D.new()
	root.add_child(r)
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.16, 0.18, 0.20)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.82, 0.86)
	e.ambient_light_energy = 1.2
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_white = 1.6
	we.environment = e
	r.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30, 20, 0)
	sun.light_energy = 0.5
	r.add_child(sun)
	var fig := BrickLib.minifig(BrickLib.C_BLUE, BrickLib.C_DGREY, BrickLib.C_BROWN)
	r.add_child(fig)
	var cam := Camera3D.new()
	r.add_child(cam)
	await process_frame
	cam.current = true
	DirAccess.make_dir_recursive_absolute("/home/user/brickstorm_shots/facing")
	for shot in [["cam_at_minus_Z", Vector3(0, 1.20, -2.2)],
				 ["cam_at_plus_Z", Vector3(0, 1.20, 2.2)]]:
		cam.global_position = shot[1]
		cam.look_at(Vector3(0, 1.16, 0), Vector3.UP)
		for i in range(5):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(
			"/home/user/brickstorm_shots/facing/%s.png" % shot[0])
	print("FACING done")
	quit()
