# @brickstorm.system components
# @brickstorm.role Owns one actor's acquired contextual tools and publishes toolbelt changes without coupling world puzzles to the player implementation.
# @brickstorm.scope runtime
# @brickstorm.risk medium
# @brickstorm.contract contextual_tools,tool_persistence_during_respawn
# @brickstorm.north_star lego_twister
# @brickstorm.owner openai/brickstorm

class_name ToolbeltComponent
extends Node

signal tool_added(tool_id: StringName, display_name: String)

var _tools: Dictionary = {}

func add_tool(tool_id: StringName, display_name: String) -> bool:
	if tool_id.is_empty() or _tools.has(tool_id):
		return false
	var safe_name: String = display_name.strip_edges()
	if safe_name.is_empty():
		safe_name = String(tool_id).replace("_", " ").to_upper()
	_tools[tool_id] = safe_name
	tool_added.emit(tool_id, safe_name)
	GameEvents.tool_acquired.emit(tool_id, safe_name)
	GameEvents.toolbelt_changed.emit(get_summary())
	return true

func has_tool(tool_id: StringName) -> bool:
	return not tool_id.is_empty() and _tools.has(tool_id)

func tool_count() -> int:
	return _tools.size()

func get_summary() -> String:
	if _tools.is_empty():
		return "--"
	var names: Array[String] = []
	for value: Variant in _tools.values():
		names.append(str(value))
	names.sort()
	return " / ".join(names)
