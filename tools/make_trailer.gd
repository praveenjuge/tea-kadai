extends SceneTree
## Plays a one-minute trailer through the real game, with captions, for
## Godot's movie writer to record: the title, the morning market, pouring and
## frying through a rush, a golden glass frenzy, hiring helpers, a Karthigai
## Deepam street with the radio on, the night tally, a grand kadai with
## fireworks and trophies, and an end card.
## Uses its own save and settings, so a player's save is never touched.
##   godot --path . --resolution 1920x1080 --write-movie /tmp/trailer/frame.png --fixed-fps 30 -s tools/make_trailer.gd
##   ffmpeg -framerate 30 -i /tmp/trailer/frame%08d.png -i /tmp/trailer/frame.wav -c:v libx264 -crf 20 \
##     -tune animation -pix_fmt yuv420p -c:a aac -b:a 160k -shortest -movflags +faststart website/public/trailer.mp4

var _main: Control
var _caption: Caption


func _init() -> void:
	SaveGame.path = "user://trailer_save.json"
	Settings.path = "user://trailer_settings.cfg"
	SaveGame.delete()
	_main = load("res://main.tscn").instantiate()
	root.add_child(_main)
	var layer := CanvasLayer.new()
	layer.layer = 20
	root.add_child(layer)
	_caption = Caption.new()
	_caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_caption)
	_run.call_deferred()


func _run() -> void:
	await _wait(1.0)
	_caption.theme = _main.theme
	var state := _kadai(9)
	SaveGame.save(state)

	# Title, with the news ticker running.
	_main._show_title()
	await _wait(1.2)
	_caption.show_text("A little tea stall on a busy Chennai street", "")
	await _wait(3.6)

	# The morning paper and the market.
	_main.state = state
	await _swap(_main._show_morning)
	_caption.show_text("Every morning: the paper, the market", "Stock up on milk, tea dust, batter and buns")
	await _wait(4.5)

	# The morning rush: pour, fry, serve.
	await _swap(_main._show_service)
	var service: Service = _main._screen._service
	service.clock.elapsed = 40.0
	_caption.show_text("Pour from up high", "Let go in the green for the perfect glass")
	await _play(service, 5.5)
	_caption.show_text("Fry vadai. Serve the rush.", "Auto drivers, students, nurses, and the regulars")
	await _play(service, 5.5)

	# A golden glass, then a frenzy.
	_caption.show_text("Catch the golden glass", "")
	service._golden_timer = 0.0
	await _play(service, 1.6)
	service.rng.seed = 2
	service.frenzy = 0.0
	_main._screen._on_golden_clicked()
	if service.frenzy <= 0.0:
		service.frenzy = Catalog.FRENZY_SECONDS
		_main._screen._effects.banner("Frenzy! Helpers earn %dx!" % Catalog.FRENZY_TIMES, Style.WARN)
	await _play(service, 3.4)

	# Grow: buy helpers, then watch them out on the street.
	_main._screen._open_shop()
	_caption.show_text("Hire helpers", "Flask boys, tea runners, carts. They earn while you pour.")
	var shop: HelpersShop = _main._screen._shop
	for id in ["flask_boy", "office_runner", "bus_cart", "flask_boy"]:
		await _wait(0.7)
		state.money += state.helper_cost(id)
		if state.buy_helper(id):
			shop.bought.emit("helper")
			shop._show_tab("Helpers")
	await _wait(1.0)
	shop.close()
	await _play(service, 3.0)

	# Chennai: Karthigai Deepam, a big kolam, the radio on.
	var festival := _kadai(32)
	_main.state = festival
	await _swap(_main._show_service)
	service = _main._screen._service
	service.clock.elapsed = 55.0
	_caption.show_text("Kolams, festivals, film Fridays", "and cricket on the radio")
	await _play(service, 1.5)
	service.message.emit("Radio commentary: SIX! Out of the stadium!")
	service.happened.emit("cheer", 0)
	await _play(service, 4.5)

	# Night under the moon.
	festival.today["served"] = 46
	festival.today["perfect"] = 21
	festival.today["revenue"] = 1840
	festival.today["tips"] = 164
	festival.today["helpers"] = 2600
	festival.today["spent"] = 420
	festival.today["points"] = 96
	festival.today["best_streak"] = 7
	festival.today["met"] = ["karthik", "murugan"]
	await _swap(_main._show_night)
	_caption.show_text("Count the day's takings under the moon", "")
	await _wait(6.0)

	# A grand kadai, trophies and a big number.
	var grand := _kadai(41)
	grand.big_numbers_seen = 6
	grand.earned_total = 2000000000
	grand.upgrades.assign(Catalog.UPGRADE_ORDER)
	for id in Catalog.HELPER_ORDER:
		grand.helpers[id] = 30
	grand.check_achievements()
	_main.state = grand
	await _swap(_main._show_service)
	service = _main._screen._service
	service.clock.elapsed = 260.0
	_caption.show_text("40 trophies. From one lakh to one padma.", "Open branches all over Chennai")
	await _play(service, 1.0)
	_main._screen._effects.trophy("Trophy: Tea empire  (+1%)")
	await _play(service, 1.2)
	service.big_number.emit(Milestones.BIG_NUMBERS[5])
	await _play(service, 3.8)

	# The end card.
	_caption.show_end()
	await _wait(5.5)
	SaveGame.delete()
	quit()


## A kadai a little way in, on this day, with a full stock room.
func _kadai(day: int) -> KadaiState:
	var stock := {}
	for stock_id in Catalog.MARKET:
		stock[stock_id] = 200
	return KadaiState.from_dict({
		"day": day, "money": 9400, "stock": stock, "reputation": 700,
		"upgrades": ["bench", "pot", "paint", "plants", "fan", "radio"], "recipes": ["ginger_tea"],
		"regulars": {"karthik": {"friendship": 60, "visits": 9, "flags": {"taught": true}},
			"murugan": {"friendship": 30, "visits": 3, "flags": {}}},
		"helpers": {"flask_boy": 8, "office_runner": 3}, "earned_total": 60000, "branch_earned": 60000,
	})


## Switches screens and waits until the new one is fully up.
func _swap(show: Callable) -> void:
	_caption.hide_text()
	var before = _main._screen
	show.call()
	await process_frame
	while _main._screen == before or _main.covered():
		await process_frame
	await _wait(0.2)


## Plays the counter well for a while: perfect pours, golden vadai, serving.
func _play(service: Service, seconds: float) -> void:
	var done := [false]
	create_timer(seconds).timeout.connect(func() -> void: done[0] = true)
	while not done[0]:
		if not service.closed:
			_turn(service)
		await process_frame


func _turn(service: Service) -> void:
	var tea := service.tea
	if tea.stage == TeaStation.Stage.POURING:
		if tea.pour_height >= (tea.target.x + tea.target.y) / 2.0:
			service.tea_release()
	elif tea.can_pour():
		service.tea_press()
	elif tea.stage == TeaStation.Stage.EMPTY and service.glasses_ready() < 3:
		service.set_tea_kind(service.drinks()[0])
		service.tea_press()
	var fry := service.fryer.doneness()
	if fry == Fryer.Doneness.GOLDEN:
		service.fry_press()
	elif fry == Fryer.Doneness.EMPTY and service.fries_ready() < 3:
		service.fry_press()
	for seat in service.seats.size():
		var customer = service.seats[seat]
		if customer != null:
			customer["usual_hidden"] = false
			service.answer(seat, 0)
		if service.can_fill(seat):
			service.serve(seat)


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


## Captions over the game: a lower-third line with a smaller one under it,
## and the end card.
class Caption extends Control:
	const BAND := 46.0

	var _title := ""
	var _sub := ""
	var _shown := 0.0
	var _target := 0.0
	var _end := 0.0
	var _icon: Texture2D

	func _init() -> void:
		mouse_filter = MOUSE_FILTER_IGNORE
		_icon = load("res://assets/icon.png")

	func show_text(title: String, sub: String) -> void:
		_title = title
		_sub = sub
		_shown = 0.0
		_target = 1.0

	func hide_text() -> void:
		_target = 0.0

	func show_end() -> void:
		_target = 0.0
		var fade := create_tween()
		fade.tween_property(self, "_end", 1.0, 0.6)

	func _process(delta: float) -> void:
		_shown = move_toward(_shown, _target, delta * 4.0)
		queue_redraw()

	func _draw() -> void:
		var font := Style.font()
		if _shown > 0.0 and _title != "":
			var y := size.y - BAND - 14.0 + (1.0 - ease(_shown, 0.4)) * 20.0
			var band := Rect2(0, y, size.x, BAND)
			draw_rect(band, Color(Style.BG, 0.82 * _shown))
			draw_rect(Rect2(0, y, size.x, 2), Color(Style.ACCENT, _shown))
			_centered(font, _title, y + 21, Style.TITLE_SIZE + 2, Color(Style.ACCENT, _shown))
			if _sub != "":
				_centered(font, _sub, y + 37, Style.FONT_SIZE, Color(Style.TEXT, _shown))
		if _end > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(Style.BG, _end))
			var mid := size / 2.0
			draw_texture_rect(_icon, Rect2(mid + Vector2(-32, -110), Vector2(64, 64)), false, Color(1, 1, 1, _end))
			_centered(font, "TEA KADAI", mid.y - 10, Style.HERO_SIZE, Color(Style.ACCENT, _end))
			_centered(font, "Free on Mac, Windows and Linux", mid.y + 18, Style.TITLE_SIZE, Color(Style.TEXT, _end))
			_centered(font, "tea-kadai.praveenjuge.com", mid.y + 44, Style.FONT_SIZE + 2, Color(Style.GOOD, _end))

	func _centered(font: Font, text: String, baseline: float, font_size: int, color: Color) -> void:
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var at := Vector2((size.x - width) / 2.0, baseline)
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(Style.BG, color.a))
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
