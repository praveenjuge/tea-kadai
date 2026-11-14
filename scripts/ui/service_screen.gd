class_name ServiceScreen
extends Control
## The live day: street view on top, tea and vadai stations below, with a
## pause menu and little flourishes. Maps input to Service methods; holds no
## game rules itself.

signal day_finished
## "settings", "help" or "quit", from the pause menu.
signal menu_requested(choice: String)

const TOAST_SECONDS := 2.6
const CLOSE_DELAY := 2.5
const PHASE_BANNERS := {
	"morning_rush": ["Morning rush!", Style.ACCENT],
	"afternoon": ["Quiet afternoon", Style.MUTED],
	"evening_rush": ["Evening rush!", Style.ACCENT],
	"closing": ["Closing time", Style.MUTED],
}

var _state: KadaiState
var _service: Service
var _sound: SoundBoard
var _street: StreetView
var _effects := EffectsLayer.new()
var _tea_panel: TeaPanel
var _fryer_panel: FryerPanel
var _tray_panel: TrayPanel
var _clock: Label
var _phase: Label
var _money: Label
var _toast: Label
var _toast_left := 0.0
var _hint: Label
var _pause_menu: Control
var _paused := false
var _was_raining := false


func _init(state: KadaiState, sound: SoundBoard) -> void:
	_state = state
	_sound = sound
	_service = Service.new(state)


func _ready() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	root.add_child(_build_top_bar())
	_street = StreetView.new(_service)
	_street.size_flags_vertical = SIZE_EXPAND_FILL
	_street.seat_clicked.connect(_on_seat_clicked)
	_street.answered.connect(func(seat: int, index: int) -> void: _service.answer(seat, index))
	root.add_child(_street)

	# First-day hint along the top of the street, until the first sale.
	_hint = Style.outlined("Make tea, then hold the button to pour and let go in the green. Click a customer to serve them.")
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	_hint.offset_top = 4
	_hint.offset_bottom = 18
	_hint.mouse_filter = MOUSE_FILTER_IGNORE
	_hint.visible = _state.day == 1
	_street.add_child(_hint)

	# Messages show along the bottom of the street, close to the stations.
	_toast = Style.outlined("")
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	_toast.offset_top = -18
	_toast.offset_bottom = -4
	_toast.mouse_filter = MOUSE_FILTER_IGNORE
	_street.add_child(_toast)

	var stations := HBoxContainer.new()
	stations.add_theme_constant_override("separation", 0)
	stations.custom_minimum_size.y = 118
	_tea_panel = TeaPanel.new(_service)
	_fryer_panel = FryerPanel.new(_service)
	_tray_panel = TrayPanel.new(_service)
	for panel in [_tea_panel, _fryer_panel, _tray_panel]:
		stations.add_child(panel)
	root.add_child(stations)

	_effects.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_effects.coin_landed.connect(_punch_money)
	add_child(_effects)
	_pause_menu = _build_pause_menu()
	add_child(_pause_menu)

	_service.message.connect(_show_toast)
	_service.customer_arrived.connect(_street.on_arrived)
	_service.customer_left.connect(_on_customer_left)
	_service.said.connect(_street.say)
	_service.asked.connect(_street.ask)
	_service.day_over.connect(_on_day_over)
	_service.happened.connect(_sound.on_event)
	_service.happened.connect(_on_happened)
	_service.phase_started.connect(_on_phase_started)
	_show_toast("%s. The kadai is open!" % Catalog.date_text(_state.day))


func _build_top_bar() -> Control:
	var bar := PanelContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	bar.add_child(row)
	row.add_child(Style.label("Day %d · %s" % [_state.day, Catalog.weekday_short(_state.day)], Style.ACCENT))
	_clock = Style.label("")
	row.add_child(_clock)
	_phase = Style.label("", Style.MUTED)
	_phase.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(_phase)
	_money = Style.label("", Style.ACCENT)
	row.add_child(_money)
	var menu := Style.button("Menu", _toggle_pause, true)
	menu.custom_minimum_size.y = 14
	row.add_child(menu)
	return bar


func _build_pause_menu() -> Control:
	var cover := Control.new()
	cover.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	cover.mouse_filter = MOUSE_FILTER_STOP
	cover.visible = false
	var dim := ColorRect.new()
	dim.color = Color(Style.BG, 0.75)
	dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	cover.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	cover.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 200
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	box.add_child(Style.label("Paused", Style.ACCENT, Style.TITLE_SIZE))
	box.add_child(Style.label(Catalog.date_text(_state.day), Style.MUTED))
	box.add_child(Style.button("Back to the counter", _toggle_pause))
	box.add_child(Style.button("Settings", func() -> void: menu_requested.emit("settings"), true))
	box.add_child(Style.button("How to play", func() -> void: menu_requested.emit("help"), true))
	box.add_child(Style.button("Quit to title", func() -> void: menu_requested.emit("quit"), true))
	box.add_child(Style.paragraph("Quitting replays today from the morning.", 180.0, Style.MUTED))
	return cover


func _process(delta: float) -> void:
	if not _paused:
		_service.update(delta)
	_clock.text = _service.clock.time_text()
	_phase.text = _service.clock.phase()["name"] + ("  ·  Raining" if _service.is_raining() else "")
	var earned := int(_state.today["revenue"]) + int(_state.today["tips"])
	_money.text = "%s today · %s" % [Style.rupees(earned), Style.rupees(_state.money)]
	_update_sound()
	_tea_panel.refresh()
	_fryer_panel.refresh()
	_tray_panel.refresh()
	if _hint.visible and int(_state.today["served"]) > 0:
		_hint.visible = false
	_toast_left = maxf(0.0, _toast_left - delta)
	_toast.modulate.a = clampf(_toast_left / 0.5, 0.0, 1.0)


func _update_sound() -> void:
	var tea := _service.tea
	var pouring := tea.stage == TeaStation.Stage.POURING and not _paused
	_sound.set_loop("pour_loop", 1.0 if pouring else 0.0, 0.85 + tea.pour_height * 0.5)
	var frying := not _service.fryer.is_empty() and not _paused and not _service.closed
	_sound.set_loop("sizzle_loop", 1.0 if frying else 0.0)
	_sound.set_loop("street_loop", 0.0 if _paused else 1.0)
	var raining := _service.is_raining()
	_sound.set_loop("rain_loop", 1.0 if raining and not _paused else 0.0)
	_sound.set_time_of_day(_service.clock.minutes())
	if raining and not _was_raining:
		_effects.banner("Rain! Everyone wants tea.", Color("8ab4e0"))
	_was_raining = raining


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if _paused or _service.closed:
		return
	if event.is_action_released("tea"):
		_service.tea_release()
	elif event.is_action_pressed("tea"):
		_service.tea_press()
	elif event.is_action_pressed("ginger"):
		_service.set_tea_kind("tea" if _service.tea_kind == "ginger_tea" else "ginger_tea")
	elif event.is_action_pressed("fry"):
		_service.fry_press()
	else:
		for i in _service.seats.size():
			if event.is_action_pressed("serve_%d" % (i + 1)):
				_service.serve(i)


func _toggle_pause() -> void:
	if _service.closed:
		return
	_paused = not _paused
	_pause_menu.visible = _paused
	if _paused:
		_service.tea_release()


func _on_seat_clicked(seat: int) -> void:
	if not _paused and not _service.closed:
		_service.serve(seat)


func _on_customer_left(seat: int, customer: Dictionary, outcome: String) -> void:
	_street.on_left(seat, customer, outcome)
	if outcome == "served":
		var from := _street.position + _street.seat_point(seat)
		var to := _money.global_position - global_position + _money.size / 2.0
		_effects.fly_coins(from, to, 2 + int(customer["tip"]) / 2)


func _on_happened(event: String, _amount: int) -> void:
	match event:
		"poured_perfect":
			_effects.sparkle(_tea_panel.glass_point() - global_position)
		"recipe":
			_effects.banner("New recipe: ginger tea!", Style.GOOD)
		"treat":
			_effects.banner("Karthik passed! Double tips!", Style.GOOD)


func _on_phase_started(phase: Dictionary) -> void:
	var banner: Array = PHASE_BANNERS.get(phase["id"], [])
	if not banner.is_empty():
		_effects.banner(banner[0], banner[1])
	_sound.set_rush(phase["id"] in ["morning_rush", "evening_rush"])


func _punch_money() -> void:
	_money.pivot_offset = _money.size / 2.0
	var punch := create_tween()
	punch.tween_property(_money, "scale", Vector2(1.2, 1.2), 0.06)
	punch.tween_property(_money, "scale", Vector2.ONE, 0.12)


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast_left = TOAST_SECONDS


func _on_day_over() -> void:
	_sound.set_rush(false)
	_show_toast("Shutters down. Time to count the money!")
	get_tree().create_timer(CLOSE_DELAY).timeout.connect(func() -> void: day_finished.emit())
