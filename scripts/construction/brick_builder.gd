# @brickstorm.system construction
# @brickstorm.role Procedural renderer for tagged brick element specs used by vehicles, props, architecture, and build previews.
# @brickstorm.scope runtime
# @brickstorm.risk high
# @brickstorm.contract element_rendering,stud_layout,brick_blueprint
# @brickstorm.north_star classic_lego_mobile
# @brickstorm.owner openai/brickstorm

class_name BrickBuilder
extends RefCounted

static func add_element(parent: Node3D, spec: BrickElementSpec, node_name: String = "BrickElement") -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = node_name
	root.position = spec.position
	root.rotation_degrees = spec.rotation_degrees
	parent.add_child(root)

	if spec.kind == BrickElementSpec.KIND_ROUND or spec.kind == BrickElementSpec.KIND_BAR:
		_add_round_body(root, spec)
	elif spec.kind == BrickElementSpec.KIND_WHEEL:
		_add_wheel_body(root, spec)
	elif spec.kind == BrickElementSpec.KIND_ARCH:
		_add_arch_body(root, spec)
	elif spec.kind == BrickElementSpec.KIND_SLOPE or spec.kind == BrickElementSpec.KIND_INVERTED_SLOPE:
		_add_stepped_slope(root, spec)
	else:
		_add_box_body(root, spec)

	if spec.show_studs and spec.kind != BrickElementSpec.KIND_TILE and spec.kind != BrickElementSpec.KIND_WHEEL and spec.kind != BrickElementSpec.KIND_BAR:
		_add_studs(root, spec)
	if spec.underside_detail:
		_add_underside_tubes(root, spec)
	return root

static func add_brick(
	parent: Node3D,
	position: Vector3,
	studs_x: int,
	studs_z: int,
	plates_high: int,
	color: Color,
	node_name: String,
	rotation_degrees: Vector3 = Vector3.ZERO
) -> Node3D:
	var spec: BrickElementSpec = BrickElementSpec.new()
	spec.kind = BrickElementSpec.KIND_BRICK
	spec.studs_x = studs_x
	spec.studs_z = studs_z
	spec.plates_high = plates_high
	spec.color = color
	spec.position = position
	spec.rotation_degrees = rotation_degrees
	return add_element(parent, spec, node_name)

static func add_tile(
	parent: Node3D,
	position: Vector3,
	studs_x: int,
	studs_z: int,
	plates_high: int,
	color: Color,
	node_name: String,
	rotation_degrees: Vector3 = Vector3.ZERO
) -> Node3D:
	var spec: BrickElementSpec = BrickElementSpec.new()
	spec.kind = BrickElementSpec.KIND_TILE
	spec.studs_x = studs_x
	spec.studs_z = studs_z
	spec.plates_high = plates_high
	spec.color = color
	spec.position = position
	spec.rotation_degrees = rotation_degrees
	spec.show_studs = false
	spec.semantic_role = BrickElementSpec.ROLE_TRIM
	return add_element(parent, spec, node_name)

static func add_glass_panel(
	parent: Node3D,
	position: Vector3,
	studs_x: int,
	studs_z: int,
	plates_high: int,
	color: Color,
	node_name: String,
	rotation_degrees: Vector3 = Vector3.ZERO
) -> Node3D:
	var spec: BrickElementSpec = BrickElementSpec.new()
	spec.kind = BrickElementSpec.KIND_PANEL
	spec.studs_x = studs_x
	spec.studs_z = studs_z
	spec.plates_high = plates_high
	spec.color = color
	spec.position = position
	spec.rotation_degrees = rotation_degrees
	spec.show_studs = false
	spec.transparent = true
	spec.roughness = BrickPalette.TRANSPARENT_ROUGHNESS
	spec.semantic_role = BrickElementSpec.ROLE_GLASS
	return add_element(parent, spec, node_name)

static func add_wheel(parent: Node3D, position: Vector3, radius: float, width: float, node_name: String = "Wheel") -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = node_name
	root.position = position
	parent.add_child(root)
	var tire: MeshInstance3D = PrimitiveFactory.add_cylinder_mesh(root, Vector3.ZERO, radius, width, BrickPalette.RUBBER, "Tire", 16)
	tire.rotation_degrees.z = 90.0
	tire.material_override = PrimitiveFactory.material(BrickPalette.RUBBER, BrickPalette.RUBBER_ROUGHNESS)
	var hub: MeshInstance3D = PrimitiveFactory.add_cylinder_mesh(root, Vector3.ZERO, radius * 0.48, width * 1.06, BrickPalette.LIGHT_GRAY, "Hub", 12)
	hub.rotation_degrees.z = 90.0
	hub.material_override = PrimitiveFactory.material(BrickPalette.LIGHT_GRAY, BrickPalette.PLASTIC_ROUGHNESS)
	return root

static func _add_box_body(root: Node3D, spec: BrickElementSpec) -> void:
	var body: MeshInstance3D = PrimitiveFactory.add_box_mesh(root, Vector3.ZERO, spec.body_size(), spec.color, "Body")
	body.material_override = PrimitiveFactory.material(spec.color, spec.roughness, spec.metallic)

static func _add_round_body(root: Node3D, spec: BrickElementSpec) -> void:
	var size_value: Vector3 = spec.body_size()
	var radius: float = minf(size_value.x, size_value.z) * 0.5
	var body: MeshInstance3D = PrimitiveFactory.add_cylinder_mesh(root, Vector3.ZERO, radius, size_value.y, spec.color, "RoundBody", 14)
	body.material_override = PrimitiveFactory.material(spec.color, spec.roughness, spec.metallic)

static func _add_wheel_body(root: Node3D, spec: BrickElementSpec) -> void:
	var size_value: Vector3 = spec.body_size()
	var radius: float = maxf(0.14, maxf(size_value.x, size_value.y) * 0.5)
	var width: float = maxf(0.12, size_value.z)
	var tire: MeshInstance3D = PrimitiveFactory.add_cylinder_mesh(root, Vector3.ZERO, radius, width, BrickPalette.RUBBER, "Tire", 16)
	tire.rotation_degrees.z = 90.0
	tire.material_override = PrimitiveFactory.material(BrickPalette.RUBBER, BrickPalette.RUBBER_ROUGHNESS)

static func _add_arch_body(root: Node3D, spec: BrickElementSpec) -> void:
	var size_value: Vector3 = spec.body_size()
	var leg_width: float = maxf(0.14, size_value.x * 0.22)
	var top_height: float = maxf(0.12, size_value.y * 0.34)
	var leg_height: float = maxf(0.12, size_value.y - top_height)
	var left: MeshInstance3D = PrimitiveFactory.add_box_mesh(root, Vector3(-size_value.x * 0.5 + leg_width * 0.5, -top_height * 0.5, 0.0), Vector3(leg_width, leg_height, size_value.z), spec.color, "ArchLeft")
	var right: MeshInstance3D = PrimitiveFactory.add_box_mesh(root, Vector3(size_value.x * 0.5 - leg_width * 0.5, -top_height * 0.5, 0.0), Vector3(leg_width, leg_height, size_value.z), spec.color, "ArchRight")
	var top: MeshInstance3D = PrimitiveFactory.add_box_mesh(root, Vector3(0.0, size_value.y * 0.5 - top_height * 0.5, 0.0), Vector3(size_value.x, top_height, size_value.z), spec.color, "ArchTop")
	var material: StandardMaterial3D = PrimitiveFactory.material(spec.color, spec.roughness, spec.metallic)
	left.material_override = material
	right.material_override = material
	top.material_override = material

static func _add_stepped_slope(root: Node3D, spec: BrickElementSpec) -> void:
	var size_value: Vector3 = spec.body_size()
	var step_count: int = clampi(spec.studs_z, 2, 5)
	var step_depth: float = size_value.z / float(step_count)
	for step_index in range(step_count):
		var ratio: float = float(step_index + 1) / float(step_count)
		var height: float = maxf(BrickDimensions.PLATE_HEIGHT * 0.72, size_value.y * ratio)
		if spec.kind == BrickElementSpec.KIND_INVERTED_SLOPE:
			height = maxf(BrickDimensions.PLATE_HEIGHT * 0.72, size_value.y * (1.0 - float(step_index) / float(step_count)))
		var z_value: float = -size_value.z * 0.5 + step_depth * (float(step_index) + 0.5)
		var y_value: float = -size_value.y * 0.5 + height * 0.5
		var step: MeshInstance3D = PrimitiveFactory.add_box_mesh(root, Vector3(0.0, y_value, z_value), Vector3(size_value.x, height, step_depth - BrickDimensions.EDGE_GAP), spec.color, "SlopeStep_%02d" % step_index)
		step.material_override = PrimitiveFactory.material(spec.color, spec.roughness, spec.metallic)

static func _add_studs(root: Node3D, spec: BrickElementSpec) -> void:
	var size_value: Vector3 = spec.body_size()
	var stud_color: Color = BrickPalette.accent_for(spec.color)
	for x_index in range(maxi(1, spec.studs_x)):
		for z_index in range(maxi(1, spec.studs_z)):
			var stud_position: Vector3 = Vector3(
				BrickDimensions.stud_axis_position(x_index, spec.studs_x),
				size_value.y * 0.5 + BrickDimensions.STUD_HEIGHT * 0.5,
				BrickDimensions.stud_axis_position(z_index, spec.studs_z)
			)
			var stud: MeshInstance3D = PrimitiveFactory.add_cylinder_mesh(root, stud_position, BrickDimensions.STUD_RADIUS, BrickDimensions.STUD_HEIGHT, stud_color, "Stud_%02d_%02d" % [x_index, z_index], 10, false)
			stud.material_override = PrimitiveFactory.material(stud_color, spec.roughness, spec.metallic)

static func _add_underside_tubes(root: Node3D, spec: BrickElementSpec) -> void:
	if spec.studs_x < 2 or spec.studs_z < 2:
		return
	var size_value: Vector3 = spec.body_size()
	for x_index in range(spec.studs_x - 1):
		for z_index in range(spec.studs_z - 1):
			var tube_x: float = BrickDimensions.stud_axis_position(x_index, spec.studs_x - 1) + BrickDimensions.STUD_PITCH * 0.5
			var tube_z: float = BrickDimensions.stud_axis_position(z_index, spec.studs_z - 1) + BrickDimensions.STUD_PITCH * 0.5
			var tube: MeshInstance3D = PrimitiveFactory.add_cylinder_mesh(root, Vector3(tube_x, -size_value.y * 0.5 + 0.045, tube_z), BrickDimensions.STUD_RADIUS * 0.82, 0.07, spec.color, "Tube_%02d_%02d" % [x_index, z_index], 10, false)
			tube.material_override = PrimitiveFactory.material(spec.color, spec.roughness, spec.metallic)
