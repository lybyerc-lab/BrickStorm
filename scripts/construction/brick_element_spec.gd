# @brickstorm.system construction
# @brickstorm.role Data contract for one authored brick element, including visual, build-order, and destruction semantics.
# @brickstorm.scope runtime
# @brickstorm.risk high
# @brickstorm.contract element_spec,semantic_role,break_cluster,build_order
# @brickstorm.north_star classic_lego_mobile
# @brickstorm.owner openai/brickstorm

class_name BrickElementSpec
extends RefCounted

const KIND_BRICK: StringName = &"brick"
const KIND_PLATE: StringName = &"plate"
const KIND_TILE: StringName = &"tile"
const KIND_SLOPE: StringName = &"slope"
const KIND_INVERTED_SLOPE: StringName = &"inverted_slope"
const KIND_ROUND: StringName = &"round"
const KIND_CONE: StringName = &"cone"
const KIND_WHEEL: StringName = &"wheel"
const KIND_BEAM: StringName = &"beam"
const KIND_TECHNIC_BEAM: StringName = &"technic_beam"
const KIND_ARCH: StringName = &"arch"
const KIND_BAR: StringName = &"bar"
const KIND_PANEL: StringName = &"panel"

const ROLE_STRUCTURE: StringName = &"structure"
const ROLE_TRIM: StringName = &"trim"
const ROLE_GLASS: StringName = &"glass"
const ROLE_ROOF: StringName = &"roof"
const ROLE_SUPPORT: StringName = &"support"
const ROLE_PROP: StringName = &"prop"

var kind: StringName = KIND_BRICK
var studs_x: int = 2
var studs_z: int = 4
var plates_high: int = BrickDimensions.BRICK_PLATES
var color: Color = BrickPalette.RED
var position: Vector3 = Vector3.ZERO
var rotation_degrees: Vector3 = Vector3.ZERO
var show_studs: bool = true
var underside_detail: bool = false
var transparent: bool = false
var roughness: float = BrickPalette.PLASTIC_ROUGHNESS
var metallic: float = 0.0
var bevel: float = BrickDimensions.DEFAULT_BEVEL
var mass: float = 0.45
var front_height_ratio: float = 0.22
var semantic_role: StringName = ROLE_STRUCTURE
var break_cluster: StringName = &"body"
var build_order: int = 0
var tags: Array[StringName] = []

static func make(
	kind_value: StringName,
	studs_x_value: int,
	studs_z_value: int,
	plates_high_value: int,
	color_value: Color,
	target_position: Vector3,
	build_order_value: int = 0,
	semantic_role_value: StringName = ROLE_STRUCTURE,
	rotation_degrees_value: Vector3 = Vector3.ZERO
) -> BrickElementSpec:
	var result: BrickElementSpec = BrickElementSpec.new()
	result.kind = kind_value
	result.studs_x = maxi(1, studs_x_value)
	result.studs_z = maxi(1, studs_z_value)
	result.plates_high = maxi(1, plates_high_value)
	result.color = color_value
	result.position = target_position
	result.build_order = maxi(0, build_order_value)
	result.semantic_role = semantic_role_value
	result.rotation_degrees = rotation_degrees_value
	if kind_value == KIND_TILE or kind_value == KIND_BAR:
		result.show_studs = false
	if semantic_role_value == ROLE_GLASS:
		result.transparent = true
		result.roughness = BrickPalette.TRANSPARENT_ROUGHNESS
	return result

func duplicate_spec() -> BrickElementSpec:
	var result: BrickElementSpec = BrickElementSpec.new()
	result.kind = kind
	result.studs_x = studs_x
	result.studs_z = studs_z
	result.plates_high = plates_high
	result.color = color
	result.position = position
	result.rotation_degrees = rotation_degrees
	result.show_studs = show_studs
	result.underside_detail = underside_detail
	result.transparent = transparent
	result.roughness = roughness
	result.metallic = metallic
	result.bevel = bevel
	result.mass = mass
	result.front_height_ratio = front_height_ratio
	result.semantic_role = semantic_role
	result.break_cluster = break_cluster
	result.build_order = build_order
	result.tags = tags.duplicate()
	return result

func body_size() -> Vector3:
	return BrickDimensions.body_size(studs_x, studs_z, plates_high)

func nominal_size() -> Vector3:
	return BrickDimensions.nominal_size(studs_x, studs_z, plates_high)
