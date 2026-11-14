class_name RegularVisit
extends RefCounted
## Today's visit from one regular: when they arrive, what they order and say,
## the question they ask, and what friendship unlocks. Talks to the player
## through the service's signals.

const WAIT_LINE_AFTER := 5.0
const ASK_AFTER := 2.5
const SERVED_GAIN := 8
const PERFECT_GAIN := 4
const REMEMBERED_GAIN := 6
const REMEMBERED_TIP := 5
const GRUMPY_LOSS := 6
const TEACH_LINE := "Anna, crush some ginger into the decoction. My amma's trick!"

var id: String
var info: Dictionary
## Today's visit from the story, or empty if they don't come today.
var visit: Dictionary
## Where they're sitting, or -1 before they arrive.
var seat := -1
var done := false
## True while they're here but the counter is full. They get the next spot.
var waiting := false
## Held weakly: the service owns this visit, so a strong reference back
## would keep both alive forever.
var _service_ref: WeakRef
var _service: Service:
	get:
		return _service_ref.get_ref()
var _wait := 0.0
var _said_wait := false
var _asked := false
var _answered := false


func _init(service: Service, regular_id: String) -> void:
	_service_ref = weakref(service)
	id = regular_id
	info = Story.REGULARS[id]
	visit = Story.visit(id, service.state.day)
	done = visit.is_empty()


func friendship() -> int:
	return int(_service.state.regular(id)["friendship"])


func is_here() -> bool:
	if seat < 0 or done:
		return false
	var customer = _service.seats[seat]
	return customer != null and customer.get("regular", "") == id


func update(delta: float) -> void:
	if done:
		return
	if seat < 0:
		if _service.clock.minutes() >= float(visit["minute"]) and _service.clock.can_arrive():
			_try_arrive()
		return
	if not is_here():
		done = true
		return
	_wait += delta
	var customer: Dictionary = _service.seats[seat]
	if customer["usual_hidden"] and _wait >= float(info["usual_hint_after"]):
		customer["usual_hidden"] = false
		_service.said.emit(seat, "Tea and a bun, anna. Same as always!")
	if not _asked and visit.has("ask") and _wait >= ASK_AFTER:
		_asked = true
		var options: Array = []
		for option in visit["ask"]["options"]:
			options.append(option["text"])
		_service.asked.emit(seat, visit["ask"]["q"], options)
	if not _said_wait and _wait >= WAIT_LINE_AFTER:
		_said_wait = true
		if _should_teach():
			_teach()
		elif visit.has("wait"):
			_service.said.emit(seat, visit["wait"])


## The player picked an answer to their question.
func answer(index: int) -> void:
	if not _asked or _answered or not is_here():
		return
	_answered = true
	var option: Dictionary = visit["ask"]["options"][index]
	_service.state.add_friendship(id, int(option.get("friendship", 0)))
	var money := int(option.get("money", 0))
	if money < 0 and _service.state.money >= -money:
		_service.state.money += money
	_service.said.emit(seat, option["reply"])
	_service.happened.emit("friendship", 0)


## Called by the service when this regular is served. Returns extra tip.
func on_served(served_seat: int, customer: Dictionary, quality: float) -> int:
	var gain := SERVED_GAIN
	var extra := 0
	if quality >= 1.0:
		gain += PERFECT_GAIN
	if customer.get("usual_hidden", false):
		gain += REMEMBERED_GAIN
		extra += REMEMBERED_TIP
		_service.message.emit("%s: \"You remembered! Thambi, you're the best.\"" % info["name"])
	_service.state.add_friendship(id, gain)
	var line: String = visit.get("served", "")
	if visit.get("lucky", false):
		line = visit["lucky_yes"] if quality >= 1.0 else visit["lucky_no"]
	if line != "":
		_service.said.emit(served_seat, line)
	done = true
	return extra


func on_grumpy() -> void:
	_service.state.add_friendship(id, -GRUMPY_LOSS)


## Tips are doubled for good friends.
func tip_multiplier() -> float:
	return 2.0 if friendship() >= int(info["big_tips_at"]) else 1.0


func _try_arrive() -> void:
	var free := _service.seats.find(null)
	if free < 0:
		if not waiting:
			waiting = true
			_service.message.emit("%s is waiting for a spot at the counter." % info["name"])
		return
	waiting = false
	var state := _service.state
	var order: Dictionary
	var hidden := false
	if visit["order"] is String:
		order = Dictionary(info["usual"]).duplicate()
		hidden = state.day >= int(info["usual_from_day"])
	else:
		order = Dictionary(visit["order"]).duplicate()
	seat = free
	_service.seat_customer(free, id, order, float(info["patience"]))
	var customer: Dictionary = _service.seats[free]
	customer["regular"] = id
	customer["usual_hidden"] = hidden
	state.regular(id)["visits"] = int(state.regular(id)["visits"]) + 1
	state.today["met"].append(id)
	var bring := int(visit.get("friends", 0))
	var with_friends := bring > 0 and friendship() >= int(info["friends_at"])
	var arrive: String = visit.get("arrive", "")
	if bring > 0 and not with_friends:
		arrive = visit.get("arrive_alone", arrive)
	if arrive != "":
		_service.said.emit(seat, arrive)
	if visit.get("treat", false):
		_service.treat = true
		_service.message.emit("%s is celebrating! Double tips for the rest of the day." % info["name"])
		_service.happened.emit("treat", 0)
	if with_friends:
		for i in bring:
			_service.arrive("student")


func _should_teach() -> bool:
	var flags: Dictionary = _service.state.regular(id)["flags"]
	return (not flags.get("taught", false) and _service.state.day >= 3
		and friendship() >= int(info["teach_at"]) and not _service.state.recipes.has("ginger_tea"))


func _teach() -> void:
	var state := _service.state
	state.regular(id)["flags"]["taught"] = true
	state.recipes.append("ginger_tea")
	state.stock["ginger"] = int(state.stock["ginger"]) + 20
	_service.said.emit(seat, visit["wait"] if visit.has("teach") else TEACH_LINE)
	_service.message.emit("New recipe: ginger tea! %s's amma sent some ginger too." % info["name"])
	_service.happened.emit("recipe", 0)
