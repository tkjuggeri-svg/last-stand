extends SceneTree
## Dev-only: renders every MusicRecipes track to assets/audio/music/<id>.wav (a seamless loop). Then import:
##   godot --headless --path . --script res://tools/audio/generate_music.gd [-- --only=title,boss]
##   godot --headless --path . --import

const OUT_DIR: String = "res://assets/audio/music"


func _initialize() -> void:
	var only: PackedStringArray = []
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.trim_prefix("--only=").split(",")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for id: StringName in MusicRecipes.TRACKS:
		if not only.is_empty() and not only.has(String(id)):
			continue
		var samples: PackedFloat32Array = MusicSynth.render(MusicRecipes.TRACKS[id])
		var path: String = ProjectSettings.globalize_path(OUT_DIR.path_join("%s.wav" % id))
		var error: Error = MusicSynth.to_stream(samples).save_to_wav(path)
		print("%-10s %5.1f s  %s" % [id, samples.size() / float(MusicSynth.RATE), "ok" if error == OK else "FAILED %d" % error])
	quit()
