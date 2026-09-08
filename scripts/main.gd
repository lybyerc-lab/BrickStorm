# BRICKSTORM - vertical slice.
#
# Proves the six things a design document cannot (Docs/GAME_CONCEPT.md §10):
# real-time destruction, distance-scaled stud value, wind pressure and BRACE,
# two characters with real ability gates, a build spot and a Dorothy
# deployment, and one-stick landscape touch control.
extends Node3D

const STUD_GOAL := 400
const TRUE_CHASER := 1400
const MAX_LOOSE := 110
const TEAR_BUDGET := 5
const BRICK_LIFETIME := 6.0
const BUILD_TIME := 2.4

enum Phase { LOOT, BUILD, CARRY, DEPLOY, WON }

var tornado: Tornado
var player: Player
var studfield: StudField
var hud: HUD
var camera: Camera3D
var debris_root: Node3D
var critter_root: Node3D

var structures: Array[Structure] = []
var debris: Array = []

var score: int = 0
var phase: int = Phase.LOOT
var build_spot: Node3D
var anchor_node: Node3D
var build_progress: float = 0.0
var dorothy: Node3D
var dorothy_deployed: bool = false

var context_action: String = "BRACE"
var ctx_held: bool = false
var _last_ctx_press: float = -10.0
var demo_mode: bool = false
var capture_mode: bool = false
var _capture_at: Array = [5.0, 11.0, 17.0, 23.0, 29.0]
var _capture_i: int = 0
var _capture_dir: String = "/home/user/brickstorm_shots"
var _demo_target := Vector3.ZERO
var _elapsed: float = 0.0


func _ready() -> void:
	randomize()
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	capture_mode = args.has("--capture")
	demo_mode = args.has("--demo") or args.has("--selftest") or capture_mode

	_setup_environment()
	_build_ground()
	_build_town()
	_spawn_actors()
	_spawn_objective_props()
	_wire_hud()

	if args.has("--selftest"):
		_run_selftest()


# ---------------------------------------------------------------- environment
# ============================================================================
# [BS:WORLD:ENVIRONMENT]
# Purpose: Sky, sun and fog.
# Invariants:
# - The SKY carries the dread; the world below stays bright and
#   saturated (North Star pillar 2). Do NOT darken the ground palette
#   to signal danger - that contrast is the visual identity.
# ============================================================================
func _setup_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY

	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	# The sky carries the dread; the world below stays bright (§9).
	sm.sky_top_color = Color(0.11, 0.15, 0.14)
	sm.sky_horizon_color = Color(0.60, 0.58, 0.32)
	sm.ground_bottom_color = Color(0.18, 0.20, 0.16)
	sm.ground_horizon_color = Color(0.50, 0.49, 0.33)
	sm.sun_angle_max = 40.0
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.15
	env.fog_enabled = true
	env.fog_light_color = Color(0.55, 0.55, 0.40)
	env.fog_density = 0.0022
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-46, 38, 0)
	sun.light_energy = 1.15
	sun.light_color = Color(1.0, 0.95, 0.82)
	sun.shadow_enabled = true
	add_child(sun)
# [BS:WORLD:ENVIRONMENT:END]


# ============================================================================
# [BS:WORLD:GROUND]
# Purpose: Ground plane and crop squares.
# Invariants:
# - Crop squares exist so the funnel's track across the fields reads
#   from the air, and so no large dead empty zone fills the frame.
# ============================================================================
func _build_ground() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var wb := WorldBoundaryShape3D.new()
	cs.shape = wb
	body.add_child(cs)
	add_child(body)

	var pm := PlaneMesh.new()
	pm.size = Vector2(420, 420)
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.material_override = BrickLib.mat(Color(0.36, 0.50, 0.24))
	add_child(mi)

	# crop squares, so the funnel's track across the fields reads from the air
	for i in range(16):
		var q := PlaneMesh.new()
		var w := randf_range(18.0, 34.0)
		q.size = Vector2(w, randf_range(18.0, 34.0))
		var m := MeshInstance3D.new()
		m.mesh = q
		var tone := randf_range(-0.05, 0.08)
		var base := Color(0.44 + tone, 0.46 + tone, 0.20 + tone * 0.5)
		if i % 3 == 0:
			base = Color(0.62 + tone, 0.55 + tone, 0.28)
		m.material_override = BrickLib.mat(base)
		m.position = Vector3(randf_range(-150, 150), 0.02 + float(i) * 0.002, randf_range(-150, 150))
		add_child(m)


# --------------------------------------------------------------------- world
# Small convenience: a positioned visual brick.
# [BS:WORLD:GROUND:END]
func _vbrick(sw: int, sd: int, h: float, colour: Color, pos: Vector3) -> Node3D:
	var b := BrickLib.brick_visual(sw, sd, h, colour)
	b.position = pos
	return b


func _add_structure(st: Structure) -> void:
	add_child(st)
	structures.append(st)


# ============================================================================
# [BS:WORLD:LAYOUT]
# Purpose: Where the town stands.
# Invariants:
# - Structures are placed so the funnel's path crosses several of
#   them - an empty run is a boring run.
# - At least one structure should remain intact in frame for scale
#   contrast (screenshot checklist).
# ============================================================================
func _build_town() -> void:
	_add_structure(PropBuilder.farmhouse(Vector3(-20, 0, -12)))
	_add_structure(PropBuilder.barn(Vector3(16, 0, -18)))
	_add_structure(PropBuilder.silo(Vector3(25, 0, -14)))
	_add_structure(PropBuilder.silo(Vector3(29, 0, -18)))
	_add_structure(PropBuilder.water_tower(Vector3(-6, 0, 22)))
	_add_structure(PropBuilder.windmill(Vector3(30, 0, 10)))
	_add_structure(PropBuilder.drive_in_screen(Vector3(-34, 0, 26), 0.6))
	_add_structure(PropBuilder.farmhouse(Vector3(6, 0, 34)))
	_add_structure(PropBuilder.barn(Vector3(-30, 0, -34)))

	_add_structure(PropBuilder.pickup(Vector3(-13, 0, -4), BrickLib.C_RED, 0.4))
	_add_structure(PropBuilder.pickup(Vector3(-9, 0, 1), BrickLib.C_WHITE, 1.9))
	_add_structure(PropBuilder.pickup(Vector3(20, 0, -8), BrickLib.C_BLUE, -0.7))
	_add_structure(PropBuilder.pickup(Vector3(-2, 0, 30), BrickLib.C_YELLOW, 2.6))

	for p in [Vector3(-28, 0, 4), Vector3(-16, 0, 12), Vector3(8, 0, -30), Vector3(34, 0, -4),
			Vector3(-40, 0, -18), Vector3(18, 0, 22), Vector3(-2, 0, -28), Vector3(40, 0, 24)]:
		_add_structure(PropBuilder.tree(p, randf_range(0.85, 1.3)))

	_add_structure(PropBuilder.fence_run(Vector3(-12, 0, 6), Vector3(12, 0, 6)))
	_add_structure(PropBuilder.fence_run(Vector3(12, 0, 6), Vector3(12, 0, 26)))
	_add_structure(PropBuilder.fence_run(Vector3(-34, 0, -6), Vector3(-34, 0, 14)))

	_build_cows()


# Design Law #1: cows fly, cows land, cows are never destroyed.
# [BS:WORLD:LAYOUT:END]
# ============================================================================
# [BS:WORLD:CRITTERS]
# Purpose: Cows - protected actors, and the proof of North Star Law 1.
# Invariants:
# - Cows are on collision layer 8. Debris (layer 4) cannot touch them.
# - They are dragged by the funnel exactly like debris, and are NEVER
#   converted to studs, damaged, or removed. They fly, they land, they
#   are fine. See BS:LAW:NO_HARM.
# ============================================================================
func _build_cows() -> void:
	critter_root = Node3D.new()
	critter_root.name = "Critters"
	add_child(critter_root)

	for p in [Vector3(-4, 0, 12), Vector3(2, 0, 15), Vector3(-8, 0, 17), Vector3(5, 0, 10)]:
		var cow := RigidBody3D.new()
		cow.mass = 3.0
		cow.collision_layer = 8
		cow.collision_mask = 1
		cow.set_meta("protected", true)
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(1.4, 1.0, 0.8)
		cs.shape = bs
		cs.position = Vector3(0, 0.7, 0)
		cow.add_child(cs)

		var v := Node3D.new()
		var bodyb := BrickLib.brick_visual(3, 2, 0.6, BrickLib.C_WHITE)
		bodyb.position = Vector3(0, 0.75, 0)
		v.add_child(bodyb)
		var headb := BrickLib.brick_visual(1, 1, 0.5, BrickLib.C_WHITE, false)
		headb.position = Vector3(0.85, 0.85, 0)
		v.add_child(headb)
		for sx in [-0.45, 0.45]:
			for sz in [-0.28, 0.28]:
				var leg := BrickLib.brick_visual(1, 1, 0.5, BrickLib.C_BLACK, false)
				leg.position = Vector3(sx, 0.25, sz)
				v.add_child(leg)
		var patch := BrickLib.brick_visual(1, 1, 0.12, BrickLib.C_BLACK, false)
		patch.position = Vector3(-0.2, 1.06, 0.2)
		v.add_child(patch)
		cow.add_child(v)

		critter_root.add_child(cow)
		cow.global_position = p


# -------------------------------------------------------------------- actors
# [BS:WORLD:CRITTERS:END]
func _spawn_actors() -> void:
	debris_root = Node3D.new()
	debris_root.name = "Debris"
	add_child(debris_root)

	studfield = StudField.new()
	studfield.name = "Studs"
	add_child(studfield)
	studfield.collected.connect(_on_stud_collected)

	tornado = Tornado.new()
	tornado.name = "Tornado"
	tornado.add_to_group("tornado")
	tornado.debris_root = debris_root
	tornado.critter_root = critter_root
	add_child(tornado)
	tornado.set_path(PackedVector3Array([
		Vector3(30, 0, -32), Vector3(14, 0, -18), Vector3(-18, 0, -10),
		Vector3(-30, 0, 14), Vector3(-4, 0, 24), Vector3(24, 0, 12),
		Vector3(34, 0, -12),
	]))

	player = Player.new()
	player.name = "Player"
	player.add_to_group("player")
	add_child(player)
	player.global_position = Vector3(-4, 0.2, 0)
	player.tumbled.connect(_on_player_tumbled)

	camera = Camera3D.new()
	camera.fov = 58.0
	camera.far = 500.0
	add_child(camera)
	camera.global_position = Vector3(-4, 22, 28)


# ============================================================================
# [BS:OBJECTIVE:DOROTHY]
# Purpose: The build spot and the DOROTHY pod - the objective props.
# Invariants:
# - Deploying Dorothy is the recurring objective verb of the whole
#   campaign, not a one-off for this level.
# - The build spot must sit where the funnel's path will reach it, or
#   the deployment can never complete.
# ============================================================================
func _spawn_objective_props() -> void:
	# the build spot: a heap of loose bricks waiting to become an anchor
	build_spot = Node3D.new()
	add_child(build_spot)
	build_spot.position = Vector3(2, 0, -6)
	for i in range(14):
		var a := TAU * float(i) / 14.0
		var b := _vbrick(2, 1, 0.2, BrickLib.C_DGREY,
			Vector3(cos(a) * randf_range(0.4, 1.5), 0.1, sin(a) * randf_range(0.4, 1.5)))
		b.rotation.y = randf_range(0, TAU)
		build_spot.add_child(b)
	var marker := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.9
	tm.outer_radius = 2.2
	marker.mesh = tm
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mm.albedo_color = Color(0.4, 0.9, 1.0, 0.35)
	marker.material_override = mm
	marker.position.y = 0.05
	marker.name = "Marker"
	build_spot.add_child(marker)

	# DOROTHY: the pod full of sensor balls
	dorothy = Node3D.new()
	add_child(dorothy)
	dorothy.position = Vector3(-11, 0, -2)
	var drum := BrickLib.brick_visual(4, 4, 1.0, BrickLib.C_YELLOW)
	drum.position = Vector3(0, 0.5, 0)
	dorothy.add_child(drum)
	var lid := BrickLib.brick_visual(5, 5, 0.2, BrickLib.C_DGREY, false)
	lid.position = Vector3(0, 1.1, 0)
	dorothy.add_child(lid)
	for i in range(5):
		var ball := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.16
		sm.height = 0.32
		sm.radial_segments = 8
		sm.rings = 5
		ball.mesh = sm
		ball.material_override = BrickLib.mat(BrickLib.C_TRANS)
		ball.position = Vector3(randf_range(-0.4, 0.4), 1.3, randf_range(-0.4, 0.4))
		dorothy.add_child(ball)


# [BS:OBJECTIVE:DOROTHY:END]

func _wire_hud() -> void:
	hud = HUD.new()
	add_child(hud)
	hud.context_pressed.connect(_on_context_pressed)
	hud.context_released.connect(_on_context_released)
	hud.swap_to.connect(func(c: int) -> void: player.set_character(c); hud.set_active_character(c))
	hud.set_active_character(player.character)
	hud.set_objective("LOOT THE DEBRIS - %d STUDS" % STUD_GOAL)


# ---------------------------------------------------------------------- loop
func _process(delta: float) -> void:
	_elapsed += delta
	_read_input()
	_update_camera(delta)
	_update_context()
	_update_phase(delta)
	_age_debris(delta)
	if capture_mode:
		_tick_capture()

	var band := tornado.band_of(player.global_position)
	hud.set_band(band, Tornado.band_multiplier(band))
	hud.set_studs(score)


func _physics_process(_delta: float) -> void:
	_tear_with_funnel()
	_check_lift()


func _read_input() -> void:
	var v := hud.stick.value
	# desktop fallback so the slice is playable without a touchscreen
	var kb := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		kb.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		kb.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		kb.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		kb.y += 1.0
	if kb.length() > 0.01:
		v = kb.normalized()

	if demo_mode:
		v = _demo_input()

	player.move_input = v


# ============================================================================
# [BS:CAMERA:DIRECTOR]
# Purpose: Auto-framing. The camera is a director, not a player control.
# Invariants:
# - There is no camera control and never will be (pillar 6).
# - The lead toward the funnel is CAPPED. Uncapped, the camera frames
#   a midpoint and loses the player off-screen entirely. This has
#   already been a bug once.
# - The player is always in frame. That is the one hard requirement.
# ============================================================================
func _update_camera(delta: float) -> void:
	var p := player.global_position
	var t := tornado.funnel_pos()
	# Lead toward the funnel, but never far enough to push the player out of
	# frame - the camera is a director, not a control (§8).
	var toward := t - p
	toward.y = 0.0
	if toward.length() > 26.0:
		toward = toward.normalized() * 26.0
	var mid := p + toward * 0.44
	var d: float = clampf(p.distance_to(t), 14.0, 60.0)
	var desired := mid + Vector3(0.0, 10.0 + d * 0.19, 13.0 + d * 0.27)
	camera.global_position = camera.global_position.lerp(desired, clampf(delta * 2.4, 0.0, 1.0))
	camera.look_at(mid + Vector3(0, 2.5, 0), Vector3.UP)


# ------------------------------------------------------------------ contexts
# [BS:CAMERA:DIRECTOR:END]
func _nearest_structure(within: float) -> Structure:
	var best: Structure = null
	var bd := within
	for s in structures:
		if s.is_rubble():
			continue
		var d := s.global_position.distance_to(player.global_position)
		if d < bd:
			bd = d
			best = s
	return best


# ============================================================================
# [BS:OBJECTIVE:CONTEXT_ACTION]
# Purpose: What the single context button means at this moment.
# Invariants:
# - Exactly one action is offered at a time, and the button label
#   always states it. Ambiguity here is a control bug.
# - Resolution order is priority order: the most specific applicable
#   action wins, and BRACE is the fallback.
# ============================================================================
func _update_context() -> void:
	var p := player.global_position
	var act := "BRACE"

	if phase == Phase.DEPLOY and player.carrying != null and anchor_node != null \
			and p.distance_to(anchor_node.global_position) < 3.5:
		act = "DEPLOY"
	elif phase >= Phase.CARRY and player.carrying == null and dorothy != null \
			and not dorothy_deployed and p.distance_to(dorothy.global_position) < 3.0:
		act = "GRAB"
	elif phase == Phase.BUILD and p.distance_to(build_spot.global_position) < 3.0:
		act = "BUILD"
	elif player.can_smash() and _nearest_structure(4.0) != null:
		act = "SMASH"

	context_action = act
	hud.set_context(act)
# [BS:OBJECTIVE:CONTEXT_ACTION:END]


func _on_context_pressed() -> void:
	var now := _elapsed
	if now - _last_ctx_press < 0.32:
		player.use_ability()
		if player.character == Player.Character.JO:
			hud.toast("READ THE SKY", Color(0.5, 0.85, 1.0))
	_last_ctx_press = now

	ctx_held = true
	match context_action:
		"SMASH":
			_do_smash()
		"GRAB":
			player.carry(dorothy)
			hud.toast("DOROTHY UP", BrickLib.C_YELLOW)
			phase = Phase.DEPLOY
			hud.set_objective("CARRY DOROTHY TO THE ANCHOR")
		"DEPLOY":
			_do_deploy()
		"BRACE":
			player.braced = true


func _on_context_released() -> void:
	ctx_held = false
	player.braced = false
	if phase == Phase.BUILD:
		build_progress = 0.0


func _do_smash() -> void:
	var s := _nearest_structure(4.0)
	if s == null:
		return
	var bodies := s.tear(player.global_position, 3.2, debris_root, 6)
	for b in bodies:
		var away: Vector3 = (b.global_position - player.global_position).normalized()
		b.apply_central_impulse((away + Vector3.UP * 0.8) * 5.5 * b.mass)
		debris.append({"body": b, "age": 0.0})


func _do_deploy() -> void:
	var pod := player.drop()
	if pod == null:
		return
	pod.global_position = anchor_node.global_position + Vector3(0, 1.4, 0)
	dorothy_deployed = true
	hud.toast("DOROTHY DEPLOYED - HOLD THE ANCHOR", Color(0.5, 0.9, 1.0))
	hud.set_objective("HOLD THE ANCHOR UNTIL THE FUNNEL PASSES")


# -------------------------------------------------------------------- phases
# ============================================================================
# [BS:OBJECTIVE:PHASES]
# Purpose: LOOT -> BUILD -> CARRY -> DEPLOY -> WON.
# Invariants:
# - Phases only advance. There is no failure transition - see
#   BS:LAW:NO_FAIL.
# - Each phase change restates the objective on the HUD; the player
#   must never have to guess what to do next.
# ============================================================================
func _update_phase(delta: float) -> void:
	match phase:
		Phase.LOOT:
			if score >= STUD_GOAL:
				phase = Phase.BUILD
				hud.toast("ANCHOR SITE UNLOCKED", Color(0.4, 0.95, 1.0))
				hud.set_objective("BUILD THE ANCHOR")
		Phase.BUILD:
			if ctx_held and context_action == "BUILD":
				build_progress += delta * (3.0 if player.character == Player.Character.BILL else 1.0)
				if build_progress >= BUILD_TIME:
					_assemble_anchor()
		Phase.DEPLOY:
			if dorothy_deployed and anchor_node != null:
				if tornado.funnel_pos().distance_to(anchor_node.global_position) < 18.0:
					_win()
		_:
			pass
# [BS:OBJECTIVE:PHASES:END]


func _assemble_anchor() -> void:
	phase = Phase.CARRY
	for c in build_spot.get_children():
		c.queue_free()
	anchor_node = Node3D.new()
	add_child(anchor_node)
	anchor_node.global_position = build_spot.global_position
	for i in range(5):
		var b := _vbrick(2, 2, 0.6, BrickLib.C_DGREY, Vector3(0, 0.3 + float(i) * 0.6, 0))
		anchor_node.add_child(b)
	for i in range(4):
		var a := TAU * float(i) / 4.0
		var brace := _vbrick(1, 4, 0.3, BrickLib.C_LGREY,
			Vector3(cos(a) * 0.9, 0.4, sin(a) * 0.9))
		brace.rotation = Vector3(0.5, -a, 0)
		anchor_node.add_child(brace)
	hud.toast("ANCHOR BUILT", Color(0.5, 1.0, 0.6))
	hud.set_objective("GRAB DOROTHY FROM THE TRUCK")


func _win() -> void:
	phase = Phase.WON
	var rating := "TRUE CHASER" if score >= TRUE_CHASER else "LOGGED"
	hud.toast("F3 LOGGED - DOROTHY DEPLOYED   %s" % rating, BrickLib.C_YELLOW)
	hud.set_objective("F3 LOGGED - %s   (%d STUDS)" % [rating, score])


# ---------------------------------------------------------------- destruction
func _tear_with_funnel() -> void:
	var c := tornado.funnel_pos()
	var budget := TEAR_BUDGET
	for s in structures:
		if budget <= 0:
			break
		if s.torn_count >= s.entries.size():
			continue
		if s.global_position.distance_to(c) > tornado.damage_radius + 26.0:
			continue
		var bodies := s.tear(c, tornado.damage_radius, debris_root, budget)
		budget -= bodies.size()
		for b in bodies:
			var out: Vector3 = b.global_position - c
			out.y = 0.0
			var tangent := Vector3(-out.z, 0.0, out.x).normalized()
			b.apply_central_impulse((tangent * 6.0 + Vector3.UP * 5.0) * b.mass)
			debris.append({"body": b, "age": 0.0})


# A loose brick lives briefly, then bursts into the studs it is worth.
# ============================================================================
# [BS:DESTRUCTION:DEBRIS_LIFECYCLE]
# Purpose: A loose brick lives briefly, then bursts into the studs it is worth.
# Invariants:
# - This is the link between destruction and the economy: torn
#   scenery MUST become collectable value, or the loop breaks.
# - Loose bodies are capped. Oldest-first retirement keeps the
#   simulation affordable on a phone.
# ============================================================================
func _age_debris(delta: float) -> void:
	var i := debris.size() - 1
	while i >= 0:
		var d: Dictionary = debris[i]
		var b: RigidBody3D = d["body"]
		if not is_instance_valid(b):
			debris.remove_at(i)
			i -= 1
			continue
		d["age"] += delta
		var over := debris.size() > MAX_LOOSE and i < debris.size() - MAX_LOOSE
		if d["age"] > BRICK_LIFETIME or b.global_position.y < -8.0 or over:
			var at := b.global_position
			at.y = maxf(at.y, 0.3)
			studfield.spawn_burst(at, randi_range(1, 3))
			b.queue_free()
			debris.remove_at(i)
		i -= 1
# [BS:DESTRUCTION:DEBRIS_LIFECYCLE:END]


func _check_lift() -> void:
	if player.tumble_timer > 0.0 or player.immune_to_lift():
		return
	var d := tornado.funnel_pos().distance_to(player.global_position)
	if d < tornado.lift_radius:
		player.tumble()


# ------------------------------------------------------------------- scoring
func _on_stud_collected(value: int, _band: int, _at: Vector3) -> void:
	score += value


# The toll for getting caught: studs, not a game over (Design Law #2).
func _on_player_tumbled(at: Vector3) -> void:
	var lost: int = int(float(score) * 0.20)
	score -= lost
	hud.toast("TUMBLED" if lost == 0 else "TUMBLED  -%d" % lost, Color(1.0, 0.5, 0.4))
	var away := (player.global_position - tornado.funnel_pos()).normalized()
	player.launch(away, 12.0)
	if lost > 0:
		studfield.spawn_burst(at + Vector3(0, 1, 0), mini(12, int(lost / 10.0) + 1))


# ---------------------------------------------------------------------- demo
# Autopilot used for verification captures: walk the risk bands, loot, brace.
# ============================================================================
# [BS:QA:AUTOPILOT]
# Purpose: The demo driver used for capture runs.
# Invariants:
# - Not gameplay. It exists to make captures reproducible and must
#   never be reachable in a shipping build.
# - It only chases loot still near the funnel - stale studs behind the
#   storm are a trap that pulls the capture out of the bands.
# ============================================================================
func _demo_input() -> Vector2:
	var p := player.global_position
	var band := tornado.band_of(p)
	player.braced = band >= 2 and fmod(_elapsed, 6.0) < 1.2

	var c := tornado.funnel_pos()
	var nearest := Vector3.ZERO
	var best := 1e9
	for s in studfield.studs:
		var n: Node3D = s["node"]
		if not is_instance_valid(n):
			continue
		# only chase loot still close enough to the funnel to be worth a
		# multiplier - stale studs behind the storm are a trap
		if n.global_position.distance_to(c) > 24.0:
			continue
		var d := n.global_position.distance_to(p)
		if d < best:
			best = d
			nearest = n.global_position
	if best < 24.0:
		_demo_target = nearest
	else:
		# hang just outside the red band, where the multiplier is worth having
		var ang := _elapsed * 0.4
		_demo_target = c + Vector3(cos(ang), 0, sin(ang)) * 15.0

	var to := _demo_target - p
	return Vector2(to.x, to.z).normalized()


# Drives the funnel straight onto the barn and steps real physics frames, so the
# check covers the actual hook: tear -> debris -> studs -> score.
# [BS:QA:AUTOPILOT:END]
# ============================================================================
# [BS:QA:CAPTURE]
# Purpose: Screenshot capture at fixed simulated times.
# Invariants:
# - Captures happen after frame_post_draw, so a shot is what was
#   actually drawn.
# - Screenshots are load-bearing evidence (Docs/NO_DRIFT_POLICY.md).
#   Nothing in Docs/shots is concept art.
# ============================================================================
func _tick_capture() -> void:
	if _capture_i >= _capture_at.size():
		return
	if _elapsed < _capture_at[_capture_i]:
		return
	var idx := _capture_i
	_capture_i += 1
	_grab("shot_%d" % (idx + 1))


func _grab(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(_capture_dir)
	img.save_png("%s/%s.png" % [_capture_dir, name])
	var pp := player.global_position
	print("CAPTURED %s t=%.1f score=%d phase=%d torn=%d debris=%d studs=%d band=%d gap=%.0f" % [
		name, _elapsed, score, phase, _total_torn(), debris.size(),
		studfield.studs.size(), tornado.band_of(pp),
		pp.distance_to(tornado.funnel_pos())])
	if _capture_i >= _capture_at.size():
		get_tree().quit()


# [BS:QA:CAPTURE:END]

# ============================================================================
# [BS:QA:SELFTEST]
# Purpose: The load-bearing behavioural gate. CI runs this before it exports anything.
# Invariants:
# - It must be able to FAIL. It drives the funnel onto the barn, steps
#   real physics frames, and asserts bricks were actually torn AND that
#   destruction actually produced studs and score.
# - It exits non-zero on failure. Never weaken an assertion to make a
#   build pass - a check that cannot fail is worse than no check.
# - It steps physics frames, not process frames: headless process
#   frames run uncapped and simulate almost no time.
# ============================================================================
func _run_selftest() -> void:
	await get_tree().process_frame
	tornado.global_position = Vector3(16, 0, -18)
	player.global_position = Vector3(25, 0.2, -18)
	for i in range(700):
		await get_tree().physics_frame

	var torn := _total_torn()
	print("SELFTEST structures=%d torn=%d debris=%d studs=%d score=%d phase=%d" % [
		structures.size(), torn, debris.size(), studfield.studs.size(), score, phase])
	var ok := true
	if torn < 10:
		print("SELFTEST FAIL: funnel tore only %d bricks" % torn)
		ok = false
	if studfield.studs.size() == 0 and score == 0:
		print("SELFTEST FAIL: destruction produced no studs")
		ok = false
	print("SELFTEST OK" if ok else "SELFTEST FAILED")
	get_tree().quit(0 if ok else 1)
# [BS:QA:SELFTEST:END]


func _total_torn() -> int:
	var n := 0
	for s in structures:
		n += s.torn_count
	return n
