class_name EffectsLayer
extends Control
## Little flourishes drawn over the service screen: coins flying to the money
## counter, sparkles on a perfect pour, and a banner when the day changes pace.

signal coin_landed

const COIN_SECONDS := 0.6
const SPARKLE_SECONDS := 0.5
const BANNER_SECONDS := 2.0

var _coins: Array[Dictionary] = []
var _sparks: Array[Dictionary] = []
var _banner := {}
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	_rng.randomize()


## A few coins arc from "from" to "to" (both in this layer's coordinates).
func fly_coins(from: Vector2, to: Vector2, count: int) -> void:
	for i in clampi(count, 1, 6):
		var lift := _rng.randf_range(40.0, 80.0)
		_coins.append({"from": from + Vector2(_rng.randf_range(-6, 6), 0), "to": to,
			"lift": lift, "t": -i * 0.06})


func sparkle(at: Vector2) -> void:
	for i in 8:
		var angle := TAU * i / 8.0 + _rng.randf_range(-0.2, 0.2)
		_sparks.append({"at": at, "dir": Vector2(cos(angle), sin(angle)), "t": 0.0})


func banner(text: String, color: Color) -> void:
	_banner = {"text": text, "color": color, "t": 0.0}


func _process(delta: float) -> void:
	for coin in _coins:
		coin["t"] += delta
		if coin["t"] >= COIN_SECONDS and not coin.get("landed", false):
			coin["landed"] = true
			coin_landed.emit()
	_coins = _coins.filter(func(c: Dictionary) -> bool: return not c.get("landed", false))
	for spark in _sparks:
		spark["t"] += delta
	_sparks = _sparks.filter(func(s: Dictionary) -> bool: return s["t"] < SPARKLE_SECONDS)
	if not _banner.is_empty():
		_banner["t"] += delta
		if _banner["t"] > BANNER_SECONDS:
			_banner = {}
	queue_redraw()


func _draw() -> void:
	for coin in _coins:
		var t := clampf(coin["t"] / COIN_SECONDS, 0.0, 1.0)
		if coin["t"] < 0.0:
			continue
		var from: Vector2 = coin["from"]
		var to: Vector2 = coin["to"]
		var at := from.lerp(to, ease(t, 0.6)) - Vector2(0, sin(t * PI) * float(coin["lift"]))
		Style.draw_symbol(self, "coin", at, 1.2)
	for spark in _sparks:
		var t: float = spark["t"] / SPARKLE_SECONDS
		var dir: Vector2 = spark["dir"]
		var at: Vector2 = spark["at"] + dir * (4.0 + t * 16.0)
		var size := 2.0 * (1.0 - t)
		draw_rect(Rect2(at - Vector2(size, size) / 2.0, Vector2(size, size) * 1.5), Color(Style.FROTH, 1.0 - t))
	if not _banner.is_empty():
		_draw_banner()


func _draw_banner() -> void:
	var t: float = _banner["t"]
	var slide := clampf(t / 0.25, 0.0, 1.0)
	var out := clampf((t - (BANNER_SECONDS - 0.3)) / 0.3, 0.0, 1.0)
	var font := get_theme_default_font()
	var text: String = _banner["text"]
	var font_size := Style.TITLE_SIZE + 4
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 40.0
	var x := lerpf(-width, (size.x - width) / 2.0, ease(slide, 0.4)) + out * size.x
	var rect := Rect2(x, 46, width, 26)
	var color: Color = _banner["color"]
	draw_rect(rect, Color(Style.BG, 0.85))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2)), color)
	draw_rect(Rect2(rect.position + Vector2(0, rect.size.y - 2), Vector2(rect.size.x, 2)), color)
	draw_string_outline(font, rect.position + Vector2(20, 19), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Style.BG)
	draw_string(font, rect.position + Vector2(20, 19), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
