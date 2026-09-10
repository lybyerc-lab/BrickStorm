# @brickstorm.system world
# @brickstorm.role Reusable LEGO-active building attachment cluster for roofs, windows, doors, trim, and storm-detachable architectural pieces mounted to permanent world shells.
# @brickstorm.scope runtime
# @brickstorm.risk medium
# @brickstorm.contract hybrid_building_attachment,storm_detach,permanent_shell_separation
# @brickstorm.north_star classic_lego_environment
# @brickstorm.owner openai/brickstorm

class_name BuildingAttachmentCluster
extends DestructibleStructure

enum AttachmentKind {
	ROOF_LEFT,
	ROOF_RIGHT,
	WINDOW,
	DOOR,
	SIGN,
}

var attachment_kind: AttachmentKind = AttachmentKind.WINDOW
var primary_color: Color = Color(0.52, 0.17, 0.10)
var accent_color: Color = Color(0.88, 0.84, 0.67)
var pane_color: Color = Color(0.35, 0.60, 0.68, 0.82)
var module_size: Vector3 = Vector3(2.0, 2.0, 0.35)

func configure(kind: AttachmentKind, size_value: Vector3, color: Color, storm_threshold: float) -> void:
	attachment_kind = kind
	module_size = size_value
	primary_color = color
	storm_break_intensity = clampf(storm_threshold, 0.05, 1.0)

func build_structure() -> void:
	# This object is deliberately only the LEGO attachment. The permanent wall
	# shell and its collision belong to HybridRoadsideHouse and survive after this
	# cluster is promoted into bounded physics fragments.
	match attachment_kind:
		AttachmentKind.ROOF_LEFT, AttachmentKind.ROOF_RIGHT:
			_build_roof_half()
		AttachmentKind.WINDOW:
			_build_window()
		AttachmentKind.DOOR:
			_build_door()
		AttachmentKind.SIGN:
			_build_sign()

func get_authored_break_sequence() -> Array[Dictionary]:
	if attachment_kind != AttachmentKind.ROOF_LEFT and attachment_kind != AttachmentKind.ROOF_RIGHT:
		return []
	# Roofs peel in two readable stages instead of atomizing all at once. The
	# intact presentation remains cheap until the tornado actually earns physics.
	return [
		{
			"cluster": &"eave",
			"anticipation": 0.12,
			"delay": 0.08,
			"impulse_scale": 0.82,
			"burst_scale": 0.70,
			"camera_strength": 0.14,
			"studs": 1,
		},
		{
			"cluster": &"roof_panel",
			"anticipation": 0.18,
			"delay": 0.05,
			"impulse_scale": 1.18,
			"burst_scale": 1.05,
			"camera_strength": 0.24,
			"studs": 2,
		},
		{
			"cluster": &"ridge",
			"anticipation": 0.10,
			"impulse_scale": 1.32,
			"burst_scale": 0.85,
			"camera_strength": 0.19,
			"studs": 1,
		},
	]

func _build_roof_half() -> void:
	durability = 1.55
	stud_count = 4
	stud_value = StudCurrency.VALUE_SILVER
	fragment_lifetime = 7.5
	maximum_spawned_fragments = 18
	var side: float = -1.0 if attachment_kind == AttachmentKind.ROOF_LEFT else 1.0
	# A handful of broad plate-like LEGO modules reads as a roof but stays cheap.
	for row in range(3):
		var row_z: float = -1.72 + float(row) * 1.72
		for column in range(2):
			var local_x: float = side * (1.30 + float(column) * 2.55)
			var local_y: float = 0.46 - float(column) * 0.96
			var cluster_id: StringName = &"roof_panel"
			if row == 0:
				cluster_id = &"eave"
			add_intact_brick(
				Vector3(local_x, local_y, row_z),
				Vector3(2.68, 0.24, 1.82),
				primary_color,
				0.42,
				Vector3(0.0, 0.0, -22.0 * side),
				cluster_id
			)
	# One long ridge plate per half provides the final visual release.
	add_intact_brick(
		Vector3(side * 0.30, 0.96, 0.0),
		Vector3(0.58, 0.24, 5.55),
		accent_color,
		0.38,
		Vector3(0.0, 0.0, -22.0 * side),
		&"ridge"
	)

func _build_window() -> void:
	durability = 0.82
	stud_count = 2
	stud_value = StudCurrency.VALUE_SILVER
	fragment_lifetime = 6.0
	maximum_spawned_fragments = 10
	var half_w: float = module_size.x * 0.5
	var half_h: float = module_size.y * 0.5
	var frame: float = 0.18
	add_intact_brick(Vector3(-half_w + frame * 0.5, 0.0, 0.0), Vector3(frame, module_size.y, 0.28), primary_color, 0.20)
	add_intact_brick(Vector3(half_w - frame * 0.5, 0.0, 0.0), Vector3(frame, module_size.y, 0.28), primary_color, 0.20)
	add_intact_brick(Vector3(0.0, half_h - frame * 0.5, 0.0), Vector3(module_size.x, frame, 0.28), primary_color, 0.20)
	add_intact_brick(Vector3(0.0, -half_h + frame * 0.5, 0.0), Vector3(module_size.x, frame, 0.28), primary_color, 0.20)
	# Pane is deliberately toy-like and remains part of the detachable module.
	add_intact_brick(Vector3(0.0, 0.0, -0.02), Vector3(module_size.x - 0.32, module_size.y - 0.32, 0.10), pane_color, 0.16)
	add_collision_box(Vector3.ZERO, Vector3(module_size.x, module_size.y, 0.26))

func _build_door() -> void:
	durability = 1.0
	stud_count = 3
	stud_value = StudCurrency.VALUE_SILVER
	fragment_lifetime = 6.5
	maximum_spawned_fragments = 12
	# Vertical LEGO planks make the door read as brick-built without creating a
	# dense micro-brick surface.
	for column in range(3):
		var local_x: float = -0.58 + float(column) * 0.58
		add_intact_brick(Vector3(local_x, 0.0, 0.0), Vector3(0.58, module_size.y, 0.30), primary_color, 0.28)
	add_intact_brick(Vector3(0.0, module_size.y * 0.34, 0.18), Vector3(1.64, 0.20, 0.20), accent_color, 0.18)
	add_intact_brick(Vector3(0.0, -module_size.y * 0.34, 0.18), Vector3(1.64, 0.20, 0.20), accent_color, 0.18)
	add_intact_brick(Vector3(0.53, 0.0, 0.22), Vector3(0.18, 0.18, 0.18), accent_color, 0.12)
	add_collision_box(Vector3.ZERO, Vector3(module_size.x, module_size.y, 0.34))

func _build_sign() -> void:
	durability = 0.58
	stud_count = 2
	stud_value = StudCurrency.VALUE_SILVER
	fragment_lifetime = 5.5
	maximum_spawned_fragments = 8
	add_intact_brick(Vector3.ZERO, module_size, primary_color, 0.34)
	add_intact_brick(Vector3(0.0, 0.0, module_size.z * 0.58), Vector3(module_size.x * 0.62, module_size.y * 0.16, 0.12), accent_color, 0.16)
	add_collision_box(Vector3.ZERO, module_size)
