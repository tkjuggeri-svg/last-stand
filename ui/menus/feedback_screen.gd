class_name FeedbackScreen
extends CanvasLayer
## The in-game feedback box (the feedback action, F8 by default, rebindable): it takes a screenshot of
## the game as it is, pauses, and asks for a short note. Save reports `submitted` (Main saves the note,
## the screenshot and the run's state, then shows where with show_saved()); Cancel or Esc closes it.
## Works on every screen, paused or not. Display and intents only.

signal submitted(note: String, screenshot: Image)

## False switches the key off (e.g. while another text box has the keyboard).
var enabled: bool = true

var _screenshot: Image
## True while this box holds the game paused (it only ever ends its own pause).
var _paused_by_us: bool = false
## Where the last report was saved.
var _folder: String = ""

@onready var _note: TextEdit = %Note
@onready var _save_button: Button = %SaveButton
@onready var _cancel_button: Button = %CancelButton
@onready var _form: Control = %Form
@onready var _done: Control = %Done
@onready var _saved_label: Label = %SavedLabel
@onready var _open_button: Button = %OpenFolderButton
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	hide()
	_save_button.pressed.connect(_save)
	_cancel_button.pressed.connect(close)
	_close_button.pressed.connect(close)
	_open_button.pressed.connect(func() -> void: OS.shell_open(_folder))


func _exit_tree() -> void:
	if _paused_by_us:
		get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if not is_open() and enabled and event.is_action_pressed("feedback"):
		get_viewport().set_input_as_handled()
		open()


func _input(event: InputEvent) -> void:
	if not is_open():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func is_open() -> bool:
	return visible


## Takes the screenshot (before the box covers the game), pauses and shows the empty box.
func open() -> void:
	# No picture without a real display (the headless runs of the tests): the report is saved without it.
	var shown: bool = DisplayServer.get_name() != "headless" and get_viewport().get_texture() != null
	_screenshot = get_viewport().get_texture().get_image() if shown else null
	if not get_tree().paused:
		get_tree().paused = true
		_paused_by_us = true
	_note.text = ""
	_form.show()
	_done.hide()
	show()
	_note.grab_focus.call_deferred()


func close() -> void:
	hide()
	if _paused_by_us:
		_paused_by_us = false
		get_tree().paused = false


## The report was saved in `folder` (an absolute path; "" if it failed).
func show_saved(folder: String) -> void:
	_folder = folder
	_form.hide()
	_done.show()
	_saved_label.text = "Thank you! Saved in:\n%s" % folder if not folder.is_empty() else "Sorry: the report could not be saved."
	_open_button.visible = not folder.is_empty()
	_close_button.grab_focus.call_deferred()


func get_note_edit() -> TextEdit:
	return _note


func get_save_button() -> Button:
	return _save_button


func _save() -> void:
	submitted.emit(_note.text, _screenshot)
