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
## Its beam killed an enemy (Soul Harvester heals the fortress for it).
signal slew(tower: Tower, enemy: Enemy)

## Loaded when needed: the aura's script refers back to Tower, so a preload would be a cycle.
const SHATTER_AURA_PATH: String = "res://entities/towers/shatter_aura.tscn"
## The Ossuary's glow while it fills: energy at no souls and at a full ossuary.
const OSSUARY_GLOW: Vector2 = Vector2(0.15, 0.9)
## A Bone Pit raises its skeleton this far (px) from the enemy toward the tower; a Bone Storm's skeletons
## stand on a ring this big.
const RAISE_LEAD: float = 36.0
const RELEASE_RING: float = 40.0
const EXPLOSION_SCENE: PackedScene = preload("res://entities/towers/explosion.tscn")
## Upgrade feedback (display only): a bright flash that fades over this many seconds.
const UPGRADE_FLASH_TIME: float = 0.35

@export var data: TowerData
## The run's upgrades (set by TowerBuilder): damage, range etc. read through it. Null = base stats.
var modifiers: RunModifiers
## Where a Bone Pit's skeletons and a Bone Storm's are raised (set by TowerBuilder).
var minion_pool: MinionPool

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
var _traps: TowerTraps = TowerTraps.new()
var _beam: TowerBeam
## The Ossuary: souls gathered since its last blast.
var _souls: int = 0
## Watchtower: more range for the towers around it (TowerBuilder keeps it up to date); 0 = none.
var _aura_range: float = 0.0
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
	if data.frames != null:
		_sprite.sprite_frames = data.frames
	_stats = _effective_stats()
	_apply_range()
	if modifiers != null:
		modifiers.changed.connect(_on_modifiers_changed)
	_glow.enabled = data.glow_color.a > 0.0
	_glow.color = data.glow_color
	_glow.position = data.muzzle_offset
	if data.kind == TowerData.Kind.BEAM:
		_beam = TowerBeam.new()
		add_child(_beam)
		_beam.setup(self)
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
	if not _acts():
		return
	if not _sight.is_valid_target(self, _target):
		_target = _sight.pick_target(self)  # also forgets a target that died, left range or reached the fortress
	if _target != null and _cooldown_left <= 0.0 and not _silence.is_silenced() and data.kind != TowerData.Kind.BEAM:
		_fire()


## True while its beam may burn: finished, working and not silenced (the TowerBeam asks).
func is_beaming() -> bool:
	return _active and _build_left <= 0.0 and not _silence.is_silenced()


## The beam killed `enemy` (TowerBeam tells it).
func report_kill(enemy: Enemy) -> void:
	slew.emit(self, enemy)


## An Ossuary takes `amount` souls (the dead nearby); at its limit it releases them in a blast.
func add_souls(amount: int) -> void:
	if data.kind != TowerData.Kind.OSSUARY or not _active or _build_left > 0.0:
		return
	_souls += amount
	var needed: int = get_stats().souls_needed
	if needed > 0 and _souls >= needed:
		_souls = 0
		_release_souls.call_deferred()  # a death may have been dealt inside a physics callback
	_update_ossuary_glow()


func get_souls() -> int:
	return _souls


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


## Watchtower's aura on this tower: `bonus` more range (TowerBuilder gives the best one in reach).
func set_aura_range(bonus: float) -> void:
	if is_equal_approx(bonus, _aura_range):
		return
	_aura_range = bonus
	_stats = _effective_stats()
	_apply_range()


func get_aura_range() -> float:
	return _aura_range


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
	stats.attack_range = base.attack_range * (1.0 + _aura_range)
	if modifiers != null:
		_apply_modifiers(stats, base)
	for synergy: TowerSynergy in _synergies:
		synergy.apply_to(stats)
	return stats


func _apply_modifiers(stats: TowerTier, base: TowerTier) -> void:
	stats.damage = modifiers.apply_int(base.damage, RunModifiers.tower_stats(RunModifiers.TOWER_DAMAGE, data.id))
	stats.fire_interval = maxf(modifiers.apply(stats.fire_interval, RunModifiers.tower_stats(RunModifiers.TOWER_FIRE_INTERVAL, data.id)), 0.1)
	stats.attack_range = modifiers.apply(base.attack_range * (1.0 + _aura_range), RunModifiers.tower_stats(RunModifiers.TOWER_RANGE, data.id))
	stats.slow_duration = modifiers.apply(base.slow_duration, RunModifiers.tower_stats(RunModifiers.TOWER_SLOW_DURATION, data.id))
	stats.pierce = modifiers.apply_int(base.pierce, RunModifiers.tower_stats(RunModifiers.TOWER_PIERCE, data.id))
	stats.snare_hold = modifiers.apply(base.snare_hold, RunModifiers.tower_stats(RunModifiers.TOWER_SNARE_HOLD, data.id))
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
	if data.kind == TowerData.Kind.PIT:
		_raise_skeleton(stats)
		return
	if data.kind == TowerData.Kind.TRAP:
		if not _traps.can_throw(stats):
			return  # all its snares are lying: wait for one to spring
		_cooldown_left = stats.fire_interval
		_traps.throw(self, _target, stats)
		_sprite.play(_anim("fire"))
		if data.fire_sound != &"":
			Sfx.play(self, data.fire_sound)
		return
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
	if data.fire_sound != &"":
		Sfx.play(self, data.fire_sound)


## A Bone Pit raises a skeleton between itself and its target (unless all its own are standing).
func _raise_skeleton(stats: TowerTier) -> void:
	if minion_pool == null or minion_pool.count_for(self) >= stats.minion_cap:
		return  # wait for one to fall
	_cooldown_left = stats.fire_interval
	var spot: Vector2 = _target.global_position + (global_position - _target.global_position).limit_length(RAISE_LEAD)
	minion_pool.raise(stats.minion, spot, self, stats.minion_cap, self)
	_sprite.play(_anim("fire"))


## False for a tower that never aims: an Ossuary, or a Watchtower that has no attack of its own.
func _acts() -> bool:
	if data.kind == TowerData.Kind.OSSUARY:
		return false
	return data.kind != TowerData.Kind.AURA or get_stats().damage > 0


## The Ossuary's blast: damage to every enemy in its reach (a slow for Death Knell, skeletons for Bone
## Storm). The blast is the stats' splash_radius.
func _release_souls() -> void:
	var stats: TowerTier = get_stats()
	var blast: Explosion = EXPLOSION_SCENE.instantiate()
	blast.setup(stats.damage, stats.splash_radius, true)
	blast.top_level = true
	blast.position = global_position
	add_child(blast)
	_sprite.play(_anim("fire"))
	if stats.slow_factor < 1.0:
		for enemy: Enemy in EnemyQuery.in_circle(get_world_2d(), global_position, stats.splash_radius):
			enemy.apply_slow(stats.slow_factor, stats.slow_duration)
	if stats.release_minions > 0 and minion_pool != null and stats.minion != null:
		for i: int in stats.release_minions:
			var at: Vector2 = global_position + Vector2.from_angle(TAU * i / stats.release_minions) * RELEASE_RING
			minion_pool.raise(stats.minion, at, self, stats.release_minions + stats.minion_cap, self)


func _update_ossuary_glow() -> void:
	if data.kind != TowerData.Kind.OSSUARY:
		return
	var fraction: float = float(_souls) / maxf(get_stats().souls_needed, 1.0)
	_glow.enabled = true
	_glow.energy = lerpf(OSSUARY_GLOW.x, OSSUARY_GLOW.y, fraction)


func _on_range_body_entered(body: Node2D) -> void:
	if _active:
		_sight.add(body)


func _on_range_body_exited(body: Node2D) -> void:
	_sight.remove(body)


func _on_sprite_animation_finished() -> void:
	_sprite.play(_anim("idle"))
