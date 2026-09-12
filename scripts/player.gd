# The chaser.
#
# Two characters share one body; swapping is instant and is the core LEGO verb.
# There is no death here - only TUMBLE, which costs studs and dignity
# (Docs/GAME_CONCEPT.md §3, Design Law #2).
class_name Player
extends CharacterBody3D

signal tumbled(at: Vector3)

enum Character { JO, BILL }

const GRAVITY := 22.0
const TUMBLE_TIME := 2.2
const JUMP_SPEED := 9.4
const AUTO_BRACE_WIND := 9.0

var character: int = Character.JO
var braced: bool = false
var move_input := Vector2.ZERO
var carrying: Node3D = null
var tumble_timer: float = 0.0
var ability_timer: float = 0.0
var driving: Node = null
var invuln_timer: float = 0.0
var _walk_phase: float = 0.0
var _parts: Dictionary = {}

var _rigs: Dictionary = {}
var _visual_root: Node3D = null
var _facing: float = 0.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.4

	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.42
	cap.height = 1.7
	cs.shape = cap
	cs.position = Vector3(0, 0.85, 0)
	add_child(cs)

	_visual_root = Node3D.new()
	add_child(_visual_root)

	# Jo - blue shirt, brown hair.  Bill - grey tee, dark hair.
	_rigs[Character.JO] = BrickLib.minifig(BrickLib.C_BLUE, BrickLib.C_DGREY, BrickLib.C_BROWN)
	_rigs[Character.BILL] = BrickLib.minifig(BrickLib.C_LGREY, BrickLib.C_BROWN, BrickLib.C_BLACK)
	for k in _rigs:
		var r: Node3D = _rigs[k]
		_visual_root.add_child(r)
		# Recursive: the hips and shoulders hang off Pelvis and Upper now, not
		# off the rig root. See BS:BUILD:MINIFIG.
		_parts[k] = {
			"hl": r.find_child("HipL", true, false),
			"hr": r.find_child("HipR", true, false),
			"sl": r.find_child("ShoulderL", true, false),
			"sr": r.find_child("ShoulderR", true, false),
			"pelvis": r.find_child("Pelvis", true, false),
			"upper": r.find_child("Upper", true, false),
		}
	_apply_character()


# ============================================================================
# [BS:PLAYER:CHARACTERS]
# Purpose: Per-character ability gates - the core LEGO verb.
# Invariants:
# - Each character has exactly one thing nobody else has. Bill walks
#   the RED band; Jo reads the sky and has the wide magnet.
# - Levels are built as locks for these keys. Do not give a character
#   a second headline ability to 'round them out' - that dissolves the
#   gate and the swap stops mattering.
# - Swapping is instant and never gated behind a menu.
# ============================================================================
func speed() -> float:
	return 5.8 if character == Character.BILL else 7.2


# Bill is the Extreme: he barely notices weather that flattens everyone else.
func magnet_range() -> float:
	var base := 3.6 if character == Character.BILL else 4.2
	if character == Character.JO and ability_timer > 0.0:
		base *= 2.0
	return base


# Everyone smashes. Smashing everything is the point (North Star pillar 7) and
# must never be gated behind a character. Bill's gate is REACH, not permission.
func smash_radius() -> float:
	return 4.6 if character == Character.BILL else 3.4


# [BS:PLAYER:CHARACTERS:END]

# ============================================================================
# [BS:PLAYER:BRACE]
# Purpose: Wind resistance and lift immunity - why standing close is a decision.
# Invariants:
# - Bracing trades ALL movement for the ability to hold ground. That trade
#   is the mechanic; a brace that still allows movement is not a brace.
# - It is AUTOMATIC, not a button: release the stick in high wind and the
#   player digs in. Director decision 2026-09-08 spent the button budget on
#   SMASH / BUILD / JUMP. See Docs/DECISION_LOG.md.
# - Bill's resistance is a character ability gate (BS:PLAYER:CHARACTERS),
#   not a general buff.
# - Immunity to lift is the ONLY thing standing between the player and
#   BS:LAW:NO_FAIL. It must never be granted permanently.
# - A brief post-tumble immunity is part of it. TT Games respawn the player
#   temporarily invincible; without that, a player caught in the red band is
#   tumbled over and over with no way out, which is exactly the punishment the
#   no-fail design exists to prevent. See Docs/TT_GAMES_REFERENCE.md.
# ============================================================================
func wind_resist() -> float:
	if braced:
		return 0.10
	return 0.30 if character == Character.BILL else 1.0
func immune_to_lift() -> bool:
	return braced or invuln_timer > 0.0 or character == Character.BILL
# [BS:PLAYER:BRACE:END]

func set_character(c: int) -> void:
	if c == character or tumble_timer > 0.0:
		return
	character = c
	_apply_character()


func _apply_character() -> void:
	for k in _rigs:
		_rigs[k].visible = (k == character)


func use_ability() -> void:
	if character == Character.JO:
		ability_timer = 6.0        # READ THE SKY


# ============================================================================
# [BS:LAW:NO_FAIL]
# Purpose: Enforcement point for North Star Law 2 - there is no fail state, only a toll.
# Invariants:
# - The player is carried up, spun, and set down. Never killed, never
#   respawned, never sent to a retry screen.
# - The toll is studs, which SCATTER and can be re-collected. Nothing
#   is permanently lost.
# - Do not add lives, health, or a damage model to the player.
# ============================================================================
const INVULN_TIME := 3.0

func tumble() -> void:
	if tumble_timer > 0.0 or invuln_timer > 0.0:
		return
	tumble_timer = TUMBLE_TIME
	braced = false
	tumbled.emit(global_position)
# [BS:LAW:NO_FAIL:END]


# ============================================================================
# [BS:PLAYER:JUMP]
# Purpose: The jump. Always available, never contextual.
# Invariants:
# - Refused only while tumbling or driving. A player who presses JUMP and
#   nothing happens is a player who thinks the game is broken.
# - Deliberately generous: this is a toy, not a precision platformer.
# ============================================================================
func jump() -> void:
	if tumble_timer > 0.0 or driving != null:
		return
	if is_on_floor():
		velocity.y = JUMP_SPEED
# [BS:PLAYER:JUMP:END]


func carry(node: Node3D) -> void:
	carrying = node


func drop() -> Node3D:
	var n := carrying
	carrying = null
	return n


# ============================================================================
# [BS:PLAYER:MOVEMENT]
# Purpose: Movement under wind pressure.
# Invariants:
# - Wind is added to intended movement rather than replacing it, so
#   the player always retains some authority.
# - A braced player does not move - that is the cost of bracing.
# ============================================================================
func _physics_process(delta: float) -> void:
	if ability_timer > 0.0:
		ability_timer -= delta
	if invuln_timer > 0.0:
		invuln_timer -= delta
		# flicker so the grace period is visible, then always restore
		_visual_root.visible = invuln_timer <= 0.0 or fmod(invuln_timer, 0.26) > 0.13
		if invuln_timer <= 0.0:
			_visual_root.visible = true

	var wind := Vector3.ZERO
	var t := get_tree().get_first_node_in_group("tornado") as Tornado
	if t != null:
		wind = t.wind_at(global_position)

	if driving != null:
		_visual_root.visible = false
		if is_instance_valid(driving):
			global_position = (driving as Node3D).global_position
		return
	_visual_root.visible = true

	if tumble_timer > 0.0:
		_tumbling(delta)
		return

	# BRACE is not a button: release the stick in high wind and you dig in.
	braced = move_input.length() < 0.15 and wind.length() > AUTO_BRACE_WIND and is_on_floor()

	var planar := Vector3.ZERO
	if not braced:
		planar = Vector3(move_input.x, 0.0, move_input.y) * speed()
	planar += wind * wind_resist() * 0.55

	velocity.x = planar.x
	velocity.z = planar.z
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif velocity.y <= 0.0:
		velocity.y = 0.0

	move_and_slide()

	var flat := Vector2(velocity.x, velocity.z)
	if flat.length() > 0.4:
		_facing = lerp_angle(_facing, atan2(velocity.x, velocity.z), 0.24)
	_visual_root.rotation = Vector3(0, _facing, 0)
	_animate_walk(delta, flat.length())

	# a braced minifig leans into it
	if braced and t != null:
		var into := (t.funnel_pos() - global_position).normalized()
		_visual_root.rotation.x = -0.30
		_visual_root.rotation.y = atan2(into.x, into.z)
	else:
		_visual_root.rotation.x = 0.0

	if carrying != null and is_instance_valid(carrying):
		carrying.global_position = global_position + Vector3(0, 1.25, 0) \
			+ Vector3(sin(_facing), 0, cos(_facing)) * 0.75


# Picked up, spun, and set back down. Nobody is ever destroyed.
# [BS:PLAYER:MOVEMENT:END]
# ============================================================================
# [BS:PLAYER:TUMBLE]
# Purpose: The carried-and-dropped state.
# Invariants:
# - Purely animation plus damping. It ends on a timer and always
#   returns control - it can never trap the player.
# ============================================================================
func _tumbling(delta: float) -> void:
	tumble_timer -= delta
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	velocity.x = lerpf(velocity.x, 0.0, delta * 1.2)
	velocity.z = lerpf(velocity.z, 0.0, delta * 1.2)
	move_and_slide()
	_visual_root.rotation.y += delta * 13.0
	_visual_root.rotation.x = sin(tumble_timer * 9.0) * 0.9
	_visual_root.position.y = maxf(0.0, sin((TUMBLE_TIME - tumble_timer) * 2.4) * 1.4)
	if tumble_timer <= 0.0:
		_visual_root.rotation.x = 0.0
		_visual_root.position.y = 0.0
		invuln_timer = INVULN_TIME
# [BS:PLAYER:TUMBLE:END]


# ============================================================================
# [BS:PLAYER:WALK_CYCLE]
# Purpose: The stiff-legged minifig waddle, and the swagger on top of it.
# Invariants:
# - Legs and arms swing in opposition from hip and shoulder pivots, with a
#   small vertical bob. This is THE signature silhouette of the genre - a
#   minifig that slides across the ground reads as a physics prop, not a
#   character, and no amount of shading fixes that.
# - Amplitude scales with actual speed, so a shove from the wind animates too.
# - The pose always returns to neutral when stopped; it must never leave the
#   rig frozen mid-stride.
# - A SMASH IS VISIBLE. The arms were driven from the walk phase and nothing
#   else, so hitting SMASH moved the world and not the character: bricks flew
#   off a wall while the minifig stood there, or kept strolling. Reported from
#   a phone as "when I smash stuff the arms don't show movement". swing()
#   overrides both shoulders together for SMASH_TIME, and it fires whether or
#   not anything was in range - a button that sometimes does nothing visible
#   reads as a dropped input.
# --- gait: where a character's walk originates ------------------------------
# The thing that makes two minifigs built from identical parts read as
# different people, and part of the same walk cycle above.
# - A MINIFIG CANNOT BEND A KNEE OR AN ELBOW. The parts are rigid, so unlike
#   almost any other character animation there is nowhere for the personality
#   to live except in WHERE THE MOTION STARTS. TT get enormous mileage out of
#   this: their men half-run led from the SHOULDERS, rolling the upper body and
#   throwing the arms, and their women lead from the HIPS, with the pelvis
#   swinging and the shoulders comparatively quiet.
# - So the rig is split at the waist (Pelvis and Upper) and these numbers drive
#   the two against each other. Before the split every part was a sibling and
#   there was nothing to lead from - both characters walked identically and the
#   swap was invisible below the neck.
# - Torso twist is COUNTER to the hips, as a real gait is. Rotating both the
#   same way reads as a mannequin being carried.
# - Keep it under about 0.2 radians. Past that it stops being a walk and starts
#   being a dance, and the minifig's rigidity makes big angles read as broken.
const GAIT := {
	Character.JO: {
		"leg": 0.66, "arm": 0.52, "sway": 0.135, "twist": 0.085,
		"roll": 0.025, "bob": 0.070, "lean": 0.05,
	},
	Character.BILL: {
		"leg": 0.60, "arm": 0.94, "sway": 0.030, "twist": 0.170,
		"roll": 0.090, "bob": 0.098, "lean": 0.10,
	},
}


# A two-handed overhead slam: both arms up, then driven down hard. A minifig
# has no elbow, so the whole character has to sell the hit - which is why the
# upper body pitches into it rather than the arms simply rotating.
const SMASH_TIME := 0.34
var smash_timer: float = 0.0


func swing() -> void:
	smash_timer = SMASH_TIME


# THE swing curve. Shared with tools/swing_probe.gd so the picture shows the
# shipped motion rather than a re-typed copy of it - a probe that restates the
# formula it is checking proves only that the author can type it twice.
# t runs 0 to 1 across SMASH_TIME. Cubic ease-out puts the speed at the front
# of the motion, where a hit wants it.
static func swing_angle(t: float) -> float:
	var e: float = 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), 3.0)
	return lerpf(-2.05, 0.55, e)


static func swing_pitch(t: float) -> float:
	return sin(clampf(t, 0.0, 1.0) * PI) * 0.26


func _animate_walk(delta: float, spd: float) -> void:
	# Tick the swing BEFORE the rig check. Behind that early return the timer
	# could never reach zero for a character whose parts had not been cached,
	# leaving the swing latched on forever.
	if smash_timer > 0.0:
		smash_timer = maxf(smash_timer - delta, 0.0)
	var p: Dictionary = _parts.get(character, {})
	if p.is_empty():
		return
	var g: Dictionary = GAIT.get(character, GAIT[Character.JO])
	var amp: float = clampf(spd / maxf(speed(), 0.01), 0.0, 1.0)
	if spd > 0.6:
		_walk_phase += delta * (7.0 + spd * 0.8)
	else:
		amp = 0.0
		_walk_phase = 0.0
	var sw: float = sin(_walk_phase) * amp

	if p["hl"] != null:
		p["hl"].rotation.x = sw * g["leg"]
	if p["hr"] != null:
		p["hr"].rotation.x = -sw * g["leg"]
	# The swing OWNS both shoulders while it lasts, so it is not fighting the
	# walk for the same bone. t runs 0 to 1 across SMASH_TIME; the arms start
	# raised and are driven down on a cubic ease-out, which puts the speed at
	# the front of the motion where a hit wants it.
	var swinging := smash_timer > 0.0
	var arm_l: float = -sw * g["arm"]
	var arm_r: float = sw * g["arm"]
	var pitch_in := 0.0
	if swinging:
		var t: float = 1.0 - smash_timer / SMASH_TIME
		var ang: float = swing_angle(t)
		arm_l = ang
		arm_r = ang
		pitch_in = swing_pitch(t)
	if p["sl"] != null:
		p["sl"].rotation.x = arm_l
	if p["sr"] != null:
		p["sr"].rotation.x = arm_r

	var pelvis: Node3D = p.get("pelvis")
	if pelvis != null:
		# The hips swing, and carry a little lateral shift with them - the
		# weight moving over the planted foot. This is the half of the walk Jo
		# is built around.
		pelvis.rotation.z = sw * g["sway"]
		pelvis.rotation.y = sw * g["twist"] * 0.5
		pelvis.position.x = sw * g["sway"] * 0.30
	var upper: Node3D = p.get("upper")
	if upper != null:
		# And the shoulders roll against them. This is Bill's half: the roll
		# plus the wide arm throw is the whole swagger.
		upper.rotation.z = sw * g["roll"]
		upper.rotation.y = -sw * g["twist"]
		# Lean into the run. Positive x pitches the upper body toward +Z, which
		# is the direction this rig faces - see BS:RENDER:FACE.
		upper.rotation.x = amp * g["lean"] + pitch_in

	_visual_root.position.y = absf(sin(_walk_phase)) * amp * g["bob"]
# [BS:PLAYER:WALK_CYCLE:END]


func launch(dir: Vector3, force: float) -> void:
	velocity = dir.normalized() * force + Vector3.UP * force * 0.55
