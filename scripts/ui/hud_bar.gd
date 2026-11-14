class_name HudBar
extends PanelContainer
## The service screen's top bar: day, a clock dial that fills as the day goes,
## the part of the day and the weather, the kadai level, a coin purse whose
## number rolls up, and the menu button.

signal menu_pressed

const ROLL_SPEED := 8.0

var _service: Service
var _state: KadaiState
var _clock: Control
var _time_label: Label
var _phase: Label
var _level: Control
var _money: Label
var _today: Label
## The money shown, rolling towards the real amount.
var _shown_money := 0.0


func _init(service: Service) -> void:
	_service = service
	_state = service.state
	_shown_money = _state.money


func _ready() -> void:
	theme_type_variation = "HudPanel"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)

	row.add_child(_tag("Day %d · %s" % [_state.day, Catalog.weekday_short(_state.day)]))
	_clock = Control.new()
	_clock.custom_minimum_size = Vector2(20, 18)
	_clock.draw.connect(_draw_clock)
	row.add_child(_clock)
	_time_label = Style.label("")
	_time_label.custom_minimum_size.x = 52
	row.add_child(_time_label)
	_phase = Style.label("", Style.MUTED)
	_phase.size_flags_horizontal = SIZE_EXPAND_FILL
	_phase.clip_text = true
	row.add_child(_phase)

	_level = Control.new()
	_level.custom_minimum_size = Vector2(64, 18)
	_level.draw.connect(_draw_level)
	row.add_child(_level)

	var purse := Control.new()
	purse.custom_minimum_size = Vector2(14, 18)
	purse.draw.connect(func() -> void: Style.draw_symbol(purse, "coin", Vector2(7, 9), 1.3))
	row.add_child(purse)
	var money_box := VBoxContainer.new()
	money_box.add_theme_constant_override("separation", -4)
	_money = Style.label("", Style.ACCENT)
	money_box.add_child(_money)
	_today = Style.label("", Style.MUTED, 8)
	money_box.add_child(_today)
	row.add_child(money_box)

	var menu := Style.button("Menu", func() -> void: menu_pressed.emit(), true)
	menu.custom_minimum_size.y = 16
	row.add_child(menu)


func _process(delta: float) -> void:
	_shown_money = lerpf(_shown_money, float(_state.money), minf(1.0, delta * ROLL_SPEED))
	if absf(_shown_money - _state.money) < 0.5:
		_shown_money = _state.money
	_money.text = Style.rupees(roundi(_shown_money))
	var earned := int(_state.today["revenue"]) + int(_state.today["tips"])
	_today.text = "+%s today" % Style.rupees(earned)
	_time_label.text = _service.clock.time_text()
	var phase: String = _service.clock.phase()["name"]
	_phase.text = phase + ("  ·  Raining" if _service.is_raining() else "")
	_clock.queue_redraw()
	_level.queue_redraw()


## Where the money sits, for coins flying in. In this bar's parent's space.
func money_point() -> Vector2:
	return _money.global_position + _money.size / 2.0


func punch_money() -> void:
	_money.pivot_offset = _money.size / 2.0
	var punch := create_tween()
	punch.tween_property(_money, "scale", Vector2(1.25, 1.25), 0.06)
	punch.tween_property(_money, "scale", Vector2.ONE, 0.14)


func _tag(text: String) -> Control:
	var label := Style.label(text, Style.INK)
	var tag := PanelContainer.new()
	tag.theme_type_variation = "TagPanel"
	tag.add_child(label)
	return tag


## A small clock face: the hand shows the hour, the ring fills as the day goes.
func _draw_clock() -> void:
	var center := Vector2(10, 9)
	_clock.draw_circle(center, 8.0, Style.PAPER)
	_clock.draw_arc(center, 8.0, -PI / 2.0, -PI / 2.0 + TAU * _service.clock.progress(), 24, Style.ACCENT, 2.0)
	var minutes := _service.clock.minutes()
	var hour_angle := TAU * fmod(minutes / 60.0, 12.0) / 12.0 - PI / 2.0
	_clock.draw_line(center, center + Vector2(cos(hour_angle), sin(hour_angle)) * 5.0, Style.INK, 1.0)
	var minute_angle := TAU * fmod(minutes, 60.0) / 60.0 - PI / 2.0
	_clock.draw_line(center, center + Vector2(cos(minute_angle), sin(minute_angle)) * 6.5, Style.LINE, 1.0)
	_clock.draw_circle(center, 1.0, Style.INK)
	var weather := "cloud" if _service.is_raining() else ("sun" if minutes < 1110.0 else "")
	if weather != "":
		Style.draw_symbol(_clock, weather, center + Vector2(9, -5), 0.6)


## A star badge with the level number and a thin progress bar.
func _draw_level() -> void:
	var font := _level.get_theme_default_font()
	Style.draw_symbol(_level, "star", Vector2(8, 9), 1.6)
	var level_text := str(_state.level())
	var width := font.get_string_size(level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	_level.draw_string(font, Vector2(8 - width / 2.0, 12), level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Style.INK)
	var bar := Rect2(20, 7, 40, 4)
	_level.draw_rect(bar, Style.PANEL_DARK)
	_level.draw_rect(Rect2(bar.position, Vector2(bar.size.x * _state.level_progress(), bar.size.y)), Style.ACCENT)
	_level.draw_rect(bar, Style.WOOD_EDGE, false, 1.0)
