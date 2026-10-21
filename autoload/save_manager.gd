class_name SaveManagerNode
extends Node
## The player's save (autoload "SaveManager", allowed by CLAUDE.md): one versioned JSON file in user://
## holding the SaveProfile. Written atomically (to a .tmp file, then renamed; the previous file kept as
## .bak); a save that can't be read falls back to the backup, then to a fresh profile, and says so
## (load_problem), never crashing and never wiping silently.
## Under --script (tests, the balance tools) it is in script mode: the profile has everything unlocked,
## nothing is written, and Main boots straight into a run, as before M8; a test switches it off with
## use_file(). Scripts run with --script reach it as get_node("/root/SaveManager") as SaveManagerNode.

## The profile changed (shards, unlocks, records): screens refresh.
signal changed

const DEFAULT_PATH: String = "user://save.json"

var profile: SaveProfile = SaveProfile.new()
## What went wrong at the last load ("" = nothing).
var load_problem: String = ""

var _path: String = DEFAULT_PATH
var _scripted: bool = false


func _ready() -> void:
	_scripted = OS.get_cmdline_args().has("--script")
	if _scripted:
		profile.unlock_everything = true
	else:
		load_profile()


## True in script mode (tests and tools): everything unlocked, nothing saved, no title screen.
func is_scripted() -> bool:
	return _scripted


## Uses the save at `path` from now on (and leaves script mode): loads it, or starts fresh.
func use_file(path: String) -> void:
	_scripted = false
	_path = path
	load_profile()


func get_path_used() -> String:
	return _path


## Reads the save (or its backup); a fresh profile if neither can be read.
func load_profile() -> void:
	load_problem = ""
	for candidate: String in [_path, _path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var json: JSON = JSON.new()
		var parsed: Variant = json.data if json.parse(FileAccess.get_file_as_string(candidate)) == OK else null
		if parsed is Dictionary:
			profile = SaveProfile.from_dict(parsed)
			if candidate != _path:
				load_problem = "The save could not be read; the backup was loaded."
			changed.emit()
			return
		load_problem = "The save could not be read."
	profile = SaveProfile.new()
	if not load_problem.is_empty():
		load_problem += " A fresh profile was started."
	changed.emit()


## Writes the profile (nothing in script mode). Returns false if it couldn't be written.
func save_profile() -> bool:
	changed.emit()
	if _scripted:
		return true
	var tmp: String = _path + ".tmp"
	var file: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(profile.to_dict(), "\t") + "\n")
	file.close()
	if FileAccess.file_exists(_path):
		DirAccess.copy_absolute(_path, _path + ".bak")
	return DirAccess.rename_absolute(tmp, _path) == OK


## Starts the profile over (the hub's Reset progress); the old save stays as the backup.
func reset_profile() -> void:
	profile = SaveProfile.new()
	profile.unlock_everything = _scripted
	save_profile()
