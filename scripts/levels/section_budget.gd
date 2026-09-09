# @brickstorm.system levels
# @brickstorm.role Independent render, texture, gameplay, physics, debris, presentation, and static-cluster budget contract for one streamed section.
# @brickstorm.scope runtime
# @brickstorm.risk medium
# @brickstorm.contract section_budget,static_render_clusters,mobile_performance
# @brickstorm.north_star mobile_first
# @brickstorm.owner openai/brickstorm

class_name SectionBudget
extends Resource

@export_category("Static Rendering")
@export var maximum_static_clusters: int = 48
@export var maximum_visible_clusters: int = 32
@export var maximum_material_families: int = 24
@export var maximum_texture_residency_mb: float = 96.0

@export_category("Gameplay Population")
@export var maximum_active_interactables: int = 96
@export var maximum_npcs: int = 12
@export var maximum_vehicles: int = 4

@export_category("Physics and Destruction")
@export var maximum_dynamic_bodies: int = 120
@export var maximum_tornado_fragments: int = 110
@export var maximum_active_studs: int = 60

@export_category("Presentation")
@export var maximum_particle_emitters: int = 18
@export var maximum_audio_voices: int = 16
@export var maximum_camera_requests: int = 2

func is_sane() -> bool:
	return (
		maximum_static_clusters >= 0
		and maximum_visible_clusters >= 0
		and maximum_visible_clusters <= maximum_static_clusters
		and maximum_material_families >= 0
		and maximum_texture_residency_mb >= 0.0
		and maximum_active_interactables >= 0
		and maximum_npcs >= 0
		and maximum_vehicles >= 0
		and maximum_dynamic_bodies >= 0
		and maximum_tornado_fragments >= 0
		and maximum_active_studs >= 0
		and maximum_particle_emitters >= 0
		and maximum_audio_voices >= 0
		and maximum_camera_requests >= 0
	)
