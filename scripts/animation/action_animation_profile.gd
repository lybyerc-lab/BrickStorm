# @brickstorm.system animation
# @brickstorm.role Data resource for authored toy-motion state holds, stride cadence, blend response, and semantic action event markers.
# @brickstorm.scope runtime
# @brickstorm.risk medium
# @brickstorm.contract action_animation_profile,semantic_animation_events
# @brickstorm.north_star classic_lego_movement
# @brickstorm.owner openai/brickstorm

class_name ActionAnimationProfile
extends Resource

@export_category("State Timing")
@export var start_hold_seconds: float = 0.12
@export var pivot_hold_seconds: float = 0.10
@export var land_hold_seconds: float = 0.12
@export var pose_return_rate: float = 18.0

@export_category("Stride")
@export var stride_phase_rate: float = 1.88
@export var footstep_phase_step: float = PI

@export_category("Waist-Led Presentation")
# Clean-room demo study points to a shared motor with richer authored action
# presentation. These values keep the controller untouched while letting the
# visible toy read as hip-driven instead of chest-driven.
@export var arm_phase_lag: float = 0.38
@export var hip_phase_lead: float = 0.10
@export var shoulder_phase_lag: float = 0.50
@export var hip_yaw_sway: float = 0.105
@export var hip_roll_sway: float = 0.026
@export var torso_follow_yaw: float = 0.040
@export var torso_roll_sway: float = 0.022
@export var shoulder_yaw_sway: float = 0.105
@export var shoulder_roll_sway: float = 0.085
@export var head_settle_yaw: float = 0.036

@export_category("Semantic Events")
@export var footstep_event_id: StringName = &"footstep"
@export var landing_event_id: StringName = &"land"
@export var pivot_event_id: StringName = &"pivot"
@export var tool_contact_event_id: StringName = &"tool_contact"
@export var smash_contact_event_id: StringName = &"smash_contact"
@export var tool_contact_delay: float = 0.18
@export var smash_contact_delay: float = 0.10

func get_safe_footstep_phase_step() -> float:
	return maxf(0.25, footstep_phase_step)
