# @brickstorm.system util
# @brickstorm.role Cached procedural placeholder meshes, materials, collision shapes, and simple static geometry helpers.
# @brickstorm.scope runtime
# @brickstorm.risk low
# @brickstorm.contract none
# @brickstorm.north_star foundation
# @brickstorm.owner openai/brickstorm

class_name PrimitiveFactory
extends RefCounted

# Procedural placeholder art is intentionally cached. Reusing meshes, materials,
# and collision shapes keeps a brick-heavy scene much friendlier to phones.
static var _material_cache: Dictionary = {}
static var _box_mesh_cache: Dictionary = {}
static var _cylinder_mesh_cache: Dictionary = {}
static var _sphere_mesh_cache: Dictionary = {}
static var _frustum_mesh_cache: Dictionary = {}
static var _box_shape_cache: Dictionary = {}
static var _capsule_shape_cache: Dictionary = {}

static func material(color: Color, roughness: float = 0.88, metallic: float = 0.0) -> StandardMaterial3D:
	var key: String = "%s|%.3f|%.3f" % [color.to_html(true), roughness, metallic]
	if _material_cache.has(key):
		return _material_cache[key] as StandardMaterial3D
	var result: StandardMaterial3D = StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	result.metallic = metallic
	if color.a < 0.995:
		result.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		result.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	_material_cache[key] = result
	return result

static func box_mesh(size_value: Vector3) -> BoxMesh:
	var key: String = _vector_key(size_value)
	if _box_mesh_cache.has(key):
		return _box_mesh_cache[key] as BoxMesh
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size_value
	_box_mesh_cache[key] = mesh
	return mesh

static func cylinder_mesh(radius: float, height: float, radial_segments: int = 12) -> CylinderMesh:
	var key: String = "%.4f|%.4f|%d" % [radius, height, radial_segments]
	if _cylinder_mesh_cache.has(key):
		return _cylinder_mesh_cache[key] as CylinderMesh
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = radial_segments
	_cylinder_mesh_cache[key] = mesh
	return mesh


static func frustum_box_mesh(top_size: Vector2, bottom_size: Vector2, height: float) -> ArrayMesh:
	var key: String = "%.4f|%.4f|%.4f|%.4f|%.4f" % [top_size.x, top_size.y, bottom_size.x, bottom_size.y, height]
	if _frustum_mesh_cache.has(key):
		return _frustum_mesh_cache[key] as ArrayMesh
	var top_x: float = top_size.x * 0.5
	var top_z: float = top_size.y * 0.5
	var bottom_x: float = bottom_size.x * 0.5
	var bottom_z: float = bottom_size.y * 0.5
	var half_h: float = height * 0.5
	var b0: Vector3 = Vector3(-bottom_x, -half_h, -bottom_z)
	var b1: Vector3 = Vector3(bottom_x, -half_h, -bottom_z)
	var b2: Vector3 = Vector3(bottom_x, -half_h, bottom_z)
	var b3: Vector3 = Vector3(-bottom_x, -half_h, bottom_z)
	var t0: Vector3 = Vector3(-top_x, half_h, -top_z)
	var t1: Vector3 = Vector3(top_x, half_h, -top_z)
	var t2: Vector3 = Vector3(top_x, half_h, top_z)
	var t3: Vector3 = Vector3(-top_x, half_h, top_z)
	var triangles: Array[Vector3] = [
		b0, b2, b1, b0, b3, b2,
		t0, t1, t2, t0, t2, t3,
		b0, b1, t1, b0, t1, t0,
		b1, b2, t2, b1, t2, t1,
		b2, b3, t3, b2, t3, t2,
		b3, b0, t0, b3, t0, t3,
	]
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex: Vector3 in triangles:
		surface.add_vertex(vertex)
	surface.generate_normals()
	var mesh: ArrayMesh = surface.commit()
	_frustum_mesh_cache[key] = mesh
	return mesh

static func sphere_mesh(radius: float) -> SphereMesh:
	var key: String = "%.4f" % radius
	if _sphere_mesh_cache.has(key):
		return _sphere_mesh_cache[key] as SphereMesh
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	_sphere_mesh_cache[key] = mesh
	return mesh

static func box_shape(size_value: Vector3) -> BoxShape3D:
	var key: String = _vector_key(size_value)
	if _box_shape_cache.has(key):
		return _box_shape_cache[key] as BoxShape3D
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size_value
	_box_shape_cache[key] = shape
	return shape

static func capsule_shape(radius: float, height: float) -> CapsuleShape3D:
	var key: String = "%.4f|%.4f" % [radius, height]
	if _capsule_shape_cache.has(key):
		return _capsule_shape_cache[key] as CapsuleShape3D
	var shape: CapsuleShape3D = CapsuleShape3D.new()
	shape.radius = radius
	shape.height = height
	_capsule_shape_cache[key] = shape
	return shape

static func add_box_mesh(parent: Node, local_position: Vector3, size_value: Vector3, color: Color, node_name: String = "Box", cast_shadow: bool = true) -> MeshInstance3D:
	var mesh_node: MeshInstance3D = MeshInstance3D.new()
	mesh_node.name = node_name
	mesh_node.mesh = box_mesh(size_value)
	mesh_node.position = local_position
	mesh_node.material_override = material(color)
	if not cast_shadow:
		mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh_node)
	return mesh_node


static func add_frustum_mesh(parent: Node, local_position: Vector3, top_size: Vector2, bottom_size: Vector2, height: float, color: Color, node_name: String = "Frustum", cast_shadow: bool = true) -> MeshInstance3D:
	var mesh_node: MeshInstance3D = MeshInstance3D.new()
	mesh_node.name = node_name
	mesh_node.mesh = frustum_box_mesh(top_size, bottom_size, height)
	mesh_node.position = local_position
	mesh_node.material_override = material(color)
	if not cast_shadow:
		mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh_node)
	return mesh_node

static func add_cylinder_mesh(parent: Node, local_position: Vector3, radius: float, height: float, color: Color, node_name: String = "Cylinder", radial_segments: int = 12, cast_shadow: bool = true) -> MeshInstance3D:
	var mesh_node: MeshInstance3D = MeshInstance3D.new()
	mesh_node.name = node_name
	mesh_node.mesh = cylinder_mesh(radius, height, radial_segments)
	mesh_node.position = local_position
	mesh_node.material_override = material(color)
	if not cast_shadow:
		mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh_node)
	return mesh_node

static func add_sphere_mesh(parent: Node, local_position: Vector3, radius: float, color: Color, node_name: String = "Sphere", cast_shadow: bool = true) -> MeshInstance3D:
	var mesh_node: MeshInstance3D = MeshInstance3D.new()
	mesh_node.name = node_name
	mesh_node.mesh = sphere_mesh(radius)
	mesh_node.position = local_position
	mesh_node.material_override = material(color)
	if not cast_shadow:
		mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh_node)
	return mesh_node

static func add_box_collision(parent: Node, local_position: Vector3, size_value: Vector3, node_name: String = "CollisionShape3D") -> CollisionShape3D:
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = node_name
	collision.shape = box_shape(size_value)
	collision.position = local_position
	parent.add_child(collision)
	return collision

static func add_capsule_collision(parent: Node, local_position: Vector3, radius: float, height: float, node_name: String = "CollisionShape3D") -> CollisionShape3D:
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = node_name
	collision.shape = capsule_shape(radius, height)
	collision.position = local_position
	parent.add_child(collision)
	return collision

static func add_static_box(parent: Node, local_position: Vector3, size_value: Vector3, color: Color, node_name: String = "StaticBox") -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = node_name
	body.position = local_position
	body.collision_layer = GameConstants.LAYER_WORLD
	body.collision_mask = GameConstants.MASK_WORLD
	parent.add_child(body)
	add_box_mesh(body, Vector3.ZERO, size_value, color, "Visual")
	add_box_collision(body, Vector3.ZERO, size_value)
	return body

static func _vector_key(value: Vector3) -> String:
	return "%.4f|%.4f|%.4f" % [value.x, value.y, value.z]
