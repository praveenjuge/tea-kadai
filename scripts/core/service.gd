class_name Service
extends RefCounted
## One live day at the kadai: customers arriving, the tea station, the fryer,
## the ready food, and serving. Holds no drawing or input code; screens call
## the action methods and listen to the signals.
##
## Nobody walks out. A customer who waits too long starts to grumble and won't
## tip, but stays until served. If the kadai runs out of something they want,
## they skip it, and leave only if nothing they wanted is left.

signal customer_arrived(seat: int)
## outcome is "served", "out_of_stock", or "closed".
signal customer_left(seat: int, customer: Dictionary, outcome: String)
signal message(text: String)
signal day_over

const SUPPLY_CHECK_SECONDS := 1.0

var state: KadaiState
var clock := DayClock.new()
var tea := TeaStation.new()
var fryer := Fryer.new()
var rng := RandomNumberGenerator.new()
## One entry per seat: a customer Dictionary, or null when the seat is free.
var seats: Array = []
## Made food waiting to be handed over, as a list of qualities per item.
var ready := {"tea": [], "vadai": []}
var closed := false
var _spawn_timer := 2.0
var _supply_timer := SUPPLY_CHECK_SECONDS
var _golden_told := false


func _init(kadai: KadaiState, seed_value: int = -1) -> void:
	state = kadai
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	for i in Catalog.SEATS:
		seats.append(null)
	tea.poured.connect(_on_tea_poured)


func update(delta: float) -> void:
	if closed:
		return
	clock.advance(delta)
	tea.update(delta)
	fryer.update(delta)
	_update_patience(delta)
	_update_fryer_cue()
	_supply_timer -= delta
	if _supply_timer <= 0.0:
		_supply_timer = SUPPLY_CHECK_SECONDS
		_drop_unavailable()
	_update_arrivals(delta)
	if clock.is_over():
		_close()


# --- Player actions -------------------------------------------------------

## Press: start a new glass, or start pouring a full one.
func tea_press() -> void:
	match tea.stage:
		TeaStation.Stage.EMPTY:
			if ready["tea"].size() >= int(Catalog.READY_CAPS["tea"]):
				message.emit("The tray is full. Serve someone first.")
			elif not state.use_recipe("tea"):
				message.emit("Out of %s! Buy more tomorrow." % state.missing_for("tea").to_lower())
			else:
				tea.start(rng)
		TeaStation.Stage.READY:
			tea.begin_pour()


## Release: let go of the pour.
func tea_release() -> void:
	tea.release_pour()


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


# --- Queries for screens --------------------------------------------------

## How many of an item could be handed over right now.
func ready_count(item: String) -> int:
	if Catalog.MENU[item]["made"]:
		return ready[item].size()
	return state.how_many(item)


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


func fry_action_text() -> String:
	if not fryer.is_empty():
		return "Lift them out"
	return "Fry %d vadai" % _batch_size() if _batch_size() > 0 else "Fry vadai"


# --- Internals ------------------------------------------------------------

func _batch_size() -> int:
	var space: int = int(Catalog.READY_CAPS["vadai"]) - ready["vadai"].size()
	return mini(Fryer.BATCH, mini(state.how_many("vadai"), space))


func _fry_drop() -> void:
	var amount := _batch_size()
	if ready["vadai"].size() >= int(Catalog.READY_CAPS["vadai"]):
		message.emit("The vadai plate is full.")
		return
	if amount <= 0:
		message.emit("Out of %s for vadai." % state.missing_for("vadai").to_lower())
		return
	for i in amount:
		state.use_recipe("vadai")
	fryer.drop(amount)
	_golden_told = false


func _fry_take() -> void:
	var batch := fryer.take()
	var amount: int = batch["count"]
	match batch["doneness"]:
		Fryer.Doneness.BURNT:
			state.today["wasted"] += amount
			message.emit("Burnt! The crows get a feast.")
		Fryer.Doneness.GOLDEN:
			for i in amount:
				ready["vadai"].append(1.0)
			message.emit("%d crispy vadai!" % amount)
		_:
			for i in amount:
				ready["vadai"].append(0.5)
			message.emit("A bit soggy, but they'll do.")


func _update_fryer_cue() -> void:
	if not _golden_told and fryer.doneness() == Fryer.Doneness.GOLDEN:
		_golden_told = true
		message.emit("The vadai are golden. Lift them out!")


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
	var kind: Dictionary = Catalog.CUSTOMERS[customer["type"]]
	var avg: float = customer["quality_sum"] / maxf(1.0, customer["quality_n"])
	var calm: float = customer["patience"] / customer["patience_max"]
	var tip := 0
	if not customer["grumpy"] and avg >= 0.7:
		tip = roundi(float(kind["tip"]) * avg * (0.5 + calm))
	state.record_tip(tip)
	state.today["served"] += 1
	customer["tip"] = tip
	customer["mood"] = avg
	seats[seat] = null
	customer_left.emit(seat, customer, "served")


func _update_patience(delta: float) -> void:
	for customer in seats:
		if customer == null or customer["grumpy"]:
			continue
		customer["patience"] = maxf(0.0, customer["patience"] - delta)
		if customer["patience"] <= 0.0:
			customer["grumpy"] = true
			state.today["waited_long"] += 1


## Whether this item can still reach a customer today.
func _can_supply(item: String) -> bool:
	match item:
		"tea":
			return not ready["tea"].is_empty() or tea.stage != TeaStation.Stage.EMPTY or state.can_make("tea")
		"vadai":
			return not ready["vadai"].is_empty() or not fryer.is_empty() or state.can_make("vadai")
		_:
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
	var gap: Vector2 = clock.phase()["spawn_gap"]
	_spawn_timer = rng.randf_range(gap.x, gap.y)
	_arrive(_pick_weighted(clock.phase()["mix"]))


func _arrive(type_id: String) -> void:
	var kind: Dictionary = Catalog.CUSTOMERS[type_id]
	var seat := seats.find(null)
	if seat < 0:
		state.today["no_seat"] += 1
		message.emit("A %s walked past. No room at the counter." % kind["name"].to_lower())
		return
	var order := {}
	var wants: Dictionary = kind["wants"]
	for item in wants:
		if rng.randf() < float(wants[item]):
			order[item] = 1
	if order.is_empty():
		order["tea"] = 1
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
	seats[seat] = {
		"type": type_id,
		"order": order,
		"patience": float(kind["patience"]),
		"patience_max": float(kind["patience"]),
		"grumpy": false,
		"bill": 0,
		"quality_sum": 0.0,
		"quality_n": 0,
	}
	customer_arrived.emit(seat)


## Above the usual price, each customer may decide it's not worth it.
func _price_ok(item: String, kind: Dictionary) -> bool:
	var usual := float(Catalog.MENU[item]["price"])
	var asked := float(state.prices[item])
	if asked <= usual:
		return true
	var over := (asked - usual) / usual
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
	ready["tea"].append(quality)
	message.emit(label)


func _close() -> void:
	closed = true
	tea.release_pour()
	for seat in seats.size():
		var customer = seats[seat]
		if customer != null:
			seats[seat] = null
			customer_left.emit(seat, customer, "closed")
	state.today["wasted"] += ready["tea"].size() + ready["vadai"].size() + fryer.count
	day_over.emit()
