# Floating virtual stick: it appears wherever the thumb lands, which is the only
# version of this control that works on a phone you are not looking down at.
class_name VirtualStick
extends Control

const RADIUS := 86.0

var value := Vector2.ZERO
var _touch_id: int = -1
var _centre := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id == -1:
			_touch_id = event.index
			_centre = event.position
			_set_from(event.position)
		elif not event.pressed and event.index == _touch_id:
			_touch_id = -1
			value = Vector2.ZERO
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_set_from(event.position)


func _set_from(p: Vector2) -> void:
	var d := p - _centre
	if d.length() > RADIUS:
		d = d.normalized() * RADIUS
		# drag the origin along so the stick never feels stuck
		_centre = p - d
	value = d / RADIUS
	queue_redraw()


func _draw() -> void:
	if _touch_id == -1:
		var hint := Vector2(size.x * 0.32, size.y * 0.62)
		draw_arc(hint, RADIUS * 0.7, 0.0, TAU, 40, Color(1, 1, 1, 0.10), 3.0, true)
		return
	draw_circle(_centre, RADIUS, Color(0.05, 0.06, 0.09, 0.28))
	draw_arc(_centre, RADIUS, 0.0, TAU, 44, Color(1, 1, 1, 0.22), 3.0, true)
	draw_circle(_centre + value * RADIUS, 36.0, Color(0.98, 0.80, 0.12, 0.80))
