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
## The fifth spot, at the bench, opens with the bench upgrade.
const SEAT_TILES: Array[Vector2] = [Vector2(1.9, 2.9), Vector2(3.4, 2.9), Vector2(4.9, 2.9), Vector2(6.4, 2.9), Vector2(7.9, 2.9)]
## The edge of the road that customers walk in from and leave to.
const ROAD_EDGE_Y := 6.6
const WALK_SECONDS := 0.7
const LEAVE_SECONDS := 1.6

const WALL := Color("6aa39a")
const PAVEMENT := Color("b9a58a")
const ROAD := Color("4b4a4f")
const WOOD := Color("9a6a3c")
const STALL_PAINT := Color("2f7fb5")
const TARP := Color("3b6fc4")

var _service: Service
var _time := 0.0
## Walk-in progress per seat, 0 to 1.
var _arrive: Array[float] = []
## Customers on their way out: {"type", "tile", "t", "text", "color"}.
var _leavers: Array[Dictionary] = []
var _origin := Vector2.ZERO
var _font: Font
var _speech: SpeechBubbles
var _life: StreetLife


func _init(service: Service) -> void:
	_service = service
	for i in service.seats.size():
		_arrive.append(1.0)
	clip_contents = true
	_speech = SpeechBubbles.new(self)
	_life = StreetLife.new(self)


func _ready() -> void:
	_font = get_theme_default_font()


func on_arrived(seat: int) -> void:
	_arrive[seat] = 0.0


func say(seat: int, text: String) -> void:
	_speech.say(seat, text)


func ask(seat: int, question: String, options: Array) -> void:
	_speech.ask(seat, question, options)


## Where a seated customer's head is, in this view's coordinates.
func seat_point(seat: int) -> Vector2:
	return _iso(SEAT_TILES[seat], 22.0)


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
	elif outcome == "out_of_stock":
		text = "Nothing left? Okay…"
		color = Style.MUTED
	_leavers.append({"type": customer["type"], "tile": SEAT_TILES[seat], "t": 0.0, "text": text, "color": color})


func _process(delta: float) -> void:
	_time += delta
	for i in _arrive.size():
		_arrive[i] = minf(1.0, _arrive[i] + delta / WALK_SECONDS)
	for leaver in _leavers:
		leaver["t"] += delta
	_leavers = _leavers.filter(func(l: Dictionary) -> bool: return l["t"] < LEAVE_SECONDS)
	_speech.update(delta)
	_life.update(delta)
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
		var body := Rect2(feet + Vector2(-10, -32), Vector2(20, 34))
		if body.has_point(point) or _bubble_box(seat, items).grow(2.0).has_point(point):
			return seat
	return -1


func _iso(tile: Vector2, up: float = 0.0) -> Vector2:
	return _origin + Vector2((tile.x - tile.y) * HALF_W, (tile.x + tile.y) * HALF_H - up)


# --- Drawing --------------------------------------------------------------

func _draw() -> void:
	_origin = Vector2(roundf(size.x * 0.5 - 60.0), roundf(size.y * 0.5 - 28.0))
	_draw_ground()
	_draw_stall()
	_draw_tree(Vector2(-0.6, 3.6))
	if _service.state.has_upgrade("bench"):
		_box(Vector2(7.1, 2.3), Vector2(8.7, 2.7), 9, WOOD.lightened(0.1), WOOD.darkened(0.1), WOOD.darkened(0.3))
	_draw_cow(Vector2(9.4, 3.9))
	for seat in _service.seats.size():
		var customer = _service.seats[seat]
		if customer != null:
			draw_person(customer["type"], _walk_tile(seat), _arrive[seat] < 1.0, 1.0)
	for leaver in _leavers:
		var t: float = leaver["t"] / LEAVE_SECONDS
		var from: Vector2 = leaver["tile"]
		var tile := from.lerp(Vector2(from.x + 1.5, ROAD_EDGE_Y + 0.6), t)
		draw_person(leaver["type"], tile, true, 1.0 - t)
	_life.draw_passers_by()
	_draw_traffic()
	_life.draw_rain()
	_draw_light()
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


func _draw_ground() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), WALL)
	var poster := [_iso(Vector2(8.5, -0.5), 66), _iso(Vector2(11.5, -0.5), 66), _iso(Vector2(11.5, -0.5), 26), _iso(Vector2(8.5, -0.5), 26)]
	draw_colored_polygon(PackedVector2Array(poster), Color("e8c547"))
	draw_colored_polygon(PackedVector2Array([poster[0] + Vector2(4, 6), poster[1] + Vector2(-4, 6), poster[2] + Vector2(-4, -4), poster[3] + Vector2(4, -4)]), Color("c0392b"))
	_text(_iso(Vector2(10.0, -0.5), 42), "CINEMA", Style.FROTH, HORIZONTAL_ALIGNMENT_CENTER)
	_quad(Vector2(-30, -0.5), Vector2(30, 30), PAVEMENT)
	_quad(Vector2(-30, 5.6), Vector2(30, 8.6), ROAD)
	_quad(Vector2(-30, 5.4), Vector2(30, 5.6), Color("8c8273"))
	var dash := -30.0
	while dash < 30.0:
		_quad(Vector2(dash, 7.05), Vector2(dash + 0.8, 7.15), Color("d8d3c4"))
		dash += 2.0


func _draw_stall() -> void:
	_box(Vector2(1.4, -0.3), Vector2(6.6, 0.0), 66, STALL_PAINT.lightened(0.1), STALL_PAINT, STALL_PAINT.darkened(0.2))
	# Shelf with snack packets and jars on the back wall.
	var shelf_l := _iso(Vector2(1.6, 0.0), 34)
	var shelf_r := _iso(Vector2(6.4, 0.0), 34)
	draw_line(shelf_l, shelf_r, WOOD.darkened(0.3), 2.0)
	var packet_colors := [Color("e0604e"), Color("e8c547"), Color("7cc46a"), Color("d9a55b")]
	for i in 9:
		var at := shelf_l.lerp(shelf_r, (i + 0.5) / 9.0)
		draw_rect(Rect2(at + Vector2(-3, -9), Vector2(6, 8)), packet_colors[i % packet_colors.size()])
	for i in 4:
		var hang := _iso(Vector2(2.0 + i * 1.3, 0.0), 58)
		draw_line(hang, hang + Vector2(0, 8), Color("ded4bf"), 1.0)
		draw_rect(Rect2(hang + Vector2(-3, 8), Vector2(6, 9)), packet_colors[(i + 1) % packet_colors.size()].lightened(0.2))

	# Pillars, counter, and the roof.
	for corner in [Vector2(1.4, 0.0), Vector2(6.6, 0.0)]:
		_box(corner + Vector2(0, 0.0), corner + Vector2(0.15, 0.15), 66, WOOD, WOOD.darkened(0.2), WOOD.darkened(0.35))
	_box(Vector2(1.4, 1.2), Vector2(6.6, 2.0), 20, WOOD.lightened(0.15), WOOD, WOOD.darkened(0.25))
	_quad_up(Vector2(1.4, 1.95), Vector2(6.6, 2.0), 14, 6, Color("e8c547"))
	for corner in [Vector2(1.4, 1.9), Vector2(6.45, 1.9)]:
		_box(corner, corner + Vector2(0.15, 0.15), 60, WOOD, WOOD.darkened(0.2), WOOD.darkened(0.35))
	_draw_counter_things()
	# A tarp awning over the front, so the shelf behind stays visible.
	var roof := [_iso(Vector2(1.1, 1.1), 66), _iso(Vector2(6.9, 1.1), 66), _iso(Vector2(6.9, 2.5), 58), _iso(Vector2(1.1, 2.5), 58)]
	draw_colored_polygon(PackedVector2Array(roof), TARP)
	for i in range(1, 8):
		var t := i / 8.0
		draw_line(roof[0].lerp(roof[1], t), roof[3].lerp(roof[2], t), TARP.darkened(0.2), 1.0)
	draw_line(roof[3], roof[2], TARP.darkened(0.4), 2.0)
	# Bananas hanging under the awning's front edge.
	var hook := _iso(Vector2(1.7, 2.4), 56)
	draw_line(hook, hook + Vector2(0, 4), Color("ded4bf"), 1.0)
	for i in 5:
		draw_rect(Rect2(hook + Vector2(-5 + i * 2, 4 + (i % 2) * 2), Vector2(2, 8)), Color("e8d23c"))
	# Sign board on top of the back wall.
	var sign_at := _iso(Vector2(4.0, -0.15), 80)
	if _service.state.has_upgrade("sign"):
		var lit := _service.clock.minutes() > 1050.0
		for i in 12:
			var bulb := sign_at + Vector2(-36 + i * 6.5, -12)
			var on := lit and (int(_time * 4.0) + i) % 3 != 0
			draw_rect(Rect2(bulb, Vector2(2, 2)), Color("fff3a8") if on else Color("8a7a4a"))
			draw_rect(Rect2(bulb + Vector2(0, 16), Vector2(2, 2)), Color("fff3a8") if on else Color("8a7a4a"))
		if lit:
			draw_circle(sign_at + Vector2(0, -4), 44.0, Color(1.0, 0.95, 0.6, 0.12))
	draw_rect(Rect2(sign_at + Vector2(-34, -10), Vector2(68, 13)), Color("e8c547"))
	draw_rect(Rect2(sign_at + Vector2(-34, -10), Vector2(68, 13)), Color("b5321f"), false, 1.0)
	_text(sign_at + Vector2(0, 0), "TEA KADAI", Color("b5321f"), HORIZONTAL_ALIGNMENT_CENTER)


func _draw_counter_things() -> void:
	# Biscuit jars on the left of the counter.
	var biscuits := _service.state.how_many("biscuit")
	for i in 2:
		var jar := _iso(Vector2(1.8 + i * 0.5, 1.55), 20)
		draw_rect(Rect2(jar + Vector2(-4, -12), Vector2(8, 12)), Color(0.9, 0.95, 1.0, 0.45))
		var fill := clampi(biscuits - i * 10, 0, 10)
		if fill > 0:
			draw_rect(Rect2(jar + Vector2(-3, -fill), Vector2(6, fill)), Color("d9a55b"))
		draw_rect(Rect2(jar + Vector2(-4, -14), Vector2(8, 2)), Color("e0604e"))
	# Ready tea glasses along the middle of the counter, vadai piled on a plate.
	var glass := 0
	for kind in Catalog.GLASSES:
		for quality in _service.ready[kind]:
			Style.draw_item(self, kind, _iso(Vector2(2.7 + glass * 0.36, 1.6), 26), quality)
			glass += 1
	var vadai: Array = _service.ready["vadai"]
	if not vadai.is_empty():
		var plate := _iso(Vector2(5.0, 1.6), 21)
		draw_rect(Rect2(plate + Vector2(-9, -1), Vector2(18, 3)), Color("d8dde3"))
		for i in vadai.size():
			Style.draw_item(self, "vadai", plate + Vector2(-5 + (i % 3) * 5, -4 - (i / 3) * 4), vadai[i])
	# Stove and milk pot with steam on the right. The upgrade is a bigger pot.
	var stove := _iso(Vector2(5.9, 1.6), 20)
	var pot := 1.4 if _service.state.has_upgrade("pot") else 1.0
	draw_rect(Rect2(stove + Vector2(-9, -4), Vector2(18, 4)), Color("2b2b2b"))
	draw_rect(Rect2(stove + Vector2(-8, -20) * pot, Vector2(16, 16) * pot), Color("b8863b"))
	draw_rect(Rect2(stove + Vector2(-9 * pot, -20 * pot - 2), Vector2(18 * pot, 3)), Color("d9a55b"))
	if _service.state.has_upgrade("fan"):
		var fan := _iso(Vector2(2.6, 0.2), 40)
		draw_rect(Rect2(fan + Vector2(-1, 0), Vector2(2, 10)), Color("4a4a4a"))
		draw_circle(fan, 7.0, Color(0.85, 0.88, 0.92, 0.35))
		for i in 3:
			var a := _time * 18.0 + i * TAU / 3.0
			draw_line(fan, fan + Vector2(cos(a), sin(a) * 0.6) * 7.0, Color("dfe5ea"), 2.0)
		draw_circle(fan, 1.5, Color("4a4a4a"))
	for i in 3:
		var x := stove.x - 5 + i * 5 + sin(_time * 2.5 + i) * 2.0
		var y := stove.y - 26 - fmod(_time * 10.0 + i * 5.0, 16.0)
		draw_rect(Rect2(x, y, 1, 3), Color(1, 1, 1, 0.45))


func draw_person(type_id: String, tile: Vector2, walking: bool, alpha: float) -> void:
	draw_figure(Service.kind_of(type_id), _iso(tile).round(), walking, alpha)


## A little person standing on "feet". "look" needs shirt, legs and hair
## colours; a "bag" colour adds a backpack.
func draw_figure(look: Dictionary, feet: Vector2, walking: bool, alpha: float, scale: float = 1.0) -> void:
	var kind := look
	draw_set_transform(feet, 0.0, Vector2(scale, scale))
	feet = Vector2.ZERO
	var bob := absf(sin(_time * 12.0)) * 1.5 if walking else 0.0
	var shirt: Color = kind["shirt"]
	var legs: Color = kind["legs"]
	var hair: Color = kind["hair"]
	draw_rect(Rect2(feet + Vector2(-5, -2), Vector2(10, 2)), Color(0, 0, 0, 0.2 * alpha))
	draw_rect(Rect2(feet + Vector2(-3, -9 - bob), Vector2(6, 9)), Color(legs, alpha))
	draw_rect(Rect2(feet + Vector2(-4, -19 - bob), Vector2(8, 11)), Color(shirt, alpha))
	draw_rect(Rect2(feet + Vector2(-5, -18 - bob), Vector2(1, 7)), Color(Style.SKIN, alpha))
	draw_rect(Rect2(feet + Vector2(4, -18 - bob), Vector2(1, 7)), Color(Style.SKIN, alpha))
	draw_rect(Rect2(feet + Vector2(-3, -26 - bob), Vector2(6, 7)), Color(Style.SKIN, alpha))
	draw_rect(Rect2(feet + Vector2(-3, -27 - bob), Vector2(6, 5)), Color(hair, alpha))
	if kind.has("bag"):
		draw_rect(Rect2(feet + Vector2(-5, -18 - bob), Vector2(10, 7)), Color(kind["bag"], alpha))
		draw_rect(Rect2(feet + Vector2(-3, -25 - bob), Vector2(6, 1)), Color(0.1, 0.1, 0.1, alpha))
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
	draw_line(Vector2(feet.x, box.end.y), feet + Vector2(0, -30), Style.TEXT, 1.0)
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
	return Rect2(feet + Vector2(-width / 2.0, -60.0 - lift), Vector2(width, 26))


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


func _draw_traffic() -> void:
	var lane := fmod(_time * 2.2, 44.0) - 22.0
	var auto_tile := Vector2(lane, 6.3)
	_box(auto_tile, auto_tile + Vector2(1.3, 0.7), 8, Color("2a2a2a"), Color("1e1e1e"), Color("151515"))
	_box(auto_tile + Vector2(0.1, 0.05), auto_tile + Vector2(1.2, 0.65), 16, Color("e8c547"), Color("3a8a3a"), Color("2e6e2e"))
	var bus := 22.0 - fmod(_time * 1.5 + 18.0, 44.0)
	var bus_tile := Vector2(bus, 7.4)
	_box(bus_tile, bus_tile + Vector2(3.2, 0.9), 24, Color("d64a3a"), Color("b5321f"), Color("8f2718"))


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
	draw_colored_polygon(PackedVector2Array([a, b, b - up, a - up]), left)
	draw_colored_polygon(PackedVector2Array([b, c, c - up, b - up]), right)
	draw_colored_polygon(PackedVector2Array([_iso(from, height), c - up, b - up, a - up]), top)


func _text(at: Vector2, text: String, color: Color, align: HorizontalAlignment, font_size: int = Style.FONT_SIZE) -> void:
	var offset := 0.0
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		offset = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x / 2.0
	draw_string(_font, at - Vector2(offset, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
