# A drivable brick truck.
#
# Arcade handling, not a simulator: the stick is a DIRECTION, not a wheel.
# Point the thumb where you want to go and the truck turns to face it. That is
# the only driving model that works with one thumb on a phone.
class_name Vehicle
extends CharacterBody3D

signal rammed(body: Node, at: Vector3, force: float)

const GRAVITY := 22.0

@export var max_speed: float = 17.0
@export var accel: float = 16.0
@export var brake: float = 26.0
@export var turn_rate: float = 3.2

var driver: Node = null
var move_input := Vector2.ZERO
var heading: float = 0.0
var body_colour: Color = BrickLib.C_RED

var _visual: Node3D = null
var _wheels: Array[Node3D] = []
var _ram_cooldown: float = 0.0


func _ready() -> void:
	collision_layer = 16
	collision_mask = 1
	floor_snap_length = 0.5

	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(4.2, 1.6, 2.4)
	cs.shape = bs
	cs.position = Vector3(0, 0.9, 0)
	add_child(cs)
	_build_visual()


func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)

	var chassis := BrickLib.brick_visual(8, 4, 0.2, BrickLib.C_DGREY, false)
	chassis.position = Vector3(0, 0.42, 0)
	_visual.add_child(chassis)

	var bed := BrickLib.brick_visual(5, 4, 0.96, body_colour)
	bed.position = Vector3(-0.7, 0.95, 0)
	_visual.add_child(bed)

	var cab := BrickLib.brick_visual(4, 4, 0.84, BrickLib.C_TRANS, false)
	cab.position = Vector3(0.5, 1.35, 0)
	_visual.add_child(cab)

	var hood := BrickLib.brick_visual(4, 4, 0.54, body_colour)
	hood.position = Vector3(1.5, 0.85, 0)
	_visual.add_child(hood)

	# a bull bar, because this truck is going to be driven into a barn
	var bar := BrickLib.brick_visual(1, 5, 0.5, BrickLib.C_LGREY, false)
	bar.position = Vector3(2.15, 0.75, 0)
	_visual.add_child(bar)

	for sx in [-1.2, 1.2]:
		for sz in [-1.05, 1.05]:
			var w := BrickLib.brick_visual(1, 1, 0.6, BrickLib.C_BLACK, false)
			w.position = Vector3(sx, 0.35, sz)
			w.rotation.z = PI * 0.5
			_visual.add_child(w)
			_wheels.append(w)


func is_occupied() -> bool:
	return driver != null


# ============================================================================
# [BS:VEHICLE:OCCUPANCY]
# Purpose: Getting in and out of a truck.
# Invariants:
# - While driving, the driver is hidden and its position is SYNCED to the
#   vehicle. Everything that reads the player - risk band, wind, stud magnet,
#   camera - therefore keeps working unchanged, and driving into the red band
#   pays exactly like walking into it.
# - Exiting always places the driver on the ground beside the truck. It must
#   never be possible to be left inside geometry.
# ============================================================================
func board(who: Node) -> void:
	driver = who
	heading = rotation.y


func alight() -> Vector3:
	driver = null
	var side := Vector3(sin(heading + PI * 0.5), 0.0, cos(heading + PI * 0.5)) * 3.0
	return global_position + side + Vector3(0, 0.4, 0)
# [BS:VEHICLE:OCCUPANCY:END]


# ============================================================================
# [BS:VEHICLE:DRIVE]
# Purpose: Arcade handling - the stick is a heading, not a steering wheel.
# Invariants:
# - Point-and-go. One thumb. No separate accelerator, brake, or reverse control
#   (North Star pillar 6).
# - The truck turns toward the stick and drives forward; releasing the stick
#   coasts to a stop. A player who never learns a control scheme can still use
#   this one.
# - Wind acts on the truck as it does on the player, so the funnel is still
#   dangerous from the driver's seat.
# ============================================================================
func _physics_process(delta: float) -> void:
	if _ram_cooldown > 0.0:
		_ram_cooldown -= delta

	var want := move_input.length()
	if driver != null and want > 0.05:
		var target := atan2(move_input.x, move_input.y)
		heading = rotate_toward(heading, target, turn_rate * delta)

	var forward := Vector3(sin(heading), 0.0, cos(heading))
	var speed := Vector3(velocity.x, 0.0, velocity.z).length()
	if driver != null and want > 0.05:
		speed = minf(speed + accel * want * delta, max_speed * want)
	else:
		speed = maxf(speed - brake * delta, 0.0)

	var planar := forward * speed

	var tor := get_tree().get_first_node_in_group("tornado") as Tornado
	if tor != null:
		planar += tor.wind_at(global_position) * 0.30

	velocity.x = planar.x
	velocity.z = planar.z
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	move_and_slide()
	rotation.y = heading

	var roll := speed * delta * 3.0
	for w in _wheels:
		w.rotation.x += roll

	_check_ram(speed)
# [BS:VEHICLE:DRIVE:END]


# ============================================================================
# [BS:VEHICLE:RAM]
# Purpose: Driving through scenery destroys it.
# Invariants:
# - Ramming only ever damages SCENERY. Actors are on layers this body does not
#   report against, and the ram signal is refused for anything that is not a
#   Structure - a truck cannot be used to break North Star Law 1.
# - Ram force scales with speed, so a stationary nudge does nothing and a
#   full-speed run through a fence is spectacular.
# ============================================================================
func _check_ram(speed: float) -> void:
	if speed < 5.0 or _ram_cooldown > 0.0:
		return
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var other := col.get_collider()
		if other == null:
			continue
		var st := _structure_of(other)
		if st == null:
			continue
		_ram_cooldown = 0.12
		rammed.emit(st, col.get_position(), speed)
		return


static func _structure_of(node: Object) -> Structure:
	var n := node as Node
	while n != null:
		var st := n as Structure
		if st != null:
			return st
		n = n.get_parent()
	return null
# [BS:VEHICLE:RAM:END]
