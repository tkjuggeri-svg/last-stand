class_name PauseMenu
extends CanvasLayer
## The pause menu: Resume, Settings, Restart, Quit. While open the game is truly frozen: the tree is
## paused and time stands still (Engine.time_scale 0, so even the always-running sprites stop). Main
## decides when it may open (not during the upgrade choice or after the run) and what Restart and
## Quit mean; this only shows the menu and reports the player's choice.

signal restart_requested
signal quit_requested

## True while open (it only ever ends its own pause).
var _paused_by_us: bool = false
var _time_scale: float = 1.0

@onready var _resume_button: Button = %ResumeButton
@onready var _settings_button: Button = %SettingsButton
@onready var _restart_button: Button = %RestartButton
@onready var _quit_button: Button = %QuitButton
@onready var _buttons: Control = %Buttons
@onready var _settings: SettingsMenu = %SettingsMenu


func _ready() -> void:
	hide()
	_resume_button.pressed.connect(close)
	_settings_button.pressed.connect(_open_settings)
	_restart_button.pressed.connect(func() -> void:
		close()
		restart_requested.emit())
	_quit_button.pressed.connect(func() -> void: quit_requested.emit())
	_settings.closed.connect(_on_settings_closed)


func _exit_tree() -> void:
	if _paused_by_us:
		close()


func is_open() -> bool:
	return visible


func open() -> void:
	if is_open():
		return
	_paused_by_us = true
	get_tree().paused = true
	_time_scale = Engine.time_scale
	Engine.time_scale = 0.0
	_settings.hide()
	_buttons.show()
	show()
	_resume_button.grab_focus.call_deferred()


func close() -> void:
	if not is_open():
		return
	hide()
	_settings.hide()
	if _paused_by_us:
		_paused_by_us = false
		Engine.time_scale = _time_scale
		get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _settings.visible:
			_settings.close()
		else:
			close()


func _open_settings() -> void:
	_buttons.hide()
	_settings.open()


func _on_settings_closed() -> void:
	_buttons.show()
	_settings_button.grab_focus.call_deferred()
