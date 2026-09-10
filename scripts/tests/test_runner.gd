extends Node

const MinifigCharacter = preload("res://scripts/actors/minifig_character.gd")
const StudField = preload("res://scripts/economy/stud_field.gd")
const Stud = preload("res://scripts/economy/stud.gd")
const DestructibleObject = preload("res://scripts/world/destructible_building.gd")
const BuildPile = preload("res://scripts/building/build_pile.gd")
const Tornado = preload("res://scripts/storm/tornado.gd")
const FlyingCow = preload("res://scripts/props/flying_cow.gd")
const DorothyPod = preload("res://scripts/props/dorothy_pod.gd")

func _ready() -> void:
	print("==================================================")
	print("   BRICKSTORM GEMINI ENGINE TEST RUNNER (GODOT 4.7) ")
	print("==================================================")
	
	var passed = 0
	var failed = 0
	
	if await _run_test("test_minifig_locomotion_and_swap", Callable(self, "_test_minifig_locomotion_and_swap")):
		passed += 1
	else:
		failed += 1
		
	if await _run_test("test_smash_and_stud_burst", Callable(self, "_test_smash_and_stud_burst")):
		passed += 1
	else:
		failed += 1
		
	if await _run_test("test_bouncing_build_pile", Callable(self, "_test_bouncing_build_pile")):
		passed += 1
	else:
		failed += 1
		
	if await _run_test("test_tornado_vortex_and_risk_bands", Callable(self, "_test_tornado_vortex_and_risk_bands")):
		passed += 1
	else:
		failed += 1
		
	if await _run_test("test_gameplay_soak", Callable(self, "_test_gameplay_soak")):
		passed += 1
	else:
		failed += 1
		
	print("==================================================")
	print("TEST RESULTS: %d PASSED, %d FAILED" % [passed, failed])
	print("==================================================")
	
	if failed > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)

func _run_test(test_name: String, test_func: Callable) -> bool:
	print("[RUNNING] %s..." % test_name)
	var err: String = await test_func.call()
	_cleanup_children()
	await get_tree().process_frame
	await get_tree().process_frame
	if err == "":
		print("[PASS] %s" % test_name)
		return true
	else:
		printerr("[FAIL] %s: %s" % [test_name, err])
		return false

func _cleanup_children() -> void:
	for c in get_children():
		c.queue_free()

func _test_minifig_locomotion_and_swap() -> String:
	var character = MinifigCharacter.new()
	add_child(character)
	await get_tree().process_frame
	
	if not character.is_jo:
		character.queue_free()
		return "Default character should be Jo"
	if character.current_hearts != 4:
		character.queue_free()
		return "Expected 4 hearts default"
	if character.magnet_radius != 8.0:
		character.queue_free()
		return "Expected Jo magnet radius 8.0, got %f" % character.magnet_radius
		
	# Swap to Bill
	character.swap_character()
	if character.is_jo:
		character.queue_free()
		return "Expected character to swap to Bill (is_jo == false)"
	if character.move_speed != 7.5:
		character.queue_free()
		return "Expected Bill move_speed 7.5, got %f" % character.move_speed
	if character.magnet_radius != 4.5:
		character.queue_free()
		return "Expected Bill magnet_radius 4.5, got %f" % character.magnet_radius
		
	# Swap back to Jo
	character.swap_character()
	if not character.is_jo:
		character.queue_free()
		return "Expected character to swap back to Jo"
		
	# Test punch trigger
	character.perform_attack()
	if character.attack_cooldown <= 0.0:
		character.queue_free()
		return "Expected attack cooldown to be active after attack"
		
	character.queue_free()
	await get_tree().process_frame
	return ""

func _test_smash_and_stud_burst() -> String:
	var field = StudField.new()
	add_child(field)
	
	var fence = DestructibleObject.new()
	fence.is_fence = true
	add_child(fence)
	await get_tree().process_frame
	
	# Verify denomination values
	if Stud.Denomination.SILVER != 10 or Stud.Denomination.GOLD != 100 or Stud.Denomination.BLUE != 1000 or Stud.Denomination.PURPLE != 10000:
		field.queue_free()
		fence.queue_free()
		return "Invalid stud denomination canonical values"
		
	# Smash fence
	fence.smash(Vector3.UP, 8.0)
	if not fence.is_smashed:
		field.queue_free()
		return "Fence failed to mark as smashed"
		
	# Test stud collection & multiplier
	field.set_multiplier(3)
	var test_stud = Stud.new()
	test_stud.denomination = Stud.Denomination.GOLD
	add_child(test_stud)
	await get_tree().process_frame
	
	var score_before = field.total_score
	field.collect_stud(test_stud)
	var expected_add = 100 * 3 # 300
	if field.total_score != score_before + expected_add:
		field.queue_free()
		return "Expected total score %d, got %d" % [score_before + expected_add, field.total_score]
		
	field.queue_free()
	await get_tree().process_frame
	return ""

func _test_bouncing_build_pile() -> String:
	var pile = BuildPile.new()
	pile.build_time_required = 0.5
	add_child(pile)
	await get_tree().process_frame
	
	if pile.is_complete:
		pile.queue_free()
		return "Build pile should not start complete"
		
	# Step building
	pile.assemble_step(0.3)
	if pile.build_progress < 0.29:
		pile.queue_free()
		return "Build progress failed to advance"
		
	pile.assemble_step(0.4)
	if not pile.is_complete:
		pile.queue_free()
		return "Build pile failed to complete after full duration"
		
	await get_tree().process_frame
	return ""

func _test_tornado_vortex_and_risk_bands() -> String:
	var tornado = Tornado.new()
	add_child(tornado)
	await get_tree().process_frame
	
	if not is_instance_valid(tornado.cow):
		tornado.queue_free()
		return "Tornado failed to spawn FlyingCow"
		
	if tornado.rings.size() < 8:
		tornado.queue_free()
		return "Expected at least 8 funnel rings, got %d" % tornado.rings.size()
		
	# Verify risk band definitions
	if Tornado.BAND_RED != 15.0 or Tornado.BAND_ORANGE != 25.0 or Tornado.BAND_YELLOW != 35.0:
		tornado.queue_free()
		return "Risk band distance thresholds incorrect"
		
	tornado.queue_free()
	await get_tree().process_frame
	return ""

func _test_gameplay_soak() -> String:
	var main_scene = load("res://scenes/main.tscn")
	if main_scene == null:
		return "Failed to load res://scenes/main.tscn"
		
	var main_node = main_scene.instantiate()
	add_child(main_node)
	
	# Simulate 120 live game frames
	for i in range(120):
		await get_tree().physics_frame
		
	main_node.queue_free()
	await get_tree().process_frame
	return ""
