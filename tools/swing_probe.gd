# The smash swing, as a strip of frames.
#
# A smash that moves bricks but not the character reads as the button being
# dropped - that was the report from a phone, and nothing headless could see
# it: the tear happens, the score goes up, the gate passes. Only a picture of
# the arms across the motion shows whether there IS a motion.
extends SceneTree

const OUT := "/home/user/brickstorm_shots/swing"


func _initialize() -> void:
	_run()


func _run() -> void:
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

	# The rig straight out of BrickLib, posed by hand through the same maths
	# the player uses, so this shows the shipped curve and not a mock-up.
	var fig := BrickLib.minifig(BrickLib.C_BLUE, BrickLib.C_DGREY, BrickLib.C_BROWN)
	r.add_child(fig)
	var sl: Node3D = fig.find_child("ShoulderL", true, false)
	var sr: Node3D = fig.find_child("ShoulderR", true, false)
	var upper: Node3D = fig.find_child("Upper", true, false)
	if sl == null or sr == null:
		print("SWINGPROBE FAILED: no shoulders on the rig")
		quit(1)
		return

	var cam := Camera3D.new()
	r.add_child(cam)
	await process_frame
	cam.current = true
	cam.global_position = Vector3(2.4, 1.35, -1.7)
	cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)

	var lo := 9.0
	var hi := -9.0
	for i in range(6):
		# Player's own curve, not a copy of it.
		var t: float = float(i) / 5.0
		var ang: float = Player.swing_angle(t)
		sl.rotation.x = ang
		sr.rotation.x = ang
		if upper != null:
			upper.rotation.x = Player.swing_pitch(t)
		lo = minf(lo, ang)
		hi = maxf(hi, ang)
		for f in range(3):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/swing_%d.png" % [OUT, i])
	var sweep: float = hi - lo
	print("SWINGPROBE sweep=%.2f rad (%.0f degrees) -> %s"
		% [sweep, rad_to_deg(sweep), OUT])
	if sweep < 1.5:
		print("SWINGPROBE FAILED: the arms barely move")
		quit(1)
		return
	print("SWINGPROBE OK")
	quit()
