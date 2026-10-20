class_name RunData
extends Resource
## A whole run: its chapters in order. Beating the last chapter's boss wins the run. The chapter
## count is data: a new chapter (M10's maps) is one more ChapterData here.

@export var chapters: Array[ChapterData] = []
