class_name TeaPanel
extends PanelContainer
## The tea station: one button to make a glass, then hold it to pour. Once
## more drinks are on the menu, small switches pick the next one.

var _service: Service
var _art: TeaArt
var _button: Button
var _stock: Label
var _kinds := {}
var _head: HBoxContainer
var _drinks: Array[String] = []


func _init(service: Service) -> void:
	_service = service


func _ready() -> void:
	custom_minimum_size = Vector2(230, 0)
	var box := VBoxContainer.new()
	add_child(box)

	_head = HBoxContainer.new()
	_head.add_theme_constant_override("separation", 3)
	box.add_child(_head)
	_build_head()

	_art = TeaArt.new(_service.tea)
	_art.custom_minimum_size = Vector2(0, 70)
	_art.size_flags_vertical = SIZE_EXPAND_FILL
	box.add_child(_art)

	# Press to make a glass; press and hold to pour; let go to stop pouring.
	_button = Button.new()
	_button.focus_mode = FOCUS_NONE
	_button.custom_minimum_size.y = 22
	_button.button_down.connect(_service.tea_press)
	_button.button_up.connect(_service.tea_release)
	box.add_child(_button)


## The title, or one switch per drink once there's more than one, plus how
## many of the chosen drink are left. Rebuilt when a drink is learned mid-day.
func _build_head() -> void:
	for child in _head.get_children():
		child.queue_free()
	_kinds.clear()
	_drinks = _service.drinks()
	if _drinks.size() == 1:
		_head.add_child(Style.label("Tea", Style.ACCENT))
	else:
		for kind in _drinks:
			var short: String = Catalog.MENU[kind].get("short", Catalog.MENU[kind]["name"])
			var text := short.replace(" tea", "").replace("Tea", "Plain")
			var pick := Style.button(text, _service.set_tea_kind.bind(kind), true)
			pick.custom_minimum_size.y = 14
			_head.add_child(pick)
			_kinds[kind] = pick
	_stock = Style.label("", Style.MUTED)
	_stock.size_flags_horizontal = SIZE_EXPAND_FILL
	_stock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_stock.clip_text = true
	_head.add_child(_stock)


func refresh() -> void:
	if _service.drinks() != _drinks:
		_build_head()
	var tea := _service.tea
	_button.text = "%s  [%s]" % [tea.action_text(), Controls.hint("tea")]
	_button.disabled = tea.stage == TeaStation.Stage.FILLING
	var left := _service.state.how_many(_service.tea_kind)
	_stock.text = ("%d left" % left) if _drinks.size() < 4 else "×%d" % left
	for kind in _kinds:
		var pick: Button = _kinds[kind]
		var look := "Button" if kind == _service.tea_kind else "QuietButton"
		if pick.theme_type_variation != look:
			pick.theme_type_variation = look
	_art.queue_redraw()


## Where the glass sits on screen, for the sparkle on a perfect pour.
func glass_point() -> Vector2:
	return _art.global_position + Vector2(_art.size.x * 0.5, _art.size.y - 34)


## Draws the milk pot, the glass, the tumbler and stream while pouring, and the meter.
class TeaArt extends Control:
	const METER_W := 10.0

	var tea: TeaStation

	func _init(station: TeaStation) -> void:
		tea = station

	func _draw() -> void:
		var floor_y := size.y - 4.0
		draw_rect(Rect2(0, floor_y, size.x - METER_W - 8, 4), Style.LINE)
		_draw_milk_pot(Vector2(28, floor_y))
		_draw_glass(Vector2(size.x * 0.5, floor_y))
		_draw_meter(Rect2(size.x - METER_W, 2, METER_W, floor_y - 2))

	func _draw_milk_pot(base: Vector2) -> void:
		draw_rect(Rect2(base.x - 16, base.y - 6, 32, 6), Color("2b2b2b"))
		draw_rect(Rect2(base.x - 12, base.y - 8, 24, 2), Color("4a7bd9"))
		draw_rect(Rect2(base.x - 15, base.y - 34, 30, 26), Color("b8863b"))
		draw_rect(Rect2(base.x - 16, base.y - 36, 32, 3), Color("d9a55b"))
		var t := Time.get_ticks_msec() / 1000.0
		for i in 3:
			var x := base.x - 8 + i * 8 + sin(t * 3.0 + i) * 1.5
			var y := base.y - 40 - fmod(t * 8.0 + i * 4.0, 14.0)
			draw_rect(Rect2(x, y, 1, 3), Color(Style.TEXT, 0.35))

	func _draw_glass(base: Vector2) -> void:
		var height := 34.0
		var top := base.y - height
		var outline := PackedVector2Array([
			Vector2(base.x - 11, top), Vector2(base.x + 11, top),
			Vector2(base.x + 8, base.y), Vector2(base.x - 8, base.y),
		])
		if tea.stage == TeaStation.Stage.EMPTY:
			outline.append(outline[0])
			draw_polyline(outline, Color(Style.MUTED, 0.4), 1.0)
			return
		draw_colored_polygon(outline, Style.GLASS)
		var fill_h := (height - 4) * 0.8 * tea.fill_progress()
		draw_rect(Rect2(base.x - 8, base.y - fill_h, 16, fill_h), Style.drink_color(tea.kind))
		if tea.kind == "lemon_tea" and tea.fill_progress() >= 1.0:
			draw_circle(Vector2(base.x + 9, top + 4), 4.0, Color("e8d23c"))
			draw_circle(Vector2(base.x + 9, top + 4), 2.5, Color("f4eb8a"))
		if tea.stage == TeaStation.Stage.POURING:
			_draw_pour(base, top)

	func _draw_pour(base: Vector2, glass_top: float) -> void:
		var lowest := glass_top - 4.0
		var highest := 4.0
		var y := lerpf(lowest, highest, tea.pour_height)
		draw_line(Vector2(base.x + 1, y + 6), Vector2(base.x + 1, glass_top + 6), Style.drink_color(tea.kind), 2.0)
		draw_rect(Rect2(base.x - 7, y - 4, 16, 10), Color("c9ced6"))
		draw_rect(Rect2(base.x - 8, y - 5, 18, 2), Color("e6eaf0"))
		var froth := int(tea.pour_height * 5.0)
		for i in froth:
			draw_rect(Rect2(base.x - 8 + i * 3, glass_top + 5, 3, 2), Style.FROTH)

	func _draw_meter(rect: Rect2) -> void:
		var active := tea.can_pour() or tea.stage == TeaStation.Stage.POURING
		var alpha := 1.0 if active else 0.3
		draw_rect(rect, Color(Style.PANEL_DARK, alpha))
		var zone_top := rect.end.y - rect.size.y * tea.target.y
		var zone_h := rect.size.y * (tea.target.y - tea.target.x)
		draw_rect(Rect2(rect.position.x, zone_top, rect.size.x, zone_h), Color(Style.GOOD, alpha))
		draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 3), Color(Style.BAD, alpha))
		if tea.stage == TeaStation.Stage.POURING:
			var marker := rect.end.y - rect.size.y * tea.pour_height
			draw_rect(Rect2(rect.position.x - 3, marker - 1, rect.size.x + 6, 3), Style.TEXT)
		draw_rect(rect, Color(Style.LINE, alpha), false, 1.0)
