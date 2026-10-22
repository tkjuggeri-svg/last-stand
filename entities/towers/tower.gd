class_name Tower
extends StaticBody2D
## A built tower. One scene for every tower type: its TowerData decides the look and the stats.
## It targets the living enemy in range that is furthest along the lane (closest to the fortress),
## keeps that target while it stays valid and in range, and fires a volley every fire_interval (one
## shot, or one per target for multi-target levels: the next leading enemies in range).
## "In range" means the enemy's centre is within the range of the tower's base (the range area is
## only the broad phase: it reports bodies that merely touch the circle).
## The base stands at the node's origin (the build slot's centre); a small body blocks the hero.
## After placing it is under construction for data.build_time seconds (shown by its "<id>_build"
## animation, stretched to that time): it tracks enemies entering its range but can't target or fire.
## Levels: it starts at 1; TowerBuilder upgrades it (set_level) and the stats come from
## data.stats_for(level). At the highest level TowerBuilder can evolve it once (evolve(): level 4, one
## of data.evolutions, for good), which may change its targeting (strongest, densest, a dead zone) and
## its attack (arrow rain, a cone blast, freezing, dragging, soul fire: see TowerEvolution).
## A Beacon Flame nearby speeds up its fire rate (set_fire_rate_boost, from TowerBuilder), and a
## partner tower nearby gives it its pair bonus (set_synergies, TowerSynergy); a
## Tollkeeper's toll silences it for a while (get_silence(): no firing).
## deactivate() (called when it is sold) stops it for good. Its parts: TowerSight (what it can see and
## aims at), TowerWeapon (how a volley is delivered), TowerSilence (the toll's silence).

signal construction_finished

## Loaded when needed: the aura's script refers back to Tower, so a preload would be a cycle.
const SHATTER_AURA_PATH: String = "res://entities/towers/shatter_aura.tscn"
## Upgrade feedback (display only): a bright flash that fades over this many seconds.
const UPGRADE_FLASH_TIME: float = 0.35

@export var data: TowerData
## The run's upgrades (set by TowerBuilder): damage, range etc. read through it. Null = base stats.
var modifiers: RunModifiers

## Gold put into this tower so far (build + upgrades); selling refunds a share of it.
var invested: int = 0

var _level: int = 1
## The level-4 branch, once chosen (null before).
var _evolution: TowerEvolution = null
## Fire-rate bonus from a Beacon Flame in reach (0 = none; 0.25 = 25% more shots).
var _boost: float = 0.0
## Its pair bonuses active now (a partner tower nearby; TowerBuilder keeps them up to date).
var _synergies: Array[TowerSynergy] = []
## Twin Banners: a same-type tower's level shared with this one (0 = none); the better one counts.
var _shared_level: int = 0
var _weapon: TowerWeapon = TowerWeapon.new()
var _sight: TowerSight = TowerSight.new()
var _stats: TowerTier
var _build_left: float = 0.0
var _active: bool = true
var _target: Enemy = null
var _cooldown_left: float = 0.0

@onready var _sprite: AnimatedSprite2D = %Sprite
@onready var _range_area: Area2D = %RangeArea
@onready var _glow: PointLight2D = %Glow
@onready var _range_shape: CollisionShape2D = %RangeShape
@onready var _boost_mark: AnimatedSprite2D = %BoostMark
@onready var _silence: TowerSilence = %Silence


func _ready() -> void:
	if data == null:
		# Opened on its own (no TowerBuilder gave it data): just stand there.
		_sprite.play(&"archer_idle")
		_active = false
		set_physics_process(false)
		return
	_stats = _effective_stats()
	_apply_range()
	if modifiers != null:
		modifiers.changed.connect(_on_modifiers_changed)
	_glow.enabled = data.glow_color.a > 0.0
	_glow.color = data.glow_color
	_glow.position = data.muzzle_offset
	_range_area.body_entered.connect(_on_range_body_entered)
	_range_area.body_exited.connect(_on_range_body_exited)
	_sprite.animation_finished.connect(_on_sprite_animation_finished)
	_build_left = RunModifiers.value(modifiers, data.build_time, RunModifiers.tower_stats(RunModifiers.TOWER_BUILD_TIME, data.id))
	var build: StringName = StringName("%s_build" % data.id)
	if _build_left > 0.0 and _sprite.sprite_frames.has_animation(build):
		var length: float = _sprite.sprite_frames.get_frame_count(build) / _sprite.sprite_frames.get_animation_speed(build)
		_sprite.play(build, length / _build_left)
	else:
		_sprite.play(_anim("idle"))


func _physics_process(delta: float) -> void:
	if _build_left > 0.0:
		_build_left -= delta
		if _build_left > 0.0:
			return
		_build_left = 0.0
		construction_finished.emit()
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if not _sight.is_valid_target(self, _target):
		_target = _sight.pick_target(self)  # also forgets a target that died, left range or reached the fortress
	if _target != null and _cooldown_left <= 0.0 and not _silence.is_silenced():
		_fire()


## Skips the construction (a tower put back by a resumed run, M8).
func finish_building() -> void:
	if _build_left <= 0.0:
		return
	_build_left = 0.0
	_sprite.play(_anim("idle"))
	construction_finished.emit()


## The enemy currently aimed at, or null.
func get_target() -> Enemy:
	if not _sight.is_valid_target(self, _target):
		return null
	return _target


## True while under construction (can't target or fire yet).
func is_building() -> bool:
	return _build_left > 0.0


## False once the tower has been sold (or opened without data).
func is_active() -> bool:
	return _active


## Stops the tower for good: no more targeting or shots. Called when it is sold, before it is removed.
func deactivate() -> void:
	_active = false
	_target = null
	_sight.clear()
	set_physics_process(false)
	_range_area.set_deferred(&"monitoring", false)


func get_level() -> int:
	return _level


## True at the highest regular level (3) or above: no more upgrades (an evolution may still come).
func is_max_level() -> bool:
	return data == null or _level >= data.max_level()


func is_evolved() -> bool:
	return _evolution != null


func get_evolution() -> TowerEvolution:
	return _evolution


## Takes the level-4 branch (TowerBuilder does the paying and the checks): for good.
func evolve(evolution: TowerEvolution) -> void:
	assert(_evolution == null, "A tower evolves only once")
	_evolution = evolution
	set_level(data.max_level() + 1)
	if evolution.shatter_bonus > 0.0:
		var aura: ShatterAura = (load(SHATTER_AURA_PATH) as PackedScene).instantiate()
		aura.setup(self)
		add_child(aura)


## Its silence (a Tollkeeper's toll stops it firing).
func get_silence() -> TowerSilence:
	return _silence


## Fire-rate bonus from a Beacon Flame (TowerBuilder keeps it up to date; never stacking).
func set_fire_rate_boost(bonus: float) -> void:
	if is_equal_approx(bonus, _boost):
		return
	_boost = bonus
	_stats = _effective_stats()
	_update_boost_mark()


func get_fire_rate_boost() -> float:
	return _boost


## The pair bonuses active now (from TowerBuilder).
func set_synergies(synergies: Array[TowerSynergy]) -> void:
	if synergies == _synergies:
		return
	_synergies = synergies
	_stats = _effective_stats()
	_update_boost_mark()


func get_synergies() -> Array[TowerSynergy]:
	return _synergies


## Twin Banners (from TowerBuilder): fights with the stats of `level` if that is above its own.
func set_shared_level(level: int) -> void:
	if level == _shared_level:
		return
	_shared_level = level
	_stats = _effective_stats()
	_apply_range()
	_update_boost_mark()


## The level whose stats it fights with (its own, or a twin's higher one).
func get_stats_level() -> int:
	return _level if _evolution != null else maxi(_level, mini(_shared_level, data.max_level()))


## The stats at the current level, with the run's upgrades applied.
func get_stats() -> TowerTier:
	return _stats if _stats != null else _effective_stats()


## What it would fight with at regular `level` (the upgrade preview: same cards and pair bonuses).
func preview_level(level: int) -> TowerTier:
	return _stats_from(data.stats_for(level))


## Switches to `level` (TowerBuilder does the paying): new stats, range and look, with a flash.
func set_level(level: int) -> void:
	_level = clampi(level, 1, data.max_level() + (1 if _evolution != null else 0))
	_stats = _effective_stats()
	_apply_range()
	_update_boost_mark()
	if not is_building():
		_sprite.play(_anim("idle"))
	_sprite.modulate = Color(2.2, 2.2, 2.2, 1.0)  # overbright, then back to normal
	_sprite.create_tween().tween_property(_sprite, "modulate", Color.WHITE, UPGRADE_FLASH_TIME)


## The current attack range in px (what the range ring shows).
func get_attack_range() -> float:
	return get_stats().attack_range if data != null else 0.0


## The dead zone around the base (Siege Mortar), in px: closer enemies can't be targeted.
func get_min_range() -> float:
	return _evolution.min_range if _evolution != null else 0.0


## True if `point` is within attack range of the tower's base (and outside its dead zone).
func is_in_range(point: Vector2) -> bool:
	var distance: float = global_position.distance_to(point)
	return distance <= get_attack_range() and distance >= get_min_range()


## Where a shell fired now must land to meet `enemy` (TowerWeapon.lead_point: simple lead, never
## beyond the range).
func aim_point(enemy: Enemy) -> Vector2:
	return TowerWeapon.lead_point(self, enemy)


## "<id>_<state>" for level 1, "<id>_<state>_<level>" above, "<evolution id>_<state>" once evolved
## (each falls back to the level below's art if missing).
func _anim(state: String) -> StringName:
	if _evolution != null and _sprite.sprite_frames.has_animation(StringName("%s_%s" % [_evolution.id, state])):
		return StringName("%s_%s" % [_evolution.id, state])
	var name_at_level: StringName = StringName("%s_%s_%d" % [data.id, state, _level])
	if _level > 1 and _sprite.sprite_frames.has_animation(name_at_level):
		return name_at_level
	return StringName("%s_%s" % [data.id, state])


## The level's stats with the run's modifiers applied (a copy: the data stays untouched).
func _effective_stats() -> TowerTier:
	return _stats_from(_evolution if _evolution != null else data.stats_for(get_stats_level()))


## `base` with everything that lifts this tower now: a Beacon's speed, the run's cards, pair bonuses.
func _stats_from(base: TowerTier) -> TowerTier:
	var stats: TowerTier = base.duplicate() as TowerTier
	stats.fire_interval = base.fire_interval / (1.0 + _boost)
	if modifiers != null:
		_apply_modifiers(stats, base)
	for synergy: TowerSynergy in _synergies:
		synergy.apply_to(stats)
	return stats


func _apply_modifiers(stats: TowerTier, base: TowerTier) -> void:
	stats.damage = modifiers.apply_int(base.damage, RunModifiers.tower_stats(RunModifiers.TOWER_DAMAGE, data.id))
	stats.fire_interval = maxf(modifiers.apply(stats.fire_interval, RunModifiers.tower_stats(RunModifiers.TOWER_FIRE_INTERVAL, data.id)), 0.1)
	stats.attack_range = modifiers.apply(base.attack_range, RunModifiers.tower_stats(RunModifiers.TOWER_RANGE, data.id))
	stats.slow_duration = modifiers.apply(base.slow_duration, RunModifiers.tower_stats(RunModifiers.TOWER_SLOW_DURATION, data.id))
	stats.pierce = modifiers.apply_int(base.pierce, RunModifiers.tower_stats(RunModifiers.TOWER_PIERCE, data.id))
	stats.burn_dps = modifiers.apply(base.burn_dps, RunModifiers.tower_stats(RunModifiers.TOWER_BURN, data.id))
	stats.burn_duration = modifiers.apply(base.burn_duration, RunModifiers.tower_stats(RunModifiers.TOWER_BURN_DURATION, data.id))


## The ember over a tower something lifts: a Beacon Flame's speed, a twin's level (Twin Banners), a
## pair bonus.
func _update_boost_mark() -> void:
	_boost_mark.visible = _boost > 0.0 or get_stats_level() > _level or not _synergies.is_empty()


func _on_modifiers_changed() -> void:
	_stats = _effective_stats()
	_apply_range()


func _apply_range() -> void:
	(_range_shape.shape as CircleShape2D).radius = get_attack_range()


## One volley at the target (plus the next leading enemies for multi-target levels): TowerWeapon
## delivers it.
func _fire() -> void:
	var stats: TowerTier = get_stats()
	_cooldown_left = stats.fire_interval
	var targets: Array[Enemy] = [_target]
	if stats.targets > 1:
		for enemy: Enemy in _sight.targets_in_range(self):
			if targets.size() >= stats.targets:
				break
			if enemy != _target:
				targets.append(enemy)
	_weapon.fire(self, targets, stats)
	_sprite.play(_anim("fire"))


func _on_range_body_entered(body: Node2D) -> void:
	if _active:
		_sight.add(body)


func _on_range_body_exited(body: Node2D) -> void:
	_sight.remove(body)


func _on_sprite_animation_finished() -> void:
	_sprite.play(_anim("idle"))
