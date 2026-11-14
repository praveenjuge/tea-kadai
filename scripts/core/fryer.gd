class_name Fryer
extends RefCounted
## A kadai of hot oil with a few spots for vadai. Take them out when golden.

enum Doneness { EMPTY, RAW, GOLDEN, BURNT }

const SLOTS := 3
const GOLDEN_AT := 7.0
const BURNT_AT := 13.0

## Seconds each slot has been frying, or -1 when empty.
var slots: Array[float] = []


func _init() -> void:
	for i in SLOTS:
		slots.append(-1.0)


func free_slot() -> int:
	return slots.find(-1.0)


## Drops a vadai into the first free slot. The caller takes the stock first.
func drop() -> int:
	var slot := free_slot()
	if slot >= 0:
		slots[slot] = 0.0
	return slot


func update(delta: float) -> void:
	for i in SLOTS:
		if slots[i] >= 0.0:
			slots[i] += delta


func doneness(slot: int) -> Doneness:
	var t := slots[slot]
	if t < 0.0:
		return Doneness.EMPTY
	if t < GOLDEN_AT:
		return Doneness.RAW
	if t < BURNT_AT:
		return Doneness.GOLDEN
	return Doneness.BURNT


## 0..1 while raw, 1..2 while golden, 2+ once burnt. Used for drawing.
func cook_level(slot: int) -> float:
	var t := slots[slot]
	if t < 0.0:
		return 0.0
	if t < GOLDEN_AT:
		return t / GOLDEN_AT
	if t < BURNT_AT:
		return 1.0 + (t - GOLDEN_AT) / (BURNT_AT - GOLDEN_AT)
	return 2.0


## Lifts a vadai out and empties the slot. Returns what it was.
func take(slot: int) -> Doneness:
	var result := doneness(slot)
	slots[slot] = -1.0
	return result


func count_cooking() -> int:
	var n := 0
	for t in slots:
		if t >= 0.0:
			n += 1
	return n
