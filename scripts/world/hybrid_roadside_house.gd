# @brickstorm.system world
# @brickstorm.role First production hybrid building prototype: permanent non-LEGO shell plus independently addressable LEGO roof, window, door, and sign attachment modules.
# @brickstorm.scope runtime
# @brickstorm.risk medium
# @brickstorm.contract permanent_world_shell,lego_attachment_layer,hybrid_building_tornado_damage
# @brickstorm.north_star classic_lego_environment
# @brickstorm.owner openai/brickstorm

class_name HybridRoadsideHouse
extends Node3D

var shell_root: Node3D
var attachment_root: Node3D
var _attachments: Array[BuildingAttachmentCluster] = []

func _ready() -> void:
	_build_shell()
	_build_attachments()

func get_attachment_count() -> int:
	return _attachments.size()

func get_broken_attachment_count() -> int:
	var count: int = 0
	for attachment: BuildingAttachmentCluster in _attachments:
		if is_instance_valid(attachment) and attachment.broken:
			count += 1
	return count

func shell_is_present() -> bool:
	return is_instance_valid(shell_root) and not shell_root.is_queued_for_deletion()

func get_attachment_by_name(attachment_name: StringName) -> BuildingAttachmentCluster:
	for attachment: BuildingAttachmentCluster in _attachments:
		if is_instance_valid(attachment) and StringName(attachment.name) == attachment_name:
			return attachment
	return null

func _build_shell() -> void:
	shell_root = Node3D.new()
	shell_root.name = "PermanentShell"
	add_child(shell_root)

	var wall_color: Color = Color(0.66, 0.61, 0.48)
	var foundation_color: Color = Color(0.38, 0.37, 0.33)
	var interior_dark: Color = Color(0.16, 0.15, 0.13)
	# Foundation and walls are ordinary world geometry. Openings are authored as
	# negative spaces between simple wall blocks so LEGO modules can detach while
	# the damaged building remains recognizable.
	PrimitiveFactory.add_static_box(shell_root, Vector3(0.0, 0.24, 0.0), Vector3(10.6, 0.48, 7.8), foundation_color, "Foundation")
	# Back wall and side walls.
	PrimitiveFactory.add_static_box(shell_root, Vector3(0.0, 2.25, -3.55), Vector3(10.2, 4.1, 0.42), wall_color, "BackWall")
	PrimitiveFactory.add_static_box(shell_root, Vector3(-4.90, 2.25, 0.0), Vector3(0.42, 4.1, 7.2), wall_color, "LeftWall")
	PrimitiveFactory.add_static_box(shell_root, Vector3(4.90, 2.25, 0.0), Vector3(0.42, 4.1, 7.2), wall_color, "RightWall")
	# Front facade around a centered door and two windows.
	PrimitiveFactory.add_static_box(shell_root, Vector3(0.0, 4.00, 3.55), Vector3(10.2, 0.60, 0.42), wall_color, "FrontHeader")
	PrimitiveFactory.add_static_box(shell_root, Vector3(-4.15, 2.15, 3.55), Vector3(1.70, 3.10, 0.42), wall_color, "FrontFarLeft")
	PrimitiveFactory.add_static_box(shell_root, Vector3(4.15, 2.15, 3.55), Vector3(1.70, 3.10, 0.42), wall_color, "FrontFarRight")
	PrimitiveFactory.add_static_box(shell_root, Vector3(-1.78, 2.05, 3.55), Vector3(1.05, 3.25, 0.42), wall_color, "FrontMidLeft")
	PrimitiveFactory.add_static_box(shell_root, Vector3(1.78, 2.05, 3.55), Vector3(1.05, 3.25, 0.42), wall_color, "FrontMidRight")
	PrimitiveFactory.add_static_box(shell_root, Vector3(0.0, 0.60, 3.55), Vector3(1.90, 0.72, 0.42), wall_color, "DoorSillWall")
	# Dark recesses make detached LEGO windows/door read as actual openings.
	PrimitiveFactory.add_box_mesh(shell_root, Vector3(-2.95, 2.30, 3.34), Vector3(1.55, 1.85, 0.06), interior_dark, "LeftWindowVoid", false)
	PrimitiveFactory.add_box_mesh(shell_root, Vector3(2.95, 2.30, 3.34), Vector3(1.55, 1.85, 0.06), interior_dark, "RightWindowVoid", false)
	PrimitiveFactory.add_box_mesh(shell_root, Vector3(0.0, 1.75, 3.34), Vector3(1.86, 2.85, 0.06), interior_dark, "DoorVoid", false)
	# Simple gable mass is shell geometry. The visible pitched roof surface is LEGO.
	var gable: MeshInstance3D = PrimitiveFactory.add_frustum_mesh(
		shell_root, Vector3(0.0, 4.62, 0.0),
		Vector2(2.4, 7.1), Vector2(9.8, 7.1), 1.25,
		wall_color, "GableMass"
	)
	gable.rotation_degrees.z = 0.0

func _build_attachments() -> void:
	attachment_root = Node3D.new()
	attachment_root.name = "LegoAttachmentLayer"
	add_child(attachment_root)

	_add_attachment(
		"RoofLeft", BuildingAttachmentCluster.AttachmentKind.ROOF_LEFT,
		Vector3(0.0, 5.02, 0.0), Vector3(5.2, 0.4, 5.6),
		Color(0.46, 0.14, 0.08), 0.66
	)
	_add_attachment(
		"RoofRight", BuildingAttachmentCluster.AttachmentKind.ROOF_RIGHT,
		Vector3(0.0, 5.02, 0.0), Vector3(5.2, 0.4, 5.6),
		Color(0.46, 0.14, 0.08), 0.70
	)
	_add_attachment(
		"FrontWindowLeft", BuildingAttachmentCluster.AttachmentKind.WINDOW,
		Vector3(-2.95, 2.30, 3.72), Vector3(1.70, 1.95, 0.30),
		Color(0.88, 0.84, 0.67), 0.42
	)
	_add_attachment(
		"FrontWindowRight", BuildingAttachmentCluster.AttachmentKind.WINDOW,
		Vector3(2.95, 2.30, 3.72), Vector3(1.70, 1.95, 0.30),
		Color(0.88, 0.84, 0.67), 0.46
	)
	_add_attachment(
		"FrontDoor", BuildingAttachmentCluster.AttachmentKind.DOOR,
		Vector3(0.0, 1.78, 3.74), Vector3(1.82, 2.90, 0.34),
		Color(0.20, 0.35, 0.48), 0.52
	)
	var sign: BuildingAttachmentCluster = _add_attachment(
		"StormStopSign", BuildingAttachmentCluster.AttachmentKind.SIGN,
		Vector3(0.0, 3.72, 3.94), Vector3(2.70, 0.62, 0.24),
		Color(0.85, 0.55, 0.10), 0.30
	)
	if sign != null:
		sign.rotation_degrees.z = -2.0

func _add_attachment(
	attachment_name: String,
	kind: BuildingAttachmentCluster.AttachmentKind,
	local_position: Vector3,
	size_value: Vector3,
	color: Color,
	storm_threshold: float
) -> BuildingAttachmentCluster:
	var attachment: BuildingAttachmentCluster = BuildingAttachmentCluster.new()
	attachment.name = attachment_name
	attachment.position = local_position
	attachment.configure(kind, size_value, color, storm_threshold)
	attachment_root.add_child(attachment)
	_attachments.append(attachment)
	return attachment
