# @brickstorm.system tests
# @brickstorm.role Real-Godot contract for the first demo-informed hybrid environment building: permanent world shell, LEGO-active attachments, staged roof peel, and bounded storm debris.
# @brickstorm.scope test
# @brickstorm.risk low
# @brickstorm.contract none
# @brickstorm.north_star classic_lego_environment
# @brickstorm.owner openai/brickstorm

extends Node3D

const HybridHouseScene: PackedScene = preload("res://scenes/levels/hybrid_roadside_house.tscn")

var _failures: Array[String] = []
var _roof_stages: Array[StringName] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func _run() -> void:
	DestructionManager.reset_runtime_objects()
	PrimitiveFactory.add_static_box(self, Vector3(0.0, -0.50, 0.0), Vector3(30.0, 1.0, 30.0), Color(0.28, 0.40, 0.19), "BuildingTestGround")
	var house: HybridRoadsideHouse = HybridHouseScene.instantiate() as HybridRoadsideHouse
	house.position = Vector3.ZERO
	add_child(house)
	for _index in range(4):
		await get_tree().process_frame

	_check(house.shell_is_present(), "hybrid building keeps a permanent world shell")
	_check(house.get_node_or_null("PermanentShell/Foundation") is StaticBody3D, "permanent shell owns stable world collision")
	_check(house.get_attachment_count() == 6, "LEGO attachment layer remains a small independently addressable population")
	_check(house.get_node_or_null("LegoAttachmentLayer") is Node3D, "LEGO-active attachment layer is structurally separate from shell geometry")

	var sign: BuildingAttachmentCluster = house.get_attachment_by_name(&"StormStopSign")
	var window: BuildingAttachmentCluster = house.get_attachment_by_name(&"FrontWindowLeft")
	var door: BuildingAttachmentCluster = house.get_attachment_by_name(&"FrontDoor")
	var roof: BuildingAttachmentCluster = house.get_attachment_by_name(&"RoofLeft")
	_check(sign != null and window != null and door != null and roof != null, "sign, window, door, and roof retain independent gameplay identity")
	if roof != null:
		_check(roof.uses_authored_break_stages(), "LEGO roof uses authored staged peel instead of one-frame atomization")
		_check(roof.fragment_cluster_count(&"eave") > 0 and roof.fragment_cluster_count(&"roof_panel") > 0, "roof blueprint separates eave and panel tear-off clusters")
		roof.break_stage_released.connect(_on_roof_stage)

	# Below-threshold wind must leave the loose sign alone, proving attachment
	# susceptibility is data rather than a global all-buildings switch.
	if sign != null:
		sign.apply_storm(0.20, Vector3(0.0, 0.0, 8.0))
		_check(not sign.broken and is_zero_approx(sign.accumulated_damage), "attachment ignores storm pressure below its own susceptibility threshold")
		sign.apply_damage(1.0, sign.global_position, Vector3(3.0, 3.5, 1.0), DestructibleStructure.DAMAGE_CAUSE_STORM)
	if window != null:
		window.apply_damage(1.0, window.global_position, Vector3(4.0, 4.0, 1.0), DestructibleStructure.DAMAGE_CAUSE_STORM)
	if door != null:
		door.apply_damage(1.2, door.global_position, Vector3(4.5, 3.2, 1.2), DestructibleStructure.DAMAGE_CAUSE_STORM)
	if roof != null:
		roof.break_apart(roof.global_position + Vector3(6.0, 0.0, 0.0), Vector3(-7.0, 7.5, -1.0))

	for _index in range(80):
		await get_tree().process_frame

	_check(house.shell_is_present(), "permanent wall shell survives after LEGO attachments tear away")
	_check(house.get_node_or_null("PermanentShell/FrontHeader") is StaticBody3D, "damaged building still retains recognizable facade collision")
	_check(house.get_broken_attachment_count() >= 4, "storm event can remove multiple LEGO attachment modules independently")
	_check(_roof_stages.size() == 3, "roof releases eave, panel, and ridge in three authored stages")
	if _roof_stages.size() == 3:
		_check(_roof_stages[0] == &"eave" and _roof_stages[1] == &"roof_panel" and _roof_stages[2] == &"ridge", "roof damage progresses from edge peel to panel lift to ridge release")
	_check(DestructionManager.active_piece_count() > 0, "detached LEGO architecture becomes physical tornado debris only after breakaway")
	_check(DestructionManager.active_piece_count() <= DestructionManager.maximum_active_pieces, "hybrid building destruction obeys global phone fragment budget")

	if _failures.is_empty():
		print("BRICKSTORM HYBRID BUILDING ENGINE TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error("HYBRID BUILDING TEST FAILURE: " + failure)
	print("BRICKSTORM HYBRID BUILDING ENGINE TEST: FAIL (", _failures.size(), ")")
	get_tree().quit(1)

func _on_roof_stage(cluster_id: StringName) -> void:
	_roof_stages.append(cluster_id)

func _check(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: " + label)
	else:
		_failures.append(label)
