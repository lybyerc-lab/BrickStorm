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

var _cache: Dictionary = {}
var _pool: Array[AudioStreamPlayer3D] = []
var _next: int = 0

var _stud_streak: int = 0
var _stud_last: float = 0.0
var _stud_sounded: float = 0.0


func _ready() -> void:
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer3D.new()
		p.max_distance = 90.0
		p.unit_size = 14.0
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		add_child(p)
		_pool.append(p)


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


func _voice() -> AudioStreamPlayer3D:
	for i in range(_pool.size()):
		var p := _pool[(_next + i) % _pool.size()]
		if not p.playing:
			_next = (_next + i + 1) % _pool.size()
			return p
	var steal := _pool[_next]
	_next = (_next + 1) % _pool.size()
	return steal


func play(event: String, at: Vector3, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not BANK.has(event):
		return
	var names: Array = BANK[event]
	var s := stream_for(names[randi() % names.size()])
	if s == null:
		return
	var p := _voice()
	p.stream = s
	p.global_position = at
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


# A looping voice owned by another node - the funnel, a truck.
func attach_loop(name: String, to: Node3D, volume_db: float = -80.0) -> AudioStreamPlayer3D:
	if not LOOPS.has(name):
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
	to.add_child(p)
	p.play()
	return p
# [BS:AUDIO:MIXER:END]


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
func stud(at: Vector3) -> void:
	var now := float(Time.get_ticks_msec()) * 0.001
	if now - _stud_last > 0.6:
		_stud_streak = 0
	_stud_last = now
	if now - _stud_sounded < 0.045:
		return
	_stud_sounded = now
	_stud_streak = mini(_stud_streak + 1, 22)
	play("stud", at, -9.0, 1.0 + float(_stud_streak) * 0.045)
# [BS:AUDIO:STUD_LADDER:END]


# Convenience wrappers so callers name the event, not the file.
func smash(at: Vector3, heavy: bool = false) -> void:
	play("smash_heavy" if heavy else "smash", at, -3.0, randf_range(0.92, 1.10))


func ram(at: Vector3, force: float) -> void:
	play("ram", at, clampf(-10.0 + force * 0.4, -10.0, 2.0), randf_range(0.85, 1.0))


func tumble(at: Vector3) -> void:
	play("tumble", at, -2.0, randf_range(0.9, 1.05))


func jump(at: Vector3) -> void:
	play("jump", at, -14.0, randf_range(1.0, 1.12))


func built(at: Vector3) -> void:
	play("build", at, -4.0)


func objective(at: Vector3) -> void:
	play("objective", at, -5.0)


func deployed(at: Vector3) -> void:
	play("deploy", at, -3.0)
