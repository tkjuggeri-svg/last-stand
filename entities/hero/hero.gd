class_name Hero
extends CharacterBody2D
## The player-controlled hero. Moves with the move_* actions, swings a melee attack toward the mouse and
## dashes (HeroDash) in the movement direction, passing through enemies and immune while it lasts.
## Enemy attacks hurt it through its Hurtbox (with a short invulnerability window after each hit).
## When it falls it stops being a target (enemies walk on) until revive() brings it back. In marsh
## water (MarshWater) it wades: slower, with rings spreading around it.
## Visuals (DirectionalSprite, swing trail, hit feedback) only follow the gameplay state.

## HP reached 0. HeroLives decides whether it comes back.
signal died
## Back on its feet with full HP (see revive()).
signal revived
## Its sword landed a hit for `damage` (the Bloodpact relic heals from it).
signal struck(damage: int)
## Its bolt killed an enemy, which fell at `at` (the Necromancer raises a skeleton there).
signal slew(at: Vector2)
## It lost `amount` HP (a hit got through).
signal hurt(amount: int)
## An enemy's hit landed on the hero (Crown of Thorns answers it).
signal hit_by(attacker: Enemy)

const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://entities/effects/damage_number.tscn")
## Where damage numbers appear, relative to the hero.
const DAMAGE_NUMBER_OFFSET: Vector2 = Vector2(0, -34)
## Respawn protection blink: the sprite fades to this alpha and back, this many times per second.
const BLINK_ALPHA: float = 0.3
## The swing trail art: normal reach, and the Long Reach tiers (reach x REACH_TIERS[i] is tier i + 1).
const SWING_FRAMES: SpriteFrames = preload("res://entities/hero/swing_frames.tres")
const SWING_LONG_FRAMES: SpriteFrames = preload("res://entities/hero/swing_long_frames.tres")
const BOLT_SCENE: PackedScene = preload("res://entities/hero/hero_bolt.tscn")
## Where a bolt leaves the crossbow: this far (px) along the aim, at chest height.
const MUZZLE_DISTANCE: float = 18.0
const MUZZLE_HEIGHT: float = -14.0
## Quiver of Plenty: every this-many bolts is a fan of three, the side ones this far (rad) off the aim.
const QUIVER_EVERY: int = 5
const QUIVER_FAN: float = 0.21
const REACH_TIERS: Array[float] = [1.0, 1.15, 1.3, 1.45, 1.6]
const BLINKS_PER_SECOND: float = 6.0
## Bulwark never shrugs off more than this share of a hit; Shield Bash reaches enemies this close to the dashing hero (px).
const BULWARK_MAX: float = 0.9
const BASH_RADIUS: float = 48.0
## Game feel (M8.5, display only): a landed hit and a hit taken stop time this long (s) and shake the
## screen this much (px), a fall more.
const HIT_STOP: float = 0.03
const HIT_SHAKE: Vector2 = Vector2(1.5, 0.08)
const HURT_STOP: float = 0.06
const HURT_SHAKE: Vector2 = Vector2(3.0, 0.18)
const DEATH_SHAKE: Vector2 = Vector2(5.0, 0.4)

## The hero's stats (data/heroes/); they replace the values below when the hero is ready.
@export var data: HeroData
@export var move_speed: float = 200.0
## The run's upgrades (damage, speed, max HP, attack speed, reach). Null = base stats.
@export var modifiers: RunModifiers
## How long the swing's hitbox stays active, in seconds.
@export var attack_duration: float = 0.12
## Time between the start of two swings, in seconds. Keep it longer than attack_duration.
@export var attack_cooldown: float = 0.4
## How far (px) a sword hit pushes an enemy back along its lane (EnemyData.knockback_taken scales it).
@export var knockback: float = 12.0

## Extra damage the hero deals where it stands, as a share (a Watchtower's: set by the Level).
var damage_bonus_at: Callable = Callable()
var _bolts_fired: int = 0
## A chill (a Frost Wraith's): the share of its speed the hero keeps, and for how much longer.
var _chill_factor: float = 1.0
var _chill_left: float = 0.0
## Held in place (roots): the seconds left; a dash breaks free.
var _held_left: float = 0.0
var _attack_time_left: float = 0.0
## The enemies this dash has already knocked back (Shield Bash), by instance id.
var _bashed: Dictionary = {}
## The last direction the hero moved in: a dash from standing still goes this way.
var _last_direction: Vector2 = Vector2.DOWN
var _cooldown_left: float = 0.0
var _last_health: int = 0
var _base_max_health: int = 0
var _base_damage: int = 0
## The body's collision layer while alive (the hero layer); 0 while fallen.
var _body_layer: int = 0
## Share of its speed it keeps (1 on land; less while wading, see set_wading()).
var _wading_speed: float = 1.0

## Public so other systems (HUD) can read HP.
@onready var health: HealthComponent = %HealthComponent
@onready var _hit_spark: AnimatedSprite2D = %HitSpark
@onready var _attack_pivot: Node2D = %AttackPivot
@onready var _attack_shape: CollisionPolygon2D = %AttackShape
@onready var _attack_visual: AnimatedSprite2D = %AttackVisual
@onready var _sprite: DirectionalSprite = %Sprite
@onready var _hurtbox: Hurtbox = %Hurtbox
@onready var _attack_hitbox: Hitbox = %AttackHitbox
@onready var _dash: HeroDash = %Dash
@onready var _ripple: AnimatedSprite2D = %Ripple


func _ready() -> void:
	_apply_data()
	_attack_visual.animation_finished.connect(_attack_visual.hide)
	_hit_spark.animation_finished.connect(_hit_spark.hide)
	_last_health = health.current_health
	_body_layer = collision_layer
	_base_max_health = health.max_health
	_base_damage = _attack_hitbox.damage
	_dash.modifiers = modifiers
	_dash.setup(self, _sprite)
	_attack_hitbox.hit.connect(_on_attack_landed)
	_hurtbox.hit_received.connect(_on_hit_received)
	if modifiers != null:
		modifiers.changed.connect(_apply_modifiers)
		_apply_modifiers()
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_health_died)


func _physics_process(delta: float) -> void:
	if health.is_dead():
		return
	if Input.is_action_just_pressed("dash"):
		dash(_input_direction())
	if _dash.is_dashing():
		velocity = _dash.get_velocity()
		move_and_slide()
		_bash_enemies()
	else:
		_move()
	_update_attack_timers(delta)
	health.damage_taken_multiplier = _bulwark_multiplier()
	# Holding the button keeps swinging, limited by the cooldown. Clicks on UI (e.g. the build menu)
	# are not swings.
	if Input.is_action_pressed("attack") and get_viewport().gui_get_hovered_control() == null:
		attack(get_global_mouse_position())
	_update_animation()


## Swings toward a point in the world. Does nothing while the previous swing is on cooldown.
func attack(target_position: Vector2) -> void:
	if _cooldown_left > 0.0 or health.is_dead() or _dash.is_dashing():
		return
	var direction: Vector2 = target_position - global_position
	_attack_pivot.rotation = direction.angle()
	_cooldown_left = RunModifiers.value(modifiers, attack_cooldown, [RunModifiers.HERO_ATTACK_COOLDOWN])
	if data != null and data.attack_kind == HeroData.AttackKind.BOLT:
		_fire_bolt(direction)
		return
	_attack_time_left = attack_duration
	_set_attack_active(true)
	_sprite.face(direction)
	_sprite.play_state("attack", true)
	_play_swing_trail(direction.angle())
	Sfx.play(self, &"hero_swing")


## The Huntress's attack: a bolt along the aim, her animation and no sword arc.
func _fire_bolt(direction: Vector2) -> void:
	var aim: Vector2 = direction.normalized() if not direction.is_zero_approx() else Vector2.DOWN
	_bolts_fired += 1
	_loose_bolt(aim)
	if RunModifiers.relic(modifiers, RunModifiers.RELIC_QUIVER) and _bolts_fired % QUIVER_EVERY == 0:
		_loose_bolt(aim.rotated(QUIVER_FAN))
		_loose_bolt(aim.rotated(-QUIVER_FAN))
	_sprite.face(aim)
	_sprite.play_state("attack", true)
	Sfx.play(self, data.bolt_sound)


## One bolt along `aim`, with the run's upgrades (range, pierce, Mark) and a Watchtower's bonus.
func _loose_bolt(aim: Vector2) -> void:
	var bolt: HeroBolt = BOLT_SCENE.instantiate()
	var bonus: float = float(damage_bonus_at.call(global_position)) if damage_bonus_at.is_valid() else 0.0
	bolt.reach_scale = RunModifiers.value(modifiers, 1.0, [RunModifiers.HERO_REACH])
	bolt.extra_pierce = RunModifiers.value_int(modifiers, 0, [RunModifiers.HERO_BOLT_PIERCE])
	bolt.mark_bonus = RunModifiers.value(modifiers, data.mark_bonus, [RunModifiers.HERO_MARK_BONUS])
	bolt.mark_time = RunModifiers.value(modifiers, data.mark_time, [RunModifiers.HERO_MARK_TIME])
	bolt.launch(global_position + Vector2(0, MUZZLE_HEIGHT) + aim * MUZZLE_DISTANCE, aim, roundi(_attack_hitbox.damage * (1.0 + bonus)), data)
	bolt.hit.connect(_on_bolt_hit)
	add_child(bolt)


## Dashes toward `direction` (zero: the way the hero last moved). Hits are ignored while it lasts.
## Returns false while dashing, on cooldown or fallen.
func dash(direction: Vector2) -> bool:
	if health.is_dead():
		return false
	if not _dash.try_dash(direction if not direction.is_zero_approx() else _last_direction):
		return false
	_bashed.clear()
	_held_left = 0.0
	_hurtbox.make_invulnerable(_dash.get_invulnerability())
	Sfx.play(self, &"hero_dash")
	return true


## Held in place for `seconds` (a Hollow Stag's roots): no walking; a dash breaks free.
func hold(seconds: float) -> void:
	_held_left = maxf(_held_left, seconds)


func is_held() -> bool:
	return _held_left > 0.0


## Chilled for `seconds`: the hero keeps `factor` of its speed (the strongest chill counts).
func chill(seconds: float, factor: float) -> void:
	if _chill_left <= 0.0 or factor < _chill_factor:
		_chill_factor = factor
	_chill_left = maxf(_chill_left, seconds)


func is_chilled() -> bool:
	return _chill_left > 0.0


func _chill_speed() -> float:
	return _chill_factor if _chill_left > 0.0 else 1.0


## Wading in water that leaves it `speed_factor` of its speed (1 = back on dry land).
func set_wading(speed_factor: float) -> void:
	_wading_speed = speed_factor
	_ripple.visible = is_wading()


func is_wading() -> bool:
	return _wading_speed < 1.0


## The dash component (cooldown, for the HUD).
func get_dash() -> HeroDash:
	return _dash


## The hero's own base stats from its data (none: the scene's values stay).
func _apply_data() -> void:
	if data == null:
		return
	if data.frames != null:
		_sprite.sprite_frames = data.frames
	health.setup(data.max_health)
	_attack_hitbox.damage = data.attack_damage
	move_speed = data.move_speed
	attack_cooldown = data.attack_cooldown
	attack_duration = data.attack_duration
	knockback = data.knockback


## Max HP, swing damage and reach under the run's upgrades (re-read whenever they change).
func _apply_modifiers() -> void:
	health.set_max_health(modifiers.apply_int(_base_max_health, [RunModifiers.HERO_MAX_HEALTH]))
	_attack_hitbox.damage = modifiers.apply_int(_base_damage, [RunModifiers.HERO_DAMAGE])
	# Scaling the hitbox (an Area2D, not a sprite) lengthens the swing's reach; the trail art stays.
	_attack_hitbox.scale = Vector2.ONE * modifiers.apply(1.0, [RunModifiers.HERO_REACH])


## Brings a fallen hero back at `at` with full HP, idle and targetable again, and immune to hits for
## `invulnerable_time` seconds (shown by a blink). Does nothing while alive.
func revive(at: Vector2, invulnerable_time: float = 0.0) -> void:
	if not health.is_dead():
		return
	global_position = at
	velocity = Vector2.ZERO
	_cooldown_left = 0.0
	health.revive()
	_set_targetable(true)
	_sprite.facing = "down"
	_sprite.play_state("idle", true)
	if invulnerable_time > 0.0:
		_hurtbox.make_invulnerable(invulnerable_time)
		_blink(invulnerable_time)
	Sfx.play(self, &"hero_respawn")
	revived.emit()


## True while hits are ignored (right after a hit or a respawn).
func is_invulnerable() -> bool:
	return _hurtbox.is_invulnerable()


## Display only: the sprite flickers for `seconds`, then is fully visible again.
func _blink(seconds: float) -> void:
	var blinks: int = maxi(roundi(seconds * BLINKS_PER_SECOND), 1)
	var half: float = seconds / blinks / 2.0
	var tween: Tween = _sprite.create_tween()
	for _i: int in blinks:
		tween.tween_property(_sprite, "modulate:a", BLINK_ALPHA, half)
		tween.tween_property(_sprite, "modulate:a", 1.0, half)


func _move() -> void:
	var input_direction: Vector2 = _input_direction()
	if not input_direction.is_zero_approx():
		_last_direction = input_direction
	velocity = input_direction * RunModifiers.value(modifiers, move_speed, [RunModifiers.HERO_MOVE_SPEED]) * _wading_speed * _chill_speed()
	if _held_left > 0.0:
		velocity = Vector2.ZERO
	move_and_slide()


func _input_direction() -> Vector2:
	# get_vector() caps the length at 1, so diagonals are not faster than straight lines.
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func _update_attack_timers(delta: float) -> void:
	_chill_left = maxf(_chill_left - delta, 0.0)
	_held_left = maxf(_held_left - delta, 0.0)
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if _attack_time_left > 0.0:
		_attack_time_left -= delta
		if _attack_time_left <= 0.0:
			_set_attack_active(false)


func _set_attack_active(active: bool) -> void:
	# Turning the shape on makes hurtboxes inside it register a new hit, so each swing hits once.
	# Deferred because physics shapes should not change in the middle of a physics step.
	_attack_shape.set_deferred("disabled", not active)


## A fallen hero leaves the hero layer, so enemies' attack ranges let go and they walk on, and its
## hurtbox stops listening. Deferred: this changes physics state, often inside a physics callback.
func _set_targetable(targetable: bool) -> void:
	set_deferred(&"collision_layer", _body_layer if targetable else 0)
	_hurtbox.set_deferred(&"monitoring", targetable)


func _update_animation() -> void:
	if _dash.is_dashing():
		_sprite.face(velocity)
		_sprite.play_state("dash")  # the lunge behind the shield (display only)
		return
	if _sprite.is_playing_state("attack"):
		return  # let the swing pose finish
	if velocity.is_zero_approx():
		_sprite.play_state("idle")
	else:
		_sprite.face(velocity)
		_sprite.play_state("walk")


## The trail art exists for 8 directions (every 45 degrees); the hitbox itself follows the exact aim.
## With Long Reach the trail drawn at the nearest reach tier is used, so it matches the hitbox.
func _play_swing_trail(angle: float) -> void:
	var index: int = posmod(roundi(angle / (PI / 4.0)), 8)
	var tier: int = get_reach_tier()
	_attack_visual.sprite_frames = SWING_FRAMES if tier == 0 else SWING_LONG_FRAMES
	_attack_visual.show()
	_attack_visual.stop()
	_attack_visual.play(StringName("swing_%d" % index if tier == 0 else "swing_%d_%d" % [index, tier]))


## Which trail size fits the swing's reach: 0 = normal, 1-4 = the Long Reach tiers (nearest).
func get_reach_tier() -> int:
	var reach: float = RunModifiers.value(modifiers, 1.0, [RunModifiers.HERO_REACH])
	var best: int = 0
	for i: int in REACH_TIERS.size():
		if absf(REACH_TIERS[i] - reach) < absf(REACH_TIERS[best] - reach):
			best = i
	return best


## Hit feedback: a red-white flash, a spark and a floating damage number.
func _on_health_changed(current_health: int, _max_health: int) -> void:
	var amount: int = _last_health - current_health
	_last_health = current_health
	if amount <= 0:
		return
	# The tween belongs to the sprite, which keeps running during Game Over, so the flash always ends.
	var flash_material: ShaderMaterial = _sprite.material
	flash_material.set_shader_parameter("flash", 0.9)  # visible in the same frame as the hit
	var flash: Tween = _sprite.create_tween()
	flash.tween_property(flash_material, "shader_parameter/flash", 0.0, 0.25)
	_hit_spark.show()
	_hit_spark.stop()
	_hit_spark.play(&"spark")
	Sfx.play(self, &"hero_hurt")
	Juice.hit_stop(self, HURT_STOP)
	Juice.shake(self, HURT_SHAKE.x, HURT_SHAKE.y)
	hurt.emit(amount)
	var number: DamageNumber = DAMAGE_NUMBER_SCENE.instantiate()
	number.set_amount(amount)
	number.top_level = true  # stays where the hit happened instead of following the hero
	number.position = global_position + DAMAGE_NUMBER_OFFSET
	add_child(number)


func _on_bolt_hit(enemy: Enemy) -> void:
	Sfx.play(self, &"hero_hit")
	struck.emit(_attack_hitbox.damage)
	if is_instance_valid(enemy) and not enemy.is_alive():
		slew.emit(enemy.global_position)


## Oathkeeper: a sword hit on a boss lands this many more times.
func _oathkeeper(enemy: Enemy) -> void:
	var extra: int = RunModifiers.value_int(modifiers, 0, [RunModifiers.HERO_BOSS_HITS])
	if extra > 0 and enemy.data != null and enemy.data.is_boss and enemy.is_alive():
		enemy.get_health().take_damage(_attack_hitbox.damage * extra)


## Bulwark: while swinging (the swing's cooldown), a hit does this share of its damage (Iron Will lowers it more).
func _bulwark_multiplier() -> float:
	if data == null or _cooldown_left <= 0.0 or data.attack_kind != HeroData.AttackKind.SWORD:
		return 1.0
	return 1.0 - clampf(RunModifiers.value(modifiers, data.bulwark, [RunModifiers.HERO_BULWARK]), 0.0, BULWARK_MAX)


## Shield Bash: a dash knocks every enemy it passes back along its lane, once per dash.
func _bash_enemies() -> void:
	var push: float = RunModifiers.value(modifiers, 0.0, [RunModifiers.HERO_DASH_BASH])
	if push <= 0.0:
		return
	for enemy: Enemy in EnemyQuery.in_circle(get_world_2d(), global_position, BASH_RADIUS):
		if not _bashed.has(enemy.get_instance_id()):
			_bashed[enemy.get_instance_id()] = true
			enemy.knock_back(push)


func _on_hit_received(hitbox: Hitbox) -> void:
	var attacker: Enemy = hitbox.owner as Enemy if is_instance_valid(hitbox) else null
	if attacker != null:
		hit_by.emit(attacker)


func _on_attack_landed(target: Hurtbox) -> void:
	Sfx.play(self, &"hero_hit")
	Juice.hit_stop(self, HIT_STOP)
	Juice.shake(self, HIT_SHAKE.x, HIT_SHAKE.y)
	var enemy: Enemy = target.owner as Enemy if is_instance_valid(target) else null
	if enemy != null:
		enemy.knock_back(knockback)
		_oathkeeper(enemy)
	struck.emit(_attack_hitbox.damage)


func _on_health_died() -> void:
	_attack_time_left = 0.0
	_dash.cancel()
	_set_attack_active(false)
	_attack_visual.hide()
	_set_targetable(false)
	_sprite.play(&"death")
	Sfx.play(self, &"hero_death")
	Juice.shake(self, DEATH_SHAKE.x, DEATH_SHAKE.y)
	died.emit()
