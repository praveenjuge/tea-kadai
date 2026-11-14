class_name Controls
extends RefCounted
## Every player action is a named input action. Gameplay only listens for these
## names, so touch and controller bindings can be added here later without
## changing any game code. The game is mouse first; keys are optional shortcuts.

const KEYS := {
	"tea": KEY_SPACE,
	"fry": KEY_F,
	"serve_1": KEY_1,
	"serve_2": KEY_2,
	"serve_3": KEY_3,
	"serve_4": KEY_4,
	"pause": KEY_P,
	"mute": KEY_M,
}


static func setup() -> void:
	for action in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = KEYS[action]
		InputMap.action_add_event(action, event)


## Short key label for showing on buttons, like "F" or "Space".
static func hint(action: String) -> String:
	return OS.get_keycode_string(KEYS[action])
