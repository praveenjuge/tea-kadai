class_name MenuOverlay
extends Control
## A dimmed layer over the game with one panel in the middle. Builds the
## settings, how to play, credits, and yes/no panels.

signal closed
signal confirmed

var _box := VBoxContainer.new()


func _init(title: String, width: float = 320.0) -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(Style.BG, 0.78)
	dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = width
	center.add_child(panel)
	_box.add_theme_constant_override("separation", 6)
	panel.add_child(_box)
	_box.add_child(Style.label(title, Style.ACCENT, Style.TITLE_SIZE))


func add(node: Control) -> Control:
	_box.add_child(node)
	return node


func add_buttons(buttons: Array[Button]) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 6)
	for button in buttons:
		row.add_child(button)
	_box.add_child(HSeparator.new())
	_box.add_child(row)


func close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey or event is InputEventMouseButton:
		# Nothing underneath reacts while a panel is open.
		get_viewport().set_input_as_handled()


# --- Panels -----------------------------------------------------------------

static func settings_panel(settings: Settings) -> MenuOverlay:
	var overlay := MenuOverlay.new("Settings")
	var names := {"Music": "Music", "Effects": "Sound effects", "Street": "Street sounds"}
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	for bus in Settings.BUSES:
		grid.add_child(Style.label(names[bus]))
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = settings.volume[bus]
		slider.custom_minimum_size.x = 160
		slider.focus_mode = FOCUS_NONE
		slider.value_changed.connect(func(value: float) -> void:
			settings.volume[bus] = value
			settings.apply_audio())
		grid.add_child(slider)
	overlay.add(grid)
	var full := CheckBox.new()
	full.text = "Fullscreen"
	full.focus_mode = FOCUS_NONE
	full.button_pressed = settings.fullscreen
	full.toggled.connect(func(on: bool) -> void:
		settings.fullscreen = on
		settings.apply_window())
	overlay.add(full)
	overlay.add_buttons([Style.button("Done", func() -> void:
		settings.save()
		overlay.close())])
	return overlay


static func how_to_play() -> MenuOverlay:
	var overlay := MenuOverlay.new("How to play", 400.0)
	var steps := [
		["bun", "Morning", "Buy milk, tea powder and snacks at the market. Leftovers keep for tomorrow."],
		["tea", "Tea", "Press Make tea. When the glass is full, hold the button and let go while the meter is in the green."],
		["vadai", "Vadai", "Fry a batch, then lift them out once they turn golden."],
		["coin", "Serve", "Click a customer when their bubble has a green border. Bright items are ready, faded ones aren't yet."],
		["heart", "Regulars", "Some faces come back every day. Remember their usual and they'll remember you."],
		["star", "Night", "Count the day's money and save up for upgrades."],
	]
	for step in steps:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var icon := Control.new()
		icon.custom_minimum_size = Vector2(28, 24)
		var symbol: String = step[0]
		icon.draw.connect(func() -> void: Style.draw_symbol(icon, symbol, Vector2(14, 12), 2.0))
		row.add_child(icon)
		var text := VBoxContainer.new()
		text.add_theme_constant_override("separation", 0)
		text.add_child(Style.label(step[1], Style.ACCENT))
		text.add_child(Style.paragraph(step[2], 340.0, Style.TEXT))
		row.add_child(text)
		overlay.add(row)
	overlay.add(Style.label("Space tea · G ginger tea · F vadai · 1 to 5 serve · P pause · M sound", Style.MUTED))
	overlay.add_buttons([Style.button("Got it", overlay.close)])
	return overlay


static func credits() -> MenuOverlay:
	var overlay := MenuOverlay.new("Credits")
	for line in [
		["Tea Kadai", Style.TEXT],
		["Made by Praveen Juge, with Claude.", Style.TEXT],
		["Font: Pixelify Sans by the Pixelify Sans Project Authors, SIL Open Font License.", Style.MUTED],
		["Art, sounds and music: placeholders made in code for now.", Style.MUTED],
		["Built with the Godot Engine.", Style.MUTED],
	]:
		overlay.add(Style.paragraph(line[0], 300.0, line[1]))
	overlay.add_buttons([Style.button("Back", overlay.close)])
	return overlay


static func confirm(title: String, text: String, yes: String, no: String) -> MenuOverlay:
	var overlay := MenuOverlay.new(title)
	overlay.add(Style.paragraph(text, 300.0))
	overlay.add_buttons([
		Style.button(no, overlay.close, true),
		Style.button(yes, func() -> void:
			overlay.confirmed.emit()
			overlay.close()),
	])
	return overlay
