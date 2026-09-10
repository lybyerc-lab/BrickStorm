extends Node3D
class_name ComicPopup

static func spawn(parent: Node, pos: Vector3, text: String = "SMASH!") -> void:
	var popup = Node3D.new()
	parent.add_child(popup)
	popup.global_position = pos + Vector3(randf_range(-0.3, 0.3), 1.2, randf_range(-0.3, 0.3))
	
	var label = Label3D.new()
	label.text = text
	label.font_size = 48
	label.outline_size = 12
	label.outline_modulate = Color(0.1, 0.1, 0.1)
	
	# Comic book colors: bright punchy yellow or orange
	var colors = [Color(1.0, 0.85, 0.1), Color(1.0, 0.45, 0.1), Color(0.2, 0.9, 1.0), Color(1.0, 0.25, 0.4)]
	label.modulate = colors[randi() % colors.size()]
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	popup.add_child(label)
	
	# Punchy pop & float animation
	popup.scale = Vector3(0.2, 0.2, 0.2)
	var tween = popup.create_tween()
	tween.tween_property(popup, "scale", Vector3(1.4, 1.4, 1.4), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(popup, "position:y", popup.position.y + 0.8, 0.5)
	tween.tween_property(popup, "scale", Vector3(0.0, 0.0, 0.0), 0.18).set_delay(0.2)
	tween.tween_callback(popup.queue_free)
