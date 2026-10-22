class_name Enemy
extends CharacterBody2D
## Base enemy: walks along its lane toward the fortress. When the hero comes within attack range it
## stops and attacks, then resumes the lane once the hero is gone; a ranged enemy (the Cultist) also
## stops before the fortress to shoot it: EnemyAttack runs the attacks. A boss has an EnemyAbility (EnemyData.ability)
## that runs beside this and may take the enemy over for a while (is_busy).
## Towers can slow it (apply_slow: the strongest slow wins, it always wears off), freeze it (no moving
## or attacking), make it vulnerable (more damage taken) and drag it back along its lane: EnemyStatus
## keeps those effects.
## Dies when its HP runs out; is used up when its FortressHitbox reaches the fortress.
## A shielded enemy (EnemyData.shield_arc, the Shieldbearer) blocks tower shots that come at its front
## (receive_shot): it faces the way it walks, or its target while it fights.
## Stats, body size and animations come from an EnemyData resource (one scene for every enemy type).
## Visuals only follow the gameplay state.

## Killed by damage (e.g. the hero). Emitted at most once, and never together with reached_fortress.
signal died(enemy: Enemy)
## Touched the fortress and was used up. Emitted at most once, and never together with died.
signal reached_fortress(enemy: Enemy)
## An attack on a target began (the wind-up started).
signal attack_started(enemy: Enemy)
## Its ability calls up `data` at `at` (the WaveSpawner adds it to the wave, on this enemy's lane).
signal summon_requested(summoner: Enemy, minion: EnemyData, at: Vector2)
## Its shield stopped a tower shot (nothing was taken).
signal shot_blocked(enemy: Enemy)
## Damage it took since the last report (summed, so burning doesn't flood: at most every
## DAMAGE_REPORT_TIME, and once more as it dies). The level shows it as a number.
signal damage_reported(amount: int, at: Vector2)

## How far ahead on the lane the enemy aims, in pixels. Aiming ahead (instead of following
## a fixed position) lets it find its way back to the lane if something pushes it off.
const LANE_LOOKAHEAD: float = 24.0
## The hurtbox is this much bigger than the body, so hits that graze the body still count.
const HURTBOX_MARGIN: float = 2.0
## The claw/fist strike reaches this far past the body's edge (centre of the attack shape).
const STRIKE_REACH: float = 10.0
## A boss's arrival shakes the screen this much (px) for this long (s).
const BOSS_ARRIVAL_SHAKE: float = 3.0
const BOSS_ARRIVAL_SHAKE_TIME: float = 0.5
## Seconds between two damage reports (damage_reported).
const DAMAGE_REPORT_TIME: float = 0.3

@export var data: EnemyData

## The Path2D to follow. Set by the spawner before the enemy is added to the tree.
var lane: Path2D
## Its wave's toughness: max HP = data.max_health x this. Set by the spawner before it enters the tree.
var health_multiplier: float = 1.0
## Its wave's kill-gold scale: the kill pays data.gold_reward x this (WaveRewards). Set by the spawner.
var gold_multiplier: float = 1.0
## Its wave's pace: move speed = data.move_speed x this (before slows). Set by the spawner.
var speed_multiplier: float = 1.0

var _is_finished: bool = false
## Where on its lane the enemy is (curve offset), worked out once per physics frame: finding the
## closest point on the curve is the costliest thing an enemy does, and towers ask for it too.
var _lane_offset: float = 0.0
var _lane_offset_frame: int = -1
var _ability: EnemyAbility
## The way it faces (its shield's side): where it walks, or toward what it attacks.
var _heading: Vector2 = Vector2.DOWN
var _last_health: int = 0
var _unreported_damage: int = 0
var _report_left: float = 0.0

@onready var _health: HealthComponent = %HealthComponent
@onready var _fortress_hitbox: Hitbox = %FortressHitbox
@onready var _attack_hitbox: Hitbox = %AttackHitbox
@onready var _attack_shape: CollisionShape2D = %AttackShape
@onready var _attack: EnemyAttack = %Attack
@onready var _sprite: DirectionalSprite = %Sprite
@onready var _hurtbox: Hurtbox = %Hurtbox
@onready var _look: EnemyLook = %Look
@onready var _status: EnemyStatus = %Status


func _ready() -> void:
	assert(data != null, "Enemy needs EnemyData: %s" % get_path())
	_health.setup(maxi(roundi(data.max_health * health_multiplier), 1))
	_last_health = _health.current_health
	_fortress_hitbox.damage = data.fortress_damage
	_attack_hitbox.damage = data.hero_damage
	_apply_body(data.body_radius)
	_look.setup(data)
	_health.shield_changed.connect(_look.show_shield)
	_status.setup(_health, data.burn_taken)
	_status.status_changed.connect(func() -> void: _look.show_status(_status))
	if data.ability != null:
		_ability = data.ability.instantiate()
		_ability.setup(self)
		add_child(_ability)
	_health.died.connect(_on_health_died)
	_health.health_changed.connect(_on_health_changed)
	_fortress_hitbox.hit.connect(_on_fortress_hitbox_hit)
	_attack.setup(self)
	if data.is_boss:
		Sfx.play(self, &"boss_appear")
		Juice.shake(self, BOSS_ARRIVAL_SHAKE, BOSS_ARRIVAL_SHAKE_TIME)
	_attack.attack_started.connect(func() -> void: attack_started.emit(self))


func _physics_process(delta: float) -> void:
	_report_left -= delta
	if _unreported_damage > 0 and _report_left <= 0.0:
		_report_damage()
	_attack.tick_cooldown(delta)
	_status.tick(delta)
	if _status.is_dragged():
		velocity = Vector2.ZERO
		global_position += _status.drag_step(lane, global_position, delta)
		return
	if _status.is_frozen():
		velocity = Vector2.ZERO
		return  # frozen solid: no step, no strike (a wind-up waits)
	if is_busy():
		return  # the ability moves and animates it
	_attack.step(delta)
	if is_attacking() or has_target() or is_sieging():
		velocity = Vector2.ZERO  # stand and fight
		var aim: Vector2 = _attack.get_aim_point() - global_position
		if not aim.is_zero_approx():
			_heading = aim.normalized()
	elif lane != null:
		velocity = _direction_along_lane() * get_move_speed()
		if not velocity.is_zero_approx():
			_heading = velocity.normalized()
		move_and_slide()
	else:
		velocity = Vector2.ZERO
	_update_animation()


## Sizes every shape from the body radius (the shapes are local to each enemy instance).
func _apply_body(body_radius: float) -> void:
	((%BodyShape as CollisionShape2D).shape as CircleShape2D).radius = body_radius
	((%HurtShape as CollisionShape2D).shape as CircleShape2D).radius = body_radius + HURTBOX_MARGIN
	((%FortressShape as CollisionShape2D).shape as CircleShape2D).radius = body_radius
	((%RangeShape as CollisionShape2D).shape as CircleShape2D).radius = body_radius + data.attack_range
	_attack_shape.position = Vector2(body_radius + STRIKE_REACH, 0)


## True while its ability has taken over (telegraphing, charging, stunned): no walking, no attacks.
func is_busy() -> bool:
	return _ability != null and _ability.is_busy()


func get_health() -> HealthComponent:
	return _health


func get_sprite() -> DirectionalSprite:
	return _sprite


## A ward from a boss: absorbs `amount` damage for `seconds` (see HealthComponent.add_shield).
func add_shield(amount: int, seconds: float) -> void:
	if is_alive():
		_health.add_shield(amount, seconds)


func request_summon(minion: EnemyData, at: Vector2) -> void:
	summon_requested.emit(self, minion, at)


## The spawner reports the enemy a summon produced (a summoner keeps count of its own).
func adopt_minion(minion: Enemy) -> void:
	var summoner: SummonAbility = _ability as SummonAbility
	if summoner != null:
		summoner.track_minion(minion)


## True while winding up or striking.
func is_attacking() -> bool:
	return _attack.is_attacking()


func has_target() -> bool:
	return _attack.has_target()


## True for a ranged enemy standing at its firing spot before the fortress, shooting it.
func is_sieging() -> bool:
	return _attack.is_sieging()


## Still in play: not killed, not used up at the fortress. Towers only target living enemies.
func is_alive() -> bool:
	return not _is_finished and not is_queued_for_deletion()


## How far along its lane it is, in pixels (more = closer to the fortress). Towers prefer the leader.
func get_lane_progress() -> float:
	if lane == null:
		return 0.0
	var frame: int = Engine.get_physics_frames()
	if frame != _lane_offset_frame:
		_lane_offset_frame = frame
		_lane_offset = lane.curve.get_closest_offset(lane.to_local(global_position))
	return _lane_offset


func get_move_speed() -> float:
	return data.move_speed * speed_multiplier * _status.get_slow_factor()


func is_slowed() -> bool:
	return _status.is_slowed()


## Its slows, freeze, vulnerability and drag (towers apply them here).
func get_status() -> EnemyStatus:
	return _status


## Pulled back `distance` px along its lane (Harpoon), quickly; it walks on afterwards.
func drag_back(distance: float) -> void:
	if is_alive() and lane != null and distance > 0.0:
		_status.drag_to(get_lane_progress() - distance)


## Pushed back along its lane by `distance` px (the hero's sword), less for tough ones, none for bosses.
func knock_back(distance: float) -> void:
	if not data.is_boss:
		drag_back(distance * data.knockback_taken)


## Takes a hit from a projectile that already knows its target (same path as an overlapping hitbox).
func receive_hit(hitbox: Hitbox) -> bool:
	return is_alive() and _hurtbox.receive_hit(hitbox)


## A tower shot flying along `travel`: a shield facing it blocks it (false, shot_blocked), anything
## else takes it like receive_hit. Blasts, burning ground, arrows falling from the sky and the hero's
## sword are not shots: they always get through.
func receive_shot(hitbox: Hitbox, travel: Vector2) -> bool:
	if not is_alive():
		return false
	if blocks_shot(travel):
		shot_blocked.emit(self)
		_look.show_block()
		Sfx.play(self, &"shield_block")
		return false
	return _hurtbox.receive_hit(hitbox)


## True if a shot flying along `travel` hits its shield (it comes at its front, within the arc).
func blocks_shot(travel: Vector2) -> bool:
	return data.shield_blocks(travel, _heading)


## The way it faces (where its shield is).
func get_heading() -> Vector2:
	return _heading


## Healed by `amount` (a Mire Priest's pulse): shown in green, never above its max HP.
func heal(amount: int) -> void:
	if not is_alive():
		return
	var before: int = _health.current_health
	_health.heal(amount)
	_last_health = _health.current_health
	if _health.current_health > before:
		_look.show_heal(_health.current_health - before, _health.current_health, _health.max_health)


## Slows movement to `factor` of normal speed for `duration` seconds. Slows never stack: the strongest
## factor applies and the longest remaining time is kept; when it runs out, speed is normal again.
func apply_slow(factor: float, duration: float) -> void:
	_status.apply_slow(factor, duration)




## True when it could start an attack right now if the target's AttackerLimit gave it a slot.
func is_ready_to_attack() -> bool:
	return _attack.is_ready_to_attack()


func _direction_along_lane() -> Vector2:
	var target: Vector2 = lane.to_global(lane.curve.sample_baked(get_lane_progress() + LANE_LOOKAHEAD))
	var to_target: Vector2 = target - global_position
	if to_target.length() < 1.0:
		return Vector2.ZERO
	return to_target.normalized()


func _update_animation() -> void:
	if _sprite.is_playing_state("attack"):
		return  # let the attack play out
	if velocity.is_zero_approx():
		_sprite.play_state("idle")
	else:
		_sprite.face(velocity)
		_sprite.play_state("walk")


## Damage feedback (a heal is shown by heal()).
func _on_health_changed(current_health: int, max_health: int) -> void:
	if current_health < _last_health:
		_unreported_damage += _last_health - current_health
		_look.show_hit(current_health, max_health)
		if current_health > 0:
			Sfx.play(self, &"enemy_hit")
	_last_health = current_health


func _on_health_died() -> void:
	if _ability != null:
		_ability.on_owner_died()  # before `died`: what it leaves behind (a Bloater's young) joins the wave first
	Sfx.play(self, &"boss_death" if data.is_boss else &"enemy_death")
	if _unreported_damage > 0:
		_report_damage()
	_finish(died)


func _on_fortress_hitbox_hit(_fortress_hurtbox: Hurtbox) -> void:
	# Reaching the fortress spends the enemy.
	_finish(reached_fortress)


## Reports how the enemy left (once, even if killed in the same frame it reaches the fortress) and removes it.
func _finish(outcome: Signal) -> void:
	if _is_finished:
		return
	_is_finished = true
	outcome.emit(self)
	queue_free()


func _report_damage() -> void:
	damage_reported.emit(_unreported_damage, global_position)
	_unreported_damage = 0
	_report_left = DAMAGE_REPORT_TIME
