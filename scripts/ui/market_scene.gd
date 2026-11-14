class_name MarketScene
extends Control
## The morning market: three vendor stalls with goods on the counter. Click a
## pack to buy it; click the little minus to put back one bought this morning.

signal bought(stock_id: String)
signal returned(stock_id: String)

const TILE := Vector2(46, 66)
## How tall a stall is drawn; extra space is split above and below.
const STALL_H := 124.0
const STALL_GAP := 10.0
const AWNING_H := 20.0

## Each stall: its sign, awning colour, and goods.
const STALLS := [
	{"name": "Milk & tea", "awning": Color("c0392b"),
		"goods": ["milk", "tea_powder", "sugar", "ginger", "lemon", "coffee_powder"]},
	{"name": "Oil & batter", "awning": Color("3a8a3a"), "goods": ["batter", "besan", "oil"]},
	{"name": "Bakery", "awning": Color("2f6db5"), "goods": ["biscuit", "bun", "samosa"]},
]

var _state: KadaiState
## stock id -> {"rect": Rect2, "undo": Rect2}
var _tiles := {}
var _hover := ""


func _init(state: KadaiState) -> void:
	_state = state
	mouse_default_cursor_shape = CURSOR_POINTING_HAND


## Goods on sale: ginger only once you've learned ginger tea.
func goods(stall: Dictionary) -> Array[String]:
	var list: Array[String] = []
	for stock_id in stall["goods"]:
		var needed_for: String = Catalog.MARKET[stock_id].get("for", "")
		if needed_for == "" or _state.menu().has(needed_for):
			list.append(stock_id)
	return list


func hovered() -> String:
	return _hover


func _gui_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null:
		var over := _tile_at(motion.position)
		if over != _hover:
			_hover = over
			queue_redraw()
		return
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	for stock_id in _tiles:
		var tile: Dictionary = _tiles[stock_id]
		if _state.bought_today(stock_id) > 0 and Rect2(tile["undo"]).grow(2.0).has_point(click.position):
			returned.emit(stock_id)
			accept_event()
			return
		if Rect2(tile["rect"]).has_point(click.position):
			bought.emit(stock_id)
			accept_event()
			return


func _tile_at(point: Vector2) -> String:
	for stock_id in _tiles:
		if Rect2(_tiles[stock_id]["rect"]).has_point(point):
			return stock_id
	return ""


func _draw() -> void:
	_tiles.clear()
	var font := get_theme_default_font()
	var widths: Array[float] = []
	var total := 0.0
	for stall in STALLS:
		var w := goods(stall).size() * TILE.x + 12.0
		widths.append(w)
		total += w
	total += STALL_GAP * (STALLS.size() - 1)
	var x := (size.x - total) / 2.0
	var top := maxf(0.0, (size.y - STALL_H) / 2.0)
	for i in STALLS.size():
		_draw_stall(STALLS[i], Rect2(x, top, widths[i], minf(size.y, STALL_H)), font)
		x += widths[i] + STALL_GAP


func _draw_stall(stall: Dictionary, rect: Rect2, font: Font) -> void:
	var awning: Color = stall["awning"]
	# Posts, awning with stripes, sign, counter.
	draw_rect(Rect2(rect.position + Vector2(2, 10), Vector2(3, rect.size.y - 10)), Style.WOOD_EDGE)
	draw_rect(Rect2(rect.position + Vector2(rect.size.x - 5, 10), Vector2(3, rect.size.y - 10)), Style.WOOD_EDGE)
	var stripe_w := 10.0
	var stripes := int(ceil(rect.size.x / stripe_w))
	for s in stripes:
		var color := awning if s % 2 == 0 else Color("f3e3c3")
		var w := minf(stripe_w, rect.size.x - s * stripe_w)
		draw_rect(Rect2(rect.position + Vector2(s * stripe_w, 14), Vector2(w, AWNING_H)), color)
		draw_rect(Rect2(rect.position + Vector2(s * stripe_w, 14 + AWNING_H), Vector2(w, 4)), color.darkened(0.25))
	var sign_text: String = stall["name"]
	var sign_w := font.get_string_size(sign_text, HORIZONTAL_ALIGNMENT_LEFT, -1, Style.FONT_SIZE).x + 12
	var sign_rect := Rect2(rect.position.x + (rect.size.x - sign_w) / 2.0, rect.position.y, sign_w, 15)
	draw_rect(sign_rect, Style.PAPER)
	draw_rect(sign_rect, Style.WOOD_EDGE, false, 1.0)
	draw_string(font, sign_rect.position + Vector2(6, 11), sign_text, HORIZONTAL_ALIGNMENT_LEFT, -1, Style.FONT_SIZE, Style.INK)
	var counter_y := rect.position.y + 44 + TILE.y
	draw_rect(Rect2(rect.position.x, counter_y, rect.size.x, rect.size.y - (counter_y - rect.position.y)), Style.PANEL.lightened(0.08))
	draw_rect(Rect2(rect.position.x, counter_y, rect.size.x, 3), Color("9a6a3c"))
	var items := goods(stall)
	for i in items.size():
		var tile := Rect2(rect.position + Vector2(6 + i * TILE.x, 42), TILE)
		_draw_tile(items[i], tile, font)


func _draw_tile(stock_id: String, tile: Rect2, font: Font) -> void:
	var pack: Dictionary = Catalog.MARKET[stock_id]
	var can_buy := _state.can_afford(stock_id)
	if _hover == stock_id:
		draw_rect(tile.grow(-1), Color(Style.ACCENT, 0.18))
		draw_rect(tile.grow(-1), Style.ACCENT, false, 1.0)
	var icon_at := tile.position + Vector2(tile.size.x / 2.0, 20)
	draw_set_transform(icon_at, 0.0, Vector2(2, 2))
	_draw_goods(stock_id)
	draw_set_transform(Vector2.ZERO)
	if not can_buy:
		draw_rect(Rect2(tile.position + Vector2(4, 4), Vector2(tile.size.x - 8, 34)), Color(Style.BG, 0.55))
	var name_text: String = pack.get("short", pack["name"])
	var name_w := font.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, Style.FONT_SIZE).x
	draw_string(font, tile.position + Vector2((tile.size.x - name_w) / 2.0, 47), name_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, Style.FONT_SIZE, Style.TEXT)
	var price := Style.rupees(pack["cost"])
	var tag := Rect2(tile.position + Vector2(8, 51), Vector2(tile.size.x - 16, 13))
	draw_rect(tag, Style.ACCENT if can_buy else Style.LINE)
	var price_w := font.get_string_size(price, HORIZONTAL_ALIGNMENT_LEFT, -1, Style.FONT_SIZE).x
	draw_string(font, tag.position + Vector2((tag.size.x - price_w) / 2.0, 10), price,
		HORIZONTAL_ALIGNMENT_LEFT, -1, Style.FONT_SIZE, Style.INK if can_buy else Style.MUTED)
	# Stock badge, and an undo dot if bought this morning.
	var have := str(_state.stock[stock_id])
	var badge := Rect2(tile.position + Vector2(tile.size.x - 20, 2), Vector2(18, 12))
	draw_rect(badge, Style.PANEL_DARK)
	var have_w := font.get_string_size(have, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	draw_string(font, badge.position + Vector2((badge.size.x - have_w) / 2.0, 9), have,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Style.TEXT)
	var undo := Rect2(tile.position + Vector2(2, 2), Vector2(12, 12))
	if _state.bought_today(stock_id) > 0:
		draw_rect(undo, Style.BAD)
		draw_rect(Rect2(undo.position + Vector2(3, 5), Vector2(6, 2)), Style.TEXT)
	_tiles[stock_id] = {"rect": tile, "undo": undo}


## Little pictures of each market good, centred on the origin.
func _draw_goods(stock_id: String) -> void:
	match stock_id:
		"milk":
			draw_rect(Rect2(-4, -6, 8, 11), Color("f4f6f8"))
			draw_rect(Rect2(-4, -2, 8, 3), Color("3b7dd8"))
			draw_rect(Rect2(-3, -8, 6, 2), Color("dfe5ea"))
		"tea_powder":
			draw_rect(Rect2(-4, -6, 8, 11), Color("c0392b"))
			draw_rect(Rect2(-3, -3, 6, 4), Color("e8c547"))
		"sugar":
			draw_rect(Rect2(-5, -4, 10, 9), Color("ece6da"))
			draw_rect(Rect2(-4, -6, 8, 2), Color("d9d2c0"))
			draw_rect(Rect2(-2, -1, 4, 3), Color("9aa3ad"))
		"ginger":
			draw_rect(Rect2(-5, -1, 10, 4), Color("d9b46a"))
			draw_rect(Rect2(-2, -4, 3, 3), Color("d9b46a"))
			draw_rect(Rect2(2, -3, 2, 2), Color("c9a45a"))
		"batter":
			draw_rect(Rect2(-5, -3, 10, 8), Color("b8bec6"))
			draw_rect(Rect2(-5, -4, 10, 2), Color("ecdca0"))
		"oil":
			draw_rect(Rect2(-4, -5, 8, 10), Color("e8c547"))
			draw_rect(Rect2(-1, -7, 3, 2), Color("c0392b"))
			draw_rect(Rect2(-3, -1, 6, 3), Color("3a8a3a"))
		"biscuit":
			draw_rect(Rect2(-4, -6, 8, 11), Color(0.9, 0.95, 1.0, 0.5))
			draw_rect(Rect2(-3, -2, 6, 6), Color("d9a55b"))
			draw_rect(Rect2(-4, -7, 8, 2), Color("e0604e"))
		"bun":
			Style.draw_item(self, "bun", Vector2(-2, 1))
			Style.draw_item(self, "bun", Vector2(2, -1))
		"lemon":
			for spot in [Vector2(-3, 2), Vector2(2, 2), Vector2(0, -2)]:
				draw_circle(spot, 2.8, Color("e8d23c"))
				draw_rect(Rect2(spot + Vector2(-1, -1), Vector2(1, 1)), Color("f4eb8a"))
		"coffee_powder":
			draw_rect(Rect2(-4, -6, 8, 11), Color("5a3a22"))
			draw_rect(Rect2(-3, -3, 6, 4), Color("e8c547"))
			draw_rect(Rect2(-1, -2, 2, 2), Color("5a3a22"))
		"besan":
			draw_rect(Rect2(-5, -3, 10, 8), Color("b8bec6"))
			draw_rect(Rect2(-5, -4, 10, 2), Color("e8c56a"))
			draw_rect(Rect2(2, -6, 2, 2), Color("3a8a3a"))
		"samosa":
			Style.draw_item(self, "samosa", Vector2(-2, 1))
			Style.draw_item(self, "samosa", Vector2(3, -1))
