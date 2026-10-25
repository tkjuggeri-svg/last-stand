class_name StoryCharacter
extends Resource
## A person in the War Room (M11): who they are and which portrait is theirs (an index into the portraits
## sheet, Portraits). Their lines and beats are StoryLine and StoryBeat resources naming them by id.

@export var id: StringName = &""
@export var display_name: String = ""
@export var role: String = ""
@export var portrait: int = 0
