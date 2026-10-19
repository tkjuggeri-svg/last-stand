extends Node
## Boots the game: runs the level, shows Game Over when the run is lost or Victory when it is won,
## and starts a fresh run on Restart from either screen.

const LOSS_TEXT: Dictionary = {
	Level.LossReason.FORTRESS_DESTROYED: "The fortress has fallen.",
	Level.LossReason.HERO_KILLED: "The hero has fallen.",
}
const VICTORY_TEXT: String = "The fortress stands. All %d waves held."

@export var level_scene: PackedScene

var _level: Level

@onready var _game_over_screen: GameOverScreen = %GameOverScreen
@onready var _victory_screen: VictoryScreen = %VictoryScreen


func _ready() -> void:
	assert(level_scene != null, "Main needs a level_scene")
	_game_over_screen.restart_requested.connect(start_run)
	_victory_screen.restart_requested.connect(start_run)
	start_run()


## Starts a fresh run, replacing the current level (and all its state) with a new instance.
func start_run() -> void:
	if _level != null:
		# Remove first so the old level never overlaps the new one, even for a frame.
		remove_child(_level)
		_level.queue_free()
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
