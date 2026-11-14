extends SceneTree
## Paints the app icon: a glass of tea with froth and steam on a warm tile
## with a kolam, as 64x64 pixel art scaled up to 1024x1024 for macOS and the
## App Store. Saves assets/icon.png.
## Run: godot --headless --path . -s tools/make_icon.gd

const SIZE := 64
const SCALE := 16
const OUT := "res://assets/icon.png"


func _init() -> void:
	var img := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	# A rounded square, darker towards the bottom, with a light rim on top.
	for y in SIZE:
		var shade := Color("e8a33d").lerp(Color("b5541f"), float(y) / SIZE)
		for x in SIZE:
			if _inside_rounded(x, y, 6, 11):
				img.set_pixel(x, y, shade)
	for x in range(16, SIZE - 16):
		img.set_pixel(x, 7, Color("f6c56a"))
	# A white kolam ring of dots and petals behind the glass.
	var center := Vector2(32, 35)
	for i in 24:
		var a := TAU * i / 24.0
		var at := (center + Vector2(cos(a), sin(a)) * 20.0).round()
		img.set_pixel(int(at.x), int(at.y), Color(1, 1, 1, 0.85))
	for i in 8:
		var a := TAU * i / 8.0 + 0.2
		var at := center + Vector2(cos(a), sin(a)) * 16.0
		PixelArt._disc(img, at, 2.2, Color("f4ecd2", 0.9))
	# The glass: tapered, tea inside, a thick froth, a highlight.
	PixelArt._poly(img, [Vector2(20, 21), Vector2(44, 21), Vector2(40.5, 50), Vector2(23.5, 50)], Color(0.97, 0.95, 0.9, 0.75))
	PixelArt._poly(img, [Vector2(22, 29), Vector2(42, 29), Vector2(39.5, 48), Vector2(24.5, 48)], Color("a8672f"))
	PixelArt._poly(img, [Vector2(21.5, 25), Vector2(42.5, 25), Vector2(42, 29), Vector2(22, 29)], Color("f3dcb0"))
	PixelArt._rect(img, 24, 31, 2, 15, Color("c98a4f"))
	PixelArt._rect(img, 20, 21, 24, 2, Color(1, 1, 1, 0.9))
	# Steam curling up.
	for wisp in [[26, 0.0], [32, 1.4], [38, 2.8]]:
		for y in range(11, 19):
			var x := int(wisp[0] + round(sin(y * 0.6 + wisp[1]) * 1.5))
			img.set_pixel(x, y, Color(1, 1, 1, 0.55 + 0.03 * y))
	PixelArt._finish(img)
	# The outline pass also rims the tile; keep the corners clear.
	for y in SIZE:
		for x in SIZE:
			if not _inside_rounded(x, y, 5, 12):
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	img.resize(SIZE * SCALE, SIZE * SCALE, Image.INTERPOLATE_NEAREST)
	img.save_png(ProjectSettings.globalize_path(OUT))
	print("Saved ", OUT)
	quit()


func _inside_rounded(x: int, y: int, margin: int, radius: int) -> bool:
	var lo := margin
	var hi := SIZE - 1 - margin
	if x < lo or y < lo or x > hi or y > hi:
		return false
	var cx := clampi(x, lo + radius, hi - radius)
	var cy := clampi(y, lo + radius, hi - radius)
	return Vector2(x, y).distance_to(Vector2(cx, cy)) <= radius
