# @brickstorm.system levels
# @brickstorm.role Extends Storm Run beyond the probe into a truck-first county-road chase, first production InteractionGraph chain, debris beats, and a hero storm destruction cue.
# @brickstorm.scope runtime
# @brickstorm.risk medium
# @brickstorm.contract road_chase_037,interaction_graph_production,storm_setpiece,content_expansion
# @brickstorm.north_star lego_twister
# @brickstorm.owner openai/brickstorm

class_name RoadChaseDirector
extends Node3D

const STATE_PROBE_DEPLOYED: StringName = &"probe_deployed"
const STATE_BEACON_ONLINE: StringName = &"beacon_online"
const OUTPUT_OPEN_ROAD_GATE: StringName = &"open_road_gate"

var _graph_runtime: InteractionGraphRuntime
var _beacon: BuildableRoadBeacon
var _barrier: RoadChaseBarrier
var _hero_pole: DestructibleStructure
var _crew_visual: BrickChaserVisual
var _crew_label: Label3D
var _crew_right_arm: Node3D
var _elapsed: float = 0.0
var _probe_deployed: bool = false
var _chase_started: bool = false
var _gust_one: bool = false
var _beacon_prompted: bool = false
var _hero_break_triggered: bool = false
var _chase_finished: bool = false

func _ready() -> void:
	_build_interaction_graph()
	GameEvents.mission_completed.connect(_on_mission_completed)
	GameEvents.utility_activated.connect(_on_utility_activated)
	call_deferred("_bind_authored_content")

func _process(delta: float) -> void:
	_elapsed += delta
	_animate_road_crew()
	if not _probe_deployed or _chase_finished:
		return
	var actor: Node3D = GameManager.get_active_actor()
	if actor == null:
		return
	var z_value: float = actor.global_position.z
	if not _chase_started and z_value <= -72.0:
		_start_chase()
	if _chase_started and not _gust_one and z_value <= -92.0:
		_gust_one = true
		_trigger_debris_gust(Vector3(0.0, 1.0, -99.0), 7)
		GameEvents.toast_requested.emit("DEBRIS! KEEP THE TRUCK STRAIGHT!")
	if _chase_started and not _beacon_prompted and z_value <= -108.0:
		_beacon_prompted = true
		GameManager.set_objective(
			"COUNTY GATE DOWN",
			"Build the roadside beacon, then use the wrench to restore the gate link."
		)
		if is_instance_valid(_beacon):
			GameEvents.camera_focus_requested.emit(_beacon.global_position + Vector3.UP * 1.5, 0.95, 52.0)
	if _barrier != null and _barrier.opened and not _hero_break_triggered and z_value <= -143.0:
		_hero_break_triggered = true
		_trigger_hero_pole_break()
		_trigger_debris_gust(Vector3(0.0, 1.0, -151.0), 9)
		GameManager.set_objective("STAY WITH THE CELL", "Push through the debris and reach the north ridge.")
	if _hero_break_triggered and z_value <= -174.0:
		_finish_chase()

func _build_interaction_graph() -> void:
	var condition: InteractionGraphCondition = InteractionGraphCondition.new()
	condition.operator = InteractionGraphCondition.Operator.ALL
	condition.query_ids.append(STATE_PROBE_DEPLOYED)
	condition.query_ids.append(STATE_BEACON_ONLINE)
	var graph_node: InteractionGraphNode = InteractionGraphNode.new()
	graph_node.node_id = &"road_gate_after_probe_and_beacon"
	graph_node.condition = condition
	graph_node.output_ids.append(OUTPUT_OPEN_ROAD_GATE)
	var graph: InteractionGraph = InteractionGraph.new()
	graph.nodes.append(graph_node)
	_graph_runtime = InteractionGraphRuntime.new()
	_graph_runtime.name = "RoadChaseInteractionGraph"
	_graph_runtime.graph = graph
	_graph_runtime.output_emitted.connect(_on_graph_output)
	add_child(_graph_runtime)

func _bind_authored_content() -> void:
	var level: Node = get_parent()
	if level == null:
		return
	_beacon = level.get_node_or_null("Geometry/RoadChaseBeacon") as BuildableRoadBeacon
	_barrier = level.get_node_or_null("Geometry/RoadChaseBarrier") as RoadChaseBarrier
	_hero_pole = level.get_node_or_null("Geometry/ChaseHeroPole") as DestructibleStructure
	if GameManager.mission_finished:
		_unlock_chase_after_probe()

func _on_mission_completed(_mission_id: String, _studs: int) -> void:
	_unlock_chase_after_probe()

func _unlock_chase_after_probe() -> void:
	if _probe_deployed:
		return
	_probe_deployed = true
	if is_instance_valid(_beacon):
		_beacon.set_chase_enabled(true)
	_graph_runtime.set_state(STATE_PROBE_DEPLOYED, true)
	_build_road_crew()
	GameManager.set_objective(
		"CHASE THE CELL NORTH",
		"Get back in the chase truck and follow the road beyond the farm."
	)
	GameEvents.toast_requested.emit("PROBE IS LIVE // BACK IN THE TRUCK!")
	var truck: Node3D = get_tree().get_first_node_in_group(GameConstants.GROUP_ACTIVE_CHASE_TRUCK) as Node3D
	if truck == null:
		truck = get_parent().get_node_or_null("ChaseTruck") as Node3D
	if truck != null:
		GameEvents.camera_focus_requested.emit(truck.global_position + Vector3.UP * 1.2, 1.0, 54.0)

func _on_utility_activated(utility_id: StringName, _source: Node3D) -> void:
	if utility_id != GameConstants.UTILITY_ROAD_BEACON:
		return
	_graph_runtime.set_state(STATE_BEACON_ONLINE, true)

func _on_graph_output(output_id: StringName) -> void:
	if output_id != OUTPUT_OPEN_ROAD_GATE or not is_instance_valid(_barrier):
		return
	_barrier.open_gate()
	GameManager.add_studs(StudCurrency.VALUE_BLUE)
	GameEvents.toast_requested.emit("COUNTY GATE OPEN +1000")
	GameManager.set_objective("CHASE THE CELL", "Road is open. Stay in the truck and push north.")
	if is_instance_valid(_crew_label):
		_crew_label.text = "GO! GO! GO!"

func _start_chase() -> void:
	_chase_started = true
	GameEvents.toast_requested.emit("CHASE LEG // CELL MOVING NORTH")
	GameManager.set_objective("CHASE THE CELL", "Follow the center studs. Watch for wind-thrown road debris.")
	var tornado: Node3D = get_tree().get_first_node_in_group(GameConstants.GROUP_ACTIVE_TORNADO) as Node3D
	if tornado != null:
		GameEvents.camera_focus_requested.emit(tornado.global_position + Vector3.UP * 4.0, 0.95, 58.0)

func _trigger_debris_gust(center: Vector3, count: int) -> void:
	var runtime_parent: Node = get_tree().current_scene
	if runtime_parent == null:
		return
	for index in range(count):
		var debris: LooseDebris = LooseDebris.new()
		debris.name = "ChaseGustDebris_%02d_%02d" % [int(absf(center.z)), index]
		debris.position = center + Vector3(-5.8 + float(index) * 1.65, 0.75 + float(index % 3) * 0.28, -2.2 + float((index * 3) % 5))
		debris.configure(
			Vector3(0.22 + float(index % 3) * 0.10, 0.18, 0.75 + float(index % 4) * 0.25),
			Color(0.48, 0.31, 0.14),
			0.30 + float(index % 4) * 0.10
		)
		runtime_parent.add_child(debris)
		debris.apply_central_impulse(Vector3(5.5 + float(index % 2) * 2.0, 2.2 + float(index % 3), 1.0 - float(index % 3)) * (1.0 if index % 2 == 0 else -1.0))
		debris.apply_torque_impulse(Vector3(1.8, 2.6, -1.4) * (0.7 + float(index % 3) * 0.25))
	GameEvents.camera_shake_requested.emit(0.18, 0.20)

func _trigger_hero_pole_break() -> void:
	if not is_instance_valid(_hero_pole) or _hero_pole.broken or _hero_pole.breaking:
		return
	GameEvents.camera_focus_requested.emit(_hero_pole.global_position + Vector3.UP * 2.0, 0.75, 55.0)
	_hero_pole.break_apart(_hero_pole.global_position + Vector3(-6.0, 1.2, 2.0), Vector3(7.5, 5.8, -2.5))
	GameEvents.toast_requested.emit("POLE DOWN! THREAD THE GAP!")

func _finish_chase() -> void:
	_chase_finished = true
	GameManager.add_studs(StudCurrency.VALUE_BLUE)
	AudioDirector.play_secret()
	GameEvents.camera_shake_requested.emit(0.16, 0.18)
	GameEvents.toast_requested.emit("FIRST INTERCEPT COMPLETE +1000")
	GameManager.set_objective(
		"FIRST INTERCEPT COMPLETE",
		"The storm is still moving. Next story target: the road toward Wakita."
	)
	var tornado: Node3D = get_tree().get_first_node_in_group(GameConstants.GROUP_ACTIVE_TORNADO) as Node3D
	if tornado != null:
		GameEvents.camera_focus_requested.emit(tornado.global_position + Vector3.UP * 4.0, 1.25, 56.0)

func _build_road_crew() -> void:
	if is_instance_valid(_crew_visual):
		return
	var crew_root: Node3D = Node3D.new()
	crew_root.name = "CountyRoadChaser"
	crew_root.position = Vector3(-7.2, 0.0, -113.0)
	crew_root.rotation_degrees.y = 35.0
	add_child(crew_root)
	_crew_visual = BrickChaserVisual.new()
	crew_root.add_child(_crew_visual)
	_crew_visual.build()
	_crew_visual.scale = Vector3.ONE * 0.90
	_crew_right_arm = _crew_visual.right_arm
	_crew_label = Label3D.new()
	_crew_label.name = "CountyRoadHint"
	_crew_label.text = "BEACON'S DEAD!"
	_crew_label.font_size = 36
	_crew_label.outline_size = 10
	_crew_label.pixel_size = 0.006
	_crew_label.modulate = BrickPalette.YELLOW
	_crew_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_crew_label.position = Vector3(0.0, 3.1, 0.0)
	crew_root.add_child(_crew_label)

func _animate_road_crew() -> void:
	if is_instance_valid(_crew_right_arm):
		_crew_right_arm.rotation.x = -0.45 + sin(_elapsed * 4.6) * 0.38
	if is_instance_valid(_crew_visual):
		_crew_visual.position.y = sin(_elapsed * 2.0) * 0.012
