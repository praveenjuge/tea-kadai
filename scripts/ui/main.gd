extends Control
## Runs the day loop: morning at the market, live service, night summary.
## Pass "-- --service" on the command line to skip straight to service.

var state := KadaiState.new()
var _screen: Control


func _ready() -> void:
	Controls.setup()
	theme = Style.make_theme()
	if "--service" in OS.get_cmdline_user_args():
		_show_service()
	else:
		_show_morning()


func _swap(next: Control) -> void:
	if _screen != null:
		_screen.queue_free()
	_screen = next
	add_child(next)
	next.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _show_morning() -> void:
	var screen := MorningScreen.new(state)
	screen.open_requested.connect(_show_service)
	_swap(screen)


func _show_service() -> void:
	var screen := ServiceScreen.new(state)
	screen.day_finished.connect(_show_night)
	_swap(screen)


func _show_night() -> void:
	var screen := NightScreen.new(state)
	screen.next_requested.connect(_on_next_day)
	_swap(screen)


func _on_next_day() -> void:
	state.next_day()
	_show_morning()
