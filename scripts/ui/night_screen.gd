class_name NightScreen
extends Control
## End of day: what you earned, who you served, and a word from the street.

signal next_requested

var _state: KadaiState


func _init(state: KadaiState) -> void:
	_state = state


func _ready() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 300
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	var today: Dictionary = _state.today
	box.add_child(Style.label("Day %d is done" % _state.day, Style.TEXT, Style.TITLE_SIZE))
	box.add_child(Style.label(_street_word(today), Style.MUTED))
	box.add_child(HSeparator.new())

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	box.add_child(grid)
	_row(grid, "Sales", Style.rupees(today["revenue"]))
	for item in Catalog.MENU_ORDER:
		var sold := int(today["sold"].get(item, 0))
		if sold > 0:
			_row(grid, "   %s × %d" % [Catalog.MENU[item]["name"], sold], "", Style.MUTED)
	_row(grid, "Tips", Style.rupees(today["tips"]))
	_row(grid, "Spent at the market", Style.rupees(-int(today["spent"])))
	var profit := _state.profit_today()
	_row(grid, "Profit today", Style.rupees(profit), Style.GOOD if profit >= 0 else Style.BAD)
	_row(grid, "Money now", Style.rupees(_state.money), Style.ACCENT)
	box.add_child(HSeparator.new())

	var people := "Served %d" % today["served"]
	if int(today["walked_out"]) > 0:
		people += " · %d walked off" % today["walked_out"]
	if int(today["too_costly"]) > 0:
		people += " · %d said too costly" % today["too_costly"]
	if int(today["no_seat"]) > 0:
		people += " · %d found no room" % today["no_seat"]
	box.add_child(Style.label(people, Style.MUTED))
	if int(today["wasted"]) > 0:
		box.add_child(Style.label("%d thrown away at closing or burnt" % today["wasted"], Style.MUTED))

	var button := Style.button("Plan tomorrow →", func() -> void: next_requested.emit())
	button.size_flags_horizontal = SIZE_SHRINK_END
	box.add_child(button)


func _row(grid: GridContainer, title: String, value: String, color: Color = Style.TEXT) -> void:
	grid.add_child(Style.label(title, color))
	var right := Style.label(value, color)
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.size_flags_horizontal = SIZE_EXPAND_FILL
	grid.add_child(right)


func _street_word(today: Dictionary) -> String:
	var served := int(today["served"])
	var lost := int(today["walked_out"]) + int(today["no_seat"])
	if served == 0:
		return "A quiet day. The crows had the street to themselves."
	if lost == 0:
		return "The retired uncle says: \"Best tea on this street, no doubt.\""
	if served >= lost * 2:
		return "An auto driver says: \"Good tea today. See you tomorrow, anna.\""
	return "A metro worker grumbles: \"Waited so long, my tea break got over!\""
