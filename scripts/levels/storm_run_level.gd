# @brickstorm.system levels
# @brickstorm.role Coordinates Storm Run mission objectives, side progression, storm pressure, rewards, and lighting.
# @brickstorm.scope runtime
# @brickstorm.risk medium
# @brickstorm.contract mission_session,mission_counter,side_progression,storm_pressure
# @brickstorm.north_star lego_twister
# @brickstorm.owner openai/brickstorm

extends Node3D

@export_category("Section Budget")
@export var section_budget: SectionBudget

@onready var tornado: Node3D = $Tornado

var _smash_total: int = 0
var _smash_count: int = 0
var _build_total: int = 0
var _build_count: int = 0
var _smash_bonus_12: bool = false
var _smash_bonus_30: bool = false
var _smash_all_bonus: bool = false
var _build_all_bonus: bool = false
var _storm_chaser_awarded: bool = false

const STORM_CHASER_TARGET: int = 10000

func _enter_tree() -> void:
	DestructionManager.reset_runtime_objects()
	GameManager.begin_mission(GameConstants.MISSION_STORM_RUN_01)
	GameManager.configure_counter(GameConstants.COUNTER_SENSOR_KITS, 3)

func _ready() -> void:
	_ensure_section_budget()
	_build_lighting()
	GameEvents.mission_counter_changed.connect(_on_mission_counter_changed)
	GameEvents.mission_completed.connect(_on_mission_completed)
	GameEvents.structure_destroyed.connect(_on_structure_destroyed)
	GameEvents.build_completed.connect(_on_build_completed)
	GameEvents.studs_changed.connect(_on_studs_changed)
	_smash_total = get_tree().get_nodes_in_group(GameConstants.GROUP_SMASHABLE).size()
	_build_total = get_tree().get_nodes_in_group(GameConstants.GROUP_BUILDABLE).size()
	_refresh_objective()

func _process(_delta: float) -> void:
	var active_actor: Node3D = GameManager.get_active_actor()
	if active_actor != null and tornado != null and tornado.has_method("get_intensity_at"):
		var storm_intensity: float = float(tornado.call("get_intensity_at", active_actor.global_position))
		GameEvents.storm_intensity_changed.emit(storm_intensity)
		AudioDirector.set_wind_strength(maxf(0.16, storm_intensity))

func get_section_budget() -> SectionBudget:
	_ensure_section_budget()
	return section_budget

func _ensure_section_budget() -> void:
	if section_budget == null:
		section_budget = SectionBudget.new()
	if not section_budget.is_sane():
		push_warning("Storm Run SectionBudget contains invalid limits.")

func _on_mission_counter_changed(counter_id: StringName, _current: int, _required: int) -> void:
	if counter_id == GameConstants.COUNTER_SENSOR_KITS:
		_refresh_objective()

func _on_structure_destroyed(_structure: Node3D) -> void:
	_smash_count = mini(_smash_total, _smash_count + 1)
	if _smash_count >= 12 and not _smash_bonus_12:
		_smash_bonus_12 = true
		GameManager.add_studs(200)
		GameEvents.toast_requested.emit("FARM WRECKER +200")
	if _smash_count >= 30 and not _smash_bonus_30:
		_smash_bonus_30 = true
		GameManager.add_studs(400)
		GameEvents.toast_requested.emit("BRICK RAMPAGE +400")
	if _smash_total > 0 and _smash_count >= _smash_total and not _smash_all_bonus:
		_smash_all_bonus = true
		GameManager.add_studs(800)
		GameEvents.toast_requested.emit("TOTAL FARM CHAOS +800")
	_refresh_objective()

func _on_build_completed(_buildable: Node3D) -> void:
	_build_count = mini(_build_total, _build_count + 1)
	if _build_total > 0 and _build_count >= _build_total and not _build_all_bonus:
		_build_all_bonus = true
		GameManager.add_studs(600)
		GameEvents.toast_requested.emit("MASTER BUILDER +600")
	_refresh_objective()


func _on_studs_changed(total: int) -> void:
	if _storm_chaser_awarded or total < STORM_CHASER_TARGET:
		return
	_storm_chaser_awarded = true
	AudioDirector.play_secret()
	GameEvents.toast_requested.emit("STORM CHASER! // %d STUDS" % STORM_CHASER_TARGET)
	GameEvents.camera_shake_requested.emit(0.12, 0.16)

func _on_mission_completed(_mission_id: String, _studs: int) -> void:
	_refresh_objective()
	GameEvents.toast_requested.emit("DATA LOCKED // GREAT CHASE")

func _refresh_objective() -> void:
	var side_progress: String = "Farm chaos %d/%d   Builds %d/%d" % [_smash_count, _smash_total, _build_count, _build_total]
	if GameManager.mission_finished:
		GameManager.set_objective(
			"MISSION COMPLETE: STORM DATA CAPTURED",
			"%s   Keep exploring, building, riding, and smashing." % side_progress
		)
		return
	var sensor_state: Vector2i = GameManager.get_counter_state(GameConstants.COUNTER_SENSOR_KITS)
	if sensor_state.x < sensor_state.y:
		var mission_hint: String = "Find the cow for a charge attack."
		if sensor_state.x == 0:
			mission_hint = "Follow the stud trail. Build + wrench-repair the generator to open Kit A."
		elif sensor_state.x == 1:
			mission_hint = "The farm opens up now. Scanner, truck, cow, or brute-force smashing all help."
		GameManager.set_objective(
			"RECOVER SENSOR KITS  %d / %d" % [sensor_state.x, sensor_state.y],
			"%s   %s" % [side_progress, mission_hint]
		)
		return
	GameManager.set_objective(
		"REACH THE YELLOW DEPLOYMENT ZONE",
		"%s   Chase the storm, or keep wrecking the farm." % side_progress
	)

func _build_lighting() -> void:
	var sunlight: DirectionalLight3D = DirectionalLight3D.new()
	sunlight.name = "Sunlight"
	sunlight.rotation_degrees = Vector3(-53.0, -28.0, 0.0)
	sunlight.light_energy = 1.12
	sunlight.shadow_enabled = true
	add_child(sunlight)
	var environment_node: WorldEnvironment = WorldEnvironment.new()
	environment_node.name = "StormEnvironment"
	var storm_environment: Environment = Environment.new()
	var storm_sky: Sky = Sky.new()
	var sky_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.16, 0.27, 0.34)
	sky_material.sky_horizon_color = Color(0.56, 0.64, 0.65)
	sky_material.ground_horizon_color = Color(0.38, 0.42, 0.35)
	sky_material.ground_bottom_color = Color(0.16, 0.19, 0.15)
	storm_sky.sky_material = sky_material
	storm_environment.background_mode = Environment.BG_SKY
	storm_environment.sky = storm_sky
	storm_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	storm_environment.ambient_light_color = Color(0.57, 0.62, 0.63)
	storm_environment.ambient_light_energy = 0.80
	storm_environment.fog_enabled = true
	storm_environment.fog_light_color = Color(0.50, 0.56, 0.56)
	storm_environment.fog_density = 0.0045
	storm_environment.fog_sky_affect = 0.34
	environment_node.environment = storm_environment
	add_child(environment_node)
