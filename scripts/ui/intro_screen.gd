class_name IntroScreen
extends Control
## The opening story, before day 1: four short illustrated cards about why
## you're running a tea kadai. Next to move on, Skip to jump to the market.

signal finished

const CARDS: Array[String] = [
	"Six years in an IT office. Reports, meetings, and reports about meetings.",
	"One Monday you closed the laptop for good. You had ₹300, an old stove, and a corner on a busy Chennai street.",
	"Appa thinks you've lost your mind. Amma packed a flask of decoction. \"For luck,\" she said.",
	"Day one. The street is waking up. Let's make some tea.",
]

var _index := 0
var _art: Control
var _text: Label
var _next: Button
var _time := 0.0


func _ready() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	_art = Control.new()
	_art.custom_minimum_size = Vector2(400, 150)
	_art.draw.connect(_draw_art)
	box.add_child(_art)
	_text = Style.paragraph("", 400.0, Style.TEXT)
	_text.add_theme_font_size_override("font_size", 12)
	_text.custom_minimum_size.y = 44
	box.add_child(_text)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var skip := Style.button("Skip", _finish, true)
	row.add_child(skip)
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(spacer)
	_next = Style.button("", _advance)
	row.add_child(_next)
	box.add_child(row)
	_show_card()


func _process(delta: float) -> void:
	_time += delta
	_art.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("tea") or (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER):
		_advance()
		get_viewport().set_input_as_handled()


func _advance() -> void:
	if _index >= CARDS.size() - 1:
		_finish()
		return
	_index += 1
	_show_card()


func _finish() -> void:
	set_process_unhandled_input(false)
	finished.emit()


func _show_card() -> void:
	_text.text = CARDS[_index]
	_next.text = "Open the kadai →" if _index == CARDS.size() - 1 else "Next →"
	_time = 0.0
	_text.visible_ratio = 0.0
	create_tween().tween_property(_text, "visible_ratio", 1.0, 0.6)


func _draw_art() -> void:
	var size := _art.size
	_art.draw_rect(Rect2(Vector2.ZERO, size), Style.PANEL_DARK)
	match _index:
		0:
			_draw_office(size)
		1:
			_draw_stove(size)
		2:
			_draw_flask(size)
		_:
			_draw_dawn(size)
	_art.draw_rect(Rect2(Vector2.ZERO, size), Style.WOOD_EDGE, false, 2.0)


func _draw_office(size: Vector2) -> void:
	_art.draw_rect(Rect2(0, 0, size.x, size.y), Color("2a3a48"))
	_art.draw_rect(Rect2(0, size.y - 40, size.x, 40), Color("3a4a58"))
	_art.draw_rect(Rect2(140, 70, 120, 8), Color("6b5a4a"))
	_art.draw_rect(Rect2(175, 48, 50, 30), Color("1a1a1a"))
	_art.draw_rect(Rect2(178, 51, 44, 22), Color(0.6, 0.8, 1.0, 0.6 + sin(_time * 3.0) * 0.1))
	var look := {"skin": Color("8d5a3b"), "hair": Color("1e1612"), "shirt": Color("eef0f2"), "tag": true}
	_art.draw_rect(Rect2(190, 92, 20, 26), Color("eef0f2"))
	_art.draw_set_transform(Vector2(200, 92), 0.0, Vector2(2.5, 2.5))
	Style.draw_head(_art, look)
	_art.draw_set_transform(Vector2.ZERO)
	_art.draw_circle(Vector2(320, 40), 16.0, Color("f3e3c3"))
	var hand := _time * 4.0
	_art.draw_line(Vector2(320, 40), Vector2(320, 40) + Vector2(sin(hand), -cos(hand)) * 12.0, Style.INK, 2.0)
	for i in 3:
		_art.draw_rect(Rect2(40 + i * 24, 30 + i * 8, 18, 24), Color("eef0f2"))


func _draw_stove(size: Vector2) -> void:
	_art.draw_rect(Rect2(0, size.y - 46, size.x, 46), Color("b9a58a"))
	_art.draw_rect(Rect2(160, 74, 80, 30), Color("2b2b2b"))
	var flame := 1.0 + sin(_time * 12.0) * 0.2
	for i in 4:
		_art.draw_circle(Vector2(176 + i * 16, 72), 4.0 * flame, Color("4a7bd9"))
	_art.draw_rect(Rect2(172, 40, 56, 30), Color("b8863b"))
	_art.draw_rect(Rect2(168, 36, 64, 6), Color("d9a55b"))
	for i in 3:
		var rise := fmod(_time * 20.0 + i * 12.0, 36.0)
		_art.draw_rect(Rect2(186 + i * 14 + sin(_time * 3.0 + i) * 3.0, 30 - rise, 2, 6), Color(1, 1, 1, 0.5 * (1.0 - rise / 36.0)))
	for i in 3:
		Style.draw_symbol(_art, "coin", Vector2(80 + i * 18, 100 - i * 3), 2.0)


func _draw_flask(size: Vector2) -> void:
	_art.draw_rect(Rect2(0, size.y - 40, size.x, 40), Color("6b4a2e"))
	_art.draw_rect(Rect2(180, 34, 40, 80), Color("c9ced6"))
	_art.draw_rect(Rect2(176, 26, 48, 12), Color("9aa3ad"))
	_art.draw_rect(Rect2(186, 50, 6, 50), Color("e6eaf0"))
	var beat := 1.0 + absf(sin(_time * 4.0)) * 0.25
	Style.draw_symbol(_art, "heart", Vector2(260, 46), 3.0 * beat)
	_art.draw_set_transform(Vector2(110, 108), 0.0, Vector2(3, 3))
	Style.draw_head(_art, {"skin": Color("80543a"), "hair": Color("c9c4bb"), "hair_style": "bun", "flowers": true})
	_art.draw_set_transform(Vector2.ZERO)
	_art.draw_rect(Rect2(98, 108, 24, 20), Color("c0392b"))


func _draw_dawn(size: Vector2) -> void:
	var sky := Color("e8a36a").lerp(Color("f3d9a0"), clampf(_time / 3.0, 0.0, 1.0))
	_art.draw_rect(Rect2(Vector2.ZERO, size), sky)
	_art.draw_circle(Vector2(320, 110 - minf(_time * 12.0, 40.0)), 22.0, Color("ffe08a"))
	_art.draw_rect(Rect2(0, size.y - 34, size.x, 34), Color("4b4a4f"))
	_art.draw_rect(Rect2(110, 60, 120, 56), Color("6f8aa0"))
	_art.draw_rect(Rect2(100, 52, 140, 10), Color("3b6fc4"))
	_art.draw_rect(Rect2(120, 92, 100, 24), Color("9a6a3c"))
	_art.draw_rect(Rect2(140, 40, 60, 12), Color("b08a5a"))
	var font := _art.get_theme_default_font()
	_art.draw_string(font, Vector2(158, 50), "TEA", HORIZONTAL_ALIGNMENT_LEFT, -1, Style.FONT_SIZE, Color("3a2a1a"))
	for i in 3:
		var rise := fmod(_time * 14.0 + i * 8.0, 24.0)
		_art.draw_rect(Rect2(196 + i * 6, 88 - rise, 1, 4), Color(1, 1, 1, 0.6 * (1.0 - rise / 24.0)))
