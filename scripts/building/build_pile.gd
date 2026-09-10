extends Node3D
class_name BuildPile

signal build_completed(constructed_node: Node3D)

@export var build_target_scene: PackedScene
@export var build_time_required: float = 2.0
var build_progress: float = 0.0
var is_complete: bool = false

var loose_bricks: Array[MeshInstance3D] = []
var brick_offsets: Array[float] = []

var prompt_label: Label3D
var click_timer: float = 0.0

func _ready() -> void:
	add_to_group("build_pile")
	_create_loose_brick_pile()
	_create_prompt()

func _create_loose_brick_pile() -> void:
	var colors = [
		Color(0.9, 0.15, 0.15), # Red
		Color(0.95, 0.82, 0.1), # Yellow
		Color(0.15, 0.45, 0.9), # Blue
		Color(0.2, 0.75, 0.2),  # Green
		Color(0.85, 0.85, 0.85) # White
	]
	
	for i in range(8):
		var mesh_inst = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(randf_range(0.3, 0.5), randf_range(0.15, 0.25), randf_range(0.25, 0.4))
		mesh_inst.mesh = box
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = colors[i % colors.size()]
		mat.roughness = 0.25
		mesh_inst.material_override = mat
		
		var angle = randf() * TAU
		var dist = randf_range(0.2, 0.8)
		mesh_inst.position = Vector3(cos(angle) * dist, 0.1, sin(angle) * dist)
		mesh_inst.rotation = Vector3(randf_range(-0.3, 0.3), randf() * TAU, randf_range(-0.3, 0.3))
		add_child(mesh_inst)
		
		loose_bricks.append(mesh_inst)
		brick_offsets.append(randf() * TAU)

func _create_prompt() -> void:
	prompt_label = Label3D.new()
	prompt_label.text = "[HOLD BUILD]"
	prompt_label.font_size = 38
	prompt_label.outline_size = 8
	prompt_label.modulate = Color(1.0, 0.9, 0.2)
	prompt_label.position = Vector3(0, 1.4, 0)
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(prompt_label)

func _process(delta: float) -> void:
	if is_complete:
		return
		
	var time = Time.get_ticks_msec() / 1000.0
	
	# Bouncing animation for loose bricks
	for i in range(loose_bricks.size()):
		var b = loose_bricks[i]
		var offset = brick_offsets[i]
		var bounce = abs(sin(time * 7.0 + offset)) * 0.18
		b.position.y = 0.1 + bounce
		b.rotation.y += delta * 1.5
		
	# Float & pulse the prompt label
	prompt_label.position.y = 1.4 + sin(time * 3.0) * 0.1
	if build_progress > 0.0:
		prompt_label.text = "BUILDING... %d%%" % int(build_progress * 100.0)
		prompt_label.modulate = Color(0.3, 1.0, 0.4)
	else:
		prompt_label.text = "[HOLD BUILD]"
		prompt_label.modulate = Color(1.0, 0.9, 0.2)

func assemble_step(delta: float) -> void:
	if is_complete:
		return
		
	build_progress += delta / build_time_required
	click_timer += delta
	if click_timer >= 0.12:
		click_timer = 0.0
		var synth = SoundSynthesizer.get_instance()
		if is_instance_valid(synth):
			synth.play_build_click()
			
	# Move loose bricks toward center as progress completes
	for b in loose_bricks:
		b.position.x = lerpf(b.position.x, 0.0, delta * 3.0)
		b.position.z = lerpf(b.position.z, 0.0, delta * 3.0)
		
	if build_progress >= 1.0:
		_complete_assembly()

func _complete_assembly() -> void:
	is_complete = true
	prompt_label.queue_free()
	
	# Spawn reward studs!
	var economy = get_tree().root.find_child("StudField", true, false) as StudField
	if is_instance_valid(economy):
		economy.spawn_stud_burst(global_position, 6, 2, 1) # Goodies!
		
	# Spawn the built target
	var constructed_inst: Node3D = null
	if build_target_scene != null:
		constructed_inst = build_target_scene.instantiate() as Node3D
		if is_instance_valid(constructed_inst):
			get_parent().add_child(constructed_inst)
			constructed_inst.global_position = global_position
			constructed_inst.global_rotation = global_rotation
			
	build_completed.emit(constructed_inst)
	
	# Disperse loose bricks with poof
	for b in loose_bricks:
		b.queue_free()
	loose_bricks.clear()
	
	queue_free()
