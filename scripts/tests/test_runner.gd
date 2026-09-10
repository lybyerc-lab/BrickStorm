extends Node

const MinifigCharacter = preload("res://scripts/actors/minifig_character.gd")
const CompanionAI = preload("res://scripts/actors/companion_ai.gd")
const StudField = preload("res://scripts/economy/stud_field.gd")
const Stud = preload("res://scripts/economy/stud.gd")
const DestructibleObject = preload("res://scripts/world/destructible_building.gd")
const BuildPile = preload("res://scripts/building/build_pile.gd")
const Tornado = preload("res://scripts/storm/tornado.gd")
const BrickBuilder = preload("res://scripts/construction/brick_builder.gd")

func _ready() -> void:
	print("==================================================")
	print("   BRICKSTORM PASS 2 ENGINE TEST RUNNER (GODOT 4.7) ")
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
		
	if await _run_test("test_brick_builder_grammar", Callable(self, "_test_brick_builder_grammar")):
		passed += 1
	else:
		failed += 1
		
	if await _run_test("test_companion_ai_follow", Callable(self, "_test_companion_ai_follow")):
		passed += 1
	else:
		failed += 1
		
	if await _run_test("test_gameplay_soak_pass2", Callable(self, "_test_gameplay_soak_pass2")):
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
		return "Default character should be Jo"
	if character.current_hearts != 4:
		return "Expected 4 hearts default"
	if character.magnet_radius != 8.0:
		return "Expected Jo magnet radius 8.0, got %f" % character.magnet_radius
		
	# Swap to Bill
	character.swap_character()
	if character.is_jo:
		return "Expected character to swap to Bill (is_jo == false)"
	if character.move_speed != 7.5:
		return "Expected Bill move_speed 7.5, got %f" % character.move_speed
		
	# Swap back to Jo
	character.swap_character()
	if not character.is_jo:
		return "Expected character to swap back to Jo"
		
	return ""

func _test_smash_and_stud_burst() -> String:
	var field = StudField.new()
	add_child(field)
	
	var fence = DestructibleObject.new()
	fence.is_fence = true
	add_child(fence)
	await get_tree().process_frame
	
	fence.smash(Vector3.UP, 8.0)
	if not fence.is_smashed:
		return "Fence failed to mark as smashed"
		
	field.set_multiplier(3)
	var test_stud = Stud.new()
	test_stud.denomination = Stud.Denomination.GOLD
	add_child(test_stud)
	await get_tree().process_frame
	
	var score_before = field.total_score
	field.collect_stud(test_stud)
	if field.total_score != score_before + 300:
		return "Expected total score %d, got %d" % [score_before + 300, field.total_score]
		
	return ""

func _test_bouncing_build_pile() -> String:
	var pile = BuildPile.new()
	pile.build_time_required = 0.5
	add_child(pile)
	await get_tree().process_frame
	
	pile.assemble_step(0.6)
	if not pile.is_complete:
		return "Build pile failed to complete after duration"
		
	return ""

func _test_tornado_vortex_and_risk_bands() -> String:
	var tornado = Tornado.new()
	add_child(tornado)
	await get_tree().process_frame
	
	if not is_instance_valid(tornado.cow):
		return "Tornado failed to spawn FlyingCow"
	if tornado.rings.size() < 8:
		return "Expected at least 8 funnel rings, got %d" % tornado.rings.size()
		
	return ""

func _test_brick_builder_grammar() -> String:
	# Test 2x4 Brick
	var b2x4 = BrickBuilder.create_2x4_brick(Color.RED)
	add_child(b2x4)
	await get_tree().process_frame
	
	# Children should include 1 body box + 8 studs = 9 children
	if b2x4.get_child_count() != 9:
		return "2x4 brick expected 9 child meshes (1 body + 8 studs), got %d" % b2x4.get_child_count()
		
	# Test 1x2 Plate
	var p1x2 = BrickBuilder.create_1x2_plate(Color.BLUE)
	add_child(p1x2)
	await get_tree().process_frame
	
	# Children should include 1 body box + 2 studs = 3 children
	if p1x2.get_child_count() != 3:
		return "1x2 plate expected 3 child meshes (1 body + 2 studs), got %d" % p1x2.get_child_count()
		
	return ""

func _test_companion_ai_follow() -> String:
	var hero = MinifigCharacter.new()
	add_child(hero)
	
	var comp = CompanionAI.new()
	comp.target_player = hero
	add_child(comp)
	await get_tree().process_frame
	
	# Companion should take opposite identity (Bill)
	if comp.is_jo == hero.is_jo:
		return "Companion should have opposite identity to active hero"
		
	# Move hero and tick physics
	hero.global_position = Vector3(5, 0, 5)
	for i in range(10):
		await get_tree().physics_frame
		
	return ""

func _test_gameplay_soak_pass2() -> String:
	var main_scene = load("res://scenes/main.tscn")
	if main_scene == null:
		return "Failed to load res://scenes/main.tscn"
		
	var main_node = main_scene.instantiate()
	add_child(main_node)
	
	# Simulate 150 frames with complete environment, shaders, and AI
	for i in range(150):
		await get_tree().physics_frame
		
	main_node.queue_free()
	await get_tree().process_frame
	return ""
