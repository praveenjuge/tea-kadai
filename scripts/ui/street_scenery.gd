class_name StreetScenery
extends RefCounted
## The street's backdrop and props, drawn by the street view: a sky that turns
## from dawn to night, a row of Chennai shop fronts and houses, textured
## pavement with a kolam, a drain, traffic, street lamps, and sun shadows.

const BUILDING_COLORS: Array[Color] = [Color("3fb5a8"), Color("f06292"), Color("ffca3a"), Color("8ac926"),
	Color("ff924c"), Color("6a8cff"), Color("e8e4d0"), Color("c77dff")]
const SHOP_SIGNS: Array[String] = ["MEDICALS", "STORES", "TAILOR", "MOBILES", "SWEETS", "XEROX", "HOTEL", "SILKS"]
const PAVEMENT := Color("d1b892")
const PAVEMENT_LINE := Color("bfa47c")
const ROAD := Color("4d4b52")
const LAMPS: Array[float] = [-3.5, 7.5, 15.5]
## Sky colours (top, bottom) through the day, by kadai minute.
const SKY := [
	[360.0, Color("f2a07b"), Color("ffd9a8")],
	[480.0, Color("6fc3f0"), Color("c6ecff")],
	[1020.0, Color("6fc3f0"), Color("c6ecff")],
	[1110.0, Color("ff8f5a"), Color("ffd28a")],
	[1200.0, Color("2a2f5e"), Color("6a5a8a")],
	[1320.0, Color("141a3a"), Color("2a2f5e")],
]

var _view: StreetView
var _rng := RandomNumberGenerator.new()
## Vehicles on the road: {"kind", "x", "lane", "speed", "color"}.
var _traffic: Array[Dictionary] = []
var _spawn := 0.0


func _init(view: StreetView) -> void:
	_view = view
	_rng.randomize()
	_traffic.append({"kind": "auto", "x": 2.0, "lane": 6.3, "speed": 2.2, "color": Color("3a8a3a")})
	_traffic.append({"kind": "bus", "x": 14.0, "lane": 7.4, "speed": -1.5, "color": Color("d64a3a")})


func update(delta: float) -> void:
	_spawn -= delta
	if _spawn <= 0.0:
		_spawn = _rng.randf_range(2.5, 6.0)
		var roll := _rng.randf()
		var going_right := _rng.randf() < 0.5
		var kind := "auto" if roll < 0.45 else ("scooter" if roll < 0.85 else "bus")
		var speed: float = {"auto": 2.4, "scooter": 3.6, "bus": 1.6}[kind] * _rng.randf_range(0.85, 1.15)
		var colors: Array = {
			"auto": [Color("3a8a3a"), Color("2f6db5")],
			"scooter": [Color("e0604e"), Color("eef0f2"), Color("4a90d9"), Color("e8c547")],
			"bus": [Color("d64a3a"), Color("2f8a8a")],
		}[kind]
		_traffic.append({
			"kind": kind, "x": -24.0 if going_right else 26.0,
			"lane": 6.3 if going_right else 7.4, "speed": speed * (1.0 if going_right else -1.0),
			"color": colors[_rng.randi() % colors.size()],
		})
	for vehicle in _traffic:
		vehicle["x"] += float(vehicle["speed"]) * delta
	_traffic = _traffic.filter(func(v: Dictionary) -> bool: return v["x"] > -26.0 and v["x"] < 28.0)


# --- Sky and buildings ------------------------------------------------------

func draw_sky() -> void:
	var minute := _view.service().clock.minutes()
	var top := Color("6fc3f0")
	var bottom := Color("c6ecff")
	for i in SKY.size() - 1:
		var a: Array = SKY[i]
		var b: Array = SKY[i + 1]
		if minute >= a[0] and minute <= b[0]:
			var t := (minute - float(a[0])) / (float(b[0]) - float(a[0]))
			top = Color(a[1]).lerp(b[1], t)
			bottom = Color(a[2]).lerp(b[2], t)
	if minute > SKY[-1][0]:
		top = SKY[-1][1]
		bottom = SKY[-1][2]
	var size := _view.size
	# Whole-pixel bands so no seams show between them.
	var bands := 12
	var band_h := ceilf(size.y * 0.6 / bands)
	for i in bands:
		_view.draw_rect(Rect2(0, i * band_h, size.x, band_h), top.lerp(bottom, float(i) / bands))
	_view.draw_rect(Rect2(0, bands * band_h, size.x, size.y), bottom)
	if minute > 1180.0:
		var twinkle := _view.time()
		for i in 30:
			var at := Vector2(fmod(i * 97.3, size.x), fmod(i * 41.7, size.y * 0.4))
			var on := (int(twinkle * 2.0) + i) % 5 != 0
			_view.draw_rect(Rect2(at, Vector2(1, 1)), Color(1, 1, 1, 0.8 if on else 0.3))


## A row of shop fronts and houses behind the kadai, back to front.
func draw_buildings() -> void:
	var font := _view.get_theme_default_font()
	var night := _view.service().clock.minutes() > 1120.0
	var x := -20.0
	var i := 0
	var kadai_done := false
	while x < 26.0:
		# The kadai's own building takes its place in the row.
		if not kadai_done and x >= StreetView.SHOP_FROM.x - 0.01:
			_view.draw_kadai_building()
			x = StreetView.SHOP_TO.x
			kadai_done = true
			continue
		var width := 2.5 + float((i * 7) % 3) * 0.5
		if not kadai_done and x + width > StreetView.SHOP_FROM.x:
			width = StreetView.SHOP_FROM.x - x
		var height := 70.0 + float((i * 37) % 5) * 14.0
		var color := BUILDING_COLORS[(i * 5) % BUILDING_COLORS.size()]
		var from := Vector2(x, -3.6)
		var to := Vector2(x + width, -0.7)
		_view._box(from, to, height, color.lightened(0.15), color, color.darkened(0.25))
		_draw_facade(from, to, height, color, i, night, font)
		x += width
		i += 1


func _draw_facade(from: Vector2, to: Vector2, height: float, color: Color, index: int, night: bool, font: Font) -> void:
	var y := to.y
	# Windows on upper floors, lit at night.
	var floors := int((height - 30.0) / 22.0)
	for f in floors:
		var up := 34.0 + f * 22.0
		var count := int((to.x - from.x) / 0.9)
		for w in count:
			var gx := from.x + 0.45 + w * 0.9
			var at := _view._iso(Vector2(gx, y), up + 12.0)
			var lit := night and (index + f + w) % 3 != 0
			var glass := Color("ffe9a8") if lit else Color("2a3a48")
			_view.draw_colored_polygon(PackedVector2Array([at, at + Vector2(9, 4.5), at + Vector2(9, 15.5), at + Vector2(0, 11)]), glass)
			_view.draw_line(at + Vector2(0, 11), at + Vector2(9, 15.5), color.darkened(0.4), 1.0)
		var ledge_l := _view._iso(Vector2(from.x, y), up - 2.0)
		var ledge_r := _view._iso(Vector2(to.x, y), up - 2.0)
		_view.draw_line(ledge_l, ledge_r, color.darkened(0.35), 2.0)
	# A shop shutter and painted sign at street level.
	var sign_l := _view._iso(Vector2(from.x + 0.2, y), 28.0)
	var sign_r := _view._iso(Vector2(to.x - 0.2, y), 28.0)
	var sign_color: Color = [Color("c0392b"), Color("f3e3c3"), Color("2f6db5")][index % 3]
	_view.draw_colored_polygon(PackedVector2Array([sign_l, sign_r, sign_r + Vector2(0, 9), sign_l + Vector2(0, 9)]), sign_color)
	var label := SHOP_SIGNS[index % SHOP_SIGNS.size()]
	var mid := sign_l.lerp(sign_r, 0.5)
	var ink := Style.INK if sign_color == Color("f3e3c3") else Color.WHITE
	var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	_view.draw_string(font, mid + Vector2(-w / 2.0, 8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, ink)
	var shutter_l := _view._iso(Vector2(from.x + 0.3, y), 18.0)
	var shutter_r := _view._iso(Vector2(to.x - 0.3, y), 18.0)
	var shutter := PackedVector2Array([shutter_l, shutter_r, _view._iso(Vector2(to.x - 0.3, y)), _view._iso(Vector2(from.x + 0.3, y))])
	_view.draw_colored_polygon(shutter, Color("8a8f94") if not night else Color("5a5f64"))
	for s in 4:
		var t := (s + 1) / 5.0
		_view.draw_line(shutter_l.lerp(_view._iso(Vector2(from.x + 0.3, y)), t), shutter_r.lerp(_view._iso(Vector2(to.x - 0.3, y)), t),
			Color("6a6f74"), 1.0)
	if index % 4 == 1:
		# A cinema poster on this one.
		var p := _view._iso(Vector2(from.x + 0.5, y), height - 12.0)
		_view.draw_colored_polygon(PackedVector2Array([p, p + Vector2(28, 14), p + Vector2(28, 38), p + Vector2(0, 24)]), Color("e8c547"))
		_view.draw_colored_polygon(PackedVector2Array([p + Vector2(3, 4), p + Vector2(25, 15), p + Vector2(25, 34), p + Vector2(3, 23)]), Color("c0392b"))


# --- Ground -----------------------------------------------------------------

func draw_ground() -> void:
	_view._quad(Vector2(-30, -0.7), Vector2(30, 30), PAVEMENT)
	# Pavement slabs.
	for gy in range(0, 6):
		_view.draw_line(_view._iso(Vector2(-30, gy - 0.5)), _view._iso(Vector2(30, gy - 0.5)), PAVEMENT_LINE, 1.0)
	for gx in range(-30, 30, 2):
		_view.draw_line(_view._iso(Vector2(gx, -0.7)), _view._iso(Vector2(gx, 5.4)), PAVEMENT_LINE, 1.0)
	# A few cracks.
	for crack in [Vector2(-2.3, 2.1), Vector2(8.6, 3.4), Vector2(11.2, 1.2)]:
		var a := _view._iso(crack)
		_view.draw_polyline(PackedVector2Array([a, a + Vector2(4, 2), a + Vector2(6, 1), a + Vector2(10, 4)]), PAVEMENT_LINE.darkened(0.15), 1.0)
	ChennaiBits.draw_kolam(_view, Vector2(4.0, 2.6), _view.service().state.day)
	# Kerb, drain with grates, road, and lane markings.
	_view._quad(Vector2(-30, 5.4), Vector2(30, 5.65), Color("8c8273"))
	_view._quad(Vector2(-30, 5.65), Vector2(30, 5.8), Color("3a3634"))
	for gx in range(-30, 30, 3):
		_view._quad(Vector2(gx, 5.66), Vector2(gx + 0.6, 5.79), Color("5a5654"))
	_view._quad(Vector2(-30, 5.8), Vector2(30, 8.8), ROAD)
	var dash := -30.0
	while dash < 30.0:
		_view._quad(Vector2(dash, 7.05), Vector2(dash + 0.8, 7.15), Color("e8e2cc"))
		dash += 2.0
	var manhole := _view._iso(Vector2(3.0, 7.9))
	_view.draw_colored_polygon(_ellipse(manhole, 9.0, 4.5), Color("3a383d"))
	_view.draw_arc(manhole, 6.0, 0.0, TAU, 12, Color("5a585d"), 1.0)


# --- Light and shadow -------------------------------------------------------

## Screen offset of a shadow cast by something "height" pixels tall, from the
## sun's position: long and to the right in the morning, long to the left in
## the evening, short at noon.
func shadow_offset(height: float) -> Vector2:
	var minute := _view.service().clock.minutes()
	var t := clampf((minute - 360.0) / 780.0, 0.0, 1.0)
	var length := 0.25 + absf(t - 0.5) * 1.4
	return Vector2(lerpf(1.0, -1.0, t), 0.3) * height * length


func sun_up() -> bool:
	var minute := _view.service().clock.minutes()
	return minute >= 380.0 and minute <= 1130.0


func draw_shadows() -> void:
	if not sun_up() or _view.service().is_raining():
		return
	var shade := Color(0.2, 0.12, 0.05, 0.22)
	var offset := shadow_offset(30.0)
	var footprint := [_view._iso(StreetView.COUNTER_FROM), _view._iso(Vector2(StreetView.COUNTER_TO.x, StreetView.COUNTER_FROM.y)),
		_view._iso(StreetView.COUNTER_TO), _view._iso(Vector2(StreetView.COUNTER_FROM.x, StreetView.COUNTER_TO.y))]
	var cast := PackedVector2Array([footprint[2], footprint[3], footprint[3] + offset, footprint[2] + offset])
	_view.draw_colored_polygon(cast, shade)
	var tree := _view._iso(Vector2(-0.6, 3.6))
	_view.draw_colored_polygon(_ellipse(tree + shadow_offset(50.0) * 0.6, 22.0, 8.0), shade)


func draw_lamps(pole: bool) -> void:
	var minute := _view.service().clock.minutes()
	var on := minute > 1090.0
	for gx in LAMPS:
		var base := _view._iso(Vector2(gx, 5.3))
		var head := base + Vector2(0, -64)
		if pole:
			_view.draw_rect(Rect2(base + Vector2(-1, -64), Vector2(2, 64)), Color("4a4a50"))
			_view.draw_line(head, head + Vector2(10, 2), Color("4a4a50"), 2.0)
			_view.draw_rect(Rect2(head + Vector2(8, 1), Vector2(6, 3)), Color("fff3c8") if on else Color("8a8f94"))
		elif on:
			var glow := clampf((minute - 1090.0) / 40.0, 0.0, 1.0)
			_view.draw_colored_polygon(_ellipse(base + Vector2(10, 0), 30.0, 12.0), Color(1.0, 0.92, 0.6, 0.18 * glow))
			for r in [26.0, 16.0, 8.0]:
				_view.draw_circle(head + Vector2(11, 3), r, Color(1.0, 0.95, 0.75, 0.08 * glow))


# --- Traffic ----------------------------------------------------------------

func draw_traffic() -> void:
	var sorted := _traffic.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["lane"] < b["lane"])
	for vehicle in sorted:
		var tile := Vector2(vehicle["x"], vehicle["lane"])
		match vehicle["kind"]:
			"auto":
				_draw_auto(tile, vehicle["color"])
			"bus":
				_draw_bus(tile, vehicle["color"])
			"scooter":
				_draw_scooter(tile, vehicle)


func _draw_auto(tile: Vector2, body: Color) -> void:
	_view.draw_colored_polygon(_ellipse(_view._iso(tile + Vector2(0.65, 0.35)), 20.0, 6.0), Color(0, 0, 0, 0.25))
	for wheel in [Vector2(0.15, 0.1), Vector2(0.15, 0.6), Vector2(1.15, 0.35)]:
		_view.draw_circle(_view._iso(tile + wheel, 2.0), 2.5, Color("1a1a1a"))
	_view._box(tile, tile + Vector2(1.3, 0.7), 9, body.lightened(0.1), body, body.darkened(0.25))
	for post in [Vector2(0.15, 0.7), Vector2(1.15, 0.7), Vector2(1.15, 0.05)]:
		var bottom := _view._iso(tile + post, 9.0)
		_view.draw_line(bottom, bottom + Vector2(0, -9), Color("1a1a1a"), 1.0)
	var yellow := Color("ffca3a")
	_view._box(tile + Vector2(0.05, 0.0), tile + Vector2(1.25, 0.7), 4, yellow, Color("1a1a1a"), Color("1a1a1a"))
	var roof_up := 18.0
	_view.draw_colored_polygon(PackedVector2Array([_view._iso(tile, roof_up + 4.0), _view._iso(tile + Vector2(1.3, 0.0), roof_up + 4.0),
		_view._iso(tile + Vector2(1.3, 0.7), roof_up + 4.0), _view._iso(tile + Vector2(0.0, 0.7), roof_up + 4.0)]), yellow)
	_view.draw_rect(Rect2(_view._iso(tile + Vector2(1.3, 0.3), 6.0), Vector2(2, 2)), Color("fff3a8"))


func _draw_bus(tile: Vector2, body: Color) -> void:
	_view.draw_colored_polygon(_ellipse(_view._iso(tile + Vector2(1.8, 0.45)), 46.0, 9.0), Color(0, 0, 0, 0.25))
	for wheel in [Vector2(0.5, 0.9), Vector2(3.0, 0.9)]:
		_view.draw_circle(_view._iso(tile + wheel, 2.0), 3.5, Color("1a1a1a"))
	_view._box(tile, tile + Vector2(3.6, 0.9), 28, Color("eef0f2"), body, body.darkened(0.25))
	# White stripe and a row of windows along the side facing us.
	var stripe := [_view._iso(tile + Vector2(0, 0.9), 12.0), _view._iso(tile + Vector2(3.6, 0.9), 12.0)]
	_view.draw_line(stripe[0], stripe[1], Color("eef0f2"), 2.0)
	for w in 6:
		var at := _view._iso(tile + Vector2(0.25 + w * 0.55, 0.9), 25.0)
		_view.draw_colored_polygon(PackedVector2Array([at, at + Vector2(8, 4), at + Vector2(8, 12), at + Vector2(0, 8)]), Color("2a3a48"))
	var front := _view._iso(tile + Vector2(3.6, 0.15), 25.0)
	_view.draw_colored_polygon(PackedVector2Array([front, front + Vector2(-8, 4), front + Vector2(-8, 12), front + Vector2(0, 8)]), Color("6a9ab8"))


func _draw_scooter(tile: Vector2, vehicle: Dictionary) -> void:
	var feet := _view._iso(tile).round()
	var facing := signf(float(vehicle["speed"]))
	var body: Color = vehicle["color"]
	_view.draw_colored_polygon(_ellipse(feet + Vector2(0, 1), 9.0, 3.0), Color(0, 0, 0, 0.25))
	for wheel in [-5.0, 5.0]:
		_view.draw_circle(feet + Vector2(wheel * facing, -2), 2.5, Color("1a1a1a"))
	_view.draw_rect(Rect2(feet + Vector2(-6, -7), Vector2(12, 4)), body)
	_view.draw_rect(Rect2(feet + Vector2(4 * facing - 1, -12), Vector2(2, 6)), body.darkened(0.3))
	var rider := {"shirt": body.darkened(0.2), "legs": Color("2d3a5a"), "hair": Color("1e1612"),
		"skin": Color("8d5a3b"), "hat": Color("eef0f2")}
	_view.draw_figure(rider, feet + Vector2(-1 * facing, -6), false, 1.0, 0.65)


static func _ellipse(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		points.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return points
