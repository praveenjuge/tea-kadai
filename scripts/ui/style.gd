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

	var hud := _wood(PANEL_DARK)
	hud.set_corner_radius_all(0)
	hud.border_width_left = 0
	hud.border_width_right = 0
	hud.border_width_top = 0
	hud.border_width_bottom = 2
	hud.content_margin_top = 3
	hud.content_margin_bottom = 3
	theme.set_type_variation("HudPanel", "PanelContainer")
	theme.set_stylebox("panel", "HudPanel", hud)
	var tag := _wood(PAPER)
	tag.border_color = Color("c9b48c")
	tag.set_border_width_all(1)
	tag.shadow_size = 0
	tag.content_margin_left = 5
	tag.content_margin_right = 5
	tag.content_margin_top = 1
	tag.content_margin_bottom = 1
	theme.set_type_variation("TagPanel", "PanelContainer")
	theme.set_stylebox("panel", "TagPanel", tag)
	theme.set_type_variation("BarePanel", "PanelContainer")
	var bare := StyleBoxEmpty.new()
	bare.content_margin_left = 8
	bare.content_margin_right = 8
	bare.content_margin_top = 6
	bare.content_margin_bottom = 6
	theme.set_stylebox("panel", "BarePanel", bare)

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
	juice(node)
	return node


## Buttons lift a little on hover and squash when pressed.
static func juice(node: BaseButton) -> void:
	var to := func(scale: Vector2, seconds: float) -> void:
		node.pivot_offset = node.size / 2.0
		node.create_tween().tween_property(node, "scale", scale, seconds).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	node.mouse_entered.connect(func() -> void:
		if not node.disabled:
			to.call(Vector2(1.04, 1.04), 0.12))
	node.mouse_exited.connect(func() -> void: to.call(Vector2.ONE, 0.12))
	node.button_down.connect(func() -> void: to.call(Vector2(0.94, 0.92), 0.06))
	node.button_up.connect(func() -> void: to.call(Vector2(1.04, 1.04) if node.is_hovered() else Vector2.ONE, 0.18))


## Fades a control in while it grows from slightly smaller, after "delay"
## seconds. Uses scale, not position, so it works inside containers.
static func pop_in(node: Control, delay: float = 0.0) -> void:
	node.modulate.a = 0.0
	node.scale = Vector2(0.96, 0.96)
	node.resized.connect(func() -> void: node.pivot_offset = node.size / 2.0)
	var tween := node.create_tween().set_parallel()
	tween.tween_property(node, "modulate:a", 1.0, 0.22).set_delay(delay)
	tween.tween_property(node, "scale", Vector2.ONE, 0.3).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Text with a dark outline, readable over the street scene.
static func outlined(text: String, color: Color = TEXT, size: int = FONT_SIZE) -> Label:
	var node := label(text, color, size)
	node.add_theme_color_override("font_outline_color", BG)
	node.add_theme_constant_override("outline_size", 4)
	return node


static func rupees(amount: int) -> String:
	return ("-₹%d" % -amount) if amount < 0 else ("₹%d" % amount)


## The colour of a drink in the glass.
static func drink_color(kind: String) -> Color:
	match kind:
		"lemon_tea":
			return Color("c98a2a")
		"filter_coffee":
			return Color("8a5a36")
	return TEA


## Draws a small icon for a menu item centred on "at".
static func draw_item(canvas: CanvasItem, item: String, at: Vector2, quality: float = 1.0) -> void:
	match item:
		"lemon_tea":
			var glass := PackedVector2Array([at + Vector2(-3, -5), at + Vector2(3, -5), at + Vector2(2, 5), at + Vector2(-2, 5)])
			canvas.draw_colored_polygon(glass, GLASS)
			canvas.draw_rect(Rect2(at + Vector2(-2.5, -3), Vector2(5, 8)), drink_color(item))
			canvas.draw_circle(at + Vector2(3, -5), 2.0, Color("e8d23c"))
		"filter_coffee":
			canvas.draw_rect(Rect2(at + Vector2(-4, 2), Vector2(8, 3)), Color("aab2bb"))
			canvas.draw_rect(Rect2(at + Vector2(-2.5, -5), Vector2(5, 8)), Color("c9ced6"))
			canvas.draw_rect(Rect2(at + Vector2(-2, -5), Vector2(4, 2)), Color("d9b48a"))
		"bajji":
			var bajji := VADAI_GOLDEN if quality >= 0.7 else VADAI_RAW.darkened(0.15)
			canvas.draw_rect(Rect2(at + Vector2(-5, -2), Vector2(10, 5)), bajji)
			canvas.draw_rect(Rect2(at + Vector2(-4, -3), Vector2(8, 1)), bajji.lightened(0.15))
			canvas.draw_rect(Rect2(at + Vector2(4, -1), Vector2(2, 2)), Color("3a8a3a"))
		"samosa":
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -5), at + Vector2(5, 4), at + Vector2(-5, 4)]), Color("d9a050"))
			canvas.draw_line(at + Vector2(0, -5), at + Vector2(0, 4), Color("b8803a"), 1.0)
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


## A front-facing head with a face, its chin at the origin. "look" can have
## skin, hair, hair_style (short, bald, bun, long), mustache, glasses, hat
## and flowers. Callers set a transform to place and scale it.
static func draw_head(canvas: CanvasItem, look: Dictionary, alpha: float = 1.0) -> void:
	var skin: Color = look.get("skin", SKIN)
	var hair: Color = look.get("hair", Color("1e1612"))
	var style: String = look.get("hair_style", "short")
	var dark := Color(0.1, 0.07, 0.05, alpha)
	canvas.draw_rect(Rect2(-4, -8, 8, 8), Color(skin, alpha))
	canvas.draw_rect(Rect2(-5, -5, 1, 2), Color(skin.darkened(0.1), alpha))
	canvas.draw_rect(Rect2(4, -5, 1, 2), Color(skin.darkened(0.1), alpha))
	match style:
		"bald":
			canvas.draw_rect(Rect2(-4, -6, 1, 3), Color(hair, alpha))
			canvas.draw_rect(Rect2(3, -6, 1, 3), Color(hair, alpha))
		"bun":
			canvas.draw_rect(Rect2(-4, -9, 8, 3), Color(hair, alpha))
			canvas.draw_rect(Rect2(-2, -11, 4, 2), Color(hair, alpha))
		"long":
			canvas.draw_rect(Rect2(-4, -9, 8, 3), Color(hair, alpha))
			canvas.draw_rect(Rect2(-5, -8, 1, 8), Color(hair, alpha))
			canvas.draw_rect(Rect2(4, -8, 1, 8), Color(hair, alpha))
		_:
			canvas.draw_rect(Rect2(-4, -9, 8, 3), Color(hair, alpha))
			canvas.draw_rect(Rect2(-4, -7, 1, 1), Color(hair, alpha))
	canvas.draw_rect(Rect2(-3, -5, 1, 1), dark)
	canvas.draw_rect(Rect2(2, -5, 1, 1), dark)
	if look.get("glasses", false):
		canvas.draw_rect(Rect2(-4, -6, 3, 3), Color(0.1, 0.1, 0.1, alpha), false, 1.0)
		canvas.draw_rect(Rect2(1, -6, 3, 3), Color(0.1, 0.1, 0.1, alpha), false, 1.0)
	if look.get("mustache", false):
		canvas.draw_rect(Rect2(-2, -3, 4, 1), Color(hair.darkened(0.2), alpha))
	else:
		canvas.draw_rect(Rect2(-1, -2, 2, 1), Color(skin.darkened(0.35), alpha))
	if look.has("hat"):
		var hat: Color = look["hat"]
		canvas.draw_rect(Rect2(-5, -11, 10, 4), Color(hat, alpha))
		canvas.draw_rect(Rect2(-6, -8, 12, 1), Color(hat.darkened(0.2), alpha))
	if look.get("flowers", false):
		for dot in [Vector2(-4, -10), Vector2(-3, -11), Vector2(3, -10)]:
			canvas.draw_rect(Rect2(dot, Vector2(1, 1)), Color(1, 1, 1, alpha))


## A face portrait in a small framed square, for speech bubbles.
static func draw_portrait(canvas: CanvasItem, look: Dictionary, rect: Rect2, alpha: float = 1.0) -> void:
	canvas.draw_rect(rect, Color(look.get("shirt", ACCENT).darkened(0.35), alpha))
	var scale := rect.size.y / 14.0
	canvas.draw_set_transform(rect.position + Vector2(rect.size.x / 2.0, rect.size.y - scale), 0.0, Vector2(scale, scale))
	canvas.draw_rect(Rect2(-5, -1, 10, 2), Color(look.get("shirt", ACCENT), alpha))
	canvas.draw_set_transform(rect.position + Vector2(rect.size.x / 2.0, rect.size.y - scale * 1.5), 0.0, Vector2(scale, scale))
	draw_head(canvas, look, alpha)
	canvas.draw_set_transform(Vector2.ZERO)
	canvas.draw_rect(rect, Color(WOOD_EDGE, alpha), false, 1.0)


## One weekly goal with a progress bar, for the morning and night screens.
static func goal_row(goal: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var done: bool = goal["done"]
	var text := label(str(goal["text"]) + (" · done!" if done else ""), GOOD if done else TEXT)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(50, 6)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fraction := clampf(float(goal["value"]) / float(goal["target"]), 0.0, 1.0)
	bar.draw.connect(func() -> void:
		bar.draw_rect(Rect2(Vector2.ZERO, bar.size), PANEL_DARK)
		bar.draw_rect(Rect2(Vector2.ZERO, Vector2(bar.size.x * fraction, bar.size.y)), GOOD if done else ACCENT))
	row.add_child(bar)
	return row
