class_name StoryBeat
extends Resource
## One longer speech of a War Room character (M11), told once when its condition holds: the hub shows the
## next unheard beat of each character (by `order`) as something they want to say. data/story/beats/.

@export var id: StringName = &""
@export var character: StringName = &""
@export var title: String = ""
@export_multiline var text: String = ""
## Beats of one character are told in this order.
@export var order: int = 0
@export var condition: StoryCondition
