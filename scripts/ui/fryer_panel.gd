class_name FryerPanel
extends PanelContainer
## The vadai kadai: drop batter in, lift them out when golden.

var _service: Service
var _art: FryerArt
var _drop: Button
var _stock: Label


func _init(service: Service) -> void:
	_service = service


func _ready() -> void:
	custom_minimum_size = Vector2(196, 124)
	var box := VBoxContainer.new()
	add_child(box)

	var head := HBoxContainer.new()
	head.add_child(Style.label("Vadai", Style.ACCENT))
	_stock = Style.label("", Style.MUTED)
	_stock.size_flags_horizontal = SIZE_EXPAND_FILL
	_stock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(_stock)
	box.add_child(head)

	_art = FryerArt.new(_service.fryer)
	_art.custom_minimum_size = Vector2(170, 58)
	_art.size_flags_vertical = SIZE_EXPAND_FILL
	_art.slot_clicked.connect(_service.fry_take)
	box.add_child(_art)

	_drop = Style.button("Drop vadai [%s]" % Controls.hint("fry_drop"), _service.fry_drop)
	box.add_child(_drop)
	box.add_child(Style.label("Click a vadai or press %s %s %s to lift it out." % [
		Controls.hint("fry_take_1"), Controls.hint("fry_take_2"), Controls.hint("fry_take_3")], Style.MUTED))


func refresh() -> void:
	_stock.text = "%d left" % _service.state.how_many("vadai")
	_drop.disabled = _service.fryer.free_slot() < 0 or not _service.state.can_make("vadai")
	_art.queue_redraw()


class FryerArt extends Control:
	signal slot_clicked(slot: int)

	const SLOT_GAP := 34.0
	const VADAI_R := 9.0

	var fryer: Fryer

	func _init(kadai: Fryer) -> void:
		fryer = kadai
		mouse_default_cursor_shape = CURSOR_POINTING_HAND

	func slot_center(slot: int) -> Vector2:
		return Vector2(size.x / 2.0 + (slot - 1) * SLOT_GAP, size.y / 2.0 - 2.0)

	func _gui_input(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
			return
		for slot in Fryer.SLOTS:
			if click.position.distance_to(slot_center(slot)) <= VADAI_R + 4.0:
				slot_clicked.emit(slot)
				accept_event()
				return

	func _draw() -> void:
		var center := Vector2(size.x / 2.0, size.y / 2.0 - 2.0)
		_ellipse(center + Vector2(0, 3), 64, 22, Color("1f1f1f"))
		_ellipse(center, 60, 18, Color("3a3a3a"))
		_ellipse(center, 54, 15, Color("b07a2a"))
		var font := get_theme_default_font()
		var t := Time.get_ticks_msec() / 1000.0
		for slot in Fryer.SLOTS:
			var at := slot_center(slot)
			var key := Controls.hint("fry_take_%d" % (slot + 1))
			draw_string(font, at + Vector2(-3, 22), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Style.MUTED)
			var done := fryer.doneness(slot)
			if done == Fryer.Doneness.EMPTY:
				continue
			for i in 3:
				var bubble := at + Vector2(sin(t * 5.0 + i * 2.0 + slot) * 11.0, cos(t * 4.0 + i) * 6.0)
				draw_circle(bubble, 1.0, Color(1, 0.9, 0.6, 0.5))
			draw_circle(at, VADAI_R, _vadai_color(fryer.cook_level(slot)))
			draw_circle(at, 2.5, Color("8a5a1f"))
			if done == Fryer.Doneness.GOLDEN:
				draw_arc(at, VADAI_R + 2.0, 0, TAU, 20, Style.GOOD, 1.5)

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
