class_name MorningScreen
extends Control
## The paused morning: the paper, the week ahead and its goals, the kadai's
## level, and the market stalls. Prices open in their own panel.

signal open_requested
signal prices_requested

## Below this many, an item counts as running low.
const LOW_STOCK := 6

var _state: KadaiState
var _money: Label
var _market: MarketScene
var _hint: Label
var _stock_note: Label
## Money family sent this morning, if any.
var _help := 0


func _init(state: KadaiState, help: int = 0) -> void:
	_state = state
	_help = help


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
	header.add_theme_constant_override("separation", 10)
	var title := Style.label("Day %d · %s" % [_state.day, Catalog.date_text(_state.day)], Style.TEXT, Style.TITLE_SIZE)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(_build_level_chip())
	_money = Style.label("", Style.ACCENT, Style.TITLE_SIZE)
	header.add_child(_money)
	root.add_child(header)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	var paper := _build_paper()
	top.add_child(paper)
	Style.pop_in(paper)
	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 6)
	side.add_child(_build_week())
	side.add_child(_build_goals())
	top.add_child(side)
	root.add_child(top)
	Style.pop_in(side, 0.1)

	_market = MarketScene.new(_state)
	_market.custom_minimum_size.y = 124
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

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 6)
	_stock_note = Style.label("", Style.MUTED)
	_stock_note.size_flags_horizontal = SIZE_EXPAND_FILL
	_stock_note.clip_text = true
	footer.add_child(_stock_note)
	footer.add_child(Style.button("Prices", func() -> void: prices_requested.emit(), true))
	footer.add_child(Style.button("Open the kadai →", func() -> void: open_requested.emit()))
	root.add_child(footer)
	_refresh()


func refresh() -> void:
	_refresh()


func _build_level_chip() -> Control:
	var chip := HBoxContainer.new()
	chip.add_theme_constant_override("separation", 4)
	chip.add_child(Style.label("Level %d" % _state.level(), Style.ACCENT))
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(60, 6)
	bar.size_flags_vertical = SIZE_SHRINK_CENTER
	bar.draw.connect(func() -> void:
		bar.draw_rect(Rect2(Vector2.ZERO, bar.size), Style.PANEL_DARK)
		bar.draw_rect(Rect2(Vector2.ZERO, Vector2(bar.size.x * _state.level_progress(), bar.size.y)), Style.ACCENT))
	chip.add_child(bar)
	return chip


func _build_paper() -> Control:
	var paper := PanelContainer.new()
	paper.theme_type_variation = "PaperPanel"
	paper.size_flags_horizontal = SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	paper.add_child(row)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(box)
	var photo := Control.new()
	photo.custom_minimum_size = Vector2(70, 52)
	photo.draw.connect(_draw_photo.bind(photo))
	row.add_child(photo)
	box.add_child(Style.label("THE MORNING KADAI TIMES", Style.LINE))
	box.add_child(Style.paragraph(Catalog.headline(_state.day), 210.0, Style.INK))
	var rain := Catalog.rain_for_day(_state.day)
	var forecast := "Weather: clear skies, hot by noon."
	if rain != Vector2.ZERO:
		forecast = "Weather: showers likely around %s. Tea and bajji weather!" % _clock_text(rain.x)
	box.add_child(Style.paragraph(forecast, 210.0, Style.LINE.darkened(0.2)))
	if _state.day == 1:
		box.add_child(Style.paragraph("You're stocked for today. Just open the kadai!", 210.0, Style.INK))
	if _help > 0:
		box.add_child(Style.paragraph("Money was tight, so Amma sent %s to keep the kadai going." % Style.rupees(_help),
			210.0, Style.BAD.darkened(0.2)))
	return paper


## A little printed picture for the front page, picked by the headline.
func _draw_photo(photo: Control) -> void:
	var r := Rect2(Vector2.ZERO, photo.size)
	photo.draw_rect(r, Color("d9c9a5"))
	var ink := Color("6b5a4a")
	match (_state.day - 1) % Catalog.HEADLINES.size() % 4:
		0:
			# Roadworks: a cone and a digger arm.
			photo.draw_rect(Rect2(8, 38, 54, 6), ink)
			photo.draw_colored_polygon(PackedVector2Array([Vector2(20, 38), Vector2(26, 18), Vector2(32, 38)]), Color("e8742f"))
			photo.draw_line(Vector2(40, 38), Vector2(52, 14), ink, 3.0)
			photo.draw_line(Vector2(52, 14), Vector2(60, 22), ink, 3.0)
		1:
			# Jasmine flowers.
			for i in 7:
				var at := Vector2(14 + (i % 4) * 14, 16 + (i / 4) * 18)
				for p in 5:
					var a := TAU * p / 5.0
					photo.draw_circle(at + Vector2(cos(a), sin(a)) * 3.0, 2.0, Color.WHITE)
				photo.draw_circle(at, 1.5, Color("e8c547"))
		2:
			# A film reel.
			photo.draw_circle(Vector2(35, 26), 18.0, ink)
			for i in 5:
				var a := TAU * i / 5.0
				photo.draw_circle(Vector2(35, 26) + Vector2(cos(a), sin(a)) * 9.0, 4.0, Color("d9c9a5"))
		_:
			# A cricket bat and ball.
			photo.draw_line(Vector2(20, 44), Vector2(46, 10), Color("b08a5a"), 6.0)
			photo.draw_line(Vector2(18, 47), Vector2(22, 42), ink, 3.0)
			photo.draw_circle(Vector2(52, 38), 5.0, Color("c0392b"))
	photo.draw_rect(r, ink, false, 1.0)


func _build_week() -> Control:
	var panel := PanelContainer.new()
	var strip := Control.new()
	strip.custom_minimum_size = Vector2(7 * 32, 52)
	strip.draw.connect(_draw_week.bind(strip))
	panel.add_child(strip)
	return panel


func _build_goals() -> Control:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	panel.add_child(box)
	box.add_child(Style.label("This week's goals", Style.ACCENT))
	for goal in _state.week_goals():
		box.add_child(Style.goal_row(goal))
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
		for id in Story.REGULAR_ORDER:
			var story: Dictionary = Story.visit(id, day)
			if day >= _state.day and (story.get("lucky", false) or story.get("treat", false)):
				Style.draw_symbol(strip, "star", box.position + Vector2(24, 18), 0.8)


func _refresh() -> void:
	_money.text = Style.rupees(_state.money)
	var low: Array[String] = []
	for item in _state.menu():
		var have := _state.how_many(item)
		if have < LOW_STOCK:
			# Name the ingredient that's holding it back, so it's clear what to buy.
			var short := _limiting(item)
			var text := "%s ×%d" % [Catalog.MENU[item]["name"].to_lower(), have]
			if short != "" and Catalog.RECIPES[item].size() > 1:
				text += " (needs %s)" % short.to_lower()
			low.append(text)
	_stock_note.text = "Stocked for the day." if low.is_empty() else "Running low: " + ", ".join(low)
	_stock_note.add_theme_color_override("font_color", Style.GOOD if low.is_empty() else Style.WARN)
	_market.queue_redraw()
	_refresh_hint()


## The stock item that runs out first for this menu item.
func _limiting(item: String) -> String:
	var recipe: Dictionary = Catalog.RECIPES[item]
	var lowest := ""
	var lowest_count := 1 << 30
	for stock_id in recipe:
		var count := int(_state.stock[stock_id]) / int(recipe[stock_id])
		if count < lowest_count:
			lowest = Catalog.MARKET[stock_id]["name"]
			lowest_count = count
	return lowest


func _refresh_hint() -> void:
	var over := _market.hovered()
	if over == "":
		_hint.text = "Click goods to buy a pack, the red minus to put one back."
		return
	var pack: Dictionary = Catalog.MARKET[over]
	_hint.text = "%s, %s: makes %d %s for %s. You have %d." % [pack["name"], pack["pack"].to_lower(),
		pack["gives"], pack["unit"], Style.rupees(pack["cost"]), _state.stock[over]]


static func _clock_text(minutes: float) -> String:
	var hour := int(minutes) / 60
	var suffix := "AM" if hour < 12 else "PM"
	var hour12 := hour % 12
	return "%d %s" % [12 if hour12 == 0 else hour12, suffix]
