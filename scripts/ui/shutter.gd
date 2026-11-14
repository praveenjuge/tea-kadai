class_name Shutter
extends Control
## The kadai's rolling steel shutter, pulled down between screens and rolled
## back up on the next one. "amount" is how far down it is, 0 to 1.

const SLAT := 8.0
const STEEL := Color("7d8a96")
const STEEL_DARK := Color("5d6873")
const STEEL_LIGHT := Color("a9b4be")
const RUST := Color("8a5a3c")
const BAR := Color("3c4249")

var amount := 0.0:
	set(value):
		amount = value
		visible = amount > 0.001
		mouse_filter = MOUSE_FILTER_STOP if amount > 0.5 else MOUSE_FILTER_IGNORE
		queue_redraw()


func _init() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE


func _draw() -> void:
	var bottom := size.y * amount
	var top := bottom - size.y
	# Slats, moving down with the shutter.
	var y := top
	var row := 0
	while y < bottom:
		draw_rect(Rect2(0, y, size.x, SLAT), STEEL)
		draw_rect(Rect2(0, y, size.x, 2), STEEL_LIGHT)
		draw_rect(Rect2(0, y + SLAT - 2, size.x, 2), STEEL_DARK)
		# A few rust spots, the same every time.
		for spot in 3:
			var x := fmod(row * 97.0 + spot * 211.0, size.x)
			draw_rect(Rect2(x, y + 3, 3 + spot, 2), Color(RUST, 0.5))
		y += SLAT
		row += 1
	_draw_painting(top)
	# The bottom bar with handles and a padlock.
	draw_rect(Rect2(0, bottom - 10, size.x, 10), BAR)
	draw_rect(Rect2(0, bottom - 10, size.x, 2), STEEL_LIGHT)
	for handle_x in [size.x * 0.3, size.x * 0.7]:
		draw_rect(Rect2(handle_x - 10, bottom - 7, 20, 4), STEEL_LIGHT)
		draw_rect(Rect2(handle_x - 10, bottom - 7, 20, 4), BAR, false, 1.0)
	var lock := Vector2(size.x / 2.0, bottom - 2)
	draw_arc(lock + Vector2(0, -1), 3.5, PI, TAU, 8, Color("c9a23a"), 1.5)
	draw_rect(Rect2(lock + Vector2(-4, 0), Vector2(8, 7)), Color("c9a23a"))
	draw_rect(Rect2(lock + Vector2(-1, 2), Vector2(2, 3)), BAR)


## The hand-painted name across the middle of the shutter.
func _draw_painting(top: float) -> void:
	var font := get_theme_default_font()
	if font == null:
		return
	var center := Vector2(size.x / 2.0, top + size.y * 0.45)
	var band := Rect2(center.x - 140, center.y - 26, 280, 52)
	draw_rect(band, Color("c23b2c", 0.85))
	draw_rect(Rect2(band.position + Vector2(0, 4), Vector2(band.size.x, 2)), Color("f2d27a", 0.8))
	draw_rect(Rect2(band.position + Vector2(0, band.size.y - 6), Vector2(band.size.x, 2)), Color("f2d27a", 0.8))
	_text_centered(font, "TEA KADAI", center + Vector2(0, 6), Style.HERO_SIZE, Color("f6e08a"))
	_text_centered(font, "Tea · Coffee · Snacks · Since 2025", center + Vector2(0, 22), Style.FONT_SIZE, Color("f6e7c8"))


func _text_centered(font: Font, text: String, baseline: Vector2, font_size: int, color: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var at := baseline - Vector2(width / 2.0, 0)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color("5a1c14"))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
