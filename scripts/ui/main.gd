extends Control
## Runs the game: the title screen, then each day's morning market, live
## service and night summary, with fades between them. Saves at the start of
## every morning. Pass "-- --service" to skip straight to service.

const FADE_SECONDS := 0.3

var state: KadaiState
var settings := Settings.load_saved()
var sound := SoundBoard.new()
var _screen: Control
## Screens live here; overlays sit above them so they get input first.
var _stage := Control.new()
var _overlays := CanvasLayer.new()
var _fade := ColorRect.new()


func _ready() -> void:
	Controls.setup()
	theme = Style.make_theme()
	settings.apply_audio()
	add_child(sound)
	settings.apply_window()
	_fit_window()

	_stage.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(_stage)
	_overlays.layer = 5
	add_child(_overlays)
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 10
	add_child(fade_layer)
	_fade.color = Color(Style.BG, 0.0)
	_fade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_fade.mouse_filter = MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade)

	if "--service" in OS.get_cmdline_user_args():
		state = KadaiState.new()
		_show_service()
	else:
		_show_title()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mute"):
		sound.toggle_mute()
		get_viewport().set_input_as_handled()


## Shows a menu overlay above whatever screen is up.
func open_overlay(overlay: MenuOverlay) -> MenuOverlay:
	overlay.theme = theme
	_overlays.add_child(overlay)
	return overlay


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
	var window_size := Vector2i(base * maxi(1, fit))
	DisplayServer.window_set_size(window_size)
	DisplayServer.window_set_position(usable.position + (usable.size - window_size) / 2)


## Fades out, swaps to the next screen, and fades back in.
func _swap(next: Control) -> void:
	if _screen != null:
		var out := create_tween()
		out.tween_property(_fade, "color:a", 1.0, FADE_SECONDS)
		await out.finished
		_screen.queue_free()
	_screen = next
	_stage.add_child(next)
	next.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var back := create_tween()
	back.tween_property(_fade, "color:a", 0.0, FADE_SECONDS)


func _show_title() -> void:
	var screen := TitleScreen.new(SaveGame.load_state())
	screen.chosen.connect(_on_title_choice)
	_swap(screen)
	sound.set_scene("morning")


func _on_title_choice(choice: String) -> void:
	match choice:
		"continue":
			state = SaveGame.load_state()
			if state == null:
				state = KadaiState.new()
			_show_morning()
		"new":
			if SaveGame.exists():
				var ask := open_overlay(MenuOverlay.confirm("Start a new kadai?",
					"Your saved week will be lost.", "Start fresh", "Keep it"))
				ask.confirmed.connect(_start_new_game)
			else:
				_start_new_game()
		"settings":
			open_overlay(MenuOverlay.settings_panel(settings))
		"help":
			open_overlay(MenuOverlay.how_to_play())
		"credits":
			open_overlay(MenuOverlay.credits())
		"quit":
			get_tree().quit()


func _start_new_game() -> void:
	state = KadaiState.new()
	_show_morning()


func _show_morning() -> void:
	SaveGame.save(state)
	var screen := MorningScreen.new(state)
	screen.open_requested.connect(_show_service)
	_swap(screen)
	sound.set_scene("morning")


func _show_service() -> void:
	var screen := ServiceScreen.new(state, sound)
	screen.day_finished.connect(_show_night)
	screen.menu_requested.connect(_on_service_menu)
	_swap(screen)
	sound.set_scene("service")


func _on_service_menu(choice: String) -> void:
	match choice:
		"settings":
			open_overlay(MenuOverlay.settings_panel(settings))
		"help":
			open_overlay(MenuOverlay.how_to_play())
		"quit":
			_show_title()


func _show_night() -> void:
	var screen := NightScreen.new(state, sound)
	screen.next_requested.connect(_on_next_day)
	_swap(screen)
	sound.set_scene("night")


func _on_next_day() -> void:
	state.next_day()
	_show_morning()
