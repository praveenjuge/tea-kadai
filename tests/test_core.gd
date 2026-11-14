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
	_test_murugan()
	_test_upgrades_and_saving()
	_test_rain_is_fixed_per_day()
	_test_levels_and_menu()
	_test_week_goals()
	_test_bajji()
	_test_first_day_is_stocked()
	_test_clicker()
	_test_chennai()
	_test_bot_plays_a_full_day()
	_test_two_weeks()
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
	service.fryer.update(Catalog.FRY_TIMES["vadai"].x + 0.5)
	_check(service.fryer.doneness() == Fryer.Doneness.GOLDEN, "the batch turns golden")
	service.fry_press()
	_check(service.fryer.is_empty(), "the second press lifts the batch out")
	_check(service.ready_count("vadai") == Fryer.BATCH, "golden vadai wait warm on the plate")
	service.fry_press()
	service.fryer.update(Catalog.FRY_TIMES["vadai"].y + 1.0)
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
	for i in 60:
		service._update_patience(0.5)
	_check(service.seats[0] != null, "a customer who waits too long stays a good while")
	_check(service.seats[0]["grumpy"] and int(state.today["waited_long"]) == 1, "they grumble instead")
	var money := state.money
	service.ready["tea"].append(1.0)
	service.serve(0)
	_check(state.money == money + 12, "a grumpy customer still pays, but doesn't tip")
	service.seats[1] = _customer({"filter_coffee": 1}, 1.0)
	for i in 200:
		service._update_patience(0.5)
	_check(service.seats[1] == null and int(state.today["gave_up"]) == 1,
		"an order nobody makes doesn't block the counter forever")


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
		var karthik := service.regular_visit("karthik")
		if karthik.is_here():
			return karthik.seat
		service.clock.advance(0.1)
		karthik.update(0.1)
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
	service.regular_visit("karthik").update(RegularVisit.ASK_AFTER + 0.1)
	_check(questions.size() == 1 and questions[0][1].size() == 2, "he asks a question with two answers")
	service.answer(seat, 0)
	_check(int(state.regular("karthik")["friendship"]) == 8, "answering \"Study, da!\" adds 8 friendship")
	service.ready["tea"].append(1.0)
	state.stock["bun"] = 5
	service.serve(seat)
	_check(service.regular_visit("karthik").done and state.today["met"].has("karthik"), "serving him finishes his visit")
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
	service.regular_visit("karthik").update(RegularVisit.WAIT_LINE_AFTER + 0.1)
	_check(state.menu().has("ginger_tea") and int(state.stock["ginger"]) >= 20, "he teaches ginger tea and brings ginger")
	var money := state.money
	service.ready["tea"].append(1.0)
	service.serve(seat)
	_check(state.money - money >= 12 + 15 + RegularVisit.REMEMBERED_TIP, "remembering his usual earns a bonus tip")
	_check(Story.hook("karthik", 3) != "", "each story day has a night hook")


func _test_murugan() -> void:
	var week1 := KadaiState.new()
	week1.day = 5
	_check(Service.new(week1, 1).regular_visit("murugan") == null, "Murugan isn't around in week 1")
	var state := KadaiState.new()
	state.day = 10
	state.stock["batter"] = 10
	var service := Service.new(state, 2)
	_check(service.regulars.size() == 2, "both regulars come by in week 2")
	var murugan := service.regular_visit("murugan")
	for i in 20000:
		if murugan.is_here():
			break
		service.clock.advance(0.1)
		murugan.update(0.1)
	_check(murugan.is_here(), "Murugan comes in the morning")
	_check(service.seats[murugan.seat]["usual_hidden"], "from day 10 Murugan just orders the usual")
	service.ready["tea"].append(1.0)
	service.ready["vadai"].append(1.0)
	service.serve(murugan.seat)
	_check(murugan.done and int(state.regular("murugan")["friendship"]) > 0, "serving Murugan builds friendship")
	_check(Story.hook("murugan", 14) != "", "Murugan's week ends with a hook")


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


func _test_levels_and_menu() -> void:
	var state := KadaiState.new()
	_check(state.level() == 1 and not state.menu().has("lemon_tea"), "a new kadai is level 1 with the basic menu")
	var service := Service.new(state, 21)
	for i in 300:
		var order := service._make_order(Catalog.CUSTOMERS[Catalog.CUSTOMERS.keys()[i % Catalog.CUSTOMERS.size()]])
		for item in order:
			if not state.menu().has(item):
				_check(false, "customers only order what's on the menu, got " + item)
				return
	state.add_points(Catalog.LEVEL_POINTS[1])
	_check(state.level() == 2 and state.menu().has("lemon_tea"), "level 2 puts lemon tea on the menu")
	_check(state.today["level_ups"] == [2], "the level up is noted for the night screen")
	state.add_points(Catalog.LEVEL_POINTS[4])
	for item in ["bajji", "filter_coffee", "samosa"]:
		_check(state.menu().has(item), "%s unlocks by level 5" % item)
	_check(state.level_progress() >= 0.0 and state.level_progress() <= 1.0, "level progress stays between 0 and 1")


func _test_week_goals() -> void:
	var state := KadaiState.new()
	var goals := state.week_goals()
	_check(goals.size() == 3, "each week has three goals")
	state.week["served"] = int(goals[0]["target"])
	var money := state.money
	var claimed := state.claim_goals()
	_check(claimed.size() == 1 and state.money == money + Catalog.GOAL_REWARD, "reaching a goal pays a reward")
	_check(state.claim_goals().is_empty(), "a goal pays only once")
	for i in 7:
		state.next_day()
	_check(state.day == 8 and int(state.week["served"]) == 0 and state.week["done"].is_empty(), "a new week starts fresh")
	_check(int(state.week_goals()[0]["target"]) > int(goals[0]["target"]), "week 2 goals are a bit bigger")


func _test_bajji() -> void:
	var state := KadaiState.new()
	state.reputation = Catalog.LEVEL_POINTS[2]
	state.buy("besan")
	var service := Service.new(state, 4)
	service.set_fry_kind("bajji")
	service.fry_press()
	_check(service.fryer.kind == "bajji" and service.fryer.count == Fryer.BATCH, "bajji fry in a batch too")
	service.fryer.update(Catalog.FRY_TIMES["bajji"].x + 0.1)
	service.fry_press()
	_check(service.ready_count("bajji") == Fryer.BATCH and service.ready_count("vadai") == 0, "golden bajji land on the plate as bajji")


func _test_first_day_is_stocked() -> void:
	var state := KadaiState.new()
	for item in state.menu():
		_check(state.how_many(item) >= 6, "a new kadai can make %s without shopping" % item)


## A simple bot plays a whole day. Checks that the loop runs to the end and a
## careful player can make money.
func _test_clicker() -> void:
	var state := KadaiState.new()
	state.money = 100000
	_check(state.helper_cost("flask_boy") == 150, "the first flask boy costs 150")
	state.buy_helper("flask_boy")
	_check(state.helper_cost("flask_boy") == 173, "each flask boy costs a bit more than the last")
	for i in 9:
		state.buy_helper("flask_boy")
	_check(is_equal_approx(state.income_per_second(), 3.0), "ten flask boys earn 3 a second")
	var service := Service.new(state, 3)
	var money := state.money
	for i in 100:
		service._update_helpers(0.1)
	_check(state.money - money == 30 and int(state.today["helpers"]) == 30, "helpers earn through the day")
	service.frenzy = 5.0
	money = state.money
	for i in 10:
		service._update_helpers(0.1)
	_check(state.money - money == 21, "a frenzy makes helpers earn %dx" % Catalog.FRENZY_TIMES)
	# The golden glass shows up, then gives a bonus or a frenzy when clicked.
	service._golden_timer = 0.0
	service.clock.elapsed = 10.0
	service._update_golden(0.1)
	_check(service.golden_left > 0.0, "a golden glass appears")
	money = state.money
	service.frenzy = 0.0
	var got := service.claim_golden()
	_check(got == "frenzy" and service.frenzy > 0.0 or got == "bonus" and state.money > money, "clicking the golden glass pays out")
	_check(service.claim_golden() == "", "a golden glass can only be clicked once")
	# Staff: the chai boy hands over complete orders on his own.
	_check(not state.can_hire("chai_boy"), "staff need the right level")
	state.reputation = Catalog.LEVEL_POINTS[3]
	_check(state.hire("chai_boy") and state.has_staff("chai_boy"), "the chai boy can be hired")
	var staffed := Service.new(state, 4)
	staffed.seats[0] = _customer({"tea": 1})
	staffed.ready["tea"].append(0.9)
	staffed._update_staff(0.1)
	_check(staffed.seats[0] == null, "the chai boy serves a ready order")
	# Helper tiers unlock at 1 and 10 owned, and each doubles that helper.
	var before := state.helper_income("flask_boy")
	_check(state.next_tier("flask_boy") == 0 and state.buy_tier("flask_boy"), "the first flask boy tier can be bought")
	_check(state.next_tier("flask_boy") == 1 and state.buy_tier("flask_boy"), "ten flask boys unlock the second tier")
	_check(state.next_tier("flask_boy") == -1, "the third tier needs 25 flask boys")
	_check(is_equal_approx(state.helper_income("flask_boy"), before * 4.0), "each tier doubles its helper")
	# Away earnings are half the rate, capped.
	_check(state.away_earnings(3600.0) == floori(state.income_per_second() * 3600.0 * Catalog.AWAY_RATE), "away earnings are half rate")
	_check(state.away_earnings(1e9) == state.away_earnings(Catalog.AWAY_MAX_HOURS * 3600.0), "away earnings are capped")
	# Everything survives a save.
	var copy := KadaiState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	_check(copy.helper_count("flask_boy") == 10 and copy.has_staff("chai_boy") and copy.tier("flask_boy") == 2, "helpers, staff and tiers survive a save")
	var old := KadaiState.from_dict({"helpers": {"flask_boy": 5}, "boosts": ["steel_flasks", "lucky_tumbler"]})
	_check(old.tier("flask_boy") == 1 and old.has_boost("lucky_tumbler"), "an old helper boost becomes that helper's first tier")
	# A new branch starts fresh with a permanent bonus.
	_check(not state.can_open_branch(), "a branch needs enough earned first")
	state.branch_earned = Catalog.BRANCH_NEEDS
	var day := state.day
	_check(state.open_branch(), "a branch can be opened")
	_check(state.branches == 1 and state.helpers.is_empty() and state.staff.is_empty() and state.day == day, "a new branch starts fresh on the same day")
	_check(state.money == KadaiState.new().money, "a new branch starts with starting money")
	_check(is_equal_approx(state.branch_multiplier(), 1.0 + Catalog.BRANCH_BONUS), "a branch gives a lasting bonus")
	_check(KadaiState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict()))).branches == 1, "branches survive a save")
	_check(state.tiers.is_empty(), "a new branch resets helper tiers")
	# Achievements and big numbers.
	var fresh := KadaiState.new()
	fresh.earned_total = 150000
	var earned := fresh.check_achievements()
	_check(earned.size() == 3 and fresh.achievements.has("earn_lakh"), "earning one lakh gives the first three money achievements")
	_check(fresh.check_achievements().is_empty(), "an achievement is only earned once")
	_check(is_equal_approx(fresh.achievement_multiplier(), 1.03), "each achievement adds 1%")
	var passed := fresh.check_big_numbers()
	_check(passed.size() == 1 and fresh.news.size() == 1 and fresh.check_big_numbers().is_empty(), "one lakh is a big-number milestone, once")
	var saved := KadaiState.from_dict(JSON.parse_string(JSON.stringify(fresh.to_dict())))
	_check(saved.achievements.size() == 3 and saved.big_numbers_seen == 1, "achievements survive a save")


func _test_chennai() -> void:
	_check(Catalog.headline(73).contains("Pongal"), "Pongal day has its own headline")
	_check(Catalog.headline(5).contains("releases today"), "Friday's paper has the film release")
	_check(Chennai.film(4) != Chennai.film(5) and Chennai.film(5) == Chennai.film(11), "a new film every Friday")
	_check(Chennai.kolam_size(73) > Chennai.kolam_size(2) and Chennai.kolam_size(50) > 1.0, "kolams are bigger on festivals and in Margazhi")
	_check(Chennai.is_match_day(6) and not Chennai.is_match_day(3), "weekends are match days")
	# On a match day the radio plays cricket, and a six calms everyone down.
	var state := KadaiState.new()
	state.day = 6
	var service := Service.new(state, 21)
	service.seats[0] = _customer({"tea": 1}, 5.0)
	var said: Array = []
	service.message.connect(func(text: String) -> void: said.append(text))
	for i in 6000:
		service.radio.update(0.1)
	_check(said.any(func(text: String) -> bool: return text.begins_with("Radio commentary")), "the radio plays cricket on match days")
	_check(said.any(func(text: String) -> bool: return text.contains("SIX")) == (float(service.seats[0]["patience"]) > 5.0),
		"a six gives waiting customers patience back")


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
	_check(int(state.today["served"]) >= 15, "bot serves at least 15 customers on a short first day, served %d" % state.today["served"])
	_check(state.profit_today() > 0, "bot makes a profit, made %d" % state.profit_today())
	print("Bot day: served %d, waited long %d, out of stock %d, no seat %d, profit Rs %d" % [
		state.today["served"], state.today["waited_long"], state.today["out_of_stock"],
		state.today["no_seat"], state.profit_today()])


## A careful bot plays two full weeks: restocks each morning, serves all day,
## and buys upgrades at night. Prints each day so the pacing can be judged,
## and checks the week feels winnable.
func _test_two_weeks() -> void:
	var state := KadaiState.new()
	print("day  served  lost  perfect  takings  money  level  goals  upgrades")
	var level_on_day_7 := 0
	var first_upgrade_day := 0
	for day in 14:
		_bot_morning(state)
		var service := Service.new(state, 100 + day)
		var ended := [false]
		service.day_over.connect(func() -> void: ended[0] = true)
		var guard := 0
		while not ended[0] and guard < 20000:
			guard += 1
			_bot_turn(service)
			service.update(0.1)
		state.close_day()
		for id in Catalog.UPGRADE_ORDER:
			if int(Catalog.UPGRADES[id]["level"]) <= state.level() and state.money - int(Catalog.UPGRADES[id]["cost"]) >= 250:
				if state.buy_upgrade(id) and first_upgrade_day == 0:
					first_upgrade_day = state.day
		var done: int = state.week["done"].size()
		print("%3d  %6d  %4d  %7d  %7d  %5d  %5d  %5d  %s" % [state.day, state.today["served"], state.lost_today(),
			state.today["perfect"], int(state.today["revenue"]) + int(state.today["tips"]), state.money, state.level(),
			done, ",".join(state.upgrades)])
		_check(state.money >= 0, "money never goes negative (day %d)" % state.day)
		if state.day == 7:
			level_on_day_7 = state.level()
			_check(done >= 2, "a careful player reaches at least two week-1 goals, got %d" % done)
		state.next_day()
	_check(level_on_day_7 >= 3, "a careful player reaches level 3 by day 7, got %d" % level_on_day_7)
	_check(first_upgrade_day > 0 and first_upgrade_day <= 4, "the first upgrade is affordable by day 4, got day %d" % first_upgrade_day)


## Morning restock: top up anything that can make fewer than a day's worth.
func _bot_morning(state: KadaiState) -> void:
	for item in state.menu():
		var recipe: Dictionary = Catalog.RECIPES[item]
		for stock_id in recipe:
			var guard := 0
			while state.how_many(item) < 24 and int(state.stock[stock_id]) < 24 and state.can_afford(stock_id) and guard < 5:
				guard += 1
				state.buy(stock_id)


func _bot_turn(service: Service) -> void:
	var tea := service.tea
	if tea.stage == TeaStation.Stage.POURING:
		if tea.pour_height >= tea.target.x + 0.02:
			service.tea_release()
	elif tea.can_pour():
		service.tea_press()
	elif tea.stage == TeaStation.Stage.EMPTY:
		# Make whichever drink the waiting customers need most.
		var wanted := _most_wanted(service, Catalog.GLASSES)
		if wanted != "" and service.state.can_make(wanted):
			service.set_tea_kind(wanted)
			service.tea_press()
	var fry := service.fryer.doneness()
	if fry == Fryer.Doneness.GOLDEN:
		service.fry_press()
	elif fry == Fryer.Doneness.EMPTY:
		var wanted := _most_wanted(service, Catalog.FRIED)
		if wanted != "" and service.state.can_make(wanted):
			service.set_fry_kind(wanted)
			service.fry_press()
	for seat in service.seats.size():
		var customer = service.seats[seat]
		if customer != null and customer.get("usual_hidden", false):
			customer["usual_hidden"] = false
		if service.can_fill(seat):
			service.serve(seat)


## The made item waiting customers are short of the most, or "" if none.
func _most_wanted(service: Service, items: Array[String]) -> String:
	var best := ""
	var best_need := 0
	for item in items:
		if not service.state.menu().has(item):
			continue
		var need := -service.ready_count(item)
		for customer in service.seats:
			if customer != null:
				need += int(customer["order"].get(item, 0))
		if item == "tea" or item == "vadai":
			need += 1
		if need > best_need:
			best = item
			best_need = need
	return best
