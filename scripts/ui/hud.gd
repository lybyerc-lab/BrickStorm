extends CanvasLayer
class_name GameHUD

# UI Nodes
var portrait_label: Label
var character_name_label: Label
var hearts_container: HBoxContainer
var heart_icons: Array[ColorRect] = []

var true_chaser_bar: ProgressBar
var true_chaser_label: Label

var stud_label: Label
var multiplier_label: Label
var objective_label: Label

# Mobile touch controls
var touch_root: Control
var stick_base: Control
var stick_knob: Control
var stick_active: bool = false
var stick_touch_id: int = -1
var stick_center: Vector2 = Vector2.ZERO
var stick_vector: Vector2 = Vector2.ZERO

var btn_smash: Button
var btn_build: Button
var btn_jump: Button
var btn_swap: Button

var target_player: MinifigCharacter

func _ready() -> void:
	_create_ui_layout()
	_connect_events()

func _create_ui_layout() -> void:
	# Top bar container
	var top_bar = Control.new()
	top_bar.name = "TopBar"
	top_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_bar)

	# --- TOP LEFT: Character & Hearts ---
	var char_panel = PanelContainer.new()
	char_panel.position = Vector2(24, 20)
	char_panel.custom_minimum_size = Vector2(220, 80)
	top_bar.add_child(char_panel)
	
	var char_vbox = VBoxContainer.new()
	char_panel.add_child(char_vbox)
	
	var char_header = HBoxContainer.new()
	char_vbox.add_child(char_header)
	
	portrait_label = Label.new()
	portrait_label.text = "🤠"
	portrait_label.add_theme_font_size_override("font_size", 28)
	char_header.add_child(portrait_label)
	
	character_name_label = Label.new()
	character_name_label.text = "JO [READER]"
	character_name_label.add_theme_font_size_override("font_size", 20)
	char_header.add_child(character_name_label)
	
	btn_swap = Button.new()
	btn_swap.text = "SWAP [U]"
	btn_swap.pressed.connect(_on_swap_pressed)
	char_header.add_child(btn_swap)
	
	hearts_container = HBoxContainer.new()
	char_vbox.add_child(hearts_container)
	for i in range(4):
		var h = ColorRect.new()
		h.custom_minimum_size = Vector2(22, 22)
		h.color = Color(1.0, 0.2, 0.2)
		hearts_container.add_child(h)
		heart_icons.append(h)

	# --- TOP CENTER: True Chaser Bar ---
	var tc_box = VBoxContainer.new()
	tc_box.position = Vector2(460, 16)
	tc_box.custom_minimum_size = Vector2(360, 50)
	top_bar.add_child(tc_box)
	
	true_chaser_label = Label.new()
	true_chaser_label.text = "★ TRUE CHASER ★"
	true_chaser_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	true_chaser_label.add_theme_font_size_override("font_size", 16)
	tc_box.add_child(true_chaser_label)
	
	true_chaser_bar = ProgressBar.new()
	true_chaser_bar.max_value = 100.0
	true_chaser_bar.value = 0.0
	true_chaser_bar.show_percentage = false
	true_chaser_bar.custom_minimum_size = Vector2(360, 18)
	tc_box.add_child(true_chaser_bar)

	# --- TOP RIGHT: Studs & Multiplier ---
	var stud_box = VBoxContainer.new()
	stud_box.position = Vector2(980, 20)
	stud_box.custom_minimum_size = Vector2(260, 80)
	top_bar.add_child(stud_box)
	
	var stud_row = HBoxContainer.new()
	stud_box.add_child(stud_row)
	
	var stud_icon = Label.new()
	stud_icon.text = "🟡 STUDS:"
	stud_icon.add_theme_font_size_override("font_size", 22)
	stud_row.add_child(stud_icon)
	
	stud_label = Label.new()
	stud_label.text = "0"
	stud_label.add_theme_font_size_override("font_size", 28)
	stud_row.add_child(stud_label)
	
	multiplier_label = Label.new()
	multiplier_label.text = "MULTIPLIER: x1 [GREEN ZONE]"
	multiplier_label.add_theme_font_size_override("font_size", 16)
	multiplier_label.modulate = Color(0.3, 1.0, 0.4)
	stud_box.add_child(multiplier_label)

	# --- OBJECTIVE BANNER ---
	objective_label = Label.new()
	objective_label.text = "MISSION: Smash debris, assemble DOROTHY, and deploy into the STORM!"
	objective_label.position = Vector2(240, 90)
	objective_label.custom_minimum_size = Vector2(800, 30)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 18)
	objective_label.modulate = Color(1.0, 0.95, 0.5)
	top_bar.add_child(objective_label)

	# --- MOBILE TOUCH CONTROLS OVERLAY ---
	_setup_touch_controls()

func _setup_touch_controls() -> void:
	touch_root = Control.new()
	touch_root.name = "TouchControls"
	touch_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	touch_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(touch_root)

	# Virtual joystick area in bottom-left
	stick_base = Panel.new()
	stick_base.position = Vector2(80, 480)
	stick_base.custom_minimum_size = Vector2(160, 160)
	stick_base.modulate = Color(1, 1, 1, 0.4)
	touch_root.add_child(stick_base)
	stick_center = stick_base.position + Vector2(80, 80)

	stick_knob = ColorRect.new()
	stick_knob.size = Vector2(60, 60)
	stick_knob.position = Vector2(50, 50)
	stick_knob.color = Color(1, 1, 1, 0.7)
	stick_base.add_child(stick_knob)

	# Touch Action Buttons in bottom-right
	btn_smash = Button.new()
	btn_smash.text = "SMASH\n[J / Click]"
	btn_smash.position = Vector2(980, 540)
	btn_smash.custom_minimum_size = Vector2(110, 110)
	btn_smash.button_down.connect(func(): if is_instance_valid(target_player): target_player.touch_smash_pressed = true)
	touch_root.add_child(btn_smash)

	btn_build = Button.new()
	btn_build.text = "BUILD\n[E / Hold]"
	btn_build.position = Vector2(1110, 460)
	btn_build.custom_minimum_size = Vector2(110, 110)
	btn_build.button_down.connect(func(): if is_instance_valid(target_player): target_player.touch_build_held = true)
	btn_build.button_up.connect(func(): if is_instance_valid(target_player): target_player.touch_build_held = false)
	touch_root.add_child(btn_build)

	btn_jump = Button.new()
	btn_jump.text = "JUMP\n[Space]"
	btn_jump.position = Vector2(1110, 590)
	btn_jump.custom_minimum_size = Vector2(110, 80)
	btn_jump.button_down.connect(func(): if is_instance_valid(target_player): target_player.touch_jump_pressed = true)
	touch_root.add_child(btn_jump)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		var pos = event.position
		if event.is_pressed():
			# Check left side of screen for joystick
			if pos.x < 450 and pos.y > 350:
				stick_active = true
				_update_stick(pos)
		else:
			stick_active = false
			stick_vector = Vector2.ZERO
			stick_knob.position = Vector2(50, 50)
			if is_instance_valid(target_player):
				target_player.touch_move_vector = Vector2.ZERO
				
	elif event is InputEventScreenDrag or (event is InputEventMouseMotion and stick_active):
		if stick_active:
			_update_stick(event.position)

func _update_stick(touch_pos: Vector2) -> void:
	var delta = touch_pos - stick_center
	var max_radius = 65.0
	if delta.length() > max_radius:
		delta = delta.normalized() * max_radius
	stick_knob.position = Vector2(50, 50) + delta
	stick_vector = delta / max_radius
	if is_instance_valid(target_player):
		target_player.touch_move_vector = stick_vector

func _connect_events() -> void:
	target_player = get_tree().root.find_child("MinifigCharacter", true, false) as MinifigCharacter
	if is_instance_valid(target_player):
		target_player.character_swapped.connect(_on_character_swapped)
		target_player.health_changed.connect(_on_health_changed)
		_on_character_swapped(target_player.is_jo)
		_on_health_changed(target_player.current_hearts, target_player.max_hearts)
		
	var economy = get_tree().root.find_child("StudField", true, false) as StudField
	if is_instance_valid(economy):
		economy.studs_changed.connect(_on_studs_changed)
		economy.true_chaser_achieved.connect(_on_true_chaser_achieved)
		
	var tornado = get_tree().root.find_child("Tornado", true, false) as Tornado
	if is_instance_valid(tornado):
		tornado.risk_band_entered.connect(_on_risk_band_entered)

func _on_swap_pressed() -> void:
	if is_instance_valid(target_player):
		target_player.swap_character()

func _on_character_swapped(is_jo: bool) -> void:
	if is_jo:
		portrait_label.text = "🤠"
		character_name_label.text = "JO [READER]"
		character_name_label.modulate = Color(0.4, 0.7, 1.0)
	else:
		portrait_label.text = "🧢"
		character_name_label.text = "BILL [EXTREME]"
		character_name_label.modulate = Color(1.0, 0.7, 0.3)

func _on_health_changed(hearts: int, max_h: int) -> void:
	for i in range(heart_icons.size()):
		if i < hearts:
			heart_icons[i].color = Color(1.0, 0.2, 0.2)
		else:
			heart_icons[i].color = Color(0.2, 0.2, 0.2, 0.4) # Empty heart

func _on_studs_changed(total: int, mult: int, pct: float) -> void:
	stud_label.text = "%d" % total
	true_chaser_bar.value = pct * 100.0
	
	# Scale animation bounce on stud count
	var tween = create_tween()
	stud_label.scale = Vector2(1.2, 1.2)
	tween.tween_property(stud_label, "scale", Vector2(1.0, 1.0), 0.15)

func _on_risk_band_entered(band: String, mult: int) -> void:
	match band:
		"GREEN":
			multiplier_label.text = "MULTIPLIER: x1 [GREEN ZONE]"
			multiplier_label.modulate = Color(0.3, 1.0, 0.4)
		"YELLOW":
			multiplier_label.text = "MULTIPLIER: x2 [YELLOW ZONE - GUSTS]"
			multiplier_label.modulate = Color(1.0, 0.9, 0.2)
		"ORANGE":
			multiplier_label.text = "MULTIPLIER: x3 [ORANGE ZONE - GALE!]"
			multiplier_label.modulate = Color(1.0, 0.55, 0.1)
		"RED":
			multiplier_label.text = "★ MULTIPLIER: x5 [RED CORE - EXTREME!] ★"
			multiplier_label.modulate = Color(1.0, 0.2, 0.2)

func _on_true_chaser_achieved() -> void:
	true_chaser_label.text = "🎉 TRUE CHASER COMPLETE! 🎉"
	true_chaser_label.modulate = Color(1.0, 0.9, 0.1)
	objective_label.text = "★ TRUE CHASER UNLOCKED! NOW DEPLOY DOROTHY! ★"
	objective_label.modulate = Color(1.0, 0.9, 0.2)
