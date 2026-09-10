extends Node3D
class_name MainGame

const MinifigCharacter = preload("res://scripts/actors/minifig_character.gd")
const CompanionAI = preload("res://scripts/actors/companion_ai.gd")
const Tornado = preload("res://scripts/storm/tornado.gd")
const GameHUD = preload("res://scripts/ui/hud.gd")

var camera: Camera3D
var player: MinifigCharacter
var companion: CompanionAI
var tornado: Tornado
var ground_mesh: MeshInstance3D
var world_env: WorldEnvironment
var sun_light: DirectionalLight3D

var lightning_timer: float = 4.0
var lightning_phase: float = 0.0

func _ready() -> void:
	camera = $Camera3D
	player = $MinifigCharacter
	companion = $CompanionAI if has_node("CompanionAI") else null
	tornado = $Tornado
	ground_mesh = $Ground/GroundMesh if has_node("Ground/GroundMesh") else $Ground
	world_env = $WorldEnvironment
	sun_light = $DirectionalLight3D
	
	var dorothy = find_child("DorothyPod", true, false)
	if is_instance_valid(dorothy):
		dorothy.dorothy_deployed.connect(_on_dorothy_deployed)

func _physics_process(delta: float) -> void:
	# TT Third-Person Action Camera framing
	if is_instance_valid(player) and is_instance_valid(camera):
		# Look-ahead based on player movement
		var move_forward = -player.global_transform.basis.z * 1.5
		var target_cam_pos = player.global_position + Vector3(0, 4.2, 7.8) + move_forward * 0.4
		
		# Slight pull-back if tornado is close
		if is_instance_valid(tornado):
			var dist = player.global_position.distance_to(tornado.global_position)
			if dist < 40.0:
				var pull = (40.0 - dist) * 0.08
				target_cam_pos += Vector3(0, pull * 0.4, pull)
				
		camera.global_position = camera.global_position.lerp(target_cam_pos, delta * 7.0)
		camera.look_at(player.global_position + Vector3(0, 1.1, 0), Vector3.UP)
		
	# Update tornado position on ground shader
	if is_instance_valid(ground_mesh) and is_instance_valid(tornado):
		var mat = ground_mesh.material_override as ShaderMaterial
		if is_instance_valid(mat):
			mat.set_shader_parameter("tornado_pos", tornado.global_position)
			
	# Dynamic lightning flash simulation on supercell sky
	_process_lightning(delta)

func _process_lightning(delta: float) -> void:
	lightning_timer -= delta
	if lightning_timer <= 0.0:
		lightning_timer = randf_range(3.5, 7.0)
		lightning_phase = 1.0 # Trigger lightning strike
		
	if lightning_phase > 0.0:
		lightning_phase -= delta * 4.0
		var intensity = sin(clampf(lightning_phase, 0.0, 1.0) * PI) * (0.8 + 0.2 * sin(lightning_phase * 20.0))
		
		if is_instance_valid(world_env) and world_env.environment != null and world_env.environment.sky != null:
			var sky_mat = world_env.environment.sky.sky_material as ShaderMaterial
			if is_instance_valid(sky_mat):
				sky_mat.set_shader_parameter("lightning_intensity", clampf(intensity, 0.0, 1.0))
				
		if is_instance_valid(sun_light):
			sun_light.light_energy = 1.2 + intensity * 2.5
	else:
		if is_instance_valid(sun_light):
			sun_light.light_energy = 1.2

func _on_dorothy_deployed() -> void:
	var hud = find_child("HUD", true, false) as GameHUD
	if is_instance_valid(hud):
		hud.objective_label.text = "🏆 MISSION COMPLETE! DATA CAPTURED! 🏆"
		hud.objective_label.modulate = Color(0.2, 1.0, 0.4)
