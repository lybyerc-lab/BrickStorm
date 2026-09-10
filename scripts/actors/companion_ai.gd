extends CharacterBody3D
class_name CompanionAI

const MinifigModel = preload("res://scripts/actors/minifig_model.gd")
const MinifigCharacter = preload("res://scripts/actors/minifig_character.gd")

var is_jo: bool = false # Bill by default when Jo is player
var target_player: MinifigCharacter
var model: MinifigModel
var collision_shape: CollisionShape3D

var gravity: float = 22.0
var move_speed: float = 8.0
var follow_distance: float = 2.4

var attack_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("companion")
	_setup_collision()
	_setup_model()

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

func apply_companion_identity(jo: bool) -> void:
	is_jo = jo
	if is_instance_valid(model):
		model.apply_character_identity(is_jo)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target_player):
		target_player = get_tree().root.find_child("MinifigCharacter", true, false) as MinifigCharacter
		if not is_instance_valid(target_player):
			return

	# Match companion identity to be opposite of active player
	if is_jo == target_player.is_jo:
		apply_companion_identity(not target_player.is_jo)

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# AI Follow behavior: stay slightly behind and to the right of player
	var follow_offset = target_player.global_transform.basis * Vector3(1.8, 0, 1.6)
	var target_dest = target_player.global_position + follow_offset
	var diff = target_dest - global_position
	diff.y = 0.0
	var dist = diff.length()

	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	if dist > follow_distance:
		var dir = diff.normalized()
		var speed = move_speed if dist < 6.0 else move_speed * 1.5
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		
		var target_rot = atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot, delta * 12.0)
		
		# Auto jump over low obstacles
		if is_on_wall() and is_on_floor():
			velocity.y = 7.5
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 8.0 * delta)
		# Face player when idle
		var to_player = target_player.global_position - global_position
		to_player.y = 0.0
		if to_player.length_squared() > 0.01:
			rotation.y = lerp_angle(rotation.y, atan2(to_player.x, to_player.z), delta * 6.0)

	# Assist smashing nearby destructibles
	if attack_cooldown <= 0.0 and dist < 5.0:
		_check_smash_assist()

	move_and_slide()

	# Update animation
	var is_moving = Vector2(velocity.x, velocity.z).length() > 0.5
	model.update_animation(delta, is_moving, move_speed)

func _check_smash_assist() -> void:
	var breakables = get_tree().get_nodes_in_group("destructible")
	for b in breakables:
		if b is Node3D and is_instance_valid(b):
			var d = global_position.distance_to(b.global_position)
			if d <= 1.8:
				attack_cooldown = 1.0
				model.trigger_punch()
				if b.has_method("smash"):
					b.smash((b.global_position - global_position).normalized(), 8.0)
				break
