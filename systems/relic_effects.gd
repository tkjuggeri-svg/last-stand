class_name RelicEffects
extends Node
## Carries out the run's relic rules on this level (M7.5; RelicData.rule, RunModifiers.RELIC_*). A
## plain node under the level's Systems, wired with exported references like the other per-level
## systems. Some rules live where they act instead: TowerBuilder (Siege Ledger: no evolutions; Twin
## Banners: shared levels), Fortress (Iron Tithe: no repairs) and the stats every relic brings.
## Here: Hourglass, Bloodpact, Ossuary Bell, Lantern of the Lost, Phoenix Feather, Executioner's Mark,
## Glass Banner, Soul Lantern, Drowned Bell and Second Oath. Relics taken mid-level apply at once.

## A relic did something worth telling the player (the HUD's feed shows it).
signal triggered(text: String)

const BONE_SCENE: PackedScene = preload("res://entities/pickups/bone_pickup.tscn")
const BELL_RING_COLOR: Color = Color(0.85, 0.65, 0.35, 0.8)

@export var modifiers: RunModifiers
@export var spawner: WaveSpawner
@export var run_cycle: RunCycle
@export var hero: Hero
@export var hero_lives: HeroLives
@export var fortress: Fortress
@export var economy: Economy
## Where pickups (the Ossuary Bell's bones) and the bell's ring are placed.
@export var effects: Node2D
@export_group("Tuning")
@export var hourglass_seconds: float = 5.0
@export var hourglass_slow: float = 0.5
@export_range(0.0, 1.0) var bloodpact_share: float = 0.3
@export var bone_every: int = 10
@export var bone_gold: int = 30
## Lantern of the Lost: the enemies it marks, and how much more damage they take.
@export var lantern_targets: Array[EnemyData] = []
@export var lantern_bonus: float = 0.5
@export_range(0.0, 1.0) var phoenix_health: float = 0.3
@export_range(0.0, 1.0) var executioner_threshold: float = 0.12
@export var glass_banner_damage_taken: float = 1.5
@export var soul_lantern_radius: float = 260.0
@export var bell_interval: float = 20.0
@export var bell_warning: float = 1.0
@export var bell_freeze: float = 1.2
@export var bell_boss_freeze: float = 0.4
@export var bell_radius: float = 900.0
@export var oath_respawn_delay: float = 1.0
@export var oath_fortress_cost: int = 10
@export var crown_thorns_damage: int = 8
@export_range(0.0, 1.0) var banner_damage_cut: float = 0.15

## Seconds since the current wave started (Hourglass), and of combat toward the next toll.
var _wave_time: float = 0.0
var _bell_time: float = 0.0
var _bell_ring: TelegraphMarker = null
var _kills: int = 0
var _normal_respawn_delay: float = 0.0
## The Phoenix Feather's reprieve was given on this level (once per chapter).
var _phoenix_granted: bool = false


func _ready() -> void:
	assert(modifiers != null, "RelicEffects needs RunModifiers: %s" % get_path())
	if hero_lives != null:
		_normal_respawn_delay = hero_lives.respawn_delay
		hero_lives.respawn_started.connect(_on_respawn_started)
	if spawner != null:
		spawner.wave_started.connect(func(_n: int) -> void:
			_wave_time = 0.0
			_bell_time = 0.0)
		spawner.enemy_spawned.connect(_on_enemy_spawned)
		spawner.enemy_killed.connect(_on_enemy_killed)
	if hero != null:
		hero.struck.connect(_on_hero_struck)
		hero.hit_by.connect(_on_hero_hit_by)
	if fortress != null:
		if not fortress.is_node_ready():
			await fortress.ready
		fortress.health.reprieved.connect(func() -> void: triggered.emit("Phoenix Feather: the fortress rises from the ashes!"))
	modifiers.upgrade_added.connect(func(data: UpgradeData, _stacks: int) -> void:
		if data is RelicData:
			_apply_standing_rules())
	_apply_standing_rules()


func _physics_process(delta: float) -> void:
	_wave_time += delta
	if fortress != null and modifiers.has_relic(RunModifiers.RELIC_BANNER_OF_THE_LAST_KEEP):
		_apply_fortress_multiplier()
	if not modifiers.has_relic(RunModifiers.RELIC_DROWNED_BELL) or run_cycle == null or run_cycle.get_phase() != RunCycle.Phase.COMBAT:
		return
	_bell_time += delta
	if _bell_ring == null and _bell_time >= bell_interval - bell_warning:
		_bell_ring = TelegraphMarker.new()
		_bell_ring.color = BELL_RING_COLOR
		_bell_ring.size = bell_radius
		if effects != null:
			effects.add_child(_bell_ring)
		else:
			add_child(_bell_ring)
		_bell_ring.global_position = fortress.global_position
	if _bell_ring != null:
		_bell_ring.progress = 1.0 - (bell_interval - _bell_time) / bell_warning
	if _bell_time >= bell_interval:
		_toll()


## The rules that stand while a relic is held (set again whenever a relic is taken).
func _apply_standing_rules() -> void:
	if fortress != null:
		_apply_fortress_multiplier()
		if modifiers.has_relic(RunModifiers.RELIC_PHOENIX) and not _phoenix_granted:
			_phoenix_granted = true  # once per chapter: this level's one reprieve
			fortress.health.reprieves = 1
		fortress.health.reprieve_health = maxi(roundi(fortress.health.max_health * phoenix_health), 1)
	if hero_lives != null:
		hero_lives.respawn_delay = oath_respawn_delay if modifiers.has_relic(RunModifiers.RELIC_SECOND_OATH) else _normal_respawn_delay


## What the fortress takes of a hit: the Glass Banner makes it more, the Banner of the Last Keep less while the hero stands.
func _apply_fortress_multiplier() -> void:
	var share: float = glass_banner_damage_taken if modifiers.has_relic(RunModifiers.RELIC_GLASS_BANNER) else 1.0
	if modifiers.has_relic(RunModifiers.RELIC_BANNER_OF_THE_LAST_KEEP) and hero != null and not hero.health.is_dead():
		share *= 1.0 - banner_damage_cut
	fortress.health.damage_taken_multiplier = share


## Crown of Thorns: an enemy that hit the hero takes damage back.
func _on_hero_hit_by(attacker: Enemy) -> void:
	if modifiers.has_relic(RunModifiers.RELIC_CROWN_OF_THORNS) and is_instance_valid(attacker) and attacker.is_alive():
		attacker.get_health().take_damage(crown_thorns_damage)


func _on_enemy_spawned(enemy: Enemy) -> void:
	if modifiers.has_relic(RunModifiers.RELIC_HOURGLASS) and _wave_time < hourglass_seconds:
		enemy.apply_slow(hourglass_slow, hourglass_seconds - _wave_time)
	if modifiers.has_relic(RunModifiers.RELIC_LANTERN) and lantern_targets.has(enemy.data):
		enemy.get_status().mark_vulnerable(lantern_bonus, INF)
	if modifiers.has_relic(RunModifiers.RELIC_EXECUTIONER) and not enemy.data.is_boss:
		var health: HealthComponent = enemy.get_health()
		health.health_changed.connect(func(current: int, max_health: int) -> void:
			if current > 0 and current <= max_health * executioner_threshold:
				health.take_damage.call_deferred(current))


func _on_enemy_killed(enemy: Enemy) -> void:
	_kills += 1
	if modifiers.has_relic(RunModifiers.RELIC_OSSUARY_BELL) and _kills % bone_every == 0 and effects != null:
		var bone: BonePickup = BONE_SCENE.instantiate()
		bone.collected.connect(func(_b: BonePickup) -> void:
			economy.earn(bone_gold, Economy.Source.REWARD)
			triggered.emit("Ossuary Bell: +%d gold" % bone_gold))
		# A kill is handled inside a physics callback, where an Area can't be added to the tree: defer it.
		bone.position = effects.to_local(enemy.global_position)
		effects.add_child.call_deferred(bone)
	if modifiers.has_relic(RunModifiers.RELIC_SOUL_LANTERN) and fortress != null \
			and enemy.global_position.distance_to(fortress.global_position) <= soul_lantern_radius:
		fortress.repair_hp(1)


func _on_hero_struck(damage: int) -> void:
	if modifiers.has_relic(RunModifiers.RELIC_BLOODPACT):
		hero.health.heal(maxi(ceili(damage * bloodpact_share), 1))


func _on_respawn_started(_delay: float) -> void:
	if modifiers.has_relic(RunModifiers.RELIC_SECOND_OATH) and fortress != null:
		fortress.health.take_damage(oath_fortress_cost)
		triggered.emit("Second Oath: the fortress pays %d HP" % oath_fortress_cost)


## The Drowned Bell tolls: every enemy freezes (a boss briefly).
func _toll() -> void:
	_bell_time = 0.0
	if _bell_ring != null:
		_bell_ring.queue_free()
		_bell_ring = null
	for child: Node in spawner.get_children():
		var enemy: Enemy = child as Enemy
		if enemy != null and enemy.is_alive():
			enemy.get_status().freeze(bell_boss_freeze if enemy.data.is_boss else bell_freeze)
	triggered.emit("Drowned Bell: the dead stand still")
