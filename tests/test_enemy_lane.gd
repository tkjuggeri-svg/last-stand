extends Node2D
## Test-only scene script: shows fortress HP and how many ghouls have spawned.

var _spawned_count: int = 0

@onready var _fortress: Fortress = %Fortress
@onready var _spawner: EnemySpawner = %EnemySpawner
@onready var _label: Label = %StatusLabel


func _ready() -> void:
	_fortress.health.health_changed.connect(_on_health_changed)
	_fortress.destroyed.connect(_update_label)
	_spawner.enemy_spawned.connect(_on_enemy_spawned)
	_update_label()


func _on_enemy_spawned(_enemy: Enemy) -> void:
	_spawned_count += 1
	_update_label()


func _on_health_changed(_current_health: int, _max_health: int) -> void:
	_update_label()


func _update_label() -> void:
	var fortress_text: String = "DESTROYED" if _fortress.health.is_dead() else "%d / %d" % [
		_fortress.health.current_health, _fortress.health.max_health]
	_label.text = "Fortress HP: %s    Ghouls spawned: %d / %d" % [
		fortress_text, _spawned_count, _spawner.spawn_count]
