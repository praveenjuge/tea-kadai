class_name NewsTicker
extends Control
## A strip of Chennai news scrolling right to left, like a TV channel's
## ticker. The lines get sillier the bigger the kadai has grown.

const SPEED := 28.0
const GAP := "     ·     "

var _text := ""
var _offset := 0.0
var _width := 0.0


func _init(lines: Array[String]) -> void:
	custom_minimum_size.y = 14
	mouse_filter = MOUSE_FILTER_IGNORE
	var shuffled := lines.duplicate()
	shuffled.shuffle()
	_text = GAP.join(shuffled) + GAP


func _process(delta: float) -> void:
	_offset += SPEED * delta
	if _width > 0.0 and _offset > _width:
		_offset -= _width
	queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO, size), Color(Style.BG, 0.85))
	draw_rect(Rect2(0, 0, size.x, 1), Style.ACCENT)
	_width = font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, Style.FONT_SIZE).x
	var label := "NEWS"
	var label_width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, Style.FONT_SIZE).x + 10
	var x := label_width - _offset
	while x < size.x:
		draw_string(font, Vector2(x, size.y - 3), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, Style.FONT_SIZE, Style.TEXT)
		x += _width
	draw_rect(Rect2(0, 1, label_width, size.y - 1), Style.ACCENT)
	draw_string(font, Vector2(5, size.y - 3), label, HORIZONTAL_ALIGNMENT_LEFT, -1, Style.FONT_SIZE, Style.INK)
