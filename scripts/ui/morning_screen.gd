class_name MorningScreen
extends Control
## The paused morning: buy stock at the market and set today's prices.

signal open_requested

var _state: KadaiState
var _money: Label
var _market := {}  # stock id -> {"have": Label, "buy": Button, "undo": Button}
var _price_labels := {}  # menu id -> Label
var _can_make: Label


func _init(state: KadaiState) -> void:
	_state = state


func _ready() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	var header := HBoxContainer.new()
	header.add_child(Style.label("Day %d · Morning" % _state.day, Style.TEXT, Style.TITLE_SIZE))
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(spacer)
	_money = Style.label("", Style.ACCENT, Style.TITLE_SIZE)
	header.add_child(_money)
	root.add_child(header)
	root.add_child(Style.label("Stock up at the market and set today's prices. Leftover stock keeps for tomorrow.", Style.MUTED))

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 10)
	columns.size_flags_vertical = SIZE_EXPAND_FILL
	columns.add_child(_build_market())
	columns.add_child(_build_prices())
	root.add_child(columns)

	var footer := HBoxContainer.new()
	_can_make = Style.label("", Style.MUTED)
	_can_make.size_flags_horizontal = SIZE_EXPAND_FILL
	footer.add_child(_can_make)
	footer.add_child(Style.button("Open the kadai →", func() -> void: open_requested.emit()))
	root.add_child(footer)
	_refresh()


func _build_market() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(Style.label("Market", Style.ACCENT))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 3)
	box.add_child(grid)
	for stock_id in Catalog.MARKET_ORDER:
		var pack: Dictionary = Catalog.MARKET[stock_id]
		var title := Style.label("%s (%s)" % [pack["name"], pack["pack"].to_lower()])
		title.size_flags_horizontal = SIZE_EXPAND_FILL
		grid.add_child(title)
		var have := Style.label("", Style.MUTED)
		have.custom_minimum_size.x = 64
		grid.add_child(have)
		var buy := Style.button("Buy %s" % Style.rupees(pack["cost"]), _on_buy.bind(stock_id))
		grid.add_child(buy)
		var undo := Style.button("Undo", _on_undo.bind(stock_id))
		grid.add_child(undo)
		_market[stock_id] = {"have": have, "buy": buy, "undo": undo}
	return panel


func _build_prices() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 210
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(Style.label("Today's prices", Style.ACCENT))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 3)
	box.add_child(grid)
	for item in Catalog.MENU_ORDER:
		var title := Style.label(Catalog.MENU[item]["name"])
		title.size_flags_horizontal = SIZE_EXPAND_FILL
		grid.add_child(title)
		grid.add_child(Style.button("-", _on_price.bind(item, -1)))
		var price := Style.label("")
		price.custom_minimum_size.x = 26
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(price)
		grid.add_child(Style.button("+", _on_price.bind(item, 1)))
		var usual := Style.label("costs ₹%d" % ceili(Catalog.unit_cost(item)), Style.MUTED)
		grid.add_child(usual)
		_price_labels[item] = price
	var note := Style.label("Charge more than the usual price and some customers will walk away.", Style.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.x = 190
	box.add_child(note)
	return panel


func _on_buy(stock_id: String) -> void:
	_state.buy(stock_id)
	_refresh()


func _on_undo(stock_id: String) -> void:
	_state.undo_buy(stock_id)
	_refresh()


func _on_price(item: String, change: int) -> void:
	_state.set_price(item, int(_state.prices[item]) + change)
	_refresh()


func _refresh() -> void:
	_money.text = Style.rupees(_state.money)
	for stock_id in Catalog.MARKET_ORDER:
		var row: Dictionary = _market[stock_id]
		row["have"].text = "%d %s" % [_state.stock[stock_id], Catalog.MARKET[stock_id]["unit"]]
		row["buy"].disabled = not _state.can_afford(stock_id)
		row["undo"].disabled = _state.bought_today(stock_id) == 0
	for item in Catalog.MENU_ORDER:
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
	for item in Catalog.MENU_ORDER:
		parts.append("%d %s" % [_state.how_many(item), Catalog.MENU[item]["name"].to_lower()])
	_can_make.text = "Enough stock for: " + ", ".join(parts)
