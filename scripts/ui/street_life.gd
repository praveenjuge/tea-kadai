class_name StreetLife
extends RefCounted
## The street around the kadai: people walking and cycling past, a dog, school
## kids, rain, and customers chatting while they wait. Pure atmosphere, drawn
## by the street view.

const LANES: Array[float] = [4.3, 4.85]
const CYCLE_LANE := 5.95
const SPAWN_GAP := Vector2(1.6, 4.0)
const CHAT_GAP := Vector2(7.0, 13.0)
const LEFT_END := -14.0
const RIGHT_END := 20.0
const SHIRTS: Array[Color] = [Color("e0604e"), Color("4a90d9"), Color("7cc46a"), Color("e8c547"),
	Color("eef0f2"), Color("b05fc4"), Color("e8742f"), Color("5ac4b8")]
const UMBRELLAS: Array[Color] = [Color("1f1f1f"), Color("c0392b"), Color("2f6db5"), Color("7b4fb8")]

var _view: StreetView
var _rng := RandomNumberGenerator.new()
## Each: {"kind", "x", "lane", "speed", "look", "umbrella"}.
var _walkers: Array[Dictionary] = []
var _spawn := 0.3
var _chat := 6.0


func _init(view: StreetView) -> void:
	_view = view
	_rng.randomize()
	# Start with a few people already on the street.
	for i in 3:
		_spawn_walker(false)
		_walkers[-1]["x"] = _rng.randf_range(-6.0, 14.0)


func update(delta: float) -> void:
	var service := _view.service()
	var raining := service.is_raining()
	_spawn -= delta
	if _spawn <= 0.0:
		_spawn = _rng.randf_range(SPAWN_GAP.x, SPAWN_GAP.y) * (1.7 if raining else 1.0)
		_spawn_walker(raining)
	for walker in _walkers:
		walker["x"] += float(walker["speed"]) * delta
	_walkers = _walkers.filter(func(w: Dictionary) -> bool:
		return w["x"] > LEFT_END - 1.0 and w["x"] < RIGHT_END + 1.0)
	_chat -= delta
	if _chat <= 0.0:
		_chat = _rng.randf_range(CHAT_GAP.x, CHAT_GAP.y)
		_say_chatter(service)


func draw_passers_by() -> void:
	var sorted := _walkers.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["lane"] < b["lane"])
	for walker in sorted:
		var feet := _view._iso(Vector2(walker["x"], walker["lane"])).round()
		match walker["kind"]:
			"walker":
				_view.draw_figure(walker["look"], feet, true, 1.0)
				_draw_umbrella(walker, feet, 1.0)
			"kids":
				for offset in [Vector2(-5, 0), Vector2(5, 2)]:
					_view.draw_figure(walker["look"], feet + offset, true, 1.0, 0.72)
				_draw_umbrella(walker, feet, 0.8)
			"cyclist":
				_draw_cyclist(walker, feet)
			"dog":
				_draw_dog(walker, feet)


## Grey light, falling streaks and puddles while it rains.
func draw_rain() -> void:
	var service := _view.service()
	if not service.is_raining():
		return
	var minute := service.clock.minutes()
	var strength := clampf((minute - service.rain.x) / 15.0, 0.0, 1.0) * clampf((service.rain.y - minute) / 15.0, 0.0, 1.0)
	var size := _view.size
	_view.draw_rect(Rect2(Vector2.ZERO, size), Color(0.18, 0.22, 0.32, 0.25 * strength))
	for i in 6:
		var at := _view._iso(Vector2(-2.0 + i * 2.3, 4.2 + (i % 3) * 0.5))
		_view.draw_rect(Rect2(at + Vector2(-12, -2), Vector2(24, 4)), Color(0.55, 0.62, 0.75, 0.35 * strength))
	var t := _view.time()
	for i in int(140 * strength):
		var x := fmod(i * 73.13 + t * 40.0, size.x + 40.0) - 20.0
		var y := fmod(i * 31.71 + t * 280.0, size.y + 20.0) - 10.0
		_view.draw_line(Vector2(x, y), Vector2(x - 3, y + 8), Color(0.8, 0.86, 0.96, 0.55), 1.0)


func _spawn_walker(raining: bool) -> void:
	var minute := _view.service().clock.minutes()
	var school_time := minute > 420.0 and minute < 1020.0 and not raining
	var roll := _rng.randf()
	var kind := "walker"
	if roll < 0.2:
		kind = "cyclist"
	elif roll < 0.32:
		kind = "dog"
	elif roll < 0.44 and school_time:
		kind = "kids"
	var direction := 1.0 if _rng.randf() < 0.5 else -1.0
	var speed: float = {"walker": 1.2, "kids": 1.0, "cyclist": 3.4, "dog": 1.8}[kind] * _rng.randf_range(0.85, 1.15)
	var look := {
		"shirt": SHIRTS[_rng.randi() % SHIRTS.size()],
		"legs": [Color("2d3a5a"), Color("4a4a4a"), Color("f4f1e8"), Color("6b5a3a")][_rng.randi() % 4],
		"hair": [Color("1e1612"), Color("2b1d14"), Color("c9c4bb")][_rng.randi() % 3],
	}
	if kind == "kids":
		look = {"shirt": Color("eef0f2"), "legs": Color("2f4f8f"), "hair": Color("1e1612"), "bag": Color("c0392b")}
	_walkers.append({
		"kind": kind,
		"x": LEFT_END if direction > 0.0 else RIGHT_END,
		"lane": CYCLE_LANE if kind == "cyclist" else LANES[_rng.randi() % LANES.size()] + _rng.randf_range(-0.1, 0.1),
		"speed": speed * direction,
		"look": look,
		"umbrella": UMBRELLAS[_rng.randi() % UMBRELLAS.size()] if raining and kind != "dog" else Color(0, 0, 0, 0),
	})


func _draw_umbrella(walker: Dictionary, feet: Vector2, scale: float) -> void:
	var color: Color = walker["umbrella"]
	if color.a == 0.0:
		return
	var top := feet + Vector2(0, -34 * scale)
	_view.draw_line(top, top + Vector2(0, 10 * scale), Color("3a3a3a"), 1.0)
	var points := PackedVector2Array()
	for i in 9:
		var a := PI + PI * i / 8.0
		points.append(top + Vector2(cos(a) * 11.0, sin(a) * 6.0) * scale)
	_view.draw_colored_polygon(points, color)


func _draw_cyclist(walker: Dictionary, feet: Vector2) -> void:
	var facing := signf(float(walker["speed"]))
	for wheel in [-6.0, 6.0]:
		_view.draw_arc(feet + Vector2(wheel * facing, -4), 4.0, 0.0, TAU, 10, Color("2b2b2b"), 1.0)
	_view.draw_line(feet + Vector2(-6 * facing, -4), feet + Vector2(0, -9), Color("c0392b"), 1.0)
	_view.draw_line(feet + Vector2(6 * facing, -4), feet + Vector2(0, -9), Color("c0392b"), 1.0)
	_view.draw_figure(walker["look"], feet + Vector2(-1 * facing, -6), false, 1.0, 0.8)
	_draw_umbrella(walker, feet + Vector2(0, -5), 0.8)


func _draw_dog(walker: Dictionary, feet: Vector2) -> void:
	var facing := signf(float(walker["speed"]))
	var brown := Color("a0703a")
	var step := absf(sin(_view.time() * 14.0)) * 1.0
	_view.draw_rect(Rect2(feet + Vector2(-6, -7 - step), Vector2(12, 5)), brown)
	_view.draw_rect(Rect2(feet + Vector2(4 * facing - 2, -10 - step), Vector2(5, 5)), brown)
	for leg in [-5, -2, 2, 5]:
		_view.draw_rect(Rect2(feet + Vector2(leg, -2), Vector2(1, 2)), brown.darkened(0.3))
	var wag := sin(_view.time() * 20.0) * 2.0
	_view.draw_line(feet + Vector2(-6 * facing, -7), feet + Vector2(-9 * facing, -10 + wag), brown, 1.0)


func _say_chatter(service: Service) -> void:
	var waiting: Array[int] = []
	for seat in service.seats.size():
		var customer = service.seats[seat]
		if customer != null and not customer.has("regular"):
			waiting.append(seat)
	if waiting.is_empty():
		return
	var minute := service.clock.minutes()
	var pool := "any"
	if service.is_raining():
		pool = "rain"
	elif minute < 600.0 and _rng.randf() < 0.5:
		pool = "morning"
	elif minute > 1020.0 and _rng.randf() < 0.5:
		pool = "evening"
	var lines: Array = Catalog.CHATTER[pool]
	_view.say(waiting[_rng.randi() % waiting.size()], lines[_rng.randi() % lines.size()])
