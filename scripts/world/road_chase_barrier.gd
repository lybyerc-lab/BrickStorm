# @brickstorm.system world
# @brickstorm.role Road-chase barrier controlled by the first production InteractionGraph chain.
# @brickstorm.scope runtime
# @brickstorm.risk medium
# @brickstorm.contract road_chase_gate,interaction_graph_output
# @brickstorm.north_star classic_lego_level_rhythm
# @brickstorm.owner openai/brickstorm

class_name RoadChaseBarrier
extends Node3D

var opened: bool = false
var _gate_body: StaticBody3D

func _ready() -> void:
	_build_barrier()

func _build_barrier() -> void:
	var side_values: PackedFloat32Array = PackedFloat32Array([-1.0, 1.0])
	for side: float in side_values:
		var post_root: Node3D = Node3D.new()
		post_root.name = "BarrierPost_%s" % ("L" if side < 0.0 else "R")
		post_root.position = Vector3(side * 4.25, 0.0, 0.0)
		add_child(post_root)
		BrickBuilder.add_brick(post_root, Vector3(0.0, 0.52, 0.0), 2, 2, 6, BrickPalette.DARK_BLUE, "PostBase")
		BrickBuilder.add_brick(post_root, Vector3(0.0, 1.34, 0.0), 1, 1, 6, BrickPalette.YELLOW, "PostTop")

	_gate_body = StaticBody3D.new()
	_gate_body.name = "RoadBarrierBody"
	_gate_body.collision_layer = GameConstants.LAYER_WORLD
	_gate_body.collision_mask = GameConstants.MASK_WORLD
	add_child(_gate_body)
	PrimitiveFactory.add_box_collision(_gate_body, Vector3(0.0, 1.05, 0.0), Vector3(8.0, 1.35, 0.50))
	for segment in range(8):
		var x_value: float = -3.45 + float(segment) * 0.98
		var color: Color = BrickPalette.WHITE if segment % 2 == 0 else BrickPalette.RED
		BrickBuilder.add_brick(_gate_body, Vector3(x_value, 1.05, 0.0), 2, 1, 3, color, "BarrierSegment_%02d" % segment)
	BrickBuilder.add_tile(_gate_body, Vector3(0.0, 1.82, 0.0), 8, 1, 1, BrickPalette.YELLOW, "WarningTop")

func open_gate() -> void:
	if opened or not is_instance_valid(_gate_body):
		return
	opened = true
	AudioDirector.play_secret()
	GameEvents.camera_focus_requested.emit(global_position + Vector3.UP * 1.3, 0.9, 54.0)
	GameEvents.camera_shake_requested.emit(0.13, 0.14)
	var tween: Tween = create_tween()
	tween.tween_property(_gate_body, "position:y", 3.25, 0.58).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func is_open() -> bool:
	return opened
