extends Node3D
class_name DestructibleObject

const SoundSynthesizer = preload("res://scripts/audio/sound_synthesizer.gd")
const StudField = preload("res://scripts/economy/stud_field.gd")
const BuildPile = preload("res://scripts/building/build_pile.gd")
const BrickBuilder = preload("res://scripts/construction/brick_builder.gd")
const ComicPopup = preload("res://scripts/ui/comic_popup.gd")

signal destroyed()

@export var is_farmhouse: bool = false
@export var is_barn: bool = false
@export var is_windmill: bool = false
@export var is_tractor: bool = false
@export var is_fence: bool = false
@export var is_pole: bool = false
@export var is_hay_bale: bool = false
@export var is_mailbox: bool = false
@export var is_chicken: bool = false
@export var drops_build_pile: bool = false
@export var build_pile_target: PackedScene = null

var is_smashed: bool = false
var spinning_rotor: Node3D = null
var chicken_peck_timer: float = 0.0

func _ready() -> void:
	add_to_group("destructible")
	_build_visuals()

func _process(delta: float) -> void:
	if is_smashed:
		return
	if is_instance_valid(spinning_rotor):
		spinning_rotor.rotation.z += delta * 9.0
	if is_chicken:
		chicken_peck_timer += delta
		rotation.x = sin(chicken_peck_timer * 6.0) * 0.25

func _build_visuals() -> void:
	if is_farmhouse:
		_build_farmhouse()
	elif is_barn:
		_build_barn()
	elif is_windmill:
		_build_windmill()
	elif is_tractor:
		_build_tractor()
	elif is_fence:
		_build_fence()
	elif is_pole:
		_build_pole()
	elif is_hay_bale:
		_build_hay_bale()
	elif is_mailbox:
		_build_mailbox()
	elif is_chicken:
		_build_chicken()
	else:
		_build_generic_crate()

func _build_farmhouse() -> void:
	# Aunt Meg's Farmhouse with Front Porch and Studded Roof
	var col_white = Color(0.95, 0.95, 0.95)
	var col_roof = Color(0.24, 0.26, 0.30)
	var col_stone = Color(0.48, 0.46, 0.44)
	var col_wood = Color(0.55, 0.38, 0.22)
	
	# Main house body (8m wide, 4m high, 7m deep)
	var house = MeshInstance3D.new()
	var h_box = BoxMesh.new()
	h_box.size = Vector3(8.0, 4.0, 7.0)
	house.mesh = h_box
	house.material_override = BrickBuilder.get_plastic_material(col_white)
	house.position = Vector3(0, 2.0, 0)
	add_child(house)
	
	# Sloped Gable Roof with studded ridge
	var roof = MeshInstance3D.new()
	var r_prism = PrismMesh.new()
	r_prism.size = Vector3(8.4, 2.6, 7.4)
	roof.mesh = r_prism
	roof.material_override = BrickBuilder.get_plastic_material(col_roof)
	roof.position = Vector3(0, 5.3, 0)
	add_child(roof)
	
	# Front Porch deck & pillars
	var porch = MeshInstance3D.new()
	var p_box = BoxMesh.new()
	p_box.size = Vector3(8.0, 0.3, 2.2)
	porch.mesh = p_box
	porch.material_override = BrickBuilder.get_plastic_material(col_wood)
	porch.position = Vector3(0, 0.15, 4.6)
	add_child(porch)
	
	for px in [-3.6, -1.2, 1.2, 3.6]:
		var post = MeshInstance3D.new()
		var post_box = BoxMesh.new()
		post_box.size = Vector3(0.2, 2.8, 0.2)
		post.mesh = post_box
		post.material_override = BrickBuilder.get_plastic_material(col_white)
		post.position = Vector3(px, 1.55, 5.5)
		add_child(post)
		
	# Stone Chimney
	var chim = MeshInstance3D.new()
	var c_box = BoxMesh.new()
	c_box.size = Vector3(1.0, 5.8, 1.0)
	chim.mesh = c_box
	chim.material_override = BrickBuilder.get_plastic_material(col_stone)
	chim.position = Vector3(3.2, 3.5, 0)
	add_child(chim)

func _build_barn() -> void:
	# Red Barn with Sloped Roof and White Cross-Braces
	var col_red = Color(0.82, 0.12, 0.12)
	var col_white = Color(0.95, 0.95, 0.95)
	var col_roof = Color(0.18, 0.20, 0.22)
	
	var body = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(6.5, 4.2, 8.5)
	body.mesh = b_box
	body.material_override = BrickBuilder.get_plastic_material(col_red)
	body.position = Vector3(0, 2.1, 0)
	add_child(body)
	
	var roof = MeshInstance3D.new()
	var r_prism = PrismMesh.new()
	r_prism.size = Vector3(6.9, 2.6, 8.8)
	roof.mesh = r_prism
	roof.material_override = BrickBuilder.get_plastic_material(col_roof)
	roof.position = Vector3(0, 5.5, 0)
	add_child(roof)
	
	# Barn Door
	var door = MeshInstance3D.new()
	var d_box = BoxMesh.new()
	d_box.size = Vector3(2.4, 2.8, 0.15)
	door.mesh = d_box
	door.material_override = BrickBuilder.get_plastic_material(col_white)
	door.position = Vector3(0, 1.4, 4.3)
	add_child(door)

func _build_windmill() -> void:
	# Aermotor Lattice Windmill
	var col_steel = Color(0.85, 0.88, 0.92)
	
	# 4 Splayed Lattice Legs
	for lx in [-0.8, 0.8]:
		for lz in [-0.8, 0.8]:
			var leg = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.05
			cyl.bottom_radius = 0.08
			cyl.height = 8.0
			leg.mesh = cyl
			leg.material_override = BrickBuilder.get_plastic_material(col_steel)
			leg.position = Vector3(lx * 0.6, 4.0, lz * 0.6)
			leg.rotation.x = -lz * 0.08
			leg.rotation.z = lx * 0.08
			add_child(leg)
			
	# Windmill Nacelle head
	var head = Node3D.new()
	head.position = Vector3(0, 8.2, 0)
	add_child(head)
	
	# Tail Vane
	var tail = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.08, 0.7, 1.4)
	tail.mesh = t_box
	tail.material_override = BrickBuilder.get_plastic_material(col_steel)
	tail.position = Vector3(0, 0.2, -1.2)
	head.add_child(tail)
	
	# Rotor Hub and Blades
	spinning_rotor = Node3D.new()
	spinning_rotor.position = Vector3(0, 0.2, 0.4)
	head.add_child(spinning_rotor)
	
	# Multi-blade fan
	for i in range(8):
		var blade = MeshInstance3D.new()
		var b_box = BoxMesh.new()
		b_box.size = Vector3(0.25, 1.8, 0.03)
		blade.mesh = b_box
		blade.material_override = BrickBuilder.get_plastic_material(col_steel)
		blade.rotation.z = (TAU / 8.0) * i
		spinning_rotor.add_child(blade)

func _build_tractor() -> void:
	# Vintage Green & Yellow Farm Tractor
	var col_green = Color(0.12, 0.55, 0.22)
	var col_yellow = Color(0.95, 0.82, 0.1)
	var col_black = Color(0.1, 0.1, 0.1)
	var col_silver = Color(0.85, 0.88, 0.9)
	
	# Tractor Hood / Body
	var hood = MeshInstance3D.new()
	var h_box = BoxMesh.new()
	h_box.size = Vector3(1.2, 0.9, 2.2)
	hood.mesh = h_box
	hood.material_override = BrickBuilder.get_plastic_material(col_green)
	hood.position = Vector3(0, 1.0, 0.4)
	add_child(hood)
	
	# Grille & Headlights
	var grille = MeshInstance3D.new()
	var g_box = BoxMesh.new()
	g_box.size = Vector3(1.0, 0.7, 0.1)
	grille.mesh = g_box
	grille.material_override = BrickBuilder.get_plastic_material(col_yellow)
	grille.position = Vector3(0, 1.0, 1.55)
	add_child(grille)
	
	# Exhaust Smokestack
	var stack = MeshInstance3D.new()
	var s_cyl = CylinderMesh.new()
	s_cyl.top_radius = 0.06
	s_cyl.bottom_radius = 0.06
	s_cyl.height = 0.9
	stack.mesh = s_cyl
	stack.material_override = BrickBuilder.get_plastic_material(col_black)
	stack.position = Vector3(0.4, 1.8, 1.0)
	add_child(stack)
	
	# Big Knobby Rear Wheels
	for wx in [-0.9, 0.9]:
		var r_wheel = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.75
		cyl.bottom_radius = 0.75
		cyl.height = 0.45
		r_wheel.mesh = cyl
		r_wheel.material_override = BrickBuilder.get_plastic_material(col_yellow)
		r_wheel.rotation.z = PI / 2.0
		r_wheel.position = Vector3(wx, 0.75, -0.6)
		add_child(r_wheel)
		
	# Smaller Front Wheels
	for wx in [-0.75, 0.75]:
		var f_wheel = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.45
		cyl.bottom_radius = 0.45
		cyl.height = 0.3
		f_wheel.mesh = cyl
		f_wheel.material_override = BrickBuilder.get_plastic_material(col_yellow)
		f_wheel.rotation.z = PI / 2.0
		f_wheel.position = Vector3(wx, 0.45, 1.1)
		add_child(f_wheel)

func _build_fence() -> void:
	# Wooden rail fence with true studs on posts
	var col_wood = Color(0.92, 0.92, 0.88)
	
	for px in [-1.4, 1.4]:
		var post = BrickBuilder.create_brick(1, 1, 7, col_wood, true)
		post.position = Vector3(px, 0, 0)
		add_child(post)
		
	for ry in [0.35, 0.75]:
		var rail = MeshInstance3D.new()
		var r_box = BoxMesh.new()
		r_box.size = Vector3(3.0, 0.14, 0.08)
		rail.mesh = r_box
		rail.material_override = BrickBuilder.get_plastic_material(col_wood)
		rail.position = Vector3(0, ry, 0)
		add_child(rail)

func _build_pole() -> void:
	var col_pole = Color(0.42, 0.3, 0.18)
	var pole = MeshInstance3D.new()
	var p_cyl = CylinderMesh.new()
	p_cyl.top_radius = 0.16
	p_cyl.bottom_radius = 0.2
	p_cyl.height = 6.5
	pole.mesh = p_cyl
	pole.material_override = BrickBuilder.get_plastic_material(col_pole)
	pole.position = Vector3(0, 3.25, 0)
	add_child(pole)
	
	var arm = MeshInstance3D.new()
	var a_box = BoxMesh.new()
	a_box.size = Vector3(2.4, 0.2, 0.2)
	arm.mesh = a_box
	arm.material_override = BrickBuilder.get_plastic_material(col_pole)
	arm.position = Vector3(0, 5.8, 0)
	add_child(arm)

func _build_hay_bale() -> void:
	var col_hay = Color(0.88, 0.75, 0.24)
	var bale = MeshInstance3D.new()
	var b_cyl = CylinderMesh.new()
	b_cyl.top_radius = 0.75
	b_cyl.bottom_radius = 0.75
	b_cyl.height = 1.3
	bale.mesh = b_cyl
	bale.material_override = BrickBuilder.get_plastic_material(col_hay)
	bale.rotation.z = PI / 2.0
	bale.position = Vector3(0, 0.75, 0)
	add_child(bale)

func _build_mailbox() -> void:
	var col_wood = Color(0.55, 0.38, 0.22)
	var col_box = Color(0.85, 0.88, 0.92)
	var col_flag = Color(0.9, 0.15, 0.15)
	
	var post = MeshInstance3D.new()
	var p_box = BoxMesh.new()
	p_box.size = Vector3(0.14, 1.1, 0.14)
	post.mesh = p_box
	post.material_override = BrickBuilder.get_plastic_material(col_wood)
	post.position = Vector3(0, 0.55, 0)
	add_child(post)
	
	var box = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.35, 0.35, 0.6)
	box.mesh = b_box
	box.material_override = BrickBuilder.get_plastic_material(col_box)
	box.position = Vector3(0, 1.25, 0)
	add_child(box)
	
	var flag = MeshInstance3D.new()
	var f_box = BoxMesh.new()
	f_box.size = Vector3(0.04, 0.2, 0.08)
	flag.mesh = f_box
	flag.material_override = BrickBuilder.get_plastic_material(col_flag)
	flag.position = Vector3(0.2, 1.35, -0.15)
	add_child(flag)

func _build_chicken() -> void:
	var col_white = Color(0.95, 0.95, 0.95)
	var col_red = Color(0.9, 0.15, 0.15)
	var col_yellow = Color(0.95, 0.82, 0.1)
	
	var body = BrickBuilder.create_brick(1, 1, 2, col_white, true)
	add_child(body)
	
	var comb = MeshInstance3D.new()
	var c_box = BoxMesh.new()
	c_box.size = Vector3(0.08, 0.12, 0.15)
	comb.mesh = c_box
	comb.material_override = BrickBuilder.get_plastic_material(col_red)
	comb.position = Vector3(0, 0.42, 0)
	add_child(comb)
	
	var beak = MeshInstance3D.new()
	var b_prism = PrismMesh.new()
	b_prism.size = Vector3(0.12, 0.1, 0.1)
	beak.mesh = b_prism
	beak.material_override = BrickBuilder.get_plastic_material(col_yellow)
	beak.position = Vector3(0, 0.25, 0.25)
	beak.rotation.x = PI / 2.0
	add_child(beak)

func _build_generic_crate() -> void:
	var crate = BrickBuilder.create_brick(2, 2, 6, Color(0.9, 0.6, 0.1), true)
	add_child(crate)

func smash(impact_dir: Vector3 = Vector3.UP, force: float = 8.0) -> void:
	if is_smashed:
		return
	is_smashed = true
	
	var synth = SoundSynthesizer.get_instance()
	if is_instance_valid(synth):
		synth.play_brick_smash()
		
	# Spawn slapstick comic book impact text
	var words = ["SMASH!", "BAM!", "POW!", "CLATTER!", "CRUNCH!"]
	ComicPopup.spawn(get_parent(), global_position, words[randi() % words.size()])
		
	# Spawn authentic LEGO brick parts
	_spawn_authentic_brick_debris(impact_dir, force)
	
	# Spawn studs
	var economy = get_tree().root.find_child("StudField", true, false) as StudField
	if is_instance_valid(economy):
		var silver = 4
		var gold = 1
		var blue = 0
		if is_farmhouse:
			silver = 16
			gold = 6
			blue = 2
		elif is_barn or is_tractor:
			silver = 12
			gold = 4
			blue = 1
		elif is_hay_bale or is_pole or is_windmill:
			silver = 6
			gold = 2
		economy.spawn_stud_burst(global_position, silver, gold, blue)
		
	if drops_build_pile:
		_spawn_build_pile()
		
	destroyed.emit()
	queue_free()

func _spawn_authentic_brick_debris(impact_dir: Vector3, force: float) -> void:
	var count = 10 if (is_barn or is_farmhouse) else (4 if is_chicken else 6)
	var colors = [Color(0.85, 0.15, 0.15), Color(0.95, 0.8, 0.1), Color(0.9, 0.9, 0.9), Color(0.15, 0.45, 0.85), Color(0.1, 0.55, 0.2)]
	
	for i in range(count):
		var rb = RigidBody3D.new()
		
		# Build a real 2x4 or 1x2 brick with studs!
		var part_node: Node3D
		var col_shape = BoxShape3D.new()
		if i % 2 == 0:
			part_node = BrickBuilder.create_2x4_brick(colors[i % colors.size()])
			col_shape.size = Vector3(0.8, 0.48, 1.6)
		else:
			part_node = BrickBuilder.create_1x2_plate(colors[i % colors.size()])
			col_shape.size = Vector3(0.4, 0.16, 0.8)
			
		rb.add_child(part_node)
		
		var col = CollisionShape3D.new()
		col.shape = col_shape
		rb.add_child(col)
		
		get_parent().add_child(rb)
		rb.global_position = global_position + Vector3(randf_range(-1.2, 1.2), randf_range(0.5, 2.5), randf_range(-1.2, 1.2))
		
		var impulse = (impact_dir.normalized() + Vector3(randf_range(-0.5, 0.5), randf_range(0.4, 1.0), randf_range(-0.5, 0.5))).normalized() * randf_range(force * 0.6, force * 1.3)
		rb.apply_central_impulse(impulse)
		rb.apply_torque_impulse(Vector3(randf_range(-6, 6), randf_range(-6, 6), randf_range(-6, 6)))
		
		rb.get_tree().create_timer(4.5).timeout.connect(rb.queue_free)

func _spawn_build_pile() -> void:
	var pile = BuildPile.new()
	if build_pile_target != null:
		pile.build_target_scene = build_pile_target
	get_parent().add_child(pile)
	pile.global_position = global_position
