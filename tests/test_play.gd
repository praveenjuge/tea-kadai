extends SceneTree
## Plays the real game through input events, the same path a player's mouse
## and keyboard take: buy stock, open the kadai, make tea with the keyboard,
## fry vadai and serve customers with the mouse, pause, end the day, and start
## the next morning.
## Run: godot --path . -s tests/test_play.gd
## Record it: add --write-movie <path>.avi --fixed-fps 30

const PLAY_SPEED := 3.0
const SERVE_GOAL := 4

var _failures := 0
var _main: Control


func _init() -> void:
	_main = load("res://main.tscn").instantiate()
	root.add_child(_main)
	_run.call_deferred()


func _run() -> void:
	await _frames(5)
	await _morning()
	await _service()
	await _night()
	if _failures == 0:
		print("All play checks passed.")
	else:
		printerr("%d play check(s) failed." % _failures)
	Engine.time_scale = 1.0
	_main.queue_free()
	await _frames(2)
	quit(1 if _failures > 0 else 0)


func _morning() -> void:
	var screen = _main._screen
	_check(screen is MorningScreen, "game opens on the morning market")
	var state: KadaiState = _main.state
	var money := state.money
	_click(screen._market["batter"]["buy"])
	_click(screen._market["oil"]["buy"])
	_click(screen._market["milk"]["buy"])
	await _frames(3)
	_check(state.money == money - 48 - 140 - 60, "buying batter, oil and milk spends the right money")
	_check(state.how_many("vadai") > 0, "batter and oil make vadai stock")
	_click(_find_button(screen, "Open the kadai"))
	await _frames(5)


func _service() -> void:
	var screen = _main._screen
	_check(screen is ServiceScreen, "opening the kadai starts service")
	var service: Service = screen._service
	var state: KadaiState = _main.state
	var sound: SoundBoard = _main.sound
	await _frames(30)
	_check(sound._loops["street_loop"].playing, "street sounds play during service")
	_check(sound._loops["music_day"].playing, "day music plays in the morning")

	# Pause stops the clock.
	_key(KEY_P, true)
	_key(KEY_P, false)
	var paused_at := service.clock.elapsed
	await _frames(20)
	_check(is_equal_approx(service.clock.elapsed, paused_at), "pausing stops the clock")
	_key(KEY_P, true)
	_key(KEY_P, false)

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

	# Fast forward to closing time.
	Engine.time_scale = 60.0
	guard = 0
	while not (_main._screen is NightScreen) and guard < 20000:
		guard += 1
		await process_frame
	Engine.time_scale = 1.0


func _night() -> void:
	var screen = _main._screen
	_check(screen is NightScreen, "the day ends on the night summary")
	if not (screen is NightScreen):
		return
	await _frames(10)
	_click(_find_button(screen, "Plan tomorrow"))
	await _frames(5)
	_check(_main._screen is MorningScreen and _main.state.day == 2, "next morning is day 2")


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
	for seat in Catalog.SEATS:
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


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _check(ok: bool, what: String) -> void:
	if ok:
		print("ok: " + what)
	else:
		_failures += 1
		printerr("FAIL: " + what)
