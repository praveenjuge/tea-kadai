class_name ServiceScreen
extends Control
## The live day: street view on top, tea and vadai stations below.
## Maps input actions to Service methods; holds no game rules itself.

signal day_finished

const TOAST_SECONDS := 2.6
const CLOSE_DELAY := 2.5

var _state: KadaiState
var _service: Service
var _street: StreetView
var _tea_panel: TeaPanel
var _fryer_panel: FryerPanel
var _tray_panel: TrayPanel
var _clock: Label
var _phase: Label
var _money: Label
var _toast: Label
var _toast_left := 0.0
var _pause_cover: ColorRect
var _paused := false


func _init(state: KadaiState) -> void:
	_state = state
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
	root.add_child(_street)

	var stations := HBoxContainer.new()
	stations.add_theme_constant_override("separation", 0)
	_tea_panel = TeaPanel.new(_service)
	_fryer_panel = FryerPanel.new(_service)
	_tray_panel = TrayPanel.new(_service)
	for panel in [_tea_panel, _fryer_panel, _tray_panel]:
		stations.add_child(panel)
	root.add_child(stations)

	_toast = Style.label("")
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	_toast.offset_top = 24
	_toast.add_theme_color_override("font_outline_color", Style.BG)
	_toast.add_theme_constant_override("outline_size", 4)
	add_child(_toast)

	_pause_cover = ColorRect.new()
	_pause_cover.color = Color(Style.BG, 0.8)
	_pause_cover.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_pause_cover.mouse_filter = MOUSE_FILTER_STOP
	var paused_label := Style.label("Paused. Press %s to carry on." % Controls.hint("pause"), Style.TEXT, Style.TITLE_SIZE)
	paused_label.set_anchors_and_offsets_preset(PRESET_CENTER)
	paused_label.grow_horizontal = GROW_DIRECTION_BOTH
	_pause_cover.add_child(paused_label)
	_pause_cover.visible = false
	add_child(_pause_cover)

	_service.message.connect(_show_toast)
	_service.customer_arrived.connect(_street.on_arrived)
	_service.customer_left.connect(_street.on_left)
	_service.day_over.connect(_on_day_over)
	_show_toast("Day %d. The kadai is open!" % _state.day)


func _build_top_bar() -> Control:
	var bar := PanelContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	bar.add_child(row)
	row.add_child(Style.label("Day %d" % _state.day, Style.ACCENT))
	_clock = Style.label("")
	row.add_child(_clock)
	_phase = Style.label("", Style.MUTED)
	_phase.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(_phase)
	_money = Style.label("", Style.ACCENT)
	row.add_child(_money)
	row.add_child(Style.label("%s pause" % Controls.hint("pause"), Style.MUTED))
	return bar


func _process(delta: float) -> void:
	if not _paused:
		_service.update(delta)
	_clock.text = _service.clock.time_text()
	_phase.text = _service.clock.phase()["name"]
	var earned := int(_state.today["revenue"]) + int(_state.today["tips"])
	_money.text = "%s today · %s" % [Style.rupees(earned), Style.rupees(_state.money)]
	_tea_panel.refresh()
	_fryer_panel.refresh()
	_tray_panel.refresh()
	_toast_left = maxf(0.0, _toast_left - delta)
	_toast.modulate.a = clampf(_toast_left / 0.5, 0.0, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_paused = not _paused
		_pause_cover.visible = _paused
		if _paused:
			_service.tea_pour_release()
		get_viewport().set_input_as_handled()
		return
	if _paused or _service.closed:
		return
	if event.is_action_released("tea_pour"):
		_service.tea_pour_release()
	elif event.is_action_pressed("tea_pour"):
		_service.tea_pour_start()
	elif event.is_action_pressed("tea_next"):
		_service.tea_next()
	elif event.is_action_pressed("fry_drop"):
		_service.fry_drop()
	else:
		for i in Fryer.SLOTS:
			if event.is_action_pressed("fry_take_%d" % (i + 1)):
				_service.fry_take(i)
		for i in Catalog.SEATS:
			if event.is_action_pressed("serve_%d" % (i + 1)):
				_service.serve(i)


func _on_seat_clicked(seat: int) -> void:
	if not _paused and not _service.closed:
		_service.serve(seat)


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast_left = TOAST_SECONDS


func _on_day_over() -> void:
	_show_toast("Shutters down. Time to count the money!")
	get_tree().create_timer(CLOSE_DELAY).timeout.connect(func() -> void: day_finished.emit())
