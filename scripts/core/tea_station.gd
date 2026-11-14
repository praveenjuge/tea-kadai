class_name TeaStation
extends RefCounted
## Makes one glass of tea at a time: decoction, sugar, milk, then the long pour.
## The pour is the skill part: hold to pull the tumbler up, and let go while
## the stream is in the green zone for a good froth.

signal poured(quality: float, label: String)

enum Stage { EMPTY, GLASS, DECOCTION, SUGAR, MILK, POURING }

## Seconds of holding to pull the tumbler all the way up and spill.
const POUR_SECONDS := 1.5
const TARGET_WIDTH := 0.17

var stage := Stage.EMPTY
## 0 = tumbler at the glass, 1 = full stretch (spills).
var pour_height := 0.0
## Low and high edge of the green zone on the pour meter.
var target := Vector2(0.6, 0.6 + TARGET_WIDTH)
var _pour_time := 0.0


## Text for the button that does the next step.
func next_action() -> String:
	match stage:
		Stage.EMPTY:
			return "New glass"
		Stage.GLASS:
			return "Decoction"
		Stage.DECOCTION:
			return "Sugar"
		Stage.SUGAR:
			return "Milk"
		Stage.MILK:
			return "Now pour!"
		_:
			return "Let go in green"


## Places a new glass. The caller takes the stock for it first.
func start(rng: RandomNumberGenerator) -> void:
	stage = Stage.GLASS
	var low := rng.randf_range(0.5, 0.7)
	target = Vector2(low, low + TARGET_WIDTH)


## Adds the next ingredient. Returns false when there is nothing to add.
func add_next() -> bool:
	match stage:
		Stage.GLASS:
			stage = Stage.DECOCTION
		Stage.DECOCTION:
			stage = Stage.SUGAR
		Stage.SUGAR:
			stage = Stage.MILK
		_:
			return false
	return true


func can_pour() -> bool:
	return stage == Stage.MILK


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
	if stage != Stage.POURING:
		return
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
