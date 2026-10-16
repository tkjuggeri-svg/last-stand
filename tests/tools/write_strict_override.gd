extends SceneTree
## Writes res://override.cfg raising every enabled GDScript warning to an error.
## Used by tests/run_tests.sh so warnings show up on the command line. Never commit override.cfg.

const WARNING_PREFIX: String = "debug/gdscript/warnings/"
const LEVEL_WARN: int = 1
const LEVEL_ERROR: int = 2


func _initialize() -> void:
	var lines: PackedStringArray = ["[debug]", ""]
	for property: Dictionary in ProjectSettings.get_property_list():
		var setting_name: String = property["name"]
		if setting_name.begins_with(WARNING_PREFIX) and ProjectSettings.get_setting(setting_name) is int:
			if ProjectSettings.get_setting(setting_name) == LEVEL_WARN:
				lines.append("%s=%d" % [setting_name.trim_prefix("debug/"), LEVEL_ERROR])
	var file: FileAccess = FileAccess.open("res://override.cfg", FileAccess.WRITE)
	if file == null:
		push_error("Could not write override.cfg: %s" % error_string(FileAccess.get_open_error()))
		quit(1)
		return
	file.store_string("\n".join(lines) + "\n")
	file.close()
	print("override.cfg: %d warnings raised to errors" % (lines.size() - 2))
	quit()
