# @brickstorm.system building
# @brickstorm.role One semantic ordered component in a reusable LEGO-style build recipe.
# @brickstorm.scope runtime
# @brickstorm.risk low
# @brickstorm.contract build_recipe_steps
# @brickstorm.north_star classic_lego_presentation
# @brickstorm.owner openai/brickstorm

class_name BuildRecipeStep
extends Resource

@export var part_id: StringName = &""
@export var build_order: int = 0
@export var delay_seconds: float = -1.0
