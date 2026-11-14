class_name TeaPanel
extends PanelContainer
## The tea station: a glass that fills step by step, and the pour meter.

var _service: Service
var _art: TeaArt
var _next: Button
var _pour: Button
var _stock: Label


func _init(service: Service) -> void:
	_service = service


func _ready() -> void:
	custom_minimum_size = Vector2(216, 124)
	var box := VBoxContainer.new()
	add_child(box)

	var head := HBoxContainer.new()
	head.add_child(Style.label("Tea", Style.ACCENT))
	_stock = Style.label("", Style.MUTED)
	_stock.size_flags_horizontal = SIZE_EXPAND_FILL
	_stock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(_stock)
	box.add_child(head)

	var body := HBoxContainer.new()
	body.size_flags_vertical = SIZE_EXPAND_FILL
	box.add_child(body)
	_art = TeaArt.new(_service.tea)
	_art.custom_minimum_size = Vector2(96, 84)
	body.add_child(_art)

	var buttons := VBoxContainer.new()
	buttons.size_flags_horizontal = SIZE_EXPAND_FILL
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(buttons)
	_next = Style.button("", _service.tea_next)
	buttons.add_child(_next)
	_pour = Button.new()
	_pour.text = "Pour [%s]" % Controls.hint("tea_pour")
	_pour.focus_mode = FOCUS_NONE
	_pour.button_down.connect(_service.tea_pour_start)
	_pour.button_up.connect(_service.tea_pour_release)
	buttons.add_child(_pour)
	var help := Style.label("Hold to pour high, let go in the green.", Style.MUTED)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	buttons.add_child(help)


func refresh() -> void:
	var tea := _service.tea
	var pouring := tea.stage == TeaStation.Stage.POURING
	_next.text = "%s [%s]" % [tea.next_action(), Controls.hint("tea_next")]
	_next.disabled = tea.can_pour() or pouring
	_pour.disabled = not (tea.can_pour() or pouring)
	_stock.text = "%d glasses' worth" % _service.state.how_many("tea")
	_art.queue_redraw()


## Draws the glass, the tumbler and stream while pouring, and the pour meter.
class TeaArt extends Control:
	const METER_W := 8.0

	var tea: TeaStation

	func _init(station: TeaStation) -> void:
		tea = station

	func _draw() -> void:
		var floor_y := size.y - 6.0
		draw_rect(Rect2(0, floor_y, size.x - METER_W - 6, 6), Style.LINE)
		_draw_milk_pot(Vector2(16, floor_y))
		_draw_glass(Vector2(54, floor_y))
		_draw_meter(Rect2(size.x - METER_W, 4, METER_W, floor_y - 4))

	func _draw_milk_pot(base: Vector2) -> void:
		draw_rect(Rect2(base.x - 12, base.y - 6, 24, 6), Color("2b2b2b"))
		draw_rect(Rect2(base.x - 9, base.y - 8, 18, 2), Color("4a7bd9"))
		draw_rect(Rect2(base.x - 11, base.y - 28, 22, 20), Color("b8863b"))
		draw_rect(Rect2(base.x - 12, base.y - 30, 24, 3), Color("d9a55b"))
		var t := Time.get_ticks_msec() / 1000.0
		for i in 3:
			var x := base.x - 6 + i * 6 + sin(t * 3.0 + i) * 1.5
			var y := base.y - 34 - fmod(t * 8.0 + i * 4.0, 12.0)
			draw_rect(Rect2(x, y, 1, 3), Color(Style.TEXT, 0.35))

	func _draw_glass(base: Vector2) -> void:
		var height := 30.0
		var top := base.y - height
		var outline := PackedVector2Array([
			Vector2(base.x - 9, top), Vector2(base.x + 9, top),
			Vector2(base.x + 7, base.y), Vector2(base.x - 7, base.y),
		])
		if tea.stage == TeaStation.Stage.EMPTY:
			outline.append(outline[0])
			draw_polyline(outline, Color(Style.MUTED, 0.4), 1.0)
			return
		draw_colored_polygon(outline, Style.GLASS)
		var level := 0.0
		var color := Style.DECOCTION
		match tea.stage:
			TeaStation.Stage.DECOCTION, TeaStation.Stage.SUGAR:
				level = 0.3
			TeaStation.Stage.MILK, TeaStation.Stage.POURING:
				level = 0.8
				color = Style.TEA
		if level > 0.0:
			var fill_h := (height - 2) * level
			draw_rect(Rect2(base.x - 7, base.y - fill_h, 14, fill_h), color)
		if tea.stage == TeaStation.Stage.SUGAR:
			for i in 4:
				draw_rect(Rect2(base.x - 5 + i * 3, base.y - 10 - (i % 2) * 2, 1, 1), Color.WHITE)
		if tea.stage == TeaStation.Stage.POURING:
			_draw_pour(base, top)

	func _draw_pour(base: Vector2, glass_top: float) -> void:
		var lowest := glass_top - 4.0
		var highest := 4.0
		var y := lerpf(lowest, highest, tea.pour_height)
		draw_line(Vector2(base.x + 1, y + 6), Vector2(base.x + 1, glass_top + 4), Style.TEA, 2.0)
		draw_rect(Rect2(base.x - 6, y - 4, 14, 10), Color("c9ced6"))
		draw_rect(Rect2(base.x - 7, y - 5, 16, 2), Color("e6eaf0"))
		var froth := int(tea.pour_height * 4.0)
		for i in froth:
			draw_rect(Rect2(base.x - 6 + i * 3, glass_top + 3, 3, 2), Style.FROTH)

	func _draw_meter(rect: Rect2) -> void:
		var active := tea.can_pour() or tea.stage == TeaStation.Stage.POURING
		var alpha := 1.0 if active else 0.35
		draw_rect(rect, Color(Style.PANEL_DARK, alpha))
		var zone_top := rect.end.y - rect.size.y * tea.target.y
		var zone_h := rect.size.y * (tea.target.y - tea.target.x)
		draw_rect(Rect2(rect.position.x, zone_top, rect.size.x, zone_h), Color(Style.GOOD, alpha))
		draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 3), Color(Style.BAD, alpha))
		if tea.stage == TeaStation.Stage.POURING:
			var marker := rect.end.y - rect.size.y * tea.pour_height
			draw_rect(Rect2(rect.position.x - 2, marker - 1, rect.size.x + 4, 2), Style.TEXT)
		draw_rect(rect, Color(Style.LINE, alpha), false, 1.0)
