class_name TitleScreen
extends Control
## The title: the kadai's street at dawn, alive behind the logo and menu.

## "continue", "new", "help", "settings", "credits" or "quit".
signal chosen(choice: String)

var _saved: KadaiState
var _street: StreetView
var _glass: Control


## "saved" is the saved kadai, or null when there is no save.
func _init(saved: KadaiState) -> void:
	_saved = saved


func _ready() -> void:
	var dawn := Service.new(KadaiState.new(), 1, true)
	dawn.clock.elapsed = 25.0
	_street = StreetView.new(dawn)
	_street.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_street.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_street)

	var shade := TextureRect.new()
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.38, 0.62])
	gradient.colors = PackedColorArray([Color(Style.BG, 0.94), Color(Style.BG, 0.86), Color(Style.BG, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 64
	texture.height = 4
	shade.texture = texture
	shade.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	shade.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(shade)

	var level := _saved.big_numbers_seen if _saved != null else 0
	var ticker := NewsTicker.new(Chennai.ticker(level))
	ticker.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	ticker.offset_top = -14
	add_child(ticker)

	# Left-aligned and vertically centred, whatever the screen height.
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.anchor_top = 0.5
	column.anchor_bottom = 0.5
	column.offset_left = 36
	column.grow_vertical = GROW_DIRECTION_BOTH
	add_child(column)

	var logo := HBoxContainer.new()
	logo.add_theme_constant_override("separation", 8)
	_glass = Control.new()
	_glass.custom_minimum_size = Vector2(30, 40)
	_glass.draw.connect(_draw_logo_glass)
	logo.add_child(_glass)
	logo.add_child(Style.outlined("TEA KADAI", Style.ACCENT, Style.HERO_SIZE))
	column.add_child(logo)
	column.add_child(Style.outlined("A little tea stall on a busy Chennai street", Style.TEXT))
	var gap := Control.new()
	gap.custom_minimum_size.y = 14
	column.add_child(gap)

	if _saved != null:
		column.add_child(_menu_button("Continue", "continue", false))
		column.add_child(_menu_button("New game", "new", true))
	else:
		column.add_child(_menu_button("New game", "new", false))
	column.add_child(_menu_button("How to play", "help", true))
	column.add_child(_menu_button("Settings", "settings", true))
	column.add_child(_menu_button("Credits", "credits", true))
	column.add_child(_menu_button("Quit", "quit", true))

	if _saved != null:
		var note := Style.outlined("Saved: day %d, %s" % [_saved.day, Catalog.date_text(_saved.day)], Style.MUTED)
		note.anchor_top = 1.0
		note.anchor_bottom = 1.0
		note.offset_left = 36
		note.offset_top = -28
		add_child(note)

	var version := Style.outlined("v" + str(ProjectSettings.get_setting("application/config/version", "dev")), Style.MUTED)
	version.anchor_left = 1.0
	version.anchor_right = 1.0
	version.anchor_top = 1.0
	version.anchor_bottom = 1.0
	version.offset_left = -80
	version.offset_right = -12
	version.offset_top = -26
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(version)

	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.6)


func _process(_delta: float) -> void:
	_glass.queue_redraw()


func _menu_button(text: String, choice: String, quiet: bool) -> Button:
	var button := Style.button(text, func() -> void: chosen.emit(choice), quiet)
	button.custom_minimum_size = Vector2(170, 22)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.size_flags_horizontal = SIZE_SHRINK_BEGIN
	return button


func _draw_logo_glass() -> void:
	var canvas := _glass
	var base := Vector2(15, 38)
	var glass := PackedVector2Array([base + Vector2(-11, -26), base + Vector2(11, -26), base + Vector2(8, 0), base + Vector2(-8, 0)])
	canvas.draw_colored_polygon(glass, Color(Style.GLASS, 0.5))
	canvas.draw_rect(Rect2(base + Vector2(-8.5, -18), Vector2(17, 18)), Style.TEA)
	canvas.draw_rect(Rect2(base + Vector2(-10, -22), Vector2(20, 5)), Style.FROTH)
	var t := Time.get_ticks_msec() / 1000.0
	for i in 3:
		var x := base.x - 6 + i * 6 + sin(t * 2.0 + i) * 2.0
		var rise := fmod(t * 7.0 + i * 5.0, 14.0)
		canvas.draw_rect(Rect2(x, base.y - 28 - rise, 1, 4), Color(Style.TEXT, 0.6 * (1.0 - rise / 14.0)))
