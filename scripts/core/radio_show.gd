class_name RadioShow
extends RefCounted
## The radio on the kadai shelf. Every so often it plays a song, or on match
## days (weekends) the cricket commentary. A big shot gets the whole street
## cheering, and waiting customers forget how long they've waited.

const GAP := Vector2(35.0, 60.0)
## How much patience a six gives back to everyone waiting, in seconds.
const SIX_PATIENCE := 10.0

## A WeakRef: the service owns this, so a strong reference back would leak.
var _service: WeakRef
var _timer := 0.0


func _init(service: Service) -> void:
	_service = weakref(service)
	_timer = service.rng.randf_range(12.0, 25.0)


func update(delta: float) -> void:
	var service: Service = _service.get_ref()
	if service == null or service.closed:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = service.rng.randf_range(GAP.x, GAP.y)
	if Chennai.is_match_day(service.state.day):
		_commentary(service)
	else:
		var song: String = Chennai.SONGS[service.rng.randi() % Chennai.SONGS.size()]
		service.message.emit("♪ On the radio: %s ♪" % song)
		service.happened.emit("radio", 0)


func _commentary(service: Service) -> void:
	var ball: Dictionary = Chennai.CRICKET[service.rng.randi() % Chennai.CRICKET.size()]
	service.message.emit("Radio commentary: " + ball["text"])
	service.happened.emit("cheer" if ball["cheer"] else "radio", 0)
	if ball.get("six", false):
		for customer in service.seats:
			if customer != null:
				customer["patience"] = minf(float(customer["patience_max"]), float(customer["patience"]) + SIX_PATIENCE)
	# Someone at the counter reacts.
	var waiting: Array[int] = []
	for seat in service.seats.size():
		if service.seats[seat] != null and not service.seats[seat].has("regular"):
			waiting.append(seat)
	if not waiting.is_empty():
		var line: String = Chennai.CRICKET_REACTIONS[service.rng.randi() % Chennai.CRICKET_REACTIONS.size()]
		service.said.emit(waiting[service.rng.randi() % waiting.size()], line)
