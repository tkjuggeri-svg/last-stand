class_name SfxLibrary
extends Resource
## Every sound effect of the game (data/audio/sfx_library.tres, M8.5): generated, see SfxRecipes.

@export var entries: Array[SfxEntry] = []


func find(id: StringName) -> SfxEntry:
	for entry: SfxEntry in entries:
		if entry.id == id:
			return entry
	return null
