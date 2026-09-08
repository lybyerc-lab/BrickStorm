class_name BrickDimensions
extends RefCounted

# Brickstorm uses a game-scale brick grid inspired by classic interlocking-brick
# proportions. Units are intentionally clean and deterministic for snapping,
# animation, destruction, and mobile-friendly procedural construction.
const STUD_PITCH: float = 0.42
const PLATE_HEIGHT: float = 0.16
const BRICK_PLATES: int = 3
const STUD_RADIUS: float = 0.12
const STUD_HEIGHT: float = 0.075
const EDGE_GAP: float = 0.016
const VERTICAL_GAP: float = 0.006
const MIN_BODY_HEIGHT: float = 0.08
const DEFAULT_BEVEL: float = 0.022

static func body_size(studs_x: int, studs_z: int, plates_high: int = BRICK_PLATES) -> Vector3:
	var safe_x: int = maxi(1, studs_x)
	var safe_z: int = maxi(1, studs_z)
	var safe_plates: int = maxi(1, plates_high)
	return Vector3(
		float(safe_x) * STUD_PITCH - EDGE_GAP,
		maxf(MIN_BODY_HEIGHT, float(safe_plates) * PLATE_HEIGHT - VERTICAL_GAP),
		float(safe_z) * STUD_PITCH - EDGE_GAP
	)

static func nominal_size(studs_x: int, studs_z: int, plates_high: int = BRICK_PLATES) -> Vector3:
	return Vector3(
		float(maxi(1, studs_x)) * STUD_PITCH,
		float(maxi(1, plates_high)) * PLATE_HEIGHT,
		float(maxi(1, studs_z)) * STUD_PITCH
	)

static func center_y(plates_high: int = BRICK_PLATES) -> float:
	return body_size(1, 1, plates_high).y * 0.5

static func stud_axis_position(index: int, count: int) -> float:
	var safe_count: int = maxi(1, count)
	var centered_index: float = float(index) - float(safe_count - 1) * 0.5
	return centered_index * STUD_PITCH

static func snap_position(value: Vector3) -> Vector3:
	return Vector3(
		roundf(value.x / STUD_PITCH) * STUD_PITCH,
		roundf(value.y / PLATE_HEIGHT) * PLATE_HEIGHT,
		roundf(value.z / STUD_PITCH) * STUD_PITCH
	)

static func snap_horizontal(value: Vector3) -> Vector3:
	return Vector3(
		roundf(value.x / STUD_PITCH) * STUD_PITCH,
		value.y,
		roundf(value.z / STUD_PITCH) * STUD_PITCH
	)

static func stack_y(layer_index: int, plates_high: int = BRICK_PLATES) -> float:
	var body_height: float = float(maxi(1, plates_high)) * PLATE_HEIGHT
	return float(layer_index) * body_height + center_y(plates_high)
