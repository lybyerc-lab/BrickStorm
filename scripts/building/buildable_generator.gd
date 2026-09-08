# @brickstorm.system building
# @brickstorm.role Optional farm generator that demonstrates build-then-tool-then-world-change gameplay with a contextual wrench requirement.
# @brickstorm.scope runtime
# @brickstorm.risk medium
# @brickstorm.contract usable_buildables,contextual_tool_requirements,powered_world_change
# @brickstorm.north_star lego_twister
# @brickstorm.owner openai/brickstorm

extends BuildableObject

var activated: bool = false
var _flywheel: Node3D
var _running_time: float = 0.0

func _ready() -> void:
	prompt_text = "BUILD FARM GENERATOR"
	stud_reward = 220
	build_duration = 0.84
	completion_message = "GENERATOR ASSEMBLED // NEEDS WRENCH"
	post_build_usable = true
	post_build_prompt = "REPAIR GENERATOR"
	required_tool_id = GameConstants.TOOL_WRENCH
	required_tool_display_name = "WRENCH"
	super._ready()

func _process(delta: float) -> void:
	if not activated:
		return
	_running_time += delta
	if is_instance_valid(_flywheel):
		_flywheel.rotation.z += delta * 6.4

func can_interact(actor: Node3D) -> bool:
	return not activated and super.can_interact(actor)

func build_blueprint() -> void:
	add_build_element(
		BrickElementSpec.make(BrickElementSpec.KIND_BRICK, 6, 4, 2, BrickPalette.DARK_BLUE, Vector3(0.0, 0.20, 0.0), 0),
		Vector3(-1.8, 0.18, -1.0),
		Vector3(0.0, -24.0, 8.0)
	)
	add_build_element(
		BrickElementSpec.make(BrickElementSpec.KIND_BRICK, 4, 3, 3, BrickPalette.YELLOW, Vector3(-0.42, 0.66, 0.0), 1, BrickElementSpec.ROLE_STRUCTURE),
		Vector3(1.6, 0.22, 1.2),
		Vector3(10.0, 30.0, -8.0)
	)
	add_build_element(
		BrickElementSpec.make(BrickElementSpec.KIND_BRICK, 3, 3, 3, BrickPalette.ORANGE, Vector3(0.78, 0.66, 0.0), 1, BrickElementSpec.ROLE_STRUCTURE),
		Vector3(-1.4, 0.20, 1.4),
		Vector3(-10.0, -28.0, 12.0)
	)
	var axle: BrickElementSpec = BrickElementSpec.make(
		BrickElementSpec.KIND_BAR, 1, 1, 6, BrickPalette.SILVER, Vector3(0.72, 1.18, 0.0), 2, BrickElementSpec.ROLE_SUPPORT, Vector3(0.0, 0.0, 90.0)
	)
	axle.roughness = BrickPalette.METAL_ROUGHNESS
	axle.metallic = 0.40
	add_build_element(axle, Vector3(1.9, 0.18, -0.9), Vector3(18.0, 20.0, 30.0))
	var wheel_spec: BrickElementSpec = BrickElementSpec.make(
		BrickElementSpec.KIND_WHEEL, 2, 2, 2, BrickPalette.DARK_GRAY, Vector3(1.30, 1.18, 0.0), 3, BrickElementSpec.ROLE_PROP, Vector3(0.0, 0.0, 90.0)
	)
	_flywheel = add_build_element(wheel_spec, Vector3(-1.9, 0.28, 0.8), Vector3(0.0, 32.0, 30.0))
	add_build_element(
		BrickElementSpec.make(BrickElementSpec.KIND_TILE, 3, 2, 1, BrickPalette.BLACK, Vector3(-0.58, 1.22, 0.0), 3, BrickElementSpec.ROLE_TRIM),
		Vector3(0.7, 0.20, -1.7),
		Vector3(-12.0, 18.0, -10.0)
	)
	add_build_element(
		BrickElementSpec.make(BrickElementSpec.KIND_ROUND, 1, 1, 2, BrickPalette.RED, Vector3(-0.95, 1.44, 0.0), 4, BrickElementSpec.ROLE_PROP),
		Vector3(2.0, 0.16, 0.5),
		Vector3(20.0, -18.0, 12.0)
	)

func use_built_object(_actor: Node3D) -> void:
	if activated:
		return
	activated = true
	remove_from_group(GameConstants.GROUP_INTERACTABLE)
	GameManager.add_studs(250)
	GameEvents.utility_activated.emit(GameConstants.UTILITY_FARM_GENERATOR, self)
	GameEvents.toast_requested.emit("GENERATOR ONLINE // EQUIPMENT CACHE OPEN +250")
	GameEvents.camera_shake_requested.emit(0.24, 0.22)
	DestructionManager.spawn_destruction_burst(global_position + Vector3.UP * 0.9, BrickPalette.YELLOW, Vector3.UP * 1.8, 18, 0.70)

func is_activated() -> bool:
	return activated
