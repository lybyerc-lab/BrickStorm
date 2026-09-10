extends RefCounted
class_name BrickBuilder

# Authentic LEGO scale constants (in game meters)
const STUD_PITCH: float = 0.40      # Distance between stud centers
const PLATE_HEIGHT: float = 0.16    # Height of a 1x plate
const BRICK_HEIGHT: float = 0.48    # Height of a standard brick (3 plates)
const STUD_RADIUS: float = 0.11     # Radius of top stud cylinder
const STUD_HEIGHT: float = 0.075    # Height of top stud cylinder

static var _mat_cache: Dictionary = {}

static func get_plastic_material(color: Color) -> StandardMaterial3D:
	var key = color.to_html()
	if not _mat_cache.has(key):
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.18 # Glossy ABS plastic
		mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
		mat.metallic = 0.0
		# Plastic rim/Fresnel sheen
		mat.rim_enabled = true
		mat.rim = 0.35
		mat.rim_tint = 0.4
		_mat_cache[key] = mat
	return _mat_cache[key]

static func create_brick(width_studs: int, length_studs: int, height_plates: int, color: Color, with_studs: bool = true) -> Node3D:
	var root_node = Node3D.new()
	var mat = get_plastic_material(color)
	
	var total_w = width_studs * STUD_PITCH
	var total_h = height_plates * PLATE_HEIGHT
	var total_l = length_studs * STUD_PITCH
	
	# Main body box
	var body = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(total_w, total_h, total_l)
	body.mesh = box
	body.material_override = mat
	body.position = Vector3(0, total_h * 0.5, 0)
	root_node.add_child(body)
	
	# Circular studs on top surface
	if with_studs:
		var top_y = total_h + (STUD_HEIGHT * 0.5)
		var half_w = (width_studs - 1) * 0.5
		var half_l = (length_studs - 1) * 0.5
		
		for sx in range(width_studs):
			for sz in range(length_studs):
				var stud_mesh = MeshInstance3D.new()
				var cyl = CylinderMesh.new()
				cyl.top_radius = STUD_RADIUS
				cyl.bottom_radius = STUD_RADIUS
				cyl.height = STUD_HEIGHT
				cyl.radial_segments = 12
				stud_mesh.mesh = cyl
				stud_mesh.material_override = mat
				
				var px = (sx - half_w) * STUD_PITCH
				var pz = (sz - half_l) * STUD_PITCH
				stud_mesh.position = Vector3(px, top_y, pz)
				root_node.add_child(stud_mesh)
				
	return root_node

static func create_2x4_brick(color: Color) -> Node3D:
	return create_brick(2, 4, 3, color, true)

static func create_2x2_brick(color: Color) -> Node3D:
	return create_brick(2, 2, 3, color, true)

static func create_1x2_plate(color: Color) -> Node3D:
	return create_brick(1, 2, 1, color, true)

static func create_2x2_tile(color: Color) -> Node3D:
	# Smooth tile (no studs)
	return create_brick(2, 2, 1, color, false)

static func create_round_stud(color: Color) -> Node3D:
	var root_node = Node3D.new()
	var mat = get_plastic_material(color)
	
	var cyl_base = MeshInstance3D.new()
	var base_mesh = CylinderMesh.new()
	base_mesh.top_radius = STUD_PITCH * 0.45
	base_mesh.bottom_radius = STUD_PITCH * 0.45
	base_mesh.height = PLATE_HEIGHT
	base_mesh.radial_segments = 12
	cyl_base.mesh = base_mesh
	cyl_base.material_override = mat
	cyl_base.position = Vector3(0, PLATE_HEIGHT * 0.5, 0)
	root_node.add_child(cyl_base)
	
	var stud_pip = MeshInstance3D.new()
	var pip_mesh = CylinderMesh.new()
	pip_mesh.top_radius = STUD_RADIUS
	pip_mesh.bottom_radius = STUD_RADIUS
	pip_mesh.height = STUD_HEIGHT
	pip_mesh.radial_segments = 10
	stud_pip.mesh = pip_mesh
	stud_pip.material_override = mat
	stud_pip.position = Vector3(0, PLATE_HEIGHT + STUD_HEIGHT * 0.5, 0)
	root_node.add_child(stud_pip)
	
	return root_node
