extends CanvasLayer
## In-game overlay: fortress and hero HP, enemy counts, and short event notifications.
## Assign fortress, hero and spawner in the level scene. Parts whose target is not assigned are
## hidden, so the HUD also runs on its own.

const INCOMING_COLOR: Color = Color(1.0, 0.65, 0.3, 1)
const SLAIN_COLOR: Color = Color(0.6, 0.9, 0.5, 1)

@export var fortress: Fortress
@export var hero: Hero
@export var spawner: EnemySpawner

@onready var _fortress_bar: HealthBar = %FortressBar
@onready var _hero_bar: HealthBar = %HeroBar
@onready var _enemy_stats_label: Label = %EnemyStatsLabel
@onready var _feed: NotificationFeed = %NotificationFeed


func _ready() -> void:
	_fortress_bar.visible = fortress != null
	_hero_bar.visible = hero != null
	_enemy_stats_label.visible = spawner != null
	if spawner != null:
		spawner.enemy_spawned.connect(_on_enemy_spawned)
		spawner.enemy_killed.connect(_on_enemy_killed)
		spawner.enemy_counts_changed.connect(_on_enemy_counts_changed)
		_on_enemy_counts_changed(spawner.get_living_count(), spawner.get_spawned_count())
	# The HUD may be ready before them (tree order); their `health` is only set in their _ready().
	if fortress != null:
		if not fortress.is_node_ready():
			await fortress.ready
		_fortress_bar.track(fortress.health)
	if hero != null:
		if not hero.is_node_ready():
			await hero.ready
		_hero_bar.track(hero.health)


func _on_enemy_spawned(enemy: Enemy) -> void:
	_feed.push("%s incoming!" % enemy.data.display_name, INCOMING_COLOR)


func _on_enemy_killed(enemy: Enemy) -> void:
	_feed.push("%s slain!" % enemy.data.display_name, SLAIN_COLOR)


func _on_enemy_counts_changed(living_count: int, spawned_count: int) -> void:
	_enemy_stats_label.text = "Enemies alive: %d    Spawned: %d" % [living_count, spawned_count]
