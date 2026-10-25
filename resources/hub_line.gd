class_name HubLine
extends Resource
## What a War Room character says now, in one line (M11; the reactive lines of M8 as data): of the lines
## of a character whose condition holds, the one with the highest priority is shown. data/story/lines/.

@export var character: StringName = &""
@export_multiline var text: String = ""
@export var priority: int = 0
@export var condition: StoryCondition
