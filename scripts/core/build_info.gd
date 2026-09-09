# @brickstorm.system core
# @brickstorm.role Single source for user-visible build identity and engine target.
# @brickstorm.scope runtime
# @brickstorm.risk high
# @brickstorm.contract none
# @brickstorm.north_star foundation
# @brickstorm.owner openai/brickstorm

class_name BuildInfo
extends RefCounted

const VERSION: String = "0.3.6"
const DISPLAY_LABEL: String = "FOUNDATION " + VERSION
const ENGINE_TARGET: String = "Godot 4.7.2 stable"
