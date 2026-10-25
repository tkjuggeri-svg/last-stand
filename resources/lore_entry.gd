class_name LoreEntry
extends Resource
## One entry of the Chronicle (M11): a foe (unlocked when it first appears in a run) or a place (when its
## map is first entered). data/story/lore/.

enum Kind { FOE, PLACE }

@export var id: StringName = &""
@export var kind: Kind = Kind.FOE
## An enemy's file name, or a biome's chapter id.
@export var key: StringName = &""
@export var title: String = ""
@export_multiline var text: String = ""
## Shown while it is locked.
@export var hint: String = ""
