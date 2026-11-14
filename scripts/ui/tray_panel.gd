class_name TrayPanel
extends PanelContainer
## Everything ready to hand over: tea on the tray, vadai on the plate, and the
## packaged snacks on the shelf.

var _service: Service
var _art: Control


func _init(service: Service) -> void:
	_service = service


func _ready() -> void:
	size_flags_horizontal = SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	add_child(box)
	box.add_child(Style.label("Ready to serve", Style.ACCENT))
	_art = Control.new()
	_art.size_flags_vertical = SIZE_EXPAND_FILL
	_art.draw.connect(_draw_ready)
	box.add_child(_art)
	box.add_child(Style.label("Click a customer to serve them.", Style.MUTED))


func refresh() -> void:
	_art.queue_redraw()


func _draw_ready() -> void:
	var font := _art.get_theme_default_font()
	var items := _service.state.menu()
	var column := _art.size.x / items.size()
	for i in items.size():
		var item := items[i]
		var count := _service.ready_count(item)
		var at := Vector2(column * (i + 0.5), _art.size.y * 0.42)
		var alpha := 1.0 if count > 0 else 0.3
		_art.draw_set_transform(at, 0.0, Vector2(2, 2))
		Style.draw_item(_art, item, Vector2.ZERO)
		_art.draw_set_transform(Vector2.ZERO)
		if count == 0:
			_art.draw_rect(Rect2(at - Vector2(12, 12), Vector2(24, 24)), Color(Style.PANEL, 0.7))
		var text := "× %d" % count
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, Style.FONT_SIZE).x
		_art.draw_string(font, at + Vector2(-width / 2.0, 26), text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			Style.FONT_SIZE, Color(Style.TEXT, alpha))
