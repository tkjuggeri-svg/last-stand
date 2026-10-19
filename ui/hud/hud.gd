extends CanvasLayer
## In-game overlay: fortress and hero HP, gold, enemy counts, the wave and phase (with the "Start
## wave" button and key during the build phase), and short event notifications.
## Assign its targets in the level scene. Parts whose target is not assigned are hidden, so the HUD
## also runs on its own. It only displays and sends the start-wave intent; RunCycle decides.

const INCOMING_COLOR: Color = Color(1.0, 0.65, 0.3, 1)
const SLAIN_COLOR: Color = Color(0.6, 0.9, 0.5, 1)
const GOLD_COLOR: Color = Color(0.95, 0.82, 0.45, 1)
const LIFE_ICON: Texture2D = preload("res://assets/sprites/ui/icon_helm.png")
## A spent life: the helm icon, dark.
const LIFE_SPENT_TINT: Color = Color(0.25, 0.22, 0.28, 1)
const PHASE_COLORS: Dictionary = {
	RunCycle.Phase.BUILD: Color(0.72, 0.84, 0.62, 1),
	RunCycle.Phase.COMBAT: Color(1.0, 0.5, 0.38, 1),
	RunCycle.Phase.CHOOSE: Color(0.94, 0.82, 0.48, 1),
	RunCycle.Phase.FINISHED: Color(0.94, 0.82, 0.48, 1),
}
const PHASE_TEXTS: Dictionary = {
	RunCycle.Phase.BUILD: "Build phase",
	RunCycle.Phase.COMBAT: "Combat",
	RunCycle.Phase.CHOOSE: "Choose an upgrade",
	RunCycle.Phase.FINISHED: "All waves cleared",
}

@export var fortress: Fortress
@export var hero: Hero
@export var spawner: WaveSpawner
@export var economy: Economy
@export var rewards: WaveRewards
@export var builder: TowerBuilder
@export var run_cycle: RunCycle
@export var hero_lives: HeroLives
## The run's upgrades: one icon each (with a stack count) under the wave panel.
@export var modifiers: RunModifiers

@onready var _fortress_bar: HealthBar = %FortressBar
@onready var _hero_bar: HealthBar = %HeroBar
@onready var _enemy_stats_label: Label = %EnemyStatsLabel
@onready var _feed: NotificationFeed = %NotificationFeed
@onready var _gold_row: Control = %GoldRow
@onready var _gold_label: Label = %GoldLabel
@onready var _slots_label: Label = %SlotsLabel
@onready var _slots_row: Control = %SlotsRow
@onready var _enemy_row: Control = %EnemyRow
@onready var _wave_margin: Control = %WaveMargin
@onready var _wave_label: Label = %WaveLabel
@onready var _phase_label: Label = %PhaseLabel
@onready var _start_wave_button: Button = %StartWaveButton
@onready var _lives_icons: HBoxContainer = %LivesIcons
@onready var _lives_status: Label = %LivesStatus
@onready var _upgrade_icons: HFlowContainer = %UpgradeIcons


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
	_wave_margin.visible = run_cycle != null
	_upgrade_icons.visible = modifiers != null
	if modifiers != null:
		modifiers.upgrade_added.connect(_on_upgrade_added)
	_lives_icons.visible = hero_lives != null
	set_process(hero_lives != null)
	if hero_lives != null:
		hero_lives.lives_changed.connect(func(_left: int) -> void: _update_lives())
		hero_lives.hero_respawned.connect(_on_hero_respawned)
		_update_lives()
	_start_wave_button.pressed.connect(_request_start_wave)
	if run_cycle != null:
		run_cycle.phase_changed.connect(func(_phase: RunCycle.Phase) -> void: _update_wave())
	if spawner != null:
		spawner.enemy_spawned.connect(_on_enemy_spawned)
		spawner.enemy_killed.connect(_on_enemy_killed)
		spawner.enemy_counts_changed.connect(_on_enemy_counts_changed)
		spawner.wave_started.connect(_on_wave_started)
		spawner.wave_cleared.connect(_on_wave_cleared)
		_update_wave()
	# The HUD may be ready before them (tree order); their `health` is only set in their _ready().
	if fortress != null:
		if not fortress.is_node_ready():
			await fortress.ready
		_fortress_bar.track(fortress.health)
	if hero != null:
		if not hero.is_node_ready():
			await hero.ready
		_hero_bar.track(hero.health)


func _process(_delta: float) -> void:
	_lives_status.visible = hero_lives.is_respawning()
	if hero_lives.is_respawning():
		_lives_status.text = "Hero back in %d s" % ceili(hero_lives.get_respawn_time_left())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start_wave") and run_cycle != null and run_cycle.can_start_wave():
		_request_start_wave()
		get_viewport().set_input_as_handled()


func _request_start_wave() -> void:
	if run_cycle != null:
		run_cycle.start_wave()


## Wave number, phase, the Start button and the enemy count.
func _update_wave() -> void:
	if run_cycle != null:
		var phase: RunCycle.Phase = run_cycle.get_phase()
		_wave_label.text = "Wave %d / %d" % [mini(run_cycle.get_current_wave_number(), run_cycle.get_wave_count()), run_cycle.get_wave_count()]
		_phase_label.text = PHASE_TEXTS[phase]
		_phase_label.add_theme_color_override(&"font_color", PHASE_COLORS[phase])
		_start_wave_button.visible = run_cycle.can_start_wave()
	if spawner == null:
		return
	if spawner.is_wave_active() or run_cycle == null:
		_enemy_stats_label.text = "Enemies left: %d / %d" % [spawner.get_remaining_count(), spawner.get_wave_enemy_total()]
	elif spawner.has_next_wave():
		_enemy_stats_label.text = "Next wave: %d enemies" % spawner.get_next_wave_enemy_total()
	else:
		_enemy_stats_label.text = "Enemies left: 0"


## An icon per upgrade taken (hover: its name and description); a stacked one shows "xN".
func _on_upgrade_added(data: UpgradeData, stacks: int) -> void:
	var existing: Node = _upgrade_icons.get_node_or_null(NodePath(String(data.id)))
	if existing != null:
		(existing.get_node("Count") as Label).text = "x%d" % stacks
		return
	var icon: TextureRect = TextureRect.new()
	icon.name = String(data.id)
	icon.texture = data.icon
	icon.custom_minimum_size = Vector2(32, 32)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.tooltip_text = "%s\n%s" % [data.display_name, data.description]
	var count: Label = Label.new()
	count.name = "Count"
	count.position = Vector2(14, 10)
	icon.add_child(count)
	_upgrade_icons.add_child(icon)
	_feed.push("Upgrade: %s" % data.display_name, GOLD_COLOR)


## One helm per life next to the hero's HP bar (spent ones dark).
func _update_lives() -> void:
	while _lives_icons.get_child_count() < hero_lives.get_max_lives():
		var icon: TextureRect = TextureRect.new()
		icon.texture = LIFE_ICON
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_lives_icons.add_child(icon)
	var left: int = hero_lives.get_lives_left()
	for i: int in _lives_icons.get_child_count():
		(_lives_icons.get_child(i) as CanvasItem).modulate = Color.WHITE if i < left else LIFE_SPENT_TINT


func _on_hero_respawned() -> void:
	_feed.push("The hero returns!", SLAIN_COLOR)
	_update_lives()


func _on_wave_started(wave_number: int) -> void:
	_feed.push("Wave %d begins!" % wave_number, INCOMING_COLOR)
	_update_wave()


func _on_wave_cleared(wave_number: int) -> void:
	_feed.push("Wave %d cleared!" % wave_number, SLAIN_COLOR)
	_update_wave()


func _on_enemy_spawned(enemy: Enemy) -> void:
	_feed.push("%s incoming!" % enemy.data.display_name, INCOMING_COLOR)


func _on_enemy_killed(enemy: Enemy) -> void:
	_feed.push("%s slain!" % enemy.data.display_name, SLAIN_COLOR)


func _on_enemy_counts_changed(_living_count: int, _spawned_count: int) -> void:
	_update_wave()


func _on_gold_changed(gold: int) -> void:
	_gold_label.text = str(gold)


func _on_perfect_defense_awarded(bonus: int) -> void:
	_feed.push("Perfect defense! +%d gold" % bonus, GOLD_COLOR)


func _on_tower_sold(_slot: BuildSlot, refund: int) -> void:
	_update_slots()
	_feed.push("Tower sold: +%d gold" % refund, GOLD_COLOR)


func _update_slots() -> void:
	_slots_label.text = "Tower slots free: %d / %d" % [builder.get_free_slot_count(), builder.get_slots().size()]
