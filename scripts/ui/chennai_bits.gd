class_name ChennaiBits
extends RefCounted
## Chennai on the street outside the kadai: a new kolam every morning (bigger
## on Sundays, festivals and in Margazhi), a wall of film posters with a giant
## star cutout on release Fridays, the auto stand, and festival touches like
## Karthigai lamps and Pongal sugarcane. Drawn onto the StreetView.

const POSTER_WALL := [Vector2(-5.4, -0.25), Vector2(-2.6, -0.25)]
const WALL_HEIGHT := 22.0
const CUTOUT := Vector2(0.2, 0.3)
## Autos parked at the kerb, their drivers chatting on the pavement.
const AUTOS: Array[Vector2] = [Vector2(-5.6, 6.2), Vector2(-4.3, 6.2)]
const DRIVERS: Array[Vector2] = [Vector2(-4.6, 5.0), Vector2(-5.4, 4.9)]
const STAND_SIGN := Vector2(-6.3, 5.2)
const AUTO_YELLOW := Color("f2c230")
const WHITE := Color(1, 1, 1, 0.9)


## Today's kolam, different every day.
static func draw_kolam(view: StreetView, center: Vector2, day: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = day * 7919
	var scale := Chennai.kolam_size(day)
	var colors: Array = Chennai.KOLAM_PALETTES[rng.randi() % Chennai.KOLAM_PALETTES.size()]
	var style: String = Chennai.KOLAM_STYLES[rng.randi() % Chennai.KOLAM_STYLES.size()]
	match style:
		"dots":
			_kolam_dots(view, center, scale, colors)
		"star":
			_kolam_star(view, center, scale, colors, 5 + rng.randi() % 4)
		"lotus":
			_kolam_lotus(view, center, scale, colors)
		_:
			_kolam_petals(view, center, scale, colors, 8 + (rng.randi() % 3) * 2)
	# A rice-flour outline around every kolam.
	var outline := PackedVector2Array()
	for i in 33:
		var a := TAU * i / 32.0
		var wobble := (1.05 + 0.12 * sin(a * 6.0)) * scale
		outline.append(view._iso(center + Vector2(cos(a), sin(a)) * wobble))
	view.draw_polyline(outline, WHITE, 1.0)


static func _kolam_petals(view: StreetView, center: Vector2, scale: float, colors: Array, petals: int) -> void:
	_dot_grid(view, center, 2, 0.3 * scale)
	for ring in 2:
		var r := (0.45 + ring * 0.35) * scale
		var count := petals + ring * 4
		for i in count:
			var a := TAU * i / count + ring * 0.2
			var at := view._iso(center + Vector2(cos(a), sin(a)) * r)
			view.draw_colored_polygon(StreetScenery._ellipse(at, 3.0 * scale, 1.6 * scale), colors[(i + ring) % colors.size()])


## Sikku style: a grid of dots with loops drawn around them.
static func _kolam_dots(view: StreetView, center: Vector2, scale: float, colors: Array) -> void:
	var step := 0.28 * scale
	for ix in range(-2, 3):
		for iy in range(-2, 3):
			if absi(ix) + absi(iy) > 3:
				continue
			var at := center + Vector2(ix, iy) * step
			var ring := PackedVector2Array()
			for i in 9:
				var a := TAU * i / 8.0
				ring.append(view._iso(at + Vector2(cos(a), sin(a)) * step * 0.5))
			view.draw_polyline(ring, colors[(absi(ix) + absi(iy)) % colors.size()], 1.0)
			view.draw_rect(Rect2(view._iso(at), Vector2(1, 1)), WHITE)


static func _kolam_star(view: StreetView, center: Vector2, scale: float, colors: Array, points: int) -> void:
	for layer in 3:
		var outer := (0.95 - layer * 0.28) * scale
		var inner := outer * 0.45
		var shape := PackedVector2Array()
		for i in points * 2:
			var a := TAU * i / (points * 2) + layer * 0.3
			var r := outer if i % 2 == 0 else inner
			shape.append(view._iso(center + Vector2(cos(a), sin(a)) * r))
		view.draw_colored_polygon(shape, colors[layer % colors.size()])
	view.draw_circle(view._iso(center), 2.0 * scale, WHITE)


static func _kolam_lotus(view: StreetView, center: Vector2, scale: float, colors: Array) -> void:
	for layer in 2:
		var petals := 6 + layer * 2
		for i in petals:
			var a := TAU * i / petals + layer * 0.4
			var tip := center + Vector2(cos(a), sin(a)) * (0.9 - layer * 0.35) * scale
			var left := center + Vector2(cos(a - 0.35), sin(a - 0.35)) * 0.3 * scale
			var right := center + Vector2(cos(a + 0.35), sin(a + 0.35)) * 0.3 * scale
			view.draw_colored_polygon(PackedVector2Array([view._iso(left), view._iso(tip), view._iso(right)]),
				colors[(i + layer) % colors.size()])
	view.draw_colored_polygon(StreetScenery._ellipse(view._iso(center), 4.0 * scale, 2.0 * scale), colors[3])


static func _dot_grid(view: StreetView, center: Vector2, reach: int, step: float) -> void:
	for ix in range(-reach, reach + 1):
		for iy in range(-reach, reach + 1):
			if absi(ix) + absi(iy) <= reach:
				view.draw_rect(Rect2(view._iso(center + Vector2(ix, iy) * step), Vector2(1, 1)), WHITE)


# --- Posters, cutout and the auto stand --------------------------------------

## The wall of film posters, behind everything else on the pavement.
static func draw_poster_wall(view: StreetView, day: int) -> void:
	var from: Vector2 = POSTER_WALL[0]
	var to: Vector2 = POSTER_WALL[1]
	view._box(from - Vector2(0, 0.15), to, WALL_HEIGHT, Color("d8cfc0"), Color("b9ae9c"), Color("c9bfae"))
	var showing := Chennai.film(day)
	var older := Chennai.FILMS[(Chennai.FILMS.find(showing) + Chennai.FILMS.size() - 1) % Chennai.FILMS.size()]
	var films := [older, showing, showing]
	var width := (to.x - from.x) / 3.0
	for i in 3:
		var x0 := from.x + i * width + 0.1
		var x1 := x0 + width - 0.2
		var color: Color = films[i]["color"]
		var y := from.y - 0.16
		var torn := i == 0
		var poster := PackedVector2Array([view._iso(Vector2(x0, y), WALL_HEIGHT - 2), view._iso(Vector2(x1, y), WALL_HEIGHT - 2),
			view._iso(Vector2(x1, y), 3 if not torn else 7), view._iso(Vector2(x0, y), 3)])
		view.draw_colored_polygon(poster, color.darkened(0.25) if torn else color)
		# A face in sunglasses, and a title strip.
		var face := view._iso(Vector2((x0 + x1) / 2.0, y), WALL_HEIGHT - 7)
		view.draw_rect(Rect2(face + Vector2(-2, -2), Vector2(4, 4)), Color("c48a5a"))
		view.draw_rect(Rect2(face + Vector2(-2, -1), Vector2(4, 1)), Color("111111"))
		var strip := PackedVector2Array([view._iso(Vector2(x0, y), 7), view._iso(Vector2(x1, y), 7),
			view._iso(Vector2(x1, y), 5), view._iso(Vector2(x0, y), 5)])
		view.draw_colored_polygon(strip, Color("f6e08a"))


## On release Fridays, a giant cutout of the star, garlanded by fans.
static func draw_cutout(view: StreetView, day: int, time: float) -> void:
	if not Chennai.is_release_day(day):
		return
	var showing := Chennai.film(day)
	var feet := view._iso(CUTOUT)
	var color: Color = showing["color"]
	# Scaffolding behind, then the flat figure.
	view.draw_line(feet + Vector2(-8, 0), feet + Vector2(-8, -70), Color("6b4a2c"), 1.0)
	view.draw_line(feet + Vector2(8, 0), feet + Vector2(8, -70), Color("6b4a2c"), 1.0)
	view.draw_rect(Rect2(feet + Vector2(-7, -34), Vector2(14, 30)), color)
	view.draw_rect(Rect2(feet + Vector2(-6, -6), Vector2(4, 6)), Color("222222"))
	view.draw_rect(Rect2(feet + Vector2(2, -6), Vector2(4, 6)), Color("222222"))
	view.draw_rect(Rect2(feet + Vector2(-11, -32), Vector2(4, 16)), color.darkened(0.2))
	# One arm up, waving to the fans.
	var wave := sin(time * 2.0) * 1.5
	view.draw_rect(Rect2(feet + Vector2(7, -48 + wave), Vector2(4, 16)), color.darkened(0.2))
	view.draw_rect(Rect2(feet + Vector2(-6, -48), Vector2(12, 14)), Color("c48a5a"))
	view.draw_rect(Rect2(feet + Vector2(-6, -50), Vector2(12, 4)), Color("1e1612"))
	view.draw_rect(Rect2(feet + Vector2(-6, -44), Vector2(12, 3)), Color("111111"))
	# The garland: a loop of marigold dots.
	for i in 12:
		var a := PI * i / 11.0
		var at := feet + Vector2(cos(a) * 7.0, -34 + sin(a) * 9.0)
		view.draw_rect(Rect2(at, Vector2(2, 2)), Color("f39c12") if i % 2 == 0 else Color("e74c3c"))
	view._text(feet + Vector2(0, -56), showing["title"], Color("f6e08a"), HORIZONTAL_ALIGNMENT_CENTER, 8)


static func draw_auto_stand(view: StreetView, scenery: StreetScenery) -> void:
	var sign := view._iso(STAND_SIGN)
	view.draw_line(sign, sign + Vector2(0, -26), Color("5a5654"), 1.0)
	view.draw_rect(Rect2(sign + Vector2(-14, -34), Vector2(28, 9)), Color("2f6db5"))
	view._text(sign + Vector2(0, -26), "AUTO STAND", Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 6)
	for tile in AUTOS:
		scenery._draw_auto(tile, AUTO_YELLOW)
	for i in DRIVERS.size():
		view.draw_person("auto_driver", DRIVERS[i], false, 1.0, "wave" if i == 0 and int(view.time()) % 9 == 0 else "")


## The kadai gets grander with each big-number milestone: bunting, a gold
## frame on the sign, a rooftop billboard, sweeping spotlights, a red carpet,
## and fireworks over the street.
static func draw_grandeur(view: StreetView, level: int, time: float) -> void:
	if level <= 0:
		return
	var x0 := StreetView.SHOP_FROM.x
	var x1 := StreetView.SHOP_TO.x
	var front := StreetView.SHOP_TO.y
	var flag_colors := [Color("e0604e"), Color("e8c547"), Color("7cc46a"), Color("4a90d9")]
	# Bunting across the front.
	var flags := 14
	for i in flags:
		var t := float(i) / flags
		var sag := sin(t * PI) * 6.0
		var at := view._iso(Vector2(lerpf(x0, x1, t), front), StreetView.SHOP_HEIGHT - 6 - sag)
		var flutter := sin(time * 4.0 + i) * 0.8
		view.draw_colored_polygon(PackedVector2Array([at, at + Vector2(5, 2.5), at + Vector2(1.5 + flutter, 7)]), flag_colors[i % 4])
	var sign_at := view._iso(Vector2((x0 + x1) / 2.0, front), StreetView.SHOP_OPENING + 34)
	if level >= 2:
		view.draw_rect(Rect2(sign_at + Vector2(-39, -14), Vector2(78, 21)), Color("f2c14e"), false, 2.0)
		for corner in [Vector2(-40, -15), Vector2(36, -15), Vector2(-40, 5), Vector2(36, 5)]:
			view.draw_rect(Rect2(sign_at + corner, Vector2(4, 4)), Color("fff1c4"))
	if level >= 3:
		var roof := view._iso(Vector2((x0 + x1) / 2.0, (StreetView.SHOP_FROM.y + front) / 2.0), StreetView.SHOP_HEIGHT)
		view.draw_line(roof + Vector2(-14, 0), roof + Vector2(-14, -14), Color("4a4a4a"), 1.0)
		view.draw_line(roof + Vector2(14, 0), roof + Vector2(14, -14), Color("4a4a4a"), 1.0)
		view.draw_rect(Rect2(roof + Vector2(-30, -34), Vector2(60, 20)), Color("b5321f"))
		view.draw_rect(Rect2(roof + Vector2(-30, -34), Vector2(60, 20)), Color("f2c14e"), false, 1.0)
		view._text(roof + Vector2(0, -26), "No.1 TEA", Color("fff1c4"), HORIZONTAL_ALIGNMENT_CENTER, 8)
		view._text(roof + Vector2(0, -17), "IN CHENNAI", Color("f2c14e"), HORIZONTAL_ALIGNMENT_CENTER, 6)
	if level >= 4:
		var top := view._iso(Vector2(x0, StreetView.SHOP_FROM.y), StreetView.SHOP_HEIGHT)
		for i in 2:
			var angle := -PI / 2.0 + sin(time * 0.6 + i * 2.0) * 0.6
			var base := top + Vector2(10 + i * 100, 0)
			var tip := base + Vector2(cos(angle), sin(angle)) * 120.0
			var side := Vector2(-sin(angle), cos(angle)) * 14.0
			view.draw_colored_polygon(PackedVector2Array([base, tip + side, tip - side]), Color(1.0, 0.95, 0.7, 0.12))
	if level >= 5:
		var carpet := PackedVector2Array([view._iso(Vector2(5.9, 1.2)), view._iso(Vector2(6.6, 1.2)), view._iso(Vector2(6.6, 5.3)), view._iso(Vector2(5.9, 5.3))])
		view.draw_colored_polygon(carpet, Color("a3202a"))
		view.draw_polyline(PackedVector2Array([carpet[0], carpet[3]]), Color("f2c14e"), 1.0)
		view.draw_polyline(PackedVector2Array([carpet[1], carpet[2]]), Color("f2c14e"), 1.0)
	if level >= 6:
		_draw_fireworks(view, time)


static func _draw_fireworks(view: StreetView, time: float) -> void:
	for i in 3:
		var cycle := fmod(time * 0.5 + i * 0.37, 1.0)
		if cycle > 0.6:
			continue
		var seed_value := floori(time * 0.5 + i * 0.37) * 31 + i * 7
		var center := Vector2(fmod(seed_value * 53.0, view.size.x * 0.8) + view.size.x * 0.1, 20.0 + fmod(seed_value * 17.0, 30.0))
		var radius := cycle * 30.0
		var color: Color = [Color("ffca3a"), Color("ff6fa8"), Color("6aa0d9")][i]
		for ray in 12:
			var dir := Vector2.from_angle(TAU * ray / 12.0)
			view.draw_rect(Rect2(center + dir * radius, Vector2(2, 2)), Color(color, 1.0 - cycle / 0.6))


## Helpers that stay put: a tea cart at the kerb, the college gate stall and
## the film crew's van, once you own one.
static func draw_helper_spots(view: StreetView, state: KadaiState, time: float) -> void:
	if state.helper_count("college_stall") > 0:
		var stall := Vector2(-3.4, 1.5)
		view._box(stall, stall + Vector2(0.7, 0.45), 12, Color("e8e2cc"), Color("2f6db5"), Color("24548c"))
		var sign := view._iso(stall + Vector2(0.35, 0.2), 30)
		view.draw_line(sign + Vector2(0, 2), sign + Vector2(0, 14), Color("5a5654"), 1.0)
		view.draw_rect(Rect2(sign + Vector2(-12, -6), Vector2(24, 8)), Color("2f6db5"))
		view._text(sign, "COLLEGE", Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 6)
	if state.helper_count("bus_cart") > 0:
		var cart := Vector2(1.3, 6.15)
		view._box(cart, cart + Vector2(0.8, 0.4), 12, Color("c9ced6"), Color("4a90d9"), Color("2f6db5"))
		var top := view._iso(cart + Vector2(0.4, 0.2), 12)
		view.draw_line(top, top + Vector2(0, -14), Color("5a5654"), 1.0)
		view.draw_colored_polygon(PackedVector2Array([top + Vector2(-12, -12), top + Vector2(12, -12), top + Vector2(0, -20)]), Color("e0604e"))
		var steam := fmod(time * 10.0, 10.0)
		view.draw_rect(Rect2(top + Vector2(4, -2 - steam), Vector2(1, 2)), Color(1, 1, 1, 0.5 * (1.0 - steam / 10.0)))
	if state.helper_count("film_catering") > 0:
		var van := Vector2(2.8, 6.2)
		view._box(van, van + Vector2(1.4, 0.5), 18, Color("eef0f2"), Color("d9dde2"), Color("aab2bb"))
		var side := view._iso(van + Vector2(0.7, 0.5), 10)
		view._text(side, "SHOOTING", Color("b5321f"), HORIZONTAL_ALIGNMENT_CENTER, 6)
		for wheel in [Vector2(0.3, 0.5), Vector2(1.1, 0.5)]:
			view.draw_circle(view._iso(van + wheel), 2.5, Color("1a1a1a"))


## Festival touches around the kadai.
static func draw_festival(view: StreetView, day: int, time: float) -> void:
	var special := Chennai.festival(day)
	if special.get("lamps", false):
		for i in 8:
			var at := view._iso(Vector2(1.2 + i * 0.75, 0.8))
			view.draw_rect(Rect2(at + Vector2(-2, -1), Vector2(4, 2)), Color("a0522d"))
			var flicker := 1.0 + sin(time * 12.0 + i) * 0.4
			view.draw_circle(at + Vector2(0, -3), 1.5 * flicker, Color("ffd166"))
			view.draw_circle(at + Vector2(0, -3), 4.0, Color(1.0, 0.8, 0.4, 0.15))
	if special.get("sugarcane", false):
		for i in 3:
			var foot := view._iso(Vector2(7.3 + i * 0.15, 0.5))
			view.draw_line(foot, foot + Vector2(-3 + i * 2, -40), Color("5b8c3a"), 2.0)
			view.draw_line(foot + Vector2(-3 + i * 2, -40), foot + Vector2(-8 + i * 5, -50), Color("7cc46a"), 1.0)
