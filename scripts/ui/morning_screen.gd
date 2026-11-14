class_name MorningScreen
extends Control
## The paused morning: the paper, the week ahead, the market stalls, and
## today's prices.

signal open_requested

var _state: KadaiState
var _money: Label
var _market: MarketScene
var _hint: Label
var _price_labels := {}
var _can_make: Label


func _init(state: KadaiState) -> void:
	_state = state


func _ready() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	margin.add_child(root)

	var header := HBoxContainer.new()
	header.add_child(Style.label("Day %d · %s" % [_state.day, Catalog.date_text(_state.day)], Style.TEXT, Style.TITLE_SIZE))
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(spacer)
	_money = Style.label("", Style.ACCENT, Style.TITLE_SIZE)
	header.add_child(_money)
	root.add_child(header)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	top.add_child(_build_paper())
	top.add_child(_build_week())
	root.add_child(top)

	_market = MarketScene.new(_state)
	_market.custom_minimum_size.y = 128
	_market.size_flags_vertical = SIZE_EXPAND_FILL
	_market.bought.connect(func(id: String) -> void:
		_state.buy(id)
		_refresh())
	_market.returned.connect(func(id: String) -> void:
		_state.undo_buy(id)
		_refresh())
	_market.mouse_exited.connect(_refresh)
	_market.gui_input.connect(func(_e: InputEvent) -> void: _refresh_hint())
	root.add_child(_market)
	_hint = Style.label("", Style.MUTED)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_hint)

	root.add_child(_build_prices())

	var footer := HBoxContainer.new()
	_can_make = Style.label("", Style.MUTED)
	_can_make.size_flags_horizontal = SIZE_EXPAND_FILL
	footer.add_child(_can_make)
	footer.add_child(Style.button("Open the kadai →", func() -> void: open_requested.emit()))
	root.add_child(footer)
	_refresh()


func _build_paper() -> Control:
	var paper := PanelContainer.new()
	paper.theme_type_variation = "PaperPanel"
	paper.size_flags_horizontal = SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	paper.add_child(box)
	box.add_child(Style.label("THE MORNING KADAI TIMES", Style.LINE))
	box.add_child(Style.paragraph(Catalog.headline(_state.day), 300.0, Style.INK))
	var rain := Catalog.rain_for_day(_state.day)
	var forecast := "Weather: clear skies, hot by noon."
	if rain != Vector2.ZERO:
		forecast = "Weather: showers likely around %s. Tea weather!" % _clock_text(rain.x)
	box.add_child(Style.label(forecast, Style.LINE.darkened(0.2)))
	return paper


func _build_week() -> Control:
	var panel := PanelContainer.new()
	var strip := Control.new()
	strip.custom_minimum_size = Vector2(7 * 32, 52)
	strip.draw.connect(_draw_week.bind(strip))
	panel.add_child(strip)
	return panel


func _draw_week(strip: Control) -> void:
	var font := strip.get_theme_default_font()
	var first := _state.day - (_state.day - 1) % 7
	for i in 7:
		var day := first + i
		var box := Rect2(i * 32 + 1, 0, 30, 52)
		var today := day == _state.day
		strip.draw_rect(box, Style.ACCENT if today else (Style.PANEL_DARK if day > _state.day else Style.LINE))
		var label := Catalog.weekday_short(day)
		var color := Style.INK if today else Style.TEXT
		strip.draw_string(font, box.position + Vector2(4, 12), label, HORIZONTAL_ALIGNMENT_LEFT, -1, Style.FONT_SIZE, color)
		strip.draw_string(font, box.position + Vector2(4, 24), str(day), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)
		var symbol := "cloud" if Catalog.rain_for_day(day) != Vector2.ZERO else "sun"
		if day >= _state.day:
			Style.draw_symbol(strip, symbol, box.position + Vector2(15, 38), 1.0)
		var story: Dictionary = Story.visit("karthik", day)
		if day >= _state.day and (story.get("lucky", false) or story.get("treat", false)):
			Style.draw_symbol(strip, "star", box.position + Vector2(24, 18), 0.8)


func _build_prices() -> Control:
	var panel := PanelContainer.new()
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 14)
	panel.add_child(flow)
	flow.add_child(Style.label("Prices:", Style.ACCENT))
	for item in _state.menu():
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 3)
		cell.add_child(Style.label(Catalog.MENU[item]["name"]))
		cell.add_child(_price_button("-", item, -1))
		var price := Style.label("")
		price.custom_minimum_size.x = 24
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(price)
		cell.add_child(_price_button("+", item, 1))
		_price_labels[item] = price
		flow.add_child(cell)
	return panel


func _price_button(text: String, item: String, change: int) -> Button:
	var button := Style.button(text, func() -> void:
		_state.set_price(item, int(_state.prices[item]) + change)
		_refresh(), true)
	button.custom_minimum_size = Vector2(14, 14)
	return button


func _refresh() -> void:
	_money.text = Style.rupees(_state.money)
	for item in _price_labels:
		var price := int(_state.prices[item])
		var usual := int(Catalog.MENU[item]["price"])
		var label: Label = _price_labels[item]
		label.text = "₹%d" % price
		var color := Style.TEXT
		if price > usual:
			color = Style.WARN
		elif price < usual:
			color = Style.GOOD
		label.add_theme_color_override("font_color", color)
	var parts: Array[String] = []
	for item in _state.menu():
		parts.append("%d %s" % [_state.how_many(item), Catalog.MENU[item]["name"].to_lower()])
	_can_make.text = "Enough for: " + ", ".join(parts)
	_market.queue_redraw()
	_refresh_hint()


func _refresh_hint() -> void:
	var over := _market.hovered()
	if over == "":
		_hint.text = "Click goods to buy a pack, the red minus to put one back. Above the usual price, some customers walk away."
		return
	var pack: Dictionary = Catalog.MARKET[over]
	_hint.text = "%s, %s: makes %d %s for %s. You have %d." % [pack["name"], pack["pack"].to_lower(),
		pack["gives"], pack["unit"], Style.rupees(pack["cost"]), _state.stock[over]]


static func _clock_text(minutes: float) -> String:
	var hour := int(minutes) / 60
	var suffix := "AM" if hour < 12 else "PM"
	var hour12 := hour % 12
	return "%d %s" % [12 if hour12 == 0 else hour12, suffix]
