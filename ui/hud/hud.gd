extends CanvasLayer
## In-game overlay: fortress and hero HP, the dash cooldown, a boss's big HP bar (top centre) and
## banners when a boss arrives or falls, gold, enemy counts, the wave and phase (with the "Start
## wave" button and key during the build phase, and the Quartermaster's repairs / life buy-back), and
## short event notifications.
## The bottom-left panel, the wave panel and the Quartermaster panel turn see-through while the hero
## is behind them (SeeThrough).
## Assign its targets in the level scene. Parts whose target is not assigned are hidden, so the HUD
## also runs on its own. It only displays and sends the start-wave intent; RunCycle decides.

const START_WAVE_TEXT: String = "Start wave  [Enter]"
const EARLY_CALL_TEXT: String = "Next wave now +%d  [Enter]"
const INCOMING_COLOR: Color = Color(1.0, 0.65, 0.3, 1)
const SLAIN_COLOR: Color = UiColors.GOOD
const GOLD_COLOR: Color = UiColors.GOLD
## The dash row while the dash recharges (it is bright again when ready).
const DASH_COOLING_TINT: Color = Color(0.55, 0.55, 0.62, 1)
const BOSS_ARRIVES_COLOR: Color = Color(0.86, 0.6, 0.95, 1)
## Banner timing: fade in, stay, fade out (seconds).
const BANNER_TIMES: Vector3 = Vector3(0.3, 1.8, 0.7)
const LIFE_ICON: Texture2D = preload("res://assets/sprites/ui/icon_helm.png")
## A spent life: the helm icon, dark.
const LIFE_SPENT_TINT: Color = Color(0.25, 0.22, 0.28, 1)
const PHASE_COLORS: Dictionary = {
	RunCycle.Phase.BUILD: Color(0.72, 0.84, 0.62, 1),
	RunCycle.Phase.COMBAT: Color(1.0, 0.5, 0.38, 1),
	RunCycle.Phase.CHOOSE: UiColors.GOLD,
	RunCycle.Phase.FINISHED: UiColors.GOLD,
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
## Between-waves repairs and life buy-back, offered under the wave panel.
@export var quartermaster: Quartermaster
## The run's relic rules (their messages go to the feed). Optional.
@export var relic_effects: RelicEffects

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
@onready var _upgrade_icons: RunIconsRow = %UpgradeIcons
@onready var _relic_icons: RunIconsRow = %RelicIcons
@onready var _dash_row: Control = %DashRow
@onready var _dash_bar: ProgressBar = %DashBar
@onready var _dash_label: Label = %DashLabel
@onready var _boss_margin: Control = %BossMargin
@onready var _boss_name: Label = %BossName
@onready var _boss_bar: ProgressBar = %BossBar
@onready var _banner: Label = %Banner
@onready var _services: ServicesPanel = %ServicesPanel

## The boss whose HP the top bar shows (null when none is alive).
var _boss: Enemy
var _banner_tween: Tween
## Enemy types already introduced by their hint in this level.
var _hinted: Dictionary = {}


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
		rewards.early_call_paid.connect(func(bonus: int) -> void:
			Sfx.play(self, &"gold")
			_feed.push("Called early: +%d gold" % bonus, GOLD_COLOR))
	_slots_label.visible = builder != null
	_slots_row.visible = builder != null
	if builder != null:
		builder.tower_built.connect(func(_s: BuildSlot, _t: Tower) -> void: _update_slots())
		builder.tower_sold.connect(_on_tower_sold)
		_update_slots()
	_wave_margin.visible = run_cycle != null
	_upgrade_icons.setup(modifiers)
	_relic_icons.setup(modifiers)
	if modifiers != null:
		modifiers.upgrade_added.connect(func(data: UpgradeData, _stacks: int) -> void:
			_feed.push("%s: %s" % ["Relic" if data is RelicData else "Upgrade", data.display_name], GOLD_COLOR))
	if relic_effects != null:
		relic_effects.triggered.connect(func(text: String) -> void: _feed.push(text, GOLD_COLOR))
	_lives_icons.visible = hero_lives != null
	_dash_row.visible = hero != null
	set_process(hero_lives != null or hero != null)
	if hero_lives != null:
		hero_lives.lives_changed.connect(func(_left: int) -> void: _update_lives())
		hero_lives.hero_respawned.connect(_on_hero_respawned)
		_update_lives()
	_start_wave_button.pressed.connect(_request_start_wave)
	_services.setup(quartermaster)
	if quartermaster != null:
		quartermaster.fortress_repaired.connect(func(amount: int, _cost: int) -> void: _feed.push("Walls repaired: +%d" % amount, SLAIN_COLOR))
		quartermaster.life_bought.connect(func(_cost: int) -> void: _feed.push("A life bought back!", SLAIN_COLOR))
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
		for fade: SeeThrough in [%SeeThrough, %WaveSeeThrough, _services.get_node("%SeeThrough")]:
			fade.track(hero)
		if not hero.is_node_ready():
			await hero.ready
		_hero_bar.track(hero.health)


func _process(_delta: float) -> void:
	if hero != null and hero.is_node_ready():
		_update_dash(hero.get_dash())
	if hero_lives == null:
		return
	_lives_status.visible = hero_lives.is_respawning()
	if hero_lives.is_respawning():
		_lives_status.text = "Hero back in %d s" % ceili(hero_lives.get_respawn_time_left())


## The bar fills up as the dash recharges; "Ready" (bright) once it can be used again.
func _update_dash(dash: HeroDash) -> void:
	var left: float = dash.get_cooldown_left()
	_dash_bar.value = 1.0 - left / dash.get_cooldown() if left > 0.0 else 1.0
	_dash_label.text = "Ready" if left <= 0.0 else "%.1f s" % left
	_dash_row.modulate = Color.WHITE if left <= 0.0 else DASH_COOLING_TINT


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start_wave") and run_cycle != null and (run_cycle.can_start_wave() or run_cycle.can_call_early()):
		_request_start_wave()
		get_viewport().set_input_as_handled()


## Starts the wave in the build phase, or calls the next one early during a fight (M8).
func _request_start_wave() -> void:
	if run_cycle != null and not run_cycle.start_wave():
		run_cycle.call_early()


## Wave number, phase, the Start button and the enemy count.
func _update_wave() -> void:
	if run_cycle != null:
		var phase: RunCycle.Phase = run_cycle.get_phase()
		_wave_label.text = "Wave %d / %d" % [mini(run_cycle.get_current_wave_number(), run_cycle.get_wave_count()), run_cycle.get_wave_count()]
		_phase_label.text = PHASE_TEXTS[phase]
		_phase_label.add_theme_color_override(&"font_color", PHASE_COLORS[phase])
		var early: bool = run_cycle.can_call_early()
		_start_wave_button.visible = run_cycle.can_start_wave() or early
		_start_wave_button.text = EARLY_CALL_TEXT % (rewards.early_call_bonus() if rewards != null else 0) if early else START_WAVE_TEXT
	if spawner == null:
		return
	if spawner.is_wave_active() or run_cycle == null:
		_enemy_stats_label.text = "Enemies left: %d / %d" % [spawner.get_remaining_count(), spawner.get_wave_enemy_total()]
	elif spawner.has_next_wave():
		_enemy_stats_label.text = "Next wave: %d enemies" % spawner.get_next_wave_enemy_total()
	else:
		_enemy_stats_label.text = "Enemies left: 0"


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
	Sfx.play(self, &"wave_start")
	_update_wave()


func _on_wave_cleared(wave_number: int) -> void:
	_feed.push("Wave %d cleared!" % wave_number, SLAIN_COLOR)
	Sfx.play(self, &"wave_clear")
	_update_wave()


func _on_enemy_spawned(enemy: Enemy) -> void:
	var role_color: Color = EnemyRoles.color_of(enemy.data.role)
	_feed.push("%s incoming!" % enemy.data.display_name, role_color)
	if not enemy.data.hint.is_empty() and not _hinted.has(enemy.data):
		_hinted[enemy.data] = true
		show_banner("%s: %s" % [enemy.data.display_name, enemy.data.hint], role_color)
	if enemy.data.is_boss:
		_show_boss(enemy)


func _on_enemy_killed(enemy: Enemy) -> void:
	_feed.push("%s slain!" % enemy.data.display_name, SLAIN_COLOR)
	if enemy.data.is_boss:
		show_banner("%s is slain!" % enemy.data.display_name, GOLD_COLOR)


## The boss's name and HP across the top while it lives, and a banner as it arrives.
func _show_boss(enemy: Enemy) -> void:
	_boss = enemy
	_boss_name.text = enemy.data.display_name
	var health: HealthComponent = enemy.get_health()
	health.health_changed.connect(_on_boss_health_changed)
	_on_boss_health_changed(health.current_health, health.max_health)
	enemy.tree_exiting.connect(_on_boss_gone.bind(enemy))
	_boss_margin.show()
	show_banner("%s approaches!" % enemy.data.display_name, BOSS_ARRIVES_COLOR)


func _on_boss_health_changed(current: int, maximum: int) -> void:
	_boss_bar.max_value = maximum
	_boss_bar.value = current


## Untyped: the boss is being freed when this runs.
func _on_boss_gone(enemy: Variant) -> void:
	if enemy == _boss:
		_boss = null
		_boss_margin.hide()


## Big text in the middle of the upper screen that fades in and out (a boss arriving or falling).
func show_banner(text: String, color: Color) -> void:
	_banner.text = text
	_banner.add_theme_color_override(&"font_color", color)
	_banner.modulate.a = 0.0
	_banner.show()
	if _banner_tween != null:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, BANNER_TIMES.x)
	_banner_tween.tween_interval(BANNER_TIMES.y)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, BANNER_TIMES.z)
	_banner_tween.tween_callback(_banner.hide)


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
