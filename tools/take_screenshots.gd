extends SceneTree
## Takes the screenshots for the README and the website by running the real
## game with a grown kadai: the title, the morning market, a morning rush,
## the night tally and the Grow shop.
## Uses its own save and settings files, so a player's save is never touched.
## Needs a window (not --headless):
##   godot --path . -s tools/take_screenshots.gd
## With "-- --clip" it instead plays a few seconds of the rainy evening rush,
## with a full counter while the cousin pours, to record with Godot's movie
## writer. It prints the frame the clip starts on, so the fast-forward before
## it can be cut:
##   godot --path . --write-movie /tmp/clip/frame.png --fixed-fps 30 -s tools/take_screenshots.gd -- --clip
## Then, with N the printed start frame (website/public/screenshots/rainy-rush.*):
##   ffmpeg -framerate 30 -start_number N -i /tmp/clip/frame%08d.png -frames:v 348 -c:v libx264 -crf 22 \
##     -tune animation -pix_fmt yuv420p -movflags +faststart -an rainy-rush.mp4
##   ffmpeg -framerate 30 -start_number N -i /tmp/clip/frame%08d.png -frames:v 348 -vf "fps=15,scale=640:360:flags=neighbor,
##     split[a][b];[a]palettegen=max_colors=128:stats_mode=diff[p];[b][p]paletteuse=dither=none:diff_mode=rectangle" rainy-rush.gif

const OUT_DIR := "res://website/public/screenshots/"
const SIZE := Vector2i(1280, 720)
## Fast-forward speed while waiting for a moment in the day.
const RUSH := 12.0
const CLIP_SECONDS := 12.0

var _main: Control


func _init() -> void:
	SaveGame.path = "user://screenshot_save.json"
	Settings.path = "user://screenshot_settings.cfg"
	_main = load("res://main.tscn").instantiate()
	root.add_child(_main)
	_run.call_deferred()


func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	DisplayServer.window_set_size(SIZE)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var state := _grown_kadai()
	if "--clip" in OS.get_cmdline_user_args():
		await _clip(state)
		return
	SaveGame.save(state)
	_main._show_title()
	await _settle(3.0)
	await _shoot("title")

	_main.state = state
	_main._show_morning()
	await _settle(2.0)
	await _shoot("market")

	_main._show_service()
	await _settle(1.0)
	var service: Service = _main._screen._service
	await _until(func() -> bool: return service.clock.minutes() >= 490.0)
	await _settle(0.6)
	await _shoot("morning-rush")

	# Without a chai boy, customers wait at the counter with their orders up,
	# which makes for a busier street. The next day the whole staff works, so
	# the night tally has a full day's takings.
	await _until(func() -> bool: return _main._screen is NightScreen)
	state.staff.assign(Catalog.STAFF_ORDER)
	_main._on_next_day()
	await _settle(1.0)
	_main._show_service()
	await _settle(1.0)
	await _until(func() -> bool: return _main._screen is NightScreen)
	await _settle(4.0)
	await _shoot("night")

	_main._open_shop(_main._screen)
	await _settle(0.8)
	await _shoot("grow")

	SaveGame.delete()
	quit()


func _clip(state: KadaiState) -> void:
	_main.state = state
	_main._show_service()
	await _settle(1.0)
	var service: Service = _main._screen._service
	await _until(func() -> bool: return service.is_raining() and service.clock.minutes() >= service.rain.x + 15.0)
	print("Clip starts at frame ", Engine.get_frames_drawn())
	await _settle(CLIP_SECONDS)
	print("Clip ends at frame ", Engine.get_frames_drawn())
	SaveGame.delete()
	quit()


## A kadai about ten days in: every upgrade, a cousin making drinks and a
## vadai master at the fryer, a few helpers, and Karthik as a friend. The day
## is one with evening rain.
func _grown_kadai() -> KadaiState:
	var day := 9
	while day % 7 == 0 or Catalog.rain_for_day(day).x < 990.0:
		day += 1
	var stock := {}
	for stock_id in Catalog.MARKET:
		stock[stock_id] = 200
	return KadaiState.from_dict({
		"day": day, "money": 6400, "stock": stock, "reputation": 700,
		"upgrades": Catalog.UPGRADE_ORDER, "recipes": ["ginger_tea"],
		"regulars": {"karthik": {"friendship": 60, "visits": 9, "flags": {"taught": true}}},
		"helpers": {"flask_boy": 6, "office_runner": 3, "bus_cart": 1},
		"staff": ["cousin", "vadai_master"], "boosts": ["steel_flasks"],
		"earned_total": 38000, "branch_earned": 38000,
	})


func _until(done: Callable) -> void:
	Engine.time_scale = RUSH
	while not done.call():
		await process_frame
	Engine.time_scale = 1.0


func _settle(seconds: float) -> void:
	Engine.time_scale = 1.0
	await create_timer(seconds).timeout


func _shoot(shot_name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.get_size() != SIZE:
		image.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_NEAREST)
	var path := OUT_DIR + shot_name + ".png"
	image.save_png(path)
	print("Saved ", path)
