class_name StoryBook
extends Resource
## Everything the story is made of (M11), in one resource Main hands to the front end: the War Room's
## characters, their lines and beats, the endings and the Chronicle's entries. data/story/story_book.tres.

@export var characters: Array[StoryCharacter] = []
@export var lines: Array[HubLine] = []
@export var beats: Array[StoryBeat] = []
@export var endings: Array[EndingData] = []
@export var lore: Array[LoreEntry] = []
