extends Node3D
class_name Tornado

signal risk_band_entered(band_name: String, multiplier: int)

@export var move_speed: float = 2.5
var travel_dir: Vector3 = Vector3(0, 0, 1)

var rings: Array[MeshInstance3D] = []
var base_radius: float = 2.5
var top_radius: float = 12.0
var funnel_height: float = 36.0

# Risk bands
const BAND_RED = 15.0
const BAND_ORANGE = 25.0
const BAND_YELLOW = 35.0

var current_band: String = "GREEN"
var current_multiplier: int = 1

var cow: FlyingCow

func _ready() -> void:
	add_to_group("tornado")
	_build_funnel_geometry()
	_spawn_flying_cow()

func _build_funnel_geometry() -> void:
	var mat_funnel = StandardMaterial3D.new()
	mat_funnel.albedo_color = Color(0.18, 0.21, 0.24, 0.92)
	mat_funnel.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_funnel.roughness = 0.9
	mat_funnel.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# Build 8 stacked twisting rings
	var ring_count = 9
	for i in range(ring_count):
		var t = float(i) / float(ring_count - 1)
		var ring = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		var r_bot = lerpf(base_radius, top_radius, t)
		var r_top = lerpf(base_radius, top_radius, minf(1.0, t + 1.0 / ring_count))
		cyl.bottom_radius = r_bot
		cyl.top_radius = r_top
		cyl.height = funnel_height / ring_count
		cyl.radial_segments = 16
		
		ring.mesh = cyl
		ring.material_override = mat_funnel
		ring.position = Vector3(0, (i + 0.5) * (funnel_height / ring_count), 0)
		add_child(ring)
		rings.append(ring)

func _spawn_flying_cow() -> void:
	cow = FlyingCow.new()
	add_child(cow)

func _physics_process(delta: float) -> void:
	# Advance funnel along path
	global_position += travel_dir * move_speed * delta
	
	# Churn and snake the funnel rings
	var time = Time.get_ticks_msec() / 1000.0
	for i in range(rings.size()):
		var r = rings[i]
		var t = float(i) / float(rings.size())
		r.rotation.y += delta * (4.0 + (1.0 - t) * 6.0) # Faster spin at bottom
		r.position.x = sin(time * 2.5 + t * 4.0) * (t * 2.2)
		r.position.z = cos(time * 2.0 + t * 3.5) * (t * 2.2)
		
	# Update ground shader risk band position
	_update_environment(delta)
	
	# Tear apart nearby destructibles
	_tear_world_structures()

func _update_environment(delta: float) -> void:
	var player = get_tree().root.find_child("MinifigCharacter", true, false) as MinifigCharacter
	var dist = 999.0
	if is_instance_valid(player):
		dist = global_position.distance_to(player.global_position)
		
		# Wind suction / push on player
		var push_dir = (player.global_position - global_position).normalized()
		push_dir.y = 0.0
		
		var wind_force = 0.0
		var band_name = "GREEN"
		var mult = 1
		
		if dist < BAND_RED:
			band_name = "RED"
			mult = 5
			wind_force = 12.0
		elif dist < BAND_ORANGE:
			band_name = "ORANGE"
			mult = 3
			wind_force = 6.5
		elif dist < BAND_YELLOW:
			band_name = "YELLOW"
			mult = 2
			wind_force = 3.0
			
		# Bill has heavy brace: immune to yellow, resistant to orange
		if not player.is_jo:
			if band_name == "YELLOW":
				wind_force = 0.0
			elif band_name == "ORANGE":
				wind_force *= 0.3
			elif band_name == "RED":
				wind_force *= 0.6
				
		if wind_force > 0.0:
			player.velocity += push_dir * (wind_force * 2.0 * delta)
			
		if band_name != current_band:
			current_band = band_name
			current_multiplier = mult
			risk_band_entered.emit(current_band, current_multiplier)
			
		# Update stud field multiplier
		var economy = get_tree().root.find_child("StudField", true, false) as StudField
		if is_instance_valid(economy):
			economy.set_multiplier(current_multiplier)
			
	# Update synthesizer wind sound
	var synth = SoundSynthesizer.get_instance()
	if is_instance_valid(synth):
		synth.update_wind_proximity(dist)

func _tear_world_structures() -> void:
	var breakables = get_tree().get_nodes_in_group("destructible")
	for b in breakables:
		if b is Node3D and is_instance_valid(b):
			var dist = global_position.distance_to(b.global_position)
			if dist < 16.0:
				if b.has_method("smash"):
					var away = (b.global_position - global_position).normalized() + Vector3(0, 0.6, 0)
					b.smash(away, 14.0)
