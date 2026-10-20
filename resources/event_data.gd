class_name EventData
extends Resource
## A run map event (a short scene with 2-3 choices) or shrine (one deal: accept or walk away), from
## data/events/. EventScreen shows it, EventResolver applies the chosen answer.

@export var id: StringName = &""
@export var title: String = ""
@export_multiline var text: String = ""
@export var shrine: bool = false
@export var choices: Array[EventChoice] = []
