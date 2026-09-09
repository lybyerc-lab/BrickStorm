# @brickstorm.system actors
# @brickstorm.role Owns the original brick-toy chaser silhouette, authored locomotion poses, rigid hinge limbs, carried tools, landing response, and action animation.
# @brickstorm.scope runtime
# @brickstorm.risk medium
# @brickstorm.contract avatar_visual,lego_locomotion,authored_locomotion_states,visible_carried_tools
# @brickstorm.north_star classic_lego_movement
# @brickstorm.owner openai/brickstorm

class_name BrickChaserVisual
extends Node3D

signal action_event(event_id: StringName)

enum LocomotionState {
	IDLE,
	START,
	RUN,
	PIVOT,
	AIR,
	LAND,
}

var torso_root: Node3D
var head_root: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var _stride_phase: float = 0.0
var _state: LocomotionState = LocomotionState.IDLE
var _state_time: float = 0.0
var _was_moving: bool = false
var _was_on_floor: bool = true
var _tool_visuals: Dictionary = {}
var action_profile: ActionAnimationProfile

func build() -> void:
	name = "BrickChaserVisual"
	if action_profile == null:
		action_profile = ActionAnimationProfile.new()
	var shirt_color: Color = Color(0.96, 0.55, 0.08)
	var shirt_detail: Color = Color(0.08, 0.26, 0.42)
	var pants_color: Color = Color(0.10, 0.23, 0.34)
	var skin_color: Color = Color(0.91, 0.70, 0.48)
	var cap_color: Color = Color(0.06, 0.18, 0.30)
	var face_color: Color = Color(0.055, 0.045, 0.035)

	torso_root = Node3D.new()
	torso_root.name = "TorsoRoot"
	add_child(torso_root)
	PrimitiveFactory.add_box_mesh(torso_root, Vector3(0.0, 1.54, 0.0), Vector3(1.08, 0.50, 0.58), shirt_color, "UpperTorso")
	PrimitiveFactory.add_box_mesh(torso_root, Vector3(0.0, 1.18, 0.0), Vector3(0.76, 0.32, 0.50), shirt_color, "LowerTorso")
	PrimitiveFactory.add_box_mesh(torso_root, Vector3(0.0, 1.43, 0.306), Vector3(0.50, 0.16, 0.025), shirt_detail, "StormVestStripe", false)
	PrimitiveFactory.add_box_mesh(torso_root, Vector3(0.0, 0.96, 0.0), Vector3(0.78, 0.18, 0.50), pants_color, "Hips")
	PrimitiveFactory.add_box_mesh(torso_root, Vector3(0.0, 0.99, 0.268), Vector3(0.60, 0.08, 0.025), BrickPalette.BLACK, "Belt", false)

	head_root = Node3D.new()
	head_root.name = "HeadPivot"
	head_root.position = Vector3(0.0, 2.14, 0.0)
	torso_root.add_child(head_root)
	PrimitiveFactory.add_cylinder_mesh(head_root, Vector3.ZERO, 0.38, 0.58, skin_color, "Head", 16)
	PrimitiveFactory.add_cylinder_mesh(head_root, Vector3(0.0, 0.36, 0.0), 0.40, 0.16, cap_color, "Cap", 16)
	PrimitiveFactory.add_box_mesh(head_root, Vector3(0.0, 0.32, 0.30), Vector3(0.54, 0.08, 0.34), cap_color, "CapBrim")

	var eye_left: MeshInstance3D = PrimitiveFactory.add_cylinder_mesh(head_root, Vector3(-0.13, 0.07, 0.365), 0.035, 0.035, face_color, "LeftEye", 8, false)
	eye_left.rotation_degrees.x = 90.0
	var eye_right: MeshInstance3D = PrimitiveFactory.add_cylinder_mesh(head_root, Vector3(0.13, 0.07, 0.365), 0.035, 0.035, face_color, "RightEye", 8, false)
	eye_right.rotation_degrees.x = 90.0
	PrimitiveFactory.add_box_mesh(head_root, Vector3(0.0, -0.11, 0.374), Vector3(0.18, 0.035, 0.025), face_color, "Smile")

	left_arm = _build_arm(Vector3(-0.62, 1.72, 0.0), shirt_color, skin_color, "LeftArm")
	right_arm = _build_arm(Vector3(0.62, 1.72, 0.0), shirt_color, skin_color, "RightArm")
	left_leg = _build_leg(Vector3(-0.23, 0.89, 0.0), pants_color, "LeftLeg")
	right_leg = _build_leg(Vector3(0.23, 0.89, 0.0), pants_color, "RightLeg")

func add_tool(tool_id: StringName) -> void:
	if _tool_visuals.has(tool_id):
		return
	if tool_id == GameConstants.TOOL_WRENCH:
		_build_wrench_carried_visual()
	elif tool_id == GameConstants.TOOL_PRY_BAR:
		_build_pry_bar_carried_visual()

func play_tool_use(tool_id: StringName) -> void:
	if not _tool_visuals.has(tool_id):
		return
	var tool: Node3D = _tool_visuals[tool_id] as Node3D
	if not is_instance_valid(tool):
		return
	var original_position: Vector3 = tool.position
	var original_rotation: Vector3 = tool.rotation_degrees
	var use_position: Vector3 = Vector3(0.72, 1.32, 0.42)
	var use_rotation: Vector3 = Vector3(0.0, 0.0, -58.0)
	if tool_id == GameConstants.TOOL_PRY_BAR:
		use_position = Vector3(0.72, 1.08, 0.46)
		use_rotation = Vector3(12.0, 0.0, -82.0)
	var tool_tween: Tween = create_tween()
	tool_tween.tween_property(tool, "position", use_position, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tool_tween.parallel().tween_property(tool, "rotation_degrees", use_rotation, 0.10)
	tool_tween.tween_property(tool, "rotation_degrees:z", use_rotation.z + 44.0, 0.12)
	tool_tween.tween_property(tool, "rotation_degrees", original_rotation, 0.13).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tool_tween.parallel().tween_property(tool, "position", original_position, 0.13)
	if right_arm != null:
		var arm_tween: Tween = create_tween()
		arm_tween.tween_property(right_arm, "rotation:x", -1.35, 0.10)
		arm_tween.tween_property(right_arm, "rotation:x", -0.18, 0.20)
	if action_profile != null and not action_profile.tool_contact_event_id.is_empty():
		var contact_timer: SceneTreeTimer = get_tree().create_timer(maxf(0.0, action_profile.tool_contact_delay))
		contact_timer.timeout.connect(_emit_action_event.bind(action_profile.tool_contact_event_id))

func update_locomotion(delta: float, horizontal_speed: float, move_speed: float, on_floor: bool, smash_cooldown: float, landing_pulse: float, pivot_pulse: float) -> void:
	var movement_amount: float = clampf(horizontal_speed / maxf(move_speed, 0.01), 0.0, 1.0)
	var moving: bool = movement_amount > 0.045
	var next_state: LocomotionState = _state
	if not on_floor:
		next_state = LocomotionState.AIR
	elif landing_pulse > 0.42 and not _was_on_floor:
		next_state = LocomotionState.LAND
	elif pivot_pulse > 0.20 and moving:
		next_state = LocomotionState.PIVOT
	elif moving and not _was_moving:
		next_state = LocomotionState.START
	elif moving:
		if _state == LocomotionState.START and _state_time < _get_start_hold_seconds():
			next_state = LocomotionState.START
		elif _state == LocomotionState.PIVOT and _state_time < _get_pivot_hold_seconds():
			next_state = LocomotionState.PIVOT
		else:
			next_state = LocomotionState.RUN
	else:
		if _state == LocomotionState.LAND and _state_time < _get_land_hold_seconds():
			next_state = LocomotionState.LAND
		else:
			next_state = LocomotionState.IDLE

	if next_state != _state:
		_state = next_state
		_state_time = 0.0
		_emit_state_event(_state)
	else:
		_state_time += delta

	if on_floor and moving and _state == LocomotionState.RUN:
		var previous_phase: float = _stride_phase
		_stride_phase += horizontal_speed * delta * _get_stride_phase_rate()
		_emit_footstep_events(previous_phase, _stride_phase)

	var return_weight: float = minf(1.0, delta * _get_pose_return_rate())
	match _state:
		LocomotionState.IDLE:
			_pose_idle(return_weight)
		LocomotionState.START:
			_pose_start(return_weight, movement_amount)
		LocomotionState.RUN:
			_pose_run(return_weight, movement_amount, smash_cooldown)
		LocomotionState.PIVOT:
			_pose_pivot(return_weight, pivot_pulse)
		LocomotionState.AIR:
			_pose_air(return_weight, smash_cooldown)
		LocomotionState.LAND:
			_pose_land(return_weight, landing_pulse)

	_was_moving = moving
	_was_on_floor = on_floor

func animate_smash() -> void:
	if right_arm == null:
		return
	var smash_tween: Tween = create_tween()
	smash_tween.tween_property(torso_root, "rotation:y", -0.18, 0.07)
	smash_tween.parallel().tween_property(right_arm, "rotation:x", -1.85, 0.08)
	smash_tween.tween_property(torso_root, "rotation:y", 0.24, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	smash_tween.parallel().tween_property(right_arm, "rotation:x", 0.30, 0.10)
	smash_tween.tween_property(torso_root, "rotation:y", 0.0, 0.10)
	smash_tween.parallel().tween_property(right_arm, "rotation:x", 0.0, 0.10)
	if action_profile != null and not action_profile.smash_contact_event_id.is_empty():
		var contact_timer: SceneTreeTimer = get_tree().create_timer(maxf(0.0, action_profile.smash_contact_delay))
		contact_timer.timeout.connect(_emit_action_event.bind(action_profile.smash_contact_event_id))

func set_action_profile(profile: ActionAnimationProfile) -> void:
	action_profile = profile if profile != null else ActionAnimationProfile.new()

func _get_start_hold_seconds() -> float:
	return maxf(0.0, action_profile.start_hold_seconds) if action_profile != null else 0.12

func _get_pivot_hold_seconds() -> float:
	return maxf(0.0, action_profile.pivot_hold_seconds) if action_profile != null else 0.10

func _get_land_hold_seconds() -> float:
	return maxf(0.0, action_profile.land_hold_seconds) if action_profile != null else 0.12

func _get_pose_return_rate() -> float:
	return maxf(0.01, action_profile.pose_return_rate) if action_profile != null else 22.0

func _get_stride_phase_rate() -> float:
	return maxf(0.01, action_profile.stride_phase_rate) if action_profile != null else 2.05

func _emit_state_event(state: LocomotionState) -> void:
	if action_profile == null:
		return
	if state == LocomotionState.LAND and not action_profile.landing_event_id.is_empty():
		_emit_action_event(action_profile.landing_event_id)
	elif state == LocomotionState.PIVOT and not action_profile.pivot_event_id.is_empty():
		_emit_action_event(action_profile.pivot_event_id)

func _emit_footstep_events(previous_phase: float, current_phase: float) -> void:
	if action_profile == null or action_profile.footstep_event_id.is_empty():
		return
	var phase_step: float = action_profile.get_safe_footstep_phase_step()
	var previous_index: int = floori(previous_phase / phase_step)
	var current_index: int = floori(current_phase / phase_step)
	if current_index != previous_index:
		_emit_action_event(action_profile.footstep_event_id)

func _emit_action_event(event_id: StringName) -> void:
	if not event_id.is_empty():
		action_event.emit(event_id)

func _pose_idle(weight: float) -> void:
	var idle: float = sin(Time.get_ticks_msec() * 0.0024)
	_set_leg_pose(0.03, -0.03, weight)
	_set_arm_pose(-0.08 + idle * 0.025, 0.08 - idle * 0.025, weight)
	position.y = lerpf(position.y, idle * 0.008, weight)
	scale = scale.lerp(Vector3.ONE, weight)
	if torso_root != null:
		torso_root.rotation.x = lerpf(torso_root.rotation.x, 0.0, weight)
		torso_root.rotation.z = lerpf(torso_root.rotation.z, idle * 0.008, weight)
	if head_root != null:
		head_root.rotation.y = lerpf(head_root.rotation.y, idle * 0.035, weight)

func _pose_start(weight: float, movement_amount: float) -> void:
	var punch: float = clampf(_state_time / 0.105, 0.0, 1.0)
	var planted: float = sin(punch * PI * 0.72)
	_set_leg_pose(-0.66 * planted * movement_amount, 0.40 * planted * movement_amount, weight)
	_set_arm_pose(0.52 * planted, -0.60 * planted, weight)
	position.y = lerpf(position.y, -0.025 + planted * 0.035, weight)
	if torso_root != null:
		torso_root.rotation.x = lerpf(torso_root.rotation.x, -0.12 * planted, weight)
		torso_root.rotation.z = lerpf(torso_root.rotation.z, 0.03 * planted, weight)

func _pose_run(weight: float, movement_amount: float, smash_cooldown: float) -> void:
	var raw_stride: float = sin(_stride_phase)
	var hinge_stride: float = signf(raw_stride) * pow(absf(raw_stride), 0.72)
	var stride_amount: float = 0.78 * movement_amount
	var arm_amount: float = 0.62 * movement_amount
	_set_leg_pose(hinge_stride * stride_amount, -hinge_stride * stride_amount, weight)
	if smash_cooldown <= 0.26:
		_set_arm_pose(-hinge_stride * arm_amount, hinge_stride * arm_amount, weight)
	var heel_snap: float = absf(sin(_stride_phase * 2.0))
	position.y = lerpf(position.y, heel_snap * 0.028 * movement_amount, weight)
	scale = scale.lerp(Vector3.ONE, weight)
	if torso_root != null:
		torso_root.rotation.x = lerpf(torso_root.rotation.x, -0.055 * movement_amount, weight)
		torso_root.rotation.z = lerpf(torso_root.rotation.z, -hinge_stride * 0.022 * movement_amount, weight)
	if head_root != null:
		head_root.rotation.y = lerpf(head_root.rotation.y, hinge_stride * 0.018, weight)

func _pose_pivot(weight: float, pivot_pulse: float) -> void:
	var side: float = -1.0 if sin(_stride_phase) < 0.0 else 1.0
	_set_leg_pose(0.50 * side, -0.34 * side, weight)
	_set_arm_pose(-0.34 * side, 0.48 * side, weight)
	position.y = lerpf(position.y, -0.045, weight)
	if torso_root != null:
		torso_root.rotation.z = lerpf(torso_root.rotation.z, 0.13 * side * clampf(pivot_pulse, 0.0, 1.0), weight)
		torso_root.rotation.x = lerpf(torso_root.rotation.x, -0.04, weight)
	if head_root != null:
		head_root.rotation.y = lerpf(head_root.rotation.y, -0.20 * side, weight)

func _pose_air(weight: float, smash_cooldown: float) -> void:
	_set_leg_pose(-0.25, 0.22, weight)
	if smash_cooldown <= 0.26:
		_set_arm_pose(-0.52, -0.38, weight)
	position.y = lerpf(position.y, 0.02, weight)
	scale = scale.lerp(Vector3.ONE, weight)
	if torso_root != null:
		torso_root.rotation.x = lerpf(torso_root.rotation.x, 0.05, weight)
	if head_root != null:
		head_root.rotation.y = lerpf(head_root.rotation.y, 0.0, weight)

func _pose_land(weight: float, landing_pulse: float) -> void:
	var squash: float = clampf(landing_pulse, 0.0, 1.0)
	_set_leg_pose(0.22, -0.16, weight)
	_set_arm_pose(0.26, 0.18, weight)
	position.y = lerpf(position.y, -0.11 * squash, weight)
	scale = scale.lerp(Vector3(1.0 + squash * 0.09, 1.0 - squash * 0.14, 1.0 + squash * 0.09), weight)
	if torso_root != null:
		torso_root.rotation.x = lerpf(torso_root.rotation.x, 0.09 * squash, weight)

func _set_leg_pose(left_x: float, right_x: float, weight: float) -> void:
	if left_leg != null:
		left_leg.rotation.x = lerpf(left_leg.rotation.x, left_x, weight)
	if right_leg != null:
		right_leg.rotation.x = lerpf(right_leg.rotation.x, right_x, weight)

func _set_arm_pose(left_x: float, right_x: float, weight: float) -> void:
	if left_arm != null:
		left_arm.rotation.x = lerpf(left_arm.rotation.x, left_x, weight)
	if right_arm != null:
		right_arm.rotation.x = lerpf(right_arm.rotation.x, right_x, weight)

func _build_arm(anchor: Vector3, sleeve_color: Color, hand_color: Color, node_name: String) -> Node3D:
	var arm: Node3D = Node3D.new()
	arm.name = node_name + "Pivot"
	arm.position = anchor
	add_child(arm)
	PrimitiveFactory.add_sphere_mesh(arm, Vector3(0.0, -0.08, 0.0), 0.18, sleeve_color, node_name + "Shoulder")
	PrimitiveFactory.add_cylinder_mesh(arm, Vector3(0.0, -0.36, 0.0), 0.15, 0.60, sleeve_color, node_name, 12)
	PrimitiveFactory.add_cylinder_mesh(arm, Vector3(0.0, -0.72, 0.0), 0.17, 0.22, hand_color, node_name + "Hand", 12)
	PrimitiveFactory.add_box_mesh(arm, Vector3(0.0, -0.76, 0.10), Vector3(0.20, 0.12, 0.23), hand_color, node_name + "Grip", false)
	return arm

func _build_leg(anchor: Vector3, pants_color: Color, node_name: String) -> Node3D:
	var leg: Node3D = Node3D.new()
	leg.name = node_name + "Pivot"
	leg.position = anchor
	add_child(leg)
	PrimitiveFactory.add_box_mesh(leg, Vector3(0.0, -0.31, 0.0), Vector3(0.34, 0.62, 0.40), pants_color, node_name)
	PrimitiveFactory.add_box_mesh(leg, Vector3(0.0, -0.67, 0.11), Vector3(0.37, 0.18, 0.60), pants_color, node_name + "Foot")
	return leg

func _build_wrench_carried_visual() -> void:
	var tool: Node3D = Node3D.new()
	tool.name = "WrenchCarriedVisual"
	tool.position = Vector3(0.58, 1.14, 0.10)
	tool.rotation_degrees = Vector3(0.0, 0.0, 32.0)
	add_child(tool)
	PrimitiveFactory.add_box_mesh(tool, Vector3(0.0, 0.16, 0.0), Vector3(0.15, 0.72, 0.12), BrickPalette.SILVER, "WrenchHandle", false)
	PrimitiveFactory.add_box_mesh(tool, Vector3(0.0, -0.25, 0.0), Vector3(0.19, 0.24, 0.15), BrickPalette.BLUE, "WrenchGrip", false)
	PrimitiveFactory.add_box_mesh(tool, Vector3(-0.14, 0.56, 0.0), Vector3(0.14, 0.34, 0.12), BrickPalette.SILVER, "WrenchJawLeft", false)
	PrimitiveFactory.add_box_mesh(tool, Vector3(0.14, 0.56, 0.0), Vector3(0.14, 0.34, 0.12), BrickPalette.SILVER, "WrenchJawRight", false)
	_tool_visuals[GameConstants.TOOL_WRENCH] = tool

func _build_pry_bar_carried_visual() -> void:
	var tool: Node3D = Node3D.new()
	tool.name = "PryBarCarriedVisual"
	tool.position = Vector3(-0.54, 1.20, -0.14)
	tool.rotation_degrees = Vector3(0.0, 0.0, -30.0)
	add_child(tool)
	PrimitiveFactory.add_box_mesh(tool, Vector3(0.0, 0.12, 0.0), Vector3(0.13, 0.92, 0.13), BrickPalette.RED, "PryBarShaft", false)
	PrimitiveFactory.add_box_mesh(tool, Vector3(0.14, -0.37, 0.0), Vector3(0.28, 0.13, 0.15), BrickPalette.DARK_GRAY, "PryBarFoot", false)
	PrimitiveFactory.add_box_mesh(tool, Vector3(-0.14, 0.61, 0.0), Vector3(0.28, 0.13, 0.15), BrickPalette.DARK_GRAY, "PryBarHook", false)
	_tool_visuals[GameConstants.TOOL_PRY_BAR] = tool
