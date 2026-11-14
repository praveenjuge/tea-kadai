extends SceneTree
## Headless checks for the kadai's core rules.
## Run: godot --headless --path . -s tests/test_core.gd

var _failures := 0


func _init() -> void:
	if not _scripts_compile("res://scripts"):
		printerr("Scripts failed to compile; skipping rule checks.")
		quit(1)
		return
	_test_clock()
	_test_market()
	_test_tea_pour()
	_test_fryer()
	_test_serving()
	_test_nobody_walks_out()
	_test_running_out()
	_test_sounds_exist()
	_test_karthik()
	_test_upgrades_and_saving()
	_test_rain_is_fixed_per_day()
	_test_bot_plays_a_full_day()
	if _failures == 0:
		print("All core checks passed.")
	else:
		printerr("%d core check(s) failed." % _failures)
	quit(1 if _failures > 0 else 0)


## Fails loudly if any game script has a parse or compile error, which would
## otherwise only show up as runtime errors.
func _scripts_compile(dir_path: String) -> bool:
	var ok := true
	for file in DirAccess.get_files_at(dir_path):
		if file.ends_with(".gd"):
			var script: GDScript = load(dir_path.path_join(file))
			if script == null or not script.can_instantiate():
				printerr("FAIL: %s does not compile" % dir_path.path_join(file))
				ok = false
	for sub in DirAccess.get_directories_at(dir_path):
		ok = _scripts_compile(dir_path.path_join(sub)) and ok
	return ok


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAIL: " + what)


func _test_clock() -> void:
	var clock := DayClock.new()
	_check(clock.time_text() == "6:00 AM", "day starts at 6:00 AM, got " + clock.time_text())
	_check(clock.phase()["id"] == "morning_rush", "day starts in the morning rush")
	clock.advance(float(Catalog.PHASES[0]["seconds"]) + 1.0)
	_check(clock.phase()["id"] == "afternoon", "afternoon follows the morning rush")
	clock.advance(100000.0)
	_check(clock.is_over(), "clock ends")
	_check(clock.time_text() == "10:00 PM", "day ends at 10:00 PM, got " + clock.time_text())
	_check(not clock.can_arrive(), "nobody arrives after closing")


func _test_market() -> void:
	var state := KadaiState.new()
	var money := state.money
	var milk := int(state.stock["milk"])
	_check(state.buy("milk"), "can buy milk with starting money")
	_check(state.money == money - 60, "milk costs 60")
	_check(int(state.stock["milk"]) == milk + 12, "a litre of milk makes 12 glasses")
	_check(state.undo_buy("milk"), "can undo a pack bought this morning")
	_check(state.money == money and int(state.stock["milk"]) == milk, "undo refunds fully")
	_check(not state.undo_buy("milk"), "cannot undo more than was bought")
	state.money = 10
	_check(not state.buy("oil"), "cannot buy without enough money")
	state.set_price("tea", 500)
	_check(int(state.prices["tea"]) == Catalog.MAX_PRICE, "prices are capped")
	_check(Catalog.unit_cost("tea") < float(Catalog.MENU["tea"]["price"]), "tea makes a profit at the usual price")
	_check(Catalog.unit_cost("vadai") < float(Catalog.MENU["vadai"]["price"]), "vadai makes a profit at the usual price")


func _test_tea_pour() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var station := TeaStation.new()
	var results: Array = []
	station.poured.connect(func(q: float, _label: String) -> void: results.append(q))
	station.start(rng)
	_check(not station.begin_pour(), "cannot pour while the glass is filling")
	station.update(TeaStation.FILL_SECONDS + 0.01)
	_check(station.begin_pour(), "can pour once the glass is full")
	while station.pour_height < (station.target.x + station.target.y) / 2.0:
		station.update(0.01)
	station.release_pour()
	_check(results.size() == 1 and is_equal_approx(results[0], 1.0), "letting go in the green zone is a perfect pour")
	station.start(rng)
	station.update(TeaStation.FILL_SECONDS + 0.01)
	station.begin_pour()
	for i in 300:
		station.update(0.01)
	_check(results.size() == 2 and results[1] < 0.5, "holding too long spills")
	_check(station.stage == TeaStation.Stage.EMPTY, "station is empty after pouring")


func _test_fryer() -> void:
	var state := KadaiState.new()
	state.buy("batter")
	state.buy("oil")
	var service := Service.new(state, 3)
	var batter := int(state.stock["batter"])
	service.fry_press()
	_check(service.fryer.count == Fryer.BATCH, "one press fries a batch of %d" % Fryer.BATCH)
	_check(int(state.stock["batter"]) == batter - Fryer.BATCH, "the batch uses batter for each vadai")
	service.fryer.update(Fryer.GOLDEN_AT + 0.5)
	_check(service.fryer.doneness() == Fryer.Doneness.GOLDEN, "the batch turns golden")
	service.fry_press()
	_check(service.fryer.is_empty(), "the second press lifts the batch out")
	_check(service.ready_count("vadai") == Fryer.BATCH, "golden vadai wait warm on the plate")
	service.fry_press()
	service.fryer.update(Fryer.BURNT_AT + 1.0)
	service.fry_press()
	_check(service.ready_count("vadai") == Fryer.BATCH and int(state.today["wasted"]) == Fryer.BATCH,
		"a burnt batch is thrown away")


func _customer(order: Dictionary, patience: float = 30.0) -> Dictionary:
	return {
		"type": "student", "order": order, "patience": patience, "patience_max": 35.0,
		"grumpy": false, "bill": 0, "quality_sum": 0.0, "quality_n": 0,
	}


func _test_serving() -> void:
	var state := KadaiState.new()
	var service := Service.new(state, 7)
	service.seats[0] = _customer({"tea": 1, "biscuit": 1})
	var left: Array = []
	service.customer_left.connect(func(_s: int, c: Dictionary, outcome: String) -> void: left.append([c, outcome]))
	var money := state.money
	service.serve(0)
	_check(service.seats[0] != null, "partly served customer keeps waiting for their tea")
	_check(state.money == money + 5, "biscuit is paid for when handed over")
	service.ready["tea"].append(1.0)
	_check(service.can_fill(0), "customer can be filled once tea is ready")
	service.serve(0)
	_check(service.seats[0] == null, "fully served customer leaves")
	_check(left.size() == 1 and left[0][1] == "served", "customer leaves as served")
	_check(int(state.today["served"]) == 1, "served count goes up")
	_check(state.money > money + 5 + 12, "tea is paid for, with a tip for good service")


func _test_nobody_walks_out() -> void:
	var state := KadaiState.new()
	var service := Service.new(state, 9)
	service.seats[0] = _customer({"tea": 1}, 1.0)
	for i in 200:
		service._update_patience(0.5)
	_check(service.seats[0] != null, "a customer who waits too long stays")
	_check(service.seats[0]["grumpy"] and int(state.today["waited_long"]) == 1, "they grumble instead")
	var money := state.money
	service.ready["tea"].append(1.0)
	service.serve(0)
	_check(state.money == money + 12, "a grumpy customer still pays, but doesn't tip")


func _test_running_out() -> void:
	var state := KadaiState.new()
	state.stock["bun"] = 0
	var service := Service.new(state, 11)
	service.seats[0] = _customer({"tea": 1, "bun": 1})
	service.seats[1] = _customer({"bun": 1})
	service._drop_unavailable()
	_check(service.seats[0] != null and not service.seats[0]["order"].has("bun"), "customer skips what's sold out")
	_check(service.seats[1] == null and int(state.today["out_of_stock"]) == 1,
		"customer leaves if nothing they want is left")


## Every sound the game refers to has a file, so swapping in real recordings
## can't silently break anything.
func _test_sounds_exist() -> void:
	for sound_name in SoundBoard.VOLUME:
		_check(ResourceLoader.exists(SoundBoard.DIR + sound_name + ".wav"), "sound file exists: " + sound_name)
	for event in SoundBoard.EVENTS:
		_check(SoundBoard.VOLUME.has(SoundBoard.EVENTS[event]), "event %s plays a known sound" % event)
	for loop_name in SoundBoard.LOOP_FADE:
		_check(SoundBoard.VOLUME.has(loop_name), "loop %s has a volume" % loop_name)


## Runs a service until Karthik is at the counter and returns his seat.
func _bring_karthik(service: Service) -> int:
	for i in 20000:
		if service.regular.is_here():
			return service.regular.seat
		service.clock.advance(0.1)
		service.regular.update(0.1)
	return -1


func _test_karthik() -> void:
	# Day 2: he asks a question; answering builds friendship.
	var state := KadaiState.new()
	state.day = 2
	var service := Service.new(state, 5)
	var lines: Array = []
	var questions: Array = []
	service.said.connect(func(_s: int, text: String) -> void: lines.append(text))
	service.asked.connect(func(_s: int, q: String, options: Array) -> void: questions.append([q, options]))
	var seat := _bring_karthik(service)
	_check(seat >= 0, "Karthik arrives on day 2")
	_check(lines.size() == 1, "he says hello when he arrives")
	service.regular.update(RegularVisit.ASK_AFTER + 0.1)
	_check(questions.size() == 1 and questions[0][1].size() == 2, "he asks a question with two answers")
	service.answer(seat, 0)
	_check(int(state.regular("karthik")["friendship"]) == 8, "answering \"Study, da!\" adds 8 friendship")
	service.ready["tea"].append(1.0)
	state.stock["bun"] = 5
	service.serve(seat)
	_check(service.regular.done and state.today["met"].has("karthik"), "serving him finishes his visit")
	_check(int(state.regular("karthik")["friendship"]) == 8 + RegularVisit.SERVED_GAIN + RegularVisit.PERFECT_GAIN,
		"a perfect tea for him adds more friendship")

	# Day 3: his usual is hidden, remembering it pays, and he teaches ginger tea.
	state = KadaiState.new()
	state.day = 3
	state.add_friendship("karthik", 25)
	state.stock["bun"] = 5
	service = Service.new(state, 6)
	seat = _bring_karthik(service)
	_check(service.seats[seat]["usual_hidden"], "on day 3 he just asks for \"the usual\"")
	service.regular.update(RegularVisit.WAIT_LINE_AFTER + 0.1)
	_check(state.menu().has("ginger_tea") and int(state.stock["ginger"]) >= 20, "he teaches ginger tea and brings ginger")
	var money := state.money
	service.ready["tea"].append(1.0)
	service.serve(seat)
	_check(state.money - money >= 12 + 15 + RegularVisit.REMEMBERED_TIP, "remembering his usual earns a bonus tip")
	_check(Story.hook("karthik", 3) != "", "each story day has a night hook")


func _test_upgrades_and_saving() -> void:
	var state := KadaiState.new()
	state.money = 1000
	_check(state.buy_upgrade("bench") and state.money == 650, "the bench costs 350")
	_check(not state.buy_upgrade("bench"), "an upgrade can only be bought once")
	_check(Service.new(state, 1).seats.size() == Catalog.SEATS + 1, "the bench adds a seat")
	state.buy_upgrade("pot")
	_check(Service.new(state, 1).tea.fill_seconds < TeaStation.FILL_SECONDS, "the bigger pot fills glasses faster")
	state.recipes.append("ginger_tea")
	state.add_friendship("karthik", 30)
	state.day = 4
	var copy := KadaiState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	_check(copy.day == 4 and copy.money == state.money, "day and money survive a save")
	_check(copy.has_upgrade("bench") and copy.has_upgrade("pot"), "upgrades survive a save")
	_check(copy.menu().has("ginger_tea"), "learned recipes survive a save")
	_check(int(copy.regular("karthik")["friendship"]) == 30, "friendship survives a save")
	var old := KadaiState.from_dict({"day": 2, "money": 50})
	_check(old.day == 2 and old.stock.has("ginger"), "an old or partial save still loads")


func _test_rain_is_fixed_per_day() -> void:
	var rainy := 0
	for day in range(1, 31):
		_check(Catalog.rain_for_day(day) == Catalog.rain_for_day(day), "rain is the same every time for day %d" % day)
		if Catalog.rain_for_day(day) != Vector2.ZERO:
			rainy += 1
	_check(Catalog.rain_for_day(1) == Vector2.ZERO, "never rains on day 1")
	_check(rainy >= 5 and rainy <= 16, "it rains on about a third of days, got %d of 30" % rainy)


## A simple bot plays a whole day. Checks that the loop runs to the end and a
## careful player can make money.
func _test_bot_plays_a_full_day() -> void:
	var state := KadaiState.new()
	state.buy("batter")
	state.buy("oil")
	state.buy("milk")
	state.buy("milk")
	var service := Service.new(state, 42)
	var ended := [false]
	service.day_over.connect(func() -> void: ended[0] = true)
	var step := 0.1
	var guard := 0
	while not ended[0] and guard < 20000:
		guard += 1
		_bot_turn(service)
		service.update(step)
	_check(ended[0], "the day ends")
	_check(int(state.today["served"]) >= 25, "bot serves at least 25 customers, served %d" % state.today["served"])
	_check(state.profit_today() > 0, "bot makes a profit, made %d" % state.profit_today())
	print("Bot day: served %d, waited long %d, out of stock %d, no seat %d, profit Rs %d" % [
		state.today["served"], state.today["waited_long"], state.today["out_of_stock"],
		state.today["no_seat"], state.profit_today()])


func _bot_turn(service: Service) -> void:
	var tea := service.tea
	if tea.stage == TeaStation.Stage.POURING:
		if tea.pour_height >= tea.target.x + 0.02:
			service.tea_release()
	elif tea.can_pour():
		service.tea_press()
	elif tea.stage == TeaStation.Stage.EMPTY and service.ready_count("tea") < 3 and service.state.can_make("tea"):
		service.tea_press()
	var fry := service.fryer.doneness()
	if fry == Fryer.Doneness.GOLDEN or (fry == Fryer.Doneness.EMPTY and service.ready_count("vadai") < 2):
		service.fry_press()
	for seat in service.seats.size():
		if service.can_fill(seat):
			service.serve(seat)
