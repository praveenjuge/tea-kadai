extends Node
## Keeps the GitHub builds up to date (autoloaded as "Updater").
##
## Each release ships the game's content as TeaKadai.pck plus a version.json
## describing it. At launch this checks that file, downloads a newer pack in
## the background, and verifies its size and SHA-256. On the next launch the
## pack is loaded over the built-in one before any game script runs (Godot
## refreshes its class list when a pack loads). The app itself, the signed
## engine binary, never changes, so macOS signatures stay valid.
##
## Only builds exported with the "self_update" feature do this. Running from
## source, the Mac App Store build and anything with updates switched off in
## Settings never touch the network. Changes to project settings (autoloads,
## the main scene) need a full download, since they're read before this runs.

signal status_changed(text: String)

const LATEST_URL := "https://github.com/praveenjuge/tea-kadai/releases/latest/download/version.json"
const DIR := "user://update"
const INSTALLED := "user://update/installed.json"
## Lets a local test point the game at another server.
const URL_ENV := "TEA_KADAI_UPDATE_URL"

## A short line for the title screen, like "Updated to v0.1.9".
var status := ""
var _http: HTTPRequest
var _offer := {}
var _base_url := ""
## The downloaded pack in use this session, if any.
var _loaded_pack := ""


## Runs as the autoload is created, before the main scene or any other game
## script loads, so the whole game comes from the newer pack.
func _init() -> void:
	if not OS.has_feature("self_update"):
		return
	var installed := _read_json(INSTALLED)
	var pack := str(installed.get("file", ""))
	var newer := is_newer(str(installed.get("version", "")), running_version())
	if newer and str(installed.get("engine", "")) == engine_version() and FileAccess.file_exists(pack):
		if ProjectSettings.load_resource_pack(pack, true):
			_loaded_pack = pack
			status = "Updated to v%s" % running_version()
			print("Updater: running v%s from a downloaded pack" % running_version())
		else:
			push_warning("Updater: could not load %s" % pack)


func _ready() -> void:
	if not OS.has_feature("self_update") or not Settings.load_saved().auto_update:
		return
	_check.call_deferred()


## The version of the game that's running. Release builds carry it in
## version.txt (written by CI), which a downloaded pack replaces.
static func running_version() -> String:
	if FileAccess.file_exists("res://version.txt"):
		return FileAccess.get_file_as_string("res://version.txt").strip_edges()
	return str(ProjectSettings.get_setting("application/config/version", "0.0.0"))


## "4.7.2.stable": a pack only runs on the engine it was exported with.
static func engine_version() -> String:
	var info := Engine.get_version_info()
	return "%d.%d.%d.%s" % [info["major"], info["minor"], info["patch"], info["status"]]


## True if a is a newer "x.y.z" version than b.
static func is_newer(a: String, b: String) -> bool:
	var left := a.split(".")
	var right := b.split(".")
	for i in maxi(left.size(), right.size()):
		var l := int(left[i]) if i < left.size() else 0
		var r := int(right[i]) if i < right.size() else 0
		if l != r:
			return l > r
	return false


func _check() -> void:
	var url := OS.get_environment(URL_ENV) if OS.has_environment(URL_ENV) else LATEST_URL
	_base_url = url.get_base_dir()
	_http = HTTPRequest.new()
	_http.timeout = 20.0
	add_child(_http)
	_http.request_completed.connect(_on_version, CONNECT_ONE_SHOT)
	if _http.request(url) != OK:
		_done("")


func _on_version(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_done("")
		return
	var offer = JSON.parse_string(body.get_string_from_utf8())
	if not offer is Dictionary or not offer.has_all(["version", "engine", "pck", "size", "sha256"]):
		_done("")
		return
	var version := str(offer["version"])
	var installed := _read_json(INSTALLED)
	var have := str(installed.get("version", running_version()))
	if is_newer(running_version(), have):
		have = running_version()
	if not is_newer(version, have) or str(offer["engine"]) != engine_version():
		_done("")
		return
	# Only a plain file name next to version.json, never a path elsewhere.
	var name := str(offer["pck"])
	if name.get_file() != name or not name.ends_with(".pck"):
		_done("")
		return
	_offer = offer
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	_http.download_file = "%s/TeaKadai-%s.pck.part" % [DIR, version]
	_http.request_completed.connect(_on_pack, CONNECT_ONE_SHOT)
	_set_status("Downloading v%s…" % version)
	if _http.request(_base_url + "/" + name) != OK:
		_done("")


func _on_pack(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	var part := _http.download_file
	var version := str(_offer["version"])
	var ok := result == HTTPRequest.RESULT_SUCCESS and code == 200 and FileAccess.file_exists(part)
	if ok:
		var file := FileAccess.open(part, FileAccess.READ)
		ok = file != null and file.get_length() == int(_offer["size"])
		file = null
	if ok:
		ok = FileAccess.get_sha256(part) == str(_offer["sha256"]).to_lower()
	if not ok:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(part))
		_done("")
		return
	var pack := "%s/TeaKadai-%s.pck" % [DIR, version]
	DirAccess.rename_absolute(ProjectSettings.globalize_path(part), ProjectSettings.globalize_path(pack))
	var installed := FileAccess.open(INSTALLED, FileAccess.WRITE)
	installed.store_string(JSON.stringify({"version": version, "engine": _offer["engine"], "file": pack}))
	installed = null
	_remove_old_packs(pack)
	print("Updater: v%s downloaded" % version)
	_done("v%s is ready: it starts next time" % version)


## Keeps only the newest pack, and the one running right now.
func _remove_old_packs(keep: String) -> void:
	for file in DirAccess.get_files_at(DIR):
		var path := DIR.path_join(file)
		if file.ends_with(".pck") and path != keep and path != _loaded_pack:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _done(text: String) -> void:
	if text != "" or status.begins_with("Downloading"):
		_set_status(text)
	if _http != null:
		_http.queue_free()
		_http = null


func _set_status(text: String) -> void:
	status = text
	status_changed.emit(text)


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}
