class_name EndingData
extends Resource
## An ending (M11): which finale boss it belongs to (its EnemyData file name), its title and its paragraphs
## (separated by blank lines). The secret one has no boss: it needs the other endings seen. data/story/endings/.

@export var id: StringName = &""
## The boss that was the run's last (enemy file name, e.g. "fallen_marshal"); empty: the secret ending.
@export var boss: StringName = &""
@export var title: String = ""
@export_multiline var text: String = ""
@export var secret: bool = false
