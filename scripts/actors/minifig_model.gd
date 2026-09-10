extends Node3D
class_name MinifigModel

# Minifigure Parts
var head: Node3D
var torso: Node3D
var hips: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_hand: Node3D
var right_hand: Node3D

var is_jo: bool = true
var punch_time: float = 0.0
var walk_cycle: float = 0.0
var is_charging: bool = false

# Materials
var mat_yellow: StandardMaterial3D
var mat_torso: StandardMaterial3D
var mat_pants: StandardMaterial3D
var mat_face: StandardMaterial3D

func _ready() -> void:
	_setup_materials()
	_build_minifig_hierarchy()
	apply_character_identity(is_jo)

func _setup_materials() -> void:
	mat_yellow = StandardMaterial3D.new()
	mat_yellow.albedo_color = Color(0.98, 0.82, 0.12) # Classic LEGO yellow
	mat_yellow.roughness = 0.22
	mat_yellow.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX

	mat_torso = StandardMaterial3D.new()
	mat_torso.roughness = 0.25

	mat_pants = StandardMaterial3D.new()
	mat_pants.roughness = 0.3

	mat_face = StandardMaterial3D.new()
	mat_face.albedo_color = Color(0.98, 0.82, 0.12)
	mat_face.roughness = 0.22

func apply_character_identity(jo: bool) -> void:
	is_jo = jo
	if is_jo:
		# Jo: Chaser blue vest, grey pants
		mat_torso.albedo_color = Color(0.15, 0.35, 0.65)
		mat_pants.albedo_color = Color(0.3, 0.32, 0.35)
	else:
		# Bill: Heavy rugged khaki/brown jacket, dark blue jeans
		mat_torso.albedo_color = Color(0.55, 0.42, 0.22)
		mat_pants.albedo_color = Color(0.12, 0.18, 0.32)

func _build_minifig_hierarchy() -> void:
	# Root node at baseplate level
	hips = Node3D.new()
	hips.name = "Hips"
	hips.position = Vector3(0, 0.45, 0)
	add_child(hips)

	# Hip block mesh
	var hip_mesh = MeshInstance3D.new()
	var hip_box = BoxMesh.new()
	hip_box.size = Vector3(0.42, 0.14, 0.22)
	hip_box.material = mat_pants
	hip_mesh.mesh = hip_box
	hips.add_child(hip_mesh)

	# Left Leg
	left_leg = Node3D.new()
	left_leg.name = "LeftLeg"
	left_leg.position = Vector3(-0.11, -0.06, 0)
	hips.add_child(left_leg)
	var l_leg_mesh = MeshInstance3D.new()
	var leg_box = BoxMesh.new()
	leg_box.size = Vector3(0.19, 0.38, 0.22)
	leg_box.material = mat_pants
	l_leg_mesh.mesh = leg_box
	l_leg_mesh.position = Vector3(0, -0.19, 0)
	left_leg.add_child(l_leg_mesh)
	# Foot toe
	var l_toe = MeshInstance3D.new()
	var toe_box = BoxMesh.new()
	toe_box.size = Vector3(0.19, 0.12, 0.12)
	toe_box.material = mat_pants
	l_toe.mesh = toe_box
	l_toe.position = Vector3(0, -0.32, 0.12)
	left_leg.add_child(l_toe)

	# Right Leg
	right_leg = Node3D.new()
	right_leg.name = "RightLeg"
	right_leg.position = Vector3(0.11, -0.06, 0)
	hips.add_child(right_leg)
	var r_leg_mesh = MeshInstance3D.new()
	r_leg_mesh.mesh = leg_box
	r_leg_mesh.position = Vector3(0, -0.19, 0)
	right_leg.add_child(r_leg_mesh)
	# Foot toe
	var r_toe = MeshInstance3D.new()
	r_toe.mesh = toe_box
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
	t_box.material = mat_torso
	torso_mesh.mesh = t_box
	torso_mesh.position = Vector3(0, 0.22, 0)
	torso.add_child(torso_mesh)

	# Torso badge / detail plate
	var badge = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.24, 0.2, 0.02)
	var mat_badge = StandardMaterial3D.new()
	mat_badge.albedo_color = Color(0.9, 0.85, 0.3)
	badge.mesh = b_box
	badge.material_override = mat_badge
	badge.position = Vector3(0, 0.24, 0.125)
	torso.add_child(badge)

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
	h_cyl.material = mat_yellow
	head_mesh.mesh = h_cyl
	head_mesh.position = Vector3(0, 0.15, 0)
	head.add_child(head_mesh)

	# Head Stud on top
	var stud_mesh = MeshInstance3D.new()
	var s_cyl = CylinderMesh.new()
	s_cyl.top_radius = 0.08
	s_cyl.bottom_radius = 0.08
	s_cyl.height = 0.07
	s_cyl.material = mat_yellow
	stud_mesh.mesh = s_cyl
	stud_mesh.position = Vector3(0, 0.33, 0)
	head.add_child(stud_mesh)

	# Eyes / Face dots
	var l_eye = MeshInstance3D.new()
	var eye_box = BoxMesh.new()
	eye_box.size = Vector3(0.035, 0.05, 0.02)
	var mat_black = StandardMaterial3D.new()
	mat_black.albedo_color = Color(0.08, 0.08, 0.08)
	l_eye.mesh = eye_box
	l_eye.material_override = mat_black
	l_eye.position = Vector3(-0.06, 0.17, 0.15)
	head.add_child(l_eye)

	var r_eye = MeshInstance3D.new()
	r_eye.mesh = eye_box
	r_eye.material_override = mat_black
	r_eye.position = Vector3(0.06, 0.17, 0.15)
	head.add_child(r_eye)

	# Left Arm
	left_arm = Node3D.new()
	left_arm.name = "LeftArm"
	left_arm.position = Vector3(-0.25, 0.38, 0)
	torso.add_child(left_arm)
	var l_arm_mesh = MeshInstance3D.new()
	var arm_cyl = CylinderMesh.new()
	arm_cyl.top_radius = 0.07
	arm_cyl.bottom_radius = 0.07
	arm_cyl.height = 0.32
	arm_cyl.material = mat_torso
	l_arm_mesh.mesh = arm_cyl
	l_arm_mesh.position = Vector3(0, -0.16, 0)
	left_arm.add_child(l_arm_mesh)

	# Left Hand (C-grip)
	left_hand = Node3D.new()
	left_hand.position = Vector3(0, -0.34, 0)
	left_arm.add_child(left_hand)
	var l_hand_mesh = MeshInstance3D.new()
	var hand_box = BoxMesh.new()
	hand_box.size = Vector3(0.08, 0.1, 0.1)
	hand_box.material = mat_yellow
	l_hand_mesh.mesh = hand_box
	left_hand.add_child(l_hand_mesh)

	# Right Arm
	right_arm = Node3D.new()
	right_arm.name = "RightArm"
	right_arm.position = Vector3(0.25, 0.38, 0)
	torso.add_child(right_arm)
	var r_arm_mesh = MeshInstance3D.new()
	r_arm_mesh.mesh = arm_cyl
	r_arm_mesh.position = Vector3(0, -0.16, 0)
	right_arm.add_child(r_arm_mesh)

	# Right Hand
	right_hand = Node3D.new()
	right_hand.position = Vector3(0, -0.34, 0)
	right_arm.add_child(right_hand)
	var r_hand_mesh = MeshInstance3D.new()
	r_hand_mesh.mesh = hand_box
	right_hand.add_child(r_hand_mesh)

func update_animation(delta: float, is_moving: bool, move_speed: float) -> void:
	if punch_time > 0.0:
		punch_time -= delta * 4.0
		var punch_phase = sin(clampf(punch_time, 0.0, 1.0) * PI)
		right_arm.rotation.x = -punch_phase * 1.6
		torso.rotation.y = punch_phase * 0.35
	else:
		torso.rotation.y = 0.0

	if is_charging:
		# Bill's shoulder bash charge
		hips.rotation.x = 0.45 # Aggressive forward lean
		left_arm.rotation.x = -0.8
		right_arm.rotation.x = -1.2
		left_leg.rotation.x = sin(walk_cycle * 2.0) * 0.6
		right_leg.rotation.x = -sin(walk_cycle * 2.0) * 0.6
		walk_cycle += delta * 18.0
		return

	if is_moving:
		walk_cycle += delta * (move_speed * 2.4)
		var leg_swing = sin(walk_cycle) * 0.75
		left_leg.rotation.x = leg_swing
		right_leg.rotation.x = -leg_swing
		
		# TT arm swings opposite to legs
		if punch_time <= 0.0:
			right_arm.rotation.x = leg_swing * 0.8
		left_arm.rotation.x = -leg_swing * 0.8

		# Classic minifig waist bob & sway
		hips.position.y = 0.45 + abs(sin(walk_cycle * 2.0)) * 0.04
		torso.rotation.z = sin(walk_cycle) * 0.08
		head.rotation.y = sin(walk_cycle) * 0.06
	else:
		# Idle settle
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
	# Comedic pop on zero health
	var tween = create_tween().set_parallel(true)
	tween.tween_property(head, "position", head.position + Vector3(randf_range(-0.5, 0.5), 1.2, randf_range(-0.5, 0.5)), 0.4)
	tween.tween_property(torso, "position", torso.position + Vector3(randf_range(-0.6, 0.6), 0.6, randf_range(-0.6, 0.6)), 0.4)
	tween.tween_property(left_leg, "position", left_leg.position + Vector3(-0.4, 0.3, 0.2), 0.4)
	tween.tween_property(right_leg, "position", right_leg.position + Vector3(0.4, 0.3, -0.2), 0.4)
	
	# Snap back after 0.8s
	await get_tree().create_timer(0.7).timeout
	var restore = create_tween().set_parallel(true)
	restore.tween_property(head, "position", Vector3(0, 0.44, 0), 0.25)
	restore.tween_property(torso, "position", Vector3(0, 0.07, 0), 0.25)
	restore.tween_property(left_leg, "position", Vector3(-0.11, -0.06, 0), 0.25)
	restore.tween_property(right_leg, "position", Vector3(0.11, -0.06, 0), 0.25)
