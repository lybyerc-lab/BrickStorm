# The chaser.
#
# Two characters share one body; swapping is instant and is the core LEGO verb.
# There is no death here - only TUMBLE, which costs studs and dignity
# (Docs/GAME_CONCEPT.md §3, Design Law #2).
class_name Player
extends CharacterBody3D

signal tumbled(at: Vector3)

enum Character { JO, BILL }

const GRAVITY := 22.0
const TUMBLE_TIME := 2.2

var character: int = Character.JO
var braced: bool = false
var move_input := Vector2.ZERO
var carrying: Node3D = null
var tumble_timer: float = 0.0
var ability_timer: float = 0.0

var _rigs: Dictionary = {}
var _visual_root: Node3D = null
var _facing: float = 0.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.4

	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.42
	cap.height = 1.7
	cs.shape = cap
	cs.position = Vector3(0, 0.85, 0)
	add_child(cs)

	_visual_root = Node3D.new()
	add_child(_visual_root)

	# Jo - blue shirt, brown hair.  Bill - grey tee, dark hair.
	_rigs[Character.JO] = BrickLib.minifig(BrickLib.C_BLUE, BrickLib.C_DGREY, BrickLib.C_BROWN)
	_rigs[Character.BILL] = BrickLib.minifig(BrickLib.C_LGREY, BrickLib.C_BROWN, BrickLib.C_BLACK)
	for k in _rigs:
		_visual_root.add_child(_rigs[k])
	_apply_character()


func speed() -> float:
	return 5.8 if character == Character.BILL else 7.2


# Bill is the Extreme: he barely notices weather that flattens everyone else.
func wind_resist() -> float:
	if braced:
		return 0.10
	return 0.30 if character == Character.BILL else 1.0


func immune_to_lift() -> bool:
	return braced or character == Character.BILL


func magnet_range() -> float:
	var base := 3.6 if character == Character.BILL else 4.2
	if character == Character.JO and ability_timer > 0.0:
		base *= 2.0
	return base


func can_smash() -> bool:
	return character == Character.BILL


func set_character(c: int) -> void:
	if c == character or tumble_timer > 0.0:
		return
	character = c
	_apply_character()


func _apply_character() -> void:
	for k in _rigs:
		_rigs[k].visible = (k == character)


func use_ability() -> void:
	if character == Character.JO:
		ability_timer = 6.0        # READ THE SKY


func tumble() -> void:
	if tumble_timer > 0.0:
		return
	tumble_timer = TUMBLE_TIME
	braced = false
	tumbled.emit(global_position)


func carry(node: Node3D) -> void:
	carrying = node


func drop() -> Node3D:
	var n := carrying
	carrying = null
	return n


func _physics_process(delta: float) -> void:
	if ability_timer > 0.0:
		ability_timer -= delta

	var wind := Vector3.ZERO
	var t := get_tree().get_first_node_in_group("tornado") as Tornado
	if t != null:
		wind = t.wind_at(global_position)

	if tumble_timer > 0.0:
		_tumbling(delta)
		return

	var planar := Vector3.ZERO
	if not braced:
		planar = Vector3(move_input.x, 0.0, move_input.y) * speed()
	planar += wind * wind_resist() * 0.55

	velocity.x = planar.x
	velocity.z = planar.z
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	move_and_slide()

	var flat := Vector2(velocity.x, velocity.z)
	if flat.length() > 0.4:
		_facing = lerp_angle(_facing, atan2(velocity.x, velocity.z), 0.24)
	_visual_root.rotation = Vector3(0, _facing, 0)
	_visual_root.position = Vector3.ZERO

	# a braced minifig leans into it
	if braced and t != null:
		var into := (t.funnel_pos() - global_position).normalized()
		_visual_root.rotation.x = -0.30
		_visual_root.rotation.y = atan2(into.x, into.z)
	else:
		_visual_root.rotation.x = 0.0

	if carrying != null and is_instance_valid(carrying):
		carrying.global_position = global_position + Vector3(0, 1.25, 0) \
			+ Vector3(sin(_facing), 0, cos(_facing)) * 0.75


# Picked up, spun, and set back down. Nobody is ever destroyed.
func _tumbling(delta: float) -> void:
	tumble_timer -= delta
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	velocity.x = lerpf(velocity.x, 0.0, delta * 1.2)
	velocity.z = lerpf(velocity.z, 0.0, delta * 1.2)
	move_and_slide()
	_visual_root.rotation.y += delta * 13.0
	_visual_root.rotation.x = sin(tumble_timer * 9.0) * 0.9
	_visual_root.position.y = maxf(0.0, sin((TUMBLE_TIME - tumble_timer) * 2.4) * 1.4)
	if tumble_timer <= 0.0:
		_visual_root.rotation.x = 0.0
		_visual_root.position.y = 0.0


func launch(dir: Vector3, force: float) -> void:
	velocity = dir.normalized() * force + Vector3.UP * force * 0.55
