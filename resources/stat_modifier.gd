class_name StatModifier
extends Resource
## One change to a named run stat (see RunModifiers for the names). A stat's final value is
## (base + every flat) * (1 + every percent), so percents add up instead of multiplying.

@export var stat: StringName = &""
@export var flat: float = 0.0
## 0.2 = +20 %, -0.15 = -15 %.
@export var percent: float = 0.0
