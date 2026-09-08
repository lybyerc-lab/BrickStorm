# @brickstorm.system building
# @brickstorm.role Base contract for LEGO-style scattered-part rebuildables, rewards, completion events, and optional post-build utility interactions.
# @brickstorm.scope runtime
# @brickstorm.risk medium
# @brickstorm.contract build_animation,brick_element_build_order,usable_buildables,contextual_tool_requirements
# @brickstorm.north_star lego_twister
# @brickstorm.owner openai/brickstorm

class_name BuildableObject
extends InteractableArea

signal build_completed(buildable: Node3D)

@export_category("Build Interaction")
@export var stud_reward: int = 150
@export var build_duration: float = 0.72
@export var activation_radius: float = 2.8
@export var completion_message: String = "BUILD COMPLETE"

@export_category("Post-Build Utility")
@export var post_build_usable: bool = false
@export var post_build_prompt: String = "USE"
@export var required_tool_id: StringName = &""
@export var required_tool_display_name: String = ""
@export var use_cooldown: float = 0.0

var built: bool = false
var building: bool = false
var _parts: Array[Node3D] = []
var _target_positions: Array[Vector3] = []
var _target_rotations: Array[Vector3] = []
var _build_orders: Array[int] = []
var _next_use_msec: int = 0

func _ready() -> void:
	interaction_priority = 7
	add_to_group(GameConstants.GROUP_BUILDABLE)
	super._ready()
	_add_interaction_shape()
	build_blueprint()

func build_blueprint() -> void:
	pass

func add_build_brick(scattered_position: Vector3, target_position: Vector3, size_value: Vector3, color: Color, scattered_rotation: Vector3 = Vector3.ZERO, target_rotation: Vector3 = Vector3.ZERO) -> Node3D:
	var part: Node3D = Node3D.new()
	part.name = "BuildPart_%02d" % _parts.size()
	part.position = scattered_position
	part.rotation_degrees = scattered_rotation
	add_child(part)
	PrimitiveFactory.add_box_mesh(part, Vector3.ZERO, size_value, color, "Body")
	_add_studs(part, size_value, color)
	_parts.append(part)
	_target_positions.append(target_position)
	_target_rotations.append(target_rotation)
	_build_orders.append(_parts.size() - 1)
	return part

func add_build_element(spec: BrickElementSpec, scattered_position: Vector3, scattered_rotation: Vector3 = Vector3.ZERO) -> Node3D:
	var render_spec: BrickElementSpec = spec.duplicate_spec()
	var target_position: Vector3 = spec.position
	var target_rotation: Vector3 = spec.rotation_degrees
	render_spec.position = scattered_position
	render_spec.rotation_degrees = scattered_rotation
	var part: Node3D = BrickBuilder.add_element(self, render_spec, "BuildElement_%02d" % _parts.size())
	_parts.append(part)
	_target_positions.append(target_position)
	_target_rotations.append(target_rotation)
	_build_orders.append(maxi(0, spec.build_order))
	return part

func can_interact(actor: Node3D) -> bool:
	if building:
		return false
	if built:
		return post_build_usable and super.can_interact(actor)
	return super.can_interact(actor)

func get_prompt(actor: Node3D) -> String:
	if not built:
		return prompt_text
	if not _actor_has_required_tool(actor):
		var tool_name: String = required_tool_display_name.strip_edges()
		if tool_name.is_empty():
			tool_name = String(required_tool_id).replace("_", " ").to_upper()
		return "NEEDS " + tool_name
	return post_build_prompt

func interact(actor: Node3D) -> void:
	if building:
		return
	if built:
		_try_use_built(actor)
		return
	building = true
	remove_from_group(GameConstants.GROUP_INTERACTABLE)
	GameEvents.context_prompt_changed.emit("")
	GameEvents.toast_requested.emit("BUILDING...")
	var build_tween: Tween = create_tween()
	build_tween.set_parallel(true)
	for part_index in range(_parts.size()):
		var part_delay: float = float(_build_orders[part_index]) * 0.035
		build_tween.tween_property(_parts[part_index], "position", _target_positions[part_index], build_duration).set_delay(part_delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		build_tween.tween_property(_parts[part_index], "rotation_degrees", _target_rotations[part_index], build_duration * 0.82).set_delay(part_delay)
	build_tween.finished.connect(_finish_build)

func use_built_object(_actor: Node3D) -> void:
	pass

func _finish_build() -> void:
	building = false
	built = true
	GameManager.add_studs(stud_reward)
	GameEvents.toast_requested.emit(completion_message)
	GameEvents.camera_shake_requested.emit(0.16, 0.18)
	GameEvents.build_completed.emit(self)
	build_completed.emit(self)
	if post_build_usable:
		add_to_group(GameConstants.GROUP_INTERACTABLE)

func _try_use_built(actor: Node3D) -> void:
	if not post_build_usable:
		return
	if not _actor_has_required_tool(actor):
		var tool_name: String = required_tool_display_name.strip_edges()
		if tool_name.is_empty():
			tool_name = String(required_tool_id).replace("_", " ").to_upper()
		GameEvents.toast_requested.emit("FIND A " + tool_name)
		return
	var now_msec: int = Time.get_ticks_msec()
	if now_msec < _next_use_msec:
		GameEvents.toast_requested.emit("READYING...")
		return
	if actor != null and not required_tool_id.is_empty() and actor.has_method("play_tool_use"):
		actor.call("play_tool_use", required_tool_id)
	use_built_object(actor)
	_next_use_msec = now_msec + int(maxf(0.0, use_cooldown) * 1000.0)

func _actor_has_required_tool(actor: Node3D) -> bool:
	if required_tool_id.is_empty():
		return true
	if actor == null or not actor.has_method("has_tool"):
		return false
	return bool(actor.call("has_tool", required_tool_id))

func _add_interaction_shape() -> void:
	var collision: CollisionShape3D = CollisionShape3D.new()
	var interaction_shape: SphereShape3D = SphereShape3D.new()
	interaction_shape.radius = activation_radius
	collision.shape = interaction_shape
	collision.position.y = 0.9
	add_child(collision)

func _add_studs(parent: Node3D, size_value: Vector3, color: Color) -> void:
	if size_value.x < 0.42 or size_value.z < 0.42:
		return
	var stud_radius: float = minf(size_value.x, size_value.z) * 0.15
	var stud_height: float = minf(0.11, size_value.y * 0.20)
	var x_count: int = 2 if size_value.x > 1.0 else 1
	var z_count: int = 2 if size_value.z > 1.0 else 1
	for x_index in range(x_count):
		for z_index in range(z_count):
			var stud_x: float = 0.0 if x_count == 1 else lerpf(-size_value.x * 0.24, size_value.x * 0.24, float(x_index))
			var stud_z: float = 0.0 if z_count == 1 else lerpf(-size_value.z * 0.24, size_value.z * 0.24, float(z_index))
			PrimitiveFactory.add_cylinder_mesh(parent, Vector3(stud_x, size_value.y * 0.5 + stud_height * 0.5, stud_z), stud_radius, stud_height, color, "Stud", 10, false)
