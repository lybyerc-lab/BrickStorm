# @brickstorm.system world
# @brickstorm.role Brick-built powered equipment cage whose gate opens when the matching utility activates and reveals a collectible cache.
# @brickstorm.scope runtime
# @brickstorm.risk medium
# @brickstorm.contract powered_world_change,utility_signal,optional_reward_route
# @brickstorm.north_star lego_twister
# @brickstorm.owner openai/brickstorm

extends Node3D

const StudScene: PackedScene = preload("res://scenes/pickups/stud_pickup.tscn")

@export var required_utility_id: StringName = GameConstants.UTILITY_FARM_GENERATOR

var opened: bool = false
var _gate_body: StaticBody3D

func _ready() -> void:
	_build_cage()
	GameEvents.utility_activated.connect(_on_utility_activated)

func _build_cage() -> void:
	_build_static_wall(Vector3(-2.55, 1.35, -2.1), Vector3(0.44, 2.70, 4.5), "LeftWall")
	_build_static_wall(Vector3(2.55, 1.35, -2.1), Vector3(0.44, 2.70, 4.5), "RightWall")
	_build_static_wall(Vector3(0.0, 1.35, -4.2), Vector3(5.5, 2.70, 0.44), "BackWall")

	_gate_body = StaticBody3D.new()
	_gate_body.name = "PoweredGateBody"
	_gate_body.collision_layer = GameConstants.LAYER_WORLD
	_gate_body.collision_mask = GameConstants.MASK_WORLD
	add_child(_gate_body)
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(4.7, 2.65, 0.44)
	collision.shape = shape
	collision.position = Vector3(0.0, 1.32, 0.0)
	_gate_body.add_child(collision)
	for column in range(6):
		var x_value: float = -1.95 + float(column) * 0.78
		var bar_spec: BrickElementSpec = BrickElementSpec.make(
			BrickElementSpec.KIND_BEAM, 1, 1, 8, BrickPalette.YELLOW, Vector3(x_value, 1.34, 0.0), 0, BrickElementSpec.ROLE_SUPPORT
		)
		BrickBuilder.add_element(_gate_body, bar_spec, "GateBar_%02d" % column)
	var top_spec: BrickElementSpec = BrickElementSpec.make(
		BrickElementSpec.KIND_BRICK, 12, 1, 2, BrickPalette.DARK_BLUE, Vector3(0.0, 2.58, 0.0), 0, BrickElementSpec.ROLE_STRUCTURE
	)
	BrickBuilder.add_element(_gate_body, top_spec, "GateTop")

func _build_static_wall(local_position: Vector3, size_value: Vector3, node_name: String) -> void:
	var collision_body: StaticBody3D = PrimitiveFactory.add_static_box(self, local_position, size_value, BrickPalette.DARK_GRAY, node_name + "Collision")
	var collision_visual: MeshInstance3D = collision_body.get_node_or_null("Visual") as MeshInstance3D
	if collision_visual != null:
		collision_visual.visible = false
	var visible_root: Node3D = Node3D.new()
	visible_root.name = node_name + "Bricks"
	visible_root.position = local_position
	add_child(visible_root)
	var horizontal: bool = size_value.x > size_value.z
	var rows: int = 5
	for row in range(rows):
		var spec: BrickElementSpec
		if horizontal:
			spec = BrickElementSpec.make(BrickElementSpec.KIND_BRICK, 12, 1, 2, BrickPalette.DARK_BLUE if row % 2 == 0 else BrickPalette.BLUE, Vector3(0.0, -1.05 + float(row) * 0.52, 0.0), row, BrickElementSpec.ROLE_STRUCTURE)
		else:
			spec = BrickElementSpec.make(BrickElementSpec.KIND_BRICK, 1, 10, 2, BrickPalette.DARK_BLUE if row % 2 == 0 else BrickPalette.BLUE, Vector3(0.0, -1.05 + float(row) * 0.52, 0.0), row, BrickElementSpec.ROLE_STRUCTURE)
		BrickBuilder.add_element(visible_root, spec, "WallBrick_%02d" % row)

func _on_utility_activated(utility_id: StringName, _source: Node3D) -> void:
	if opened or utility_id != required_utility_id:
		return
	open_gate()

func open_gate() -> void:
	if opened or not is_instance_valid(_gate_body):
		return
	opened = true
	var gate_tween: Tween = create_tween()
	gate_tween.tween_property(_gate_body, "position:y", 3.15, 0.72).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	gate_tween.finished.connect(_spawn_cache)
	GameEvents.camera_shake_requested.emit(0.16, 0.16)

func is_open() -> bool:
	return opened

func _spawn_cache() -> void:
	for index in range(8):
		var stud: Node3D = StudScene.instantiate() as Node3D
		stud.name = "PoweredCacheStud_%02d" % index
		add_child(stud)
		stud.position = Vector3(-1.45 + float(index % 4) * 0.95, 0.72, -2.5 - float(index / 4) * 0.85)
		stud.call("configure_placed", 20 if index < 6 else 50)
	DestructionManager.spawn_destruction_burst(global_position + Vector3(0.0, 1.7, -2.4), BrickPalette.BLUE, Vector3.UP * 1.6, 16, 0.80)
