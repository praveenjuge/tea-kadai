extends SceneTree
## Headless checks for the kadai's core rules.
## Run: godot --headless --path . -s tests/test_core.gd

var _failures := 0


func _init() -> void:
	_test_clock()
	_test_market()
	_test_tea_pour()
	_test_fryer()
	_test_serving()
	_test_bot_plays_a_full_day()
	if _failures == 0:
		print("All core checks passed.")
	else:
		printerr("%d core check(s) failed." % _failures)
	quit(1 if _failures > 0 else 0)


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
	_check(not station.begin_pour(), "cannot pour before adding milk")
	for i in 3:
		station.add_next()
	_check(station.begin_pour(), "can pour once milk is in")
	while station.pour_height < (station.target.x + station.target.y) / 2.0:
		station.update(0.01)
	station.release_pour()
	_check(results.size() == 1 and is_equal_approx(results[0], 1.0), "letting go in the green zone is a perfect pour")
	station.start(rng)
	for i in 3:
		station.add_next()
	station.begin_pour()
	for i in 300:
		station.update(0.01)
	_check(results.size() == 2 and results[1] < 0.5, "holding too long spills")
	_check(station.stage == TeaStation.Stage.EMPTY, "station is empty after pouring")


func _test_fryer() -> void:
	var fryer := Fryer.new()
	_check(fryer.drop() == 0, "first vadai goes in slot 0")
	fryer.update(Fryer.GOLDEN_AT + 0.5)
	_check(fryer.doneness(0) == Fryer.Doneness.GOLDEN, "vadai turns golden")
	fryer.update(Fryer.BURNT_AT)
	_check(fryer.doneness(0) == Fryer.Doneness.BURNT, "vadai burns if left too long")
	_check(fryer.take(0) == Fryer.Doneness.BURNT and fryer.free_slot() == 0, "taking empties the slot")


func _test_serving() -> void:
	var state := KadaiState.new()
	var service := Service.new(state, 7)
	service.seats[0] = {
		"type": "student", "order": {"tea": 1, "biscuit": 1},
		"patience": 30.0, "patience_max": 35.0, "bill": 0, "quality_sum": 0.0, "quality_n": 0,
	}
	var left: Array = []
	service.customer_left.connect(func(_s: int, c: Dictionary, outcome: String) -> void: left.append([c, outcome]))
	var money := state.money
	service.serve(0)
	_check(service.seats[0] != null, "partly served customer keeps waiting for their tea")
	_check(state.money == money + 5, "biscuit is paid for when handed over")
	service.tray.append({"item": "tea", "quality": 1.0})
	_check(service.can_fill(0), "customer can be filled once tea is ready")
	service.serve(0)
	_check(service.seats[0] == null, "fully served customer leaves")
	_check(left.size() == 1 and left[0][1] == "served", "customer leaves as served")
	_check(int(state.today["served"]) == 1, "served count goes up")
	_check(state.money >= money + 5 + 12, "tea is paid for")


## A simple bot plays a whole day. Checks that the loop runs to the end and a
## careful player can make money.
func _test_bot_plays_a_full_day() -> void:
	var state := KadaiState.new()
	state.buy("batter")
	state.buy("oil")
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
	_check(int(state.today["served"]) >= 20, "bot serves at least 20 customers, served %d" % state.today["served"])
	_check(state.profit_today() > 0, "bot makes a profit, made %d" % state.profit_today())
	print("Bot day: served %d, walked out %d, profit Rs %d" % [
		state.today["served"], state.today["walked_out"], state.profit_today()])


func _bot_turn(service: Service) -> void:
	var tea := service.tea
	if tea.stage == TeaStation.Stage.POURING:
		if tea.pour_height >= tea.target.x + 0.02:
			service.tea_pour_release()
	elif tea.can_pour():
		service.tea_pour_start()
	elif service.tray_count("tea") < 3 and service.state.can_make("tea"):
		service.tea_next()
	for slot in Fryer.SLOTS:
		if service.fryer.doneness(slot) == Fryer.Doneness.GOLDEN:
			service.fry_take(slot)
	if service.tray_count("vadai") + service.fryer.count_cooking() < 2:
		service.fry_drop()
	for seat in service.seats.size():
		if service.can_fill(seat):
			service.serve(seat)
