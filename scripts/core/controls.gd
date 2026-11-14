class_name Controls
extends RefCounted
## Every player action is a named input action. Gameplay only listens for these
## names, so touch and controller bindings can be added here later without
## changing any game code.

const KEYS := {
	"serve_1": KEY_1,
	"serve_2": KEY_2,
	"serve_3": KEY_3,
	"serve_4": KEY_4,
	"tea_next": KEY_T,
	"tea_pour": KEY_SPACE,
	"fry_drop": KEY_F,
	"fry_take_1": KEY_Z,
	"fry_take_2": KEY_X,
	"fry_take_3": KEY_C,
	"pause": KEY_P,
}


static func setup() -> void:
	for action in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = KEYS[action]
		InputMap.action_add_event(action, event)


## Short key label for showing on buttons, like "T" or "Space".
static func hint(action: String) -> String:
	return OS.get_keycode_string(KEYS[action])
