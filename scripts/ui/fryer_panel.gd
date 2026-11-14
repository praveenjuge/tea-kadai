class_name FryerPanel
extends PanelContainer
## The kadai: fry a batch of vadai or bajji, lift it out when golden. One
## button does both, and clicking the kadai itself does the same.

var _service: Service
var _art: FryerArt
var _button: Button
var _stock: Label
var _kinds := {}


func _init(service: Service) -> void:
	_service = service


func _ready() -> void:
	custom_minimum_size = Vector2(190, 0)
	var box := VBoxContainer.new()
	add_child(box)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 3)
	var fries := _service.fries()
	if fries.size() == 1:
		head.add_child(Style.label("Vadai", Style.ACCENT))
	else:
		for kind in fries:
			var pick := Style.button(Catalog.MENU[kind]["name"], _service.set_fry_kind.bind(kind), true)
			pick.custom_minimum_size.y = 14
			head.add_child(pick)
			_kinds[kind] = pick
	_stock = Style.label("", Style.MUTED)
	_stock.size_flags_horizontal = SIZE_EXPAND_FILL
	_stock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(_stock)
	box.add_child(head)

	_art = FryerArt.new(_service.fryer)
	_art.custom_minimum_size = Vector2(0, 70)
	_art.size_flags_vertical = SIZE_EXPAND_FILL
	_art.clicked.connect(_service.fry_press)
	box.add_child(_art)

	_button = Style.button("", _service.fry_press)
	_button.custom_minimum_size.y = 22
	box.add_child(_button)


func refresh() -> void:
	_stock.text = "%d left" % _service.state.how_many(_service.fry_kind)
	var action := _service.fry_action_text()
	_button.text = "%s  [%s]" % [action, Controls.hint("fry")]
	_button.disabled = not _service.can_fry_press()
	for kind in _kinds:
		var pick: Button = _kinds[kind]
		var look := "Button" if kind == _service.fry_kind else "QuietButton"
		if pick.theme_type_variation != look:
			pick.theme_type_variation = look
	_art.queue_redraw()


class FryerArt extends Control:
	signal clicked

	const VADAI_R := 9.0
	const SPOTS: Array[Vector2] = [Vector2(-20, -3), Vector2(2, -6), Vector2(-8, 5), Vector2(16, 4)]

	var fryer: Fryer

	func _init(kadai: Fryer) -> void:
		fryer = kadai
		mouse_default_cursor_shape = CURSOR_POINTING_HAND

	func _gui_input(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit()
			accept_event()

	func _draw() -> void:
		var center := Vector2(size.x / 2.0, size.y / 2.0)
		_ellipse(center + Vector2(0, 4), 66, 24, Color("1f1f1f"))
		_ellipse(center, 62, 20, Color("3a3a3a"))
		_ellipse(center, 56, 16, Color("b07a2a"))
		var t := Time.get_ticks_msec() / 1000.0
		var done := fryer.doneness()
		if done == Fryer.Doneness.EMPTY:
			return
		for i in 6:
			var bubble := center + Vector2(sin(t * 5.0 + i * 1.7) * 40.0, cos(t * 4.0 + i) * 10.0)
			draw_circle(bubble, 1.0, Color(1, 0.9, 0.6, 0.5))
		var color := _vadai_color(fryer.cook_level())
		for i in fryer.count:
			var at := center + SPOTS[i]
			if fryer.kind == "bajji":
				_ellipse(at, VADAI_R + 3.0, VADAI_R - 3.0, color)
			else:
				draw_circle(at, VADAI_R, color)
				draw_circle(at, 2.5, Color("8a5a1f"))
			if done == Fryer.Doneness.GOLDEN:
				draw_arc(at, VADAI_R + 2.0, 0, TAU, 20, Style.GOOD, 1.5)
		var progress := clampf(fryer.time / fryer.golden_at(), 0.0, 1.0)
		if done == Fryer.Doneness.RAW:
			draw_rect(Rect2(center.x - 30, size.y - 5, 60, 3), Color(0, 0, 0, 0.4))
			draw_rect(Rect2(center.x - 30, size.y - 5, 60 * progress, 3), Style.VADAI_GOLDEN)

	func _vadai_color(level: float) -> Color:
		if level <= 1.0:
			return Style.VADAI_RAW.lerp(Style.VADAI_GOLDEN, level)
		var burnt := clampf((level - 1.6) / 0.4, 0.0, 1.0)
		return Style.VADAI_GOLDEN.lerp(Style.VADAI_BURNT, burnt)

	func _ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
		var points := PackedVector2Array()
		for i in 24:
			var a := TAU * i / 24.0
			points.append(center + Vector2(cos(a) * rx, sin(a) * ry))
		draw_colored_polygon(points, color)
