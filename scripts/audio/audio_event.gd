# @brickstorm.system audio
# @brickstorm.role Data resource for semantic sound identity, sample variation, pitch/gain ranges, concurrency, cooldown, and future spatial policy.
# @brickstorm.scope runtime
# @brickstorm.risk medium
# @brickstorm.contract semantic_audio_event,audio_variation
# @brickstorm.north_star classic_lego_presentation
# @brickstorm.owner openai/brickstorm

class_name AudioEvent
extends Resource

@export_category("Identity")
@export var event_id: StringName = &""
@export var variants: Array[AudioStream] = []

@export_category("Variation")
@export var volume_db_min: float = -8.0
@export var volume_db_max: float = -8.0
@export var pitch_min: float = 1.0
@export var pitch_max: float = 1.0

@export_category("Playback Policy")
@export var priority: int = 50
@export var concurrency_limit: int = 0
@export var cooldown_seconds: float = 0.0
@export var loop: bool = false

@export_category("Spatial Policy")
@export var near_distance: float = 0.0
@export var far_distance: float = 0.0

func choose_stream(rng: RandomNumberGenerator) -> AudioStream:
	if variants.is_empty():
		return null
	var index: int = rng.randi_range(0, variants.size() - 1)
	return variants[index]

func sample_volume_db(rng: RandomNumberGenerator) -> float:
	return rng.randf_range(minf(volume_db_min, volume_db_max), maxf(volume_db_min, volume_db_max))

func sample_pitch(rng: RandomNumberGenerator) -> float:
	return rng.randf_range(minf(pitch_min, pitch_max), maxf(pitch_min, pitch_max))

func is_valid_event() -> bool:
	return not event_id.is_empty() and not variants.is_empty()
