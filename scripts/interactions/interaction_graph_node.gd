# @brickstorm.system interactions
# @brickstorm.role One typed interaction-graph rule connecting semantic conditions to semantic outputs.
# @brickstorm.scope runtime
# @brickstorm.risk low
# @brickstorm.contract interaction_graph,interaction_graph_nodes
# @brickstorm.north_star classic_lego_presentation
# @brickstorm.owner openai/brickstorm

class_name InteractionGraphNode
extends Resource

@export var node_id: StringName = &""
@export var condition: InteractionGraphCondition
@export var output_ids: Array[StringName] = []
@export var repeatable: bool = false
@export var story_only: bool = false
@export var free_play_only: bool = false
