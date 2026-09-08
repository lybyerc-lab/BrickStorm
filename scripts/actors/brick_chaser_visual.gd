# @brickstorm.system actors
# @brickstorm.role Owns the original brick-toy chaser mesh, rigid hinge locomotion, landing response, carried-tool visuals, and tool/smash animation.
# @brickstorm.scope runtime
# @brickstorm.risk medium
# @brickstorm.contract avatar_visual,lego_locomotion,visible_carried_tools
# @brickstorm.north_star classic_lego_movement
# @brickstorm.owner openai/brickstorm

class_name BrickChaserVisual
extends Node3D

var torso_root: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var _stride_phase: float = 0.0
var _tool_visuals: Dictionary = {}

func build() -> void:
	name = "BrickChaserVisual"
	var shirt_color: Color = Color(0.96, 0.55, 0.08)
	var shirt_detail: Color = Color(0.08, 0.26, 0.42)
	var pants_color: Color = Color(0.10, 0.23, 0.34)
	var skin_color: Color = Color(0.91, 0.70, 0.48)
	var cap_color: Color = Color(0.06, 0.18, 0.30)
	var face_color: Color = Color(0.055, 0.045, 0.035)

	torso_root = Node3D.new()
	torso_root.name = "TorsoRoot"
	add_child(torso_root)
	PrimitiveFactory.add_box_mesh(torso_root, Vector3(0.0, 1.52, 0.0), Vector3(0.98, 0.48, 0.54), shirt_color, "UpperTorso")
	PrimitiveFactory.add_box_mesh(torso_root, Vector3(0.0, 1.17, 0.0), Vector3(0.80, 0.34, 0.50), shirt_color, "LowerTorso")
	PrimitiveFactory.add_box_mesh(torso_root, Vector3(0.0, 1.42, 0.286), Vector3(0.46, 0.16, 0.025), shirt_detail, "StormVestStripe", false)
	PrimitiveFactory.add_box_mesh(torso_root, Vector3(0.0, 0.94, 0.0), Vector3(0.76, 0.18, 0.48), pants_color, "Hips")
	PrimitiveFactory.add_box_mesh(torso_root, Vector3(0.0, 0.98, 0.258), Vector3(0.58, 0.08, 0.025), BrickPalette.BLACK, "Belt", false)
	PrimitiveFactory.add_cylinder_mesh(torso_root, Vector3(0.0, 2.15, 0.0), 0.38, 0.58, skin_color, "Head", 16)
	PrimitiveFactory.add_cylinder_mesh(torso_root, Vector3(0.0, 2.51, 0.0), 0.40, 0.16, cap_color, "Cap", 16)
	PrimitiveFactory.add_box_mesh(torso_root, Vector3(0.0, 2.47, 0.30), Vector3(0.54, 0.08, 0.34), cap_color, "CapBrim")

	var eye_left: MeshInstance3D = PrimitiveFactory.add_cylinder_mesh(torso_root, Vector3(-0.13, 2.22, 0.365), 0.035, 0.035, face_color, "LeftEye", 8, false)
	eye_left.rotation_degrees.x = 90.0
	var eye_right: MeshInstance3D = PrimitiveFactory.add_cylinder_mesh(torso_root, Vector3(0.13, 2.22, 0.365), 0.035, 0.035, face_color, "RightEye", 8, false)
	eye_right.rotation_degrees.x = 90.0
	PrimitiveFactory.add_box_mesh(torso_root, Vector3(0.0, 2.04, 0.374), Vector3(0.18, 0.035, 0.025), face_color, "Smile")

	left_arm = _build_arm(Vector3(-0.61, 1.70, 0.0), shirt_color, skin_color, "LeftArm")
	right_arm = _build_arm(Vector3(0.61, 1.70, 0.0), shirt_color, skin_color, "RightArm")
	left_leg = _build_leg(Vector3(-0.23, 0.88, 0.0), pants_color, "LeftLeg")
	right_leg = _build_leg(Vector3(0.23, 0.88, 0.0), pants_color, "RightLeg")

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

func update_locomotion(delta: float, horizontal_speed: float, move_speed: float, on_floor: bool, smash_cooldown: float, landing_pulse: float, pivot_pulse: float) -> void:
	var movement_amount: float = clampf(horizontal_speed / maxf(move_speed, 0.01), 0.0, 1.0)
	if on_floor and movement_amount > 0.04:
		_stride_phase += horizontal_speed * delta * 2.25
	var stride: float = sin(_stride_phase)
	var stride_amount: float = 0.74 * movement_amount
	var arm_amount: float = 0.58 * movement_amount
	var return_weight: float = minf(1.0, delta * 18.0)

	if not on_floor:
		left_leg.rotation.x = lerpf(left_leg.rotation.x, -0.20, return_weight)
		right_leg.rotation.x = lerpf(right_leg.rotation.x, 0.18, return_weight)
		if smash_cooldown <= 0.26:
			left_arm.rotation.x = lerpf(left_arm.rotation.x, -0.38, return_weight)
			right_arm.rotation.x = lerpf(right_arm.rotation.x, -0.30, return_weight)
	else:
		left_leg.rotation.x = lerpf(left_leg.rotation.x, stride * stride_amount, return_weight)
		right_leg.rotation.x = lerpf(right_leg.rotation.x, -stride * stride_amount, return_weight)
		if smash_cooldown <= 0.26:
			left_arm.rotation.x = lerpf(left_arm.rotation.x, -stride * arm_amount, return_weight)
			right_arm.rotation.x = lerpf(right_arm.rotation.x, stride * arm_amount, return_weight)

	var step_bob: float = absf(sin(_stride_phase * 2.0)) * 0.022 * movement_amount
	var landing_squash: float = landing_pulse * 0.10
	position.y = step_bob - landing_squash
	scale = Vector3(1.0 + landing_squash * 0.22, 1.0 - landing_squash, 1.0 + landing_squash * 0.22)
	if torso_root != null:
		torso_root.rotation.z = lerpf(torso_root.rotation.z, -stride * 0.025 * movement_amount + pivot_pulse * 0.035, return_weight)
		torso_root.rotation.x = lerpf(torso_root.rotation.x, -0.035 * movement_amount, return_weight)

func animate_smash() -> void:
	if right_arm == null:
		return
	var smash_tween: Tween = create_tween()
	smash_tween.tween_property(right_arm, "rotation:x", -1.8, 0.10)
	smash_tween.tween_property(right_arm, "rotation:x", 0.0, 0.20)

func _build_arm(anchor: Vector3, sleeve_color: Color, hand_color: Color, node_name: String) -> Node3D:
	var arm: Node3D = Node3D.new()
	arm.name = node_name + "Pivot"
	arm.position = anchor
	add_child(arm)
	PrimitiveFactory.add_box_mesh(arm, Vector3(0.0, -0.30, 0.0), Vector3(0.27, 0.70, 0.31), sleeve_color, node_name)
	PrimitiveFactory.add_cylinder_mesh(arm, Vector3(0.0, -0.70, 0.0), 0.15, 0.22, hand_color, node_name + "Hand", 12)
	return arm

func _build_leg(anchor: Vector3, pants_color: Color, node_name: String) -> Node3D:
	var leg: Node3D = Node3D.new()
	leg.name = node_name + "Pivot"
	leg.position = anchor
	add_child(leg)
	PrimitiveFactory.add_box_mesh(leg, Vector3(0.0, -0.32, 0.0), Vector3(0.36, 0.64, 0.42), pants_color, node_name)
	PrimitiveFactory.add_box_mesh(leg, Vector3(0.0, -0.69, 0.10), Vector3(0.38, 0.18, 0.58), pants_color, node_name + "Foot")
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
