extends Node3D
class_name MinifigModel

# Minifigure Parts
var hips: Node3D
var left_leg: Node3D
var right_leg: Node3D
var torso: Node3D
var head: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_hand: Node3D
var right_hand: Node3D
var headwear: Node3D

var is_jo: bool = true
var punch_time: float = 0.0
var walk_cycle: float = 0.0
var is_charging: bool = false

# Materials
var mat_yellow: StandardMaterial3D
var mat_torso: StandardMaterial3D
var mat_pants: StandardMaterial3D
var mat_hair_hat: StandardMaterial3D

func _ready() -> void:
	_setup_materials()
	_build_minifig_hierarchy()
	apply_character_identity(is_jo)

func _setup_materials() -> void:
	mat_yellow = StandardMaterial3D.new()
	mat_yellow.albedo_color = Color(0.98, 0.82, 0.12) # Classic LEGO yellow
	mat_yellow.roughness = 0.18
	mat_yellow.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	mat_yellow.rim_enabled = true
	mat_yellow.rim = 0.35

	mat_torso = StandardMaterial3D.new()
	mat_torso.roughness = 0.22
	mat_torso.rim_enabled = true
	mat_torso.rim = 0.25

	mat_pants = StandardMaterial3D.new()
	mat_pants.roughness = 0.25

	mat_hair_hat = StandardMaterial3D.new()
	mat_hair_hat.roughness = 0.2

func apply_character_identity(jo: bool) -> void:
	is_jo = jo
	if is_instance_valid(headwear):
		headwear.queue_free()
		
	if is_jo:
		# Jo: Deep blue chaser vest, olive pants, red backward cap
		mat_torso.albedo_color = Color(0.12, 0.32, 0.62)
		mat_pants.albedo_color = Color(0.28, 0.32, 0.28)
		mat_hair_hat.albedo_color = Color(0.85, 0.15, 0.15) # Red cap
		_build_jo_cap()
	else:
		# Bill: Khaki rugged field jacket, dark blue jeans, brown tousled hair
		mat_torso.albedo_color = Color(0.58, 0.44, 0.25)
		mat_pants.albedo_color = Color(0.14, 0.18, 0.32)
		mat_hair_hat.albedo_color = Color(0.32, 0.22, 0.12) # Dark brown hair
		_build_bill_hair()

func _build_minifig_hierarchy() -> void:
	# Root at baseplate level
	hips = Node3D.new()
	hips.name = "Hips"
	hips.position = Vector3(0, 0.45, 0)
	add_child(hips)

	# Hip bridge mesh
	var hip_mesh = MeshInstance3D.new()
	var hip_box = BoxMesh.new()
	hip_box.size = Vector3(0.42, 0.14, 0.22)
	hip_mesh.mesh = hip_box
	hip_mesh.material_override = mat_pants
	hips.add_child(hip_mesh)

	# Left Leg
	left_leg = Node3D.new()
	left_leg.name = "LeftLeg"
	left_leg.position = Vector3(-0.11, -0.06, 0)
	hips.add_child(left_leg)
	var l_leg_mesh = MeshInstance3D.new()
	var leg_box = BoxMesh.new()
	leg_box.size = Vector3(0.19, 0.38, 0.22)
	l_leg_mesh.mesh = leg_box
	l_leg_mesh.material_override = mat_pants
	l_leg_mesh.position = Vector3(0, -0.19, 0)
	left_leg.add_child(l_leg_mesh)
	
	# Left Foot toe extension
	var l_toe = MeshInstance3D.new()
	var toe_box = BoxMesh.new()
	toe_box.size = Vector3(0.19, 0.12, 0.12)
	l_toe.mesh = toe_box
	l_toe.material_override = mat_pants
	l_toe.position = Vector3(0, -0.32, 0.12)
	left_leg.add_child(l_toe)

	# Right Leg
	right_leg = Node3D.new()
	right_leg.name = "RightLeg"
	right_leg.position = Vector3(0.11, -0.06, 0)
	hips.add_child(right_leg)
	var r_leg_mesh = MeshInstance3D.new()
	r_leg_mesh.mesh = leg_box
	r_leg_mesh.material_override = mat_pants
	r_leg_mesh.position = Vector3(0, -0.19, 0)
	right_leg.add_child(r_leg_mesh)
	
	# Right Foot toe extension
	var r_toe = MeshInstance3D.new()
	r_toe.mesh = toe_box
	r_toe.material_override = mat_pants
	r_toe.position = Vector3(0, -0.32, 0.12)
	right_leg.add_child(r_toe)

	# Torso
	torso = Node3D.new()
	torso.name = "Torso"
	torso.position = Vector3(0, 0.07, 0)
	hips.add_child(torso)
	var torso_mesh = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.42, 0.44, 0.24)
	torso_mesh.mesh = t_box
	torso_mesh.material_override = mat_torso
	torso_mesh.position = Vector3(0, 0.22, 0)
	torso.add_child(torso_mesh)

	# Torso detail badge / zipper print
	var vest_trim = MeshInstance3D.new()
	var v_box = BoxMesh.new()
	v_box.size = Vector3(0.12, 0.42, 0.015)
	var mat_zipper = StandardMaterial3D.new()
	mat_zipper.albedo_color = Color(0.85, 0.85, 0.88)
	vest_trim.mesh = v_box
	vest_trim.material_override = mat_zipper
	vest_trim.position = Vector3(0, 0.22, 0.128)
	torso.add_child(vest_trim)

	# Head
	head = Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.44, 0)
	torso.add_child(head)
	var head_mesh = MeshInstance3D.new()
	var h_cyl = CylinderMesh.new()
	h_cyl.top_radius = 0.16
	h_cyl.bottom_radius = 0.16
	h_cyl.height = 0.30
	head_mesh.mesh = h_cyl
	head_mesh.material_override = mat_yellow
	head_mesh.position = Vector3(0, 0.15, 0)
	head.add_child(head_mesh)

	# Head Stud on top (with hollow rim)
	var stud_mesh = MeshInstance3D.new()
	var s_cyl = CylinderMesh.new()
	s_cyl.top_radius = 0.09
	s_cyl.bottom_radius = 0.09
	s_cyl.height = 0.08
	stud_mesh.mesh = s_cyl
	stud_mesh.material_override = mat_yellow
	stud_mesh.position = Vector3(0, 0.34, 0)
	head.add_child(stud_mesh)

	# Facial Decal Features (Eyes with white specular catchlights)
	var mat_black = StandardMaterial3D.new()
	mat_black.albedo_color = Color(0.08, 0.08, 0.08)
	var eye_box = BoxMesh.new()
	eye_box.size = Vector3(0.04, 0.055, 0.015)

	var l_eye = MeshInstance3D.new()
	l_eye.mesh = eye_box
	l_eye.material_override = mat_black
	l_eye.position = Vector3(-0.065, 0.17, 0.155)
	head.add_child(l_eye)

	var r_eye = MeshInstance3D.new()
	r_eye.mesh = eye_box
	r_eye.material_override = mat_black
	r_eye.position = Vector3(0.065, 0.17, 0.155)
	head.add_child(r_eye)

	# Smirk Mouth
	var mouth = MeshInstance3D.new()
	var m_box = BoxMesh.new()
	m_box.size = Vector3(0.08, 0.02, 0.015)
	mouth.mesh = m_box
	mouth.material_override = mat_black
	mouth.position = Vector3(0.01, 0.09, 0.155)
	mouth.rotation.z = 0.1
	head.add_child(mouth)

	# Left Arm (Molded with elbow angle)
	left_arm = Node3D.new()
	left_arm.name = "LeftArm"
	left_arm.position = Vector3(-0.25, 0.38, 0)
	torso.add_child(left_arm)
	_build_molded_arm(left_arm, false)

	# Right Arm (Molded with elbow angle)
	right_arm = Node3D.new()
	right_arm.name = "RightArm"
	right_arm.position = Vector3(0.25, 0.38, 0)
	torso.add_child(right_arm)
	_build_molded_arm(right_arm, true)

func _build_molded_arm(arm_node: Node3D, is_right: bool) -> void:
	# Upper arm
	var upper_mesh = MeshInstance3D.new()
	var u_cyl = CylinderMesh.new()
	u_cyl.top_radius = 0.075
	u_cyl.bottom_radius = 0.07
	u_cyl.height = 0.20
	upper_mesh.mesh = u_cyl
	upper_mesh.material_override = mat_torso
	upper_mesh.position = Vector3(0, -0.10, 0)
	arm_node.add_child(upper_mesh)

	# Forearm with classic 15 degree forward bend
	var fore_node = Node3D.new()
	fore_node.position = Vector3(0, -0.20, 0)
	fore_node.rotation.x = 0.28 # Forward bend
	arm_node.add_child(fore_node)

	var fore_mesh = MeshInstance3D.new()
	var f_cyl = CylinderMesh.new()
	f_cyl.top_radius = 0.07
	f_cyl.bottom_radius = 0.065
	f_cyl.height = 0.16
	fore_mesh.mesh = f_cyl
	fore_mesh.material_override = mat_torso
	fore_mesh.position = Vector3(0, -0.08, 0)
	fore_node.add_child(fore_mesh)

	# Wrist cuff
	var cuff = MeshInstance3D.new()
	var c_cyl = CylinderMesh.new()
	c_cyl.top_radius = 0.065
	c_cyl.bottom_radius = 0.065
	c_cyl.height = 0.04
	cuff.mesh = c_cyl
	cuff.material_override = mat_torso
	cuff.position = Vector3(0, -0.16, 0)
	fore_node.add_child(cuff)

	# C-grip hand
	var hand_mesh = MeshInstance3D.new()
	var h_box = BoxMesh.new()
	h_box.size = Vector3(0.08, 0.10, 0.09)
	hand_mesh.mesh = h_box
	hand_mesh.material_override = mat_yellow
	hand_mesh.position = Vector3(0, -0.21, 0.02)
	fore_node.add_child(hand_mesh)

	if is_right:
		right_hand = fore_node
	else:
		left_hand = fore_node

func _build_jo_cap() -> void:
	headwear = Node3D.new()
	headwear.name = "JoCap"
	head.add_child(headwear)

	# Cap dome
	var cap_dome = MeshInstance3D.new()
	var s_mesh = SphereMesh.new()
	s_mesh.radius = 0.18
	s_mesh.height = 0.22
	cap_dome.mesh = s_mesh
	cap_dome.material_override = mat_hair_hat
	cap_dome.position = Vector3(0, 0.25, -0.02)
	headwear.add_child(cap_dome)

	# Backward bill / visor
	var visor = MeshInstance3D.new()
	var v_box = BoxMesh.new()
	v_box.size = Vector3(0.18, 0.03, 0.16)
	visor.mesh = v_box
	visor.material_override = mat_hair_hat
	visor.position = Vector3(0, 0.22, -0.20)
	visor.rotation.x = -0.2
	headwear.add_child(visor)

	# Ponytail
	var mat_hair = StandardMaterial3D.new()
	mat_hair.albedo_color = Color(0.7, 0.45, 0.18) # Auburn ponytail
	var pony = MeshInstance3D.new()
	var p_cyl = CylinderMesh.new()
	p_cyl.top_radius = 0.05
	p_cyl.bottom_radius = 0.03
	p_cyl.height = 0.18
	pony.mesh = p_cyl
	pony.material_override = mat_hair
	pony.position = Vector3(0, 0.14, -0.24)
	pony.rotation.x = -0.6
	headwear.add_child(pony)

func _build_bill_hair() -> void:
	headwear = Node3D.new()
	headwear.name = "BillHair"
	head.add_child(headwear)

	# Tousled hair base
	var hair_base = MeshInstance3D.new()
	var h_box = BoxMesh.new()
	h_box.size = Vector3(0.36, 0.14, 0.36)
	hair_base.mesh = h_box
	hair_base.material_override = mat_hair_hat
	hair_base.position = Vector3(0, 0.28, 0)
	headwear.add_child(hair_base)

	# Windblown hair peaks
	for i in range(3):
		var peak = MeshInstance3D.new()
		var p_prism = PrismMesh.new()
		p_prism.size = Vector3(0.10, 0.12, 0.12)
		peak.mesh = p_prism
		peak.material_override = mat_hair_hat
		peak.position = Vector3(-0.1 + i * 0.1, 0.36, 0.06)
		peak.rotation.x = 0.3
		headwear.add_child(peak)

func update_animation(delta: float, is_moving: bool, move_speed: float) -> void:
	if punch_time > 0.0:
		punch_time -= delta * 4.5
		var punch_phase = sin(clampf(punch_time, 0.0, 1.0) * PI)
		right_arm.rotation.x = -punch_phase * 1.7
		torso.rotation.y = punch_phase * 0.35
	else:
		torso.rotation.y = 0.0

	if is_charging:
		hips.rotation.x = 0.45
		left_arm.rotation.x = -0.8
		right_arm.rotation.x = -1.2
		left_leg.rotation.x = sin(walk_cycle * 2.0) * 0.6
		right_leg.rotation.x = -sin(walk_cycle * 2.0) * 0.6
		walk_cycle += delta * 18.0
		return

	if is_moving:
		walk_cycle += delta * (move_speed * 2.5)
		var leg_swing = sin(walk_cycle) * 0.75
		left_leg.rotation.x = leg_swing
		right_leg.rotation.x = -leg_swing
		
		if punch_time <= 0.0:
			right_arm.rotation.x = leg_swing * 0.8
		left_arm.rotation.x = -leg_swing * 0.8

		hips.position.y = 0.45 + abs(sin(walk_cycle * 2.0)) * 0.045
		torso.rotation.z = sin(walk_cycle) * 0.08
		head.rotation.y = sin(walk_cycle) * 0.06
	else:
		left_leg.rotation.x = lerpf(left_leg.rotation.x, 0.0, delta * 12.0)
		right_leg.rotation.x = lerpf(right_leg.rotation.x, 0.0, delta * 12.0)
		if punch_time <= 0.0:
			right_arm.rotation.x = lerpf(right_arm.rotation.x, 0.0, delta * 12.0)
		left_arm.rotation.x = lerpf(left_arm.rotation.x, 0.0, delta * 12.0)
		hips.position.y = lerpf(hips.position.y, 0.45, delta * 12.0)
		hips.rotation.x = lerpf(hips.rotation.x, 0.0, delta * 12.0)
		torso.rotation.z = lerpf(torso.rotation.z, 0.0, delta * 12.0)
		head.rotation.y = lerpf(head.rotation.y, 0.0, delta * 12.0)

func trigger_punch() -> void:
	punch_time = 1.0

func trigger_pop_apart() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(head, "position", head.position + Vector3(randf_range(-0.5, 0.5), 1.2, randf_range(-0.5, 0.5)), 0.4)
	tween.tween_property(torso, "position", torso.position + Vector3(randf_range(-0.6, 0.6), 0.6, randf_range(-0.6, 0.6)), 0.4)
	tween.tween_property(left_leg, "position", left_leg.position + Vector3(-0.4, 0.3, 0.2), 0.4)
	tween.tween_property(right_leg, "position", right_leg.position + Vector3(0.4, 0.3, -0.2), 0.4)
	
	await get_tree().create_timer(0.7).timeout
	var restore = create_tween().set_parallel(true)
	restore.tween_property(head, "position", Vector3(0, 0.44, 0), 0.25)
	restore.tween_property(torso, "position", Vector3(0, 0.07, 0), 0.25)
	restore.tween_property(left_leg, "position", Vector3(-0.11, -0.06, 0), 0.25)
	restore.tween_property(right_leg, "position", Vector3(0.11, -0.06, 0), 0.25)
