# Renders the town props close up, one per frame, so they can be judged as
# models rather than squinted at across a gameplay screenshot.
#
# The director's note on the last build was "it feels like ROBLOX mini... just
# a game with mega blocks in it", and the answer to that is not visible from
# the chase camera. It is visible here: a roof made of slope courses, a round
# trunk, a cone on the silo, tiles where a surface should be smooth.
extends SceneTree

const OUT := "/home/user/brickstorm_shots/props"


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
	sm.sky_top_color = Color(0.36, 0.47, 0.60)
	sm.sky_horizon_color = Color(0.78, 0.80, 0.74)
	sm.ground_bottom_color = Color(0.30, 0.40, 0.24)
	sm.ground_horizon_color = Color(0.62, 0.66, 0.50)
	sky.sky_material = sm
	e.sky = sky
	# Matched to the game's own environment, so what this shows is what the
	# game draws. See BS:RENDER:LOOK in main.gd.
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
	sun.light_color = Color(1.0, 0.97, 0.90)
	sun.shadow_enabled = true
	r.add_child(sun)

	var ground := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	pl.size = Vector2(120, 120)
	ground.mesh = pl
	ground.material_override = BrickLib.terrain_mat(Color(0.36, 0.52, 0.26))
	r.add_child(ground)

	var cam := Camera3D.new()
	r.add_child(cam)
	await process_frame
	cam.current = true
	# An orthographic elevation settles roof questions that a 3/4 view cannot:
	# whether the face is a continuous pitch or a staircase is a silhouette
	# question, and perspective plus a 45-degree angle hides it either way.
	await _elevation(r, cam, "barn_elevation", PropBuilder.barn(Vector3.ZERO), 14.0, 3.0)
	await _elevation(r, cam, "farmhouse_elevation", PropBuilder.farmhouse(Vector3.ZERO), 12.0, 2.6)

	# name, structure, camera distance, camera height, aim height, [x sign, z sign]
	var shots := [
		["barn", PropBuilder.barn(Vector3.ZERO), 20.0, 7.0, 3.0],
		["barn_front", PropBuilder.barn(Vector3.ZERO), 17.0, 5.0, 2.6, 0.6, -1.0],
		["barn_roof", PropBuilder.barn(Vector3.ZERO), 11.0, 11.0, 4.4, 0.7, 0.7],
		["farmhouse_front", PropBuilder.farmhouse(Vector3.ZERO), 15.0, 5.0, 2.4, 0.5, -1.0],
		["farmhouse", PropBuilder.farmhouse(Vector3.ZERO), 17.0, 6.0, 2.6],
		["silo", PropBuilder.silo(Vector3.ZERO), 12.0, 4.5, 2.4],
		["water_tower", PropBuilder.water_tower(Vector3.ZERO), 16.0, 6.0, 3.4],
		["tree", PropBuilder.tree(Vector3.ZERO, 1.0), 8.0, 3.0, 1.8],
		["pickup", PropBuilder.pickup(Vector3.ZERO, BrickLib.C_BLUE, 0.6), 7.5, 2.6, 1.0],
		["windmill", PropBuilder.windmill(Vector3.ZERO), 14.0, 5.0, 3.0],
		["outhouse", PropBuilder.outhouse(Vector3.ZERO), 8.0, 3.2, 1.6],
		["fence", PropBuilder.fence_run(Vector3(-4, 0, 0), Vector3(4, 0, 0)), 9.0, 2.4, 0.9],
		["drive_in", PropBuilder.drive_in_screen(Vector3.ZERO, 0.0), 20.0, 7.0, 3.0],
		["crate", PropBuilder.crate(Vector3.ZERO, 0.0, true), 4.0, 1.8, 0.8],
		["hay_bale", PropBuilder.hay_bale(Vector3.ZERO, 0.0), 4.0, 1.6, 0.7],
		["tyre_stack", PropBuilder.tyre_stack(Vector3.ZERO), 3.4, 1.4, 0.5],
		["mailbox", PropBuilder.mailbox(Vector3.ZERO, 0.0), 3.6, 1.6, 0.9],
		["barrel", PropBuilder.barrel(Vector3.ZERO), 3.6, 1.5, 0.9],
		["power_line", PropBuilder.power_line(Vector3(-21, 0, 0), Vector3(21, 0, 0)), 34.0, 11.0, 4.0],
		["grain_elevator", PropBuilder.grain_elevator(Vector3.ZERO, 0.0), 30.0, 11.0, 6.0],
		["aermotor", PropBuilder.windmill(Vector3.ZERO), 15.0, 5.0, 4.0],
	]
	for shot in shots:
		var st: Structure = shot[1]
		r.add_child(st)
		var dist: float = shot[2]
		var hgt: float = shot[3]
		var aim: float = shot[4]
		var sx: float = shot[5] if shot.size() > 5 else 0.72
		var sz: float = shot[6] if shot.size() > 6 else 0.72
		cam.global_position = Vector3(dist * sx, hgt, dist * sz)
		cam.look_at(Vector3(0, aim, 0), Vector3.UP)
		for i in range(6):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/%s.png" % [OUT, shot[0]])
		print("prop %-12s parts=%d" % [shot[0], st.entries.size()])
		r.remove_child(st)
		st.queue_free()
	print("PROPPROBE done -> %s" % OUT)
	quit()


func _elevation(r: Node3D, cam: Camera3D, name: String, st: Structure,
		size: float, aim: float) -> void:
	r.add_child(st)
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = size
	cam.global_position = Vector3(0, aim, 40)
	cam.look_at(Vector3(0, aim, 0), Vector3.UP)
	for i in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [OUT, name])
	print("prop %-12s parts=%d (elevation)" % [name, st.entries.size()])
	r.remove_child(st)
	st.queue_free()
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
