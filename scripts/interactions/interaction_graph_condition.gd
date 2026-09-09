# @brickstorm.system interactions
# @brickstorm.role Typed ALL/ANY/NONE condition over semantic interaction state IDs.
# @brickstorm.scope runtime
# @brickstorm.risk medium
# @brickstorm.contract interaction_graph,semantic_state_queries
# @brickstorm.north_star classic_lego_presentation
# @brickstorm.owner openai/brickstorm

class_name InteractionGraphCondition
extends Resource

enum Operator {
	ALL,
	ANY,
	NONE,
}

@export var operator: Operator = Operator.ALL
@export var query_ids: Array[StringName] = []

func evaluate(states: Dictionary[StringName, bool]) -> bool:
	if query_ids.is_empty():
		return operator != Operator.ANY
	if operator == Operator.ALL:
		for query_id: StringName in query_ids:
			if not states.has(query_id) or not states[query_id]:
				return false
		return true
	if operator == Operator.ANY:
		for query_id: StringName in query_ids:
			if states.has(query_id) and states[query_id]:
				return true
		return false
	for query_id: StringName in query_ids:
		if states.has(query_id) and states[query_id]:
			return false
	return true
