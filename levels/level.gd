class_name Level
extends Node2D
## Root of a playable level. The run is lost when the fortress is destroyed or the hero loses its last
## life (HeroLives), and won when RunCycle reports the last wave cleared: either way everything in the
## level stops, and run_lost / run_won (once, never both) tells the owner (Main) which screen to show.
## It also places one-shot visuals (an enemy's death effect and the "+gold" it was worth) in its
## Effects layer. A boss's death is a big moment: a brief slow-motion hit-stop and a camera shake.
## On a run map (encounter mode) the level stays for a whole chapter and plays one fight at a time:
## start_encounter() loads the fight's waves (towers, gold and damage stay), and when they are cleared
## it gives the fight's reward (gold, a repair, an upgrade choice) and reports encounter_cleared
## instead of run_won. set_active() hides and freezes it while the map is shown.

signal run_lost(reason: LossReason)
signal run_won
## A run map fight was won and its reward taken.
signal encounter_cleared

enum LossReason { FORTRESS_DESTROYED, HERO_KILLED }

const FLOATING_TEXT_SCENE: PackedScene = preload("res://entities/effects/damage_number.tscn")
const GOLD_TEXT_COLOR: Color = Color(0.95, 0.82, 0.45, 1)
## A boss's death: the game runs at this speed for this many real seconds, and the camera shakes.
const BOSS_HIT_STOP_SCALE: float = 0.25
const BOSS_HIT_STOP_TIME: float = 0.5
const BOSS_SHAKE: float = 8.0
const BOSS_SHAKE_TIME: float = 0.6

@export var fortress: Fortress
@export var spawner: WaveSpawner
@export var hero_lives: HeroLives
@export var run_cycle: RunCycle
@export var modifiers: RunModifiers
@export var offers: UpgradeOffers
@export var economy: Economy
## The run map's shop on this level (null on a level without one).
@export var merchant: Merchant
## Applies the run map's events and shrines to this level.
@export var events: EventResolver
@export var builder: TowerBuilder

var _run_over: bool = false
var _encounter_mode: bool = false
## True while a previous chapter's upgrades are put back (their instant effects already happened).
var _carrying_in: bool = false
var _reward: FightReward
## Canvas layers that were showing when the level was set inactive (shown again on activation).
var _hidden_layers: Array[CanvasLayer] = []

@onready var _effects: Node2D = %Effects


func _ready() -> void:
	assert(fortress != null, "Level needs a fortress: %s" % get_path())
	fortress.destroyed.connect(_on_fortress_destroyed)
	if hero_lives != null:
		hero_lives.out_of_lives.connect(func() -> void: _end_run(LossReason.HERO_KILLED))
	if run_cycle != null:
		run_cycle.all_waves_cleared.connect(_on_all_waves_cleared)
	if modifiers != null:
		modifiers.upgrade_added.connect(_on_upgrade_added)
	if spawner != null:
		spawner.enemy_killed.connect(_on_enemy_killed)


func _exit_tree() -> void:
	Engine.time_scale = 1.0  # a restart during a hit-stop must not leave the game slowed


func is_run_over() -> bool:
	return _run_over


## What this chapter hands to the next: its gold plus `refund_ratio` of what every tower cost (packed
## up), the run's upgrades, the hero's lives and the fortress's HP.
func carry_out(refund_ratio: float) -> ChapterCarry:
	var carry: ChapterCarry = ChapterCarry.new()
	var invested: int = 0
	for slot: BuildSlot in builder.get_slots():
		if not slot.is_empty():
			invested += slot.tower.invested
	carry.refund = floori(invested * refund_ratio)
	carry.gold = economy.get_gold() + carry.refund
	carry.upgrades = modifiers.get_taken()
	carry.lives_left = hero_lives.get_lives_left()
	carry.fortress_health = fortress.health.current_health
	return carry


## Starts this chapter from the previous one's `carry`: its gold, its upgrades (their instant effects
## not again), its lives, and the fortress at its HP plus `repair` of the max. Call once it is ready.
func carry_in(carry: ChapterCarry, repair: float) -> void:
	economy.earn(carry.gold - economy.get_gold(), Economy.Source.REFUND)
	if economy.get_gold() > carry.gold:
		economy.try_spend(economy.get_gold() - carry.gold)
	_carrying_in = true
	for data: UpgradeData in carry.upgrades:
		modifiers.add_upgrade(data)
	_carrying_in = false
	hero_lives.set_lives_left(carry.lives_left)
	var health: HealthComponent = fortress.health
	health.set_current_health(carry.fortress_health + roundi(health.max_health * repair))


## Stops the level as won (the run map's last boss fell): everything freezes, like at Game Over.
func end_run_won() -> void:
	if _stop():
		run_won.emit()


func is_encounter_mode() -> bool:
	return _encounter_mode


## Plays a run map fight next on this level: its waves (each with a build phase before it, no upgrade
## choice between them), then `reward`. Returns false while a wave is still running.
func start_encounter(waves: Array[WaveData], reward: FightReward) -> bool:
	if not spawner.load_waves(waves):
		return false
	_encounter_mode = true
	_reward = reward
	run_cycle.choose_between_waves = false
	run_cycle.restart()
	return true


## Shows and runs the level, or hides and freezes it (with its HUD and menus) while the map is shown.
func set_active(active: bool) -> void:
	if active:
		for layer: CanvasLayer in _hidden_layers:
			layer.visible = true
		_hidden_layers.clear()
	else:
		for child: Node in get_children():
			var layer: CanvasLayer = child as CanvasLayer
			if layer != null and layer.visible:
				layer.visible = false
				_hidden_layers.append(layer)
	visible = active
	if not _run_over:
		process_mode = PROCESS_MODE_INHERIT if active else PROCESS_MODE_DISABLED


func is_active() -> bool:
	return visible


func _on_fortress_destroyed() -> void:
	_end_run(LossReason.FORTRESS_DESTROYED)


## Upgrades that do something once when picked.
func _on_upgrade_added(data: UpgradeData, _stacks: int) -> void:
	if _carrying_in:
		return
	if data.instant_effect == RunModifiers.INSTANT_REPAIR_FORTRESS:
		fortress.repair(data.effect_amount)


func _on_all_waves_cleared() -> void:
	if _encounter_mode:
		_give_reward()
	elif _stop():
		run_won.emit()


## The fight's gold and repair at once, then its upgrade choice (if any); encounter_cleared once taken.
func _give_reward() -> void:
	if _run_over:
		return
	if _reward == null:
		encounter_cleared.emit()
		return
	if _reward.gold > 0 and economy != null:
		economy.earn(_reward.gold, Economy.Source.REWARD)
	if _reward.repair > 0.0:
		fortress.repair(_reward.repair)
	if _reward.cards > 0 and offers != null and not offers.make_offer(_reward.cards, _reward.rare_only).is_empty():
		offers.picked.connect(func(_data: UpgradeData) -> void: encounter_cleared.emit(), CONNECT_ONE_SHOT)
		return
	encounter_cleared.emit()


func _end_run(reason: LossReason) -> void:
	if _stop():
		run_lost.emit(reason)


## Freezes the level once; returns false if the run was already over (a loss and a win in the same
## moment: whichever came first counts).
func _stop() -> bool:
	if _run_over:
		return false
	_run_over = true
	# Disabling the level stops every node in it (hero, enemies, spawner) and takes their collision
	# shapes out of physics. Deferred, because this runs inside a physics callback (an enemy hit).
	# Nodes set to PROCESS_MODE_ALWAYS (the hero's sprite) keep animating, so the death plays out.
	set_deferred("process_mode", PROCESS_MODE_DISABLED)
	return true


func _on_enemy_killed(enemy: Enemy) -> void:
	var at: Vector2 = _effects.to_local(enemy.global_position)
	if enemy.data.death_effect != null:
		var effect: Node2D = enemy.data.death_effect.instantiate()
		effect.position = at
		_effects.add_child(effect)
	if enemy.data.gold_reward > 0:
		var gold_text: DamageNumber = FLOATING_TEXT_SCENE.instantiate()
		gold_text.set_text("+%d" % enemy.data.gold_reward, GOLD_TEXT_COLOR)
		gold_text.position = at + Vector2(0, -30)
		_effects.add_child(gold_text)
	if enemy.data.is_boss:
		_boss_moment()


func _boss_moment() -> void:
	Engine.time_scale = BOSS_HIT_STOP_SCALE
	# Real seconds, and only while the game runs (a pause keeps time at 0 until it ends).
	get_tree().create_timer(BOSS_HIT_STOP_TIME, false, false, true).timeout.connect(func() -> void: Engine.time_scale = 1.0)
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	var shake: Tween = camera.create_tween()
	shake.set_ignore_time_scale(true)
	for i: int in 6:
		var strength: float = BOSS_SHAKE * (1.0 - i / 6.0)
		shake.tween_property(camera, "offset", Vector2(strength if i % 2 == 0 else -strength, strength * 0.5).round(), BOSS_SHAKE_TIME / 7.0)
	shake.tween_property(camera, "offset", Vector2.ZERO, BOSS_SHAKE_TIME / 7.0)
