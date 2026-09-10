extends Node3D
class_name MainGame

var camera: Camera3D
var player: MinifigCharacter
var tornado: Tornado
var ground_mesh: MeshInstance3D

func _ready() -> void:
	camera = $Camera3D
	player = $MinifigCharacter
	tornado = $Tornado
	ground_mesh = $Ground
	
	# Hook up Dorothy deploy signal
	var dorothy = find_child("DorothyPod", true, false)
	if is_instance_valid(dorothy):
		dorothy.dorothy_deployed.connect(_on_dorothy_deployed)

func _physics_process(delta: float) -> void:
	# Director Camera framing
	if is_instance_valid(player) and is_instance_valid(camera):
		var target_cam_pos = player.global_position + Vector3(0, 7.5, 12.0)
		
		# If tornado is active, pull camera back slightly to keep both in shot
		if is_instance_valid(tornado):
			var dist = player.global_position.distance_to(tornado.global_position)
			if dist < 45.0:
				var pull_back = (45.0 - dist) * 0.12
				target_cam_pos += Vector3(0, pull_back * 0.5, pull_back)
				
		camera.global_position = camera.global_position.lerp(target_cam_pos, delta * 5.0)
		camera.look_at(player.global_position + Vector3(0, 1.2, 0), Vector3.UP)
		
	# Feed tornado position to ground shader
	if is_instance_valid(ground_mesh) and is_instance_valid(tornado):
		var mat = ground_mesh.material_override as ShaderMaterial
		if is_instance_valid(mat):
			mat.set_shader_parameter("tornado_pos", tornado.global_position)

func _on_dorothy_deployed() -> void:
	# Victory camera zoom & slow-mo beat!
	var hud = find_child("HUD", true, false) as GameHUD
	if is_instance_valid(hud):
		hud.objective_label.text = "🏆 MISSION COMPLETE! DATA CAPTURED! 🏆"
		hud.objective_label.modulate = Color(0.2, 1.0, 0.4)
