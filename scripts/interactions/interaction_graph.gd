# @brickstorm.system interactions
# @brickstorm.role Data-authored interaction graph composed of typed semantic condition/output nodes.
# @brickstorm.scope runtime
# @brickstorm.risk medium
# @brickstorm.contract interaction_graph,story_freeplay_policy
# @brickstorm.north_star classic_lego_presentation
# @brickstorm.owner openai/brickstorm

class_name InteractionGraph
extends Resource

@export var nodes: Array[InteractionGraphNode] = []
