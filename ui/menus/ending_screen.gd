class_name EndingScreen
extends CanvasLayer
## An ending (M11): the finale boss's story, shown once the last boss falls and before the Victory
## screen. Display and intent only: Main picks the ending (Story.ending_for) and records it.

signal continued

@onready var _title: Label = %Title
@onready var _text: Label = %Text
@onready var _continue: Button = %ContinueButton


func _ready() -> void:
	hide()
	_continue.pressed.connect(close)


func open(ending: EndingData) -> void:
	_title.text = ending.title
	_text.text = ending.text
	show()
	_continue.grab_focus.call_deferred()


func close() -> void:
	if not visible:
		return
	hide()
	continued.emit()


func get_continue_button() -> Button:
	return _continue
