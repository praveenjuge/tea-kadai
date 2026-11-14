class_name NightScreen
extends Control
## End of day, out on the street under the moon: the kadai with its shutter
## half down, you counting coins, the day's takings chalked up one line at a
## time on a board, and the kadai's level, the week's goals and the regulars
## written in a notebook.

signal next_requested
signal shop_requested
signal branch_requested

const ROW_GAP := 0.35
const COUNT_SECONDS := 0.4
const PANEL_WIDTH := 212.0
const CHALK := Color("eef1e6")
const CHALK_DIM := Color("aab8a8")
const CHALK_YELLOW := Color("f2d27a")
const CHALK_GREEN := Color("a6e08f")
const CHALK_RED := Color("f09a8a")
const INK_ACCENT := Color("9a4f12")
const INK_GOOD := Color("2f7a2a")

var _state: KadaiState
var _sound: SoundBoard
var _scene := NightScene.new()
## Each tally row: {"label": Label, "value": Label, "to": int, "money": bool, "t": float}.
var _rows: Array[Dictionary] = []
var _stars: Control
var _stars_shown := 0
var _time := 0.0
var _money: Label
var _saved: Label


func _init(state: KadaiState, sound: SoundBoard) -> void:
	_state = state
	_sound = sound


func _ready() -> void:
	_scene.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(_scene)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	margin.add_child(root)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = SIZE_EXPAND_FILL
	root.add_child(columns)
	var board := _build_chalkboard()
	columns.add_child(board)
	Style.pop_in(board)
	var gap := Control.new()
	gap.size_flags_horizontal = SIZE_EXPAND_FILL
	gap.mouse_filter = MOUSE_FILTER_IGNORE
	columns.add_child(gap)
	var notebook := _build_notebook()
	columns.add_child(notebook)
	Style.pop_in(notebook, 0.2)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 6)
	_saved = Style.outlined("", Style.GOOD)
	_saved.size_flags_horizontal = SIZE_EXPAND_FILL
	_saved.clip_text = true
	footer.add_child(_saved)
	if _state.can_open_branch():
		footer.add_child(Style.button("Open a branch", func() -> void: branch_requested.emit()))
	footer.add_child(Style.button("Grow", func() -> void: shop_requested.emit(), true))
	footer.add_child(Style.button("Save day card", _save_card, true))
	footer.add_child(Style.button("Plan tomorrow →", func() -> void: next_requested.emit()))
	root.add_child(footer)
	refresh()


# --- The chalkboard ---------------------------------------------------------

func _build_chalkboard() -> Control:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "ChalkPanel"
	panel.custom_minimum_size.x = PANEL_WIDTH
	panel.size_flags_vertical = SIZE_SHRINK_BEGIN
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	box.add_child(Style.label("%s is done" % Catalog.WEEKDAYS[(_state.day - 1) % 7], CHALK, Style.TITLE_SIZE))
	_stars = Control.new()
	_stars.custom_minimum_size = Vector2(0, 24)
	_stars.draw.connect(_draw_stars)
	box.add_child(_stars)
	var today: Dictionary = _state.today
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 2)
	box.add_child(grid)
	_add_row(grid, "Customers served", int(today["served"]), false)
	_add_row(grid, "Perfect pours", int(today["perfect"]), false)
	_add_row(grid, "Sales", int(today["revenue"]), true)
	_add_row(grid, "Tips", int(today["tips"]), true)
	if int(today["helpers"]) > 0:
		_add_row(grid, "Helpers earned", int(today["helpers"]), true)
	_add_row(grid, "Stock bought", -int(today["spent"]), true)
	var profit := _state.profit_today()
	_add_row(grid, "Profit today", profit, true, CHALK_GREEN if profit >= 0 else CHALK_RED)
	_add_row(grid, "Reputation", int(today["points"]), false, CHALK_YELLOW)
	box.add_child(_chalk_line())
	var notes: Array[String] = []
	if int(today["best_streak"]) >= 3:
		notes.append("Best streak: %d perfect in a row" % today["best_streak"])
	if _state.lost_today() > 0:
		notes.append("%d left unhappy or found no room" % _state.lost_today())
	if int(today["wasted"]) > 0:
		notes.append("%d thrown away or burnt" % today["wasted"])
	for note in notes:
		box.add_child(Style.paragraph(note, PANEL_WIDTH - 20, CHALK_DIM))
	_money = Style.label("", CHALK_YELLOW, Style.TITLE_SIZE)
	box.add_child(_money)
	return panel


func _add_row(grid: GridContainer, title: String, amount: int, money: bool, color: Color = CHALK) -> void:
	var name_label := Style.label(title, color)
	var value := Style.label("", color)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_horizontal = SIZE_EXPAND_FILL
	name_label.modulate.a = 0.0
	value.modulate.a = 0.0
	grid.add_child(name_label)
	grid.add_child(value)
	_rows.append({"label": name_label, "value": value, "to": amount, "money": money, "t": -_rows.size() * ROW_GAP})


## A wobbly chalk underline.
func _chalk_line() -> Control:
	var line := Control.new()
	line.custom_minimum_size = Vector2(0, 5)
	line.draw.connect(func() -> void:
		var points := PackedVector2Array()
		for i in 13:
			var x := line.size.x * i / 12.0
			points.append(Vector2(x, 2.5 + sin(i * 1.7) * 0.8))
		line.draw_polyline(points, Color(CHALK, 0.7), 1.0))
	return line


func _draw_stars() -> void:
	for i in 3:
		var at := Vector2(12 + i * 24, 12)
		var lit := i < _stars_shown
		Style.draw_symbol(_stars, "star" if lit else "star_empty", at, 1.8)


# --- The notebook -----------------------------------------------------------

func _build_notebook() -> Control:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "NotebookPanel"
	panel.custom_minimum_size.x = PANEL_WIDTH + 20
	panel.size_flags_vertical = SIZE_SHRINK_BEGIN
	panel.draw.connect(_draw_ruling.bind(panel))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	_add_level(box)
	_add_goals(box)
	_add_regulars(box)
	return panel


## Ruled lines and a red margin, like a school notebook.
func _draw_ruling(panel: Control) -> void:
	var y := 18.0
	while y < panel.size.y - 4:
		panel.draw_line(Vector2(4, y), Vector2(panel.size.x - 4, y), Color("9fb7d6", 0.45), 1.0)
		y += 13.0
	panel.draw_line(Vector2(14, 2), Vector2(14, panel.size.y - 2), Color("d46a6a", 0.6), 1.0)


func _add_level(box: VBoxContainer) -> void:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	var title := "Level %d" % _state.level()
	if _state.branches > 0:
		title = "%s · level %d" % [_state.branch_name(), _state.level()]
	head.add_child(Style.label(title, INK_ACCENT))
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, 8)
	bar.size_flags_horizontal = SIZE_EXPAND_FILL
	bar.size_flags_vertical = SIZE_SHRINK_CENTER
	bar.draw.connect(func() -> void:
		bar.draw_rect(Rect2(Vector2.ZERO, bar.size), Color("d9c9a5"))
		bar.draw_rect(Rect2(Vector2.ZERO, Vector2(bar.size.x * _state.level_progress(), bar.size.y)), Style.ACCENT)
		bar.draw_rect(Rect2(Vector2.ZERO, bar.size), Style.INK, false, 1.0))
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
		box.add_child(Style.paragraph(line, PANEL_WIDTH - 10, INK_GOOD))


func _add_goals(box: VBoxContainer) -> void:
	var day_of_week := (_state.day - 1) % 7 + 1
	box.add_child(Style.label("Week %d goals · day %d of 7" % [Catalog.week_of(_state.day), day_of_week], INK_ACCENT))
	for goal in _state.week_goals():
		box.add_child(Style.goal_row(goal, Style.INK))
	for text in _state.today["goals_done"]:
		box.add_child(Style.paragraph("Goal reached: %s! +%s" % [text.to_lower(), Style.rupees(Catalog.GOAL_REWARD)], PANEL_WIDTH - 10, INK_GOOD))


## A line for each regular in the story so far: their face, friendship
## hearts, and what's next for them.
func _add_regulars(box: VBoxContainer) -> void:
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


func _regular_row(id: String, line: String) -> Control:
	var info: Dictionary = Story.REGULARS[id]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var face := Control.new()
	face.custom_minimum_size = Vector2(22, 22)
	face.size_flags_vertical = SIZE_SHRINK_BEGIN
	face.draw.connect(func() -> void: Style.draw_portrait(face, info, Rect2(Vector2.ZERO, Vector2(22, 22))))
	row.add_child(face)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 0)
	text.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(text)
	var head := HBoxContainer.new()
	head.add_child(Style.label(info["name"], Style.INK))
	var hearts := Control.new()
	hearts.custom_minimum_size = Vector2(66, 12)
	hearts.size_flags_horizontal = SIZE_EXPAND_FILL
	var friendship := int(_state.regular(id)["friendship"])
	hearts.draw.connect(func() -> void:
		for i in 5:
			var full := friendship >= (i + 1) * 20
			Style.draw_symbol(hearts, "heart" if full else "heart_empty", Vector2(hearts.size.x - 58 + i * 12, 6), 0.9))
	head.add_child(hearts)
	text.add_child(head)
	text.add_child(Style.paragraph(line, PANEL_WIDTH - 40, Style.INK))
	return row


# ---------------------------------------------------------------------------

func _save_card() -> void:
	var path := await ShareCard.save_png(self, ShareCard.for_day(_state), "Tea Kadai - Day %d.png" % _state.day)
	_saved.text = "Saved to Desktop: " + path.get_file()


func refresh() -> void:
	_money.text = "Money now: %s" % Style.short_rupees(_state.money)


func _process(delta: float) -> void:
	_time += delta
	var counted := 0
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
		if row["money"] and shown > 0:
			counted += shown
	_scene.counted = counted
	var stars_at := _rows.size() * ROW_GAP + 0.3
	var earned := _state.stars_today()
	while _stars_shown < earned and _time >= stars_at + _stars_shown * 0.3:
		_stars_shown += 1
		_sound.play("perfect", 1.0 + _stars_shown * 0.12)
	_stars.queue_redraw()
