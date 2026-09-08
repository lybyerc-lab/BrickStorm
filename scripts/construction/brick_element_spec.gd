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
	return result

func body_size() -> Vector3:
	return BrickDimensions.body_size(studs_x, studs_z, plates_high)

func nominal_size() -> Vector3:
	return BrickDimensions.nominal_size(studs_x, studs_z, plates_high)
