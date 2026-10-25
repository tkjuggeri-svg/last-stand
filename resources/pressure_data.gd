class_name PressureData
extends Resource
## One Pressure modifier (M12): a difficulty the player turns on before a run for more shards and a title.
## Difficulty only, never power. Stat changes ride on `modifiers` (granted through RunModifiers, hidden); the
## rest is a `rule` key the systems read (PressureRules.RULE_*). data/meta/pressure/.

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var text: String = ""
@export_range(1, 3) var points: int = 1
@export var modifiers: Array[StatModifier] = []
## What else it does (PressureRules.RULE_*); empty: only the stat changes.
@export var rule: StringName = &""
