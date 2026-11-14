class_name PixelArt
extends RefCounted
## Paints the game's pixel sprites, pixel by pixel: people from a "look"
## (skin, hair, shirt, saree, glasses...) in a few poses, and every menu item.
## Each sprite gets light from the top left, shade on the bottom right and a
## dark outline. Textures are cached, so each look is painted once.
## tools/make_sprites.gd exports them all to a sheet for a look.

const PERSON := Vector2i(20, 44)
## Where the feet are in a person sprite.
const FEET := Vector2i(10, 43)
const ITEM := Vector2i(14, 14)
const POSES: Array[String] = ["stand", "step", "wave_a", "wave_b", "slump"]
const SANDAL := Color("3a2a1a")
const DARK := Color("1a120d")

static var _cache := {}


## A person's texture for this look and pose, drawn with the feet at FEET.
static func person_texture(look: Dictionary, pose: String) -> Texture2D:
	var key := "p%d_%s" % [hash(look), pose]
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(person(look, pose))
	return _cache[key]


## A menu item's texture; "low" is the not-so-good version (pale, no froth).
static func item_texture(id: String, low: bool = false) -> Texture2D:
	var key := "i%s_%s" % [id, low]
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(item(id, low))
	return _cache[key]


# --- People -----------------------------------------------------------------

static func person(look: Dictionary, pose: String) -> Image:
	var img := Image.create_empty(PERSON.x, PERSON.y, false, Image.FORMAT_RGBA8)
	var skin: Color = look.get("skin", Style.SKIN)
	var hair: Color = look.get("hair", DARK)
	var shirt: Color = look["shirt"]
	var legs: Color = look["legs"]
	var step := pose == "step"
	# How far the upper body sits below its usual place.
	var drop := 2 if pose == "slump" else (-1 if step else 0)
	# Legs, or a saree's skirt.
	if look.has("saree"):
		_poly(img, [Vector2(5, 30), Vector2(15, 30), Vector2(16, 43), Vector2(4, 43)], legs)
		_rect(img, 4, 41, 12, 2, look["saree"])
	else:
		var left_end := 40 if step else 42
		_rect(img, 6, 30, 3, left_end - 30 + 1, legs)
		_rect(img, 11, 30, 3, 42 - 30 + 1, legs)
		_rect(img, 6, left_end, 3, 1, SANDAL)
		_rect(img, 11, 42, 4, 1, SANDAL)
	# Body and arms.
	var top := 18 + drop
	_rect(img, 5, top, 10, 13 - maxi(drop, 0), shirt)
	_rect(img, 9, top, 2, 2, skin)
	if look.has("saree"):
		_poly(img, [Vector2(12, top), Vector2(15, top), Vector2(7, top + 12), Vector2(5, top + 12), Vector2(5, top + 10)], look["saree"])
	elif not look.get("tag", false):
		_rect(img, 6, top + 3, 2, 2, shirt.darkened(0.25))
	_arm(img, 3, top, shirt, skin, false, 0)
	if pose == "wave_a" or pose == "wave_b":
		_arm(img, 15, top, shirt, skin, true, 1 if pose == "wave_b" else 0)
	else:
		_arm(img, 15, top, shirt, skin, false, 0)
	if look.get("tag", false):
		_line(img, Vector2i(7, top), Vector2i(9, top + 5), Color("2f4f8f"))
		_rect(img, 9, top + 5, 3, 3, Color.WHITE)
		_rect(img, 9, top + 5, 3, 1, Color("2f6db5"))
	if look.has("bag"):
		var bag: Color = look["bag"]
		_line(img, Vector2i(6, top), Vector2i(13, top + 9), bag.darkened(0.3))
		_rect(img, 16, top + 1, 3, 8, bag)
	# Neck and head.
	_rect(img, 8, top - 1, 4, 1, skin.darkened(0.15))
	_head(img, look, skin, hair, top - 12)
	_finish(img)
	return img


static func _arm(img: Image, x: int, top: int, shirt: Color, skin: Color, up: bool, swing: int) -> void:
	if up:
		_rect(img, x, top - 9, 2, 10, skin)
		_rect(img, x, top - 1, 2, 3, shirt)
		_rect(img, x + swing, top - 11, 2, 2, skin)
		return
	_rect(img, x, top + 1, 2, 4, shirt)
	_rect(img, x, top + 5, 2, 5, skin)


static func _head(img: Image, look: Dictionary, skin: Color, hair: Color, top: int) -> void:
	var style: String = look.get("hair_style", "short")
	if style == "long":
		_rect(img, 4, top + 2, 12, 12, hair)
	_rect(img, 5, top + 1, 10, 11, skin)
	_rect(img, 4, top + 5, 1, 3, skin.darkened(0.1))
	_rect(img, 15, top + 5, 1, 3, skin.darkened(0.1))
	match style:
		"bald":
			_rect(img, 5, top + 3, 1, 4, hair)
			_rect(img, 14, top + 3, 1, 4, hair)
			_rect(img, 8, top + 1, 3, 1, skin.lightened(0.25))
		"bun":
			_rect(img, 5, top, 10, 3, hair)
			_rect(img, 6, top - 1, 8, 1, hair)
			_rect(img, 8, top - 4, 4, 3, hair)
		_:
			_rect(img, 5, top, 10, 3, hair)
			_rect(img, 6, top - 1, 8, 1, hair)
			_rect(img, 5, top + 3, 1, 2, hair)
			_rect(img, 14, top + 3, 1, 1, hair)
	# Face: brows, eyes, nose and mouth or mustache.
	_rect(img, 6, top + 4, 2, 1, hair.lightened(0.1))
	_rect(img, 12, top + 4, 2, 1, hair.lightened(0.1))
	_rect(img, 7, top + 6, 1, 1, DARK)
	_rect(img, 12, top + 6, 1, 1, DARK)
	_rect(img, 9, top + 7, 2, 1, skin.darkened(0.2))
	if look.get("mustache", false):
		_rect(img, 7, top + 8, 6, 1, hair.darkened(0.2))
	else:
		_rect(img, 9, top + 9, 2, 1, skin.darkened(0.35))
	if look.get("glasses", false):
		var frame := Color("5a5a66")
		for x in [6, 11]:
			_rect(img, x, top + 5, 3, 1, frame)
			_rect(img, x, top + 7, 3, 1, frame)
		_rect(img, 9, top + 5, 2, 1, frame)
	if look.has("hat"):
		var hat: Color = look["hat"]
		_rect(img, 5, top - 2, 10, 4, hat)
		_rect(img, 6, top - 3, 8, 1, hat)
		_rect(img, 3, top + 1, 13, 1, hat.darkened(0.2))
	if look.get("flowers", false):
		for dot in [Vector2i(14, top), Vector2i(15, top + 1), Vector2i(14, top + 2), Vector2i(15, top + 3)]:
			_rect(img, dot.x, dot.y, 1, 1, Color.WHITE)
		_rect(img, 15, top + 2, 1, 1, Color("f39c12"))


# --- Items ------------------------------------------------------------------

static func item(id: String, low: bool) -> Image:
	var img := Image.create_empty(ITEM.x, ITEM.y, false, Image.FORMAT_RGBA8)
	var golden := Style.VADAI_RAW.darkened(0.1) if low else Style.VADAI_GOLDEN
	match id:
		"tea", "ginger_tea", "lemon_tea":
			_glass(img, Style.drink_color(id), not low and id != "lemon_tea")
			if id == "ginger_tea":
				_rect(img, 10, 1, 3, 3, Color("d9c25a"))
				_rect(img, 11, 0, 1, 1, Color("7cc46a"))
			if id == "lemon_tea":
				_disc(img, Vector2(10.5, 3.5), 2.6, Color("e8d23c"))
				_rect(img, 10, 3, 1, 1, Color("f4eb8a"))
		"filter_coffee":
			_rect(img, 1, 10, 12, 3, Color("aab2bb"))
			_rect(img, 4, 2, 6, 9, Color("c9ced6"))
			_rect(img, 4, 2, 6, 2, Color("d9b48a"))
			_rect(img, 5, 5, 1, 4, Color("e4e8ee"))
		"vadai":
			_disc(img, Vector2(7, 7.5), 5.6, golden)
			_disc(img, Vector2(7, 7.5), 1.6, Color(0, 0, 0, 0))
			for dot in [Vector2i(4, 5), Vector2i(9, 4), Vector2i(10, 9), Vector2i(4, 10)]:
				_rect(img, dot.x, dot.y, 1, 1, golden.darkened(0.25))
		"bajji":
			_poly(img, [Vector2(1, 8), Vector2(4, 4), Vector2(11, 4), Vector2(13, 7), Vector2(11, 11), Vector2(3, 11)], golden)
			_rect(img, 12, 6, 2, 2, Color("3a8a3a"))
			_rect(img, 4, 6, 1, 1, golden.lightened(0.2))
			_rect(img, 8, 8, 1, 1, golden.darkened(0.2))
		"biscuit":
			_rect(img, 2, 2, 10, 10, Color("d9a55b"))
			for dot in [Vector2i(4, 4), Vector2i(8, 4), Vector2i(4, 8), Vector2i(8, 8), Vector2i(6, 6)]:
				_rect(img, dot.x, dot.y, 1, 1, Color("8a5a2b"))
		"bun":
			_disc(img, Vector2(7, 7.5), 5.5, Color("c98a45"))
			_rect(img, 1, 8, 12, 4, Color("c98a45"))
			_rect(img, 5, 4, 4, 1, Color("f0c98a"))
			for dot in [Vector2i(4, 6), Vector2i(9, 5), Vector2i(7, 7)]:
				_rect(img, dot.x, dot.y, 1, 1, Color("f4ecd2"))
		"samosa":
			_poly(img, [Vector2(7, 1), Vector2(13, 12), Vector2(1, 12)], Color("d9a050"))
			_line(img, Vector2i(7, 2), Vector2i(7, 11), Color("b8803a"))
			_line(img, Vector2i(4, 9), Vector2i(10, 9), Color("e8b86a"))
	_finish(img)
	return img


## A tapered glass tumbler with a drink, and froth for a good pour.
static func _glass(img: Image, drink: Color, froth: bool) -> void:
	_poly(img, [Vector2(3, 1), Vector2(11, 1), Vector2(10, 13), Vector2(4, 13)], Color(0.95, 0.93, 0.86, 0.55))
	_poly(img, [Vector2(3.5, 4), Vector2(10.5, 4), Vector2(10, 13), Vector2(4, 13)], drink)
	if froth:
		_rect(img, 4, 3, 6, 2, Style.FROTH)
	_rect(img, 4, 5, 1, 6, drink.lightened(0.25))


# --- Painting helpers -------------------------------------------------------

static func _rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	var rect := Rect2i(x, y, w, h).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	if rect.has_area():
		img.fill_rect(rect, color)


static func _disc(img: Image, center: Vector2, radius: float, color: Color) -> void:
	for y in img.get_height():
		for x in img.get_width():
			if Vector2(x + 0.5, y + 0.5).distance_to(center) <= radius:
				img.set_pixel(x, y, color)


static func _poly(img: Image, points: Array, color: Color) -> void:
	var shape := PackedVector2Array(points)
	for y in img.get_height():
		for x in img.get_width():
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), shape):
				img.set_pixel(x, y, color)


static func _line(img: Image, from: Vector2i, to: Vector2i, color: Color) -> void:
	var steps := maxi(absi(to.x - from.x), absi(to.y - from.y))
	for i in steps + 1:
		var at := Vector2(from).lerp(Vector2(to), float(i) / maxf(1.0, steps)).round()
		if Rect2i(Vector2i.ZERO, img.get_size()).has_point(Vector2i(at)):
			img.set_pixel(int(at.x), int(at.y), color)


## Light from the top left, shade on the bottom right, and a dark outline.
static func _finish(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var base := img.duplicate() as Image
	var solid := func(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < w and y < h and base.get_pixel(x, y).a > 0.3
	for y in h:
		for x in w:
			var color := base.get_pixel(x, y)
			if color.a <= 0.3:
				continue
			if not solid.call(x, y - 1) or not solid.call(x - 1, y):
				color = color.lightened(0.14)
			elif not solid.call(x, y + 1) or not solid.call(x + 1, y):
				color = color.darkened(0.2)
			img.set_pixel(x, y, color)
	for y in h:
		for x in w:
			if solid.call(x, y):
				continue
			for n in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
				if solid.call(x + n.x, y + n.y):
					var near := base.get_pixel(x + n.x, y + n.y)
					img.set_pixel(x, y, Color(near.darkened(0.72), 1.0))
					break
