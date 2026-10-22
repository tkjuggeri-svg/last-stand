extends SceneTree
## Dev-only: renders every SfxRecipes sound to assets/audio/sfx/<id>.wav, normalised to the same
## loudness (the mix in the library sets each one's level). Then import, then build_sfx_library.gd:
##   godot --headless --path . --script res://tools/audio/generate_sfx.gd [-- --only=ui_click,gold]
##   godot --headless --path . --import
##   godot --headless --path . --script res://tools/audio/build_sfx_library.gd

const OUT_DIR: String = "res://assets/audio/sfx"
## Loudness every sound is rendered at (RMS), and its highest peak.
const TARGET_RMS: float = 0.2
const PEAK: float = 0.9


func _initialize() -> void:
	var only: PackedStringArray = []
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.trim_prefix("--only=").split(",")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var ids: Array = SfxRecipes.RECIPES.keys()
	for i: int in ids.size():
		var id: StringName = ids[i]
		if not only.is_empty() and not only.has(String(id)):
			continue
		var recipe: Dictionary = SfxRecipes.RECIPES[id]
		var samples: PackedFloat32Array = SfxSynth.render(recipe["layers"], hash(String(id)))
		samples = SfxSynth.normalize(samples, TARGET_RMS, PEAK)
		var path: String = ProjectSettings.globalize_path(OUT_DIR.path_join("%s.wav" % id))
		var error: Error = SfxSynth.to_stream(samples).save_to_wav(path)
		print("%-16s %5.2f s  %s" % [id, samples.size() / float(SfxSynth.RATE), "ok" if error == OK else "FAILED %d" % error])
	quit()
