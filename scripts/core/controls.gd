class_name Controls
extends RefCounted
## Every player action is a named input action. Gameplay only listens for these
## names, so touch and controller bindings can be added here later without
## changing any game code. The game is mouse first; keys are optional shortcuts.

## Each action's keys. The first one is shown on buttons.
const KEYS := {
	"tea": [KEY_SPACE],
	"ginger": [KEY_G],
	"fry": [KEY_F],
	"serve_1": [KEY_1],
	"serve_2": [KEY_2],
	"serve_3": [KEY_3],
	"serve_4": [KEY_4],
	"serve_5": [KEY_5],
	"pause": [KEY_P, KEY_ESCAPE],
	"mute": [KEY_M],
}


static func setup() -> void:
	for action in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in KEYS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)


## Short key label for showing on buttons, like "F" or "Space".
static func hint(action: String) -> String:
	return OS.get_keycode_string(KEYS[action][0])
