class_name Service
extends RefCounted
## One live day at the kadai: customers arriving, the tea station, the fryer,
## the ready tray, and serving. Holds no drawing or input code; screens call
## the action methods and listen to the signals.

signal customer_arrived(seat: int)
## outcome is "served", "walked_out", or "closed".
signal customer_left(seat: int, customer: Dictionary, outcome: String)
signal message(text: String)
signal day_over

var state: KadaiState
var clock := DayClock.new()
var tea := TeaStation.new()
var fryer := Fryer.new()
var rng := RandomNumberGenerator.new()
## One entry per seat: a customer Dictionary, or null when the seat is free.
var seats: Array = []
## Ready food waiting to be handed over: {"item": String, "quality": float}.
var tray: Array[Dictionary] = []
var closed := false
var _spawn_timer := 2.0


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
	_update_arrivals(delta)
	if clock.is_over():
		_close()


# --- Player actions -------------------------------------------------------

## Does the next tea step: a new glass, then each ingredient.
func tea_next() -> void:
	if tea.stage == TeaStation.Stage.EMPTY:
		if tray.size() >= Catalog.TRAY_SIZE:
			message.emit("The tray is full. Serve someone first.")
			return
		if not state.use_recipe("tea"):
			message.emit("Out of %s! Buy more tomorrow." % state.missing_for("tea").to_lower())
			return
		tea.start(rng)
	elif not tea.add_next() and tea.can_pour():
		message.emit("Hold %s to pour." % Controls.hint("tea_pour"))


func tea_pour_start() -> void:
	tea.begin_pour()


func tea_pour_release() -> void:
	tea.release_pour()


func fry_drop() -> void:
	if fryer.free_slot() < 0:
		message.emit("The kadai is full.")
		return
	if not state.use_recipe("vadai"):
		message.emit("Out of %s for vadai." % state.missing_for("vadai").to_lower())
		return
	fryer.drop()


func fry_take(slot: int) -> void:
	match fryer.doneness(slot):
		Fryer.Doneness.EMPTY:
			return
		Fryer.Doneness.BURNT:
			fryer.take(slot)
			state.today["wasted"] += 1
			message.emit("Burnt! That vadai goes to the crows.")
		var done:
			if tray.size() >= Catalog.TRAY_SIZE:
				message.emit("The tray is full. Serve someone first.")
				return
			fryer.take(slot)
			var golden: bool = done == Fryer.Doneness.GOLDEN
			tray.append({"item": "vadai", "quality": 1.0 if golden else 0.5})
			if not golden:
				message.emit("A bit soggy, but it'll do.")


## Hands over everything ready for the customer in this seat.
func serve(seat: int) -> void:
	var customer = seats[seat]
	if customer == null:
		return
	var order: Dictionary = customer["order"]
	var handed := 0
	for item in order.keys():
		while int(order[item]) > 0 and _take_ready(item, customer):
			order[item] -= 1
			handed += 1
		if int(order[item]) == 0:
			order.erase(item)
	if order.is_empty():
		_finish_customer(seat)
	elif handed > 0:
		customer["patience"] = minf(customer["patience"] + 8.0, customer["patience_max"])
	else:
		message.emit("Nothing ready for them yet.")


# --- Queries for screens --------------------------------------------------

func tray_count(item: String) -> int:
	var n := 0
	for entry in tray:
		if entry["item"] == item:
			n += 1
	return n


## True when everything this customer wants is ready to hand over right now.
func can_fill(seat: int) -> bool:
	var customer = seats[seat]
	if customer == null:
		return false
	var order: Dictionary = customer["order"]
	for item in order:
		var ready := tray_count(item) if Catalog.MENU[item]["made"] else state.how_many(item)
		if ready < int(order[item]):
			return false
	return true


# --- Internals ------------------------------------------------------------

func _take_ready(item: String, customer: Dictionary) -> bool:
	var quality := 1.0
	if Catalog.MENU[item]["made"]:
		var index := -1
		for i in tray.size():
			if tray[i]["item"] == item:
				index = i
				break
		if index < 0:
			return false
		quality = tray[index]["quality"]
		tray.remove_at(index)
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
	if avg >= 0.7:
		tip = roundi(float(kind["tip"]) * avg * (0.5 + calm))
	state.record_tip(tip)
	state.today["served"] += 1
	customer["tip"] = tip
	customer["mood"] = avg
	seats[seat] = null
	customer_left.emit(seat, customer, "served")


func _update_patience(delta: float) -> void:
	for seat in seats.size():
		var customer = seats[seat]
		if customer == null:
			continue
		customer["patience"] -= delta
		if customer["patience"] <= 0.0:
			state.today["walked_out"] += 1
			seats[seat] = null
			customer_left.emit(seat, customer, "walked_out")


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
	var skipped: Array[String] = []
	for item in order.keys():
		if not _price_ok(item, kind):
			order.erase(item)
			skipped.append(Catalog.MENU[item]["name"].to_lower())
	if order.is_empty():
		state.today["too_costly"] += 1
		message.emit("%s: \"%s at that price? No thanks.\"" % [kind["name"], skipped[0].capitalize()])
		return
	if not skipped.is_empty():
		message.emit("%s skipped the %s. Too costly." % [kind["name"], skipped[0]])
	seats[seat] = {
		"type": type_id,
		"order": order,
		"patience": float(kind["patience"]),
		"patience_max": float(kind["patience"]),
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
	tray.append({"item": "tea", "quality": quality})
	message.emit(label)


func _close() -> void:
	closed = true
	tea.release_pour()
	for seat in seats.size():
		var customer = seats[seat]
		if customer != null:
			seats[seat] = null
			customer_left.emit(seat, customer, "closed")
	state.today["wasted"] += tray.size() + fryer.count_cooking()
	day_over.emit()
