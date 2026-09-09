# @brickstorm.system tests
# @brickstorm.role Real-Godot contract for the 0.3.7 post-probe road chase, beacon build/tool loop, first production InteractionGraph output, and chase completion.
# @brickstorm.scope test
# @brickstorm.risk low
# @brickstorm.contract none
# @brickstorm.north_star lego_twister
# @brickstorm.owner openai/brickstorm

extends Node

const LevelScene: PackedScene = preload("res://scenes/levels/storm_run_01.tscn")

var _failures: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func _run() -> void:
	var level: Node3D = LevelScene.instantiate() as Node3D
	add_child(level)
	for _index in range(5):
		await get_tree().process_frame

	var player: Node3D = level.get_node_or_null("BrickChaser") as Node3D
	var director: Node = level.get_node_or_null("RoadChase")
	var beacon: BuildableRoadBeacon = level.get_node_or_null("Geometry/RoadChaseBeacon") as BuildableRoadBeacon
	var barrier: RoadChaseBarrier = level.get_node_or_null("Geometry/RoadChaseBarrier") as RoadChaseBarrier
	var hero_pole: DestructibleStructure = level.get_node_or_null("Geometry/ChaseHeroPole") as DestructibleStructure
	_check(player != null and director != null, "road-chase director and player exist in authored level")
	_check(beacon != null and barrier != null and hero_pole != null, "road chase authored beacon, barrier, and hero destruction object exist")
	if beacon == null or barrier == null or player == null or director == null:
		_finish()
		return
	_check(not beacon.visible and not beacon.monitoring, "road beacon stays dormant before probe completion")
	_check(not barrier.is_open(), "county gate begins closed")

	GameManager.complete_mission()
	for _index in range(4):
		await get_tree().process_frame
	_check(beacon.visible and beacon.monitoring, "probe completion reveals and enables the road beacon")
	_check(bool(director.get("_probe_deployed")), "probe completion unlocks chase state")

	player.call("grant_tool", GameConstants.TOOL_WRENCH, "WRENCH")
	beacon.interact(player)
	for _index in range(120):
		await get_tree().process_frame
	_check(beacon.built, "road beacon uses the real ordered build loop")
	_check(not barrier.is_open(), "build alone does not bypass the wrench repair or graph condition")
	beacon.interact(player)
	for _index in range(50):
		await get_tree().process_frame
	_check(beacon.is_online(), "wrench interaction powers the completed road beacon")
	_check(barrier.is_open(), "first production InteractionGraph opens the county gate")

	player.global_position.z = -74.0
	for _index in range(3):
		await get_tree().process_frame
	_check(bool(director.get("_chase_started")), "crossing north of the farm starts the chase leg")

	player.global_position.z = -145.0
	for _index in range(8):
		await get_tree().process_frame
	_check(bool(director.get("_hero_break_triggered")), "deep chase triggers authored roadside destruction beat")

	player.global_position.z = -176.0
	for _index in range(4):
		await get_tree().process_frame
	_check(bool(director.get("_chase_finished")), "reaching the north ridge completes the first intercept")
	_finish()

func _finish() -> void:
	InputRouter.clear_mobile_move()
	if _failures.is_empty():
		print("BRICKSTORM ROAD CHASE ENGINE TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error("ROAD CHASE TEST FAILURE: " + failure)
	print("BRICKSTORM ROAD CHASE ENGINE TEST: FAIL (", _failures.size(), ")")
	get_tree().quit(1)

func _check(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: " + label)
	else:
		_failures.append(label)
