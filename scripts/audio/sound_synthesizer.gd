extends Node
class_name SoundSynthesizer

static var _instance: SoundSynthesizer

var _audio_players: Array[AudioStreamPlayer] = []
var _wind_player: AudioStreamPlayer
var _cache: Dictionary = {}

const MIX_RATE = 22050

func _init() -> void:
	_instance = self

static func get_instance() -> SoundSynthesizer:
	return _instance

func _ready() -> void:
	_instance = self
	# Create pool of players for SFX
	for i in range(12):
		var p = AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		_audio_players.append(p)
	
	# Dedicated looping player for tornado wind
	_wind_player = AudioStreamPlayer.new()
	_wind_player.bus = &"Master"
	_wind_player.stream = _create_wind_stream(2.0)
	add_child(_wind_player)
	_wind_player.volume_db = -80.0
	_wind_player.play()

func _get_free_player() -> AudioStreamPlayer:
	for p in _audio_players:
		if not p.is_playing():
			return p
	return _audio_players[0]

func play_stud_pickup(multiplier: int = 1) -> void:
	var key = "stud_%d" % multiplier
	if not _cache.has(key):
		var base_freq = 660.0 + (multiplier - 1) * 220.0
		_cache[key] = _create_chime_stream(base_freq, 0.18)
	var p = _get_free_player()
	p.stream = _cache[key]
	p.volume_db = -4.0
	p.play()

func play_brick_smash() -> void:
	if not _cache.has("smash"):
		_cache["smash"] = _create_smash_stream(0.25)
	var p = _get_free_player()
	p.stream = _cache["smash"]
	p.volume_db = -2.0
	p.play()

func play_build_click() -> void:
	if not _cache.has("build"):
		_cache["build"] = _create_click_stream(0.08)
	var p = _get_free_player()
	p.stream = _cache["build"]
	p.volume_db = -5.0
	p.play()

func play_heart_loss() -> void:
	if not _cache.has("heart_loss"):
		_cache["heart_loss"] = _create_tone_slide(440.0, 180.0, 0.3)
	var p = _get_free_player()
	p.stream = _cache["heart_loss"]
	p.volume_db = -2.0
	p.play()

func play_cow_moo() -> void:
	if not _cache.has("moo"):
		_cache["moo"] = _create_moo_stream(0.6)
	var p = _get_free_player()
	p.stream = _cache["moo"]
	p.volume_db = 0.0
	p.play()

func play_true_chaser_fanfare() -> void:
	if not _cache.has("fanfare"):
		_cache["fanfare"] = _create_fanfare_stream()
	var p = _get_free_player()
	p.stream = _cache["fanfare"]
	p.volume_db = 2.0
	p.play()

func update_wind_proximity(dist_to_tornado: float) -> void:
	if not is_instance_valid(_wind_player):
		return
	# Scale wind volume: -40dB at 60m to 0dB at 5m
	var t = clampf(1.0 - (dist_to_tornado / 50.0), 0.0, 1.0)
	if t <= 0.01:
		_wind_player.volume_db = -80.0
	else:
		_wind_player.volume_db = lerpf(-35.0, 3.0, t)

# --- Waveform synthesizers ---

func _create_wav(data: PackedByteArray, loop: bool = false) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = data.size() / 2
	return wav

func _create_chime_stream(freq: float, duration: float) -> AudioStreamWAV:
	var num_samples = int(MIX_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	for i in range(num_samples):
		var t = float(i) / float(MIX_RATE)
		var env = exp(-t * 18.0) # Sharp bell envelope
		var s = (sin(TAU * freq * t) * 0.7 + sin(TAU * freq * 2.0 * t) * 0.3) * env
		var sample_val = int(clampf(s * 28000.0, -32767.0, 32767.0))
		bytes.encode_s16(i * 2, sample_val)
	return _create_wav(bytes)

func _create_smash_stream(duration: float) -> AudioStreamWAV:
	var num_samples = int(MIX_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	for i in range(num_samples):
		var t = float(i) / float(MIX_RATE)
		var env = exp(-t * 14.0)
		var noise = randf_range(-1.0, 1.0)
		var thud = sin(TAU * 110.0 * (1.0 - t * 3.0) * t) * 0.5
		var s = (noise * 0.6 + thud * 0.4) * env
		var sample_val = int(clampf(s * 30000.0, -32767.0, 32767.0))
		bytes.encode_s16(i * 2, sample_val)
	return _create_wav(bytes)

func _create_click_stream(duration: float) -> AudioStreamWAV:
	var num_samples = int(MIX_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	for i in range(num_samples):
		var t = float(i) / float(MIX_RATE)
		var env = exp(-t * 45.0)
		var s = sin(TAU * 1400.0 * t) * env
		var sample_val = int(clampf(s * 25000.0, -32767.0, 32767.0))
		bytes.encode_s16(i * 2, sample_val)
	return _create_wav(bytes)

func _create_tone_slide(start_f: float, end_f: float, duration: float) -> AudioStreamWAV:
	var num_samples = int(MIX_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	for i in range(num_samples):
		var progress = float(i) / float(num_samples)
		var t = float(i) / float(MIX_RATE)
		var f = lerpf(start_f, end_f, progress)
		var env = 1.0 - progress
		var s = sin(TAU * f * t) * env
		var sample_val = int(clampf(s * 26000.0, -32767.0, 32767.0))
		bytes.encode_s16(i * 2, sample_val)
	return _create_wav(bytes)

func _create_moo_stream(duration: float) -> AudioStreamWAV:
	var num_samples = int(MIX_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	for i in range(num_samples):
		var progress = float(i) / float(num_samples)
		var t = float(i) / float(MIX_RATE)
		# Frequency bend: 150Hz -> 120Hz -> 100Hz
		var f = 150.0 - sin(progress * PI) * 35.0
		var env = sin(progress * PI)
		# Rich saw/square harmonic
		var s = (sin(TAU * f * t) + 0.5 * sin(TAU * f * 2.0 * t) + 0.25 * sin(TAU * f * 3.0 * t)) * 0.4 * env
		var sample_val = int(clampf(s * 28000.0, -32767.0, 32767.0))
		bytes.encode_s16(i * 2, sample_val)
	return _create_wav(bytes)

func _create_wind_stream(duration: float) -> AudioStreamWAV:
	var num_samples = int(MIX_RATE * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	var last_noise = 0.0
	for i in range(num_samples):
		# Low-pass filtered noise for wind howl
		var raw = randf_range(-1.0, 1.0)
		last_noise = lerpf(last_noise, raw, 0.08)
		var rumble = sin(TAU * 55.0 * float(i) / float(MIX_RATE)) * 0.3
		var s = (last_noise * 0.7 + rumble * 0.3)
		var sample_val = int(clampf(s * 22000.0, -32767.0, 32767.0))
		bytes.encode_s16(i * 2, sample_val)
	return _create_wav(bytes, true)

func _create_fanfare_stream() -> AudioStreamWAV:
	# C4 -> E4 -> G4 -> C5 rapid arpeggio
	var notes = [261.63, 329.63, 392.0, 523.25]
	var note_dur = 0.14
	var total_dur = note_dur * 4 + 0.4
	var num_samples = int(MIX_RATE * total_dur)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / float(MIX_RATE)
		var note_idx = int(t / note_dur)
		if note_idx >= 4:
			note_idx = 3 # hold high C
		var f = notes[note_idx]
		var note_t = fmod(t, note_dur) if note_idx < 3 else (t - note_dur * 3.0)
		var env = exp(-note_t * 6.0) if note_idx < 3 else exp(-note_t * 2.5)
		var s = (sin(TAU * f * t) * 0.7 + sin(TAU * f * 2.0 * t) * 0.3) * env
		var sample_val = int(clampf(s * 28000.0, -32767.0, 32767.0))
		bytes.encode_s16(i * 2, sample_val)
	return _create_wav(bytes)
