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
	touch()


## Notes when the player was last here, so helpers can earn while they're away.
static func touch() -> void:
	var file := FileAccess.open(_seen_path(), FileAccess.WRITE)
	if file != null:
		file.store_string(str(int(Time.get_unix_time_from_system())))


## Seconds since the player was last here, or 0 if we don't know.
static func seconds_away() -> float:
	if not FileAccess.file_exists(_seen_path()):
		return 0.0
	var seen := FileAccess.get_file_as_string(_seen_path()).to_int()
	return maxf(0.0, Time.get_unix_time_from_system() - seen) if seen > 0 else 0.0


static func _seen_path() -> String:
	return path.get_basename() + "_seen.txt"


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
	for file in [path, _seen_path()]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
