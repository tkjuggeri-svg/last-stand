extends Node
## Boots the game: runs the level, shows Game Over when the run is lost, and starts a fresh run on Restart.

@export var level_scene: PackedScene

var _level: Level

@onready var _game_over_screen: GameOverScreen = %GameOverScreen


func _ready() -> void:
	assert(level_scene != null, "Main needs a level_scene")
	_game_over_screen.restart_requested.connect(start_run)
	start_run()


## Starts a fresh run, replacing the current level (and all its state) with a new instance.
func start_run() -> void:
	if _level != null:
		# Remove first so the old level never overlaps the new one, even for a frame.
		remove_child(_level)
		_level.queue_free()
	_game_over_screen.hide()
	_level = level_scene.instantiate()
	_level.run_lost.connect(_on_level_run_lost)
	add_child(_level)


func _on_level_run_lost() -> void:
	_game_over_screen.open()
