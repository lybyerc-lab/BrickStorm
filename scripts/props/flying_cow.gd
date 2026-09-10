extends Node3D
class_name FlyingCow

var orbit_radius: float = 8.0
var orbit_angle: float = 0.0
var orbit_speed: float = 1.4
var orbit_height: float = 6.0
var target_tornado: Node3D = null

var moo_timer: float = 3.0

func _ready() -> void:
	_build_cow_mesh()

func _build_cow_mesh() -> void:
	var mat_white = StandardMaterial3D.new()
	mat_white.albedo_color = Color(0.95, 0.95, 0.95)
	mat_white.roughness = 0.3
	
	var mat_black = StandardMaterial3D.new()
	mat_black.albedo_color = Color(0.1, 0.1, 0.1)
	mat_black.roughness = 0.3
	
	var mat_pink = StandardMaterial3D.new()
	mat_pink.albedo_color = Color(0.95, 0.6, 0.65)
	
	# Body
	var body = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.9, 0.7, 1.4)
	body.mesh = b_box
	body.material_override = mat_white
	add_child(body)
	
	# Black spot on body
	var spot = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(0.92, 0.4, 0.6)
	spot.mesh = s_box
	spot.material_override = mat_black
	spot.position = Vector3(0, 0.1, 0.1)
	add_child(spot)
	
	# Head
	var head = MeshInstance3D.new()
	var h_box = BoxMesh.new()
	h_box.size = Vector3(0.5, 0.5, 0.6)
	head.mesh = h_box
	head.material_override = mat_black
	head.position = Vector3(0, 0.4, 0.8)
	add_child(head)
	
	# Pink Muzzle / Snout
	var muzzle = MeshInstance3D.new()
	var m_box = BoxMesh.new()
	m_box.size = Vector3(0.4, 0.25, 0.3)
	muzzle.mesh = m_box
	muzzle.material_override = mat_pink
	muzzle.position = Vector3(0, 0.3, 1.15)
	add_child(muzzle)
	
	# Horns
	for hx in [-0.22, 0.22]:
		var horn = MeshInstance3D.new()
		var horn_cyl = CylinderMesh.new()
		horn_cyl.top_radius = 0.02
		horn_cyl.bottom_radius = 0.06
		horn_cyl.height = 0.22
		horn.mesh = horn_cyl
		horn.material_override = mat_white
		horn.position = Vector3(hx, 0.7, 0.75)
		add_child(horn)
		
	# 4 Legs
	for lx in [-0.3, 0.3]:
		for lz in [-0.45, 0.45]:
			var leg = MeshInstance3D.new()
			var leg_box = BoxMesh.new()
			leg_box.size = Vector3(0.2, 0.5, 0.2)
			leg.mesh = leg_box
			leg.material_override = mat_black
			leg.position = Vector3(lx, -0.5, lz)
			add_child(leg)

func _process(delta: float) -> void:
	if not is_instance_valid(target_tornado):
		target_tornado = get_tree().root.find_child("Tornado", true, false)
		if not is_instance_valid(target_tornado):
			return
			
	orbit_angle += orbit_speed * delta
	var center = target_tornado.global_position
	
	# Spiral altitude & radius variation
	var wave = sin(orbit_angle * 0.5)
	var r = orbit_radius + wave * 2.0
	var h = orbit_height + wave * 3.0
	
	global_position = Vector3(
		center.x + cos(orbit_angle) * r,
		center.y + h,
		center.z + sin(orbit_angle) * r
	)
	
	# Tumbling / graceful rotation in wind
	rotation.x += delta * 1.5
	rotation.y += delta * 2.2
	rotation.z = sin(orbit_angle) * 0.5
	
	# Comic Moo!
	moo_timer -= delta
	if moo_timer <= 0.0:
		moo_timer = randf_range(4.0, 7.5)
		var synth = SoundSynthesizer.get_instance()
		if is_instance_valid(synth):
			synth.play_cow_moo()
