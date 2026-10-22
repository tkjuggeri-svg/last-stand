class_name EventScreen
extends CanvasLayer
## A run map event or shrine: its picture (the node's icon), title and text, then one button per
## answer with what it will do underneath (an answer that can't be taken now is disabled and says
## why). After the choice it shows what happened and a Continue button. Display and intents only:
## EventResolver decides, Main runs what follows.

signal choice_picked(index: int)
signal continued

const EVENT_ICON: Texture2D = preload("res://assets/sprites/ui/map/node_event.png")
const SHRINE_ICON: Texture2D = preload("res://assets/sprites/ui/map/node_shrine.png")

var _buttons: Array[Button] = []

@onready var _icon: TextureRect = %Icon
@onready var _title: Label = %Title
@onready var _text: Label = %Text
@onready var _choices: VBoxContainer = %Choices
@onready var _result: Label = %Result
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	hide()
	_continue_button.pressed.connect(func() -> void:
		hide()
		continued.emit())


## Shows `event` with its answers; `resolver` says which can be taken.
func open(event: EventData, resolver: EventResolver) -> void:
	_icon.texture = SHRINE_ICON if event.shrine else EVENT_ICON
	_title.text = event.title
	_text.text = event.text
	for child: Node in _choices.get_children():
		child.queue_free()
	_buttons.clear()
	for i: int in event.choices.size():
		var choice: EventChoice = event.choices[i]
		var blocker: String = resolver.choice_blocker(choice)
		var button: Button = Button.new()
		button.text = choice.label + ("   (%s)" % blocker.to_lower() if not blocker.is_empty() else "")
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = not blocker.is_empty()
		button.pressed.connect(func() -> void: choice_picked.emit(i))
		_choices.add_child(button)
		_buttons.append(button)
		if not choice.outcome.is_empty():
			var outcome: Label = Label.new()
			outcome.text = "    " + choice.outcome
			outcome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			outcome.theme_type_variation = &"WarnLabel" if not blocker.is_empty() else &"DimLabel"
			_choices.add_child(outcome)
	_choices.show()
	_result.hide()
	_continue_button.hide()
	show()
	for button: Button in _buttons:
		if not button.disabled:
			button.grab_focus.call_deferred()
			break


## After the choice: what happened, and Continue.
func show_result(text: String) -> void:
	_choices.hide()
	_result.text = text
	_result.show()
	_continue_button.show()
	_continue_button.grab_focus.call_deferred()


func get_choice_button(index: int) -> Button:
	return _buttons[index]


func get_continue_button() -> Button:
	return _continue_button
