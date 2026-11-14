class_name Service
extends RefCounted
## One live day at the kadai: customers arriving, the tea station, the fryer,
## the ready food, serving, the weather, and today's regular. Holds no drawing
## or input code; screens call the action methods and listen to the signals.
##
## Nobody walks out. A customer who waits too long starts to grumble and won't
## tip, but stays until served. If the kadai runs out of something they want,
## they skip it, and leave only if nothing they wanted is left.

signal customer_arrived(seat: int)
## outcome is "served", "out_of_stock", "gave_up", or "closed".
signal customer_left(seat: int, customer: Dictionary, outcome: String)
signal message(text: String)
signal day_over
## Something worth a sound or a flourish: "tea_filling", "poured_perfect"
## (amount = streak), "poured_good", "poured_flat", "spilled", "streak",
## "vadai_drop", "vadai_golden", "vadai_lifted", "vadai_burnt", "arrive",
## "grumble", "paid" (amount = rupees), "friendship", "recipe", "treat".
signal happened(event: String, amount: int)
## A customer says something, shown as a speech bubble.
signal said(seat: int, text: String)
## A customer asks something, with answers to pick from.
signal asked(seat: int, question: String, options: Array)
## A new part of the day began, like the evening rush.
signal phase_started(phase: Dictionary)

const SUPPLY_CHECK_SECONDS := 1.0
const STREAK_BONUS_MAX := 5

var state: KadaiState
var clock := DayClock.new()
var tea := TeaStation.new()
var fryer := Fryer.new()
var rng := RandomNumberGenerator.new()
## One entry per seat: a customer Dictionary, or null when the seat is free.
var seats: Array = []
## Made food waiting to be handed over, as a list of qualities per item.
var ready := {}
var closed := false
## Which drink the next glass will be.
var tea_kind := "tea"
## Which snack the next batch will be.
var fry_kind := "vadai"
## Perfect pours in a row.
var streak := 0
## Today's shower as (start, end) kadai minutes, or ZERO.
var rain := Vector2.ZERO
## Today's regulars who are around this week of the story.
var regulars: Array[RegularVisit] = []
## Tips are doubled for everyone (a regular is celebrating).
var treat := false
var _ambient := false
var _spawn_timer := 2.0
var _supply_timer := SUPPLY_CHECK_SECONDS
var _golden_told := false
var _phase_index := -1


## "ambient" runs the street with nobody arriving, for the title screen.
func _init(kadai: KadaiState, seed_value: int = -1, ambient: bool = false) -> void:
	state = kadai
	_ambient = ambient
	for item in Catalog.GLASSES + Catalog.FRIED:
		ready[item] = []
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	var seat_count := Catalog.SEATS + (1 if state.has_upgrade("bench") else 0)
	for i in seat_count:
		seats.append(null)
	if state.has_upgrade("pot"):
		tea.fill_seconds = TeaStation.FILL_SECONDS / 2.0
	rain = Catalog.rain_for_day(state.day)
	tea.poured.connect(_on_tea_poured)
	if not ambient:
		for id in Story.REGULAR_ORDER:
			if state.day >= Story.first_day(id):
				regulars.append(RegularVisit.new(self, id))


func update(delta: float) -> void:
	if closed:
		return
	clock.advance(delta)
	_check_phase()
	tea.update(delta)
	fryer.update(delta)
	_update_patience(delta)
	_update_fryer_cue()
	_supply_timer -= delta
	if _supply_timer <= 0.0:
		_supply_timer = SUPPLY_CHECK_SECONDS
		_drop_unavailable()
	if not _ambient:
		_update_arrivals(delta)
		for visit in regulars:
			visit.update(delta)
	if clock.is_over():
		_close()


func is_raining() -> bool:
	var minute := clock.minutes()
	return rain != Vector2.ZERO and minute >= rain.x and minute < rain.y


# --- Player actions -------------------------------------------------------

## Press: start a new glass, or start pouring a full one.
func tea_press() -> void:
	match tea.stage:
		TeaStation.Stage.EMPTY:
			if glasses_ready() >= tray_size():
				message.emit("The tray is full. Serve someone first.")
			elif not state.use_recipe(tea_kind):
				message.emit("Out of %s! Buy more tomorrow." % state.missing_for(tea_kind).to_lower())
			else:
				tea.start(rng, tea_kind)
				happened.emit("tea_filling", 0)
		TeaStation.Stage.READY:
			tea.begin_pour()


## Release: let go of the pour.
func tea_release() -> void:
	tea.release_pour()


## Picks which drink the next glass will be, if it's on the menu.
func set_tea_kind(kind: String) -> void:
	if state.menu().has(kind):
		tea_kind = kind


## Picks which snack the next batch will be, if it's on the menu.
func set_fry_kind(kind: String) -> void:
	if state.menu().has(kind):
		fry_kind = kind


## Drinks and fries on today's menu, in menu order.
func drinks() -> Array[String]:
	return Catalog.GLASSES.filter(func(item: String) -> bool: return state.menu().has(item))


func fries() -> Array[String]:
	return Catalog.FRIED.filter(func(item: String) -> bool: return state.menu().has(item))


func tray_size() -> int:
	return Catalog.BIG_COUNTER_TRAY if state.has_upgrade("counter") else Catalog.TRAY_GLASSES


func plate_size() -> int:
	return Catalog.BIG_COUNTER_PLATE if state.has_upgrade("counter") else Catalog.FRY_PLATE


## Drops a batch of vadai in, or lifts the batch out.
func fry_press() -> void:
	if fryer.is_empty():
		_fry_drop()
	else:
		_fry_take()


## Hands over everything ready for the customer in this seat.
func serve(seat: int) -> void:
	var customer = seats[seat]
	if customer == null:
		return
	var order: Dictionary = customer["order"]
	var handed := 0
	for item in order.keys():
		while int(order[item]) > 0 and _hand_over(item, customer):
			order[item] -= 1
			handed += 1
		if int(order[item]) == 0:
			order.erase(item)
	if order.is_empty():
		_finish_customer(seat)
	elif handed == 0:
		message.emit("Nothing ready for them yet.")


## The player answers a regular's question.
func answer(seat: int, index: int) -> void:
	for visit in regulars:
		if visit.seat == seat and visit.is_here():
			visit.answer(index)


## Today's visit for one regular, or null if they aren't part of today.
func regular_visit(id: String) -> RegularVisit:
	for visit in regulars:
		if visit.id == id:
			return visit
	return null


# --- Queries for screens --------------------------------------------------

## How many of an item could be handed over right now.
func ready_count(item: String) -> int:
	if Catalog.MENU[item]["made"]:
		return ready[item].size()
	return state.how_many(item)


func glasses_ready() -> int:
	var n := 0
	for kind in Catalog.GLASSES:
		n += ready[kind].size()
	return n


func fries_ready() -> int:
	var n := 0
	for kind in Catalog.FRIED:
		n += ready[kind].size()
	return n


## True when everything this customer wants is ready to hand over right now.
func can_fill(seat: int) -> bool:
	var customer = seats[seat]
	if customer == null:
		return false
	var order: Dictionary = customer["order"]
	for item in order:
		if ready_count(item) < int(order[item]):
			return false
	return true


## Whether the fry button does anything right now.
func can_fry_press() -> bool:
	return not fryer.is_empty() or _batch_size() > 0


func fry_action_text() -> String:
	var name: String = Catalog.MENU[fry_kind]["name"].to_lower()
	if not fryer.is_empty():
		return "Lift them out"
	return "Fry %d %s" % [_batch_size(), name] if _batch_size() > 0 else "Fry %s" % name


## The look and numbers for a customer type or a regular.
static func kind_of(type_id: String) -> Dictionary:
	if Catalog.CUSTOMERS.has(type_id):
		return Catalog.CUSTOMERS[type_id]
	return Story.REGULARS[type_id]


## Puts a customer in a seat. Used for walk-ins and regulars.
func seat_customer(seat: int, type_id: String, order: Dictionary, patience: float) -> void:
	if state.has_upgrade("fan"):
		patience *= Catalog.FAN_PATIENCE
	if state.has_upgrade("plants"):
		patience *= Catalog.PLANTS_PATIENCE
	seats[seat] = {
		"type": type_id,
		"order": order,
		"patience": patience,
		"patience_max": patience,
		"grumpy": false,
		"bill": 0,
		"quality_sum": 0.0,
		"quality_n": 0,
	}
	customer_arrived.emit(seat)
	happened.emit("arrive", 0)


## A walk-in customer of this type arrives, if there's room.
func arrive(type_id: String) -> void:
	var kind: Dictionary = Catalog.CUSTOMERS[type_id]
	var seat := seats.find(null)
	if regulars.any(func(visit: RegularVisit) -> bool: return visit.waiting):
		seat = -1
	if seat < 0:
		state.today["no_seat"] += 1
		message.emit("A %s walked past. No room at the counter." % kind["name"].to_lower())
		return
	var order := _make_order(kind)
	var too_costly := ""
	var sold_out := ""
	for item in order.keys():
		var item_name: String = Catalog.MENU[item]["name"].to_lower()
		if not _can_supply(item):
			order.erase(item)
			sold_out = item_name
		elif not _price_ok(item, kind):
			order.erase(item)
			too_costly = item_name
	if order.is_empty():
		if too_costly != "":
			state.today["too_costly"] += 1
			message.emit("%s: \"%s at that price? No thanks.\"" % [kind["name"], too_costly.capitalize()])
		else:
			state.today["out_of_stock"] += 1
			message.emit("%s wanted %s, but you're out." % [kind["name"], sold_out])
		return
	if too_costly != "":
		message.emit("%s skipped the %s. Too costly." % [kind["name"], too_costly])
	seat_customer(seat, type_id, order, float(kind["patience"]))


# --- Internals ------------------------------------------------------------

## One drink from what's on the menu, plus maybe some snacks. Rain makes
## everyone want a drink and fried snacks.
func _make_order(kind: Dictionary) -> Dictionary:
	var order := {}
	var menu := state.menu()
	var drink_weights := {}
	var drinks_wanted: Dictionary = kind["drinks"]
	for drink in drinks_wanted:
		if menu.has(drink):
			drink_weights[drink] = drinks_wanted[drink]
	var raining := is_raining()
	if not drink_weights.is_empty() and (raining or rng.randf() < 0.92):
		order[_pick_weighted(drink_weights)] = 1
	var snacks: Dictionary = kind["snacks"]
	for snack in snacks:
		var chance := float(snacks[snack])
		if raining and Catalog.FRIED.has(snack):
			chance = minf(1.0, chance * 1.6)
		if menu.has(snack) and rng.randf() < chance:
			order[snack] = 1
	if order.is_empty():
		order["tea"] = 1
	return order


func _check_phase() -> void:
	var index := clock.phase_index()
	if index != _phase_index:
		_phase_index = index
		phase_started.emit(clock.phase())


func _batch_size() -> int:
	var space := plate_size() - fries_ready()
	return mini(Fryer.BATCH, mini(state.how_many(fry_kind), space))


func _fry_drop() -> void:
	var amount := _batch_size()
	var name: String = Catalog.MENU[fry_kind]["name"].to_lower()
	if fries_ready() >= plate_size():
		message.emit("The plate is full. Serve some first.")
		return
	if amount <= 0:
		message.emit("Out of %s for %s." % [state.missing_for(fry_kind).to_lower(), name])
		return
	for i in amount:
		state.use_recipe(fry_kind)
	fryer.drop(amount, fry_kind)
	_golden_told = false
	happened.emit("vadai_drop", 0)


func _fry_take() -> void:
	var batch := fryer.take()
	var amount: int = batch["count"]
	var snack: String = batch["kind"]
	var name: String = Catalog.MENU[snack]["name"].to_lower()
	happened.emit("vadai_burnt" if batch["doneness"] == Fryer.Doneness.BURNT else "vadai_lifted", 0)
	match batch["doneness"]:
		Fryer.Doneness.BURNT:
			state.today["wasted"] += amount
			message.emit("Burnt! The crows get a feast.")
		Fryer.Doneness.GOLDEN:
			for i in amount:
				ready[snack].append(1.0)
			message.emit("%d crispy %s!" % [amount, name])
		_:
			for i in amount:
				ready[snack].append(0.5)
			message.emit("A bit soggy, but they'll do.")


func _update_fryer_cue() -> void:
	if not _golden_told and fryer.doneness() == Fryer.Doneness.GOLDEN:
		_golden_told = true
		message.emit("The %s are golden. Lift them out!" % Catalog.MENU[fryer.kind]["name"].to_lower())
		happened.emit("vadai_golden", 0)


func _hand_over(item: String, customer: Dictionary) -> bool:
	var quality := 1.0
	if Catalog.MENU[item]["made"]:
		if ready[item].is_empty():
			return false
		quality = ready[item].pop_front()
	elif not state.use_recipe(item):
		return false
	customer["bill"] += state.record_sale(item)
	customer["quality_sum"] += quality
	customer["quality_n"] += 1
	return true


func _finish_customer(seat: int) -> void:
	var customer: Dictionary = seats[seat]
	var kind := kind_of(customer["type"])
	var avg: float = customer["quality_sum"] / maxf(1.0, customer["quality_n"])
	var calm: float = customer["patience"] / customer["patience_max"]
	var tip := 0
	if not customer["grumpy"] and avg >= 0.7:
		var multiplier := 2.0 if treat else 1.0
		if state.has_upgrade("paint"):
			multiplier *= Catalog.PAINT_TIPS
		if customer.has("regular"):
			multiplier *= regular_visit(customer["regular"]).tip_multiplier()
		tip = roundi(float(kind["tip"]) * avg * (0.5 + calm) * multiplier)
	if customer.has("regular"):
		tip += regular_visit(customer["regular"]).on_served(seat, customer, avg)
	seats[seat] = null
	state.record_tip(tip)
	state.today["served"] += 1
	state.week["served"] = int(state.week["served"]) + 1
	var points := Catalog.POINTS_GRUMPY if customer["grumpy"] else Catalog.POINTS_SERVED
	if avg >= 0.95 and not customer["grumpy"]:
		points += Catalog.POINTS_PERFECT
	if state.has_upgrade("radio"):
		points += Catalog.POINTS_RADIO
	state.add_points(points)
	customer["tip"] = tip
	customer["mood"] = avg
	customer["reaction"] = _reaction(customer, avg)
	customer_left.emit(seat, customer, "served")
	happened.emit("paid", int(customer["bill"]) + tip)


func _reaction(customer: Dictionary, avg: float) -> String:
	var pool := "okay"
	if customer["grumpy"]:
		pool = "grumpy"
	elif avg >= 0.95:
		pool = "perfect"
	elif avg >= 0.7:
		pool = "good"
	var lines: Array = Catalog.REACTIONS[pool]
	return lines[rng.randi() % lines.size()]


func _update_patience(delta: float) -> void:
	for seat in seats.size():
		var customer = seats[seat]
		if customer == null:
			continue
		if customer["grumpy"]:
			customer["grumble"] = float(customer.get("grumble", 0.0)) + delta
			if customer["grumble"] >= Catalog.GRUMBLE_LIMIT:
				_give_up(seat)
			continue
		customer["patience"] = maxf(0.0, customer["patience"] - delta)
		if customer["patience"] <= 0.0:
			customer["grumpy"] = true
			state.today["waited_long"] += 1
			happened.emit("grumble", 0)
			if customer.has("regular"):
				regular_visit(customer["regular"]).on_grumpy()


## A grumbling customer who has waited far too long leaves without paying.
func _give_up(seat: int) -> void:
	var customer: Dictionary = seats[seat]
	state.today["gave_up"] += 1
	if customer.has("regular"):
		var visit := regular_visit(customer["regular"])
		visit.on_grumpy()
		visit.done = true
	seats[seat] = null
	customer_left.emit(seat, customer, "gave_up")


## Whether this item can still reach a customer today.
func _can_supply(item: String) -> bool:
	if Catalog.GLASSES.has(item):
		var brewing := tea.stage != TeaStation.Stage.EMPTY and tea.kind == item
		return not ready[item].is_empty() or brewing or state.can_make(item)
	if Catalog.FRIED.has(item):
		var frying := not fryer.is_empty() and fryer.kind == item
		return not ready[item].is_empty() or frying or state.can_make(item)
	return state.can_make(item)


## Waiting customers skip anything the kadai has run out of.
func _drop_unavailable() -> void:
	for seat in seats.size():
		var customer = seats[seat]
		if customer == null:
			continue
		var order: Dictionary = customer["order"]
		var skipped := ""
		for item in order.keys():
			if not _can_supply(item):
				order.erase(item)
				skipped = Catalog.MENU[item]["name"].to_lower()
		if skipped == "":
			continue
		if not order.is_empty():
			message.emit("No %s left. They'll skip it." % skipped)
		elif int(customer["quality_n"]) > 0:
			_finish_customer(seat)
		else:
			state.today["out_of_stock"] += 1
			seats[seat] = null
			customer_left.emit(seat, customer, "out_of_stock")


func _update_arrivals(delta: float) -> void:
	if not clock.can_arrive():
		return
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return
	var phase := clock.phase()
	var gap: Vector2 = phase["spawn_gap"]
	var pace := Catalog.pace_for_day(state.day)
	if is_raining():
		pace *= Catalog.RAIN_PACE
	if state.has_upgrade("sign") and phase["id"] in ["evening_rush", "closing"]:
		pace *= Catalog.SIGN_EVENING_PACE
	_spawn_timer = rng.randf_range(gap.x, gap.y) * pace
	arrive(_pick_weighted(phase["mix"]))


## Above the usual price, each customer may decide it's not worth it.
func _price_ok(item: String, kind: Dictionary) -> bool:
	var usual := float(Catalog.MENU[item]["price"])
	var asked_price := float(state.prices[item])
	if asked_price <= usual:
		return true
	var over := (asked_price - usual) / usual
	var chance := clampf(1.0 - over * float(kind["price_sense"]) * 2.0, 0.05, 1.0)
	return rng.randf() < chance


func _pick_weighted(weights: Dictionary) -> String:
	var total := 0.0
	for key in weights:
		total += float(weights[key])
	var roll := rng.randf() * total
	for key in weights:
		roll -= float(weights[key])
		if roll <= 0.0:
			return key
	return weights.keys()[-1]


func _on_tea_poured(quality: float, label: String) -> void:
	ready[tea.kind].append(quality)
	if quality >= 1.0:
		streak += 1
		state.today["perfect"] += 1
		state.week["perfect"] = int(state.week["perfect"]) + 1
		state.today["best_streak"] = maxi(int(state.today["best_streak"]), streak)
		state.best_streak = maxi(state.best_streak, streak)
		happened.emit("poured_perfect", streak)
		if streak >= Catalog.STREAK_BONUS_FROM:
			var bonus := mini(streak - Catalog.STREAK_BONUS_FROM + 1, STREAK_BONUS_MAX)
			state.record_tip(bonus)
			message.emit("%d perfect in a row! +₹%d" % [streak, bonus])
			happened.emit("streak", streak)
			return
	else:
		streak = 0
		if quality >= 0.75:
			happened.emit("poured_good", 0)
		elif quality >= 0.5:
			happened.emit("poured_flat", 0)
		else:
			happened.emit("spilled", 0)
	message.emit(label)


func _close() -> void:
	closed = true
	tea.release_pour()
	for seat in seats.size():
		var customer = seats[seat]
		if customer != null:
			seats[seat] = null
			customer_left.emit(seat, customer, "closed")
	for item in ready:
		state.today["wasted"] += ready[item].size()
	state.today["wasted"] += fryer.count
	day_over.emit()
