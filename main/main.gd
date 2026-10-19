extends Node
## Boots the game: loads and applies the player's settings, runs the level, shows Game Over when the
## run is lost or Victory when it is won, and starts a fresh run on Restart from either screen. The
## pause action opens the pause menu, unless something else holds the game (the upgrade choice) or
## the run is over; a menu that is open in the level (the build menu) takes Esc first.

const LOSS_TEXT: Dictionary = {
	Level.LossReason.FORTRESS_DESTROYED: "The fortress has fallen.",
	Level.LossReason.HERO_KILLED: "The hero has fallen.",
}
const VICTORY_TEXT: String = "The fortress stands. All %d waves held."

@export var level_scene: PackedScene

var _level: Level

@onready var _game_over_screen: GameOverScreen = %GameOverScreen
@onready var _victory_screen: VictoryScreen = %VictoryScreen
@onready var _pause_menu: PauseMenu = %PauseMenu


func _ready() -> void:
	assert(level_scene != null, "Main needs a level_scene")
	GameSettings.load_and_apply()
	_game_over_screen.restart_requested.connect(start_run)
	_victory_screen.restart_requested.connect(start_run)
	_pause_menu.restart_requested.connect(start_run)
	_pause_menu.quit_requested.connect(quit_game)
	start_run()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and can_pause():
		get_viewport().set_input_as_handled()
		_pause_menu.open()


## Not while another screen holds the game (the upgrade choice pauses it) or after the run.
func can_pause() -> bool:
	return _level != null and not _level.is_run_over() and not get_tree().paused and not _pause_menu.is_open()


func quit_game() -> void:
	get_tree().quit()


## Starts a fresh run, replacing the current level (and all its state) with a new instance.
func start_run() -> void:
	if _level != null:
		# Remove first so the old level never overlaps the new one, even for a frame.
		remove_child(_level)
		_level.queue_free()
	_pause_menu.close()
	_game_over_screen.hide()
	_victory_screen.hide()
	_level = level_scene.instantiate()
	_level.run_lost.connect(_on_level_run_lost)
	_level.run_won.connect(_on_level_run_won)
	add_child(_level)


func _on_level_run_lost(reason: Level.LossReason) -> void:
	_game_over_screen.open(LOSS_TEXT[reason])


func _on_level_run_won() -> void:
	_victory_screen.open(VICTORY_TEXT % _level.spawner.get_wave_count())
