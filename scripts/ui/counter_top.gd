class_name CounterTop
extends MarginContainer
## The wooden counter along the bottom of the service screen. The stations
## (stove, kadai, tray) sit on it as one workspace instead of separate panels.

const BACK_EDGE := 6.0
const FRONT_LIP := 10.0
const PLANKS := 4
const WOOD_A := Color("8a5a32")
const WOOD_B := Color("95643a")
const GRAIN := Color("6e4626")

var _row := HBoxContainer.new()


func _init() -> void:
	add_theme_constant_override("margin_top", int(BACK_EDGE))
	add_theme_constant_override("margin_bottom", int(FRONT_LIP))
	_row.add_theme_constant_override("separation", 0)
	add_child(_row)


func add_station(station: Control) -> void:
	_row.add_child(station)


func _draw() -> void:
	var w := size.x
	var h := size.y
	# Back edge where the counter meets the street.
	draw_rect(Rect2(0, 0, w, BACK_EDGE), Style.WOOD_EDGE)
	draw_rect(Rect2(0, BACK_EDGE - 1, w, 1), WOOD_B.lightened(0.15))
	# Planks with a little grain, the same pattern every frame.
	var surface := h - BACK_EDGE - FRONT_LIP
	var plank_h := surface / PLANKS
	for i in PLANKS:
		var y := BACK_EDGE + i * plank_h
		draw_rect(Rect2(0, y, w, plank_h), WOOD_A if i % 2 == 0 else WOOD_B)
		draw_rect(Rect2(0, y, w, 1), GRAIN.darkened(0.2))
		for g in int(w / 70.0) + 1:
			var gx := fmod(g * 70.0 + i * 37.0, w)
			var gy := y + plank_h * (0.35 + 0.3 * ((g + i) % 3) / 2.0)
			draw_line(Vector2(gx, gy), Vector2(gx + 26.0, gy + 1.0), GRAIN, 1.0)
	# Front lip with a highlight and nails.
	var lip := h - FRONT_LIP
	draw_rect(Rect2(0, lip, w, FRONT_LIP), WOOD_A.darkened(0.35))
	draw_rect(Rect2(0, lip, w, 1), WOOD_B.lightened(0.2))
	for nx in range(12, int(w), 48):
		draw_rect(Rect2(nx, lip + 4, 2, 2), Color("c9b48c"))
	# Faint grooves between the stations.
	for station in _row.get_children():
		var x: float = (station as Control).position.x + (station as Control).size.x + _row.position.x
		if x < w - 4:
			draw_rect(Rect2(x - 1, BACK_EDGE, 2, surface), Color(0, 0, 0, 0.18))
