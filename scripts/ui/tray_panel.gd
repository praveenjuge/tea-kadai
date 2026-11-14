class_name TrayPanel
extends PanelContainer
## What's ready to hand over, plus the packaged snacks on the shelf.

var _service: Service
var _art: Control
var _shelf: Label


func _init(service: Service) -> void:
	_service = service


func _ready() -> void:
	size_flags_horizontal = SIZE_EXPAND_FILL
	custom_minimum_size.y = 124
	var box := VBoxContainer.new()
	add_child(box)
	box.add_child(Style.label("Ready to serve", Style.ACCENT))
	_art = Control.new()
	_art.custom_minimum_size = Vector2(0, 26)
	_art.draw.connect(_draw_tray)
	box.add_child(_art)
	_shelf = Style.label("", Style.MUTED)
	box.add_child(_shelf)
	var help := Style.label("Serve: click a customer or press 1 to 4. Packaged snacks come off the shelf.", Style.MUTED)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(help)


func refresh() -> void:
	var state := _service.state
	_shelf.text = "Shelf: %d biscuits · %d buns" % [state.how_many("biscuit"), state.how_many("bun")]
	_art.queue_redraw()


func _draw_tray() -> void:
	var width := Catalog.TRAY_SIZE * 16.0 + 8.0
	_art.draw_rect(Rect2(0, 18, width, 4), Color("9aa3ad"))
	_art.draw_rect(Rect2(0, 22, width, 1), Color("5f666e"))
	for i in Catalog.TRAY_SIZE:
		var at := Vector2(12 + i * 16, 11)
		if i < _service.tray.size():
			var entry: Dictionary = _service.tray[i]
			Style.draw_item(_art, entry["item"], at, entry["quality"])
		else:
			_art.draw_rect(Rect2(at + Vector2(-3, 4), Vector2(6, 1)), Color(Style.MUTED, 0.3))
