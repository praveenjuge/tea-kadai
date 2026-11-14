extends Control
## Runs the day loop: morning at the market, live service, night summary.
## Pass "-- --service" on the command line to skip straight to service.

var state := KadaiState.new()
var sound := SoundBoard.new()
var _screen: Control


func _ready() -> void:
	Controls.setup()
	theme = Style.make_theme()
	add_child(sound)
	_fit_window()
	if "--service" in OS.get_cmdline_user_args():
		_show_service()
	else:
		_show_morning()


## Opens the window as large as the screen allows at a whole-number scale, so
## pixels stay crisp. Window sizes are in physical pixels, so without this a
## Retina Mac shows the game at half size.
func _fit_window() -> void:
	if DisplayServer.get_name() == "headless" or Engine.get_write_movie_path() != "":
		return
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		return
	var screen := DisplayServer.window_get_current_screen()
	var usable := DisplayServer.screen_get_usable_rect(screen)
	var base := Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	var fit := floori(minf(usable.size.x * 0.92 / base.x, usable.size.y * 0.88 / base.y))
	var scale := maxi(1, fit)
	var window_size := Vector2i(base * scale)
	DisplayServer.window_set_size(window_size)
	DisplayServer.window_set_position(usable.position + (usable.size - window_size) / 2)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mute"):
		sound.toggle_mute()
		get_viewport().set_input_as_handled()


func _swap(next: Control) -> void:
	if _screen != null:
		_screen.queue_free()
	_screen = next
	add_child(next)
	next.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _show_morning() -> void:
	var screen := MorningScreen.new(state)
	screen.open_requested.connect(_show_service)
	_swap(screen)
	sound.set_scene("morning")


func _show_service() -> void:
	var screen := ServiceScreen.new(state, sound)
	screen.day_finished.connect(_show_night)
	_swap(screen)
	sound.set_scene("service")


func _show_night() -> void:
	var screen := NightScreen.new(state)
	screen.next_requested.connect(_on_next_day)
	_swap(screen)
	sound.set_scene("night")


func _on_next_day() -> void:
	state.next_day()
	_show_morning()
