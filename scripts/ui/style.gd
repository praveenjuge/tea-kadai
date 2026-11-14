class_name Style
extends RefCounted
## Colours, the UI theme, and small pixel drawings shared across screens.
## Placeholder art: everything is drawn with shapes until real sprites exist.

const BG := Color("2a1c13")
const PANEL := Color("3b2a1e")
const PANEL_DARK := Color("31231a")
const LINE := Color("5a4330")
const TEXT := Color("f6e7c8")
const MUTED := Color("bfa888")
const ACCENT := Color("e8a33d")
const GOOD := Color("7cc46a")
const WARN := Color("e8c547")
const BAD := Color("e0604e")
const TEA := Color("a8672f")
const FROTH := Color("f3dcb0")
const DECOCTION := Color("4a2a14")
const GLASS := Color(0.95, 0.92, 0.85, 0.35)
const VADAI_RAW := Color("e9d39a")
const VADAI_GOLDEN := Color("c9862f")
const VADAI_BURNT := Color("4a2a18")
const SKIN := Color("8d5a3b")

const WOOD_EDGE := Color("1c120c")
const PAPER := Color("f3e3c3")
const INK := Color("2a1c13")

const FONT_SIZE := 10
const TITLE_SIZE := 16
const HERO_SIZE := 32
const FONT_PATH := "res://assets/fonts/PixelifySans.ttf"

static var _font: Font


## The game font: Pixelify Sans, with Godot's built-in font as a fallback for
## glyphs it lacks (like ₹ and →).
static func font() -> Font:
	if _font == null:
		var pixel: FontFile = load(FONT_PATH)
		pixel.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		pixel.hinting = TextServer.HINTING_NONE
		pixel.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		pixel.fallbacks = [ThemeDB.fallback_font]
		# Its "fi" ligature looks like a different letter at small sizes.
		var text_server := TextServerManager.get_primary_interface()
		pixel.opentype_feature_overrides = {
			text_server.name_to_tag("liga"): 0, text_server.name_to_tag("clig"): 0,
		}
		_font = pixel
	return _font


static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = font()
	theme.default_font_size = FONT_SIZE
	theme.set_color("font_color", "Label", TEXT)

	# Buttons look like painted tin signs: a darker lip along the bottom that
	# disappears when pressed.
	theme.set_stylebox("normal", "Button", _sign(ACCENT, ACCENT.darkened(0.45)))
	theme.set_stylebox("hover", "Button", _sign(ACCENT.lightened(0.15), ACCENT.darkened(0.4)))
	theme.set_stylebox("pressed", "Button", _sign(ACCENT.darkened(0.15), ACCENT.darkened(0.45), true))
	theme.set_stylebox("disabled", "Button", _sign(LINE, LINE.darkened(0.3)))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		theme.set_color(state, "Button", INK)
	theme.set_color("font_disabled_color", "Button", MUTED)

	# A quieter button for secondary actions.
	theme.set_type_variation("QuietButton", "Button")
	theme.set_stylebox("normal", "QuietButton", _sign(PANEL_DARK, WOOD_EDGE))
	theme.set_stylebox("hover", "QuietButton", _sign(PANEL_DARK.lightened(0.1), WOOD_EDGE))
	theme.set_stylebox("pressed", "QuietButton", _sign(PANEL_DARK.darkened(0.1), WOOD_EDGE, true))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		theme.set_color(state, "QuietButton", TEXT)

	# Wooden panels with a dark edge and a soft drop shadow.
	theme.set_stylebox("panel", "PanelContainer", _wood(PANEL))
	theme.set_type_variation("PaperPanel", "PanelContainer")
	var paper := _wood(PAPER)
	paper.border_color = Color("c9b48c")
	theme.set_stylebox("panel", "PaperPanel", paper)

	var line := StyleBoxLine.new()
	line.color = LINE
	line.thickness = 1
	theme.set_stylebox("separator", "HSeparator", line)

	var track := StyleBoxFlat.new()
	track.bg_color = PANEL_DARK
	track.set_corner_radius_all(2)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	theme.set_stylebox("slider", "HSlider", track)
	var fill := track.duplicate()
	fill.bg_color = ACCENT
	theme.set_stylebox("grabber_area", "HSlider", fill)
	theme.set_stylebox("grabber_area_highlight", "HSlider", fill)
	theme.set_color("font_color", "CheckBox", TEXT)
	theme.set_color("font_hover_color", "CheckBox", TEXT)
	theme.set_color("font_pressed_color", "CheckBox", TEXT)
	return theme


static func _sign(color: Color, lip: Color, pressed: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = lip
	box.set_corner_radius_all(2)
	box.border_width_bottom = 0 if pressed else 3
	box.border_width_top = 2 if pressed else 0
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 3
	box.content_margin_bottom = 2
	return box


static func _wood(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = WOOD_EDGE
	box.set_border_width_all(2)
	box.set_corner_radius_all(3)
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_offset = Vector2(0, 3)
	box.shadow_size = 1
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 5
	box.content_margin_bottom = 5
	return box


static func label(text: String, color: Color = TEXT, size: int = FONT_SIZE) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_color_override("font_color", color)
	if size != FONT_SIZE:
		node.add_theme_font_size_override("font_size", size)
	return node


## A label for long text that wraps at the given width.
static func paragraph(text: String, width: float, color: Color = TEXT) -> Label:
	var node := label(text, color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.custom_minimum_size.x = width
	return node


static func button(text: String, on_press: Callable, quiet: bool = false) -> Button:
	var node := Button.new()
	node.text = text
	node.focus_mode = Control.FOCUS_NONE
	if quiet:
		node.theme_type_variation = "QuietButton"
	node.pressed.connect(on_press)
	return node


## Text with a dark outline, readable over the street scene.
static func outlined(text: String, color: Color = TEXT, size: int = FONT_SIZE) -> Label:
	var node := label(text, color, size)
	node.add_theme_color_override("font_outline_color", BG)
	node.add_theme_constant_override("outline_size", 4)
	return node


static func rupees(amount: int) -> String:
	return ("-₹%d" % -amount) if amount < 0 else ("₹%d" % amount)


## Draws a small icon for a menu item centred on "at".
static func draw_item(canvas: CanvasItem, item: String, at: Vector2, quality: float = 1.0) -> void:
	match item:
		"tea", "ginger_tea":
			var glass := PackedVector2Array([at + Vector2(-3, -5), at + Vector2(3, -5), at + Vector2(2, 5), at + Vector2(-2, 5)])
			canvas.draw_colored_polygon(glass, GLASS)
			canvas.draw_rect(Rect2(at + Vector2(-2.5, -2), Vector2(5, 7)), TEA)
			var froth := FROTH if quality >= 0.7 else TEA.lightened(0.15)
			canvas.draw_rect(Rect2(at + Vector2(-3, -4), Vector2(6, 2)), froth)
			if item == "ginger_tea":
				canvas.draw_rect(Rect2(at + Vector2(2, -7), Vector2(3, 3)), Color("d9c25a"))
				canvas.draw_rect(Rect2(at + Vector2(3, -8), Vector2(1, 1)), Color("7cc46a"))
		"vadai":
			var color := VADAI_GOLDEN if quality >= 0.7 else VADAI_RAW.darkened(0.15)
			canvas.draw_circle(at, 5.0, color)
			canvas.draw_circle(at + Vector2(-1, -1), 3.5, color.lightened(0.12))
			canvas.draw_circle(at, 1.5, PANEL_DARK)
		"biscuit":
			canvas.draw_rect(Rect2(at + Vector2(-4, -4), Vector2(8, 8)), Color("d9a55b"))
			for dot in [Vector2(-2, -2), Vector2(1, -2), Vector2(-2, 1), Vector2(1, 1)]:
				canvas.draw_rect(Rect2(at + dot, Vector2(1, 1)), Color("8a5a2b"))
		"bun":
			canvas.draw_circle(at + Vector2(0, 1), 5.0, Color("c98a45"))
			canvas.draw_rect(Rect2(at + Vector2(-5, 1), Vector2(10, 4)), Color("c98a45"))
			canvas.draw_rect(Rect2(at + Vector2(-2, -3), Vector2(3, 1)), Color("f0c98a"))


## Draws a menu symbol centred on "at": a menu item, or "coin", "heart",
## "star", "cloud" or "sun".
static func draw_symbol(canvas: CanvasItem, symbol: String, at: Vector2, scale: float = 1.0) -> void:
	canvas.draw_set_transform(at, 0.0, Vector2(scale, scale))
	var o := Vector2.ZERO
	match symbol:
		"coin":
			canvas.draw_circle(o, 5.0, Color("b8862f"))
			canvas.draw_circle(o + Vector2(0, -0.5), 4.2, WARN)
			canvas.draw_rect(Rect2(-1, -2.5, 2, 4), Color("b8862f"))
		"heart":
			canvas.draw_circle(o + Vector2(-2, -1), 2.6, BAD)
			canvas.draw_circle(o + Vector2(2, -1), 2.6, BAD)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-4.5, 0), Vector2(4.5, 0), Vector2(0, 5)]), BAD)
		"heart_empty":
			var pale := Color("d9c9a5")
			canvas.draw_circle(o + Vector2(-2, -1), 2.6, pale)
			canvas.draw_circle(o + Vector2(2, -1), 2.6, pale)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-4.5, 0), Vector2(4.5, 0), Vector2(0, 5)]), pale)
		"star", "star_empty":
			var points := PackedVector2Array()
			for i in 10:
				var r := 5.5 if i % 2 == 0 else 2.4
				var a := -PI / 2.0 + i * PI / 5.0
				points.append(Vector2(cos(a), sin(a)) * r)
			canvas.draw_colored_polygon(points, ACCENT if symbol == "star" else LINE)
		"cloud":
			for c in [Vector2(-3, 0), Vector2(1, -2), Vector2(4, 0)]:
				canvas.draw_circle(c, 3.0, Color("9aa3ad"))
			canvas.draw_rect(Rect2(-5, 0, 10, 2.5), Color("9aa3ad"))
			for x in [-3.0, 0.0, 3.0]:
				canvas.draw_line(Vector2(x, 4), Vector2(x - 1, 6.5), Color("6aa0d9"), 1.0)
		"sun":
			canvas.draw_circle(o, 3.2, WARN)
			for i in 8:
				var a := i * PI / 4.0
				canvas.draw_line(Vector2(cos(a), sin(a)) * 4.5, Vector2(cos(a), sin(a)) * 6.0, WARN, 1.0)
		_:
			draw_item(canvas, symbol, o)
	canvas.draw_set_transform(Vector2.ZERO)
