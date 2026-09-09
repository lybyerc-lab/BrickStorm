# @brickstorm.system building
# @brickstorm.role New chase-section buildable: reconstruct and wrench-repair a county road storm beacon to unlock the road barrier.
# @brickstorm.scope runtime
# @brickstorm.risk medium
# @brickstorm.contract road_chase_beacon,build_recipe,contextual_tool_requirements
# @brickstorm.north_star lego_twister
# @brickstorm.owner openai/brickstorm

class_name BuildableRoadBeacon
extends BuildableObject

var online: bool = false
var _beacon_head: Node3D
var _enabled_for_chase: bool = false
var _spin_time: float = 0.0

func _ready() -> void:
	prompt_text = "BUILD ROAD BEACON"
	stud_reward = 250
	build_duration = 0.86
	completion_message = "BEACON ASSEMBLED"
	post_build_usable = true
	post_build_prompt = "WRENCH BEACON"
	required_tool_id = GameConstants.TOOL_WRENCH
	required_tool_display_name = "WRENCH"
	use_cooldown = 0.4
	super._ready()
	set_chase_enabled(false)

func _process(delta: float) -> void:
	if not online or not is_instance_valid(_beacon_head):
		return
	_spin_time += delta
	_beacon_head.rotation.y = _spin_time * 2.7
	var pulse: float = 1.0 + sin(_spin_time * 7.5) * 0.08
	_beacon_head.scale = Vector3.ONE * pulse

func set_chase_enabled(value: bool) -> void:
	_enabled_for_chase = value
	visible = value
	monitoring = value
	monitorable = value
	if value:
		if not built and not is_in_group(GameConstants.GROUP_INTERACTABLE):
			add_to_group(GameConstants.GROUP_INTERACTABLE)
	elif is_in_group(GameConstants.GROUP_INTERACTABLE):
		remove_from_group(GameConstants.GROUP_INTERACTABLE)

func can_interact(actor: Node3D) -> bool:
	return _enabled_for_chase and super.can_interact(actor)

func use_built_object(_actor: Node3D) -> void:
	if online:
		GameEvents.toast_requested.emit("ROAD BEACON ONLINE")
		return
	online = true
	_spin_time = 0.0
	AudioDirector.play_secret()
	GameEvents.toast_requested.emit("ROAD BEACON ONLINE // GATE LINKED")
	GameEvents.camera_shake_requested.emit(0.16, 0.16)
	GameEvents.camera_focus_requested.emit(global_position + Vector3.UP * 1.65, 0.85, 52.0)
	GameEvents.utility_activated.emit(GameConstants.UTILITY_ROAD_BEACON, self)

func is_online() -> bool:
	return online

func build_blueprint() -> void:
	add_build_element(
		BrickElementSpec.make(BrickElementSpec.KIND_BRICK, 4, 4, 2, BrickPalette.DARK_BLUE, Vector3(0.0, 0.20, 0.0), 0),
		Vector3(-1.9, 0.20, 0.8), Vector3(0.0, -28.0, 8.0)
	)
	add_build_element(
		BrickElementSpec.make(BrickElementSpec.KIND_BRICK, 3, 3, 2, BrickPalette.YELLOW, Vector3(0.0, 0.48, 0.0), 1),
		Vector3(1.5, 0.18, -1.2), Vector3(8.0, 22.0, -10.0)
	)
	var lower_mast: BrickElementSpec = BrickElementSpec.make(
		BrickElementSpec.KIND_BAR, 1, 1, 7, BrickPalette.SILVER, Vector3(0.0, 1.12, 0.0), 2, BrickElementSpec.ROLE_SUPPORT
	)
	lower_mast.roughness = BrickPalette.METAL_ROUGHNESS
	lower_mast.metallic = 0.36
	add_build_element(lower_mast, Vector3(-1.4, 0.20, -1.4), Vector3(-24.0, 0.0, 16.0))
	var upper_mast: BrickElementSpec = BrickElementSpec.make(
		BrickElementSpec.KIND_BAR, 1, 1, 6, BrickPalette.SILVER, Vector3(0.0, 1.94, 0.0), 3, BrickElementSpec.ROLE_SUPPORT
	)
	upper_mast.roughness = BrickPalette.METAL_ROUGHNESS
	upper_mast.metallic = 0.36
	add_build_element(upper_mast, Vector3(1.8, 0.20, 1.0), Vector3(22.0, -12.0, -18.0))
	add_build_element(
		BrickElementSpec.make(BrickElementSpec.KIND_TILE, 4, 2, 1, BrickPalette.BLACK, Vector3(0.0, 2.40, 0.0), 4, BrickElementSpec.ROLE_TRIM),
		Vector3(-0.7, 0.18, 1.9), Vector3(-12.0, 32.0, 14.0)
	)
	_beacon_head = add_build_element(
		BrickElementSpec.make(BrickElementSpec.KIND_ROUND, 2, 2, 2, BrickPalette.ORANGE, Vector3(0.0, 2.66, 0.0), 5, BrickElementSpec.ROLE_PROP),
		Vector3(2.0, 0.22, -0.3), Vector3(14.0, -34.0, -8.0)
	)
	add_build_element(
		BrickElementSpec.make(BrickElementSpec.KIND_ROUND, 1, 1, 2, BrickPalette.YELLOW, Vector3(0.0, 2.94, 0.0), 6, BrickElementSpec.ROLE_PROP),
		Vector3(-2.1, 0.18, -0.4), Vector3(-10.0, 18.0, 16.0)
	)
