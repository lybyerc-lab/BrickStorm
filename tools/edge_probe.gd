# Does the ground run out?
#
# _build_ground makes ONE 420m PlaneMesh at the origin and never moves it, so
# it spans z = -210..210, while a 200-second round carries the storm past
# z = 600. The comment above it says the ground is "world-locked and therefore
# has no edge to run off", which is true of the SHADER and not of the mesh it
# is painted on. This looks.
extends SceneTree

const OUT := "/home/user/brickstorm_shots/edge"


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
	sm.ground_bottom_color = Color(0.42, 0.40, 0.30)
	sm.ground_horizon_color = Color(0.66, 0.62, 0.48)
	sky.sky_material = sm
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_sky_contribution = 1.0
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_white = 1.6
	we.environment = e
	r.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-44, 36, 0)
	sun.light_energy = 0.4
	r.add_child(sun)

	# The ground exactly as main.gd builds it.
	var pm := PlaneMesh.new()
	pm.size = Vector2(420, 420)
	pm.subdivide_width = 128
	pm.subdivide_depth = 128
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	var gm := ShaderMaterial.new()
	gm.shader = load("res://shaders/ground.gdshader")
	mi.material_override = gm
	r.add_child(mi)

	var cam := Camera3D.new()
	r.add_child(cam)
	await process_frame
	cam.current = true
	for z in [0, 150, 260, 420]:
		cam.global_position = Vector3(0, 9, float(z) - 40.0)
		cam.look_at(Vector3(0, 1.5, float(z) + 60.0), Vector3.UP)
		for i in range(5):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/at_z%d.png" % [OUT, z])
		print("shot from z=%d" % (z - 40))
	print("EDGEPROBE done -> %s" % OUT)
	quit()
