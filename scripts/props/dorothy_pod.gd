extends CharacterBody3D
class_name DorothyPod

signal dorothy_deployed()

var is_deployed: bool = false
var hatch: Node3D
var drum: MeshInstance3D
var prompt_label: Label3D

var push_vector: Vector3 = Vector3.ZERO

func _ready() -> void:
	add_to_group("dorothy")
	_build_dorothy_mesh()
	_create_prompt()

func _build_dorothy_mesh() -> void:
	# Main chassis
	var chassis = MeshInstance3D.new()
	var c_box = BoxMesh.new()
	c_box.size = Vector3(1.2, 0.25, 1.4)
	var mat_yellow = StandardMaterial3D.new()
	mat_yellow.albedo_color = Color(0.95, 0.75, 0.1)
	mat_yellow.roughness = 0.3
	chassis.mesh = c_box
	chassis.material_override = mat_yellow
	chassis.position = Vector3(0, 0.2, 0)
	add_child(chassis)
	
	# Wheels (4 small tires)
	var mat_tire = StandardMaterial3D.new()
	mat_tire.albedo_color = Color(0.1, 0.1, 0.1)
	for wx in [-0.65, 0.65]:
		for wz in [-0.5, 0.5]:
			var tire = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.2
			cyl.bottom_radius = 0.2
			cyl.height = 0.15
			tire.mesh = cyl
			tire.material_override = mat_tire
			tire.rotation.z = PI / 2.0
			tire.position = Vector3(wx, 0.2, wz)
			add_child(tire)
			
	# Dorothy Silver Drum
	drum = MeshInstance3D.new()
	var d_cyl = CylinderMesh.new()
	d_cyl.top_radius = 0.5
	d_cyl.bottom_radius = 0.5
	d_cyl.height = 0.8
	var mat_silver = StandardMaterial3D.new()
	mat_silver.albedo_color = Color(0.85, 0.88, 0.92)
	mat_silver.metallic = 0.9
	mat_silver.roughness = 0.2
	drum.mesh = d_cyl
	drum.material_override = mat_silver
	drum.position = Vector3(0, 0.72, 0)
	add_child(drum)
	
	# Hatch lid
	hatch = Node3D.new()
	hatch.position = Vector3(0, 1.15, 0)
	add_child(hatch)
	var lid = MeshInstance3D.new()
	var l_cyl = CylinderMesh.new()
	l_cyl.top_radius = 0.52
	l_cyl.bottom_radius = 0.52
	l_cyl.height = 0.08
	var mat_orange = StandardMaterial3D.new()
	mat_orange.albedo_color = Color(0.95, 0.45, 0.1)
	lid.mesh = l_cyl
	lid.material_override = mat_orange
	hatch.add_child(lid)
	
	# Antenna
	var ant = MeshInstance3D.new()
	var a_cyl = CylinderMesh.new()
	a_cyl.top_radius = 0.03
	a_cyl.bottom_radius = 0.03
	a_cyl.height = 0.6
	ant.mesh = a_cyl
	ant.material_override = mat_silver
	ant.position = Vector3(0.3, 0.3, 0)
	hatch.add_child(ant)

func _create_prompt() -> void:
	prompt_label = Label3D.new()
	prompt_label.text = "[PUSH DOROTHY TO THE STORM]"
	prompt_label.font_size = 32
	prompt_label.outline_size = 8
	prompt_label.modulate = Color(1.0, 0.85, 0.2)
	prompt_label.position = Vector3(0, 1.9, 0)
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(prompt_label)

func _physics_process(delta: float) -> void:
	if is_deployed:
		return
		
	# Check distance to player for pushing
	var player = get_tree().root.find_child("MinifigCharacter", true, false) as MinifigCharacter
	if is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < 2.0:
			var push_dir = (global_position - player.global_position).normalized()
			push_dir.y = 0.0
			velocity.x = push_dir.x * 5.0
			velocity.z = push_dir.z * 5.0
		else:
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
			
	# Check distance to tornado
	var tornado = get_tree().root.find_child("Tornado", true, false)
	if is_instance_valid(tornado):
		var storm_dist = global_position.distance_to(tornado.global_position)
		if storm_dist <= 18.0:
			prompt_label.text = "[PRESS E / SMASH TO DEPLOY!]"
			prompt_label.modulate = Color(0.2, 1.0, 0.4)
			if Input.is_action_just_pressed("build") or Input.is_action_just_pressed("smash"):
				deploy()
		else:
			prompt_label.text = "[PUSH DOROTHY TO STORM (%.0fm)]" % storm_dist
			prompt_label.modulate = Color(1.0, 0.85, 0.2)
			
	move_and_slide()

func deploy() -> void:
	if is_deployed:
		return
	is_deployed = true
	prompt_label.text = "★ DOROTHY DEPLOYED! SENSORS FLYING! ★"
	prompt_label.modulate = Color(1.0, 0.9, 0.1)
	
	# Pop hatch lid
	var tween = create_tween()
	tween.tween_property(hatch, "position", hatch.position + Vector3(0, 5.0, -3.0), 0.6)
	tween.parallel().tween_property(hatch, "rotation", Vector3(5.0, 3.0, 0), 0.6)
	
	# Fountain of sensor balls
	_spawn_sensor_swarm()
	
	dorothy_deployed.emit()
	
	var synth = SoundSynthesizer.get_instance()
	if is_instance_valid(synth):
		synth.play_true_chaser_fanfare()

func _spawn_sensor_swarm() -> void:
	var tornado = get_tree().root.find_child("Tornado", true, false)
	for i in range(40):
		var sphere = MeshInstance3D.new()
		var s_mesh = SphereMesh.new()
		s_mesh.radius = 0.12
		s_mesh.height = 0.24
		sphere.mesh = s_mesh
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.95, 0.4)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.8, 0.2)
		mat.emission_energy_multiplier = 2.0
		sphere.material_override = mat
		
		get_parent().add_child(sphere)
		sphere.global_position = global_position + Vector3(0, 1.0, 0)
		
		# Animate sensor ball flying up into vortex
		var t = create_tween()
		var delay = randf_range(0.0, 0.8)
		var target_offset = Vector3(randf_range(-6.0, 6.0), randf_range(8.0, 25.0), randf_range(-6.0, 6.0))
		var target_pos = (tornado.global_position if is_instance_valid(tornado) else global_position) + target_offset
		
		t.tween_interval(delay)
		t.tween_property(sphere, "global_position", target_pos, randf_range(1.2, 2.0)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
