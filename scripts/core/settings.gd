class_name Settings
extends RefCounted
## Player settings: volume for music, effects and street sounds, fullscreen,
## and whether the game updates itself.
## Stored in a small config file and applied to the audio buses and window.

const BUSES: Array[String] = ["Music", "Effects", "Street"]

## Tests point this somewhere else so they never touch a player's settings.
static var path := "user://settings.cfg"

## Volume per bus name, from 0 to 1.
var volume := {"Music": 0.8, "Effects": 1.0, "Street": 0.8}
var fullscreen := false
## Download new versions in the background (GitHub builds only).
var auto_update := true


static func load_saved() -> Settings:
	var settings := Settings.new()
	var config := ConfigFile.new()
	if config.load(path) == OK:
		for bus in BUSES:
			settings.volume[bus] = clampf(float(config.get_value("audio", bus, settings.volume[bus])), 0.0, 1.0)
		settings.fullscreen = bool(config.get_value("display", "fullscreen", false))
		settings.auto_update = bool(config.get_value("updates", "auto", true))
	return settings


func save() -> void:
	var config := ConfigFile.new()
	for bus in BUSES:
		config.set_value("audio", bus, volume[bus])
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("updates", "auto", auto_update)
	config.save(path)


## Makes sure the audio buses exist and sets their volumes.
func apply_audio() -> void:
	for bus in BUSES:
		var index := AudioServer.get_bus_index(bus)
		if index < 0:
			AudioServer.add_bus()
			index = AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, "Master")
		var level: float = volume[bus]
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(level, 0.0001)))
		AudioServer.set_bus_mute(index, level <= 0.001)


func apply_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
