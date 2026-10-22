class_name PauseMenu
extends CanvasLayer
## The pause menu: Resume, Settings, Restart, Quit. While open the game is truly frozen: the tree is
## paused and time stands still (Engine.time_scale 0, so even the always-running sprites stop). Main
## decides when it may open (not during the upgrade choice or after the run) and what Restart and
## Quit mean; this only shows the menu and reports the player's choice. It shows the run's seed, and a
## new run can be started from any seed typed in (to replay or share a run).

signal restart_requested
signal quit_requested
## A new run from `run_seed` was asked for.
signal seed_run_requested(run_seed: int)

## True while open (it only ever ends its own pause).
var _paused_by_us: bool = false
var _time_scale: float = 1.0

@onready var _resume_button: Button = %ResumeButton
@onready var _settings_button: Button = %SettingsButton
@onready var _restart_button: Button = %RestartButton
@onready var _quit_button: Button = %QuitButton
@onready var _panel: Control = %Panel
@onready var _settings: SettingsMenu = %SettingsMenu
@onready var _seed_label: Label = %SeedLabel
@onready var _seed_edit: LineEdit = %SeedEdit
@onready var _seed_run_button: Button = %SeedRunButton


func _ready() -> void:
	hide()
	_resume_button.pressed.connect(close)
	_settings_button.pressed.connect(_open_settings)
	_restart_button.pressed.connect(func() -> void:
		close()
		restart_requested.emit())
	_quit_button.pressed.connect(func() -> void: quit_requested.emit())
	_settings.closed.connect(_on_settings_closed)
	_seed_run_button.pressed.connect(_on_seed_run_pressed)
	_seed_edit.text_submitted.connect(func(_text: String) -> void: _on_seed_run_pressed())


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
	_panel.show()
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


## Shows the current run's seed (-1: none).
func show_seed(run_seed: int) -> void:
	_seed_label.text = "Seed %d" % run_seed if run_seed >= 0 else ""
	_seed_edit.text = ""


## The Restart button's text (Main: "Abandon run" when runs pay into the profile).
func set_restart_text(text: String) -> void:
	_restart_button.text = text


## A typed seed (digits only), or -1 if there is none.
func get_typed_seed() -> int:
	var text: String = _seed_edit.text.strip_edges()
	return int(text) if text.is_valid_int() and int(text) >= 0 else -1


func _on_seed_run_pressed() -> void:
	var typed: int = get_typed_seed()
	if typed < 0:
		_seed_edit.grab_focus()
		return
	close()
	seed_run_requested.emit(typed)


func _open_settings() -> void:
	_panel.hide()
	_settings.open()


func _on_settings_closed() -> void:
	_panel.show()
	_settings_button.grab_focus.call_deferred()
