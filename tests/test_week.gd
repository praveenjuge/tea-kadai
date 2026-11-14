extends SceneTree
## Bug sweep: plays the real game, every screen, for nine days at high speed.
## A bot shops in the morning, serves through the day, buys upgrades at night,
## dismisses the week-1 finale, and meets Murugan on day 8. Checks the loop
## never gets stuck and each morning is saved. Uses its own save file.
## Run: godot --path . -s tests/test_week.gd

const DAYS := 9
const SPEED := 25.0

var _failures := 0
var _main: Control


func _init() -> void:
	SaveGame.path = "user://test_week_save.json"
	Settings.path = "user://test_settings.cfg"
	SaveGame.delete()
	_main = load("res://main.tscn").instantiate()
	root.add_child(_main)
	_run.call_deferred()


func _run() -> void:
	await _wait_for(TitleScreen)
	_main._start_new_game()
	await _wait_for(IntroScreen)
	_main._screen.finished.emit()
	for day in range(1, DAYS + 1):
		await _wait_for(MorningScreen)
		_check(_main.state.day == day, "morning of day %d" % day)
		var saved := SaveGame.load_state()
		_check(saved != null and saved.day == day, "day %d is saved in the morning" % day)
		_shop(_main.state)
		_main._show_service()
		await _wait_for(ServiceScreen)
		var service: Service = _main._screen._service
		if day == 8:
			_check(service.regular_visit("murugan") != null, "Murugan is part of day 8")
		Engine.time_scale = SPEED
		var guard := 0
		while not (_main._screen is NightScreen) and guard < 40000:
			guard += 1
			if not service.closed:
				_bot(service)
			await process_frame
		Engine.time_scale = 1.0
		_check(_main._screen is NightScreen, "day %d reaches the night screen" % day)
		await create_timer(3.8).timeout
		if day == 7:
			_check(_main._overlays.get_child_count() == 1, "the week-1 finale appears on day 7")
			for overlay in _main._overlays.get_children():
				overlay.close()
			await _frames(3)
		if day == 8:
			_check(_main.state.today["met"].has("murugan"), "Murugan came to the counter on day 8")
		_buy_upgrades(_main.state)
		print("day %d: served %d, money %d, level %d" % [day, _main.state.today["served"], _main.state.money, _main.state.level()])
		_main._on_next_day()
	if _failures == 0:
		print("All week checks passed.")
	else:
		printerr("%d week check(s) failed." % _failures)
	SaveGame.delete()
	_main.queue_free()
	await _frames(2)
	quit(1 if _failures > 0 else 0)


## Buys whichever ingredient is holding each menu item back.
func _shop(state: KadaiState) -> void:
	for item in state.menu():
		var recipe: Dictionary = Catalog.RECIPES[item]
		for guard in 6:
			if state.how_many(item) >= 20:
				break
			var lowest := ""
			for stock_id in recipe:
				if lowest == "" or int(state.stock[stock_id]) < int(state.stock[lowest]):
					lowest = stock_id
			if not state.buy(lowest):
				break


func _buy_upgrades(state: KadaiState) -> void:
	for id in Catalog.UPGRADE_ORDER:
		if int(Catalog.UPGRADES[id]["level"]) <= state.level() and state.money - int(Catalog.UPGRADES[id]["cost"]) >= 300:
			state.buy_upgrade(id)


func _bot(service: Service) -> void:
	var tea := service.tea
	if tea.stage == TeaStation.Stage.POURING:
		service.tea_release()
	elif tea.can_pour():
		service.tea_press()
	elif tea.stage == TeaStation.Stage.EMPTY and service.glasses_ready() < 3:
		var drink := _wanted(service, service.drinks())
		if drink != "":
			service.set_tea_kind(drink)
			service.tea_press()
	var fry := service.fryer.doneness()
	if fry == Fryer.Doneness.GOLDEN:
		service.fry_press()
	elif fry == Fryer.Doneness.EMPTY and service.fries_ready() < 3:
		var snack := _wanted(service, service.fries())
		if snack != "":
			service.set_fry_kind(snack)
			service.fry_press()
	for seat in service.seats.size():
		var customer = service.seats[seat]
		if customer != null:
			if customer.get("usual_hidden", false):
				customer["usual_hidden"] = false
			# Answer any question the regular asked.
			service.answer(seat, 0)
		if service.can_fill(seat):
			service.serve(seat)


## What waiting customers need most that isn't ready yet; plain tea or vadai
## otherwise, if they can be made.
func _wanted(service: Service, items: Array[String]) -> String:
	var best := ""
	var best_need := 0
	for item in items:
		var need := -service.ready_count(item)
		for customer in service.seats:
			if customer != null:
				need += int(customer["order"].get(item, 0))
		if need > best_need and service.state.can_make(item):
			best = item
			best_need = need
	if best == "" and service.state.can_make(items[0]):
		best = items[0]
	return best


func _wait_for(screen_type) -> void:
	for i in 600:
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
