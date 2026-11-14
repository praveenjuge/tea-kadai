extends SceneTree
## Exports every sprite PixelArt paints to one sheet, docs/sprites.png, so the
## art can be looked over (or replaced) outside the game: each customer type
## and regular in every pose, then every menu item, good and not so good.
## Run: godot --headless --path . -s tools/make_sprites.gd

const OUT := "res://docs/sprites.png"
const ZOOM := 4
const GAP := 4


func _init() -> void:
	var people: Array[Dictionary] = []
	for id in Catalog.CUSTOMERS:
		people.append(Catalog.CUSTOMERS[id])
	for id in Story.REGULAR_ORDER:
		people.append(Story.REGULARS[id])
	var poses := PixelArt.POSES
	var items: Array[String] = Catalog.MENU_ORDER
	var cell := PixelArt.PERSON + Vector2i(GAP, GAP)
	var width := maxi(poses.size() * cell.x, items.size() * (PixelArt.ITEM.x + GAP))
	var height := people.size() * cell.y + 2 * (PixelArt.ITEM.y + GAP)
	var sheet := Image.create_empty(width + GAP, height + GAP, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("3b2a1e"))
	for row in people.size():
		for col in poses.size():
			var sprite := PixelArt.person(people[row], poses[col])
			sheet.blend_rect(sprite, Rect2i(Vector2i.ZERO, sprite.get_size()), Vector2i(GAP + col * cell.x, GAP + row * cell.y))
	var item_top := GAP + people.size() * cell.y
	for col in items.size():
		for low in 2:
			var sprite := PixelArt.item(items[col], low == 1)
			sheet.blend_rect(sprite, Rect2i(Vector2i.ZERO, sprite.get_size()),
				Vector2i(GAP + col * (PixelArt.ITEM.x + GAP), item_top + low * (PixelArt.ITEM.y + GAP)))
	sheet.resize(sheet.get_width() * ZOOM, sheet.get_height() * ZOOM, Image.INTERPOLATE_NEAREST)
	sheet.save_png(ProjectSettings.globalize_path(OUT))
	print("Saved ", OUT)
	quit()
