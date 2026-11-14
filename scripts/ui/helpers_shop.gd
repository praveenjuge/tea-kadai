class_name HelpersShop
extends MenuOverlay
## Where the kadai grows: helpers who earn on their own (buy as many as you
## like), staff who take over counter work, upgrades that double things,
## things for the kadai, a trophy shelf of achievements, and all-time stats.
## Opens from the HUD during the day, and from the morning and night screens.

## A sound to play on a purchase, like "coin".
signal bought(kind: String)

const TABS := ["Helpers", "Staff", "Upgrades", "Kadai", "Trophies", "Stats"]
const ICONS := {
	"flask_boy": "tea", "office_runner": "filter_coffee", "bus_cart": "vadai",
	"college_stall": "samosa", "train_vendor": "bun", "film_catering": "star",
	"chai_boy": "tea", "cousin": "ginger_tea", "vadai_master": "bajji",
	"lucky_tumbler": "coin", "sharp_eyes": "star", "strong_decoction": "heart",
	"bench": "bun", "pot": "tea", "paint": "star", "plants": "heart", "fan": "coin",
	"radio": "star", "counter": "biscuit", "sign": "star",
}

var _state: KadaiState
var _tab := "Helpers"
var _tab_buttons := {}
var _income: Label
## Says when a purchase earned an achievement.
var _notice: Label
var _list := VBoxContainer.new()
## Buy buttons with what they buy, refreshed as money changes.
var _buys: Array[Array] = []


func _init(state: KadaiState) -> void:
	super("Grow the kadai", 440.0)
	_state = state
	_income = Style.label("", Style.GOOD)
	add(_income)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 3)
	for tab in TABS:
		var button := Style.button(tab, _show_tab.bind(tab), true)
		button.toggle_mode = true
		_tab_buttons[tab] = button
		tabs.add_child(button)
	add(tabs)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 200
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list.size_flags_horizontal = SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)
	add(scroll)
	_notice = Style.label("", Style.ACCENT)
	_notice.size_flags_horizontal = SIZE_EXPAND_FILL
	var footer := add_buttons([Style.button("Done", close)])
	footer.add_child(_notice)
	footer.move_child(_notice, 0)
	bought.connect(_on_bought)
	_show_tab("Helpers")


func _process(_delta: float) -> void:
	_income.text = "Helpers earn %s  ·  you have %s" % [Style.per_second(_state.income_per_second()), Style.short_rupees(_state.money)]
	for entry in _buys:
		var button: Button = entry[0]
		button.disabled = _state.money < int(entry[1]) or not bool(entry[2].call())


func _show_tab(tab: String) -> void:
	_tab = tab
	for name in _tab_buttons:
		_tab_buttons[name].set_pressed_no_signal(name == tab)
	for child in _list.get_children():
		child.queue_free()
	_buys.clear()
	match tab:
		"Helpers":
			_fill_helpers()
		"Staff":
			_fill_staff()
		"Upgrades":
			_fill_tiers()
			_fill_boosts()
		"Kadai":
			_fill_upgrades()
		"Trophies":
			_fill_trophies()
		"Stats":
			_fill_stats()


## A purchase can earn an achievement too, like owning 10 helpers.
func _on_bought(kind: String) -> void:
	if kind == "trophy":
		return
	for entry in _state.check_achievements():
		_notice.text = "Trophy: %s!" % entry["name"]
		bought.emit("trophy")


func _fill_helpers() -> void:
	for i in Catalog.HELPER_ORDER.size():
		var id: String = Catalog.HELPER_ORDER[i]
		var info: Dictionary = Catalog.HELPERS[id]
		var cost := _state.helper_cost(id)
		# The next helper shows once you own the one before, or nearly afford it.
		var shown := i == 0 or _state.helper_count(Catalog.HELPER_ORDER[i - 1]) > 0 or _state.earned_total >= cost / 2
		if not shown:
			_list.add_child(_row("", "???", "Keep growing to find out.", "", null))
			break
		var owned := _state.helper_count(id)
		var title := "%s  ×%d" % [info["name"], owned] if owned > 0 else String(info["name"])
		if _state.tier(id) > 0:
			title += "  " + "*".repeat(_state.tier(id))
		var earns := "%s each" % Style.per_second(_state.helper_income(id))
		var buy := _buy_button(Style.short_rupees(cost), cost, func() -> bool: return true, func() -> void:
			if _state.buy_helper(id):
				bought.emit("helper")
				_show_tab(_tab))
		_list.add_child(_row(id, title, info["about"], earns, buy))


func _fill_staff() -> void:
	for id in Catalog.STAFF_ORDER:
		var info: Dictionary = Catalog.STAFF[id]
		var cost := int(info["cost"])
		var buy: Control
		if _state.has_staff(id):
			buy = Style.label("Hired", Style.GOOD)
		elif _state.level() < int(info["level"]):
			buy = Style.label("Level %d" % info["level"], Style.MUTED)
		else:
			buy = _buy_button(Style.short_rupees(cost), cost, func() -> bool: return _state.can_hire(id), func() -> void:
				if _state.hire(id):
					bought.emit("staff")
					_show_tab(_tab))
		_list.add_child(_row(id, info["name"], info["about"], "", buy))
	_list.add_child(Style.paragraph("Staff step in when you leave their station alone for a few seconds.", 400.0, Style.MUTED))


## Each helper's next upgrade tier, once you own any of them.
func _fill_tiers() -> void:
	for id in Catalog.HELPER_ORDER:
		var next := _state.tier(id)
		if next >= Milestones.TIER_COUNTS.size() or _state.helper_count(id) == 0:
			continue
		var name: String = Catalog.HELPERS[id]["name"]
		var title := "%s: %s" % [name, Milestones.TIER_NAMES[next]]
		var about := "%ss earn twice as much." % name
		var cost := Milestones.tier_cost(id, next)
		var buy: Control
		if _state.next_tier(id) < 0:
			buy = Style.label("Own %d" % Milestones.TIER_COUNTS[next], Style.MUTED)
		else:
			buy = _buy_button(Style.short_rupees(cost), cost, func() -> bool: return _state.next_tier(id) >= 0, func() -> void:
				if _state.buy_tier(id):
					bought.emit("tier")
					_show_tab(_tab))
		_list.add_child(_row(id, title, about, "", buy))


func _fill_boosts() -> void:
	for id in Catalog.BOOST_ORDER:
		var info: Dictionary = Catalog.BOOSTS[id]
		var cost := int(info["cost"])
		var buy: Control
		var about: String = info["about"]
		if _state.has_boost(id):
			buy = Style.label("Bought", Style.GOOD)
		elif not _state.boost_unlocked(id):
			buy = Style.label("Locked", Style.MUTED)
			about += " Needs %d helpers in all." % info.get("needs_total", 0)
		else:
			buy = _buy_button(Style.short_rupees(cost), cost, func() -> bool: return _state.boost_unlocked(id), func() -> void:
				if _state.buy_boost(id):
					bought.emit("boost")
					_show_tab(_tab))
		_list.add_child(_row(id, info["name"], about, "", buy))


## Things for the kadai itself, each bought once and unlocked by level.
func _fill_upgrades() -> void:
	for id in Catalog.UPGRADE_ORDER:
		var info: Dictionary = Catalog.UPGRADES[id]
		var cost := int(info["cost"])
		var buy: Control
		if _state.has_upgrade(id):
			buy = Style.label("Bought", Style.GOOD)
		elif _state.level() < int(info["level"]):
			buy = Style.label("Level %d" % info["level"], Style.MUTED)
		else:
			buy = _buy_button(Style.short_rupees(cost), cost, func() -> bool: return true, func() -> void:
				if _state.buy_upgrade(id):
					bought.emit("upgrade")
					_show_tab(_tab))
		_list.add_child(_row(id, info["name"], info["about"], "", buy))


## The trophy shelf: every achievement, lit once earned.
func _fill_trophies() -> void:
	var count := _state.achievements.size()
	_list.add_child(Style.label("%d of %d trophies  ·  +%d%% to helpers and tips" % [count, Milestones.ACHIEVEMENTS.size(),
		roundi(count * Milestones.ACHIEVEMENT_BONUS * 100)], Style.ACCENT))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 3)
	for entry in Milestones.ACHIEVEMENTS:
		var got := _state.achievements.has(entry["id"])
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 4)
		cell.size_flags_horizontal = SIZE_EXPAND_FILL
		cell.tooltip_text = entry["about"]
		var cup := Control.new()
		cup.custom_minimum_size = Vector2(14, 14)
		cup.mouse_filter = MOUSE_FILTER_PASS
		cup.draw.connect(func() -> void: Style.draw_symbol(cup, "trophy" if got else "trophy_empty", cup.size / 2.0, 1.0))
		cell.add_child(cup)
		var text := Style.label(entry["name"] if got else "???", Style.TEXT if got else Style.MUTED)
		text.mouse_filter = MOUSE_FILTER_PASS
		cell.add_child(text)
		grid.add_child(cell)
	_list.add_child(grid)
	_list.add_child(Style.paragraph("Hover a trophy to see what it's for.", 400.0, Style.MUTED))


func _fill_stats() -> void:
	var rows := [
		["Rupees earned, all time", Style.short_rupees(_state.earned_total)],
		["Earning now", Style.per_second(_state.income_per_second())],
		["Customers served", str(_state.stat("served"))],
		["Glasses poured", str(_state.stat("poured"))],
		["Perfect pours", str(_state.stat("perfect"))],
		["Best streak", str(_state.best_streak)],
		["Batches fried", str(_state.stat("fried"))],
		["Golden glasses clicked", str(_state.stat("golden"))],
		["Frenzies", str(_state.stat("frenzies"))],
		["Helpers owned", str(_state.total_helpers())],
		["Branches opened", str(_state.branches)],
		["Days at the kadai", str(_state.stat("days"))],
		["Time at the counter", _time_text(_state.stat("seconds"))],
		["Trophies", "%d of %d" % [_state.achievements.size(), Milestones.ACHIEVEMENTS.size()]],
	]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 2)
	for row in rows:
		var name := Style.label(row[0], Style.MUTED)
		name.size_flags_horizontal = SIZE_EXPAND_FILL
		grid.add_child(name)
		grid.add_child(Style.label(row[1]))
	_list.add_child(grid)


static func _time_text(seconds: int) -> String:
	if seconds < 3600:
		return "%d min" % (seconds / 60)
	return "%dh %02dm" % [seconds / 3600, (seconds % 3600) / 60]


func _buy_button(text: String, cost: int, allowed: Callable, on_press: Callable) -> Button:
	var button := Style.button(text, on_press)
	button.custom_minimum_size.x = 76
	_buys.append([button, cost, allowed])
	return button


## One line: an icon, the name and what it does, what it earns, and a button.
func _row(id: String, title: String, about: String, earns: String, action: Control) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(22, 22)
	var symbol: String = ICONS.get(id, "")
	if symbol != "":
		icon.draw.connect(func() -> void:
			icon.draw_rect(Rect2(Vector2.ZERO, icon.size), Style.PANEL_DARK)
			Style.draw_symbol(icon, symbol, icon.size / 2.0, 1.4))
	row.add_child(icon)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", -2)
	text.add_child(Style.label(title, Style.TEXT if id != "" else Style.MUTED))
	text.add_child(Style.paragraph(about, 250.0, Style.MUTED))
	row.add_child(text)
	if earns != "":
		row.add_child(Style.label(earns, Style.GOOD))
	if action != null:
		action.size_flags_vertical = SIZE_SHRINK_CENTER
		row.add_child(action)
	return row
