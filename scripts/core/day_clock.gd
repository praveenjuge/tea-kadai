class_name DayClock
extends RefCounted
## Turns real seconds into kadai clock time across the day's phases.

var elapsed := 0.0
var _total := 0.0


func _init() -> void:
	for phase in Catalog.PHASES:
		_total += float(phase["seconds"])


func advance(delta: float) -> void:
	elapsed = minf(elapsed + delta, _total)


func is_over() -> bool:
	return elapsed >= _total


func progress() -> float:
	return elapsed / _total


func phase_index() -> int:
	var t := elapsed
	for i in Catalog.PHASES.size():
		var length := float(Catalog.PHASES[i]["seconds"])
		if t < length:
			return i
		t -= length
	return Catalog.PHASES.size() - 1


func phase() -> Dictionary:
	return Catalog.PHASES[phase_index()]


## Kadai clock time in minutes after midnight.
func minutes() -> float:
	var t := elapsed
	for phase in Catalog.PHASES:
		var length := float(phase["seconds"])
		if t < length:
			return lerpf(float(phase["from"]), float(phase["to"]), t / length)
		t -= length
	return float(Catalog.PHASES[-1]["to"])


func time_text() -> String:
	var total := int(minutes())
	var hour := total / 60
	var minute := total % 60
	var suffix := "AM" if hour < 12 else "PM"
	var hour12 := hour % 12
	if hour12 == 0:
		hour12 = 12
	return "%d:%02d %s" % [hour12, minute, suffix]


func can_arrive() -> bool:
	return not is_over() and minutes() < Catalog.LAST_ARRIVAL_MINUTE
