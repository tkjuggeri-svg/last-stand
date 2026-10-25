class_name TitleScreen
extends CanvasLayer
## The title screen (M8; its key art, M8.5: tools/art/title_art.gd): Continue (when a run is saved), Play (to the War Room), Settings, Quit, and a
## notice if the save had to fall back (SaveManager.load_problem). Display and intents only: Main's
## front end decides.

signal continue_requested
signal play_requested
signal quit_requested

@onready var _continue_button: Button = %ContinueButton
@onready var _play_button: Button = %PlayButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _credits_button: Button = %CreditsButton
@onready var _credits: CreditsScreen = %CreditsScreen
@onready var _notice: Label = %Notice
@onready var _menu: Control = %Menu
@onready var _settings: SettingsMenu = %SettingsMenu


func _ready() -> void:
	hide()
	_continue_button.pressed.connect(func() -> void: continue_requested.emit())
	_play_button.pressed.connect(func() -> void: play_requested.emit())
	_quit_button.pressed.connect(func() -> void: quit_requested.emit())
	_settings_button.pressed.connect(_open_settings)
	_credits_button.pressed.connect(_credits.open)
	_credits.closed.connect(func() -> void:
		Music.play(self, &"title")
		_credits_button.grab_focus.call_deferred())
	_settings.closed.connect(func() -> void:
		_menu.show()
		_settings_button.grab_focus.call_deferred())


## Shows the title: Continue only with a saved run; `notice` (e.g. a save problem) under the buttons.
func open(can_continue: bool, notice: String) -> void:
	_continue_button.visible = can_continue
	_notice.text = notice
	_notice.visible = not notice.is_empty()
	_settings.hide()
	_menu.show()
	show()
	(_continue_button if can_continue else _play_button).grab_focus.call_deferred()


func get_continue_button() -> Button:
	return _continue_button


func get_credits_button() -> Button:
	return _credits_button


func get_credits() -> CreditsScreen:
	return _credits


func get_play_button() -> Button:
	return _play_button


func _open_settings() -> void:
	_menu.hide()
	_settings.open()
