# @brickstorm.system tests
# @brickstorm.role Focused engine assertions for mission/save contracts plus archaeology-driven semantic audio, build, interaction, animation, and section-budget resources.
# @brickstorm.scope test
# @brickstorm.risk low
# @brickstorm.contract mission_counter,save_schema_v1,settings_sanitization,semantic_audio_event,build_recipe,interaction_graph,action_animation_profile,section_budget
# @brickstorm.north_star foundation
# @brickstorm.owner openai/brickstorm

extends Node

const TEST_COUNTER: StringName = &"foundation_test_counter"
const TEST_MISSION: String = "foundation_test_mission"

var _failures: Array[String] = []
var _graph_outputs: Array[StringName] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func _run() -> void:
	_test_mission_counter_contract()
	_test_save_sanitization_contract()
	_test_archaeology_foundation_contracts()

	if _failures.is_empty():
		print("BRICKSTORM CORE CONTRACT ENGINE TEST: PASS")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error("CORE CONTRACT TEST FAILURE: " + failure)
	print("BRICKSTORM CORE CONTRACT ENGINE TEST: FAIL (%d)" % _failures.size())
	get_tree().quit(1)

func _test_mission_counter_contract() -> void:
	GameManager.begin_mission(TEST_MISSION)
	_check(GameManager.mission_id == TEST_MISSION, "generic mission session starts with stable ID")
	_check(GameManager.get_counter_state(TEST_COUNTER) == Vector2i.ZERO, "unknown counter reads as zero state")
	_check(not GameManager.is_counter_complete(TEST_COUNTER), "unknown counter is not complete")

	var state: Vector2i = GameManager.configure_counter(TEST_COUNTER, 3, -5)
	_check(state == Vector2i(0, 3), "counter configuration clamps negative current value")
	state = GameManager.increment_counter(TEST_COUNTER, 2)
	_check(state == Vector2i(2, 3), "counter increments generically")
	state = GameManager.increment_counter(TEST_COUNTER, 50)
	_check(state == Vector2i(3, 3), "counter clamps at required value")
	_check(GameManager.is_counter_complete(TEST_COUNTER), "configured counter reports completion")
	state = GameManager.increment_counter(TEST_COUNTER, -1)
	_check(state == Vector2i(3, 3), "counter ignores non-positive increments")
	_check(GameManager.configure_counter(StringName(), 4) == Vector2i.ZERO, "empty counter ID is rejected")

	GameManager.add_studs(75)
	GameManager.mission_finished = true
	GameManager.begin_mission(GameConstants.MISSION_STORM_RUN_01)
	_check(GameManager.mission_studs == 0, "new mission resets mission-local studs")
	_check(not GameManager.mission_finished, "new mission clears completion state")
	_check(GameManager.get_counter_state(TEST_COUNTER) == Vector2i.ZERO, "new mission clears old counters")

func _test_save_sanitization_contract() -> void:
	var original_data: Dictionary = SaveManager.data.duplicate(true)
	SaveManager.data = {
		SaveManager.KEY_VERSION: 999,
		SaveManager.KEY_TOTAL_STUDS: -200,
		SaveManager.KEY_COMPLETED_MISSIONS: {
			"": 99,
			GameConstants.MISSION_STORM_RUN_01: -10,
			42: 12,
		},
		SaveManager.KEY_SETTINGS: {
			SaveManager.SETTING_CAMERA_SHAKE: 8.5,
			SaveManager.SETTING_TOUCH_CONTROLS: 0,
			SaveManager.SETTING_EFFECTS_QUALITY: "ULTRA",
			"unknown_setting": "discard me",
		},
		"unknown_top_level": 123,
	}
	SaveManager.call("_sanitize_data")

	_check(int(SaveManager.data.get(SaveManager.KEY_VERSION, -1)) == SaveManager.SAVE_VERSION, "save schema is normalized to current version")
	_check(int(SaveManager.data.get(SaveManager.KEY_TOTAL_STUDS, -1)) == 0, "negative lifetime studs clamp to zero")
	var missions: Dictionary = SaveManager.data.get(SaveManager.KEY_COMPLETED_MISSIONS, {}) as Dictionary
	_check(not missions.has(""), "empty mission IDs are removed")
	_check(int(missions.get(GameConstants.MISSION_STORM_RUN_01, -1)) == 0, "negative mission best clamps to zero")
	_check(int(missions.get("42", -1)) == 12, "non-string mission keys normalize deterministically")
	var settings: Dictionary = SaveManager.data.get(SaveManager.KEY_SETTINGS, {}) as Dictionary
	_check(is_equal_approx(float(settings.get(SaveManager.SETTING_CAMERA_SHAKE, -1.0)), 1.0), "camera shake setting clamps to one")
	_check(not bool(settings.get(SaveManager.SETTING_TOUCH_CONTROLS, true)), "numeric false touch setting sanitizes predictably")
	_check(str(settings.get(SaveManager.SETTING_EFFECTS_QUALITY, "")) == SaveManager.EFFECTS_QUALITY_BALANCED, "unknown effects profile falls back to balanced")
	_check(not settings.has("unknown_setting"), "unknown settings are discarded")
	_check(not SaveManager.data.has("unknown_top_level"), "unknown top-level save fields are discarded")

	SaveManager.data = original_data

func _test_archaeology_foundation_contracts() -> void:
	var build_event: AudioEvent = AudioDirector.get_event(AudioDirector.EVENT_BUILD_SNAP)
	_check(build_event != null and build_event.is_valid_event(), "semantic AudioEvent library exposes the existing build snap")
	_check(build_event != null and build_event.variants.size() == 1, "0.3.5 original build audio remains the initial semantic event variant")

	var action_profile: ActionAnimationProfile = ActionAnimationProfile.new()
	_check(is_equal_approx(action_profile.start_hold_seconds, 0.12), "action profile preserves accepted start-punch hold timing")
	_check(is_equal_approx(action_profile.pivot_hold_seconds, 0.10), "action profile preserves accepted pivot hold timing")
	_check(not action_profile.footstep_event_id.is_empty(), "action profile exposes semantic footstep markers")

	var part_ids: Array[StringName] = []
	part_ids.append(&"base")
	part_ids.append(&"sensor")
	var build_orders: Array[int] = []
	build_orders.append(0)
	build_orders.append(2)
	var recipe: BuildRecipe = BuildRecipe.new()
	recipe.configure_from_build_orders(part_ids, build_orders, 0.72)
	_check(recipe.steps.size() == 2, "BuildRecipe retains explicit ordered component steps")
	_check(is_equal_approx(recipe.get_part_delay(0, 0), 0.0), "BuildRecipe first component starts immediately")
	_check(is_equal_approx(recipe.get_part_delay(1, 2), 0.07), "BuildRecipe preserves the proven 0.035-second build-order cadence")

	var condition: InteractionGraphCondition = InteractionGraphCondition.new()
	condition.operator = InteractionGraphCondition.Operator.ALL
	condition.query_ids.append(&"generator_repaired")
	var graph_node: InteractionGraphNode = InteractionGraphNode.new()
	graph_node.node_id = &"open_sensor_cage"
	graph_node.condition = condition
	graph_node.output_ids.append(&"sensor_cage_open")
	var graph: InteractionGraph = InteractionGraph.new()
	graph.nodes.append(graph_node)
	var graph_runtime: InteractionGraphRuntime = InteractionGraphRuntime.new()
	graph_runtime.graph = graph
	add_child(graph_runtime)
	_graph_outputs.clear()
	graph_runtime.output_emitted.connect(_on_graph_output)
	graph_runtime.set_state(&"generator_repaired", true)
	_check(_graph_outputs.has(&"sensor_cage_open"), "InteractionGraph emits a semantic consequence when its ALL condition becomes true")
	_graph_outputs.clear()
	graph_runtime.evaluate()
	_check(_graph_outputs.is_empty(), "non-repeatable InteractionGraph nodes fire only once")
	graph_runtime.queue_free()

	var section_budget: SectionBudget = SectionBudget.new()
	_check(section_budget.is_sane(), "default SectionBudget keeps render, texture, gameplay, physics, and presentation limits internally sane")
	_check(section_budget.maximum_visible_clusters <= section_budget.maximum_static_clusters, "visible static-cluster cap cannot exceed authored cluster cap")
	var cluster_policy: StaticRenderClusterPolicy = StaticRenderClusterPolicy.new()
	_check(cluster_policy.is_valid_policy(), "default static render-cluster policy is valid")
	_check(cluster_policy.preserve_collision_separately, "static render clustering never requires collision identity to be baked away")

func _on_graph_output(output_id: StringName) -> void:
	_graph_outputs.append(output_id)

func _check(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: " + label)
	else:
		_failures.append(label)
