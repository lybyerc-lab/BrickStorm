extends Node3D
class_name DestructibleObject

signal destroyed()

@export var is_barn: bool = false
@export var is_fence: bool = false
@export var is_pole: bool = false
@export var is_hay_bale: bool = false
@export var drops_build_pile: bool = false
@export var build_pile_target: PackedScene = null

var is_smashed: bool = false

func _ready() -> void:
	add_to_group("destructible")
	_build_visuals()

func _build_visuals() -> void:
	if is_barn:
		_build_barn()
	elif is_fence:
		_build_fence()
	elif is_pole:
		_build_pole()
	elif is_hay_bale:
		_build_hay_bale()
	else:
		_build_generic_crate()

func _build_barn() -> void:
	# Classic Red LEGO Barn with White Trim and Sloped Roof
	var mat_red = StandardMaterial3D.new()
	mat_red.albedo_color = Color(0.8, 0.12, 0.12)
	mat_red.roughness = 0.28
	
	var mat_white = StandardMaterial3D.new()
	mat_white.albedo_color = Color(0.95, 0.95, 0.95)
	mat_white.roughness = 0.28
	
	var mat_dark_roof = StandardMaterial3D.new()
	mat_dark_roof.albedo_color = Color(0.2, 0.2, 0.22)
	mat_dark_roof.roughness = 0.25

	# Main Barn Body
	var body = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(6.0, 4.0, 8.0)
	body.mesh = b_box
	body.material_override = mat_red
	body.position = Vector3(0, 2.0, 0)
	add_child(body)

	# Barn Roof
	var roof = MeshInstance3D.new()
	var r_prism = PrismMesh.new()
	r_prism.size = Vector3(6.4, 2.4, 8.2)
	roof.mesh = r_prism
	roof.material_override = mat_dark_roof
	roof.position = Vector3(0, 5.2, 0)
	add_child(roof)

	# White Barn Door Cross-Brace
	var door = MeshInstance3D.new()
	var d_box = BoxMesh.new()
	d_box.size = Vector3(2.2, 2.6, 0.1)
	door.mesh = d_box
	door.material_override = mat_white
	door.position = Vector3(0, 1.3, 4.05)
	add_child(door)

	# Silo cylinder next to barn
	var silo = MeshInstance3D.new()
	var s_cyl = CylinderMesh.new()
	s_cyl.top_radius = 1.4
	s_cyl.bottom_radius = 1.4
	s_cyl.height = 7.0
	var mat_silo = StandardMaterial3D.new()
	mat_silo.albedo_color = Color(0.85, 0.88, 0.9)
	mat_silo.metallic = 0.8
	silo.mesh = s_cyl
	silo.material_override = mat_silo
	silo.position = Vector3(4.5, 3.5, 0)
	add_child(silo)

func _build_fence() -> void:
	# Wooden rail fence
	var mat_wood = StandardMaterial3D.new()
	mat_wood.albedo_color = Color(0.85, 0.85, 0.82) # White farm fence
	mat_wood.roughness = 0.35
	
	# Two vertical posts
	for px in [-1.4, 1.4]:
		var post = MeshInstance3D.new()
		var p_box = BoxMesh.new()
		p_box.size = Vector3(0.2, 1.1, 0.2)
		post.mesh = p_box
		post.material_override = mat_wood
		post.position = Vector3(px, 0.55, 0)
		add_child(post)
		
	# Two horizontal rails
	for ry in [0.4, 0.85]:
		var rail = MeshInstance3D.new()
		var r_box = BoxMesh.new()
		r_box.size = Vector3(3.0, 0.14, 0.08)
		rail.mesh = r_box
		rail.material_override = mat_wood
		rail.position = Vector3(0, ry, 0)
		add_child(rail)

func _build_pole() -> void:
	# Oklahoma Telephone/Utility Pole with crossarm
	var mat_pole = StandardMaterial3D.new()
	mat_pole.albedo_color = Color(0.42, 0.3, 0.18)
	mat_pole.roughness = 0.5
	
	var pole = MeshInstance3D.new()
	var p_cyl = CylinderMesh.new()
	p_cyl.top_radius = 0.16
	p_cyl.bottom_radius = 0.2
	p_cyl.height = 6.5
	pole.mesh = p_cyl
	pole.material_override = mat_pole
	pole.position = Vector3(0, 3.25, 0)
	add_child(pole)
	
	# Crossarm
	var arm = MeshInstance3D.new()
	var a_box = BoxMesh.new()
	a_box.size = Vector3(2.4, 0.2, 0.2)
	arm.mesh = a_box
	arm.material_override = mat_pole
	arm.position = Vector3(0, 5.8, 0)
	add_child(arm)
	
	# Insulators
	var mat_ins = StandardMaterial3D.new()
	mat_ins.albedo_color = Color(0.2, 0.6, 0.4) # Green glass insulators
	for ix in [-0.9, 0.0, 0.9]:
		var ins = MeshInstance3D.new()
		var i_cyl = CylinderMesh.new()
		i_cyl.top_radius = 0.06
		i_cyl.bottom_radius = 0.08
		i_cyl.height = 0.18
		ins.mesh = i_cyl
		ins.material_override = mat_ins
		ins.position = Vector3(ix, 6.0, 0)
		add_child(ins)

func _build_hay_bale() -> void:
	var mat_hay = StandardMaterial3D.new()
	mat_hay.albedo_color = Color(0.85, 0.72, 0.25)
	mat_hay.roughness = 0.6
	
	var bale = MeshInstance3D.new()
	var b_cyl = CylinderMesh.new()
	b_cyl.top_radius = 0.7
	b_cyl.bottom_radius = 0.7
	b_cyl.height = 1.2
	bale.mesh = b_cyl
	bale.material_override = mat_hay
	bale.rotation.z = PI / 2.0
	bale.position = Vector3(0, 0.7, 0)
	add_child(bale)

func _build_generic_crate() -> void:
	var mat_crate = StandardMaterial3D.new()
	mat_crate.albedo_color = Color(0.9, 0.6, 0.1)
	
	var crate = MeshInstance3D.new()
	var c_box = BoxMesh.new()
	c_box.size = Vector3(1.2, 1.2, 1.2)
	crate.mesh = c_box
	crate.material_override = mat_crate
	crate.position = Vector3(0, 0.6, 0)
	add_child(crate)

func smash(impact_dir: Vector3 = Vector3.UP, force: float = 8.0) -> void:
	if is_smashed:
		return
	is_smashed = true
	
	# Sound effect
	var synth = SoundSynthesizer.get_instance()
	if is_instance_valid(synth):
		synth.play_brick_smash()
		
	# Spawn tumbling rigid body brick fragments
	_spawn_brick_debris(impact_dir, force)
	
	# Spawn studs
	var economy = get_tree().root.find_child("StudField", true, false) as StudField
	if is_instance_valid(economy):
		var silver = 4
		var gold = 1
		var blue = 0
		if is_barn:
			silver = 12
			gold = 4
			blue = 1
		elif is_hay_bale or is_pole:
			silver = 6
			gold = 2
		economy.spawn_stud_burst(global_position, silver, gold, blue)
		
	# If this drops a build pile (e.g. Dorothy's secret pack!), spawn it!
	if drops_build_pile:
		_spawn_build_pile()
		
	destroyed.emit()
	queue_free()

func _spawn_brick_debris(impact_dir: Vector3, force: float) -> void:
	var count = 10 if is_barn else (4 if is_fence else 6)
	var colors = [Color(0.85, 0.15, 0.15), Color(0.95, 0.8, 0.1), Color(0.9, 0.9, 0.9), Color(0.2, 0.5, 0.85)]
	
	for i in range(count):
		var rb = RigidBody3D.new()
		var mesh_inst = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(randf_range(0.3, 0.6), randf_range(0.2, 0.4), randf_range(0.3, 0.5))
		mesh_inst.mesh = box
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = colors[i % colors.size()]
		mat.roughness = 0.25
		mesh_inst.material_override = mat
		rb.add_child(mesh_inst)
		
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = box.size
		col.shape = shape
		rb.add_child(col)
		
		get_parent().add_child(rb)
		rb.global_position = global_position + Vector3(randf_range(-1.0, 1.0), randf_range(0.5, 2.0), randf_range(-1.0, 1.0))
		
		var impulse = (impact_dir.normalized() + Vector3(randf_range(-0.5, 0.5), randf_range(0.4, 1.0), randf_range(-0.5, 0.5))).normalized() * randf_range(force * 0.5, force * 1.2)
		rb.apply_central_impulse(impulse)
		rb.apply_torque_impulse(Vector3(randf_range(-5, 5), randf_range(-5, 5), randf_range(-5, 5)))
		
		# Auto despawn debris after 4 seconds
		rb.get_tree().create_timer(4.0).timeout.connect(rb.queue_free)

func _spawn_build_pile() -> void:
	var pile = BuildPile.new()
	if build_pile_target != null:
		pile.build_target_scene = build_pile_target
	get_parent().add_child(pile)
	pile.global_position = global_position
