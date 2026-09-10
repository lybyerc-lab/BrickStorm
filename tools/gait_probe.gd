# Renders the walk cycle as a strip, one column per phase, so a GAIT can be
# looked at instead of guessed at.
#
# A still screenshot cannot show a walk. The thing being judged here is whether
# Jo reads as leading from the HIPS and Bill from the SHOULDERS - which is a
# claim about how the pose changes across the cycle, not about any one pose.
# It drives the real Player._animate_walk rather than reimplementing it, so
# what this shows is what the game does.
extends SceneTree

const PHASES := 6


func _initialize() -> void:
	_run()


static func _out_dir(preferred: String) -> String:
	if DirAccess.make_dir_recursive_absolute(preferred) == OK:
		return preferred
	return "user://probe"


func _run() -> void:
	var out := _out_dir("/home/user/brickstorm_shots/props")
	var r := Node3D.new()
	root.add_child(r)

	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.30, 0.33, 0.37)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.80, 0.83, 0.88)
	e.ambient_light_energy = 1.15
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_white = 1.6
	we.environment = e
	r.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, 28, 0)
	sun.light_energy = 0.45
	r.add_child(sun)

	var cam := Camera3D.new()
	r.add_child(cam)
	await process_frame
	cam.current = true

	for who in [Player.Character.JO, Player.Character.BILL]:
		for view in ["front", "side"]:
			var pl := Player.new()
			r.add_child(pl)
			await process_frame
			pl.character = who
			pl._apply_character()
			# Walking flat out, so the gait is at full amplitude.
			var spd: float = pl.speed()
			for i in range(PHASES):
				pl._walk_phase = TAU * float(i) / float(PHASES)
				# delta 0 so the phase set above is the phase drawn.
				pl._animate_walk(0.0, spd)
				var aim := pl.global_position + Vector3(0, 1.35, 0)
				if view == "front":
					cam.global_position = aim + Vector3(1.1, 0.25, 3.4)
				else:
					cam.global_position = aim + Vector3(4.0, 0.2, 0.2)
				cam.look_at(aim, Vector3.UP)
				for f in range(3):
					await process_frame
				await RenderingServer.frame_post_draw
				var img := root.get_texture().get_image()
				img.save_png("%s/gait_%s_%s_%d.png"
					% [out, "jo" if who == Player.Character.JO else "bill", view, i])
			r.remove_child(pl)
			pl.queue_free()
	print("GAITPROBE wrote %d frames to %s" % [2 * 2 * PHASES, out])
	quit()
