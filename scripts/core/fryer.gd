class_name Fryer
extends RefCounted
## A kadai of hot oil. Snacks fry together in one batch, vadai or bajji: drop
## them in, then lift the whole batch out once it turns golden.

enum Doneness { EMPTY, RAW, GOLDEN, BURNT }

const BATCH := 4

## What's frying: "vadai" or "bajji".
var kind := "vadai"
## How many are in the oil right now.
var count := 0
## Seconds the current batch has been frying.
var time := 0.0


func is_empty() -> bool:
	return count == 0


## Drops a batch in. The caller takes the stock first.
func drop(amount: int, snack: String = "vadai") -> void:
	kind = snack
	count = amount
	time = 0.0


func update(delta: float) -> void:
	if count > 0:
		time += delta


func golden_at() -> float:
	return Catalog.FRY_TIMES[kind].x


func burnt_at() -> float:
	return Catalog.FRY_TIMES[kind].y


func doneness() -> Doneness:
	if count == 0:
		return Doneness.EMPTY
	if time < golden_at():
		return Doneness.RAW
	if time < burnt_at():
		return Doneness.GOLDEN
	return Doneness.BURNT


## 0..1 while raw, 1..2 while golden, 2 once burnt. Used for drawing.
func cook_level() -> float:
	if count == 0:
		return 0.0
	if time < golden_at():
		return time / golden_at()
	if time < burnt_at():
		return 1.0 + (time - golden_at()) / (burnt_at() - golden_at())
	return 2.0


## Lifts the whole batch out and empties the kadai.
func take() -> Dictionary:
	var result := {"doneness": doneness(), "count": count, "kind": kind}
	count = 0
	time = 0.0
	return result
