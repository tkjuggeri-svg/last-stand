class_name FrontEnd
extends Node
## The screens around the runs (M8): the title, the War Room (hub) and the run summary, with the fade
## between them and the game. Owned by Main, which calls down (show_title, show_summary) and starts or
## resumes a run when asked (signals up). The hub's rules go through MetaProgress and the profile is
## saved by SaveManager: buying an unlock, the tips switch, resetting progress.

signal run_requested
signal continue_requested
signal quit_requested

## The unlock board the hub shows (the same one Main gives the runs).
@export var unlock_board: UnlockBoard

@onready var _save: SaveManagerNode = get_node("/root/SaveManager")
@onready var _title: TitleScreen = %TitleScreen
@onready var _hub: HubScreen = %HubScreen
@onready var _summary: RunSummaryScreen = %RunSummaryScreen
@onready var _fade: ScreenFade = %ScreenFade


func _ready() -> void:
	_title.play_requested.connect(func() -> void: _fade.transition(show_hub))
	_title.continue_requested.connect(func() -> void: _leave(continue_requested))
	_title.quit_requested.connect(func() -> void: quit_requested.emit())
	_hub.start_requested.connect(func() -> void: _leave(run_requested))
	_hub.back_requested.connect(func() -> void: _fade.transition(show_title))
	_hub.buy_requested.connect(_buy)
	_hub.tips_toggled.connect(_set_tips)
	_hub.reset_requested.connect(_reset)
	_summary.hub_requested.connect(func() -> void: _fade.transition(show_hub))
	_summary.new_run_requested.connect(func() -> void: _leave(run_requested))
	_save.changed.connect(func() -> void:
		if _hub.visible:
			_hub.refresh(_save.profile, unlock_board))


## True while one of its screens is shown.
func is_open() -> bool:
	return _title.visible or _hub.visible or _summary.visible


## The title: Continue when a run is saved, and any problem the save had.
func show_title() -> void:
	hide_all()
	_title.open(not _save.profile.run.is_empty(), _save.load_problem)


func show_hub() -> void:
	hide_all()
	_hub.open(_save.profile, unlock_board)


## The end of a run (`summary`: RunSummary's, with its shard lines), faded in; `at_dark` (Main
## clearing the game away) is called while the screen is dark.
func show_summary(summary: Dictionary, at_dark: Callable = Callable()) -> void:
	_fade.transition(func() -> void:
		if at_dark.is_valid():
			at_dark.call()
		hide_all()
		_summary.open(summary))


func hide_all() -> void:
	_title.hide()
	_hub.hide()
	_summary.hide()


func get_title() -> TitleScreen:
	return _title


func get_hub() -> HubScreen:
	return _hub


func get_summary() -> RunSummaryScreen:
	return _summary


## Fades out of the front end and asks Main (through `request`) for the run.
func _leave(request: Signal) -> void:
	_fade.transition(func() -> void:
		hide_all()
		request.emit())


func _buy(unlock: UnlockData) -> void:
	if MetaProgress.buy(_save.profile, unlock_board, unlock):
		_save.save_profile()  # the hub refreshes on the save


## Tips back on shows every tip again, from the start.
func _set_tips(on: bool) -> void:
	if on and _save.profile.hints_off:
		_save.profile.hints_seen.clear()
	_save.profile.hints_off = not on
	_save.save_profile()


func _reset() -> void:
	_save.reset_profile()
