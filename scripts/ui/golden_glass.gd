class_name GoldenGlass
extends Control
## The golden glass: a shining glass of tea that floats over the street for a
## few seconds. Click it before it fades for a bonus or a helper frenzy.

signal clicked

const SIZE := Vector2(30, 34)

var _left := 0.0
var _time := 0.0


func _init() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = MOUSE_FILTER_STOP
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
	visible = false


## Places the glass at "spot" (0..1 across the parent) for "seconds".
func appear(spot: Vector2, seconds: float) -> void:
	var area := get_parent_area_size()
	position = Vector2(lerpf(30.0, area.x - 30.0 - SIZE.x, spot.x), lerpf(24.0, area.y * 0.55, spot.y))
	_left = seconds
	_time = 0.0
	visible = true
	scale = Vector2.ZERO
	pivot_offset = SIZE / 2.0
	create_tween().tween_property(self, "scale", Vector2(1.4, 1.4), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func vanish() -> void:
	_left = 0.0
	visible = false


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	_left -= delta
	if _left <= 0.0:
		visible = false
		return
	# Fades and blinks in its last two seconds.
	modulate.a = 1.0 if _left > 2.0 else 0.4 + 0.6 * absf(sin(_time * 10.0))
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		clicked.emit()


func _draw() -> void:
	var center := SIZE / 2.0 + Vector2(0, sin(_time * 3.0) * 2.0)
	# Turning rays behind the glass.
	for i in 8:
		var angle := _time * 0.8 + i * TAU / 8.0
		var tip := center + Vector2(cos(angle), sin(angle)) * 16.0
		var side := Vector2(cos(angle + 0.18), sin(angle + 0.18)) * 9.0
		draw_colored_polygon(PackedVector2Array([center, tip, center + side]), Color(1.0, 0.85, 0.35, 0.35))
	draw_circle(center, 10.0, Color(1.0, 0.9, 0.5, 0.35))
	# The glass: a tapered tumbler with golden tea and froth.
	var top := center + Vector2(0, -8)
	var glass := PackedVector2Array([top + Vector2(-6, 0), top + Vector2(6, 0), top + Vector2(4.5, 15), top + Vector2(-4.5, 15)])
	draw_colored_polygon(glass, Color("f2c14e"))
	draw_colored_polygon(PackedVector2Array([top + Vector2(-5.6, 2), top + Vector2(5.6, 2), top + Vector2(4.5, 15), top + Vector2(-4.5, 15)]), Color("d98e1f"))
	draw_rect(Rect2(top + Vector2(-5.6, 1), Vector2(11.2, 2)), Color("fff1c4"))
	draw_polyline(PackedVector2Array([glass[0], glass[3], glass[2], glass[1]]), Color("6b3f10"), 1.0)
	draw_line(top + Vector2(-3, 4), top + Vector2(-2.4, 12), Color(1, 1, 1, 0.7), 1.0)
	# A twinkle.
	var twinkle := center + Vector2(9, -10)
	var pulse := 2.0 + sin(_time * 6.0) * 1.2
	draw_line(twinkle - Vector2(pulse, 0), twinkle + Vector2(pulse, 0), Color.WHITE, 1.0)
	draw_line(twinkle - Vector2(0, pulse), twinkle + Vector2(0, pulse), Color.WHITE, 1.0)
