# @brickstorm.system interactions
# @brickstorm.role Runtime evaluator for semantic interaction state, one-shot/repeatable graph nodes, and Story/Free Play policy gates.
# @brickstorm.scope runtime
# @brickstorm.risk medium
# @brickstorm.contract interaction_graph,semantic_state_queries,story_freeplay_policy
# @brickstorm.north_star classic_lego_presentation
# @brickstorm.owner openai/brickstorm

class_name InteractionGraphRuntime
extends Node

signal output_emitted(output_id: StringName)

@export var graph: InteractionGraph
@export var free_play_mode: bool = false

var _states: Dictionary[StringName, bool] = {}
var _fired_nodes: Dictionary[StringName, bool] = {}

func set_state(query_id: StringName, value: bool) -> void:
	if query_id.is_empty():
		return
	_states[query_id] = value
	evaluate()

func get_state(query_id: StringName) -> bool:
	return _states.has(query_id) and _states[query_id]

func reset_runtime_state() -> void:
	_states.clear()
	_fired_nodes.clear()

func evaluate() -> void:
	if graph == null:
		return
	for graph_node: InteractionGraphNode in graph.nodes:
		if graph_node == null or graph_node.node_id.is_empty() or graph_node.condition == null:
			continue
		if graph_node.story_only and free_play_mode:
			continue
		if graph_node.free_play_only and not free_play_mode:
			continue
		if not graph_node.repeatable and _fired_nodes.has(graph_node.node_id):
			continue
		if not graph_node.condition.evaluate(_states):
			continue
		_fired_nodes[graph_node.node_id] = true
		for output_id: StringName in graph_node.output_ids:
			if not output_id.is_empty():
				output_emitted.emit(output_id)
