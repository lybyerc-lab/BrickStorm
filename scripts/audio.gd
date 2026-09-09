# The sound layer.
#
# Every asset here is CC0 and recorded in ATTRIBUTION.md. Nothing is synthesised
# and nothing is taken from a commercial game.
class_name GameAudio
extends Node3D

const DIR := "res://assets/audio/"
const POOL_SIZE := 18

# ============================================================================
# [BS:AUDIO:BANK]
# Purpose: The event vocabulary - which files answer which game event.
# Invariants:
# - Events are named after what HAPPENED, never after the file. Swapping a
#   sound must never require touching a caller.
# - Every entry must resolve to a real file; --selftest asserts it, so a typo
#   or a missing asset fails the build instead of silently playing nothing.
# - Multiple files per event where repetition would be noticed. A smash heard
#   two hundred times a session cannot be one sample.
# ============================================================================
const BANK := {
	"smash":       ["impactWood_light_000", "impactWood_medium_000", "impactWood_heavy_000"],
	"smash_heavy": ["impactPlate_heavy_000", "impactMining_000"],
	"ram":         ["impactMetal_heavy_000", "impactPunch_heavy_000"],
	"glass":       ["impactGlass_light_000"],
	"tumble":      ["impactSoft_heavy_000", "impactBell_heavy_000"],
	"stud":        ["click1"],
	"jump":        ["highUp"],
	"land":        ["lowDown"],
	"build":       ["jingles_STEEL00"],
	"objective":   ["jingles_HIT00"],
	"deploy":      ["powerUp1"],
	"reward":      ["pepSound1"],
}

const LOOPS := {
	"roar":   "noise_01",
	"wind":   "ambient_01",
	"engine": "machine_01",
	"rumble": "rolling",
}
# [BS:AUDIO:BANK:END]

const GLOBAL_POOL_SIZE := 6

# ============================================================================
# [BS:AUDIO:FLAT]
# Purpose: Two rules the shipped LEGO games follow and this mix did not.
# Invariants:
# - PRIORITY decides what survives a cascade. A barn coming apart fires more
#   impacts than there are voices; without priority the pool fills with debris
#   and the sound the player is WAITING for - the stud, the build, the
#   objective - is the one that gets stolen. Debris is the cheapest sound in
#   the game and must lose every contest.
# - A voice is never stolen by something LESS important than what it is
#   already playing. `_voice()` returns null instead, and the caller drops
#   the sound. A dropped smash is invisible; a dropped reward is not.
# - FEEDBACK ABOUT THE PLAYER'S OWN ACTION IS NOT POSITIONAL. Studs, builds,
#   objectives and deploys play at a fixed level through `play_flat`. They
#   answer "did that work?", and that answer must not get quieter because the
#   stud happened to be magnetised from twenty metres away. World events -
#   smashes, rams, tumbles, engines - stay 3D, because where they happened is
#   the information they carry.
# - Volume randomisation only ever SUBTRACTS. The authored level is the
#   ceiling, never a midpoint, so variation can soften a repeat but can never
#   spike one above the level the mix was balanced at.
# ============================================================================
# The ladder is ordered by how much the player LOSES if the sound is dropped.
# Studs are deliberately below builds: a stud shower fires dozens of voices and
# must never be able to swallow the one build that shower was paying for.
const PRI_MIN := -128
const PRI_DEBRIS := -32     # smash, tumble, glass - the cheapest sounds
const PRI_WORLD := 0        # rams, jumps, landings
const PRI_STUD := 32        # stud pickups - many, individually cheap
const PRI_REWARD := 64      # builds and deploys - rare, and the point of it all
const PRI_CRITICAL := 96    # objectives - never dropped
# [BS:AUDIO:FLAT:END]

var _cache: Dictionary = {}
var _pool: Array[AudioStreamPlayer3D] = []
var _next: int = 0
var _pri: Array[int] = []
var _flat: Array[AudioStreamPlayer] = []
var _flat_next: int = 0
var _flat_pri: Array[int] = []

# Routing counters. --selftest asserts on these; they are the only way to see,
# from outside, which pool a sound actually took.
var world_plays: int = 0
var flat_plays: int = 0
var dropped: int = 0

var _stud_streak: int = 0
var _stud_last: float = 0.0
var _stud_sounded: float = 0.0


func _ready() -> void:
	_setup_buses()
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer3D.new()
		p.max_distance = 90.0
		p.unit_size = 14.0
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
		_pri.append(PRI_MIN)
	for i in range(GLOBAL_POOL_SIZE):
		var g := AudioStreamPlayer.new()
		g.bus = "SFX"
		add_child(g)
		_flat.append(g)
		_flat_pri.append(PRI_MIN)


# ============================================================================
# [BS:AUDIO:MIX]
# Purpose: Bus layout and the master limiter.
# Invariants:
# - Impacts and the storm live on SEPARATE buses. They are balanced against
#   each other constantly and a single flat level cannot serve both: the roar
#   is a continuous bed, impacts are transient peaks.
# - A hard limiter sits on Master because this game stacks sound violently -
#   a barn coming apart can fire a dozen impacts in one frame, and without a
#   limiter that sums into clipping, which is most of what "badly levelled"
#   sounds like.
# - Levels are set in ONE place, here and in the wrappers below. No caller
#   passes a raw decibel value.
# ============================================================================
func _bus(name: String, volume_db: float) -> void:
	if AudioServer.get_bus_index(name) != -1:
		return
	AudioServer.add_bus()
	var i := AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, name)
	AudioServer.set_bus_send(i, "Master")
	AudioServer.set_bus_volume_db(i, volume_db)


func _setup_buses() -> void:
	_bus("SFX", -3.0)
	_bus("Storm", -6.0)
	var m := AudioServer.get_bus_index("Master")
	if m != -1 and AudioServer.get_bus_effect_count(m) == 0:
		var fx: AudioEffect = null
		if ClassDB.class_exists("AudioEffectHardLimiter"):
			fx = ClassDB.instantiate("AudioEffectHardLimiter")
		else:
			fx = AudioEffectLimiter.new()
		if fx != null:
			AudioServer.add_bus_effect(m, fx)
# [BS:AUDIO:MIX:END]


# ============================================================================
# [BS:AUDIO:MIXER]
# Purpose: Stream loading and a fixed pool of 3D voices.
# Invariants:
# - The pool is FIXED. Allocating a player per sound lets a debris cascade
#   spawn hundreds of nodes and stall a phone; the oldest voice is stolen
#   instead.
# - Loading is cached. A stream is read from disk once.
# - A missing file returns null and is skipped, never crashes a caller
#   mid-run. --selftest is what turns a missing file into a build failure.
# ============================================================================
func stream_for(basename: String, looping: bool = false) -> AudioStream:
	var key := basename + ("#loop" if looping else "")
	if _cache.has(key):
		return _cache[key]
	var path := DIR + basename + ".ogg"
	if not ResourceLoader.exists(path):
		push_warning("audio missing: " + path)
		return null
	var s: AudioStream = load(path)
	if s == null:
		return null
	if looping:
		s = s.duplicate()
		if s is AudioStreamOggVorbis:
			s.loop = true
	_cache[key] = s
	return s


# The stealing rule, pulled out as a pure function so --selftest can drive it
# with synthetic state. A rule that only runs inside a live audio pool is a
# rule no check can fail on.
# Returns the index to steal, or -1 to refuse (drop the incoming sound).
static func pick_victim(pris: Array[int], start: int, pri: int) -> int:
	var worst := -1
	var worst_pri := pri
	var n := pris.size()
	for i in range(n):
		var idx := (start + i) % n
		if pris[idx] < worst_pri:
			worst_pri = pris[idx]
			worst = idx
	return worst


# Returns null when every voice is busy with something MORE important than the
# incoming sound - the caller then drops it rather than displacing the reward.
func _voice(pri: int) -> AudioStreamPlayer3D:
	for i in range(_pool.size()):
		var idx := (_next + i) % _pool.size()
		var p := _pool[idx]
		if not p.playing:
			_next = (idx + 1) % _pool.size()
			_pri[idx] = pri
			return p
	var worst := pick_victim(_pri, _next, pri)
	if worst < 0:
		dropped += 1
		return null
	_next = (worst + 1) % _pool.size()
	_pri[worst] = pri
	return _pool[worst]


# A voice that is not in the world: fixed level, no distance attenuation.
# Priority applies here too - a stud shower must not shoulder out an objective.
func _flat_voice(pri: int) -> AudioStreamPlayer:
	for i in range(_flat.size()):
		var idx := (_flat_next + i) % _flat.size()
		if not _flat[idx].playing:
			_flat_next = (idx + 1) % _flat.size()
			_flat_pri[idx] = pri
			return _flat[idx]
	var worst := pick_victim(_flat_pri, _flat_next, pri)
	if worst < 0:
		dropped += 1
		return null
	_flat_next = (worst + 1) % _flat.size()
	_flat_pri[worst] = pri
	return _flat[worst]


func play(event: String, at: Vector3, volume_db: float = 0.0, pitch: float = 1.0,
		pri: int = PRI_WORLD, vol_rnd: float = 2.0) -> void:
	if not BANK.has(event):
		return
	var names: Array = BANK[event]
	var s := stream_for(names[randi() % names.size()])
	if s == null:
		return
	var p := _voice(pri)
	if p == null:
		return
	p.stream = s
	p.global_position = at
	p.volume_db = volume_db - randf() * maxf(vol_rnd, 0.0)
	p.pitch_scale = pitch
	p.play()
	world_plays += 1


# Feedback about the player's OWN action - level must not depend on where in
# the world it happened. See [BS:AUDIO:FLAT].
func play_flat(event: String, volume_db: float = 0.0, pitch: float = 1.0,
		pri: int = PRI_REWARD, vol_rnd: float = 0.0) -> void:
	if not BANK.has(event):
		return
	var names: Array = BANK[event]
	var s := stream_for(names[randi() % names.size()])
	if s == null:
		return
	var g := _flat_voice(pri)
	if g == null:
		return
	g.stream = s
	g.volume_db = volume_db - randf() * maxf(vol_rnd, 0.0)
	g.pitch_scale = pitch
	g.play()
	flat_plays += 1


# A looping voice owned by another node - the funnel, a truck.
func attach_loop(name: String, to: Node3D, volume_db: float = -80.0) -> AudioStreamPlayer3D:
	if to == null or not LOOPS.has(name):
		return null
	var s := stream_for(LOOPS[name], true)
	if s == null:
		return null
	var p := AudioStreamPlayer3D.new()
	p.stream = s
	p.max_distance = 220.0
	p.unit_size = 40.0
	p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	p.volume_db = volume_db
	p.bus = "Storm"
	to.add_child(p)
	p.play()
	return p
# [BS:AUDIO:MIXER:END]


# Silence everything and free every voice. Used on scene change, and by
# --selftest so the routing assertions start from a known pool.
func stop_all() -> void:
	for i in range(_pool.size()):
		_pool[i].stop()
		_pri[i] = PRI_MIN
	for i in range(_flat.size()):
		_flat[i].stop()
		_flat_pri[i] = PRI_MIN


# ============================================================================
# [BS:AUDIO:STUD_LADDER]
# Purpose: Stud pickups rise in pitch through a streak, then reset.
# Invariants:
# - This is a TT Games signature and it is the reward loop's whole voice: a
#   run of studs should sound like it is going somewhere.
# - Rate-limited. Two hundred studs magnetised at once must not fire two
#   hundred voices; the limiter is what keeps a stud shower from becoming a
#   buzzsaw.
# - The ladder resets after a pause, so the next run starts low again.
# ============================================================================
func stud(_at: Vector3) -> void:
	var now := float(Time.get_ticks_msec()) * 0.001
	if now - _stud_last > 0.6:
		_stud_streak = 0
	_stud_last = now
	if now - _stud_sounded < 0.045:
		return
	_stud_sounded = now
	_stud_streak = mini(_stud_streak + 1, 14)
	play_flat("stud", -13.0, 1.0 + float(_stud_streak) * 0.034, PRI_STUD)
# [BS:AUDIO:STUD_LADDER:END]


# Convenience wrappers so callers name the event, not the file. Levels live
# here and nowhere else, so the whole mix can be read in one screen and
# compared - which is the only way a mix stays balanced as sounds are added.
func smash(at: Vector3, heavy: bool = false) -> void:
	play("smash_heavy" if heavy else "smash", at, -6.0 if heavy else -9.0,
		randf_range(0.92, 1.10), PRI_DEBRIS, 3.5)


func ram(at: Vector3, force: float) -> void:
	play("ram", at, clampf(-16.0 + force * 0.4, -16.0, -5.0),
		randf_range(0.85, 1.0), PRI_WORLD, 2.0)


func tumble(at: Vector3) -> void:
	play("tumble", at, -8.0, randf_range(0.9, 1.05), PRI_DEBRIS, 3.0)


func jump(at: Vector3) -> void:
	play("jump", at, -17.0, randf_range(1.0, 1.12), PRI_WORLD, 1.5)


# The next four are the player's own action answering back - flat, not placed.
func built(_at: Vector3) -> void:
	play_flat("build", -9.0)


func objective(_at: Vector3) -> void:
	play_flat("objective", -9.0, 1.0, PRI_CRITICAL)


func deployed(_at: Vector3) -> void:
	play_flat("deploy", -8.0)
