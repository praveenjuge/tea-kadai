class_name SoundBoard
extends Node
## Plays the kadai's sounds: one-shot effects for things that happen, the pour
## and sizzle loops, street ambience with the odd crow, horn or bicycle bell,
## and music that turns from day to night. The sounds are files in
## assets/sounds, so real recordings can replace them by name.

const DIR := "res://assets/sounds/"
## Loudness of each sound in dB, balanced by measured loudness: sounds that
## play often (coins, filling a glass) sit lower, rare rewards a bit higher,
## and the street and music stay underneath.
const VOLUME := {
	"fill": -13.0, "perfect": -8.0, "good": -12.0, "flat": -13.0, "spill": -8.0,
	"golden": -10.0, "lift": -10.0, "burnt": -17.0, "coin": -19.0, "arrive": -16.0,
	"grumble": -18.0, "crow": -20.0, "horn": -22.0, "bell": -22.0,
	"pour_loop": -12.0, "sizzle_loop": -21.0, "street_loop": -19.0, "rain_loop": -16.0,
	"music_day": -16.0, "music_night": -19.0, "rush_loop": -20.0,
}
## How fast each loop fades in and out, in full volume per second.
const LOOP_FADE := {
	"pour_loop": 12.0, "sizzle_loop": 3.0, "street_loop": 0.5, "rain_loop": 0.4,
	"music_day": 0.35, "music_night": 0.35, "rush_loop": 0.5,
}
## Which volume bus each sound plays on; anything not listed is an effect.
const BUS := {
	"music_day": "Music", "music_night": "Music", "rush_loop": "Music",
	"street_loop": "Street", "rain_loop": "Street", "crow": "Street", "horn": "Street", "bell": "Street",
}
## Game events and the sound each one plays.
const EVENTS := {
	"tea_filling": "fill", "poured_perfect": "perfect", "poured_good": "good",
	"poured_flat": "flat", "spilled": "spill", "vadai_drop": "lift", "vadai_golden": "golden",
	"vadai_lifted": "lift", "vadai_burnt": "burnt", "paid": "coin", "arrive": "arrive",
	"grumble": "grumble", "streak": "golden", "friendship": "bell", "recipe": "golden", "treat": "perfect",
}
const STREET_SOUNDS: Array[String] = ["crow", "crow", "horn", "bell"]
const STREET_GAP := Vector2(6.0, 16.0)
## Music turns from day to night between these kadai clock minutes.
const DUSK_FROM := 1080.0
const DUSK_TO := 1200.0

var _streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _loops := {}
var _level := {}
var _target := {}
var _street := false
var _street_timer := 4.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	for sound_name in VOLUME:
		var stream: AudioStreamWAV = load(DIR + sound_name + ".wav")
		if LOOP_FADE.has(sound_name):
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = int(stream.get_length() * stream.mix_rate)
		_streams[sound_name] = stream
	for i in 8:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_pool.append(player)
	for loop_name in LOOP_FADE:
		var player := AudioStreamPlayer.new()
		player.stream = _streams[loop_name]
		player.bus = BUS.get(loop_name, "Effects")
		add_child(player)
		_loops[loop_name] = player
		_level[loop_name] = 0.0
		_target[loop_name] = 0.0


func play(sound_name: String, pitch: float = 1.0) -> void:
	for player in _pool:
		if not player.playing:
			player.stream = _streams[sound_name]
			player.bus = BUS.get(sound_name, "Effects")
			player.volume_db = VOLUME[sound_name]
			player.pitch_scale = pitch
			player.play()
			return


## Plays the sound for a game event, if it has one. Perfect pours rise in
## pitch as a streak builds.
func on_event(event: String, amount: int = 0) -> void:
	if not EVENTS.has(event):
		return
	var pitch := _rng.randf_range(0.96, 1.04)
	if event == "poured_perfect":
		pitch = 1.0 + 0.06 * mini(maxi(amount - 1, 0), 8)
	play(EVENTS[event], pitch)


## Fades a loop towards a level from 0 (silent) to 1 (full).
func set_loop(loop_name: String, level: float, pitch: float = 1.0) -> void:
	_target[loop_name] = level
	_loops[loop_name].pitch_scale = pitch


## "morning", "service" or "night".
func set_scene(scene: String) -> void:
	_street = scene == "service"
	set_loop("street_loop", 1.0 if _street else 0.0)
	set_loop("pour_loop", 0.0)
	set_loop("sizzle_loop", 0.0)
	set_loop("rain_loop", 0.0)
	set_rush(false)
	if scene == "night":
		set_time_of_day(DUSK_TO)
	elif scene == "morning":
		set_time_of_day(0.0)


## Cross-fades from the day music to the night music as evening comes.
func set_time_of_day(minutes: float) -> void:
	var night := clampf((minutes - DUSK_FROM) / (DUSK_TO - DUSK_FROM), 0.0, 1.0)
	set_loop("music_day", 1.0 - night)
	set_loop("music_night", night)


## A percussion layer over the music during the rushes.
func set_rush(on: bool) -> void:
	set_loop("rush_loop", 1.0 if on else 0.0)


## The rush beat starts in step with the day music.
func _start_position(loop_name: String) -> float:
	var music: AudioStreamPlayer = _loops["music_day"]
	if loop_name == "rush_loop" and music.playing:
		return fmod(music.get_playback_position(), _streams["rush_loop"].get_length())
	return 0.0


## Stops everything, so nothing is still playing when the game closes.
func stop_all() -> void:
	_street = false
	for player in _pool:
		player.stop()
		player.stream = null
	for loop_name in _loops:
		_loops[loop_name].stop()
		_loops[loop_name].stream = null


func toggle_mute() -> bool:
	var muted := not AudioServer.is_bus_mute(0)
	AudioServer.set_bus_mute(0, muted)
	return muted


func _process(delta: float) -> void:
	for loop_name in _loops:
		var level := move_toward(_level[loop_name], _target[loop_name], delta * float(LOOP_FADE[loop_name]))
		_level[loop_name] = level
		var player: AudioStreamPlayer = _loops[loop_name]
		if level > 0.001:
			player.volume_db = float(VOLUME[loop_name]) + linear_to_db(level)
			if not player.playing:
				player.play(_start_position(loop_name))
		elif player.playing:
			player.stop()
	if _street:
		_street_timer -= delta
		if _street_timer <= 0.0:
			_street_timer = _rng.randf_range(STREET_GAP.x, STREET_GAP.y)
			play(STREET_SOUNDS[_rng.randi() % STREET_SOUNDS.size()], _rng.randf_range(0.9, 1.1))
