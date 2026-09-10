extends SceneTree

func _init() -> void:
	var main_scene = load("res://scenes/main.tscn")
	var main_node = main_scene.instantiate()
	root.add_child(main_node)
	
	# Wait for 30 frames
	for i in range(30):
		await process_frame
		
	var img = root.get_texture().get_image()
	if img != null:
		img.save_png("test_capture_pass2.png")
		print("Screenshot saved to test_capture_pass2.png")
	else:
		print("Could not get image")
	quit(0)
