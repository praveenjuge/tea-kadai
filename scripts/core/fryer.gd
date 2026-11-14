class_name Fryer
extends RefCounted
## A kadai of hot oil. Vadai fry together in one batch: drop them in, then lift
## the whole batch out once it turns golden.

enum Doneness { EMPTY, RAW, GOLDEN, BURNT }

const BATCH := 4
const GOLDEN_AT := 8.0
const BURNT_AT := 18.0

## How many vadai are in the oil right now.
var count := 0
## Seconds the current batch has been frying.
var time := 0.0


func is_empty() -> bool:
	return count == 0


## Drops a batch in. The caller takes the stock first.
func drop(amount: int) -> void:
	count = amount
	time = 0.0


func update(delta: float) -> void:
	if count > 0:
		time += delta


func doneness() -> Doneness:
	if count == 0:
		return Doneness.EMPTY
	if time < GOLDEN_AT:
		return Doneness.RAW
	if time < BURNT_AT:
		return Doneness.GOLDEN
	return Doneness.BURNT


## 0..1 while raw, 1..2 while golden, 2 once burnt. Used for drawing.
func cook_level() -> float:
	if count == 0:
		return 0.0
	if time < GOLDEN_AT:
		return time / GOLDEN_AT
	if time < BURNT_AT:
		return 1.0 + (time - GOLDEN_AT) / (BURNT_AT - GOLDEN_AT)
	return 2.0


## Lifts the whole batch out and empties the kadai.
func take() -> Dictionary:
	var result := {"doneness": doneness(), "count": count}
	count = 0
	time = 0.0
	return result
