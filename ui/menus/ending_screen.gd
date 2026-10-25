class_name EndingScreen
extends CanvasLayer
## An ending (M11): the finale boss's story, shown once the last boss falls and before the Victory
## screen. Display and intent only: Main picks the ending (Story.ending_for) and records it.

## The player stops here: the run is won and over.
signal continued
## The player goes on: Endless, the next chapter one depth deeper.
signal descend_requested

@onready var _picture: TextureRect = %Picture
@onready var _title: Label = %Title
@onready var _text: Label = %Text
@onready var _continue: Button = %ContinueButton
@onready var _descend: Button = %DescendButton


func _ready() -> void:
	hide()
	_continue.pressed.connect(close)
	_descend.pressed.connect(func() -> void:
		hide()
		descend_requested.emit())


func open(ending: EndingData, can_descend: bool = false) -> void:
	_picture.texture = ending.illustration
	_picture.visible = ending.illustration != null
	_title.text = ending.title
	_text.text = ending.text
	_descend.visible = can_descend
	show()
	_continue.grab_focus.call_deferred()


func close() -> void:
	if not visible:
		return
	hide()
	continued.emit()


func get_descend_button() -> Button:
	return _descend


func get_continue_button() -> Button:
	return _continue
