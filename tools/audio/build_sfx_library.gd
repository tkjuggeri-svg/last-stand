extends SceneTree
## Dev-only: writes data/audio/sfx_library.tres: one SfxEntry per SfxRecipes sound (its imported WAV
## and its mix). Run after generate_sfx.gd and an import.

const LIBRARY_PATH: String = "res://data/audio/sfx_library.tres"
const SFX_DIR: String = "res://assets/audio/sfx"


func _initialize() -> void:
	var library: SfxLibrary = SfxLibrary.new()
	var missing: int = 0
	for id: StringName in SfxRecipes.RECIPES:
		var path: String = SFX_DIR.path_join("%s.wav" % id)
		if not ResourceLoader.exists(path):
			push_error("No %s: run generate_sfx.gd and an import first" % path)
			missing += 1
			continue
		var mix: Dictionary = SfxRecipes.RECIPES[id]["mix"]
		var entry: SfxEntry = SfxEntry.new()
		entry.id = id
		entry.stream = load(path)
		entry.volume_db = mix.get("volume_db", -10.0)
		entry.voices = mix.get("voices", 2)
		entry.interval = mix.get("interval", 0.05)
		entry.jitter = mix.get("jitter", 0.0)
		entry.world = mix.get("world", false)
		library.entries.append(entry)
	var error: Error = ResourceSaver.save(library, LIBRARY_PATH)
	print("%d sounds in %s (%s), %d missing" % [library.entries.size(), LIBRARY_PATH, "ok" if error == OK else "FAILED", missing])
	quit(missing)
