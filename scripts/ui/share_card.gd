class_name ShareCard
extends Control
## A small framed card to screenshot or save and send to friends: a little
## picture of the kadai, the numbers, stars, and a line about the regulars.
## Works for one day or a whole week.

const CARD_SIZE := Vector2(320, 180)
## Saved images are drawn at this many times the card's size, for crispness.
const SAVE_SCALE := 3

## {"title", "subtitle", "stats": [[label, value]], "stars": Array[int], "line"}
var data: Dictionary


func _init(card_data: Dictionary) -> void:
	data = card_data
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE


## The card for today.
static func for_day(state: KadaiState) -> Dictionary:
	var today := state.today
	return {
		"title": "Day %d at the kadai" % state.day,
		"subtitle": Catalog.date_text(state.day),
		"stats": [
			["Customers", str(today["served"])],
			["Perfect pours", str(today["perfect"])],
			["Best streak", str(today["best_streak"])],
			["Takings", Style.rupees(int(today["revenue"]) + int(today["tips"]))],
		],
		"stars": [state.stars_today()],
		"line": _story_line(state),
		"level": state.level(),
	}


## The card for the week that just ended.
static func for_week(state: KadaiState) -> Dictionary:
	var week := state.week
	var goals := state.week_goals()
	var done := goals.filter(func(goal: Dictionary) -> bool: return goal["done"]).size()
	return {
		"title": "Week %d complete!" % Catalog.week_of(state.day),
		"subtitle": "Kadai level %d" % state.level(),
		"stats": [
			["Customers", str(week["served"])],
			["Perfect pours", str(week["perfect"])],
			["Takings", Style.rupees(int(week["revenue"]) + int(week.get("tips", 0)))],
			["Goals", "%d of %d" % [done, goals.size()]],
		],
		"stars": week["stars"],
		"line": _story_line(state),
		"level": state.level(),
	}


static func _story_line(state: KadaiState) -> String:
	for id in Story.REGULAR_ORDER:
		var hook := Story.hook(id, state.day)
		if hook != "" and state.today["met"].has(id):
			return hook
	return "Another day of tea on a busy Chennai street."


## Where cards are saved: the Desktop, or Pictures in the Mac App Store
## build, whose sandbox can't write to the Desktop.
static func folder_name() -> String:
	return "Pictures" if OS.has_feature("app_store") else "Desktop"


## Renders the card off-screen and saves it as a PNG in "folder", by default
## the Desktop (Pictures in the App Store build, or the game's own folder if
## neither exists). Returns the saved path.
static func save_png(host: Node, card_data: Dictionary, file_name: String, folder: String = "") -> String:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(CARD_SIZE) * SAVE_SCALE
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var card := ShareCard.new(card_data)
	card.theme = Style.make_theme()
	card.scale = Vector2(SAVE_SCALE, SAVE_SCALE)
	viewport.add_child(card)
	host.add_child(viewport)
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	viewport.queue_free()
	if folder == "":
		folder = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES if OS.has_feature("app_store") else OS.SYSTEM_DIR_DESKTOP)
	if folder == "" or not DirAccess.dir_exists_absolute(folder):
		folder = OS.get_user_data_dir()
	var path := folder.path_join(file_name)
	image.save_png(path)
	return path


func _draw() -> void:
	var font := get_theme_default_font()
	var rect := Rect2(Vector2.ZERO, CARD_SIZE)
	draw_rect(rect, Style.PAPER)
	draw_rect(rect.grow(-3), Color("c9b48c"), false, 1.0)
	draw_rect(rect, Style.WOOD_EDGE, false, 2.0)
	_draw_kadai(Rect2(10, 10, 110, 110))
	var x := 132.0
	draw_string(font, Vector2(x, 26), str(data["title"]), HORIZONTAL_ALIGNMENT_LEFT, -1, Style.TITLE_SIZE, Style.INK)
	draw_string(font, Vector2(x, 40), str(data["subtitle"]), HORIZONTAL_ALIGNMENT_LEFT, -1, Style.FONT_SIZE, Style.LINE)
	var stats: Array = data["stats"]
	for i in stats.size():
		var y := 60.0 + i * 15.0
		draw_string(font, Vector2(x, y), str(stats[i][0]), HORIZONTAL_ALIGNMENT_LEFT, -1, Style.FONT_SIZE, Style.INK)
		draw_string(font, Vector2(x, y), str(stats[i][1]), HORIZONTAL_ALIGNMENT_RIGHT, 176.0, Style.FONT_SIZE, Style.INK)
	var stars: Array = data["stars"]
	if stars.size() == 1:
		for i in 3:
			Style.draw_symbol(self, "star" if i < int(stars[0]) else "star_empty", Vector2(30 + i * 30, 138), 2.2)
	else:
		# One mini row of stars per day of the week.
		for d in stars.size():
			for i in 3:
				var lit := i < int(stars[d])
				Style.draw_symbol(self, "star" if lit else "star_empty", Vector2(16 + d * 15, 128 + i * 9), 0.7)
	draw_multiline_string(font, Vector2(x, 128), str(data["line"]), HORIZONTAL_ALIGNMENT_LEFT, 176.0,
		Style.FONT_SIZE, 3, Style.INK.lightened(0.15))
	draw_string(font, Vector2(10, 172), "TEA KADAI", HORIZONTAL_ALIGNMENT_LEFT, -1, Style.FONT_SIZE, Style.ACCENT.darkened(0.2))


## A tiny picture of the shop in its building, with steam from the pot.
func _draw_kadai(area: Rect2) -> void:
	draw_rect(area, Color("8fd3f4"))
	draw_rect(Rect2(area.position + Vector2(0, area.size.y - 18), Vector2(area.size.x, 18)), Color("d1b892"))
	var wall := Rect2(area.position + Vector2(14, 16), Vector2(82, 76))
	draw_rect(wall, Style.TEA.lightened(0.1) if int(data.get("level", 1)) < 2 else Color("2f7fb5"))
	draw_rect(Rect2(wall.position + Vector2(10, 8), Vector2(16, 14)), Color("2a3a48"))
	draw_rect(Rect2(wall.position + Vector2(56, 8), Vector2(16, 14)), Color("2a3a48"))
	draw_rect(Rect2(wall.position + Vector2(12, 34), Vector2(58, 8)), Color("e8c547"))
	draw_rect(Rect2(wall.position + Vector2(10, 46), Vector2(62, 30)), Color("e8d9b8"))
	for i in 6:
		draw_rect(Rect2(wall.position + Vector2(14 + i * 9, 50), Vector2(5, 6)), [Color("e0604e"), Color("7cc46a"), Color("4a90d9")][i % 3])
	for s in 8:
		var color := Color("3b6fc4") if s % 2 == 0 else Color("f3e3c3")
		draw_rect(Rect2(wall.position + Vector2(4 + s * 9.5, 42), Vector2(9.5, 6)), color)
	draw_rect(Rect2(wall.position + Vector2(6, 66), Vector2(70, 12)), Color("9a6a3c"))
	draw_rect(Rect2(wall.position + Vector2(52, 58), Vector2(10, 8)), Color("b8863b"))
	for i in 3:
		draw_rect(Rect2(wall.position + Vector2(53 + i * 3, 48 - i * 3), Vector2(1, 5)), Color(1, 1, 1, 0.7))
	draw_rect(area, Style.WOOD_EDGE, false, 1.0)
