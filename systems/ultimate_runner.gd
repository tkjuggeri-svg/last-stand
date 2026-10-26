class_name UltimateRunner
extends Node
## Runs the hero's ultimate on a level (M14): feeds its bar from what the hero and the hero's skeletons do and from
## waves running, and plays the effect when the bar is spent. The bar's rules are HeroUltimate's; the numbers are the
## hero's UltimateData. Created by the Level.

const SKELETON_SPEEDUP: float = 1.3
## Rise of the Dead: the skeletons appear on a ring this far (px) from the hero.
const RISE_RING: float = 64.0
## Volley of Ruin: impacts alternate this far (px) to either side of the line, each hits this radius.
const VOLLEY_SPREAD: float = 18.0
const VOLLEY_RADIUS: float = 44.0
const VOLLEY_FRAMES: SpriteFrames = preload("res://entities/effects/explosion_frames.tres")
const RING_FRAMES: SpriteFrames = preload("res://entities/effects/ultimate_ring_frames.tres")
## The ring art has two sizes: the base radius and Wider Circle's; the larger one is used once the radius is this much bigger.
const WIDE_RING_AT: float = 1.2
const USE_SHAKE: Vector2 = Vector2(4.0, 0.3)

## Tests: a fixed aim for the Volley instead of the mouse.
var aim_override: Vector2 = Vector2.ZERO

var _hero: Hero
var _minions: MinionPool
var _effects: Node2D
var _modifiers: RunModifiers
var _ult: HeroUltimate


## Wires the runner to the level's pieces; does nothing for a hero without an ultimate.
func setup(hero: Hero, minions: MinionPool, effects: Node2D, modifiers: RunModifiers, spawner: WaveSpawner) -> void:
	_hero = hero
	_minions = minions
	_effects = effects
	_modifiers = modifiers
	_ult = hero.get_ultimate()
	_ult.modifiers = modifiers
	hero.dealt.connect(_ult.credit_hit)
	minions.minion_struck.connect(_on_minion_struck)
	if spawner != null:
		spawner.enemy_killed.connect(_ult.credit_kill)
		spawner.wave_started.connect(func(_n: int) -> void: _ult.wave_running = true)
		spawner.wave_cleared.connect(func(_n: int) -> void: _ult.wave_running = false)
	_ult.used.connect(_on_used)
	_ult.charged.connect(func() -> void: Sfx.play(_hero, &"ultimate_ready"))


## The skeleton counts for the hero only when it is hers.
func _on_minion_struck(minion: Minion, enemy: Enemy, _killed: bool) -> void:
	if is_instance_valid(minion) and minion.anchor == _hero and minion.data != null:
		_ult.credit_hit(enemy, minion.data.damage)


func _on_used() -> void:
	var data: UltimateData = _ult.get_data()
	Sfx.play(_hero, data.sound)
	Juice.shake(_hero, USE_SHAKE.x, USE_SHAKE.y)
	match data.kind:
		UltimateData.Kind.LAST_STAND:
			_last_stand(data)
		UltimateData.Kind.VOLLEY:
			_volley(data)
		UltimateData.Kind.RISE:
			_rise(data)


func _radius(data: UltimateData) -> float:
	return data.radius * RunModifiers.value(_modifiers, 1.0, [RunModifiers.HERO_ULT_RADIUS])


## Everything in the ring is held and takes a heavy blow (a boss is not held and takes a capped one); the hero
## takes less damage and swings wider for a while.
func _last_stand(data: UltimateData) -> void:
	var blow: int = _hero.get_attack_damage()
	for enemy: Enemy in EnemyQuery.in_circle(_hero.get_world_2d(), _hero.global_position, _radius(data)):
		if not enemy.data.is_boss:
			enemy.get_status().freeze(data.stun_time)
		enemy.get_health().take_damage(_damage_to(enemy, blow, data))
	_ult.start_buff(data.buff_seconds)
	_show_ring(_hero.global_position, _radius(data) / data.radius)


## The heavy blow's damage to `enemy`.
func _damage_to(enemy: Enemy, blow: int, data: UltimateData) -> int:
	if not enemy.data.is_boss:
		return roundi(blow * data.damage_multiplier)
	return mini(roundi(blow * data.boss_multiplier), ceili(enemy.get_health().max_health * data.boss_health_cap))


## Impacts rain along the line toward the aim, one after another; each hurts and Marks what it lands on.
func _volley(data: UltimateData) -> void:
	var aim: Vector2 = aim_override if not aim_override.is_zero_approx() else _hero.get_global_mouse_position() - _hero.global_position
	aim = aim.normalized() if not aim.is_zero_approx() else Vector2.DOWN
	var count: int = data.bolts + RunModifiers.value_int(_modifiers, 0, [RunModifiers.HERO_ULT_BOLTS])
	var gap: float = data.volley_seconds / maxf(count, 1)
	var origin: Vector2 = _hero.global_position
	var tween: Tween = create_tween()
	for i: int in count:
		var along: float = data.line_length * (i + 1) / count
		var side: Vector2 = aim.orthogonal() * (VOLLEY_SPREAD if i % 2 == 0 else -VOLLEY_SPREAD)
		tween.tween_callback(_impact.bind(origin + aim * along + side, data))
		tween.tween_interval(gap)


func _impact(at: Vector2, data: UltimateData) -> void:
	if not is_instance_valid(_hero):
		return
	var blow: int = _hero.get_attack_damage()
	var bonus: float = RunModifiers.value(_modifiers, data.mark_bonus, [RunModifiers.HERO_MARK_BONUS])
	for enemy: Enemy in EnemyQuery.in_circle(_hero.get_world_2d(), at, VOLLEY_RADIUS * RunModifiers.value(_modifiers, 1.0, [RunModifiers.HERO_ULT_RADIUS])):
		enemy.get_status().mark(bonus, data.mark_time)
		enemy.get_health().take_damage(_damage_to(enemy, blow, data))
	_flash(at)


## A ring of skeletons around the hero, over the number she may have raised otherwise, for a while.
func _rise(data: UltimateData) -> void:
	var raised: MinionData = _hero.data.raise_minion.duplicate()
	raised.lifetime = data.skeleton_seconds
	raised.move_speed *= SKELETON_SPEEDUP
	var count: int = data.skeletons + RunModifiers.value_int(_modifiers, 0, [RunModifiers.HERO_ULT_SKELETONS])
	for i: int in count:
		var at: Vector2 = _hero.global_position + Vector2.from_angle(TAU * i / maxf(count, 1)) * RISE_RING
		_minions.raise(raised, at, self, count, _hero)


## One-shot visuals (display only): a ring of light around the hero (its size follows Wider Circle), a blast where an impact lands.
func _show_ring(at: Vector2, scale_of_radius: float) -> void:
	var ring: AnimatedSprite2D = AnimatedSprite2D.new()
	ring.sprite_frames = RING_FRAMES
	ring.z_index = -1
	ring.position = _effects.to_local(at)
	ring.animation_finished.connect(ring.queue_free)
	_effects.add_child(ring)
	ring.play(&"ring_wide" if scale_of_radius >= WIDE_RING_AT else &"ring")


func _flash(at: Vector2) -> void:
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames = VOLLEY_FRAMES
	sprite.position = _effects.to_local(at)
	sprite.animation_finished.connect(sprite.queue_free)
	_effects.add_child(sprite)
	sprite.play(&"explosion")
