class_name NightScene
extends Control
## The street after closing, drawn behind the night screen: the kadai under
## the moon with its shutter half down, warm light spilling out underneath,
## you on a stool counting the day's coins, a sleeping dog and a street lamp
## with moths. Everything moves a little: stars, the bulb, the coins.

const SKY_TOP := Color("0b1230")
const SKY_LOW := Color("2b2c57")
const HOUSE := Color("171b33")
const HOUSE_EDGE := Color("22284a")
const WINDOW_LIT := Color("f2c46a")
const ROAD := Color("1b1d29")
const FOOTPATH := Color("2a2b3a")
const WALL := Color("3b3350")
const WALL_DARK := Color("2c2640")
const STEEL := Color("566275")
const STEEL_LIGHT := Color("7b889b")
const GLOW := Color(1.0, 0.72, 0.38)
const OWNER := {"skin": Color("8d5a3b"), "hair": Color("1e1612"), "mustache": true}

var _time := 0.0
## Coins counted so far, set by the night screen as the tally runs.
var counted := 0
var _stars: Array[Vector3] = []
var _windows: Array[Vector3] = []


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 90:
		_stars.append(Vector3(rng.randf(), rng.randf() * 0.55, rng.randf() * TAU))
	for i in 40:
		_windows.append(Vector3(rng.randf(), rng.randf(), rng.randf()))


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var ground := h * 0.76
	_draw_sky(w, ground)
	_draw_houses(w, ground)
	draw_rect(Rect2(0, ground, w, h - ground), ROAD)
	draw_rect(Rect2(0, ground, w, 10), FOOTPATH)
	draw_rect(Rect2(0, ground, w, 1), Color(STEEL_LIGHT, 0.4))
	var cx := w / 2.0
	_draw_lamp(Vector2(cx - 150, ground))
	_draw_kadai(Vector2(cx, ground))
	_draw_owner(Vector2(cx - 44, ground + 8))
	_draw_dog(Vector2(cx + 78, ground + 16))
	_draw_moths(Vector2(cx - 150, ground - 112))


func _draw_sky(w: float, ground: float) -> void:
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, ground), Vector2(0, ground)]),
		PackedColorArray([SKY_TOP, SKY_TOP, SKY_LOW, SKY_LOW]))
	for star in _stars:
		var twinkle := 0.45 + 0.55 * absf(sin(_time * 1.3 + star.z))
		var at := Vector2(star.x * w, 4 + star.y * ground)
		draw_rect(Rect2(at, Vector2.ONE), Color(1, 1, 0.9, twinkle))
		if star.z > 5.8:
			draw_rect(Rect2(at + Vector2(-1, 0), Vector2(3, 1)), Color(1, 1, 0.9, twinkle * 0.4))
			draw_rect(Rect2(at + Vector2(0, -1), Vector2(1, 3)), Color(1, 1, 0.9, twinkle * 0.4))
	# The moon, with a soft halo and a few craters.
	var moon := Vector2(w / 2.0 - 10, 40)
	for ring in [[30.0, 0.05], [22.0, 0.08], [17.0, 0.12]]:
		draw_circle(moon, ring[0], Color(1, 0.95, 0.8, ring[1]))
	draw_circle(moon, 12.0, Color("f4ecd2"))
	draw_circle(moon + Vector2(4, -2), 12.0, Color("f4ecd2").darkened(0.04))
	for crater in [[Vector2(-4, -3), 2.5], [Vector2(3, 4), 2.0], [Vector2(5, -5), 1.4]]:
		draw_circle(moon + crater[0], crater[1], Color("dcd2b4"))


## A row of flat-roofed houses and shops, most windows dark.
func _draw_houses(w: float, ground: float) -> void:
	var x := -10.0
	var i := 0
	while x < w:
		var width := 46.0 + fmod(i * 37.0, 30.0)
		var height := 70.0 + fmod(i * 53.0, 60.0)
		var rect := Rect2(x, ground - height, width - 2, height)
		draw_rect(rect, HOUSE)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2)), HOUSE_EDGE)
		# Water tank on some roofs.
		if i % 3 == 1:
			draw_rect(Rect2(x + 8, ground - height - 8, 12, 8), HOUSE)
		for row in int(height / 22.0) - 1:
			for col in int(width / 16.0):
				var seed_value := _windows[(i * 7 + row * 3 + col) % _windows.size()]
				var lit := seed_value.x > 0.72
				var window := Rect2(x + 5 + col * 14, ground - height + 10 + row * 20, 6, 8)
				if lit:
					var flicker := 0.85 + 0.15 * sin(_time * 0.7 + seed_value.z * 9.0)
					draw_rect(window, Color(WINDOW_LIT, flicker))
				else:
					draw_rect(window, HOUSE_EDGE)
		x += width
		i += 1


## The kadai: the sign, a half-closed shutter, and light spilling out.
func _draw_kadai(base: Vector2) -> void:
	var half := 92.0
	var top := base.y - 128.0
	var opening_top := base.y - 84.0
	var shutter_bottom := base.y - 42.0
	# Light on the footpath.
	draw_colored_polygon(PackedVector2Array([
		Vector2(base.x - half + 10, base.y), Vector2(base.x + half - 10, base.y),
		Vector2(base.x + half + 40, base.y + 40), Vector2(base.x - half - 40, base.y + 40)]), Color(GLOW, 0.13))
	draw_rect(Rect2(base.x - half, top, half * 2, base.y - top), WALL)
	draw_rect(Rect2(base.x - half, top, half * 2, 3), WALL_DARK)
	# The sign board, unlit for the night.
	var sign := Rect2(base.x - half + 10, top + 8, half * 2 - 20, 26)
	draw_rect(sign, Color("6b2a22"))
	draw_rect(sign, Color("2a1410"), false, 1.0)
	var font := get_theme_default_font()
	if font != null:
		var text := "TEA KADAI"
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, Style.TITLE_SIZE).x
		draw_string(font, Vector2(base.x - width / 2.0, sign.position.y + 19), text, HORIZONTAL_ALIGNMENT_LEFT, -1, Style.TITLE_SIZE, Color("c99a4a"))
	# Inside, under the shutter: warm light, the counter and the glasses.
	var inside := Rect2(base.x - half + 12, opening_top, half * 2 - 24, base.y - opening_top)
	draw_rect(inside, Color("3a2416"))
	var bulb := 0.85 + 0.1 * sin(_time * 9.0) * sin(_time * 2.3)
	draw_rect(Rect2(inside.position.x, shutter_bottom, inside.size.x, base.y - shutter_bottom), Color(GLOW, 0.35 * bulb))
	draw_rect(Rect2(inside.position.x, base.y - 16, inside.size.x, 16), Color("6b4024"))
	draw_rect(Rect2(inside.position.x, base.y - 16, inside.size.x, 2), Color("a8703f"))
	for i in 7:
		var glass := Vector2(inside.position.x + 14 + i * 9, base.y - 24)
		draw_rect(Rect2(glass, Vector2(5, 8)), Color(1, 0.95, 0.85, 0.5))
	draw_rect(Rect2(base.x + 30, base.y - 34, 18, 18), Color("8c8f94"))
	draw_rect(Rect2(base.x + 30, base.y - 34, 18, 3), Color("b9bcc0"))
	# The shutter, pulled half way down.
	var y := opening_top
	while y < shutter_bottom:
		draw_rect(Rect2(inside.position.x - 2, y, inside.size.x + 4, 6), STEEL)
		draw_rect(Rect2(inside.position.x - 2, y, inside.size.x + 4, 1), STEEL_LIGHT)
		y += 6
	draw_rect(Rect2(inside.position.x - 2, shutter_bottom - 3, inside.size.x + 4, 4), Color("2f353f"))
	# A thin glow line under the shutter edge.
	draw_rect(Rect2(inside.position.x, shutter_bottom + 1, inside.size.x, 1), Color(GLOW, 0.8 * bulb))


## You, on a stool by the kadai, stacking the day's coins.
func _draw_owner(feet: Vector2) -> void:
	draw_rect(Rect2(feet + Vector2(-7, -10), Vector2(14, 3)), Color("6b4024"))
	draw_rect(Rect2(feet + Vector2(-6, -7), Vector2(2, 7)), Color("4a2c18"))
	draw_rect(Rect2(feet + Vector2(4, -7), Vector2(2, 7)), Color("4a2c18"))
	# Legs, veshti and shirt.
	draw_rect(Rect2(feet + Vector2(-5, -18), Vector2(11, 9)), Color("efe6d2"))
	draw_rect(Rect2(feet + Vector2(-5, -30), Vector2(10, 13)), Color("4f7fa8"))
	draw_set_transform(feet + Vector2(0, -30))
	Style.draw_head(self, OWNER)
	draw_set_transform(Vector2.ZERO)
	# A little crate for a table, with coin stacks that grow as the tally counts.
	var table := feet + Vector2(12, -12)
	draw_rect(Rect2(table, Vector2(20, 12)), Color("7a5230"))
	draw_rect(Rect2(table, Vector2(20, 2)), Color("a8703f"))
	var stacks := clampi(1 + counted / 120, 1, 4)
	for s in stacks:
		var height := 2 + (counted / 40 + s * 3) % 6
		for c in height:
			draw_rect(Rect2(table + Vector2(2 + s * 5, -2 - c * 2), Vector2(4, 2)), Color("e8c547") if c % 2 == 0 else Color("b8862f"))
	# One coin in the hand, flipping.
	var hand := feet + Vector2(7, -24)
	var flip := absf(sin(_time * 5.0))
	draw_rect(Rect2(hand + Vector2(-2.0 * flip, -2 - flip * 3.0), Vector2(maxf(1.0, 4.0 * flip), 3)), Color("f2d27a"))
	draw_rect(Rect2(hand + Vector2(-1, 0), Vector2(4, 3)), OWNER["skin"])


## A street dog curled up asleep, breathing slowly.
func _draw_dog(at: Vector2) -> void:
	var breath := 1.0 + 0.06 * sin(_time * 1.6)
	draw_set_transform(at, 0.0, Vector2(1.0, breath))
	draw_circle(Vector2(0, -4), 8.0, Color("8a6440"))
	draw_circle(Vector2(6, -5), 4.0, Color("9a7450"))
	draw_rect(Rect2(8, -9, 3, 3), Color("6b4a2c"))
	draw_set_transform(Vector2.ZERO)
	var font := get_theme_default_font()
	if font != null:
		var rise := fmod(_time * 0.6, 1.0)
		draw_string(font, at + Vector2(10 + rise * 6, -14 - rise * 12), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, Style.FONT_SIZE, Color(1, 1, 1, 1.0 - rise))


## A street lamp with its light cone.
func _draw_lamp(foot: Vector2) -> void:
	var head := foot + Vector2(0, -112)
	draw_colored_polygon(PackedVector2Array([head + Vector2(-4, 4), head + Vector2(4, 4),
		foot + Vector2(36, 0), foot + Vector2(-36, 0)]), Color(1.0, 0.85, 0.55, 0.08))
	draw_rect(Rect2(foot + Vector2(-1.5, -112), Vector2(3, 112)), Color("3a4150"))
	draw_rect(Rect2(head + Vector2(-6, -2), Vector2(12, 5)), Color("3a4150"))
	draw_circle(head + Vector2(0, 4), 3.0, Color("fff1c4"))
	draw_circle(head + Vector2(0, 4), 8.0, Color(1.0, 0.9, 0.6, 0.18))


func _draw_moths(around: Vector2) -> void:
	for i in 4:
		var angle := _time * (1.8 + i * 0.4) + i * 1.7
		var at := around + Vector2(cos(angle) * (6 + i * 2), sin(angle * 1.3) * (4 + i))
		draw_rect(Rect2(at, Vector2(1, 1)), Color(1, 1, 0.9, 0.8))
