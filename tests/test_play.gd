extends SceneTree
## Plays the real game through input events, the same path a player's mouse
## and keyboard take: the title screen, buying at the market stalls, opening
## the kadai, making tea and vadai, serving, the pause menu, Karthik's visit,
## the night tally, the next morning, and quitting back to the title.
## Uses its own save and settings files, so a player's save is never touched.
## Run: godot --path . -s tests/test_play.gd
## Record it: add --write-movie <path>.avi --fixed-fps 30

const PLAY_SPEED := 3.0
const SERVE_GOAL := 4

var _failures := 0
var _main: Control


func _init() -> void:
	SaveGame.path = "user://test_save.json"
	Settings.path = "user://test_settings.cfg"
	SaveGame.delete()
	_main = load("res://main.tscn").instantiate()
	root.add_child(_main)
	_run.call_deferred()


func _run() -> void:
	await _wait_for(TitleScreen)
	await _title()
	await _morning()
	await _service()
	await _night()
	await _back_to_title()
	if _failures == 0:
		print("All play checks passed.")
	else:
		printerr("%d play check(s) failed." % _failures)
	Engine.time_scale = 1.0
	SaveGame.delete()
	_main.queue_free()
	await _frames(2)
	quit(1 if _failures > 0 else 0)


func _title() -> void:
	var screen = _main._screen
	_check(screen is TitleScreen, "game opens on the title screen")
	_check(_find_button(screen, "Continue") == null, "no Continue button without a save")
	_click(_find_button(screen, "Settings"))
	await _frames(3)
	_check(_main._overlays.get_child_count() == 1, "Settings opens over the title")
	_tap(KEY_ESCAPE)
	await _frames(3)
	_check(_main._overlays.get_child_count() == 0, "Escape closes the settings")
	_click(_find_button(screen, "New game"))
	await _wait_for(MorningScreen)


func _morning() -> void:
	var screen = _main._screen
	_check(screen is MorningScreen, "New game opens the morning market")
	_check(SaveGame.exists(), "the morning is saved")
	var state: KadaiState = _main.state
	var money := state.money
	var market: MarketScene = screen._market
	await _frames(2)
	for stock_id in ["batter", "oil", "milk", "bun"]:
		var tile: Rect2 = market._tiles[stock_id]["rect"]
		_click_at(market.global_position + tile.get_center())
		await _frames(2)
	_check(state.money == money - 48 - 140 - 60 - 48, "clicking goods at the stalls buys them")
	var tile: Rect2 = market._tiles["bun"]["undo"]
	_click_at(market.global_position + tile.get_center())
	await _frames(2)
	_check(state.money == money - 48 - 140 - 60, "the red minus puts a pack back")
	_click_at(market.global_position + Rect2(market._tiles["bun"]["rect"]).get_center())
	await _frames(2)
	_check(state.how_many("vadai") > 0, "batter and oil make vadai stock")
	_click(_find_button(screen, "Open the kadai"))
	await _wait_for(ServiceScreen)


func _service() -> void:
	var screen = _main._screen
	_check(screen is ServiceScreen, "opening the kadai starts service")
	var service: Service = screen._service
	var state: KadaiState = _main.state
	var sound: SoundBoard = _main.sound
	await _frames(30)
	_check(sound._loops["street_loop"].playing, "street sounds play during service")
	_check(sound._loops["music_day"].playing, "day music plays in the morning")

	# The pause menu stops the clock.
	_tap(KEY_P)
	var paused_at := service.clock.elapsed
	await _frames(20)
	_check(screen._pause_menu.visible, "P opens the pause menu")
	_check(is_equal_approx(service.clock.elapsed, paused_at), "pausing stops the clock")
	_click(_find_button(screen._pause_menu, "Back to the counter"))
	await _frames(2)
	_check(not screen._pause_menu.visible, "Back to the counter closes the menu")

	# One glass of tea with the keyboard: one press fills it, then hold to pour.
	_tap(KEY_SPACE)
	await _frames(2)
	_check(service.tea.stage == TeaStation.Stage.FILLING, "one press of Space starts a glass")
	var guard := 0
	while not service.tea.can_pour() and guard < 300:
		guard += 1
		await process_frame
	_check(service.tea.can_pour(), "the glass fills by itself")
	_key(KEY_SPACE, true)
	guard = 0
	var heard_pour := false
	while service.tea.stage == TeaStation.Stage.POURING and guard < 600:
		guard += 1
		heard_pour = heard_pour or sound._loops["pour_loop"].playing
		var mid := (service.tea.target.x + service.tea.target.y) / 2.0
		if service.tea.pour_height >= mid:
			break
		await process_frame
	_key(KEY_SPACE, false)
	_check(heard_pour, "the pour makes a pouring sound")
	await _frames(2)
	_check(service.ready_count("tea") == 1, "the poured tea lands on the tray")
	_check(service.ready["tea"].size() > 0 and service.ready["tea"][0] >= 1.0, "letting go in the green gives a perfect pour")

	# A batch of vadai with the mouse: click Fry, wait for golden, click the kadai.
	_click(_find_button(screen._fryer_panel, "Fry"))
	await _frames(2)
	_check(service.fryer.count == Fryer.BATCH, "clicking Fry drops a whole batch in")
	Engine.time_scale = PLAY_SPEED
	guard = 0
	while service.fryer.doneness() != Fryer.Doneness.GOLDEN and guard < 2000:
		guard += 1
		await process_frame
	_click(screen._fryer_panel._art)
	await _frames(2)
	_check(service.ready_count("vadai") == Fryer.BATCH, "clicking the kadai lifts the golden batch onto the plate")

	# The tea button with the mouse: press to fill, hold to pour.
	var tea_button := _find_button(screen._tea_panel, "Make tea")
	_click(tea_button)
	guard = 0
	while not service.tea.can_pour() and guard < 300:
		guard += 1
		await process_frame
	_mouse(tea_button.get_global_rect().get_center(), true)
	guard = 0
	while service.tea.pour_height < service.tea.target.x + 0.03 and guard < 600:
		guard += 1
		await process_frame
	_mouse(tea_button.get_global_rect().get_center(), false)
	await _frames(2)
	_check(service.ready_count("tea") == 2, "holding the tea button pours a second glass")

	# Play on: keep making what people want and click them to serve.
	guard = 0
	while int(state.today["served"]) < SERVE_GOAL and guard < 6000:
		guard += 1
		await _play_turn(screen, service)
	_check(int(state.today["served"]) >= SERVE_GOAL, "served %d customers by clicking them" % state.today["served"])
	_check(int(state.today["revenue"]) > 0, "serving earns money")

	# Play on faster until Karthik arrives, then serve him.
	Engine.time_scale = 8.0
	guard = 0
	while not service.regular.is_here() and not service.closed and guard < 20000:
		guard += 1
		await _play_turn(screen, service)
	Engine.time_scale = 1.0
	_check(service.regular.is_here(), "Karthik comes to the counter in the evening")
	await _frames(5)
	_check(screen._street._speech._bubbles.size() > 0, "Karthik says something in a speech bubble")
	guard = 0
	while not service.regular.done and guard < 6000:
		guard += 1
		await _play_turn(screen, service)
	_check(state.today["met"].has("karthik"), "Karthik was served today")
	_check(int(state.regular("karthik")["friendship"]) > 0, "serving Karthik builds friendship")

	# Fast forward to closing time.
	Engine.time_scale = 60.0
	guard = 0
	while not (_main._screen is NightScreen) and guard < 20000:
		guard += 1
		await process_frame
	Engine.time_scale = 1.0


func _night() -> void:
	await _wait_for(NightScreen)
	var screen = _main._screen
	_check(screen is NightScreen, "the day ends on the night summary")
	if not (screen is NightScreen):
		return
	# The tally counts up over a couple of seconds before the stars show.
	await create_timer(3.5).timeout
	_check(screen._stars_shown >= 1, "the night tally gives the day stars")
	_check(screen._upgrades.size() == Catalog.UPGRADES.size(), "the night screen offers every upgrade")
	_click(_find_button(screen, "Plan tomorrow"))
	await _wait_for(MorningScreen)
	_check(_main._screen is MorningScreen and _main.state.day == 2, "next morning is day 2")
	var saved := SaveGame.load_state()
	_check(saved != null and saved.day == 2, "day 2 is saved")
	_check(saved != null and int(saved.regular("karthik")["friendship"]) > 0, "Karthik's friendship is saved")


func _back_to_title() -> void:
	_click(_find_button(_main._screen, "Open the kadai"))
	await _wait_for(ServiceScreen)
	var screen = _main._screen
	_tap(KEY_ESCAPE)
	await _frames(2)
	_click(_find_button(screen._pause_menu, "Quit to title"))
	await _wait_for(TitleScreen)
	_check(_main._screen is TitleScreen, "Quit to title goes back to the title screen")
	_check(_find_button(_main._screen, "Continue") != null, "the title offers Continue once there's a save")


## One step of a simple player, using only input events.
func _play_turn(screen: ServiceScreen, service: Service) -> void:
	var tea := service.tea
	if tea.stage == TeaStation.Stage.POURING:
		if tea.pour_height >= tea.target.x + 0.03:
			_key(KEY_SPACE, false)
	elif tea.can_pour():
		_key(KEY_SPACE, true)
	elif tea.stage == TeaStation.Stage.EMPTY and service.ready_count("tea") < 2 and service.state.can_make("tea"):
		_tap(KEY_SPACE)
	var fry := service.fryer.doneness()
	if fry == Fryer.Doneness.GOLDEN or (fry == Fryer.Doneness.EMPTY and service.ready_count("vadai") < 2):
		_tap(KEY_F)
	var street: StreetView = screen._street
	for seat in service.seats.size():
		if service.can_fill(seat) and street._arrive[seat] >= 1.0:
			# Alternate between clicking the person and clicking their bubble.
			var feet := street._iso(StreetView.SEAT_TILES[seat])
			var target := feet + Vector2(0, -14)
			if seat % 2 == 1:
				target = street._bubble_box(seat, 1).get_center()
			_click_at(street.get_global_rect().position + target)
	await process_frame


# --- Input helpers --------------------------------------------------------

func _click(control: Control) -> void:
	_check(control != null, "button exists")
	if control != null:
		_click_at(control.get_global_rect().get_center())


func _click_at(at: Vector2) -> void:
	_mouse(at, true)
	_mouse(at, false)


func _mouse(at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = at
	event.global_position = at
	root.push_input(event, true)


func _key(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = pressed
	root.push_input(event, true)


func _tap(key: Key) -> void:
	_key(key, true)
	_key(key, false)


func _find_button(node: Node, starts_with: String) -> Button:
	for child in node.find_children("*", "Button", true, false):
		if (child as Button).text.begins_with(starts_with):
			return child
	return null


## Waits until this screen is up and faded in, plus a few frames so its
## layout has settled before anything is clicked.
func _wait_for(screen_type) -> void:
	for i in 400:
		if is_instance_of(_main._screen, screen_type) and _main._fade.color.a < 0.05:
			break
		await process_frame
	await _frames(4)


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _check(ok: bool, what: String) -> void:
	if ok:
		print("ok: " + what)
	else:
		_failures += 1
		printerr("FAIL: " + what)
