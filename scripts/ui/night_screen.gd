class_name NightScreen
extends Control
## End of day: the takings counted up one line at a time, stars for the day,
## the kadai's level and the week's goals, how things stand with Karthik, and
## upgrades to spend the money on.

signal next_requested

const ROW_GAP := 0.35
const COUNT_SECONDS := 0.4
## How many buyable upgrades to list at once.
const UPGRADES_SHOWN := 3

var _state: KadaiState
var _sound: SoundBoard
## Each tally row: {"label": Label, "value": Label, "to": int, "money": bool, "t": float}.
var _rows: Array[Dictionary] = []
var _stars: Control
var _stars_shown := 0
var _time := 0.0
var _money: Label
var _upgrades := {}
var _saved: Label


func _init(state: KadaiState, sound: SoundBoard) -> void:
	_state = state
	_sound = sound


func _ready() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	add_child(margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	columns.size_flags_vertical = SIZE_SHRINK_CENTER
	margin.add_child(columns)
	var tally := _build_tally()
	columns.add_child(tally)
	Style.pop_in(tally)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	columns.add_child(right)
	var cards: Array[Control] = [_build_level(), _build_goals(), _build_regulars(), _build_upgrades()]
	for i in cards.size():
		right.add_child(cards[i])
		Style.pop_in(cards[i], 0.15 + i * 0.12)
	var spacer := Control.new()
	spacer.size_flags_vertical = SIZE_EXPAND_FILL
	right.add_child(spacer)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 6)
	footer.alignment = BoxContainer.ALIGNMENT_END
	_saved = Style.label("", Style.GOOD)
	_saved.size_flags_horizontal = SIZE_EXPAND_FILL
	_saved.clip_text = true
	footer.add_child(_saved)
	footer.add_child(Style.button("Save day card", _save_card, true))
	footer.add_child(Style.button("Plan tomorrow →", func() -> void: next_requested.emit()))
	right.add_child(footer)
	_refresh_upgrades()


func _build_tally() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 270
	panel.size_flags_vertical = SIZE_SHRINK_BEGIN
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	box.add_child(Style.label("%s is done" % Catalog.WEEKDAYS[(_state.day - 1) % 7], Style.TEXT, Style.TITLE_SIZE))
	_stars = Control.new()
	_stars.custom_minimum_size = Vector2(0, 26)
	_stars.draw.connect(_draw_stars)
	box.add_child(_stars)
	var today: Dictionary = _state.today
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 3)
	box.add_child(grid)
	_add_row(grid, "Customers served", int(today["served"]), false)
	_add_row(grid, "Perfect pours", int(today["perfect"]), false)
	_add_row(grid, "Sales", int(today["revenue"]), true)
	_add_row(grid, "Tips", int(today["tips"]), true)
	_add_row(grid, "Stock bought (keeps)", -int(today["spent"]), true)
	var profit := _state.profit_today()
	_add_row(grid, "Profit today", profit, true, Style.GOOD if profit >= 0 else Style.BAD)
	_add_row(grid, "Reputation earned", int(today["points"]), false, Style.ACCENT)
	box.add_child(HSeparator.new())
	var notes: Array[String] = []
	if int(today["best_streak"]) >= 3:
		notes.append("Best streak: %d perfect pours in a row" % today["best_streak"])
	if _state.lost_today() > 0:
		notes.append("%d customers left unhappy or found no room" % _state.lost_today())
	if int(today["wasted"]) > 0:
		notes.append("%d thrown away at closing or burnt" % today["wasted"])
	for note in notes:
		box.add_child(Style.label(note, Style.MUTED))
	_money = Style.label("", Style.ACCENT, Style.TITLE_SIZE)
	box.add_child(_money)
	return panel


func _add_row(grid: GridContainer, title: String, amount: int, money: bool, color: Color = Style.TEXT) -> void:
	var name_label := Style.label(title, color)
	var value := Style.label("", color)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_horizontal = SIZE_EXPAND_FILL
	name_label.modulate.a = 0.0
	value.modulate.a = 0.0
	grid.add_child(name_label)
	grid.add_child(value)
	_rows.append({"label": name_label, "value": value, "to": amount, "money": money, "t": -_rows.size() * ROW_GAP})


func _build_level() -> Control:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.add_child(Style.label("Kadai level %d" % _state.level(), Style.ACCENT))
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, 10)
	bar.size_flags_horizontal = SIZE_EXPAND_FILL
	bar.size_flags_vertical = SIZE_SHRINK_CENTER
	bar.draw.connect(func() -> void:
		bar.draw_rect(Rect2(Vector2.ZERO, bar.size), Style.PANEL_DARK)
		bar.draw_rect(Rect2(Vector2.ZERO, Vector2(bar.size.x * _state.level_progress(), bar.size.y)), Style.ACCENT)
		bar.draw_rect(Rect2(Vector2.ZERO, bar.size), Style.WOOD_EDGE, false, 1.0))
	head.add_child(bar)
	box.add_child(head)
	for reached in _state.today["level_ups"]:
		var unlocked := Catalog.unlocks_at(reached)
		var line := "Level %d!" % reached
		if not unlocked.is_empty():
			line += " New on the menu: %s." % Catalog.MENU[unlocked[0]]["name"].to_lower()
		for id in Catalog.UPGRADE_ORDER:
			if int(Catalog.UPGRADES[id]["level"]) == reached:
				line += " %s is for sale." % Catalog.UPGRADES[id]["name"]
				break
		box.add_child(Style.label(line, Style.GOOD))
	return panel


func _build_goals() -> Control:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	var day_of_week := (_state.day - 1) % 7 + 1
	box.add_child(Style.label("Week %d goals · day %d of 7" % [Catalog.week_of(_state.day), day_of_week], Style.ACCENT))
	for goal in _state.week_goals():
		box.add_child(Style.goal_row(goal))
	for text in _state.today["goals_done"]:
		box.add_child(Style.label("Goal reached: %s! +%s" % [text.to_lower(), Style.rupees(Catalog.GOAL_REWARD)], Style.GOOD))
	return panel


## A paper card with a line for each regular in the story so far: their
## face, friendship hearts, and what's next for them.
func _build_regulars() -> Control:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "PaperPanel"
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	for id in Story.REGULAR_ORDER:
		if _state.day < Story.first_day(id):
			continue
		var line := Story.hook(id, _state.day)
		var met: bool = _state.today["met"].has(id)
		if line == "" and met:
			line = "Dropped by for the usual."
		elif not met:
			line = "%s didn't make it to the counter today." % Story.REGULARS[id]["name"]
		if line != "":
			box.add_child(_regular_row(id, line))
	return panel


func _regular_row(id: String, line: String) -> Control:
	var info: Dictionary = Story.REGULARS[id]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var face := Control.new()
	face.custom_minimum_size = Vector2(22, 22)
	face.draw.connect(func() -> void: Style.draw_portrait(face, info, Rect2(Vector2.ZERO, Vector2(22, 22))))
	row.add_child(face)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 0)
	text.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(text)
	var head := HBoxContainer.new()
	head.add_child(Style.label(info["name"], Style.INK))
	var hearts := Control.new()
	hearts.custom_minimum_size = Vector2(70, 12)
	hearts.size_flags_horizontal = SIZE_EXPAND_FILL
	var friendship := int(_state.regular(id)["friendship"])
	hearts.draw.connect(func() -> void:
		for i in 5:
			var full := friendship >= (i + 1) * 20
			Style.draw_symbol(hearts, "heart" if full else "heart_empty", Vector2(hearts.size.x - 60 + i * 13, 6), 1.0))
	head.add_child(hearts)
	text.add_child(head)
	text.add_child(Style.paragraph(line, 260.0, Style.INK))
	return row


func _build_upgrades() -> Control:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	box.add_child(Style.label("Upgrades for the kadai", Style.ACCENT))
	var shown := 0
	var locked := ""
	for id in Catalog.UPGRADE_ORDER:
		var upgrade: Dictionary = Catalog.UPGRADES[id]
		if _state.has_upgrade(id):
			continue
		if int(upgrade["level"]) > _state.level():
			if locked == "":
				locked = "Level %d unlocks: %s" % [upgrade["level"], upgrade["name"]]
			continue
		if shown >= UPGRADES_SHOWN:
			continue
		shown += 1
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var text := Style.label("%s · %s" % [upgrade["name"], upgrade["about"]])
		text.size_flags_horizontal = SIZE_EXPAND_FILL
		text.clip_text = true
		row.add_child(text)
		var buy := Style.button("", _buy.bind(id))
		buy.custom_minimum_size = Vector2(54, 14)
		row.add_child(buy)
		box.add_child(row)
		_upgrades[id] = buy
	if shown == 0:
		box.add_child(Style.label("Nothing new for now. Grow the kadai's level for more.", Style.MUTED))
	if locked != "":
		box.add_child(Style.label(locked, Style.MUTED))
	if not _state.upgrades.is_empty():
		var owned: Array[String] = []
		for id in _state.upgrades:
			owned.append(Catalog.UPGRADES[id]["name"])
		var owned_label := Style.label("Owned: " + ", ".join(owned), Style.MUTED)
		owned_label.clip_text = true
		box.add_child(owned_label)
	return panel


func _save_card() -> void:
	var path := await ShareCard.save_png(self, ShareCard.for_day(_state), "Tea Kadai - Day %d.png" % _state.day)
	_saved.text = "Saved to Desktop: " + path.get_file()


func _buy(id: String) -> void:
	if _state.buy_upgrade(id):
		_sound.play("perfect")
		var button: Button = _upgrades[id]
		button.text = "Bought!"
		_refresh_upgrades()


func _refresh_upgrades() -> void:
	for id in _upgrades:
		var button: Button = _upgrades[id]
		var cost := int(Catalog.UPGRADES[id]["cost"])
		if _state.has_upgrade(id):
			button.disabled = true
		else:
			button.text = Style.rupees(cost)
			button.disabled = _state.money < cost
	_money.text = "Money now: %s" % Style.rupees(_state.money)


func _process(delta: float) -> void:
	_time += delta
	for row in _rows:
		row["t"] += delta
		var t: float = row["t"]
		if t < 0.0:
			continue
		var label: Label = row["label"]
		var value: Label = row["value"]
		if label.modulate.a == 0.0:
			_sound.play("coin", 0.9 + _rows.find(row) * 0.06)
		label.modulate.a = minf(1.0, t / 0.15)
		value.modulate.a = label.modulate.a
		var shown := roundi(lerpf(0.0, float(row["to"]), clampf(t / COUNT_SECONDS, 0.0, 1.0)))
		value.text = Style.rupees(shown) if row["money"] else str(shown)
	var stars_at := _rows.size() * ROW_GAP + 0.3
	var earned := _state.stars_today()
	while _stars_shown < earned and _time >= stars_at + _stars_shown * 0.3:
		_stars_shown += 1
		_sound.play("perfect", 1.0 + _stars_shown * 0.12)
	_stars.queue_redraw()


func _draw_stars() -> void:
	for i in 3:
		var at := Vector2(12 + i * 26, 13)
		var lit := i < _stars_shown
		Style.draw_symbol(_stars, "star" if lit else "star_empty", at, 2.0)
