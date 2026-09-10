# BRICKSTORM - vertical slice.
#
# Proves the six things a design document cannot (Docs/GAME_CONCEPT.md §10):
# real-time destruction, distance-scaled stud value, wind pressure and BRACE,
# two characters with real ability gates, a build spot and a Dorothy
# deployment, and one-stick landscape touch control.
extends Node3D

const STUD_GOAL := 3500
const TRUE_CHASER := 9000
const MAX_LOOSE := 110
const TEAR_BUDGET := 5
const BRICK_LIFETIME := 6.0
# How long a brick the player knocked loose flies before it becomes studs.
# Long enough to see it come off, short enough that the payout belongs to
# the hit that caused it.
const PLAYER_BRICK_LIFETIME := 0.55
# Below this many parts, finishing a structure pays nothing extra. Measured:
# without a floor the funnel finished 92-97 structures a round - one every two
# seconds - because it eats every mailbox, bin and crate in the corridor. A
# jackpot arriving every two seconds is a stream, not a jackpot. Furniture runs
# 4-10 parts, a windmill 11, a pickup 10; a fence run is 23 and a silo 23.
const FINISH_MIN_PARTS := 20
# And this many or more pays BLUE rather than gold. Barn 154, farmhouse 117.
const BIG_STRUCTURE := 100
const BUILD_TIME := 2.4
const FUNNEL_CLEARANCE := 15.0

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
var vehicles: Array[Vehicle] = []
var comedy: Comedy
var audio: GameAudio
var _roar: AudioStreamPlayer3D = null
var driving: Vehicle = null
var outhouse: Structure = null
var _outhouse_popped: bool = false
var _cow_air: Dictionary = {}
var _force_input: bool = false
var _forced_input := Vector2.ZERO
var _cam_dir := Vector3(0, 0, 1)
var _near: Array[Structure] = []
var _near_t: float = 0.0
var _near_from := Vector3(1e9, 1e9, 1e9)
var _sp: Dictionary = {}
var _sp_balls: Array = []
var _sp_built: bool = false
var _sp_build_progress: float = 0.0
var sensors_found: int = 0
const SENSOR_BONUS := 25000
const SET_PIECE_Z := 120.0
var _stream_t: float = 0.0
const AREA_DEPTH := 34.0
# The hand-placed opening pocket, wide enough to own every prop _build_town
# places - including the furniture ring, which reaches 34m from its centre.
# Any value; it only has to never change, so shots from different commits are
# of the same world.
const CAPTURE_SEED := 20260909

const START_Z0 := -60.0
const START_DEPTH := 92.0

# The corridor's division into sub-areas. Streaming, camera framing and the
# ambience bed all key off this one map. See Docs/TT_ENGINE_NOTES.md section 8.
var areamap := AreaMap.new()
var _sp_area: SubArea = null
var _area_now: SubArea = null
var _authored_populated: int = 0
var _amb: AudioStreamPlayer3D = null
const STREAM_AHEAD := 190.0
const STREAM_BEHIND := 95.0
const CORRIDOR_HALF_WIDTH := 46.0

var score: int = 0
var phase: int = Phase.LOOT
var build_spot: Node3D
var anchor_node: Node3D
var build_progress: float = 0.0
var dorothy: Node3D
var dorothy_deployed: bool = false
var true_chaser_earned: bool = false

var context_action: String = "BRACE"
var build_held: bool = false
var _last_ctx_press: float = -10.0
var demo_mode: bool = false
var capture_mode: bool = false
var _capture_at: Array = [5.0, 11.0, 17.0, 23.0, 29.0]
var _capture_i: int = 0
var _capture_dir: String = "/home/user/brickstorm_shots"
var _closeup: bool = false
var _camera_locked: bool = false
var playthrough: bool = false
var probe_mode: bool = false
var _probe_t: float = 0.0
var _tel: Array = []
var _tel_shot: float = 0.0
var _tel_shots: int = 0
var _fps_min: float = 9999.0
var _fps_sum: float = 0.0
var _fps_n: int = 0
var _peak_structures: int = 0
const PLAYTHROUGH_SECONDS := 200.0
var _demo_target := Vector3.ZERO
var _elapsed: float = 0.0


func _ready() -> void:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	# CAPTURES ARE EVIDENCE, SO THEY MUST BE COMPARABLE. With randomize() the
	# world differs every run and two screenshots cannot be held against each
	# other - which is exactly what happened trying to judge a lighting change:
	# the "after" shot had a barn in it that the "before" shot did not, and the
	# measured difference was mostly the barn. A fixed seed makes a capture a
	# controlled comparison instead of an anecdote.
	if args.has("--capture"):
		seed(CAPTURE_SEED)
	else:
		randomize()
	capture_mode = args.has("--capture")
	playthrough = args.has("--playthrough")
	probe_mode = args.has("--probe")
	demo_mode = args.has("--demo") or args.has("--selftest") or capture_mode or playthrough

	_setup_environment()
	_build_ground()
	_build_town()
	_spawn_actors()
	# after _spawn_actors: the roof gag needs the comedy layer to exist
	_spawn_set_piece(Vector3(0, 0, SET_PIECE_Z))
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
	sm.sky_top_color = Color(0.13, 0.17, 0.16)
	sm.sky_horizon_color = Color(0.72, 0.66, 0.36)
	sm.ground_bottom_color = Color(0.30, 0.34, 0.24)
	sm.ground_horizon_color = Color(0.62, 0.58, 0.38)
	sm.sun_angle_max = 40.0
	sky.sky_material = sm
	env.sky = sky
	# THE AMBIENT IS THE SKY, NOT A COLOUR. A flat ambient term lights every
	# face of a brick identically, which is the single flattest thing a
	# renderer can do and is much of why our bricks read as cardboard. Sampling
	# the sky means a brick's top takes the storm above it and its underside
	# takes the ground it stands on - TT do this with a diffuse environment
	# cube, see Docs/TT_ENGINE_NOTES.md section 10.
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 1.0
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	# Energy is the one global dimmer over every ambient-lit surface, which is
	# what TT drive with sceneAmbientColor.a when a level goes indoors.
	env.ambient_light_energy = 0.75

	# A TONEMAPPER, because without one Godot is linear and everything above
	# 1.0 simply flatlines. Measured against the demo: 97.5% of our minifig's
	# head was clipped to pure white with a tonal spread of 2.1%, where the
	# demo's face clips 0.0% and spreads 20.9%. The model was never the
	# problem - the exposure was, and a flat blown-out surface is exactly what
	# reads as a toy rather than a photographed model.
	# ACES rolls the highlights off instead of cutting them, so a bright yellow
	# head keeps its shading; tonemap_white sets how much headroom there is
	# above 1.0 before anything is lost at all.
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 1.6
	env.fog_enabled = true
	env.fog_light_color = Color(0.66, 0.65, 0.46)
	env.fog_density = 0.0009
	we.environment = env
	we.add_to_group("worldenv")
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-46, 38, 0)
	sun.light_energy = 0.35
	sun.light_color = Color(1.0, 0.96, 0.88)
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

	# The ground is TEXTURED EARTH, not a baseplate. It was a 420m studded
	# plate on the theory that a world where nothing the bricks stand on is
	# itself a brick reads as blocks rather than as LEGO. Measurement said the
	# opposite: with the ground plastic too, nothing was left for the plastic to
	# read AGAINST, and half of every frame was a single flat saturated green.
	# Pillar 1 now draws the line at smashability, and the ground does not
	# break. See shaders/ground.gdshader and Docs/NORTH_STAR.md.
	var pm := PlaneMesh.new()
	pm.size = Vector2(420, 420)
	pm.subdivide_width = 4
	pm.subdivide_depth = 4
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	var gm := ShaderMaterial.new()
	gm.shader = load("res://shaders/ground.gdshader")
	mi.material_override = gm
	add_child(mi)

	# The crop squares are GONE. They were sixteen meshes scattered once within
	# 150m of the origin while the storm travels 600m, so the back two thirds
	# of every round ran on bare ground - and being randomly placed blobs they
	# read as patches on a lawn rather than as farmland. The fields, the section
	# roads and the plough rows are now drawn by shaders/ground.gdshader, which
	# is world-locked and therefore has no edge to run off.


# --------------------------------------------------------------------- world
# Small convenience: a positioned visual brick.
# [BS:WORLD:GROUND:END]
func _vbrick(sw: int, sd: int, h: float, colour: Color, pos: Vector3) -> Node3D:
	var b := BrickLib.brick_visual(sw, sd, h, colour)
	b.position = pos
	return b


func _add_vehicle(pos: Vector3, colour: Color, yaw: float) -> void:
	var v := Vehicle.new()
	v.body_colour = colour
	add_child(v)
	v.global_position = pos
	v.heading = yaw
	v.rotation.y = yaw
	v.rammed.connect(_on_vehicle_ram)
	vehicles.append(v)


func _add_structure(st: Structure) -> void:
	add_child(st)
	structures.append(st)
	areamap.adopt(st)


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
	# The starting pocket is a sub-area like everything else, so its structures
	# are owned and retire on the same schedule as streamed ones. Before this it
	# was the one stretch of world that nothing owned.
	areamap.depth = AREA_DEPTH
	areamap.frontier = START_Z0
	areamap.reserve(START_Z0, START_DEPTH, "START")
	areamap.ensure_ahead(START_Z0 + START_DEPTH, _populate_area)

	# Everything beyond this arrives from BS:WORLD:STREAM as the storm advances.
	_add_structure(PropBuilder.barn(Vector3(16, 0, -18)))
	_add_structure(PropBuilder.farmhouse(Vector3(-20, 0, -12)))
	_add_structure(PropBuilder.silo(Vector3(25, 0, -14)))
	_add_structure(PropBuilder.water_tower(Vector3(-6, 0, 22)))
	_add_vehicle(Vector3(-13, 0.4, -4), BrickLib.C_RED, 0.4)
	_add_vehicle(Vector3(-8, 0.4, 2), BrickLib.C_WHITE, 1.9)
	outhouse = PropBuilder.outhouse(Vector3(9, 0, 4))
	_add_structure(outhouse)
	for p in [Vector3(-28, 0, 4), Vector3(-16, 0, 12), Vector3(8, 0, -30), Vector3(34, 0, -4)]:
		_add_structure(PropBuilder.tree(p, randf_range(0.85, 1.3)))
	_add_structure(PropBuilder.fence_run(Vector3(-12, 0, 6), Vector3(12, 0, 6)))
	for k in range(16):
		var a := TAU * float(k) / 16.0
		var r := 12.0 + fmod(float(k) * 7.3, 22.0)
		_add_structure(PropBuilder.furniture(k * 3, Vector3(cos(a) * r, 0, sin(a) * r - 6.0), a))

	_build_cows()


# Design Law #1: cows fly, cows land, cows are never destroyed.
# [BS:WORLD:LAYOUT:END]


# ============================================================================
# [BS:WORLD:STREAM]
# Purpose: Keep the corridor populated ahead of the storm and reclaim it behind.
# Invariants:
# - The world is a ROUTE the storm travels, not an arena it loops. Measured on
#   2026-09-08: an arena is bare 90 seconds in and the last third of the round
#   has nothing in it. See Docs/PLAYTEST_VS_LEGO_INDY.md.
# - Blocks spawn ahead and are reclaimed behind, so the live object count is
#   bounded no matter how long the round runs. Never generate the whole
#   corridor up front.
# - Density is the point. In a LEGO game you are never more than a couple of
#   paces from something that breaks, and that is what makes SMASH the default
#   verb rather than an occasional one.
# - Nothing may spawn ON the player or inside the storm.
# ============================================================================
func _stream_world(delta: float) -> void:
	_stream_t -= delta
	if _stream_t > 0.0:
		return
	_stream_t = 0.4

	# The map decides where one area ends and the next begins, and it never
	# hands an AUTHORED area to the populator. That reservation used to be
	# open-coded arithmetic here against a magic Z.
	var front := tornado.funnel_pos().z + STREAM_AHEAD
	areamap.ensure_ahead(front, _populate_area)

	# Retire whole areas rather than testing every structure every pass. The
	# map re-homes anything the funnel has thrown ahead of the cutoff.
	var cutoff := tornado.funnel_pos().z - STREAM_BEHIND
	for st in areamap.retire_behind(cutoff):
		st.queue_free()
	areamap.compact()

	var i := structures.size() - 1
	while i >= 0:
		var st2 := structures[i]
		if not is_instance_valid(st2) or st2.is_queued_for_deletion():
			structures.remove_at(i)
		i -= 1


func _rng(n: int) -> float:
	# cheap deterministic hash so a block is stable if regenerated
	var x := float((n * 1103515245 + 12345) % 2147483647) / 2147483647.0
	return absf(x)


# Fill one procedural sub-area. The area, not a loose float, is the unit.
func _populate_area(area: SubArea) -> void:
	# The reservation rule, made observable. If this ever increments, hand-
	# composed ground is being scattered with random props, which is the one
	# thing a set piece exists not to be.
	if area.kind == SubArea.Kind.AUTHORED:
		_authored_populated += 1
		return
	var z0 := area.z0
	var span := area.depth
	var b := area.index + 1
	var w := CORRIDOR_HALF_WIDTH

	# One landmark per block, alternating, so there is always something big
	# arriving ahead of the storm.
	var lx: float = lerpf(-w * 0.7, w * 0.7, _rng(b * 7))
	var lz: float = z0 + _rng(b * 11) * span
	match b % 7:
		0: _add_structure(PropBuilder.barn(Vector3(lx, 0, lz)))
		1: _add_structure(PropBuilder.farmhouse(Vector3(lx, 0, lz)))
		2:
			_add_structure(PropBuilder.silo(Vector3(lx, 0, lz)))
			_add_structure(PropBuilder.silo(Vector3(lx + 4.0, 0, lz - 4.0)))
		3: _add_structure(PropBuilder.water_tower(Vector3(lx, 0, lz)))
		4: _add_structure(PropBuilder.windmill(Vector3(lx, 0, lz)))
		5: _add_structure(PropBuilder.grain_elevator(Vector3(lx, 0, lz), _rng(b) * 0.6))
		_: _add_structure(PropBuilder.drive_in_screen(Vector3(lx, 0, lz), _rng(b) * 2.0))

	# THE POWER LINE. A run of poles marching to a flat horizon is the single
	# most Great Plains image there is, and the corridor had none. They follow
	# the section road the ground shader draws at x = +/-24, alternating sides
	# so the player is not always looking at the same one.
	var road_x: float = 24.0 if b % 2 == 0 else -24.0
	_add_structure(PropBuilder.power_line(
		Vector3(road_x + 3.0, 0, z0), Vector3(road_x + 3.0, 0, z0 + span)))

	# Trees grow in SHELTERBELT ROWS out here, planted as windbreaks along a
	# field edge, not scattered singly across the middle of a section like a
	# park. Clustering them also leaves the open field genuinely open, which is
	# most of what makes the land read as big.
	var belt_x: float = lerpf(-w * 0.8, w * 0.8, _rng(b * 31))
	var belt_z: float = z0 + _rng(b * 17) * span * 0.6
	for k in range(4):
		_add_structure(PropBuilder.tree(
			Vector3(belt_x + _rng(b * 3 + k) * 1.4, 0, belt_z + float(k) * 3.2),
			0.85 + _rng(b * 3 + k) * 0.5))
	if b % 2 == 0:
		var fx: float = lerpf(-w * 0.8, w * 0.8, _rng(b * 41))
		_add_structure(PropBuilder.fence_run(
			Vector3(fx, 0, z0 + 2.0), Vector3(fx, 0, z0 + span - 2.0)))

	# the dense furniture layer - this is what removes dead time
	for k in range(11):
		var fx2: float = lerpf(-w, w, _rng(b * 97 + k * 23))
		var fz: float = z0 + _rng(b * 53 + k * 13) * span
		var yaw: float = _rng(b * 61 + k) * TAU
		_add_structure(PropBuilder.furniture(b * 7 + k, Vector3(fx2, 0, fz), yaw))

	# an occasional parked truck to ram
	if b % 3 == 1:
		var px: float = lerpf(-w * 0.6, w * 0.6, _rng(b * 71))
		_add_structure(PropBuilder.pickup(Vector3(px, 0, z0 + span * 0.5),
			[BrickLib.C_BLUE, BrickLib.C_YELLOW, BrickLib.C_WHITE][b % 3], _rng(b * 13) * TAU))
# [BS:WORLD:STREAM:END]
# ============================================================================
# [BS:WORLD:CRITTERS]
# Purpose: Cows - protected actors, and the proof of North Star Law 1.
# Invariants:
# - Cows are on collision layer 8. Debris (layer 4) cannot touch them.
# - They are dragged by the funnel exactly like debris, and are NEVER
#   converted to studs, damaged, or removed. They fly, they land, they
#   are fine. See BS:LAW:NO_HARM.
# ============================================================================
# One cow. Used by the herd and by the roof gag alike.
func _make_cow() -> RigidBody3D:
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
	return cow


func _build_cows() -> void:
	critter_root = Node3D.new()
	critter_root.name = "Critters"
	add_child(critter_root)

	for p in [Vector3(-4, 0, 12), Vector3(2, 0, 15), Vector3(-8, 0, 17), Vector3(5, 0, 10)]:
		var cow := _make_cow()
		critter_root.add_child(cow)
		cow.global_position = p


# -------------------------------------------------------------------- actors
# [BS:WORLD:CRITTERS:END]


# ============================================================================
# [BS:CONTENT:SET_PIECE]
# Purpose: Place the hand-authored farmyard and wire its three collectibles.
# Invariants:
# - Its structures are registered like any others, so the storm can still tear
#   them - EXCEPT the gate, which is heavy and survives on purpose.
# - The three balls are the first collectibles in the game. Their payout is
#   deliberately disproportionate: TT Games pay 50,000 studs for ten minikits
#   against a level threshold of a few thousand, because the message is that
#   exploring is loudly rewarded rather than merely permitted.
#   See Docs/TT_GAMES_REFERENCE.md.
# - The set piece is placed far enough up the corridor that a player meets it
#   after learning to move, and is not culled behind the storm before arrival.
# ============================================================================
func _spawn_set_piece(origin: Vector3) -> void:
	# Reserve the ground FIRST. An AUTHORED area is never handed to the
	# populator, which is the whole of the rule that used to be open-coded
	# arithmetic in the streamer against a magic Z.
	_sp_area = areamap.reserve(origin.z - 10.0, 42.0, "HOG_LOT")
	# The one place in the game with a hand-authored camera. The yard is a
	# composition and it only reads from further back and a little higher; the
	# automatic camera frames a minifig, which is right everywhere else.
	# Procedural areas leave these at zero - automatic by default, authored
	# where it matters, which is how the LEGO games do it.
	_sp_area.cam_back_bias = 5.0
	_sp_area.cam_height_bias = 2.6
	_sp_area.cam_range = 22.0

	_sp = SetPiece.hog_lot(origin)
	for st in _sp["structures"]:
		_add_structure(st)
	(_sp["gate"] as Structure).heavy = true

	for i in range(_sp["balls"].size()):
		_sp_balls.append(_make_sensor_ball(_sp["balls"][i]))

	# the build site that becomes the steps to the tower
	var marker := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.5
	tm.outer_radius = 1.8
	marker.mesh = tm
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mm.albedo_color = Color(0.4, 0.9, 1.0, 0.45)
	marker.material_override = mm
	marker.position = _sp["build_pos"] + Vector3(0, 0.06, 0)
	marker.name = "SetPieceBuildMarker"
	add_child(marker)
	_sp["marker"] = marker

	# the gag: a cow, on a roof, for no reason anyone will explain
	_spawn_roof_cow(_sp["cow_pos"])


func _make_sensor_ball(at: Vector3) -> Node3D:
	var n := Node3D.new()
	add_child(n)
	n.global_position = at
	var ball := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.30
	sm.height = 0.60
	sm.radial_segments = 14
	sm.rings = 8
	ball.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.45, 0.95, 1.0)
	m.emission_enabled = true
	m.emission = Color(0.3, 0.8, 1.0)
	m.emission_energy_multiplier = 1.6
	ball.material_override = m
	n.add_child(ball)
	var ring := MeshInstance3D.new()
	var rt := TorusMesh.new()
	rt.inner_radius = 0.42
	rt.outer_radius = 0.50
	ring.mesh = rt
	ring.material_override = m
	n.add_child(ring)
	return n
# [BS:CONTENT:SET_PIECE:END]
func _spawn_actors() -> void:
	debris_root = Node3D.new()
	debris_root.name = "Debris"
	add_child(debris_root)

	comedy = Comedy.new()
	comedy.name = "Comedy"
	add_child(comedy)

	audio = GameAudio.new()
	audio.name = "Audio"
	audio.add_to_group("audio")
	add_child(audio)

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
	tornado.corridor_mode = true
	tornado.move_speed = 3.0
	tornado.global_position = Vector3(0, 0, -24)

	_roar = audio.attach_loop("roar", tornado, -60.0)
	if _roar != null:
		# Volume is driven by the proximity curve below rather than by 3D
		# falloff, so the swell is a designed curve and not a side effect.
		_roar.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED

	player = Player.new()
	player.name = "Player"
	player.add_to_group("player")
	add_child(player)
	player.global_position = Vector3(-4, 0.2, 0)
	player.tumbled.connect(_on_player_tumbled)

	# The ambience bed rides with the player and is driven by the sub-area's
	# state - see BS:WORLD:AREA_STATE. "wind" sat unused in the bank until the
	# sub-area gave it something to key off.
	_amb = audio.attach_loop("wind", player, -60.0)
	if _amb != null:
		_amb.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED

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
	hud.smash_pressed.connect(_on_smash_pressed)
	hud.build_pressed.connect(_on_build_pressed)
	hud.build_released.connect(_on_build_released)
	hud.jump_pressed.connect(_on_jump_pressed)
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
	_update_gags()
	if probe_mode:
		_probe_t += delta
		if _probe_t >= 0.4:
			_probe_t = 0.0
			var pp := player.global_position
			print("PROBE t=%.1f pos=%.2f,%.2f,%.2f input=%.2f,%.2f" % [
				_elapsed, pp.x, pp.y, pp.z, player.move_input.x, player.move_input.y])
	_update_set_piece(delta)
	_stream_world(delta)
	_refresh_near(delta)
	if playthrough:
		_tick_playthrough(delta)
	_update_storm_audio()
	_update_area_state(delta)
	# One call moves every plant in the world: the foliage all draws through
	# the same material, which is the point of a world-space wind field.
	Structure.set_storm(tornado.funnel_pos(), tornado.wind_reach())
	hud.set_bracing(player.braced)
	if demo_mode:
		_demo_smash(delta)
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

	# The stick is a SCREEN direction, so it must be rotated into the camera's
	# frame. The camera orbits the player, so feeding raw world axes straight
	# in sends you somewhere unrelated to where your thumb pushed - which is
	# exactly what it felt like. Autopilot and self-test inputs are already
	# world-space and deliberately bypass this.
	if v.length() > 0.01:
		var b := camera.global_transform.basis
		var fwd := Vector3(-b.z.x, 0.0, -b.z.z).normalized()
		var right := Vector3(b.x.x, 0.0, b.x.z).normalized()
		var w := right * v.x - fwd * v.y
		v = Vector2(w.x, w.z)

	if demo_mode:
		v = _demo_input()
	if _force_input:
		v = _forced_input

	if driving != null:
		driving.move_input = v
		player.move_input = Vector2.ZERO
	else:
		player.move_input = v

	if Input.is_physical_key_pressed(KEY_SPACE):
		_on_jump_pressed()


# ============================================================================
# [BS:CAMERA:DIRECTOR]
# Purpose: Auto-framing. The camera is a director, not a player control.
# Invariants:
# - There is no camera control and never will be (pillar 6).
# - The lead toward the funnel is CAPPED. Uncapped, the camera frames
#   a midpoint and loses the player off-screen entirely. This has
#   already been a bug once.
# - The player is always in frame. That is the one hard requirement.
# - The camera orbits to sit OPPOSITE the funnel, so the framing is always
#   player-foreground / storm-beyond and the funnel can never come between the
#   lens and the player. Yaw follows the storm slowly; pitch is fixed.
# - Framing hints come from the sub-area the player is in, faded in over that
#   area's range of effect so the change reads as direction rather than as a
#   snap. Procedural areas carry no hint, so the automatic camera is untouched
#   over the great majority of the corridor - authored only where it matters.
# - It is additionally kept FUNNEL_CLEARANCE metres clear of the funnel axis.
#   The cone flares near the top, and a camera that drifts over it films the
#   inside of the tornado. This has already been a bug once.
# ============================================================================
func _update_camera(delta: float) -> void:
	if _camera_locked:
		return                      # verification closeups own the camera
	var p := player.global_position
	var t := tornado.funnel_pos()

	# Sit on the far side of the player FROM the funnel, so the shot is always
	# player in the foreground with the storm beyond them - and the funnel can
	# never end up between the lens and the player.
	var want := Vector3(p.x - t.x, 0.0, p.z - t.z)
	if want.length() < 0.5:
		want = _cam_dir
	want = want.normalized()
	_cam_dir = _cam_dir.lerp(want, clampf(delta * 0.9, 0.0, 1.0)).normalized()

	var d: float = clampf(p.distance_to(t), 14.0, 60.0)
	# Close and low. A LEGO game frames the MINIFIG; a distant top-down camera
	# turns the star of the show into a speck and reads as a strategy game.
	# Per-area framing. Zero everywhere except the areas that ship a hint, so
	# the automatic camera is unchanged over procedural ground.
	var bias := areamap.framing_at(p.z)
	var back: float = 9.5 + d * 0.12 + bias.x
	var height: float = 5.4 + d * 0.10 + bias.y
	var desired := p + _cam_dir * back + Vector3(0, height, 0)

	# Backstop: never inside the cone, which flares near the top.
	var away := Vector3(desired.x - t.x, 0.0, desired.z - t.z)
	if away.length() < FUNNEL_CLEARANCE:
		away = (away.normalized() if away.length() > 0.01 else _cam_dir) * FUNNEL_CLEARANCE
		desired.x = t.x + away.x
		desired.z = t.z + away.z

	camera.global_position = camera.global_position.lerp(desired, clampf(delta * 2.4, 0.0, 1.0))

	# Look slightly past the player toward the storm.
	var lead := t - p
	lead.y = 0.0
	if lead.length() > 16.0:
		lead = lead.normalized() * 16.0
	camera.look_at(p + lead * 0.22 + Vector3(0, 1.5, 0), Vector3.UP)


# ------------------------------------------------------------------ contexts
# [BS:CAMERA:DIRECTOR:END]
# ============================================================================
# [BS:WORLD:NEAR_CACHE]
# Purpose: A short list of structures close enough to matter this frame.
# Invariants:
# - The hot loops - context probing, funnel tearing, player smash - must NOT
#   walk every structure in the corridor every frame. Measured 2026-09-08: with
#   152 live structures the round ran at 10 fps, and dropping the render
#   resolution to an eighth changed it to 12, which is what proved the cost was
#   CPU-side GDScript iteration rather than rendering.
# - Refreshed on a timer, not per frame. A quarter second of staleness is
#   invisible at walking pace and is the entire point of the cache.
# - Anything iterating `structures` directly in a per-frame path is a bug.
# - Consumers must validate each entry. The cache is rebuilt on a timer, so it
#   can outlive a structure freed since the last refresh. This never fired
#   while the only source of freeing was reclaim 95m behind the storm; a test
#   that freed one next to the player found it immediately.
# - The refresh is also distance-triggered, not purely on a timer: a teleport
#   or a fast truck outruns a 0.25s timer and a stale list makes SMASH hit
#   nothing at all.
# ============================================================================
func _refresh_near(delta: float) -> void:
	_near_t -= delta
	# Also refresh early if the player has moved far since the last rebuild -
	# a timer alone goes stale under a teleport or a fast vehicle, and a stale
	# list means SMASH silently hits nothing.
	if _near_t > 0.0 and player.global_position.distance_squared_to(_near_from) < 64.0:
		return
	_near_t = 0.25
	_near_from = player.global_position
	_near.clear()
	var p := player.global_position
	var c := tornado.funnel_pos()
	for st in structures:
		if not is_instance_valid(st) or st.is_rubble():
			continue
		var o := st.global_position
		if o.distance_squared_to(p) < 4900.0 or o.distance_squared_to(c) < 2500.0:
			_near.append(st)
# [BS:WORLD:NEAR_CACHE:END]


func _nearest_structure(within: float) -> Structure:
	var best: Structure = null
	var bd := within
	for s in _near:
		if not is_instance_valid(s) or s.is_rubble():
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
	var act := "--"

	if driving != null:
		act = "EXIT"
	elif phase == Phase.DEPLOY and player.carrying != null and anchor_node != null \
			and p.distance_to(anchor_node.global_position) < 3.5:
		act = "DEPLOY"
	elif phase >= Phase.CARRY and player.carrying == null and dorothy != null \
			and not dorothy_deployed and p.distance_to(dorothy.global_position) < 3.0:
		act = "GRAB"
	elif not _sp_built and not _sp.is_empty() and p.distance_to(_sp["build_pos"]) < 3.2:
		act = "BUILD"
	elif phase == Phase.BUILD and p.distance_to(build_spot.global_position) < 3.0:
		act = "BUILD"
	elif _nearest_vehicle(4.5) != null:
		act = "DRIVE"

	context_action = act
	hud.set_context(act)
# [BS:OBJECTIVE:CONTEXT_ACTION:END]


func _on_jump_pressed() -> void:
	var was_floor := player.is_on_floor()
	player.jump()
	if was_floor and player.driving == null and player.tumble_timer <= 0.0:
		audio.jump(player.global_position)


func _on_smash_pressed() -> void:
	var now := _elapsed
	if now - _last_ctx_press < 0.32:
		player.use_ability()
		if player.character == Player.Character.JO:
			hud.toast("READ THE SKY", Color(0.5, 0.85, 1.0))
	_last_ctx_press = now
	_do_smash()


func _on_build_pressed() -> void:
	build_held = true
	match context_action:
		"DRIVE":
			_enter_vehicle()
		"EXIT":
			_exit_vehicle()
		"GRAB":
			player.carry(dorothy)
			hud.toast("DOROTHY UP", BrickLib.C_YELLOW)
			phase = Phase.DEPLOY
			hud.set_objective("CARRY DOROTHY TO THE ANCHOR")
		"DEPLOY":
			_do_deploy()


func _on_build_released() -> void:
	build_held = false
	if phase == Phase.BUILD:
		build_progress = 0.0


# ============================================================================
# [BS:PLAYER:SMASH]
# Purpose: Player-driven destruction. Available to everyone, at all times.
# Invariants:
# - Smashing everything is a headline pleasure of the genre and is never gated
#   behind a character, a resource, or a cooldown (North Star pillar 7).
# - It only ever tears SCENERY. Structures only - actors are untouchable, so a
#   smash cannot break North Star Law 1.
# - Player smash pays at the CURRENT band like any other stud. It is safe and
#   always available; the funnel is where the multiplier lives. That contrast
#   is what keeps the risk economy alive alongside free-for-all smashing.
# - Every smash produces a comic-book word (BS:COMEDY:POPUPS). A silent smash
#   is a wasted joke.
# - A SMASH TAKES A BITE, NOT A PROP. The bite is bounded by VOLUME, not by a
#   brick count. It used to be capped at ten bricks, which is more than any
#   small prop contains, so a barrel, a bin, a crate or a hay bale came apart
#   in a single hit. That made the pace of the game a side effect of how each
#   model happened to be subdivided: rebuilding the smashables from round parts
#   (a barrel went from 21 pieces to 6) halved the measured SMASH rate - from
#   6.3/min to a four-round mean of 3.4 - without anyone touching this verb.
#   Measured in Docs/PLAYTEST_VS_LEGO_INDY.md follow-up 2; guarded by
#   tools/smash_probe.gd, which requires every smashable to take at least
#   three hits and requires that number NOT to move when a prop is rebuilt at
#   a different granularity.
# - A budget cannot take a fraction of a part, so a prop needs enough pieces
#   for three bites to be possible. Part count is the floor, the budget is the
#   ceiling, and the probe checks both.
# ============================================================================
func _do_smash() -> void:
	if driving != null:
		return
	var p := player.global_position
	var reach := player.smash_radius()
	var hit := 0
	for st in _near:
		if hit >= 10:
			break
		if not is_instance_valid(st) or st.is_rubble():
			continue
		if st.global_position.distance_to(p) > reach + 12.0:
			continue
		var strength := Structure.HEAVY_STRENGTH if player.character == Player.Character.BILL else 1.0
		var bodies := st.tear(p, reach, debris_root, 10 - hit, strength, Structure.SMASH_BITE)
		for b in bodies:
			var away: Vector3 = (b.global_position - p).normalized()
			b.apply_central_impulse((away + Vector3.UP * 0.9) * 6.5 * b.mass)
			debris.append({"body": b, "age": 0.0, "by_player": true})
		hit += bodies.size()
		_pay_finish(st)
	if hit > 0:
		_log_event("SMASH", "bricks=%d" % hit)
		comedy.smash(p + Vector3(0, 1.6, 0))
		audio.smash(p + Vector3(0, 1.2, 0), hit >= 5)
# [BS:PLAYER:SMASH:END]


func _enter_vehicle() -> void:
	var v := _nearest_vehicle(4.5)
	if v == null:
		return
	driving = v
	player.driving = v
	v.board(player)
	hud.toast("FLOOR IT", BrickLib.C_YELLOW)


func _exit_vehicle() -> void:
	if driving == null:
		return
	var at := driving.alight()
	driving = null
	player.driving = null
	player.global_position = at
	player.velocity = Vector3.ZERO


func _nearest_vehicle(within: float) -> Vehicle:
	if driving != null:
		return null
	var best: Vehicle = null
	var bd := within
	for v in vehicles:
		var d := v.global_position.distance_to(player.global_position)
		if d < bd:
			bd = d
			best = v
	return best


func _on_vehicle_ram(st: Node, at: Vector3, force: float) -> void:
	var structure := st as Structure
	if structure == null:
		return
	var bodies := structure.tear(at, 3.6, debris_root, 10)
	for b in bodies:
		var away: Vector3 = (b.global_position - at).normalized()
		b.apply_central_impulse((away + Vector3.UP * 0.7) * force * 0.9 * b.mass)
		# The truck is the player. A ram is a player verb and pays like one.
		debris.append({"body": b, "age": 0.0, "by_player": true})
	_pay_finish(structure)
	if bodies.size() > 0:
		_log_event("RAM", "bricks=%d force=%.0f" % [bodies.size(), force])
		comedy.ram(at + Vector3(0, 1.4, 0))
		audio.ram(at, force)


func _do_deploy() -> void:
	var pod := player.drop()
	if pod == null:
		return
	pod.global_position = anchor_node.global_position + Vector3(0, 1.4, 0)
	dorothy_deployed = true
	_log_event("DEPLOY", "dorothy released")
	audio.deployed(anchor_node.global_position)
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
				_relocate_objective()
				_log_event("PHASE", "BUILD unlocked at %d studs" % score)
				audio.objective(player.global_position)
				hud.toast("ANCHOR SITE UNLOCKED", Color(0.4, 0.95, 1.0))
				hud.set_objective("BUILD THE ANCHOR")
		Phase.BUILD:
			if build_held and context_action == "BUILD":
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


# The corridor moves; a build site left at the start line is unreachable.
func _relocate_objective() -> void:
	var c := tornado.funnel_pos()
	build_spot.global_position = Vector3(c.x + randf_range(-16.0, 16.0), 0.0, c.z + 24.0)
	if dorothy != null and not dorothy_deployed and player.carrying == null:
		dorothy.global_position = player.global_position + Vector3(5.0, 0.0, 3.0)


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
	_log_event("BUILD", "anchor assembled")
	comedy.built(anchor_node.global_position + Vector3(0, 3.4, 0))
	audio.built(anchor_node.global_position)
	hud.toast("ANCHOR BUILT", Color(0.5, 1.0, 0.6))
	hud.set_objective("GRAB DOROTHY FROM THE TRUCK")


func _win() -> void:
	phase = Phase.WON
	# Latched, not re-tested: a tumble after earning it must not take it back.
	var rating := "TRUE CHASER" if true_chaser_earned else "LOGGED"
	hud.toast("F3 LOGGED - DOROTHY DEPLOYED   %s" % rating, BrickLib.C_YELLOW)
	hud.set_objective("F3 LOGGED - %s   (%d STUDS)" % [rating, score])


# ---------------------------------------------------------------- destruction
func _tear_with_funnel() -> void:
	var c := tornado.funnel_pos()
	var budget := TEAR_BUDGET
	for s in _near:
		if budget <= 0:
			break
		# The cache is rebuilt on a timer, so it can outlive a structure freed
		# since the last refresh - reclaim, a set piece teardown, anything.
		# Cheap here because the cache is short; the invariant that bans
		# walking every structure is unaffected.
		if not is_instance_valid(s):
			continue
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
		_pay_finish(s)


# ============================================================================
# [BS:ECONOMY:FINISH_BONUS]
# Purpose: Finishing a structure off drops a big stud where it stood.
# Invariants:
# - PAID EXACTLY ONCE per structure, whoever finished it. A structure crosses
#   the rubble threshold on some particular tear, and that tear can come from
#   the player, a truck or the funnel; `paid_finish` is the latch.
# - THE BONUS IS A STUD ON THE GROUND, NOT SCORE. It has to be collected, so
#   a jackpot that drops inside the red band is a decision - go in and get it,
#   at up to five times the value, or leave it. Awarding score directly would
#   hand the money over for free and cut the risk gradient out of the reward.
# - This is the answer to the flat stud stream: a payout the player can SEE
#   coming, in a place, for having completed something. See
#   Docs/PLAYTEST_VS_LEGO_INDY.md finding 4, and BS:ECONOMY:DENOMINATION.
# - It rewards FINISHING. Half-smashing six props used to pay exactly as well
#   as levelling one, which is why the round played as grazing rather than as
#   destroying things.
# ============================================================================
func _pay_finish(st: Structure) -> void:
	if st == null or st.paid_finish or not st.is_rubble():
		return
	st.paid_finish = true
	# Small scenery pays in ordinary studs like everything else. It still
	# breaks, it still pays, it just does not throw a jackpot for a bin.
	if st.entries.size() < FINISH_MIN_PARTS:
		return
	var big: bool = st.entries.size() >= BIG_STRUCTURE
	var denom: int = StudField.VALUE_BLUE if big else StudField.VALUE_GOLD
	var at := st.global_position + Vector3(0, 1.2, 0)
	studfield.spawn_burst(at, 1, denom)
	# Only a building announces itself as it goes. The gold stud is its own
	# signal, and collecting it already pops; a comic word on every finish as
	# well was most of the noise.
	if big:
		comedy.pop(at + Vector3(0, 1.0, 0), "WRECKED!",
			StudField.denom_colour(denom), 130)
	_log_event("FINISH", "%s parts=%d" % ["blue" if big else "gold", st.entries.size()])
# [BS:ECONOMY:FINISH_BONUS:END]


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
		# A brick the PLAYER knocked loose pays almost at once. Everything used
		# to sit for BRICK_LIFETIME - six seconds - before becoming studs, so
		# the reward for smashing arrived long after the smash and the loop
		# never closed. In a LEGO game you hit a thing and the studs come out
		# of it; that is the whole feedback loop, and six seconds is not it.
		# The funnel keeps the long lifetime: its debris is meant to fly, and
		# the flight IS the spectacle.
		var life: float = PLAYER_BRICK_LIFETIME if d.get("by_player", false) else BRICK_LIFETIME
		if d["age"] > life or b.global_position.y < -8.0 or over:
			var at := b.global_position
			at.y = maxf(at.y, 0.3)
			studfield.spawn_burst(at, randi_range(1, 3))
			b.queue_free()
			debris.remove_at(i)
		i -= 1
# [BS:DESTRUCTION:DEBRIS_LIFECYCLE:END]


func _check_lift() -> void:
	if driving != null or player.tumble_timer > 0.0 or player.immune_to_lift():
		return
	var d := tornado.funnel_pos().distance_to(player.global_position)
	if d < tornado.lift_radius:
		player.tumble()


# ------------------------------------------------------------------- scoring
# ============================================================================
# [BS:ECONOMY:THRESHOLD_LOCK]
# Purpose: A threshold, once crossed, is never taken back.
# Invariants:
# - TRUE CHASER latches. Tumbling costs studs, but it must NEVER un-earn a
#   threshold the player already reached. This is the load-bearing rule behind
#   TT Games' whole risk economy: the currency is soft, the achievement is
#   hard, and that is what makes players willing to keep taking risks.
#   See Docs/TT_GAMES_REFERENCE.md.
# - Any future award, rating or unlock added here latches the same way. If it
#   can be lost, it is not a threshold, it is a punishment.
# ============================================================================
func _on_stud_collected(value: int, _band: int, at: Vector3, denom: int = 10) -> void:
	score += value
	_log_event("STUD", "+%d total=%d" % [value, score])
	audio.stud(at)
	# A jackpot has to READ as one. A silver stud is a tick; a gold or blue is
	# an event, and gets the comic-book treatment every other event gets.
	if denom >= StudField.VALUE_BLUE:
		comedy.pop(at + Vector3(0, 1.9, 0), "JACKPOT!", Color(0.55, 0.75, 1.0), 150)
		hud.toast("BLUE STUD  +%s" % HUD._commas(value), Color(0.55, 0.75, 1.0))
		_log_event("JACKPOT", "blue +%d" % value)
	elif denom >= StudField.VALUE_GOLD:
		comedy.pop(at + Vector3(0, 1.6, 0), "NICE!", Color(1.0, 0.85, 0.25), 120)
		hud.toast("GOLD STUD  +%s" % HUD._commas(value), Color(1.0, 0.85, 0.25))
		_log_event("GOLD", "+%d" % value)
	if score >= TRUE_CHASER:
		if not true_chaser_earned:
			true_chaser_earned = true
			_log_event("RATING", "TRUE CHASER at %d" % score)
			audio.objective(player.global_position)
			hud.toast("TRUE CHASER", BrickLib.C_YELLOW)
			comedy.pop(player.global_position + Vector3(0, 3.0, 0),
				"TRUE CHASER!", Color(1.0, 0.85, 0.25), 150)
# [BS:ECONOMY:THRESHOLD_LOCK:END]


# The toll for getting caught: studs, not a game over (Design Law #2).
func _on_player_tumbled(at: Vector3) -> void:
	var lost: int = int(float(score) * 0.20)
	score -= lost
	hud.toast("TUMBLED" if lost == 0 else "TUMBLED  -%d" % lost, Color(1.0, 0.5, 0.4))
	_log_event("TUMBLE", "-%d studs" % lost)
	comedy.tumble(at + Vector3(0, 2.0, 0))
	audio.tumble(at + Vector3(0, 1.0, 0))
	var away := (player.global_position - tornado.funnel_pos()).normalized()
	player.launch(away, 12.0)
	if lost > 0:
		studfield.spawn_burst(at + Vector3(0, 1, 0), mini(12, int(lost / 10.0) + 1))


# ---------------------------------------------------------------------- demo
# Autopilot used for verification captures: walk the risk bands, loot, brace.
# ============================================================================
# [BS:AUDIO:STORM_ROAR]
# Purpose: The funnel's roar, swelling with proximity.
# Invariants:
# - The roar is the player's PRIMARY risk signal - it must be readable with
#   the screen ignored, because the whole game is about how close you dare to
#   stand and the eyes are busy looting.
# - Volume follows a designed curve, not 3D falloff, so the swell is authored.
# - It rises with the bands. If it is loud, the multiplier is high.
# ============================================================================
func _update_storm_audio() -> void:
	if _roar == null:
		return
	var d := tornado.funnel_pos().distance_to(player.global_position)
	var near: float = clampf(1.0 - d / 78.0, 0.0, 1.0)
	near = near * near
	_roar.volume_db = lerpf(-44.0, -13.0, near)
	_roar.pitch_scale = 0.70 + near * 0.26
# [BS:AUDIO:STORM_ROAR:END]


# ============================================================================
# [BS:WORLD:AREA_STATE]
# Purpose: The sub-area the player is in has a state, and the ambience follows.
# Invariants:
# - The state lives on the SUB-AREA, not on the player and not on the storm.
#   That is the point of the refactor: streaming, camera framing and the
#   ambience bed all read the same division of the world.
# - Three states, in TT's order of escalation: AMBIENT (nobody here), QUIET
#   (the player is here, the storm is not), ACTION (the storm is in this area).
# - The bed DUCKS in ACTION rather than swelling. The roar is the risk signal
#   and it must not compete with a wind bed; see BS:AUDIO:STORM_ROAR.
# - Transitions are RATE-LIMITED, not instant. TT quantise theirs to authored
#   musical markers, which we cannot do without composed music - a slow fade is
#   the honest stand-in, and the difference is recorded rather than papered
#   over. See Docs/TT_ENGINE_NOTES.md section 6.
# ============================================================================
const AMB_DB := {
	SubArea.Intensity.AMBIENT: -20.0,
	SubArea.Intensity.QUIET: -16.0,
	SubArea.Intensity.ACTION: -34.0,
}


func _update_area_state(delta: float) -> void:
	var pz := player.global_position.z
	var fz := tornado.funnel_pos().z
	var here := areamap.area_at(pz)
	if here == null:
		here = areamap.nearest(pz)
	if here == null:
		return

	# The storm is "in" an area when the funnel is inside its z-range. The
	# margin is deliberately generous: an area the storm is about to enter
	# should already sound like it.
	if fz >= here.z0 - 12.0 and fz < here.z1() + 12.0:
		here.intensity = SubArea.Intensity.ACTION
	else:
		here.intensity = SubArea.Intensity.QUIET
	_area_now = here

	if _amb == null:
		return
	var want: float = AMB_DB[here.intensity]
	_amb.volume_db = move_toward(_amb.volume_db, want, delta * 9.0)
# [BS:WORLD:AREA_STATE:END]


# ============================================================================
# [BS:ECONOMY:SENSOR_BALLS]
# Purpose: The collectible layer - the minikit slot the design always specified.
# Invariants:
# - Collecting all three pays SENSOR_BONUS, which is deliberately larger than
#   a whole round of looting. Exploration must out-earn grinding or nobody
#   will ever leave the storm's wake.
# - Balls are never destroyed by the storm and never expire. A collectible the
#   weather can delete is a collectible that punishes arriving late.
# - Pickup is a plain distance test on three nodes. It must stay that cheap.
# ============================================================================
func _update_set_piece(delta: float) -> void:
	if _sp.is_empty():
		return
	var p := player.global_position

	for i in range(_sp_balls.size()):
		var n: Node3D = _sp_balls[i]
		if n == null or not is_instance_valid(n):
			continue
		n.rotation.y += delta * 2.2
		n.position.y += sin(_elapsed * 2.0 + float(i)) * delta * 0.25
		if n.global_position.distance_to(p + Vector3(0, 0.9, 0)) < 1.9:
			_collect_sensor(i, n)

	if not _sp_built and build_held and context_action == "BUILD" \
			and p.distance_to(_sp["build_pos"]) < 3.2:
		_sp_build_progress += delta * (3.0 if player.character == Player.Character.BILL else 1.0)
		if _sp_build_progress >= BUILD_TIME:
			_assemble_steps()


func _collect_sensor(i: int, n: Node3D) -> void:
	_sp_balls[i] = null
	n.queue_free()
	sensors_found += 1
	_log_event("SENSOR", "%d/3" % sensors_found)
	audio.deployed(n.global_position)
	comedy.pop(n.global_position + Vector3(0, 1.2, 0), "SENSOR!", Color(0.5, 0.95, 1.0), 130)
	hud.set_sensors(sensors_found, 3)
	if sensors_found >= 3:
		score += SENSOR_BONUS
		audio.built(player.global_position)
		hud.toast("ALL SENSORS - +%s" % HUD._commas(SENSOR_BONUS), Color(0.5, 0.95, 1.0))
		comedy.pop(player.global_position + Vector3(0, 3.2, 0), "DOROTHY LIVES!",
			Color(1.0, 0.9, 0.3), 165)
		studfield.spawn_burst(player.global_position + Vector3(0, 1.5, 0), 24)
	else:
		hud.toast("SENSOR %d/3" % sensors_found, Color(0.5, 0.95, 1.0))


func _assemble_steps() -> void:
	_sp_built = true
	var h := 1.2
	for pos in _sp["steps"]:
		var st := SetPiece.step_block(pos, h)
		_add_structure(st)
		h += 1.2
	if _sp.has("marker") and is_instance_valid(_sp["marker"]):
		_sp["marker"].queue_free()
	_log_event("BUILD", "tower steps assembled")
	audio.built(_sp["build_pos"])
	comedy.built(_sp["build_pos"] + Vector3(0, 2.4, 0))
	hud.toast("STEPS BUILT", Color(0.5, 1.0, 0.6))


# The cow is on the roof. Nobody will explain this. When the barn goes, it
# lands, complains, and is completely fine - which is Law 1, told as a joke.
func _spawn_roof_cow(at: Vector3) -> void:
	if critter_root == null:
		critter_root = Node3D.new()
		critter_root.name = "Critters"
		add_child(critter_root)
	var cow := _make_cow()
	critter_root.add_child(cow)
	cow.global_position = at
	comedy.pop(at + Vector3(0, 1.6, 0), "?", Color(1, 1, 1), 110)


# [BS:ECONOMY:SENSOR_BALLS:END]


# ============================================================================
# [BS:COMEDY:GAGS]
# Purpose: The running jokes - flying livestock and the outhouse.
# Invariants:
# - Cows MOO when the funnel throws them and are otherwise untouched. They are
#   never harmed, never scored, never removed (North Star Law 1). The joke is
#   that they are completely fine.
# - The outhouse gag fires exactly once, and its occupant is a protected actor
#   like any other minifig.
# - Gags are cosmetic. Nothing here may change score, phase, or simulation.
# ============================================================================
func _update_gags() -> void:
	if critter_root != null:
		for c in critter_root.get_children():
			var cow := c as RigidBody3D
			if cow == null:
				continue
			var airborne := cow.global_position.y > 1.6
			var was: bool = _cow_air.get(cow.get_instance_id(), false)
			if airborne and not was and cow.linear_velocity.length() > 5.0:
				_log_event("GAG", "cow airborne")
				comedy.moo(cow.global_position + Vector3(0, 1.2, 0))
			_cow_air[cow.get_instance_id()] = airborne

	if outhouse != null and not _outhouse_popped and outhouse.is_rubble():
		_outhouse_popped = true
		_log_event("GAG", "outhouse occupant")
		_pop_the_outhouse()


# Somebody was in there. He is fine. He is not happy.
func _pop_the_outhouse() -> void:
	var fig := BrickLib.minifig(BrickLib.C_WHITE, BrickLib.C_BLUE, BrickLib.C_BROWN)
	add_child(fig)
	fig.global_position = outhouse.global_position + Vector3(0, 0.2, 0)
	fig.set_meta("protected", true)
	comedy.pop(outhouse.global_position + Vector3(0, 3.0, 0), "OCCUPIED!", Color(1.0, 0.85, 0.3), 150)

	var away := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	var tw := create_tween()
	tw.tween_property(fig, "global_position",
		fig.global_position + away * 14.0, 2.6).set_trans(Tween.TRANS_LINEAR)
	fig.rotation.y = atan2(away.x, away.z)
# [BS:COMEDY:GAGS:END]


# ============================================================================
# [BS:QA:PLAYTHROUGH]
# Purpose: Record a full round as a timestamped event log for cadence analysis.
# Invariants:
# - Records only what a PLAYER would perceive - a smash, a payout, a joke, a
#   phase change. Internal bookkeeping is not an event, because the question
#   this answers is "how often does something happen TO the player".
# - The autopilot is not a player. It never hesitates, never explores and never
#   gets bored, so the numbers here are an upper bound on event density and a
#   lower bound on dead time. Read them as such.
# - Diagnostic only. Nothing here may alter simulation, score, or phase.
# ============================================================================
func _log_event(kind: String, detail: String = "") -> void:
	if not playthrough:
		return
	_tel.append({"t": _elapsed, "kind": kind, "detail": detail})


func _tick_playthrough(delta: float) -> void:
	var fps := 1.0 / maxf(delta, 0.0001)
	_fps_min = minf(_fps_min, fps)
	_fps_sum += fps
	_fps_n += 1
	_peak_structures = maxi(_peak_structures, structures.size())
	_tel_shot += delta
	if _tel_shot >= 18.0 and _tel_shots < 8:
		_tel_shot = 0.0
		_tel_shots += 1
		_grab_plain("round_%d" % _tel_shots)
	if _elapsed >= PLAYTHROUGH_SECONDS:
		_dump_playthrough()


func _grab_plain(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(_capture_dir)
	img.save_png("%s/%s.png" % [_capture_dir, name])


func _dump_playthrough() -> void:
	var f := FileAccess.open("%s/playthrough.log" % _capture_dir, FileAccess.WRITE)
	for e in _tel:
		f.store_line("%8.2f  %-10s %s" % [e["t"], e["kind"], e["detail"]])
	f.store_line("---- summary ----")
	f.store_line("duration        %.1f s" % _elapsed)
	f.store_line("final score     %d" % score)
	f.store_line("bricks torn     %d" % _total_torn())
	f.store_line("phase reached   %d" % phase)
	f.store_line("true chaser     %s" % str(true_chaser_earned))
	f.store_line("corridor z      %.0f m travelled" % (tornado.funnel_pos().z + 24.0))
	f.store_line("live structures %d (peak %d)" % [structures.size(), _peak_structures])
	f.store_line("fps             avg %.0f  min %.0f" % [_fps_sum / maxf(float(_fps_n), 1.0), _fps_min])

	var counts: Dictionary = {}
	for e in _tel:
		counts[e["kind"]] = int(counts.get(e["kind"], 0)) + 1
	for k in counts:
		f.store_line("%-15s %d  (%.1f/min)" % [k, counts[k], float(counts[k]) / _elapsed * 60.0])

	# Dead time: the longest stretch with no player-facing feedback at all.
	var worst := 0.0
	var worst_at := 0.0
	var prev := 0.0
	for e in _tel:
		var gap: float = e["t"] - prev
		if gap > worst:
			worst = gap
			worst_at = prev
		prev = e["t"]
	f.store_line("longest silence %.1f s  (starting t=%.1f)" % [worst, worst_at])
	f.close()
	print("PLAYTHROUGH done: %d events over %.0fs" % [_tel.size(), _elapsed])
	get_tree().quit()
# [BS:QA:PLAYTHROUGH:END]


# ============================================================================
# [BS:QA:AUTOPILOT]
# Purpose: The demo driver used for capture runs.
# Invariants:
# - Not gameplay. It exists to make captures reproducible and must
#   never be reachable in a shipping build.
# - It only chases loot still near the funnel - stale studs behind the
#   storm are a trap that pulls the capture out of the bands.
# ============================================================================
# The autopilot smashes on a timer so captures show player destruction and the
# comic-book words, not just the funnel doing the work.
var _demo_smash_t: float = 0.0

func _demo_smash(delta: float) -> void:
	_demo_smash_t -= delta
	if _demo_smash_t > 0.0:
		return
	_demo_smash_t = 0.75
	if _nearest_structure(player.smash_radius() + 1.0) != null:
		_do_smash()


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
	if idx == _capture_at.size() - 1:
		_closeup = true
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
	if _closeup and name.begins_with("shot"):
		# Frame the minifig tight: the rig, the face and the walk cycle cannot
		# be judged from a gameplay camera and they are the whole identity.
		var focus := player.global_position
		hud.visible = false
		# The same gameplay frame, without the interface. Any measurement of
		# how the WORLD is lit or coloured has to be taken off a frame the HUD
		# is not sitting on: its white text, its two big flat buttons and the
		# thumb circles are a large fraction of the pixels, and they drag the
		# clipping and saturation figures on their own. Comparing that against
		# a demo frame would be comparing our HUD to their masonry.
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/world.png" % _capture_dir)
		_camera_locked = true
		# Freeze the player first: _physics_process re-aims the rig along its
		# movement every frame and would overwrite the pose set below.
		player.set_physics_process(false)
		player.velocity = Vector3.ZERO
		# Frame the HEAD, wherever it actually is. These offsets were tuned for
		# a figure 30% shorter and framed its chest once the proportions were
		# corrected.
		var head_n := player.find_child("Head", true, false) as Node3D
		var aim: Vector3 = head_n.global_position if head_n != null \
			else focus + Vector3(0, 1.9, 0)
		var eye := aim + Vector3(1.55, -0.45, 2.25)
		camera.global_position = eye
		camera.look_at(aim, Vector3.UP)
		# Turn the minifig to the lens and hold a mid-stride pose: a closeup of
		# the back of the head verifies nothing.
		var to_cam := eye - focus
		player._visual_root.rotation = Vector3(0, atan2(to_cam.x, to_cam.z), 0)
		player._animate_walk(0.0, player.speed() * 0.8)
		player._walk_phase = 1.2
		player._animate_walk(0.0, player.speed() * 0.8)
		await get_tree().process_frame
		# Re-assert after the tick: a physics frame can still interleave and
		# re-aim the rig along its last movement direction.
		player._visual_root.rotation = Vector3(0, atan2(to_cam.x, to_cam.z), 0)
		player._walk_phase = 1.2
		player._animate_walk(0.0, player.speed() * 0.8)
		await RenderingServer.frame_post_draw
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("%s/minifig.png" % _capture_dir)

		# Head-on at HEAD height, taken from the head itself. These were fixed
		# offsets tuned for a figure 30% shorter and framed its chest once the
		# proportions were corrected.
		var hp: Vector3 = head_n.global_position if head_n != null \
			else focus + Vector3(0, 2.35, 0)
		camera.global_position = hp + Vector3(0, 0.02, 1.45)
		camera.look_at(hp, Vector3.UP)
		player._visual_root.rotation = Vector3.ZERO
		await get_tree().process_frame
		player._visual_root.rotation = Vector3.ZERO
		await RenderingServer.frame_post_draw
		var img3 := get_viewport().get_texture().get_image()
		img3.save_png("%s/minifig_face.png" % _capture_dir)
		# An overview of the authored yard, so its COMPOSITION can be judged
		# against the procedural blocks - which is the whole point of it.
		var o: Vector3 = _sp["origin"]
		tornado.global_position = Vector3(0, 0, -900)
		player.global_position = o + Vector3(0, 0.2, -6)
		camera.global_position = o + Vector3(-1, 26, -30)
		camera.look_at(o + Vector3(0, 1, 8), Vector3.UP)
		await get_tree().process_frame
		camera.global_position = o + Vector3(-1, 26, -30)
		camera.look_at(o + Vector3(0, 1, 8), Vector3.UP)
		await RenderingServer.frame_post_draw
		var img4 := get_viewport().get_texture().get_image()
		img4.save_png("%s/setpiece.png" % _capture_dir)
		print("CAPTURED minifig closeup + face + setpiece")
		get_tree().quit()
		return
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

# Lets the self-test name a prop. GDScript has no way to call a static
# function by name, and a match here is better than a second registry that
# can quietly fall out of step with PropBuilder.
func _prop_by_name(n: String) -> Structure:
	match n:
		"barn": return PropBuilder.barn(Vector3.ZERO)
		"farmhouse": return PropBuilder.farmhouse(Vector3.ZERO)
		"silo": return PropBuilder.silo(Vector3.ZERO)
		"water_tower": return PropBuilder.water_tower(Vector3.ZERO)
		"tree": return PropBuilder.tree(Vector3.ZERO, 1.0)
		"fence": return PropBuilder.fence_run(Vector3(-4, 0, 0), Vector3(4, 0, 0))
		"pickup": return PropBuilder.pickup(Vector3.ZERO, BrickLib.C_BLUE, 0.0)
		"drive_in": return PropBuilder.drive_in_screen(Vector3.ZERO, 0.0)
		"windmill": return PropBuilder.windmill(Vector3.ZERO)
		"power_line": return PropBuilder.power_line(Vector3(-20, 0, 0), Vector3(20, 0, 0))
		"grain_elevator": return PropBuilder.grain_elevator(Vector3.ZERO, 0.0)
		"outhouse": return PropBuilder.outhouse(Vector3.ZERO)
	return null

func _run_selftest() -> void:
	await get_tree().process_frame
	var fails: Array[String] = []
	_force_input = true

	# --- 1. driving and ramming ------------------------------------------
	# A dedicated target well outside the corridor, so this tests the RAM
	# mechanic rather than whatever the world generator happened to place.
	var ram_target := PropBuilder.barn(Vector3(300, 0, 0))
	_add_structure(ram_target)
	var truck: Vehicle = vehicles[0]
	truck.global_position = Vector3(300, 0.4, -24)
	truck.heading = 0.0
	player.global_position = truck.global_position
	_enter_vehicle()
	if driving == null:
		fails.append("could not board a vehicle")
	var drive_from := truck.global_position
	var torn_before_ram := _total_torn()
	_forced_input = Vector2(0, 1)          # straight at the barn
	for i in range(260):
		await get_tree().physics_frame
	var drove := truck.global_position.distance_to(drive_from)
	var ram_torn := _total_torn() - torn_before_ram
	if drove < 8.0:
		fails.append("truck moved only %.1fm under full throttle" % drove)
	if ram_torn <= 0:
		fails.append("ramming a barn tore nothing")
	_forced_input = Vector2.ZERO
	_exit_vehicle()
	if driving != null:
		fails.append("could not leave the vehicle")

	# --- 2. player smash --------------------------------------------------
	await get_tree().physics_frame
	var smash_target := PropBuilder.silo(Vector3(340, 0, 0))
	_add_structure(smash_target)
	player.global_position = Vector3(340, 0.4, -2.2)  # beside a dedicated silo
	await get_tree().physics_frame
	var torn_before_smash := _total_torn()
	for i in range(6):
		_do_smash()
		await get_tree().physics_frame
	var smash_torn := _total_torn() - torn_before_smash
	if smash_torn <= 0:
		fails.append("player SMASH tore nothing")

	# --- 3. jump ----------------------------------------------------------
	# Park the funnel well away first: a lingering tumble from the smash test
	# would refuse the jump and make this assert order-dependent.
	tornado.global_position = Vector3(0, 0, -400)
	player.tumble_timer = 0.0
	player.global_position = Vector3(0, 0.2, 12)
	for i in range(20):
		await get_tree().physics_frame
	var y0 := player.global_position.y
	var grounded := player.is_on_floor()
	if not grounded:
		fails.append("player never settled on the ground before the jump test")
	player.jump()
	for i in range(8):
		await get_tree().physics_frame
	if player.global_position.y <= y0 + 0.3:
		fails.append("JUMP did not leave the ground")

	# --- 3b. movement must be CAMERA-relative -----------------------------
	# The bug this exists for: the camera orbits, but movement used raw world
	# axes, so pushing the stick "up" sent the player somewhere unrelated to
	# where the thumb pushed. Reported from device as "movement is terrible".
	_camera_locked = true
	var was_demo := demo_mode
	demo_mode = false
	_force_input = false
	player.global_position = Vector3(0, 0.2, 12)
	await get_tree().physics_frame

	camera.global_position = player.global_position + Vector3(0, 6, 12)
	camera.look_at(player.global_position + Vector3(0, 1, 0), Vector3.UP)
	hud.stick.value = Vector2(0, -1)                 # thumb pushed up-screen
	_read_input()
	var dir_a := Vector3(player.move_input.x, 0, player.move_input.y).normalized()
	var away := player.global_position - camera.global_position
	away.y = 0.0
	if dir_a.dot(away.normalized()) < 0.9:
		fails.append("stick up does not move away from the camera - movement is not camera-relative")

	camera.global_position = player.global_position + Vector3(0, 6, -12)
	camera.look_at(player.global_position + Vector3(0, 1, 0), Vector3.UP)
	_read_input()
	var dir_b := Vector3(player.move_input.x, 0, player.move_input.y).normalized()
	if dir_a.dot(dir_b) > -0.5:
		fails.append("world direction did not follow the camera when it orbited")

	hud.stick.value = Vector2.ZERO
	demo_mode = was_demo
	_camera_locked = false

	# --- 4. the funnel, the economy --------------------------------------
	tornado.global_position = Vector3(16, 0, -18)
	player.global_position = Vector3(25, 0.2, -18)
	_force_input = false
	for i in range(700):
		await get_tree().physics_frame

	# --- 4b. the authored set piece: gate, then collectibles --------------
	player.tumble_timer = 0.0
	player.invuln_timer = 0.0
	var gate: Structure = _sp["gate"]

	# The storm must NOT solve the gate. Default strength is what the funnel
	# and a vehicle ram both use.
	if gate.tear(gate.global_position, 12.0, debris_root, 10).size() > 0:
		fails.append("default-strength tearing shifted the heavy gate - the storm solves it")

	player.set_character(Player.Character.JO)
	player.global_position = gate.global_position + Vector3(0.0, 0.4, -2.2)
	await get_tree().process_frame
	await get_tree().physics_frame
	var gate_before := gate.torn_count
	for i in range(5):
		_do_smash()
		await get_tree().physics_frame
	if gate.torn_count != gate_before:
		fails.append("Jo shifted the heavy gate - the ability gate does nothing")

	player.set_character(Player.Character.BILL)
	for i in range(5):
		_do_smash()
		await get_tree().physics_frame
	if gate.torn_count <= gate_before:
		fails.append("Bill could not shift the heavy gate")
	player.set_character(Player.Character.JO)

	var score_pre_sensors := score
	for i in range(_sp_balls.size()):
		var nb = _sp_balls[i]
		if nb != null and is_instance_valid(nb):
			player.global_position = nb.global_position - Vector3(0, 0.9, 0)
			await get_tree().process_frame
			await get_tree().process_frame
	if sensors_found < 3:
		fails.append("sensor balls not collectable (%d/3)" % sensors_found)
	elif score - score_pre_sensors < SENSOR_BONUS:
		fails.append("collecting all sensors did not pay the bonus")

	# --- 5. every declared sound must exist and be a real stream ----------
	var missing: Array[String] = []
	var sounds := 0
	# Check the SOURCE file on disk as well as the loaded stream. load() alone
	# resolves out of .godot/imported/, so a deleted .ogg still "loads" from a
	# stale cache and the assert silently cannot fail. Found the hard way.
	for ev in GameAudio.BANK:
		for n in GameAudio.BANK[ev]:
			sounds += 1
			var st: AudioStream = audio.stream_for(n)
			if not FileAccess.file_exists(GameAudio.DIR + n + ".ogg"):
				missing.append("%s/%s (source file absent)" % [ev, n])
			elif st == null or st.get_length() <= 0.0:
				missing.append("%s/%s (stream empty)" % [ev, n])
	for k in GameAudio.LOOPS:
		sounds += 1
		var ln: String = GameAudio.LOOPS[k]
		var st2: AudioStream = audio.stream_for(ln, true)
		if not FileAccess.file_exists(GameAudio.DIR + ln + ".ogg"):
			missing.append("loop/%s (source file absent)" % k)
		elif st2 == null or st2.get_length() <= 0.0:
			missing.append("loop/%s (stream empty)" % k)
	if not missing.is_empty():
		fails.append("audio assets missing or empty: %s" % ", ".join(missing))

	# --- 4b. every part is a closed, correctly-wound, unit-sized solid ----
	# A backwards face means you see straight through the part and out its far
	# side. This has gone wrong twice by hand-tracking - 16 of the brick's 44
	# triangles, then the whole head from one sign flip - and a third time in a
	# way nothing here caught: the convention ITSELF was backwards. Godot's
	# front face is CLOCKWISE seen from the front, so the geometric cross
	# product must point AGAINST the outward normal. This test used to assert
	# the opposite, which is why it passed for weeks while the camera was
	# looking at the far surface of every brick in the game. The convention is
	# proven against the renderer, not asserted, by tools/winding_probe.gd.
	# Checked for EVERY part, because the library is now eight of them.
	for pk in range(BrickLib.PART_COUNT):
		var pm := BrickLib.part_mesh(pk)
		var pname := BrickLib.part_name(pk)
		if pm == null:
			fails.append("part '%s' has no mesh" % pname)
			continue
		var arrs: Array = pm.surface_get_arrays(0)
		var bverts: PackedVector3Array = arrs[Mesh.ARRAY_VERTEX]
		var bnorms: PackedVector3Array = arrs[Mesh.ARRAY_NORMAL]
		var wrong := 0
		var edge_use: Dictionary = {}
		var lo := Vector3(1e9, 1e9, 1e9)
		var hi := Vector3(-1e9, -1e9, -1e9)
		for ti in range(bverts.size() / 3):
			var va := bverts[ti * 3]
			var vb := bverts[ti * 3 + 1]
			var vc := bverts[ti * 3 + 2]
			var geo := (vb - va).cross(vc - va)
			# Averaged, because a smooth part carries a different normal at
			# each corner and any single one of them can lean past the face.
			var fn := (bnorms[ti * 3] + bnorms[ti * 3 + 1] + bnorms[ti * 3 + 2]).normalized()
			if geo.length() < 1e-9 or geo.normalized().dot(fn) > 0.0:
				wrong += 1
			for ei in range(3):
				var e0 := bverts[ti * 3 + ei]
				var e1 := bverts[ti * 3 + (ei + 1) % 3]
				# Snap and add zero before formatting. cos() at a right angle
				# returns -1.8e-16, which prints as "-0.0000" while the same
				# corner reached from another triangle prints "0.0000" - two
				# keys for one edge, and every round part reported as an open
				# shell. That was the TEST being wrong about closed meshes, and
				# it is exactly the class of instrument error this project has
				# already been caught by three times. Adding 0.0 collapses
				# negative zero onto zero.
				var key := "%.4f,%.4f,%.4f|%.4f,%.4f,%.4f" % [
					snappedf(minf(e0.x, e1.x), 0.0001) + 0.0,
					snappedf(minf(e0.y, e1.y), 0.0001) + 0.0,
					snappedf(minf(e0.z, e1.z), 0.0001) + 0.0,
					snappedf(maxf(e0.x, e1.x), 0.0001) + 0.0,
					snappedf(maxf(e0.y, e1.y), 0.0001) + 0.0,
					snappedf(maxf(e0.z, e1.z), 0.0001) + 0.0]
				edge_use[key] = int(edge_use.get(key, 0)) + 1
			for v in [va, vb, vc]:
				lo = Vector3(minf(lo.x, v.x), minf(lo.y, v.y), minf(lo.z, v.z))
				hi = Vector3(maxf(hi.x, v.x), maxf(hi.y, v.y), maxf(hi.z, v.z))
		if wrong != 0:
			fails.append("%d '%s' triangles face inwards - you see through the part"
				% [wrong, pname])
		for k in edge_use:
			if int(edge_use[k]) != 2:
				fails.append("the '%s' mesh is not a closed solid" % pname)
				break
		# Every part is scaled per instance from the unit cube. One that
		# overflows it reaches into the brick next door on every placement.
		if lo.x < -0.501 or lo.y < -0.501 or lo.z < -0.501 \
				or hi.x > 0.501 or hi.y > 0.501 or hi.z > 0.501:
			fails.append("the '%s' mesh spills outside the unit cube" % pname)
		if bverts.size() / 3 < 30:
			fails.append("'%s' has only %d triangles - it is not chamfered"
				% [pname, bverts.size() / 3])

	# --- 4b2. parts, studs and the batcher agree --------------------------
	# The stud table and the batcher are two halves of one thing: Structure
	# allocates the stud MultiMesh from part_stud_slots and then places into it
	# from part_stud_slots, so if those ever disagree the studs of one part
	# overwrite another's and the last few land at the origin.
	for pk in range(BrickLib.PART_COUNT):
		for sz in [[1, 1], [2, 2], [6, 2], [4, 1]]:
			var slots: Array = BrickLib.part_stud_slots(pk, sz[0], sz[1])
			var want: int = sz[0] * sz[1]
			match pk:
				BrickLib.PART_TILE, BrickLib.PART_CHEESE:
					want = 0                      # smooth parts, by definition
				BrickLib.PART_ROUND, BrickLib.PART_CONE:
					want = 1                      # one stud in the middle
				BrickLib.PART_SLOPE:
					want = sz[0]                  # one row, on the ledge
			if slots.size() != want:
				fails.append("'%s' %dx%d offers %d stud slots, expected %d"
					% [BrickLib.part_name(pk), sz[0], sz[1], slots.size(), want])
			for u in slots:
				if absf(u.x) > 0.5 or absf(u.z) > 0.5 or absf(u.y - 0.5) > 1e-5:
					fails.append("'%s' puts a stud slot off the top face at %s"
						% [BrickLib.part_name(pk), str(u)])

	# One MultiMesh per kind, and every stud the parts ask for actually placed.
	var probe := Structure.new()
	var expect_studs := 0
	for pk in range(BrickLib.PART_COUNT):
		probe.add_part(pk, 2, 2, BrickLib.BRICK_H, BrickLib.C_RED,
			Vector3(float(pk) * 1.2, 0.3, 0.0))
		expect_studs += BrickLib.part_stud_slots(pk, 2, 2).size()
	probe.finish()
	var kinds_batched := 0
	var studs_placed := -1
	for ch in probe.get_children():
		if ch is MultiMeshInstance3D:
			var mm: MultiMesh = (ch as MultiMeshInstance3D).multimesh
			if mm.mesh == BrickLib.stud_mesh():
				studs_placed = mm.instance_count
			else:
				kinds_batched += 1
				if mm.instance_count != 1:
					fails.append("a part kind batched %d instances, expected 1"
						% mm.instance_count)
	if kinds_batched != BrickLib.PART_COUNT:
		fails.append("Structure batched %d part kinds of %d - a kind is being dropped"
			% [kinds_batched, BrickLib.PART_COUNT])
	if studs_placed != expect_studs:
		fails.append("Structure placed %d studs but the parts ask for %d"
			% [studs_placed, expect_studs])
	probe.free()

	# Tearing part 3 must blank PART 3. With mixed kinds the entry index and
	# the instance slot inside that kind's MultiMesh are different numbers, and
	# confusing them tears the wrong brick - which is invisible in play,
	# because something does vanish and it is roughly where you hit.
	#
	# This checks the BOOKKEEPING, not the rendered result, and that is
	# deliberate. The first version of this test called _hide_instance and read
	# the instance transform back off the MultiMesh - and every instance came
	# back as identity, including ones that had just been written with a scale.
	# --selftest runs headless, where the dummy renderer does not keep the
	# per-instance buffer, so a read-back test here can only ever pass. The
	# rendered version of this test lives in tools/part_probe.gd, which runs
	# with a real renderer. What is checkable here is the invariant that
	# _hide_instance and tear() actually index with: within each kind the slots
	# must be exactly 0..n-1, no repeats, none out of range. A repeated slot is
	# precisely what blanks the wrong brick.
	var mixed := Structure.new()
	for i in range(6):
		mixed.add_part(BrickLib.PART_BRICK if i % 2 == 0 else BrickLib.PART_SLOPE,
			2, 2, BrickLib.BRICK_H, BrickLib.C_BLUE, Vector3(float(i) * 1.2, 0.3, 0.0))
	mixed.finish()
	var per_kind: Dictionary = {}
	for me in mixed.entries:
		var mk: int = me["kind"]
		if not per_kind.has(mk):
			per_kind[mk] = []
		per_kind[mk].append(int(me["slot"]))
	for mk in per_kind:
		var got: Array = per_kind[mk]
		got.sort()
		var want_slots: Array = []
		for j in range(got.size()):
			want_slots.append(j)
		if got != want_slots:
			fails.append("'%s' batch slots are %s, expected %s - tearing one part"
				% [BrickLib.part_name(mk), str(got), str(want_slots)]
				+ " would blank another")
		var mmi: MultiMeshInstance3D = mixed._part_mmi.get(mk, null)
		if mmi == null:
			fails.append("'%s' was added but never batched" % BrickLib.part_name(mk))
		elif mmi.multimesh.instance_count != got.size():
			fails.append("'%s' batched %d instances for %d parts"
				% [BrickLib.part_name(mk), mmi.multimesh.instance_count, got.size()])
	mixed.free()

	# --- 4b3. the props are built from real parts -------------------------
	# The note on the last build was "just a game with mega blocks in it", and
	# the cause was that every prop in the town was assembled from one shape.
	# This asserts the parts that answer it are actually in use: a roof made of
	# slopes, round things made round, smooth surfaces tiled. It cannot judge
	# whether a prop looks good - that is what Docs/shots is for - but it can
	# tell you the day a roof goes back to being a box on a hand-picked angle.
	var expect_kinds := {
		"barn": [BrickLib.PART_SLOPE, BrickLib.PART_TILE, BrickLib.PART_ARCH],
		"farmhouse": [BrickLib.PART_SLOPE, BrickLib.PART_SLOPE_INV,
			BrickLib.PART_TILE, BrickLib.PART_ROUND, BrickLib.PART_CHEESE],
		"silo": [BrickLib.PART_ROUND, BrickLib.PART_CONE],
		"water_tower": [BrickLib.PART_ROUND, BrickLib.PART_CONE, BrickLib.PART_TILE],
		"tree": [BrickLib.PART_ROUND, BrickLib.PART_CONE],
		# Barbed wire on round posts, not pointed pickets - see BS:BUILD:PLAINS.
		"fence": [BrickLib.PART_ROUND, BrickLib.PART_TILE],
		"power_line": [BrickLib.PART_ROUND, BrickLib.PART_TILE],
		"grain_elevator": [BrickLib.PART_ROUND, BrickLib.PART_TILE],
		"pickup": [BrickLib.PART_SLOPE, BrickLib.PART_TILE, BrickLib.PART_ROUND],
		"drive_in": [BrickLib.PART_TILE],
		# A lattice aermotor: round legs, tile bracing and blades. No cone -
		# that was the Dutch mill this replaced.
		"windmill": [BrickLib.PART_ROUND, BrickLib.PART_TILE],
		"outhouse": [BrickLib.PART_SLOPE],
	}
	for prop_name in expect_kinds:
		var ps := _prop_by_name(prop_name)
		if ps == null:
			fails.append("selftest asks about a prop '%s' that does not exist" % prop_name)
			continue
		var used: Dictionary = {}
		for e in ps.entries:
			used[e["kind"]] = true
		for want_kind in expect_kinds[prop_name]:
			if not used.has(want_kind):
				fails.append("prop '%s' uses no %s - it has gone back to boxes"
					% [prop_name, BrickLib.part_name(want_kind)])
		# Part variety costs a draw call per kind per prop. Five is generous;
		# more than that and a corridor of these props starts costing what the
		# batching was introduced to save. See BS:DESTRUCTION:STRUCTURE.
		# Part variety costs a draw call per kind per prop. Six is the ceiling,
		# and it is meant to be uncomfortable: the farmhouse is at it, and it
		# is a hero building that appears twice in a corridor. Anything the
		# scatter places by the dozen - trees, furniture - should be nearer
		# three. See BS:DESTRUCTION:STRUCTURE.
		if used.size() > 6:
			fails.append("prop '%s' uses %d part kinds - that is %d draw calls per"
				% [prop_name, used.size(), used.size() + 1] + " instance")
		ps.free()

	# --- 4b4. the stud stream has denominations, and finishing pays -------
	# Every payout in this game used to be ten times the band multiplier, so a
	# 200-second round logged ~370 near-identical events and the stud stream had
	# no texture at all. These check the two halves of the fix: that a
	# denomination survives from spawn to collection, and that the finish bonus
	# lands exactly once per structure however it was finished.
	#
	# ON A THROWAWAY FIELD, NOT THE LIVE ONE. The first version of this gate
	# spawned test studs into the running game's StudField and then called
	# clear_all(), which wiped the player's uncollected loot mid-round - the
	# summary line went from 240 studs to 53 and still said OK. That is the
	# same mistake as the re-homing check that once emptied the live town, and
	# it is recorded in Docs/DECISION_LOG.md for the same reason: a test that
	# damages the thing it is measuring can pass while breaking the game.
	var live_field := studfield
	var probe_field := StudField.new()
	add_child(probe_field)
	studfield = probe_field
	for denom in [StudField.VALUE_SILVER, StudField.VALUE_GOLD, StudField.VALUE_BLUE]:
		probe_field.spawn_burst(Vector3(600, 0.5, 0), 1, denom)
		var made: Dictionary = probe_field.studs[probe_field.studs.size() - 1]
		if int(made.get("denom", -1)) != denom:
			fails.append("a %d stud came back carrying denom %s - the value is"
				% [denom, str(made.get("denom", "none"))] + " lost before collection")
		# A jackpot the player cannot pick out of a field of silver is not a
		# jackpot, so size and colour have to differ too.
		if denom > StudField.VALUE_SILVER:
			if StudField.denom_scale(denom) <= StudField.denom_scale(StudField.VALUE_SILVER):
				fails.append("a %d stud is not bigger than a silver one" % denom)
			if StudField.denom_colour(denom).is_equal_approx(
					StudField.denom_colour(StudField.VALUE_SILVER)):
				fails.append("a %d stud is the same colour as a silver one" % denom)
	probe_field.clear_all()

	# The finish bonus: once per structure, and only once it is actually rubble.
	# The structure is parented directly rather than through _add_structure, so
	# it never joins the live corridor.
	# A 30m fence run is about 50 parts, so it clears FINISH_MIN_PARTS but not
	# BIG_STRUCTURE - the gold case. It was an 8m run, which fell under the
	# floor the moment the fence was rebuilt as barbed wire with fewer, wider
	# spaced posts, and the gate correctly said the bonus never paid.
	var fin := PropBuilder.fence_run(Vector3(620, 0, 0), Vector3(650, 0, 0))
	add_child(fin)
	_pay_finish(fin)
	if not probe_field.studs.is_empty():
		fails.append("the finish bonus paid on an intact structure")
	probe_field.clear_all()
	# The radius has to cover the WHOLE prop. At 6m it reached the first few
	# metres of a 30m fence, ran out of bricks in range, and left the structure
	# standing - so the bonus correctly never paid and the gate correctly said
	# so. That was the test being too small, not the code being wrong.
	while not fin.is_rubble():
		if fin.tear(fin.global_position + Vector3(0, 0.6, 0), 60.0, debris_root, 40).is_empty():
			break
	_pay_finish(fin)
	var after_first := probe_field.studs.size()
	_pay_finish(fin)
	_pay_finish(fin)
	if after_first != 1:
		fails.append("finishing a structure paid %d studs, expected 1" % after_first)
	elif probe_field.studs.size() != 1:
		fails.append("the finish bonus paid %d times for one structure - the"
			% probe_field.studs.size() + " paid_finish latch is not holding")
	elif int((probe_field.studs[0] as Dictionary).get("denom", 0)) != StudField.VALUE_GOLD:
		fails.append("a mid-sized structure paid %s instead of gold"
			% str((probe_field.studs[0] as Dictionary).get("denom", 0)))
	probe_field.clear_all()

	# And scenery below the floor pays nothing extra at all, or the jackpot is
	# not a jackpot - this is what 92 finishes a round looked like.
	var small := PropBuilder.bin(Vector3(640, 0, 0))
	add_child(small)
	while not small.is_rubble():
		if small.tear(small.global_position + Vector3(0, 0.5, 0), 6.0, debris_root, 40).is_empty():
			break
	_pay_finish(small)
	if not probe_field.studs.is_empty():
		fails.append("a %d-part prop paid a finish bonus; the floor is %d parts"
			% [small.entries.size(), FINISH_MIN_PARTS])
	probe_field.clear_all()
	small.queue_free()
	studfield = live_field
	fin.queue_free()
	probe_field.queue_free()

	# A brick the player knocked loose has to pay sooner than one the funnel
	# threw, or the reward does not belong to the hit that caused it. The
	# behavioural half of this is visible in --playthrough's STUD timings; what
	# is checkable here is that the two lifetimes have not been equalised.
	if PLAYER_BRICK_LIFETIME >= BRICK_LIFETIME:
		fails.append("player debris lives %.2fs against the funnel's %.2fs - the"
			% [PLAYER_BRICK_LIFETIME, BRICK_LIFETIME]
			+ " smash no longer pays before the storm does")

	# --- 4c. one definition of plastic, and ambient from the sky ----------
	# Structure's MultiMesh batch material is what every building in the game
	# actually draws through; BrickLib.mat() covers the minifig and loose
	# debris. They used to hand-copy the same numbers, so adding a fresnel term
	# to one changed the minifig and left every building untouched - and the
	# screenshots looked "a bit brighter" instead of different. This asserts
	# they cannot drift apart again.
	# Both paths are checked against the CONSTANTS, not against each other, so
	# neither can drag the other along when it drifts.
	var ref_mat := BrickLib.mat(BrickLib.C_RED)
	var batch := Structure._material()
	var pairs := [
		["roughness", "p_roughness", BrickLib.PLASTIC_ROUGHNESS],
		["metallic", "p_metallic", BrickLib.PLASTIC_METALLIC],
		["metallic_specular", "p_specular", BrickLib.PLASTIC_SPECULAR],
		["rim", "p_rim", BrickLib.PLASTIC_RIM],
		["rim_tint", "p_rim_tint", BrickLib.PLASTIC_RIM_TINT],
	]
	for pr in pairs:
		if not is_equal_approx(float(ref_mat.get(pr[0])), float(pr[2])):
			fails.append("BrickLib material %s=%s, constant says %s"
				% [pr[0], ref_mat.get(pr[0]), pr[2]])
		var got: Variant = batch.get_shader_parameter(pr[1])
		if got == null or not is_equal_approx(float(got), float(pr[2])):
			fails.append("brick shader %s=%s, constant says %s" % [pr[1], got, pr[2]])
	if not ref_mat.rim_enabled:
		fails.append("bricks have no fresnel term - they will read as cardboard")

	# The shader's storm must be the SAME storm the physics uses. If these
	# diverge the foliage leans one way while the player is pushed another.
	for wp in [["storm_tangent", Tornado.WIND_TANGENT],
			["storm_inward", Tornado.WIND_INWARD],
			["storm_peak", Tornado.WIND_PEAK]]:
		var gw: Variant = batch.get_shader_parameter(wp[0])
		if gw == null or not is_equal_approx(float(gw), float(wp[1])):
			fails.append("shader %s=%s but Tornado says %s" % [wp[0], gw, wp[1]])

	# And the shader must be looking at where the storm actually is.
	Structure.set_storm(tornado.funnel_pos(), tornado.wind_reach())
	var sp: Variant = batch.get_shader_parameter("storm_pos")
	if sp == null or (sp as Vector3).distance_to(tornado.funnel_pos()) > 0.01:
		fails.append("the shader's storm is not where the storm is")

	# Foliage bends; buildings do not.
	var probe_tree := PropBuilder.tree(Vector3(0, 0, 0), 1.0)
	var probe_barn := PropBuilder.barn(Vector3(0, 0, 0))
	var tip := 0.0
	for e in probe_tree.entries:
		tip = maxf(tip, float(e.get("bend", 0.0)))
	if tip < 0.5:
		fails.append("tree canopy has no bend weight - it cannot move in the wind")
	if float(probe_tree.entries[0].get("bend", 0.0)) != 0.0:
		fails.append("the tree trunk carries bend - its base will slide along the ground")
	for e in probe_barn.entries:
		if float(e.get("bend", 0.0)) != 0.0:
			fails.append("a building carries bend weight - barns do not sway")
			break
	probe_tree.queue_free()
	probe_barn.queue_free()
	if BrickLib.terrain_mat(BrickLib.C_GREEN).rim_enabled:
		fails.append("the ground has a grazing-angle response - it is not plastic")

	var envr := get_viewport().find_world_3d().environment
	if envr == null:
		var wenv := get_tree().get_first_node_in_group("worldenv")
		envr = (wenv as WorldEnvironment).environment if wenv != null else null
	if envr != null and envr.ambient_light_source != Environment.AMBIENT_SOURCE_SKY:
		fails.append("ambient is a flat colour, not the sky - every face lights the same")

	# --- 5a. the sub-area is one unit, shared -----------------------------
	# Streaming, camera framing and the ambience bed now key off the same
	# division of the world. These check that the division is sound and that
	# each of the three actually reads it.
	if not areamap.is_contiguous():
		fails.append("sub-areas do not tile the corridor (gap or overlap)")
	if areamap.areas.size() < 3:
		fails.append("corridor has only %d sub-areas" % areamap.areas.size())
	if _authored_populated != 0:
		fails.append("authored ground was procedurally populated %d times"
			% _authored_populated)
	if _sp_area == null or _sp_area.kind != SubArea.Kind.AUTHORED:
		fails.append("the set piece did not reserve an authored sub-area")

	# Camera: the hint applies inside the authored area and nowhere else.
	var f_in := areamap.framing_at(SET_PIECE_Z)
	var f_out := areamap.framing_at(SET_PIECE_Z + 400.0)
	if f_in.x <= 0.0 or f_in.y <= 0.0:
		fails.append("authored area applies no camera framing hint")
	if f_out.x != 0.0 or f_out.y != 0.0:
		fails.append("a framing hint leaked far outside its area")

	# Ownership is total, and a thrown structure outlives its birth area.
	var owned := 0
	for a in areamap.areas:
		owned += a.structures.size()
	if owned <= 0:
		fails.append("no structure is owned by any sub-area")

	# DENSITY IS THE PROMISE. The streamer exists so the corridor is never
	# bare - "in a LEGO game you are never more than a couple of paces from
	# something that breaks". Nothing asserted this until a broken test quietly
	# deleted the town and the run still reported OK, with `torn` down from 290
	# to 70. A count is the cheapest possible guard on the whole system.
	var live := 0
	for st4 in structures:
		if is_instance_valid(st4) and not st4.is_queued_for_deletion():
			live += 1
	if live < 60:
		fails.append("corridor holds only %d live structures - the world is bare" % live)
	# Re-homing is tested on a THROWAWAY map. Driving it on the live one
	# retires the starting area and deletes the town, which is exactly what the
	# first version of this check did - it dropped `torn` from 290 to 70 and
	# still reported OK, because nothing asserted on the town surviving.
	var probe_map := AreaMap.new()
	probe_map.depth = 20.0
	probe_map.ensure_ahead(60.0, func(_a: SubArea) -> void: pass)
	var stay := Node3D.new()
	var go := Node3D.new()
	add_child(stay)
	add_child(go)
	stay.global_position = Vector3(0, 0, 5.0)    # born in area 0, stays there
	go.global_position = Vector3(0, 0, 5.0)
	probe_map.adopt(stay)
	probe_map.adopt(go)
	go.global_position = Vector3(0, 0, 45.0)     # thrown two areas ahead
	var freed := probe_map.retire_behind(21.0)
	if freed.has(go):
		fails.append("a structure thrown ahead was freed with its birth area")
	if not freed.has(stay):
		fails.append("a structure left behind was not reclaimed with its area")
	var rehomed := probe_map.area_at(45.0)
	if rehomed == null or not rehomed.structures.has(go):
		fails.append("a thrown structure was not re-homed to the area it is in")
	stay.queue_free()
	go.queue_free()

	# Audio: the bed ducks in ACTION rather than swelling.
	if AMB_DB[SubArea.Intensity.ACTION] >= AMB_DB[SubArea.Intensity.QUIET]:
		fails.append("the ambience bed does not duck when the storm arrives")

	# --- 5b. the mix rules, not just the assets --------------------------
	# Asset existence was never the thing that made the mix sound wrong. These
	# check the two rules that decide how it SOUNDS: what a cascade is allowed
	# to steal, and which sounds are placed in the world at all.
	var pv_flood: Array[int] = []
	for i in range(8):
		pv_flood.append(GameAudio.PRI_DEBRIS)
	if GameAudio.pick_victim(pv_flood, 0, GameAudio.PRI_REWARD) < 0:
		fails.append("a reward could not displace a pool full of debris")
	var pv_busy: Array[int] = []
	for i in range(8):
		pv_busy.append(GameAudio.PRI_CRITICAL)
	if GameAudio.pick_victim(pv_busy, 0, GameAudio.PRI_DEBRIS) >= 0:
		fails.append("debris displaced a pool full of critical sounds")
	if GameAudio.pick_victim(pv_busy, 0, GameAudio.PRI_CRITICAL) >= 0:
		fails.append("an equal-priority sound stole a voice instead of dropping")

	# Feedback about the player's own action must not go through a positional
	# voice - that is what made pickups vary with where the stud happened to be.
	audio.stop_all()
	var w0 := audio.world_plays
	var f0 := audio.flat_plays
	audio._stud_sounded = 0.0
	audio.stud(player.global_position)
	audio.built(player.global_position)
	audio.objective(player.global_position)
	if audio.flat_plays - f0 < 3:
		fails.append("player feedback did not take the flat pool (%d of 3)"
			% (audio.flat_plays - f0))
	if audio.world_plays - w0 != 0:
		fails.append("player feedback leaked into a positional voice")
	var w1 := audio.world_plays
	audio.smash(player.global_position, false)
	if audio.world_plays - w1 != 1:
		fails.append("a world smash did not take a positional voice")

	# --- 6. TT Games rules: threshold latches, tumble grants grace ---------
	var score_before := score
	score = TRUE_CHASER + 100
	_on_stud_collected(0, 0, player.global_position)
	if not true_chaser_earned:
		fails.append("TRUE CHASER did not latch on crossing the threshold")
	score = 0
	if not true_chaser_earned:
		fails.append("TRUE CHASER was lost when studs fell - thresholds must latch")
	score = score_before          # leave the economy assertion below meaningful

	player.invuln_timer = 0.0
	player.tumble_timer = 0.0
	player.tumble()
	for i in range(int(Player.TUMBLE_TIME * 61.0) + 6):
		await get_tree().physics_frame
	if player.invuln_timer <= 0.0:
		fails.append("no grace period after a tumble - player can be re-tumbled instantly")
	if not player.immune_to_lift():
		fails.append("grace period does not actually prevent being lifted")

	var torn := _total_torn()
	if torn < 10:
		fails.append("funnel tore only %d bricks" % torn)
	if studfield.studs.size() == 0 and score == 0:
		fails.append("destruction produced no studs")

	print("SELFTEST drove=%.1fm ram_torn=%d smash_torn=%d jump_from=%.2f torn=%d debris=%d studs=%d score=%d phase=%d sounds=%d" % [
		drove, ram_torn, smash_torn, y0, torn, debris.size(),
		studfield.studs.size(), score, phase, sounds])
	print("SELFTEST setpiece sensors=%d/3 gate_torn=%d" % [sensors_found, gate.torn_count])
	for f in fails:
		print("SELFTEST FAIL: %s" % f)
	print("SELFTEST OK" if fails.is_empty() else "SELFTEST FAILED")
	get_tree().quit(0 if fails.is_empty() else 1)
# [BS:QA:SELFTEST:END]


func _total_torn() -> int:
	var n := 0
	for s in structures:
		n += s.torn_count
	return n
