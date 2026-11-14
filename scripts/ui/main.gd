extends Control
## Runs the game: the title screen, then each day's morning market, live
## service and night summary, with fades between them. Saves at the start of
## every morning. Pass "-- --service" to skip straight to service.

const SHUTTER_DOWN := 0.35
const SHUTTER_UP := 0.45
const FADE_SECONDS := 0.25

var state: KadaiState
var settings := Settings.load_saved()
var sound := SoundBoard.new()
var _screen: Control
## Screens live here; overlays sit above them so they get input first.
var _stage := Control.new()
var _overlays := CanvasLayer.new()
var _shutter := Shutter.new()
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
	var shutter_layer := CanvasLayer.new()
	shutter_layer.layer = 10
	add_child(shutter_layer)
	_shutter.theme = theme
	_shutter.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_fade.color = Color(Style.BG, 0.0)
	_fade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_fade.mouse_filter = MOUSE_FILTER_IGNORE
	shutter_layer.add_child(_fade)
	shutter_layer.add_child(_shutter)

	if "--service" in OS.get_cmdline_user_args():
		state = KadaiState.new()
		_show_service()
	else:
		_show_title()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mute"):
		sound.toggle_mute()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		sound.stop_all()
		_note_seen()


func _quit() -> void:
	sound.stop_all()
	_note_seen()
	get_tree().quit()


## Remembers when the player left, for "while you were away" money.
func _note_seen() -> void:
	if state != null and SaveGame.exists():
		SaveGame.touch()


## Helpers kept working while the game was closed; pays it out and says so.
func _collect_away(seconds: float) -> void:
	if seconds < 60.0 or state.income_per_second() <= 0.0:
		return
	var amount := state.collect_away(seconds)
	if amount <= 0:
		return
	var hours := seconds / 3600.0
	var away := ("%d minutes" % roundi(seconds / 60.0)) if hours < 1.0 else ("%.1f hours" % minf(hours, Catalog.AWAY_MAX_HOURS))
	var note := MenuOverlay.new("While you were away…")
	note.add(Style.paragraph("Your helpers kept the tea flowing for %s." % away, 300.0))
	note.add(Style.label("+%s" % Style.short_rupees(amount), Style.GOOD, Style.TITLE_SIZE))
	note.add_buttons([Style.button("Nandri!", note.close)])
	open_overlay(note)
	sound.play("coin")


func _open_shop(screen: Control) -> void:
	var shop := HelpersShop.new(state)
	shop.bought.connect(func(_kind: String) -> void: sound.play("coin"))
	if screen.has_method("refresh"):
		shop.closed.connect(screen.refresh)
	open_overlay(shop)


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


## Whether the shutter or the fade is (partly) covering, between screens.
func covered() -> bool:
	return _shutter.amount > 0.02 or _fade.color.a > 0.05


## Swaps to the next screen. Opening and closing the kadai pull the shutter
## down and roll it back up; everything else is a quick fade.
func _swap(next: Control, shutter: bool = false) -> void:
	if not shutter:
		if _screen != null:
			var out := create_tween()
			out.tween_property(_fade, "color:a", 1.0, FADE_SECONDS)
			await out.finished
			_screen.queue_free()
		_screen = next
		_stage.add_child(next)
		next.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		create_tween().tween_property(_fade, "color:a", 0.0, FADE_SECONDS)
		return
	if _screen != null:
		sound.play("shutter")
		var down := create_tween()
		down.tween_property(_shutter, "amount", 1.0, SHUTTER_DOWN).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await down.finished
		_screen.queue_free()
	_screen = next
	_stage.add_child(next)
	next.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if _shutter.amount > 0.0:
		var up := create_tween()
		up.tween_interval(0.12)
		up.tween_callback(sound.play.bind("shutter", 1.1))
		up.tween_property(_shutter, "amount", 0.0, SHUTTER_UP).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


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
			# Read before the morning save notes that we're back.
			var away := SaveGame.seconds_away()
			_collect_away(away)
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
			_quit()


func _start_new_game() -> void:
	state = KadaiState.new()
	var intro := IntroScreen.new()
	intro.finished.connect(_show_morning)
	_swap(intro)


func _show_morning() -> void:
	var help := state.morning_help()
	SaveGame.save(state)
	var screen := MorningScreen.new(state, help)
	screen.open_requested.connect(_show_service)
	screen.shop_requested.connect(_open_shop.bind(screen))
	screen.prices_requested.connect(func() -> void:
		open_overlay(MenuOverlay.prices(state)).closed.connect(screen.refresh))
	_swap(screen)
	sound.set_scene("morning")
	# A temple bell somewhere down the street as the day starts.
	get_tree().create_timer(0.9).timeout.connect(sound.play.bind("temple_bell"))


func _show_service() -> void:
	var screen := ServiceScreen.new(state, sound)
	screen.day_finished.connect(_show_night)
	screen.menu_requested.connect(_on_service_menu)
	_swap(screen, true)
	sound.set_scene("service")


func _on_service_menu(choice: String) -> void:
	match choice:
		"settings":
			open_overlay(MenuOverlay.settings_panel(settings))
		"help":
			open_overlay(MenuOverlay.how_to_play())
		"glossary":
			open_overlay(MenuOverlay.glossary())
		"quit":
			_show_title()


func _show_night() -> void:
	state.close_day()
	var screen := NightScreen.new(state, sound)
	screen.next_requested.connect(_on_next_day)
	screen.shop_requested.connect(_open_shop.bind(screen))
	screen.branch_requested.connect(_ask_branch)
	_swap(screen, true)
	sound.set_scene("night")
	if state.is_week_end():
		# Once the day's tally has counted up, celebrate the week.
		get_tree().create_timer(3.2).timeout.connect(func() -> void:
			if _screen == screen:
				open_overlay(MenuOverlay.week_done(state, screen)))


func _ask_branch() -> void:
	var ask := open_overlay(MenuOverlay.confirm("Open a branch in %s?" % state.next_branch_name(),
		"You start fresh there: money, stock, upgrades, helpers and staff reset. Your recipes, regulars and "
		+ "the day carry on, and every branch adds +%d%% to all earnings for good." % roundi(Catalog.BRANCH_BONUS * 100),
		"Open it", "Not yet"))
	ask.confirmed.connect(func() -> void:
		if state.open_branch():
			sound.play("golden")
			_on_next_day())


func _on_next_day() -> void:
	state.next_day()
	_show_morning()
