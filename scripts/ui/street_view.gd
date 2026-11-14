class_name StreetView
extends Control
## Isometric view of the kadai and the street. Everything is placeholder shapes
## drawn in code until the real pixel art is made.

signal seat_clicked(seat: int)
## The player picked an answer to a customer's question.
signal answered(seat: int, index: int)

const HALF_W := 20.0
const HALF_H := 10.0
## Where customers stand at the counter, in tile coordinates.
## Customers stand at the shop's counter. The fifth spot, by the table
## outside, opens with the bench upgrade.
const SEAT_TILES: Array[Vector2] = [Vector2(1.9, 1.0), Vector2(3.4, 1.0), Vector2(4.9, 1.0), Vector2(6.4, 1.0), Vector2(8.3, 1.9)]
## The kadai's building in the row (back corner to front corner, in tiles),
## how tall it is, and how tall the shop's open front is.
const SHOP_FROM := Vector2(1.0, -3.6)
const SHOP_TO := Vector2(7.0, -0.7)
const SHOP_HEIGHT := 104.0
const SHOP_OPENING := 54.0
## The counter across the shop front, and the table outside.
const COUNTER_FROM := Vector2(1.4, -0.6)
const COUNTER_TO := Vector2(6.6, 0.2)
const COUNTER_MID_Y := -0.2
const COUNTER_HEIGHT := 14.0
const SEATING := Vector2(8.0, 0.6)
## The edge of the road that customers walk in from and leave to.
const ROAD_EDGE_Y := 6.6
const WALK_SECONDS := 0.7
const LEAVE_SECONDS := 1.6
## Customers are drawn a little larger than passers-by so their faces read.
const CUSTOMER_SCALE := 1.25

const WOOD := Color("9a6a3c")
const STALL_PAINT := Color("2f7fb5")
const TARP := Color("3b6fc4")

var _service: Service
var _time := 0.0
## Walk-in progress per seat, 0 to 1.
var _arrive: Array[float] = []
## Seconds left of each seat's hello wave.
var _wave: Array[float] = []
## Customers on their way out: {"type", "tile", "t", "text", "color"}.
var _leavers: Array[Dictionary] = []
var _origin := Vector2.ZERO
var _font: Font
var _speech: SpeechBubbles
var _life: StreetLife
var _scenery: StreetScenery


func _init(service: Service) -> void:
	_service = service
	for i in service.seats.size():
		_arrive.append(1.0)
		_wave.append(0.0)
	clip_contents = true
	_speech = SpeechBubbles.new(self)
	_life = StreetLife.new(self)
	_scenery = StreetScenery.new(self)


func _ready() -> void:
	_font = get_theme_default_font()


func on_arrived(seat: int) -> void:
	_arrive[seat] = 0.0
	_wave[seat] = WALK_SECONDS + 1.2


func say(seat: int, text: String) -> void:
	_speech.say(seat, text, _portrait_for(seat))


func ask(seat: int, question: String, options: Array) -> void:
	_speech.ask(seat, question, options, _portrait_for(seat))


## A regular's look, for a portrait beside what they say. Empty for others.
func _portrait_for(seat: int) -> Dictionary:
	var customer = _service.seats[seat]
	if customer != null and customer.has("regular"):
		return Story.REGULARS[customer["regular"]]
	return {}


## Where a seated customer's head is, in this view's coordinates.
func seat_point(seat: int) -> Vector2:
	return _iso(SEAT_TILES[seat], 28.0)


func service() -> Service:
	return _service


func time() -> float:
	return _time


func on_left(seat: int, customer: Dictionary, outcome: String) -> void:
	var text := "Shop's closing!"
	var color := Style.MUTED
	if outcome == "served":
		text = "%s +%s" % [customer.get("reaction", ""), Style.rupees(int(customer["bill"]) + int(customer.get("tip", 0)))]
		color = Style.WARN if customer["grumpy"] else Style.GOOD
	elif outcome == "gave_up":
		text = "Forget it, I'm going!"
		color = Style.BAD
	elif outcome == "out_of_stock":
		text = "Nothing left? Okay…"
		color = Style.MUTED
	var happy: bool = outcome == "served" and not customer["grumpy"]
	_leavers.append({"type": customer["type"], "tile": SEAT_TILES[seat], "t": 0.0, "text": text, "color": color, "happy": happy})


func _process(delta: float) -> void:
	_time += delta
	for i in _arrive.size():
		_arrive[i] = minf(1.0, _arrive[i] + delta / WALK_SECONDS)
		_wave[i] = maxf(0.0, _wave[i] - delta)
	for leaver in _leavers:
		leaver["t"] += delta
	_leavers = _leavers.filter(func(l: Dictionary) -> bool: return l["t"] < LEAVE_SECONDS)
	_speech.update(delta)
	_life.update(delta)
	_scenery.update(delta)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null:
		var pointing := _seat_at(motion.position) >= 0 or _speech.option_at(motion.position).size() > 0
		mouse_default_cursor_shape = CURSOR_POINTING_HAND if pointing else CURSOR_ARROW
		return
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		var option := _speech.option_at(click.position)
		if option.size() > 0:
			_speech.clear(option[0])
			answered.emit(option[0], option[1])
			accept_event()
			return
		var seat := _seat_at(click.position)
		if seat >= 0:
			seat_clicked.emit(seat)
			accept_event()


func _seat_at(point: Vector2) -> int:
	for seat in _service.seats.size():
		if _service.seats[seat] == null or _arrive[seat] < 1.0:
			continue
		var feet := _iso(SEAT_TILES[seat])
		var order: Dictionary = _service.seats[seat]["order"]
		var items := 0
		for item in order:
			items += int(order[item])
		if _service.seats[seat].get("usual_hidden", false):
			items = 2
		var body := Rect2(feet + Vector2(-12, -44), Vector2(24, 46))
		if body.has_point(point) or _bubble_box(seat, items).grow(2.0).has_point(point):
			return seat
	return -1


func _iso(tile: Vector2, up: float = 0.0) -> Vector2:
	return _origin + Vector2((tile.x - tile.y) * HALF_W, (tile.x + tile.y) * HALF_H - up)


# --- Drawing --------------------------------------------------------------

func _draw() -> void:
	_origin = Vector2(roundf(size.x * 0.5 - 50.0), roundf(size.y * 0.5 - 8.0))
	_scenery.draw_sky()
	_scenery.draw_buildings()
	_scenery.draw_ground()
	_scenery.draw_shadows()
	var day := _service.state.day
	ChennaiBits.draw_poster_wall(self, day)
	ChennaiBits.draw_auto_stand(self, _scenery)
	ChennaiBits.draw_cutout(self, day, _time)
	_draw_stall()
	ChennaiBits.draw_festival(self, day, _time)
	_draw_tree(Vector2(-0.6, 3.6))
	_draw_cow(Vector2(9.4, 3.9))
	for seat in _service.seats.size():
		var customer = _service.seats[seat]
		if customer != null:
			var pose := ""
			if customer["grumpy"]:
				pose = "slump"
			elif _arrive[seat] >= 1.0 and _wave[seat] > 0.0:
				pose = "wave"
			draw_person(customer["type"], _walk_tile(seat), _arrive[seat] < 1.0, 1.0, pose)
	for leaver in _leavers:
		var t: float = leaver["t"] / LEAVE_SECONDS
		var from: Vector2 = leaver["tile"]
		var tile := from.lerp(Vector2(from.x + 1.5, ROAD_EDGE_Y + 0.6), t)
		# Happy customers hop as they leave.
		var hop: float = absf(sin(t * TAU * 1.5)) * 5.0 if leaver.get("happy", false) and t < 0.66 else 0.0
		draw_person(leaver["type"], tile, true, 1.0 - t, "", hop)
	_life.draw_passers_by()
	_scenery.draw_lamps(true)
	_scenery.draw_traffic()
	_life.draw_rain()
	_draw_light()
	_scenery.draw_lamps(false)
	for seat in _service.seats.size():
		if _service.seats[seat] != null and _arrive[seat] >= 1.0:
			_draw_bubble(seat, _service.seats[seat])
	for leaver in _leavers:
		var t: float = leaver["t"] / LEAVE_SECONDS
		var at := _iso(leaver["tile"], 40.0 + t * 14.0)
		var color: Color = leaver["color"]
		_text(at, leaver["text"], Color(color, 1.0 - t * t), HORIZONTAL_ALIGNMENT_CENTER)
	_speech.draw()


func _walk_tile(seat: int) -> Vector2:
	var to := SEAT_TILES[seat]
	var t := ease(_arrive[seat], 0.6)
	return Vector2(to.x - 1.0, ROAD_EDGE_Y).lerp(to, t)


## The kadai's building in the street's row: the shop on the ground floor,
## open at the front so you can see in, with flats above. Drawn by the
## scenery in row order so the neighbours overlap it correctly.
func draw_kadai_building() -> void:
	var painted := _service.state.has_upgrade("paint")
	var paint := STALL_PAINT if painted else STALL_PAINT.lerp(Color("8a8f94"), 0.55)
	var x0 := SHOP_FROM.x
	var x1 := SHOP_TO.x
	var front := SHOP_TO.y
	var back := SHOP_FROM.y
	_box(Vector2(x0, back), Vector2(x1, front), SHOP_HEIGHT, paint.lightened(0.1), paint, paint.darkened(0.25))
	# Inside the shop, seen through the open front: floor, side wall, back wall.
	var in0 := x0 + 0.4
	var in1 := x1 - 0.4
	var deep := front - 1.0
	var tiles := PackedVector2Array([_iso(Vector2(in0, deep)), _iso(Vector2(in1, deep)), _iso(Vector2(in1, front)), _iso(Vector2(in0, front))])
	draw_colored_polygon(tiles, Color("b5582f"))
	for t in 4:
		var y := lerpf(deep, front, (t + 1) / 5.0)
		draw_line(_iso(Vector2(in0, y)), _iso(Vector2(in1, y)), Color("9a4a26"), 1.0)
	var wall := Color("e8d9b8") if painted else Color("cfc4ad")
	draw_colored_polygon(PackedVector2Array([_iso(Vector2(in0, deep)), _iso(Vector2(in0, front)),
		_iso(Vector2(in0, front), SHOP_OPENING), _iso(Vector2(in0, deep), SHOP_OPENING)]), wall.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([_iso(Vector2(in0, deep)), _iso(Vector2(in1, deep)),
		_iso(Vector2(in1, deep), SHOP_OPENING), _iso(Vector2(in0, deep), SHOP_OPENING)]), wall)
	_draw_shop_inside(in0, in1, deep, front)
	# The front wall around the opening: pillars and the wall above.
	_wall_quad(x0, in0, front, 0.0, SHOP_OPENING, paint)
	_wall_quad(in1, x1, front, 0.0, SHOP_OPENING, paint)
	_wall_quad(x0, x1, front, SHOP_OPENING, SHOP_HEIGHT, paint)
	draw_line(_iso(Vector2(in0, front), SHOP_OPENING), _iso(Vector2(in1, front), SHOP_OPENING), paint.darkened(0.5), 2.0)
	if not painted:
		for stain in [Vector2(x0 + 0.8, front), Vector2(x1 - 1.5, front)]:
			draw_rect(Rect2(_iso(stain, SHOP_OPENING + 20), Vector2(10, 6)), Color(0.3, 0.25, 0.2, 0.25))
	_draw_flat_above(x0, x1, front, paint)
	_draw_shop_sign((x0 + x1) / 2.0, front, painted)


func _wall_quad(from_x: float, to_x: float, y: float, low: float, high: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([_iso(Vector2(from_x, y), low), _iso(Vector2(to_x, y), low),
		_iso(Vector2(to_x, y), high), _iso(Vector2(from_x, y), high)]), color)


func _draw_shop_inside(in0: float, in1: float, deep: float, front: float) -> void:
	# Two shelves of jars and packets on the back wall, and a tube light.
	var colors := [Color("e0604e"), Color("e8c547"), Color("7cc46a"), Color("d9a55b"), Color("4a90d9")]
	for shelf in 2:
		var up := 12.0 + shelf * 14.0
		var left := _iso(Vector2(in0 + 0.2, deep), up)
		var right := _iso(Vector2(in1 - 0.2, deep), up)
		draw_line(left, right, WOOD.darkened(0.3), 2.0)
		for i in 10:
			var at := left.lerp(right, (i + 0.5) / 10.0)
			if shelf == 0 and i % 3 == 0:
				draw_rect(Rect2(at + Vector2(-3, -8), Vector2(6, 8)), Color(0.9, 0.95, 1.0, 0.5))
				draw_rect(Rect2(at + Vector2(-2, -5), Vector2(4, 5)), Color("d9a55b"))
			else:
				draw_rect(Rect2(at + Vector2(-2, -7), Vector2(5, 7)), colors[(i + shelf) % colors.size()])
	var tube := _iso(Vector2((in0 + in1) / 2.0, deep), SHOP_OPENING - 6)
	var night := _service.clock.minutes() > 1080.0
	draw_rect(Rect2(tube + Vector2(-14, 0), Vector2(28, 2)), Color("fffbe8") if night else Color("dfe5ea"))
	if night:
		draw_circle(tube + Vector2(0, 14), 30.0, Color(1, 0.98, 0.85, 0.12))
	if _service.state.has_upgrade("radio"):
		_draw_radio_and_posters(in0, deep)
	if _service.state.has_upgrade("fan"):
		var fan := _iso(Vector2(in1 - 0.6, deep), 44)
		draw_rect(Rect2(fan + Vector2(-1, 0), Vector2(2, 8)), Color("4a4a4a"))
		draw_circle(fan, 7.0, Color(0.85, 0.88, 0.92, 0.35))
		for i in 3:
			var a := _time * 18.0 + i * TAU / 3.0
			draw_line(fan, fan + Vector2(cos(a), sin(a) * 0.6) * 7.0, Color("dfe5ea"), 2.0)
		draw_circle(fan, 1.5, Color("4a4a4a"))
	# Bunches of bananas hanging just inside the front.
	for spot in [in0 + 0.3, in1 - 0.3]:
		var hook := _iso(Vector2(spot, front - 0.15), SHOP_OPENING - 2)
		draw_line(hook, hook + Vector2(0, 4), Color("ded4bf"), 1.0)
		for i in 5:
			draw_rect(Rect2(hook + Vector2(-5 + i * 2, 4 + (i % 2) * 2), Vector2(2, 8)), Color("e8d23c"))


## The flat above the shop: windows, a balcony with a plant and washing.
func _draw_flat_above(x0: float, x1: float, front: float, paint: Color) -> void:
	var night := _service.clock.minutes() > 1120.0
	for w in 3:
		var gx := x0 + 0.8 + w * 1.7
		var at := _iso(Vector2(gx, front), SHOP_HEIGHT - 10.0)
		var glass := Color("ffe9a8") if night and w != 1 else Color("2a3a48")
		draw_colored_polygon(PackedVector2Array([at, at + Vector2(14, 7), at + Vector2(14, 21), at + Vector2(0, 14)]), glass)
		draw_line(at + Vector2(7, 3.5), at + Vector2(7, 17.5), paint.darkened(0.45), 1.0)
	var rail_l := _iso(Vector2(x0 + 0.3, front + 0.25), SHOP_HEIGHT - 30.0)
	var rail_r := _iso(Vector2(x1 - 0.3, front + 0.25), SHOP_HEIGHT - 30.0)
	draw_line(rail_l, rail_r, Color("3a3a40"), 1.0)
	for i in 12:
		var post := rail_l.lerp(rail_r, i / 11.0)
		draw_line(post, post + Vector2(0, 8), Color("3a3a40"), 1.0)
	var washing := [Color("e0604e"), Color("4a90d9"), Color("eef0f2"), Color("e8c547")]
	for i in 4:
		var at := rail_l.lerp(rail_r, 0.15 + i * 0.12) + Vector2(0, -6)
		draw_rect(Rect2(at, Vector2(5, 7)), washing[i])
	var pot := rail_l.lerp(rail_r, 0.85)
	draw_rect(Rect2(pot + Vector2(-4, -6), Vector2(8, 6)), Color("b5582f"))
	draw_circle(pot + Vector2(0, -9), 4.0, Color("4a9a3a"))


## Above the shop front: cardboard at first, a proper painted board once the
## shop is painted, with bulbs around it once lit.
func _draw_shop_sign(center_x: float, front: float, painted: bool) -> void:
	var sign_at := _iso(Vector2(center_x, front), SHOP_OPENING + 34)
	if not painted:
		draw_rect(Rect2(sign_at + Vector2(-20, -9), Vector2(40, 12)), Color("b08a5a"))
		draw_rect(Rect2(sign_at + Vector2(-20, -9), Vector2(40, 12)), Color("7a5a3a"), false, 1.0)
		_text(sign_at, "TEA", Color("3a2a1a"), HORIZONTAL_ALIGNMENT_CENTER)
		return
	if _service.state.has_upgrade("sign"):
		var lit := _service.clock.minutes() > 1050.0
		for i in 12:
			var bulb := sign_at + Vector2(-38 + i * 6.8, -13)
			var on := lit and (int(_time * 4.0) + i) % 3 != 0
			draw_rect(Rect2(bulb, Vector2(2, 2)), Color("fff3a8") if on else Color("8a7a4a"))
			draw_rect(Rect2(bulb + Vector2(0, 17), Vector2(2, 2)), Color("fff3a8") if on else Color("8a7a4a"))
		if lit:
			draw_circle(sign_at + Vector2(0, -4), 46.0, Color(1.0, 0.95, 0.6, 0.12))
	draw_rect(Rect2(sign_at + Vector2(-36, -11), Vector2(72, 15)), Color("e8c547"))
	draw_rect(Rect2(sign_at + Vector2(-36, -11), Vector2(72, 15)), Color("b5321f"), false, 1.0)
	_text(sign_at + Vector2(0, 1), "TEA KADAI", Color("b5321f"), HORIZONTAL_ALIGNMENT_CENTER)


## In front of the shop: the counter and what's on it, the awning, plants,
## and a table with plastic chairs on the pavement.
func _draw_stall() -> void:
	var big := _service.state.has_upgrade("counter")
	var c0 := COUNTER_FROM.x - (0.2 if big else 0.0)
	var c1 := COUNTER_TO.x + (0.2 if big else 0.0)
	_box(Vector2(c0, COUNTER_FROM.y), Vector2(c1, COUNTER_TO.y), COUNTER_HEIGHT, WOOD.lightened(0.15), WOOD, WOOD.darkened(0.25))
	_quad_up(Vector2(c0, COUNTER_TO.y - 0.05), Vector2(c1, COUNTER_TO.y), COUNTER_HEIGHT - 4.0, 4, Color("e8c547"))
	_draw_counter_things()
	_draw_seating()
	# A short tarp awning fixed above the open front, so you can still see in.
	var top := SHOP_OPENING + 16.0
	var reach := SHOP_TO.y + 0.6
	var roof := [_iso(Vector2(SHOP_FROM.x + 0.1, SHOP_TO.y), top), _iso(Vector2(SHOP_TO.x - 0.1, SHOP_TO.y), top),
		_iso(Vector2(SHOP_TO.x - 0.1, reach), top - 12.0), _iso(Vector2(SHOP_FROM.x + 0.1, reach), top - 12.0)]
	draw_colored_polygon(PackedVector2Array(roof), TARP)
	for i in range(1, 8):
		var t := i / 8.0
		draw_line(roof[0].lerp(roof[1], t), roof[3].lerp(roof[2], t), TARP.darkened(0.2), 1.0)
	draw_line(roof[3], roof[2], TARP.darkened(0.4), 2.0)
	# A scalloped edge along the front.
	for i in 16:
		var at: Vector2 = roof[3].lerp(roof[2], (i + 0.5) / 16.0)
		draw_circle(at + Vector2(0, 1), 3.0, TARP.darkened(0.15) if i % 2 == 0 else Color("f3e3c3"))
	if _service.state.has_upgrade("plants"):
		_draw_plants_and_lights(roof)


## A steel table with two plastic chairs on the pavement beside the shop.
func _draw_seating() -> void:
	var table := SEATING
	for chair in [[Vector2(-0.7, 0.0), Color("d64a3a")], [Vector2(0.9, 0.1), Color("2f6db5")]]:
		var at: Vector2 = table + chair[0]
		var color: Color = chair[1]
		_box(at, at + Vector2(0.35, 0.35), 6, color.lightened(0.15), color, color.darkened(0.25))
		_box(at, at + Vector2(0.06, 0.35), 13, color, color.darkened(0.1), color.darkened(0.3))
	_box(table, table + Vector2(0.6, 0.5), 11, Color("c9ced6"), Color("8a9098"), Color("6a7078"))
	for i in 2:
		Style.draw_item(self, "tea", _iso(table + Vector2(0.15 + i * 0.3, 0.25), 15), 0.9)


func _draw_plants_and_lights(roof: Array) -> void:
	for spot in [Vector2(SHOP_FROM.x - 0.2, SHOP_TO.y + 0.4), Vector2(SHOP_TO.x + 0.2, SHOP_TO.y + 0.4)]:
		var pot := _iso(spot)
		draw_rect(Rect2(pot + Vector2(-5, -8), Vector2(10, 8)), Color("b5582f"))
		draw_rect(Rect2(pot + Vector2(-6, -9), Vector2(12, 2)), Color("c96a3a"))
		for leaf in [Vector2(-4, -14), Vector2(0, -18), Vector2(4, -14), Vector2(-2, -12), Vector2(2, -12)]:
			draw_circle(pot + leaf, 3.5, Color("4a9a3a"))
	var lit := _service.clock.minutes() > 1050.0
	var colors := [Color("ff6b6b"), Color("ffd93d"), Color("6bcBff"), Color("8aff8a")]
	for i in 14:
		var at: Vector2 = roof[3].lerp(roof[2], (i + 0.5) / 14.0) + Vector2(0, 3 + sin(i * 1.3) * 1.5)
		var color: Color = colors[i % colors.size()]
		var on := lit and (int(_time * 3.0) + i) % 4 != 0
		draw_rect(Rect2(at, Vector2(2, 2)), color if on else color.darkened(0.5))
		if on:
			draw_circle(at + Vector2(1, 1), 4.0, Color(color, 0.18))


func _draw_radio_and_posters(in0: float, deep: float) -> void:
	var poster := _iso(Vector2(in0 + 0.5, deep), 52)
	draw_rect(Rect2(poster + Vector2(-6, 0), Vector2(12, 16)), Color("2f6db5"))
	draw_rect(Rect2(poster + Vector2(-5, 2), Vector2(10, 6)), Color("e8c547"))
	draw_rect(Rect2(poster + Vector2(-5, 10), Vector2(10, 2)), Color("f3e3c3"))
	var photo := _iso(Vector2(in0 + 1.5, deep), 50)
	draw_rect(Rect2(photo + Vector2(-5, 0), Vector2(10, 9)), Color("6b4a2e"))
	draw_rect(Rect2(photo + Vector2(-4, 1), Vector2(8, 7)), Color("d9c9a5"))
	draw_rect(Rect2(photo + Vector2(-1, 3), Vector2(2, 4)), Color("6b4a2e"))
	var radio := _iso(Vector2(in0 + 3.2, deep), 44)
	draw_rect(Rect2(radio + Vector2(-8, -8), Vector2(16, 9)), Color("8a3a2a"))
	draw_circle(radio + Vector2(-3, -4), 2.5, Color("3a2a1a"))
	draw_rect(Rect2(radio + Vector2(2, -6), Vector2(4, 1)), Color("e8c547"))
	draw_line(radio + Vector2(5, -8), radio + Vector2(9, -16), Color("9aa3ad"), 1.0)
	for i in 2:
		var rise := fmod(_time * 10.0 + i * 9.0, 18.0)
		var note := radio + Vector2(-2 + i * 7 + sin(_time * 2.0 + i) * 3.0, -12 - rise)
		var alpha := 1.0 - rise / 18.0
		draw_rect(Rect2(note, Vector2(2, 2)), Color(Style.TEXT, alpha))
		draw_line(note + Vector2(2, 0), note + Vector2(2, -4), Color(Style.TEXT, alpha), 1.0)


func _draw_counter_things() -> void:
	# Biscuit jars on the left of the counter.
	var biscuits := _service.state.how_many("biscuit")
	for i in 2:
		var jar := _iso(Vector2(COUNTER_FROM.x + 0.4 + i * 0.5, COUNTER_MID_Y), COUNTER_HEIGHT)
		draw_rect(Rect2(jar + Vector2(-4, -12), Vector2(8, 12)), Color(0.9, 0.95, 1.0, 0.45))
		var fill := clampi(biscuits - i * 10, 0, 10)
		if fill > 0:
			draw_rect(Rect2(jar + Vector2(-3, -fill), Vector2(6, fill)), Color("d9a55b"))
		draw_rect(Rect2(jar + Vector2(-4, -14), Vector2(8, 2)), Color("e0604e"))
	# Ready tea glasses along the middle of the counter, vadai piled on a plate.
	var glass := 0
	for kind in Catalog.GLASSES:
		for quality in _service.ready[kind]:
			Style.draw_item(self, kind, _iso(Vector2(COUNTER_FROM.x + 1.3 + glass * 0.36, COUNTER_MID_Y), COUNTER_HEIGHT + 6.0), quality)
			glass += 1
	var vadai: Array = _service.ready["vadai"]
	if not vadai.is_empty():
		var plate := _iso(Vector2(COUNTER_FROM.x + 3.6, COUNTER_MID_Y), COUNTER_HEIGHT + 1.0)
		draw_rect(Rect2(plate + Vector2(-9, -1), Vector2(18, 3)), Color("d8dde3"))
		for i in vadai.size():
			Style.draw_item(self, "vadai", plate + Vector2(-5 + (i % 3) * 5, -4 - (i / 3) * 4), vadai[i])
	# Stove and milk pot with steam on the right. The upgrade is a bigger pot.
	var stove := _iso(Vector2(COUNTER_TO.x - 0.7, COUNTER_MID_Y), COUNTER_HEIGHT)
	var pot := 1.4 if _service.state.has_upgrade("pot") else 1.0
	draw_rect(Rect2(stove + Vector2(-9, -4), Vector2(18, 4)), Color("2b2b2b"))
	draw_rect(Rect2(stove + Vector2(-8, -20) * pot, Vector2(16, 16) * pot), Color("b8863b"))
	draw_rect(Rect2(stove + Vector2(-9 * pot, -20 * pot - 2), Vector2(18 * pot, 3)), Color("d9a55b"))
	for i in 3:
		var x := stove.x - 5 + i * 5 + sin(_time * 2.5 + i) * 2.0
		var y := stove.y - 26 - fmod(_time * 10.0 + i * 5.0, 16.0)
		draw_rect(Rect2(x, y, 1, 3), Color(1, 1, 1, 0.45))


## "pose" is "", "wave" or "slump"; "lift" raises them off the ground (a hop).
func draw_person(type_id: String, tile: Vector2, walking: bool, alpha: float, pose: String = "", lift: float = 0.0) -> void:
	draw_figure(Service.kind_of(type_id), _iso(tile).round() - Vector2(0, lift), walking, alpha, CUSTOMER_SCALE, pose)


## A little person standing on "feet". "look" needs shirt, legs and hair
## colours; a "bag" colour adds a backpack.
func draw_figure(look: Dictionary, feet: Vector2, walking: bool, alpha: float, scale: float = 1.0, pose: String = "") -> void:
	draw_set_transform(feet, 0.0, Vector2(scale, scale))
	# Two-frame walk: legs swap and the body bobs on the second frame.
	var step := (int(_time * 8.0) % 2) if walking else 0
	var bob := float(step) + (1.5 if pose == "slump" else 0.0)
	var shirt: Color = look["shirt"]
	var legs: Color = look["legs"]
	var skin: Color = look.get("skin", Style.SKIN)
	var sun := _scenery.shadow_offset(12.0) / scale if _scenery.sun_up() else Vector2.ZERO
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -1), Vector2(4, -1), Vector2(4, 1) + sun, Vector2(-4, 1) + sun]),
		Color(0.15, 0.08, 0.02, 0.25 * alpha))
	if look.has("saree"):
		var saree: Color = look["saree"]
		draw_colored_polygon(PackedVector2Array([Vector2(-4, -12 - bob), Vector2(4, -12 - bob),
			Vector2(5, 0), Vector2(-5, 0)]), Color(legs, alpha))
		draw_rect(Rect2(-5, -2, 10, 1), Color(saree, alpha))
	else:
		draw_rect(Rect2(-3, -11 - bob, 2, 11 - (2 if step == 1 else 0) + bob), Color(legs, alpha))
		draw_rect(Rect2(1, -11 - bob, 2, 11 - (2 if walking and step == 0 else 0) + bob), Color(legs, alpha))
	draw_rect(Rect2(-4, -22 - bob, 8, 12), Color(shirt, alpha))
	draw_rect(Rect2(-5, -21 - bob, 1, 8), Color(skin, alpha))
	if pose == "wave":
		var swing := sin(_time * 14.0) * 1.5
		draw_rect(Rect2(4, -30 - bob, 1, 9), Color(skin, alpha))
		draw_rect(Rect2(4 + swing, -32 - bob, 2, 2), Color(skin, alpha))
	else:
		draw_rect(Rect2(4, -21 - bob, 1, 8), Color(skin, alpha))
	if look.has("saree"):
		draw_colored_polygon(PackedVector2Array([Vector2(1, -22 - bob), Vector2(4, -22 - bob),
			Vector2(-4, -12 - bob), Vector2(-4, -15 - bob)]), Color(look["saree"], alpha))
	if look.get("tag", false):
		draw_line(Vector2(-2, -22 - bob), Vector2(0, -17 - bob), Color(0.2, 0.3, 0.6, alpha), 1.0)
		draw_rect(Rect2(-1, -17 - bob, 3, 3), Color(1, 1, 1, alpha))
	if look.has("bag"):
		draw_line(Vector2(-3, -22 - bob), Vector2(3, -13 - bob), Color(look["bag"].darkened(0.3), alpha), 1.0)
		draw_rect(Rect2(4, -20 - bob, 3, 7), Color(look["bag"], alpha))
	draw_set_transform(feet + Vector2(0, (-22 - bob) * scale), 0.0, Vector2(scale, scale))
	Style.draw_head(self, look, alpha)
	if pose == "slump":
		# A little storm cloud over a grumpy head.
		var drift := sin(_time * 3.0)
		draw_circle(Vector2(-2 + drift, -15), 2.5, Color(0.35, 0.35, 0.4, alpha))
		draw_circle(Vector2(1 + drift, -16), 3.0, Color(0.35, 0.35, 0.4, alpha))
		draw_line(Vector2(0 + drift, -13), Vector2(-1 + drift, -10), Color("ffca3a", alpha), 1.0)
	draw_set_transform(Vector2.ZERO)


func _draw_bubble(seat: int, customer: Dictionary) -> void:
	var items: Array[String] = []
	var order: Dictionary = customer["order"]
	for item in Catalog.MENU_ORDER:
		for i in int(order.get(item, 0)):
			items.append(item)
	var hidden: bool = customer.get("usual_hidden", false)
	var box := _bubble_box(seat, 1 if hidden else items.size())
	if hidden:
		box = Rect2(box.position - Vector2(14, 0), box.size + Vector2(28, 0))
	var feet := _iso(SEAT_TILES[seat]).round()
	var ready := _service.can_fill(seat)
	var grumpy: bool = customer["grumpy"]
	draw_line(Vector2(feet.x, box.end.y), feet + Vector2(0, -44), Style.TEXT, 1.0)
	draw_rect(box, Style.TEXT)
	if ready:
		draw_rect(box.grow(1.0), Style.GOOD, false, 2.0)
	elif grumpy:
		draw_rect(box.grow(1.0), Style.BAD, false, 2.0)
	_text(box.position + Vector2(4, 17), str(seat + 1), Style.LINE, HORIZONTAL_ALIGNMENT_LEFT)
	if customer.has("regular"):
		var name_text: String = Story.REGULARS[customer["regular"]]["name"]
		_text(Vector2(box.get_center().x, box.position.y - 3), name_text, Style.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	if hidden:
		_text(box.position + Vector2(14, 17), "The usual?", Style.INK, HORIZONTAL_ALIGNMENT_LEFT)
		items.clear()
	# Items you could hand over right now are bright; the rest are faded.
	var on_hand := {}
	for i in items.size():
		var item := items[i]
		if not on_hand.has(item):
			on_hand[item] = _service.ready_count(item)
		var at := box.position + Vector2(24 + i * 20, 13)
		draw_set_transform(at, 0.0, Vector2(2, 2))
		Style.draw_item(self, item, Vector2.ZERO)
		draw_set_transform(Vector2.ZERO)
		if int(on_hand[item]) > 0:
			on_hand[item] -= 1
		else:
			draw_rect(Rect2(at - Vector2(9, 11), Vector2(18, 22)), Color(Style.TEXT, 0.7))
	var calm: float = customer["patience"] / customer["patience_max"]
	var bar_color := Style.GOOD if calm > 0.5 else (Style.WARN if calm > 0.25 else Style.BAD)
	draw_rect(Rect2(box.position + Vector2(0, box.size.y), Vector2(box.size.x, 3)), Color(0, 0, 0, 0.5))
	draw_rect(Rect2(box.position + Vector2(0, box.size.y), Vector2(box.size.x * calm, 3)), bar_color)
	if customer["grumpy"]:
		_text(box.position + Vector2(box.size.x + 2, 10), "grr", Style.BAD, HORIZONTAL_ALIGNMENT_LEFT, 8)


## Order bubbles currently on screen, so speech bubbles can stay clear of them.
func order_bubble_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for seat in _service.seats.size():
		var customer = _service.seats[seat]
		if customer == null or _arrive[seat] < 1.0:
			continue
		var items := 0
		for item in customer["order"]:
			items += int(customer["order"][item])
		if customer.get("usual_hidden", false):
			items = 2
		rects.append(_bubble_box(seat, items).grow(3.0))
	return rects


## The order bubble above a seat. Odd seats sit higher so neighbouring bubbles
## never overlap, even at the bigger icon size.
func _bubble_box(seat: int, item_count: int) -> Rect2:
	var width := 18.0 + item_count * 20.0
	var lift := 42.0 if seat % 2 == 1 else 0.0
	var feet := _iso(SEAT_TILES[seat]).round()
	return Rect2(feet + Vector2(-width / 2.0, -74.0 - lift), Vector2(width, 26))


func _draw_tree(tile: Vector2) -> void:
	var base := _iso(tile)
	draw_rect(Rect2(base + Vector2(-3, -40), Vector2(6, 40)), Color("6b4a2e"))
	for leaf in [Vector2(0, -56), Vector2(-14, -46), Vector2(14, -48), Vector2(-6, -66), Vector2(9, -62)]:
		draw_circle(base + leaf, 14.0, Color("3f7a3a"))
	for leaf in [Vector2(-4, -60), Vector2(10, -52)]:
		draw_circle(base + leaf, 8.0, Color("5a9a4a"))


func _draw_cow(tile: Vector2) -> void:
	var at := _iso(tile).round()
	var white := Color("ece6da")
	draw_rect(Rect2(at + Vector2(-12, -14), Vector2(22, 9)), white)
	draw_rect(Rect2(at + Vector2(-4, -12), Vector2(6, 4)), Color("7a6a5a"))
	for x in [-11, -7, 4, 8]:
		draw_rect(Rect2(at + Vector2(x, -5), Vector2(2, 5)), white.darkened(0.15))
	draw_rect(Rect2(at + Vector2(9, -18), Vector2(7, 6)), white)
	draw_rect(Rect2(at + Vector2(10, -21), Vector2(1, 3)), Color("5a4a3a"))
	draw_rect(Rect2(at + Vector2(14, -21), Vector2(1, 3)), Color("5a4a3a"))
	var swish := sin(_time * 3.0) * 2.0
	draw_line(at + Vector2(-12, -13), at + Vector2(-15 + swish, -5), white.darkened(0.2), 1.0)


## Tints the scene for the time of day and lights the tube light after dark.
func _draw_light() -> void:
	var minute := _service.clock.minutes()
	var tint := Color(0, 0, 0, 0)
	if minute < 450.0:
		tint = Color(1.0, 0.75, 0.5, lerpf(0.18, 0.0, (minute - 360.0) / 90.0))
	elif minute > 1050.0 and minute <= 1140.0:
		tint = Color(1.0, 0.55, 0.25, lerpf(0.0, 0.2, (minute - 1050.0) / 90.0))
	elif minute > 1140.0:
		var dark := clampf((minute - 1140.0) / 60.0, 0.0, 1.0)
		tint = Color(1.0, 0.55, 0.25, 0.2).lerp(Color(0.06, 0.08, 0.22, 0.5), dark)
	if tint.a > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), tint)
	if minute > 1080.0:
		var glow := clampf((minute - 1080.0) / 90.0, 0.0, 1.0)
		var tube := _iso(Vector2(4.0, 2.3), 56)
		for r in [70.0, 46.0, 26.0]:
			draw_circle(tube + Vector2(0, 30), r, Color(1.0, 0.98, 0.85, 0.06 * glow))
		draw_rect(Rect2(tube + Vector2(-14, 0), Vector2(28, 2)), Color(1, 1, 0.95, glow))


# --- Shape helpers --------------------------------------------------------

## A flat diamond on the ground between two tile corners.
func _quad(from: Vector2, to: Vector2, color: Color) -> void:
	_quad_up(from, to, 0.0, 0.0, color)


## A flat strip raised off the ground, from "low" up to "high" pixels.
func _quad_up(from: Vector2, to: Vector2, high: float, low: float, color: Color) -> void:
	if high > 0.0:
		draw_colored_polygon(PackedVector2Array([
			_iso(Vector2(from.x, to.y), high), _iso(to, high), _iso(to, low), _iso(Vector2(from.x, to.y), low),
		]), color)
		return
	draw_colored_polygon(PackedVector2Array([
		_iso(from), _iso(Vector2(to.x, from.y)), _iso(to), _iso(Vector2(from.x, to.y)),
	]), color)


## An isometric box: top face, front-left face and front-right face.
func _box(from: Vector2, to: Vector2, height: float, top: Color, left: Color, right: Color) -> void:
	var a := _iso(Vector2(from.x, to.y))
	var b := _iso(to)
	var c := _iso(Vector2(to.x, from.y))
	var up := Vector2(0, height)
	var d := _iso(from, height)
	draw_colored_polygon(PackedVector2Array([a, b, b - up, a - up]), left)
	draw_colored_polygon(PackedVector2Array([b, c, c - up, b - up]), right)
	draw_colored_polygon(PackedVector2Array([d, c - up, b - up, a - up]), top)
	# Dark outline and a light top edge, for a crisp pixel-art look.
	var edge := left.darkened(0.55)
	draw_polyline(PackedVector2Array([a, b, c, c - up, d, a - up, a]), edge, 1.0)
	draw_line(b, b - up, edge, 1.0)
	draw_line(a - up, b - up, top.lightened(0.25), 1.0)
	draw_line(b - up, c - up, top.lightened(0.25), 1.0)


func _text(at: Vector2, text: String, color: Color, align: HorizontalAlignment, font_size: int = Style.FONT_SIZE) -> void:
	var offset := 0.0
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		offset = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x / 2.0
	draw_string(_font, at - Vector2(offset, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
