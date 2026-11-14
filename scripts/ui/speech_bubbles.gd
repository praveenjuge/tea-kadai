class_name SpeechBubbles
extends RefCounted
## Speech bubbles beside customers in the street view: lines they say, and
## questions with answers you can click. Drawn by the street view.

const SAY_SECONDS := 5.0
const ASK_SECONDS := 25.0
const WIDTH := 140.0
const PAD := 4.0
const CHIP_H := 14.0

var _view: StreetView
## Each: {"seat", "text", "t", "life", "options": Array, "chips": Array[Rect2]}.
var _bubbles: Array[Dictionary] = []


func _init(view: StreetView) -> void:
	_view = view


func say(seat: int, text: String) -> void:
	_bubbles = _bubbles.filter(func(b: Dictionary) -> bool: return b["seat"] != seat or not b["options"].is_empty())
	_bubbles.append({"seat": seat, "text": text, "t": 0.0, "life": SAY_SECONDS, "options": [], "chips": []})


func ask(seat: int, question: String, options: Array) -> void:
	clear(seat)
	_bubbles.append({"seat": seat, "text": question, "t": 0.0, "life": ASK_SECONDS, "options": options, "chips": []})


func clear(seat: int) -> void:
	_bubbles = _bubbles.filter(func(b: Dictionary) -> bool: return b["seat"] != seat)


func update(delta: float) -> void:
	var seats := _view.service().seats
	for bubble in _bubbles:
		bubble["t"] += delta
	_bubbles = _bubbles.filter(func(b: Dictionary) -> bool:
		var asking: bool = not b["options"].is_empty()
		if asking and seats[b["seat"]] == null:
			return false
		return b["t"] < b["life"])


## [seat, option index] for an answer chip under "point", or [].
func option_at(point: Vector2) -> Array:
	for bubble in _bubbles:
		var chips: Array = bubble["chips"]
		for i in chips.size():
			if Rect2(chips[i]).grow(2.0).has_point(point):
				return [bubble["seat"], i]
	return []


func draw() -> void:
	var font := _view.get_theme_default_font()
	var taken := _view.order_bubble_rects()
	# Questions first, so they get the best spot.
	var ordered := _bubbles.filter(func(b: Dictionary) -> bool: return not b["options"].is_empty())
	ordered.append_array(_bubbles.filter(func(b: Dictionary) -> bool: return b["options"].is_empty()))
	for bubble in ordered:
		taken.append(_draw_bubble(bubble, font, taken))


## Finds the nearest spot, straight up or down from where the bubble wants to
## be, that stays on screen and clear of everything already placed.
func _place(rect: Rect2, taken: Array[Rect2]) -> Rect2:
	var top := 2.0
	var bottom := _view.size.y - rect.size.y - 20.0
	var wanted := clampf(rect.position.y, top, bottom)
	var tries: Array[float] = [wanted]
	for other in taken:
		tries.append(other.end.y + 3.0)
		tries.append(other.position.y - rect.size.y - 3.0)
	tries.sort_custom(func(a: float, b: float) -> bool: return absf(a - wanted) < absf(b - wanted))
	for y in tries:
		if y < top or y > bottom:
			continue
		var spot := Rect2(rect.position.x, y, rect.size.x, rect.size.y)
		if not taken.any(func(other: Rect2) -> bool: return spot.intersects(other)):
			return spot
	rect.position.y = wanted
	return rect


func _draw_bubble(bubble: Dictionary, font: Font, taken: Array[Rect2]) -> Rect2:
	var text: String = bubble["text"]
	var options: Array = bubble["options"]
	var size := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, WIDTH, Style.FONT_SIZE)
	var height := size.y + PAD * 2.0 + options.size() * (CHIP_H + 3.0)
	var width := maxf(size.x, 60.0) + PAD * 2.0
	var head := _view.seat_point(bubble["seat"])
	# Sit to the left of the head; flip to the right near the left edge.
	var x := head.x - 12.0 - width
	if x < 4.0:
		x = head.x + 12.0
	var rect := _place(Rect2(x, head.y - height / 2.0, width, height), taken)
	var fade := clampf((float(bubble["life"]) - float(bubble["t"])) / 0.4, 0.0, 1.0)
	var pop := minf(1.0, float(bubble["t"]) / 0.12)
	var paper := Color(Style.PAPER, fade)
	var tail_x := rect.end.x if rect.position.x < head.x else rect.position.x
	var tail_dir := 1.0 if rect.position.x < head.x else -1.0
	var tail_y := clampf(head.y, rect.position.y + 4.0, rect.end.y - 4.0)
	_view.draw_set_transform(head, 0.0, Vector2(pop, pop))
	var local := Rect2(rect.position - head, rect.size)
	_view.draw_rect(local, paper)
	_view.draw_rect(local, Color(Style.WOOD_EDGE, fade), false, 1.0)
	_view.draw_colored_polygon(PackedVector2Array([
		Vector2(tail_x, tail_y - 3) - head, Vector2(tail_x, tail_y + 3) - head,
		Vector2(tail_x + 6.0 * tail_dir, tail_y) - head]), paper)
	_view.draw_multiline_string(font, local.position + Vector2(PAD, PAD + 9), text, HORIZONTAL_ALIGNMENT_LEFT,
		WIDTH, Style.FONT_SIZE, -1, Color(Style.INK, fade))
	_view.draw_set_transform(Vector2.ZERO)
	var chips: Array[Rect2] = []
	for i in options.size():
		var chip := Rect2(rect.position.x + PAD, rect.position.y + PAD + size.y + 3.0 + i * (CHIP_H + 3.0),
			rect.size.x - PAD * 2.0, CHIP_H)
		_view.draw_rect(chip, Color(Style.ACCENT, fade))
		_view.draw_rect(Rect2(chip.position + Vector2(0, chip.size.y - 2), Vector2(chip.size.x, 2)),
			Color(Style.ACCENT.darkened(0.45), fade))
		_view.draw_string(font, chip.position + Vector2(4, 10), options[i], HORIZONTAL_ALIGNMENT_LEFT,
			chip.size.x - 6, Style.FONT_SIZE, Color(Style.INK, fade))
		chips.append(chip)
	bubble["chips"] = chips
	return rect.grow(2.0)
