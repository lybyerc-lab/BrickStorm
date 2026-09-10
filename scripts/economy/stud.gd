extends Node3D
class_name Stud

enum Denomination {
	SILVER = 10,
	GOLD = 100,
	BLUE = 1000,
	PURPLE = 10000
}

@export var denomination: Denomination = Denomination.SILVER
var value: int = 10

var velocity: Vector3 = Vector3.ZERO
var gravity: float = 18.0
var on_ground: bool = false
var bounces: int = 0

var target_player: CharacterBody3D = null
var is_vacuuming: bool = false
var vacuum_speed: float = 0.0

var mesh_instance: MeshInstance3D

func _ready() -> void:
	value = int(denomination)
	_create_mesh()

func _create_mesh() -> void:
	mesh_instance = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	
	# Dimensions scaled by denomination
	match denomination:
		Denomination.SILVER:
			cyl.top_radius = 0.12
			cyl.bottom_radius = 0.12
			cyl.height = 0.12
		Denomination.GOLD:
			cyl.top_radius = 0.14
			cyl.bottom_radius = 0.14
			cyl.height = 0.14
		Denomination.BLUE:
			cyl.top_radius = 0.16
			cyl.bottom_radius = 0.16
			cyl.height = 0.16
		Denomination.PURPLE:
			cyl.top_radius = 0.18
			cyl.bottom_radius = 0.18
			cyl.height = 0.18
			
	mesh_instance.mesh = cyl
	
	var mat = StandardMaterial3D.new()
	match denomination:
		Denomination.SILVER:
			mat.albedo_color = Color(0.85, 0.88, 0.92)
			mat.metallic = 0.8
			mat.roughness = 0.2
		Denomination.GOLD:
			mat.albedo_color = Color(1.0, 0.82, 0.05)
			mat.metallic = 0.85
			mat.roughness = 0.18
		Denomination.BLUE:
			mat.albedo_color = Color(0.15, 0.55, 1.0)
			mat.metallic = 0.3
			mat.roughness = 0.15
			mat.emission_enabled = true
			mat.emission = Color(0.1, 0.4, 0.9)
			mat.emission_energy_multiplier = 0.4
		Denomination.PURPLE:
			mat.albedo_color = Color(0.75, 0.15, 0.95)
			mat.metallic = 0.4
			mat.roughness = 0.15
			mat.emission_enabled = true
			mat.emission = Color(0.6, 0.1, 0.8)
			mat.emission_energy_multiplier = 0.6
			
	mesh_instance.material_override = mat
	add_child(mesh_instance)

func launch_fountain(burst_pos: Vector3) -> void:
	global_position = burst_pos
	var angle = randf() * TAU
	var speed = randf_range(2.0, 5.5)
	velocity = Vector3(cos(angle) * speed, randf_range(4.0, 7.5), sin(angle) * speed)
	on_ground = false
	bounces = 0

func _physics_process(delta: float) -> void:
	rotate_y(delta * 4.0)
	
	if is_vacuuming and is_instance_valid(target_player):
		vacuum_speed += delta * 35.0
		var target_pos = target_player.global_position + Vector3(0, 0.5, 0)
		var dir = (target_pos - global_position).normalized()
		global_position += dir * vacuum_speed * delta
		
		if global_position.distance_to(target_pos) < 0.6:
			# Collected!
			var economy = get_tree().root.find_child("StudField", true, false) as StudField
			if is_instance_valid(economy):
				economy.collect_stud(self)
			else:
				queue_free()
		return
		
	if not on_ground:
		velocity.y -= gravity * delta
		global_position += velocity * delta
		
		# Ground collision check at y = 0.1
		if global_position.y <= 0.15:
			global_position.y = 0.15
			if bounces < 2 and velocity.y < -1.5:
				velocity.y = -velocity.y * 0.4
				velocity.x *= 0.6
				velocity.z *= 0.6
				bounces += 1
			else:
				velocity = Vector3.ZERO
				on_ground = true

func start_vacuum(player: CharacterBody3D) -> void:
	if is_vacuuming:
		return
	is_vacuuming = true
	target_player = player
	vacuum_speed = 6.0
