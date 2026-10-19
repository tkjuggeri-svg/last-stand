extends CanvasLayer
## In-game overlay: fortress and hero HP, gold, enemy counts, and short event notifications.
## Assign fortress, hero, spawner, economy and rewards in the level scene. Parts whose target is not
## assigned are hidden, so the HUD also runs on its own.

const INCOMING_COLOR: Color = Color(1.0, 0.65, 0.3, 1)
const SLAIN_COLOR: Color = Color(0.6, 0.9, 0.5, 1)
const GOLD_COLOR: Color = Color(0.95, 0.82, 0.45, 1)

@export var fortress: Fortress
@export var hero: Hero
@export var spawner: WaveSpawner
@export var economy: Economy
@export var rewards: WaveRewards
@export var builder: TowerBuilder

@onready var _fortress_bar: HealthBar = %FortressBar
@onready var _hero_bar: HealthBar = %HeroBar
@onready var _enemy_stats_label: Label = %EnemyStatsLabel
@onready var _feed: NotificationFeed = %NotificationFeed
@onready var _gold_row: Control = %GoldRow
@onready var _gold_label: Label = %GoldLabel
@onready var _slots_label: Label = %SlotsLabel
@onready var _slots_row: Control = %SlotsRow
@onready var _enemy_row: Control = %EnemyRow


func _ready() -> void:
	_fortress_bar.visible = fortress != null
	_hero_bar.visible = hero != null
	_enemy_stats_label.visible = spawner != null
	_enemy_row.visible = spawner != null
	_gold_row.visible = economy != null
	if economy != null:
		if not economy.is_node_ready():
			await economy.ready
		economy.gold_changed.connect(_on_gold_changed)
		_on_gold_changed(economy.get_gold())
	if rewards != null:
		rewards.perfect_defense_awarded.connect(_on_perfect_defense_awarded)
	_slots_label.visible = builder != null
	_slots_row.visible = builder != null
	if builder != null:
		builder.tower_built.connect(func(_s: BuildSlot, _t: Tower) -> void: _update_slots())
		builder.tower_sold.connect(_on_tower_sold)
		_update_slots()
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


func _on_gold_changed(gold: int) -> void:
	_gold_label.text = str(gold)


func _on_perfect_defense_awarded(bonus: int) -> void:
	_feed.push("Perfect defense! +%d gold" % bonus, GOLD_COLOR)


func _on_tower_sold(_slot: BuildSlot, refund: int) -> void:
	_update_slots()
	_feed.push("Tower sold: +%d gold" % refund, GOLD_COLOR)


func _update_slots() -> void:
	_slots_label.text = "Tower slots free: %d / %d" % [builder.get_free_slot_count(), builder.get_slots().size()]
