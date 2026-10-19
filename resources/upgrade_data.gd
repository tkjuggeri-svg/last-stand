class_name UpgradeData
extends Resource
## One run upgrade the player can pick after a wave (M5 roguelite layer). Make one .tres per upgrade
## in data/upgrades/. Its stat modifiers go into the level's RunModifiers; an optional instant
## effect (e.g. repairing the fortress) happens once, when it is picked.

enum Category { HERO, TOWERS, FORTRESS, ECONOMY }
enum Rarity { COMMON, RARE }

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var category: Category = Category.HERO
@export var rarity: Rarity = Rarity.COMMON
## False: it can be taken once per run and is never offered again afterwards.
@export var stackable: bool = true
@export var modifiers: Array[StatModifier] = []
## Something that happens once when picked (see RunModifiers.INSTANT_*); empty = none.
@export var instant_effect: StringName = &""
@export var effect_amount: float = 0.0
