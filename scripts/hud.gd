# Two thumbs, no camera control, one context button (Docs/GAME_CONCEPT.md §8).
class_name HUD
extends CanvasLayer

signal context_pressed
signal context_released
signal swap_to(character: int)
signal ability_pressed

const BAND_COLOURS := [
	Color(0.72, 0.86, 0.55),   # green  x1
	Color(0.98, 0.82, 0.16),   # yellow x2
	Color(0.96, 0.55, 0.12),   # orange x3
	Color(0.95, 0.22, 0.18),   # red    x5
]

var stick: VirtualStick
var mult_label: Label
var studs_label: Label
var objective_label: Label
var toast_label: Label
var ctx_panel: Panel
var ctx_label: Label
var portraits: Array = []

var _ctx_touch: int = -1
var _toast_timer: float = 0.0


func _ready() -> void:
	layer = 10
	_build_readouts()
	_build_stick()
	_build_context_button()
	_build_portraits()


func _mk_label(text: String, size_px: int, colour: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", colour)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08, 0.9))
	l.add_theme_constant_override("outline_size", maxi(4, size_px / 8))
	return l


# ============================================================================
# [BS:UI:HUD]
# Purpose: HUD readouts and layout.
# Invariants:
# - The HUD supports the scene rather than covering it (North Star
#   screenshot checklist).
# - Landscape only. Layout assumes a wider-than-tall viewport.
# ============================================================================
func _build_readouts() -> void:
	mult_label = _mk_label("x1", 78, BAND_COLOURS[0])
	mult_label.position = Vector2(28, 10)
	mult_label.pivot_offset = Vector2(0, 40)
	add_child(mult_label)

	studs_label = _mk_label("STUDS 0", 30, Color(0.98, 0.85, 0.30))
	studs_label.position = Vector2(34, 112)
	add_child(studs_label)

	objective_label = _mk_label("", 26, Color(0.95, 0.96, 0.98))
	objective_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.position = Vector2(0, 22)
	add_child(objective_label)

	toast_label = _mk_label("", 40, Color(1, 1, 1))
	toast_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.position = Vector2(0, 150)
	toast_label.modulate.a = 0.0
	add_child(toast_label)
# [BS:UI:HUD:END]


func _build_stick() -> void:
	stick = VirtualStick.new()
	stick.set_anchors_preset(Control.PRESET_FULL_RECT)
	stick.anchor_right = 0.46
	stick.anchor_top = 0.30
	add_child(stick)


# ============================================================================
# [BS:UI:CONTEXT_BUTTON]
# Purpose: The single context button whose meaning changes by proximity.
# Invariants:
# - ONE button. Its label always states what it will do right now:
#   SMASH / BUILD / GRAB / BRACE / DEPLOY.
# - Everything must be reachable by a right thumb in landscape
#   (pillar 6). Do not add a second action button.
# ============================================================================
func _build_context_button() -> void:
	ctx_panel = Panel.new()
	ctx_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ctx_panel.size = Vector2(168, 168)
	ctx_panel.position = Vector2(-208, -206)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.80, 0.12, 0.30)
	sb.border_color = Color(1, 1, 1, 0.55)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(84)
	ctx_panel.add_theme_stylebox_override("panel", sb)
	ctx_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	ctx_panel.gui_input.connect(_on_ctx_input)
	add_child(ctx_panel)

	ctx_label = _mk_label("SMASH", 26, Color(1, 1, 1))
	ctx_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctx_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ctx_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ctx_panel.add_child(ctx_label)
# [BS:UI:CONTEXT_BUTTON:END]


# ============================================================================
# [BS:UI:SWAP]
# Purpose: Character portraits - swap is one tap, never a menu.
# Invariants:
# - The active character is always visually obvious.
# ============================================================================
func _build_portraits() -> void:
	var names := ["JO", "BILL"]
	var cols := [BrickLib.C_BLUE, BrickLib.C_LGREY]
	for i in range(2):
		var p := Panel.new()
		p.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		p.size = Vector2(104, 104)
		p.position = Vector2(-230 + i * 114, 16)
		var sb := StyleBoxFlat.new()
		sb.bg_color = cols[i]
		sb.border_color = Color(1, 1, 1, 0.35)
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(14)
		p.add_theme_stylebox_override("panel", sb)
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		var idx := i
		p.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventScreenTouch and e.pressed:
				swap_to.emit(idx))
		add_child(p)

		var l := _mk_label(names[i], 22, Color(1, 1, 1))
		l.set_anchors_preset(Control.PRESET_FULL_RECT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		p.add_child(l)
		portraits.append(p)
# [BS:UI:SWAP:END]


func _on_ctx_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _ctx_touch == -1:
			_ctx_touch = event.index
			context_pressed.emit()
		elif not event.pressed and event.index == _ctx_touch:
			_ctx_touch = -1
			context_released.emit()


func set_active_character(c: int) -> void:
	for i in range(portraits.size()):
		portraits[i].modulate = Color(1, 1, 1, 1.0) if i == c else Color(0.55, 0.55, 0.6, 0.8)


# ============================================================================
# [BS:UI:MULTIPLIER]
# Purpose: The multiplier: the dominant HUD element and the movie's thesis.
# Invariants:
# - It must remain the largest, most legible thing on screen
#   (pillar 5). Do not demote it to make room for anything.
# - Scale, never font-size, on change: resizing the font reflows the
#   label and walks it over the stud counter. This has already been a
#   bug once.
# - Colour comes from the band, matching the rings on the ground.
# ============================================================================
func set_band(band: int, multiplier: int) -> void:
	mult_label.text = "x%d" % multiplier
	mult_label.add_theme_color_override("font_color", BAND_COLOURS[clampi(band, 0, 3)])
	# scale rather than resize: a font-size change reflows the label and walks
	# it over the stud counter
	var k: float = 1.0 + float(band) * 0.09
	mult_label.scale = mult_label.scale.lerp(Vector2(k, k), 0.25)
# [BS:UI:MULTIPLIER:END]


func set_studs(n: int) -> void:
	studs_label.text = "STUDS %s" % _commas(n)


func set_context(text: String) -> void:
	ctx_label.text = text


func set_objective(text: String) -> void:
	objective_label.text = text


func toast(text: String, colour: Color = Color(1, 1, 1)) -> void:
	toast_label.text = text
	toast_label.add_theme_color_override("font_color", colour)
	toast_label.modulate.a = 1.0
	_toast_timer = 2.2


func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer < 0.7:
			toast_label.modulate.a = maxf(0.0, _toast_timer / 0.7)


static func _commas(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if n < 0 else "") + out
