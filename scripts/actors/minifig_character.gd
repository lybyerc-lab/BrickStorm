extends CharacterBody3D
class_name MinifigCharacter

signal character_swapped(is_jo: bool)
signal health_changed(current_hearts: int, max_hearts: int)

@export var is_jo: bool = true
var max_hearts: int = 4
var current_hearts: int = 4

var move_speed: float = 8.0
var jump_velocity: float = 9.0
var gravity: float = 22.0

var is_invulnerable: bool = false
var invulnerable_timer: float = 0.0

var attack_cooldown: float = 0.0
var is_building: bool = false
var is_shoulder_charging: bool = false
var charge_timer: float = 0.0

var magnet_radius: float = 5.0

# External mobile / input vector override (e.g. from VirtualStick)
var touch_move_vector: Vector2 = Vector2.ZERO
var touch_smash_pressed: bool = false
var touch_jump_pressed: bool = false
var touch_build_held: bool = false

var model: MinifigModel
var collision_shape: CollisionShape3D

func _ready() -> void:
	_setup_collision()
	_setup_model()
	_apply_character_stats()

func _setup_collision() -> void:
	collision_shape = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.05
	collision_shape.shape = cap
	collision_shape.position = Vector3(0, 0.52, 0)
	add_child(collision_shape)

func _setup_model() -> void:
	model = MinifigModel.new()
	model.is_jo = is_jo
	add_child(model)

func _apply_character_stats() -> void:
	if is_jo:
		move_speed = 8.5
		jump_velocity = 9.5
		magnet_radius = 8.0 # Wide magnet range
	else:
		move_speed = 7.5
		jump_velocity = 8.0
		magnet_radius = 4.5 # Standard magnet
	if is_instance_valid(model):
		model.apply_character_identity(is_jo)
	character_swapped.emit(is_jo)
	health_changed.emit(current_hearts, max_hearts)

func swap_character() -> void:
	is_jo = not is_jo
	_apply_character_stats()
	# Comedic hop on swap
	if is_on_floor():
		velocity.y = 3.5

func _physics_process(delta: float) -> void:
	# Update timers
	if invulnerable_timer > 0.0:
		invulnerable_timer -= delta
		if invulnerable_timer <= 0.0:
			is_invulnerable = false
			model.visible = true
		else:
			model.visible = (int(invulnerable_timer * 15.0) % 2 == 0) # Flash
			
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
		
	if charge_timer > 0.0:
		charge_timer -= delta
		if charge_timer <= 0.0:
			is_shoulder_charging = false
			model.is_charging = false

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
		# Jo flutter jump in air
		if is_jo and (Input.is_action_pressed("jump") or touch_jump_pressed) and velocity.y < 0.0:
			velocity.y += gravity * 0.45 * delta # Gliding flutter
			
	# Input reading
	var input_dir = Vector2.ZERO
	if touch_move_vector.length_squared() > 0.01:
		input_dir = touch_move_vector
	else:
		input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		
	var cam = get_viewport().get_camera_3d()
	var move_dir = Vector3.ZERO
	if is_instance_valid(cam):
		var cam_forward = -cam.global_transform.basis.z
		cam_forward.y = 0.0
		cam_forward = cam_forward.normalized()
		var cam_right = cam.global_transform.basis.x
		cam_right.y = 0.0
		cam_right = cam_right.normalized()
		move_dir = (cam_right * input_dir.x + cam_forward * -input_dir.y).normalized()
	else:
		move_dir = Vector3(input_dir.x, 0, input_dir.y).normalized()

	# Movement execution
	var current_speed = move_speed
	if is_shoulder_charging:
		current_speed *= 1.6
		
	if move_dir.length_squared() > 0.01:
		velocity.x = move_dir.x * current_speed
		velocity.z = move_dir.z * current_speed
		
		# Smooth face movement direction
		var target_rot = atan2(move_dir.x, move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot, delta * 14.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, current_speed * 8.0 * delta)

	# Jump
	if (Input.is_action_just_pressed("jump") or touch_jump_pressed) and is_on_floor():
		velocity.y = jump_velocity
		touch_jump_pressed = false

	# Smash / Punch / Bash
	if (Input.is_action_just_pressed("smash") or touch_smash_pressed) and attack_cooldown <= 0.0:
		perform_attack()
		touch_smash_pressed = false

	# Character Swap
	if Input.is_action_just_pressed("swap_character"):
		swap_character()

	# Build
	is_building = Input.is_action_pressed("build") or touch_build_held
	if is_building:
		_perform_build_scan(delta)

	move_and_slide()

	# Update model animations
	var is_moving = (Vector2(velocity.x, velocity.z).length() > 0.5)
	model.update_animation(delta, is_moving, current_speed)

	# Update stud vacuum
	var economy = get_tree().root.find_child("StudField", true, false) as StudField
	if is_instance_valid(economy):
		economy.update_magnet(self, magnet_radius)

func perform_attack() -> void:
	attack_cooldown = 0.28
	model.trigger_punch()
	
	if not is_jo and (Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down") or Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") or touch_move_vector.length_squared() > 0.2):
		# Bill initiates shoulder bash!
		is_shoulder_charging = true
		charge_timer = 0.6
		model.is_charging = true
	
	# Check for breakables in front
	var punch_origin = global_position + Vector3(0, 0.5, 0)
	var forward = -global_transform.basis.z
	var punch_radius = 1.8 if not is_shoulder_charging else 2.5
	
	var breakables = get_tree().get_nodes_in_group("destructible")
	for b in breakables:
		if b is Node3D and is_instance_valid(b):
			var dist = punch_origin.distance_to(b.global_position)
			if dist <= punch_radius:
				if b.has_method("smash"):
					b.smash(forward, 10.0 if not is_shoulder_charging else 22.0)

func _perform_build_scan(delta: float) -> void:
	var build_piles = get_tree().get_nodes_in_group("build_pile")
	for p in build_piles:
		if is_instance_valid(p) and p.has_method("assemble_step"):
			if global_position.distance_to(p.global_position) < 4.0:
				p.assemble_step(delta)

func take_damage(amount: int = 1) -> void:
	if is_invulnerable:
		return
		
	current_hearts = max(0, current_hearts - amount)
	health_changed.emit(current_hearts, max_hearts)
	
	var synth = SoundSynthesizer.get_instance()
	if is_instance_valid(synth):
		synth.play_heart_loss()
		
	# Drop stud toll
	var economy = get_tree().root.find_child("StudField", true, false) as StudField
	if is_instance_valid(economy):
		economy.spawn_stud_burst(global_position, 3, 0, 0)
		
	if current_hearts <= 0:
		# Comedic pop & rebuild
		is_invulnerable = true
		invulnerable_timer = 2.0
		model.trigger_pop_apart()
		await get_tree().create_timer(1.0).timeout
		current_hearts = max_hearts
		health_changed.emit(current_hearts, max_hearts)
	else:
		is_invulnerable = true
		invulnerable_timer = 1.2
