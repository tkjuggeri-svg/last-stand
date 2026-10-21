class_name RelicData
extends UpgradeData
## A relic (M7.5): rarer than a card, one of each per run, and it changes a rule of the run rather than
## (only) a stat. Its stat modifiers work like a card's (RunModifiers); its `rule` is carried out by the
## level's RelicEffects and the systems that check RunModifiers.has_relic(). Make one .tres per relic
## in data/relics/. Relics come from elites (a choice of 3), bosses, merchants (rarely, dear) and rare
## events; they show in the HUD's own relic row and carry from chapter to chapter like cards.

## What it does beyond its stats (RunModifiers.RELIC_*; empty = stats only).
@export var rule: StringName = &""
## Its price when a merchant has it.
@export var price: int = 260
## Relics it can't be offered together with (their rules work against each other), by id.
@export var incompatible: Array[StringName] = []


func _init() -> void:
	rarity = Rarity.RARE
	stackable = false
