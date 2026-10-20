class_name EventChoice
extends Resource
## One answer to an event or a shrine: its label, what it says will happen (shown before choosing),
## what it needs, and its effects. A gamble has a `chance` of its effects, else its fail_effects.

enum Need {
	NOTHING,
	GOLD,  ## at least `gold_cost` gold (spent when chosen)
	TOWER,  ## a tower built
	UPGRADABLE_TOWER,  ## a tower that can still go up a level
	UPGRADE,  ## an upgrade taken
	SPARE_LIFE,  ## more than one hero life left
}

@export var label: String = ""
@export_multiline var outcome: String = ""
@export var need: Need = Need.NOTHING
@export var gold_cost: int = 0
@export var effects: Array[EventEffect] = []
## Chance of `effects`; otherwise `fail_effects` (1 = no gamble).
@export_range(0.0, 1.0) var chance: float = 1.0
@export var fail_effects: Array[EventEffect] = []
## Text shown after the choice (the gamble's two results: success, failure).
@export var result_text: String = ""
@export var fail_text: String = ""
