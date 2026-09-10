extends Node3D
class_name StudField

signal studs_changed(total_score: int, multiplier: int, true_chaser_pct: float)
signal true_chaser_achieved()

var total_score: int = 0
var current_multiplier: int = 1
var true_chaser_target: int = 3500
var true_chaser_unlocked: bool = false

var active_studs: Array[Stud] = []

func _ready() -> void:
	pass

func spawn_stud_burst(origin: Vector3, silver_count: int = 4, gold_count: int = 1, blue_count: int = 0) -> void:
	# Silver studs
	for i in range(silver_count):
		_spawn_single_stud(origin, Stud.Denomination.SILVER)
	# Gold studs
	for i in range(gold_count):
		_spawn_single_stud(origin, Stud.Denomination.GOLD)
	# Blue studs
	for i in range(blue_count):
		_spawn_single_stud(origin, Stud.Denomination.BLUE)

func _spawn_single_stud(origin: Vector3, denom: Stud.Denomination) -> void:
	var s = Stud.new()
	s.denomination = denom
	add_child(s)
	s.launch_fountain(origin + Vector3(0, 0.4, 0))
	active_studs.append(s)

func collect_stud(stud: Stud) -> void:
	var added = stud.value * current_multiplier
	total_score += added
	active_studs.erase(stud)
	stud.queue_free()
	
	# Play chime with synthesizer
	var synth = SoundSynthesizer.get_instance()
	if is_instance_valid(synth):
		synth.play_stud_pickup(current_multiplier)
		
	var pct = clampf(float(total_score) / float(true_chaser_target), 0.0, 1.0)
	studs_changed.emit(total_score, current_multiplier, pct)
	
	if pct >= 1.0 and not true_chaser_unlocked:
		true_chaser_unlocked = true
		true_chaser_achieved.emit()
		if is_instance_valid(synth):
			synth.play_true_chaser_fanfare()

func set_multiplier(multiplier: int) -> void:
	if current_multiplier != multiplier:
		current_multiplier = multiplier
		var pct = clampf(float(total_score) / float(true_chaser_target), 0.0, 1.0)
		studs_changed.emit(total_score, current_multiplier, pct)

func update_magnet(player: CharacterBody3D, magnet_radius: float) -> void:
	if not is_instance_valid(player):
		return
	var p_pos = player.global_position
	for s in active_studs:
		if is_instance_valid(s) and not s.is_vacuuming:
			if s.global_position.distance_to(p_pos) <= magnet_radius:
				s.start_vacuum(player)
