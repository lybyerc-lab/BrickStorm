# @brickstorm.system building
# @brickstorm.role Reusable ordered build recipe that owns step cadence, snap timing, completion punctuation, and backward-compatible timing defaults.
# @brickstorm.scope runtime
# @brickstorm.risk medium
# @brickstorm.contract build_recipe,build_recipe_steps,build_completion_punctuation
# @brickstorm.north_star classic_lego_presentation
# @brickstorm.owner openai/brickstorm

class_name BuildRecipe
extends Resource

@export_category("Ordered Components")
@export var steps: Array[BuildRecipeStep] = []

@export_category("Build Cadence")
@export var move_duration: float = 0.72
@export var rotation_duration_ratio: float = 0.82
@export var order_step_delay: float = 0.035
@export var snap_base_ratio: float = 0.52
@export var snap_order_step: float = 0.035
@export var snap_delay_cap_ratio: float = 0.72

@export_category("Completion Punctuation")
@export var camera_focus_duration: float = 0.75
@export var camera_focus_fov: float = 54.0
@export var camera_shake_strength: float = 0.16
@export var camera_shake_duration: float = 0.18

func configure_from_build_orders(part_ids: Array[StringName], build_orders: Array[int], fallback_duration: float) -> void:
	steps.clear()
	move_duration = maxf(0.01, fallback_duration)
	var count: int = mini(part_ids.size(), build_orders.size())
	for index in range(count):
		var step: BuildRecipeStep = BuildRecipeStep.new()
		step.part_id = part_ids[index]
		step.build_order = maxi(0, build_orders[index])
		step.delay_seconds = -1.0
		steps.append(step)

func get_part_delay(part_index: int, fallback_order: int) -> float:
	if part_index >= 0 and part_index < steps.size():
		var step: BuildRecipeStep = steps[part_index]
		if step.delay_seconds >= 0.0:
			return step.delay_seconds
		return float(maxi(0, step.build_order)) * maxf(0.0, order_step_delay)
	return float(maxi(0, fallback_order)) * maxf(0.0, order_step_delay)

func get_snap_delay(order_value: int) -> float:
	var base_delay: float = move_duration * clampf(snap_base_ratio, 0.0, 1.0)
	var order_delay: float = float(maxi(0, order_value)) * maxf(0.0, snap_order_step)
	var delay_cap: float = move_duration * clampf(snap_delay_cap_ratio, 0.0, 1.0)
	return minf(delay_cap, base_delay + order_delay)

func get_rotation_duration() -> float:
	return move_duration * maxf(0.05, rotation_duration_ratio)
