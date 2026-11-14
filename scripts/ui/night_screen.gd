class_name NightScreen
extends Control
## End of day: the takings counted up one line at a time, stars for the day,
## how things stand with Karthik, and upgrades to spend the money on.

signal next_requested

const ROW_GAP := 0.35
const COUNT_SECONDS := 0.4

var _state: KadaiState
var _sound: SoundBoard
## Each tally row: {"label": Label, "value": Label, "to": int, "money": bool, "t": float}.
var _rows: Array[Dictionary] = []
var _stars: Control
var _stars_shown := 0
var _time := 0.0
var _money: Label
var _upgrades := {}


func _init(state: KadaiState, sound: SoundBoard) -> void:
	_state = state
	_sound = sound


func _ready() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	add_child(margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	margin.add_child(columns)
	columns.add_child(_build_tally())
	var right := VBoxContainer.new()
	right.size_flags_horizontal = SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	columns.add_child(right)
	right.add_child(_build_regular())
	right.add_child(_build_upgrades())
	var spacer := Control.new()
	spacer.size_flags_vertical = SIZE_EXPAND_FILL
	right.add_child(spacer)
	var next := Style.button("Plan tomorrow →", func() -> void: next_requested.emit())
	next.size_flags_horizontal = SIZE_SHRINK_END
	right.add_child(next)
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
	_add_row(grid, "Spent at the market", -int(today["spent"]), true)
	var profit := _state.profit_today()
	_add_row(grid, "Profit today", profit, true, Style.GOOD if profit >= 0 else Style.BAD)
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


func _build_regular() -> Control:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "PaperPanel"
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	var info: Dictionary = Story.REGULARS["karthik"]
	var head := HBoxContainer.new()
	head.add_child(Style.label(info["name"], Style.INK))
	var hearts := Control.new()
	hearts.custom_minimum_size = Vector2(70, 12)
	hearts.size_flags_horizontal = SIZE_EXPAND_FILL
	var friendship := int(_state.regular("karthik")["friendship"])
	hearts.draw.connect(func() -> void:
		for i in 5:
			var full := friendship >= (i + 1) * 20
			Style.draw_symbol(hearts, "heart" if full else "heart_empty", Vector2(hearts.size.x - 60 + i * 13, 6), 1.0))
	head.add_child(hearts)
	box.add_child(head)
	var line := Story.hook("karthik", _state.day)
	if not _state.today["met"].has("karthik"):
		line = "%s didn't make it to the counter today." % info["name"] if _state.regular("karthik")["visits"] > 0 \
			else "A college student was looking at your kadai from across the road."
	box.add_child(Style.paragraph(line, 290.0, Style.INK))
	return panel


func _build_upgrades() -> Control:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	box.add_child(Style.label("Upgrades for the kadai", Style.ACCENT))
	for id in Catalog.UPGRADE_ORDER:
		var upgrade: Dictionary = Catalog.UPGRADES[id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = SIZE_EXPAND_FILL
		text.add_theme_constant_override("separation", 0)
		text.add_child(Style.label(upgrade["name"]))
		text.add_child(Style.label(upgrade["about"], Style.MUTED))
		row.add_child(text)
		var buy := Style.button("", _buy.bind(id))
		buy.custom_minimum_size.x = 70
		row.add_child(buy)
		box.add_child(row)
		_upgrades[id] = buy
	return panel


func _buy(id: String) -> void:
	if _state.buy_upgrade(id):
		_sound.play("perfect")
		_refresh_upgrades()


func _refresh_upgrades() -> void:
	for id in _upgrades:
		var button: Button = _upgrades[id]
		var cost := int(Catalog.UPGRADES[id]["cost"])
		if _state.has_upgrade(id):
			button.text = "Owned"
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
