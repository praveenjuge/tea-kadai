class_name TeaStation
extends RefCounted
## Makes one glass of tea at a time. One press fills the glass with decoction,
## sugar and milk; then comes the pour, the skill part. Hold to pull the
## tumbler up and let go while the stream is in the green zone.

signal poured(quality: float, label: String)

enum Stage { EMPTY, FILLING, READY, POURING }

## Seconds the glass takes to fill after pressing.
const FILL_SECONDS := 0.5
## Seconds of holding to pull the tumbler all the way up and spill.
const POUR_SECONDS := 1.5
const TARGET_WIDTH := 0.17

var stage := Stage.EMPTY
## Which tea is in the glass: "tea" or "ginger_tea".
var kind := "tea"
## Seconds a glass takes to fill. The bigger milk pot halves it.
var fill_seconds := FILL_SECONDS
## 0 = tumbler at the glass, 1 = full stretch (spills).
var pour_height := 0.0
## Low and high edge of the green zone on the pour meter.
var target := Vector2(0.6, 0.6 + TARGET_WIDTH)
var _fill_time := 0.0
var _pour_time := 0.0


## Text for the tea button.
func action_text() -> String:
	match stage:
		Stage.EMPTY:
			return "Make tea"
		Stage.FILLING:
			return "Filling…"
		Stage.READY:
			return "Hold to pour"
		_:
			return "Let go in green!"


## 0 to 1 while the glass fills, 1 once it's full.
func fill_progress() -> float:
	if stage == Stage.FILLING:
		return _fill_time / fill_seconds
	return 0.0 if stage == Stage.EMPTY else 1.0


## Starts filling a new glass. The caller takes the stock for it first.
func start(rng: RandomNumberGenerator, tea_kind: String = "tea") -> void:
	kind = tea_kind
	stage = Stage.FILLING
	_fill_time = 0.0
	var low := rng.randf_range(0.5, 0.7)
	target = Vector2(low, low + TARGET_WIDTH)


func can_pour() -> bool:
	return stage == Stage.READY


func begin_pour() -> bool:
	if not can_pour():
		return false
	stage = Stage.POURING
	_pour_time = 0.0
	pour_height = 0.0
	return true


func release_pour() -> void:
	if stage == Stage.POURING:
		_finish()


func update(delta: float) -> void:
	if stage == Stage.FILLING:
		_fill_time += delta
		if _fill_time >= fill_seconds:
			stage = Stage.READY
	elif stage == Stage.POURING:
		_pour_time += delta
		# Speeds up near the top, so a long pour needs a steady hand.
		pour_height = pow(_pour_time / POUR_SECONDS, 1.4)
		if pour_height >= 1.0:
			pour_height = 1.0
			_finish()


func _finish() -> void:
	var h := pour_height
	var quality := 0.5
	var label := "Flat tea"
	if h >= 1.0:
		quality = 0.3
		label = "Spilled!"
	elif h >= target.x and h <= target.y:
		quality = 1.0
		label = "Perfect froth!"
	elif h > target.y or h >= target.x - 0.12:
		quality = 0.75
		label = "Good pour"
	stage = Stage.EMPTY
	poured.emit(quality, label)
