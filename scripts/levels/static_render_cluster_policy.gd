# @brickstorm.system levels
# @brickstorm.role Authoring policy for baking compatible noninteractive modular scenery into spatially sensible runtime render clusters without erasing gameplay identity.
# @brickstorm.scope runtime
# @brickstorm.risk low
# @brickstorm.contract static_render_clusters,modular_authoring
# @brickstorm.north_star mobile_first
# @brickstorm.owner openai/brickstorm

class_name StaticRenderClusterPolicy
extends Resource

@export var enabled: bool = true
@export var maximum_cluster_span_meters: float = 18.0
@export var maximum_source_instances: int = 64
@export var require_shared_material_family: bool = true
@export var preserve_collision_separately: bool = true

func is_valid_policy() -> bool:
	return maximum_cluster_span_meters > 0.0 and maximum_source_instances > 0
