class_name SaveGame
extends RefCounted
## One save slot: the kadai as it was at the start of the current morning.
## Saved every time a morning begins, so quitting mid-day replays that day.

## Tests point this somewhere else so they never touch a player's save.
static var path := "user://save.json"


static func exists() -> bool:
	return FileAccess.file_exists(path)


static func save(state: KadaiState) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not save the game: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(state.to_dict(), "\t"))


## The saved kadai, or null if there is no readable save.
static func load_state() -> KadaiState:
	if not exists():
		return null
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		push_warning("The save file could not be read, starting fresh.")
		return null
	return KadaiState.from_dict(data)


static func delete() -> void:
	if exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
