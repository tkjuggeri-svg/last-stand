class_name HintPanel
extends CanvasLayer
## A tutorial hint (M8): a small panel at the bottom right (clear of the HUD) with the tip, "Got it" and "Skip all tips".
## It never pauses the game and takes no keys (Enter starts the wave, Space dashes): it goes by the
## mouse, or by itself after show_time seconds of play (the time stops with the game's). Display and
## intents only: HintDirector decides which tip shows when, and remembers them.

## The tip is gone (Got it, or its time ran out).
signal closed(id: StringName)
signal skip_all_requested

## Seconds a tip stays up if it isn't dismissed.
@export var show_time: float = 9.0

var _id: StringName = &""
var _left: float = 0.0

@onready var _text: Label = %Text
@onready var _got_it: Button = %GotIt
@onready var _skip_all: Button = %SkipAll


func _ready() -> void:
	hide()
	_got_it.pressed.connect(close)
	_skip_all.pressed.connect(func() -> void: skip_all_requested.emit())


func _process(delta: float) -> void:
	if not visible:
		return
	_left -= delta  # delta is 0 while the pause menu stops time
	if _left <= 0.0:
		close()


func show_hint(id: StringName, text: String) -> void:
	_id = id
	_text.text = text
	_left = show_time
	show()


## The tip showing (&"" when none).
func get_current() -> StringName:
	return _id if visible else &""


func get_text() -> String:
	return _text.text


func close() -> void:
	if not visible:
		return
	hide()
	var id: StringName = _id
	_id = &""
	closed.emit(id)
