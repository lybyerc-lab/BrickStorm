# @brickstorm.system core
# @brickstorm.role Owns semantic AudioEvent playback for original plastic/stud/tool/build feedback and a looping storm-wind bed without licensed audio assets.
# @brickstorm.scope runtime
# @brickstorm.risk medium
# @brickstorm.contract audio_feedback,semantic_audio_event,stud_audio_identity,build_audio,tool_audio,storm_ambience
# @brickstorm.north_star classic_lego_presentation
# @brickstorm.owner openai/brickstorm

extends Node

const STUD_SILVER: AudioStream = preload("res://assets/audio/stud_silver.wav")
const STUD_GOLD: AudioStream = preload("res://assets/audio/stud_gold.wav")
const STUD_BLUE: AudioStream = preload("res://assets/audio/stud_blue.wav")
const STUD_PURPLE: AudioStream = preload("res://assets/audio/stud_purple.wav")
const SMASH_HIT: AudioStream = preload("res://assets/audio/smash_hit.wav")
const BUILD_SNAP: AudioStream = preload("res://assets/audio/build_snap.wav")
const BUILD_COMPLETE: AudioStream = preload("res://assets/audio/build_complete.wav")
const TOOL_PICKUP: AudioStream = preload("res://assets/audio/tool_pickup.wav")
const TOOL_USE: AudioStream = preload("res://assets/audio/tool_use.wav")
const SECRET: AudioStream = preload("res://assets/audio/secret.wav")
const WIND_LOOP_SOURCE: AudioStream = preload("res://assets/audio/wind_loop.wav")

const EVENT_STUD_SILVER: StringName = &"stud.silver.pickup"
const EVENT_STUD_GOLD: StringName = &"stud.gold.pickup"
const EVENT_STUD_BLUE: StringName = &"stud.blue.pickup"
const EVENT_STUD_PURPLE: StringName = &"stud.purple.pickup"
const EVENT_SMASH_HIT: StringName = &"brick.smash.hit"
const EVENT_BUILD_SNAP: StringName = &"brick.build.snap"
const EVENT_BUILD_COMPLETE: StringName = &"brick.build.complete"
const EVENT_TOOL_PICKUP: StringName = &"tool.pickup"
const EVENT_TOOL_USE: StringName = &"tool.use"
const EVENT_SECRET: StringName = &"secret.reveal"

const POOL_SIZE: int = 10

var _players: Array[AudioStreamPlayer] = []
var _player_event_ids: Array[StringName] = []
var _events: Dictionary[StringName, AudioEvent] = {}
var _last_event_msec: Dictionary[StringName, int] = {}
var _next_player: int = 0
var _wind_player: AudioStreamPlayer
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_build_event_library()
	for index in range(POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SfxPlayer_%02d" % index
		player.volume_db = -7.0
		add_child(player)
		_players.append(player)
		_player_event_ids.append(StringName())
	_build_wind_player()

func play_stud(value: int) -> void:
	var event_id: StringName = EVENT_STUD_SILVER
	if value >= StudCurrency.VALUE_PURPLE:
		event_id = EVENT_STUD_PURPLE
	elif value >= StudCurrency.VALUE_BLUE:
		event_id = EVENT_STUD_BLUE
	elif value >= StudCurrency.VALUE_GOLD:
		event_id = EVENT_STUD_GOLD
	_play_event(event_id)

func play_smash() -> void:
	_play_event(EVENT_SMASH_HIT)

func play_build_snap(order_index: int = 0) -> void:
	var pitch_multiplier: float = 0.95 + float(order_index % 5) * 0.055
	_play_event(EVENT_BUILD_SNAP, pitch_multiplier)

func play_build_complete() -> void:
	_play_event(EVENT_BUILD_COMPLETE)

func play_tool_pickup() -> void:
	_play_event(EVENT_TOOL_PICKUP)

func play_tool_use() -> void:
	_play_event(EVENT_TOOL_USE)

func play_secret() -> void:
	_play_event(EVENT_SECRET)

func set_wind_strength(strength: float) -> void:
	if not is_instance_valid(_wind_player):
		return
	var clamped: float = clampf(strength, 0.0, 1.0)
	_wind_player.volume_db = lerpf(-31.0, -14.0, clamped)
	_wind_player.pitch_scale = lerpf(0.88, 1.06, clamped)

func get_event(event_id: StringName) -> AudioEvent:
	if not _events.has(event_id):
		return null
	return _events[event_id]

func _build_event_library() -> void:
	_events.clear()
	_register_single_event(EVENT_STUD_SILVER, STUD_SILVER, -6.0, 1.0, 1.0)
	_register_single_event(EVENT_STUD_GOLD, STUD_GOLD, -6.0, 1.0, 1.0)
	_register_single_event(EVENT_STUD_BLUE, STUD_BLUE, -6.0, 1.0, 1.0)
	_register_single_event(EVENT_STUD_PURPLE, STUD_PURPLE, -6.0, 1.0, 1.0)
	_register_single_event(EVENT_SMASH_HIT, SMASH_HIT, -8.5, 0.94, 1.08)
	_register_single_event(EVENT_BUILD_SNAP, BUILD_SNAP, -8.0, 1.0, 1.0)
	_register_single_event(EVENT_BUILD_COMPLETE, BUILD_COMPLETE, -4.5, 1.0, 1.0)
	_register_single_event(EVENT_TOOL_PICKUP, TOOL_PICKUP, -5.0, 1.0, 1.0)
	_register_single_event(EVENT_TOOL_USE, TOOL_USE, -7.0, 0.96, 1.04)
	_register_single_event(EVENT_SECRET, SECRET, -4.0, 1.0, 1.0)

func _register_single_event(event_id: StringName, stream: AudioStream, volume_db: float, pitch_min: float, pitch_max: float) -> void:
	var event: AudioEvent = AudioEvent.new()
	event.event_id = event_id
	event.variants.append(stream)
	event.volume_db_min = volume_db
	event.volume_db_max = volume_db
	event.pitch_min = pitch_min
	event.pitch_max = pitch_max
	_events[event_id] = event

func _build_wind_player() -> void:
	_wind_player = AudioStreamPlayer.new()
	_wind_player.name = "StormWindBed"
	var loop_stream: AudioStream = WIND_LOOP_SOURCE.duplicate()
	if loop_stream is AudioStreamWAV:
		var wav: AudioStreamWAV = loop_stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = 0
	_wind_player.stream = loop_stream
	_wind_player.volume_db = -26.0
	add_child(_wind_player)
	if _audio_playback_available():
		_wind_player.play()

func stop_all_audio() -> void:
	for index in range(_players.size()):
		var player: AudioStreamPlayer = _players[index]
		if is_instance_valid(player):
			player.stop()
			player.stream = null
		_player_event_ids[index] = StringName()
	_last_event_msec.clear()
	if is_instance_valid(_wind_player):
		_wind_player.stop()
		_wind_player.stream = null

func _exit_tree() -> void:
	stop_all_audio()

func _audio_playback_available() -> bool:
	return DisplayServer.get_name() != "headless" and AudioServer.get_driver_name() != "Dummy"

func _play_event(event_id: StringName, pitch_multiplier: float = 1.0, volume_offset_db: float = 0.0) -> void:
	if _players.is_empty() or not _audio_playback_available() or not _events.has(event_id):
		return
	var event: AudioEvent = _events[event_id]
	if event == null or not event.is_valid_event():
		return
	var now_msec: int = Time.get_ticks_msec()
	if event.cooldown_seconds > 0.0 and _last_event_msec.has(event_id):
		var cooldown_msec: int = int(event.cooldown_seconds * 1000.0)
		if now_msec - _last_event_msec[event_id] < cooldown_msec:
			return
	if event.concurrency_limit > 0:
		var active_same_event: int = 0
		for index in range(_players.size()):
			if _players[index].playing and _player_event_ids[index] == event_id:
				active_same_event += 1
		if active_same_event >= event.concurrency_limit:
			return
	var stream: AudioStream = event.choose_stream(_rng)
	if stream == null:
		return
	var player_index: int = _next_player
	var player: AudioStreamPlayer = _players[player_index]
	_next_player = (_next_player + 1) % _players.size()
	player.stop()
	player.stream = stream
	player.volume_db = event.sample_volume_db(_rng) + volume_offset_db
	player.pitch_scale = event.sample_pitch(_rng) * maxf(0.01, pitch_multiplier)
	_player_event_ids[player_index] = event_id
	_last_event_msec[event_id] = now_msec
	player.play()
