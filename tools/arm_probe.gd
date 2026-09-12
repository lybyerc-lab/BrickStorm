extends SceneTree

# Where to write. Set FIGPROBE_OUT in the environment to keep a "before" set.
var OUT: String = "/home/user/brickstorm_shots/props"
func _initialize() -> void:
	_run()
func _run() -> void:
	var env := OS.get_environment("FIGPROBE_OUT")
	if env != "":
		OUT = env
	DirAccess.make_dir_recursive_absolute(OUT)
	var r := Node3D.new()
	root.add_child(r)
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.16, 0.18, 0.20)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.78, 0.82)
	e.ambient_light_energy = 1.1
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_white = 1.6
	we.environment = e
	r.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30, 20, 0)
	sun.light_energy = 0.5
	r.add_child(sun)
	# The raw rig, straight out of BrickLib, with no animation touching it.
	var fig := BrickLib.minifig(BrickLib.C_BLUE, BrickLib.C_DGREY, BrickLib.C_BROWN)
	r.add_child(fig)
	var cam := Camera3D.new()
	r.add_child(cam)
	await process_frame
	cam.current = true
	for shot in [["front", Vector3(0, 1.25, -3.0)], ["threequarter", Vector3(1.9, 1.5, -2.3)],
			["side", Vector3(3.0, 1.25, 0.0)], ["back", Vector3(0, 1.25, 3.0)],
			["head", Vector3(0.9, 1.62, -1.1)], ["feet", Vector3(1.2, 0.55, -1.4)]]:
		cam.global_position = shot[1]
		var aim := Vector3(0, 1.15, 0)
		if shot[0] == "head":
			aim = Vector3(0, 1.52, 0)
		elif shot[0] == "feet":
			aim = Vector3(0, 0.18, 0)
		cam.look_at(aim, Vector3.UP)
		for i in range(4):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(
			"%s/rest_%s.png" % [OUT, shot[0]])
	print("ARMPROBE done")
	quit()
