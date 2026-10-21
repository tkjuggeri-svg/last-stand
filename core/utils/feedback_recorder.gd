class_name FeedbackRecorder
## Saves a feedback report (the in-game feedback key) as a folder: `<base>/<date_time>/` with the
## player's note (note.txt), a screenshot (screenshot.png, when the renderer can give one) and the run's
## state (state.json, RunSnapshot). One folder per report, never overwritten.

## Where reports go (tests point it elsewhere).
const DEFAULT_DIR: String = "user://feedback"


## Writes the report and returns its folder (an absolute path, to show the player), or "" on failure.
static func save(base: String, note: String, screenshot: Image, state: Dictionary) -> String:
	var stamp: String = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var folder: String = base.path_join(stamp)
	var suffix: int = 2
	while DirAccess.dir_exists_absolute(folder):
		folder = base.path_join("%s_%d" % [stamp, suffix])
		suffix += 1
	if DirAccess.make_dir_recursive_absolute(folder) != OK:
		return ""
	var note_file: FileAccess = FileAccess.open(folder.path_join("note.txt"), FileAccess.WRITE)
	if note_file == null:
		return ""
	note_file.store_string(note.strip_edges() + "\n")
	note_file.close()
	var state_file: FileAccess = FileAccess.open(folder.path_join("state.json"), FileAccess.WRITE)
	if state_file == null:
		return ""
	state_file.store_string(JSON.stringify(state, "\t") + "\n")
	state_file.close()
	if screenshot != null and not screenshot.is_empty():
		screenshot.save_png(folder.path_join("screenshot.png"))
	return ProjectSettings.globalize_path(folder)
