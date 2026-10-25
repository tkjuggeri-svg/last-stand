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
const GOLD_TEXT_COLOR: Color = UiColors.GOLD
## Where an enemy's damage number starts, from its feet.
const DAMAGE_NUMBER_OFFSET: Vector2 = Vector2(0, -44)
## A boss's death: the game runs at this speed for this many real seconds, and the camera shakes.
## The most fortress HP Soul Harvesters mend in a wave.
const SOUL_HEAL_CAP: int = 10
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
## The between-waves gold sinks (a saved run keeps what was bought, M8).
@export var quartermaster: Quartermaster
## The level's minions (M9), made in _ready: a system every arena needs, so no scene lists it.
var minions: MinionPool

var _run_over: bool = false
var _encounter_mode: bool = false
## True while a previous chapter's upgrades are put back (their instant effects already happened).
## Fortress HP mended by Soul Harvesters this wave (SOUL_HEAL_CAP at most).
var _soul_healed: int = 0
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
	_make_minion_pool()
	if run_cycle != null:
		run_cycle.all_waves_cleared.connect(_on_all_waves_cleared)
	if modifiers != null:
		modifiers.upgrade_added.connect(_on_upgrade_added)
	if spawner != null:
		spawner.enemy_killed.connect(_on_enemy_killed)
		spawner.wave_started.connect(func(_n: int) -> void: _soul_healed = 0)
		spawner.enemy_spawned.connect(func(enemy: Enemy) -> void: enemy.damage_reported.connect(_show_damage))


func _make_minion_pool() -> void:
	minions = MinionPool.new()
	minions.name = "MinionPool"
	minions.parent_node = _effects
	minions.modifiers = modifiers
	add_child(minions)
	if builder != null:
		builder.minion_pool = minions
		builder.tower_slew.connect(_on_tower_slew)
	minions.minion_fell.connect(_on_minion_fell)
	minions.minion_struck.connect(_on_minion_struck)


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
	health.set_current_health(carry.fortress_health + (roundi(health.max_health * repair) if fortress.can_repair() else 0))


## Sets up the run's hero (M9): the card and relic offers hold the shared ones and this hero's own (the other heroes' leave them), the build menu holds the shared towers and this hero's own (the towers
## exclusive to another hero in `roster` leave it), and the hero's damage rises under Watchtowers.
func apply_hero(hero_data: HeroData, roster: Array[HeroData]) -> void:
	if hero_data == null:
		return
	var others: Array[TowerData] = []
	var other_cards: Array[UpgradeData] = []
	var other_relics: Array[RelicData] = []
	for other: HeroData in roster:
		if other != hero_data:
			others.append_array(other.exclusive_towers)
			other_cards.append_array(other.exclusive_cards)
			other_relics.append_array(other.exclusive_relics)
	var catalog: Array[TowerData] = builder.catalog.filter(func(t: TowerData) -> bool: return not others.has(t))
	for tower: TowerData in hero_data.exclusive_towers:
		if not catalog.has(tower):
			catalog.append(tower)
	builder.catalog = catalog
	if offers != null:
		offers.pool = offers.pool.filter(func(c: UpgradeData) -> bool: return not other_cards.has(c))
		for card: UpgradeData in hero_data.exclusive_cards:
			if not offers.pool.has(card):
				offers.pool.append(card)
		offers.relic_pool = offers.relic_pool.filter(func(r: RelicData) -> bool: return not other_relics.has(r))
		for relic: RelicData in hero_data.exclusive_relics:
			if not offers.relic_pool.has(relic):
				offers.relic_pool.append(relic)
	var hero: Hero = get_node_or_null("Hero") as Hero
	if hero != null:
		hero.damage_bonus_at = builder.hero_bonus_at
		builder.rally_hero = hero
		if hero_data.raise_minion != null:
			hero.slew.connect(func(at: Vector2) -> void: _raise_for_hero(hero, hero_data, at))


## Soul Feast: a skeleton of the hero's fell, and she regains HP.
func _on_minion_fell(minion: Minion) -> void:
	var hero: Hero = minion.anchor as Hero if is_instance_valid(minion.anchor) else null
	var heal: int = RunModifiers.value_int(modifiers, 0, [RunModifiers.HERO_SOUL_FEAST])
	if hero != null and heal > 0 and not hero.health.is_dead():
		hero.health.heal(heal)


## The Reliquary of Bones: a kill by a skeleton gives an Ossuary's soul a second time.
func _on_minion_struck(_minion: Minion, enemy: Enemy, killed: bool) -> void:
	if killed and builder != null and RunModifiers.relic(modifiers, RunModifiers.RELIC_RELIQUARY):
		builder.enemy_died(enemy.global_position)


## A Soul Harvester's beam killed: the fortress mends a little (a few a wave).
func _on_tower_slew(tower: Tower, _enemy: Enemy) -> void:
	var heal: int = tower.get_stats().soul_heal
	if heal <= 0 or fortress == null or _soul_healed >= SOUL_HEAL_CAP:
		return
	var healed: int = mini(heal, SOUL_HEAL_CAP - _soul_healed)
	_soul_healed += healed
	fortress.health.heal(healed)


## A kill by the hero's bolt raises a skeleton where the enemy fell (up to the hero's cap).
func _raise_for_hero(hero: Hero, hero_data: HeroData, at: Vector2) -> void:
	var cap: int = hero_data.raise_cap + RunModifiers.value_int(modifiers, 0, [RunModifiers.MINION_CAP])
	minions.raise(hero_data.raise_minion, at, hero, cap, hero)


## Holds back what the run hasn't unlocked (M8): towers in the build menu, card and relic pools, which
## towers may evolve, and the Drill's free reroll. Call once it is ready, before the first fight.
func apply_unlocks(unlocks: RunUnlocks) -> void:
	if unlocks == null:
		return
	builder.catalog = unlocks.filter_towers(builder.catalog)
	builder.unlocks = unlocks
	if offers != null:
		offers.pool = unlocks.filter_cards(offers.pool)
		offers.relic_pool = unlocks.filter_relics(offers.relic_pool)
		offers.free_rerolls = 1 if unlocks.has_perk(&"drill") else 0


## Turns on the run's Pressure modifiers (M12) for this chapter's level: the stat ones through the run's
## modifiers (hidden: no HUD icon), the rules on the systems they belong to. `chapter_seed` picks which
## slots the rubble blocks, so a chapter blocks the same ones every time.
func apply_pressure(list: Array[PressureData], chapter_seed: int) -> void:
	for data: PressureData in list:
		for modifier: StatModifier in data.modifiers:
			modifiers.add_modifier(modifier)
		if data.rule != &"" and not modifiers.rules.has(data.rule):
			modifiers.rules.append(data.rule)
	if modifiers.rules.has(PressureRules.RULE_SWIFT_DEAD):
		spawner.enemy_speed_scale = PressureRules.ENEMY_SPEED
	if modifiers.rules.has(PressureRules.RULE_HASTY_WAVES):
		run_cycle.hasty_seconds = PressureRules.HASTY_SECONDS
		run_cycle.restart()
	if modifiers.rules.has(PressureRules.RULE_FEWER_CARDS) and offers != null:
		offers.offer_size = PressureRules.FEWER_CARDS_SIZE
	if modifiers.rules.has(PressureRules.RULE_FEWER_SLOTS):
		_lock_slots(chapter_seed)


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


## The fight's gold and repair at once, then its upgrade or relic choice (if any); encounter_cleared
## once taken (straight away if there is nothing left to offer).
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
	var offered: bool = false
	if offers != null and _reward.relics > 0:
		offered = not offers.make_relic_offer(_reward.relics).is_empty()
	if offers != null and not offered and _reward.cards > 0:
		offered = not offers.make_offer(_reward.cards, _reward.rare_only).is_empty()
	if offered:
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
	if builder != null:
		builder.enemy_died(enemy.global_position)  # Ossuaries gather its soul
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
	Juice.hit_stop(self, BOSS_HIT_STOP_TIME, BOSS_HIT_STOP_SCALE, true)
	Juice.shake(self, BOSS_SHAKE, BOSS_SHAKE_TIME)


## A damaged enemy's number (Settings: Damage numbers), on the effects layer so it outlives the enemy.
func _show_damage(amount: int, at: Vector2) -> void:
	if not GameSettings.shows_damage_numbers():
		return
	var number: DamageNumber = FLOATING_TEXT_SCENE.instantiate()
	number.set_text(str(amount), UiColors.TEXT)
	number.position = at + DAMAGE_NUMBER_OFFSET
	_effects.add_child(number)


## Blocks PressureRules.SLOTS_LOCKED empty slots with rubble, picked from `chapter_seed`.
func _lock_slots(chapter_seed: int) -> void:
	var free: Array[BuildSlot] = builder.get_slots().filter(func(s: BuildSlot) -> bool: return s.is_empty() and not s.locked)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = chapter_seed * 13 + 5
	for i: int in mini(PressureRules.SLOTS_LOCKED, free.size()):
		var pick: int = rng.randi_range(0, free.size() - 1)
		free[pick].lock()
		free.remove_at(pick)
