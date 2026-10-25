class_name Fortress
extends StaticBody2D
## The structure the player defends. Enemies damage it through its Hurtbox; at 0 HP the run is lost.
## Its sprite shows how damaged it is: healthy, damaged (<= 2/3 HP), badly damaged (<= 1/3), destroyed.
## Decor children (banners, braziers, fires with smoke) appear and disappear with the look, and a hit
## shakes the walls and kicks up dust. All of that is display only.

signal destroyed

enum Look { HEALTHY, DAMAGED, BADLY_DAMAGED, DESTROYED }

const DUST_SCENE: PackedScene = preload("res://entities/effects/dust_puff.tscn")
## A hit also shakes the screen a little (px, s).
const HIT_SCREEN_SHAKE: float = 2.0
const HIT_SCREEN_SHAKE_TIME: float = 0.12
## How far (world px) and how long (s) the walls shake when hit.
const SHAKE_DISTANCE: float = 2.0
const SHAKE_TIME: float = 0.2
## Where hit dust can rise: the visible walls, relative to the fortress origin.
const DUST_AREA: Rect2 = Rect2(-50, -40, 100, 90)
## Dust clouds when the fortress falls.
const COLLAPSE_PUFFS: int = 7
## Thorned walls (upgrade): enemies whose body is this close to the fortress's centre take the
## thorns' damage per second, in ticks of THORNS_TICK seconds.
const THORNS_RADIUS: float = 200.0
const THORNS_TICK: float = 0.5

## The run's upgrades (max HP, thorns). Null = base stats.
@export var modifiers: RunModifiers

var _shake: Tween
var _base_max_health: int = 0
var _thorns_left: float = 0.0
var _thorns_hitbox: Hitbox
var _last_health: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _sprite_rest: Vector2 = Vector2.ZERO

## Public so other systems (HUD, game over) can read HP and connect to health_changed.
@onready var health: HealthComponent = %HealthComponent
@onready var _sprite: Sprite2D = %Sprite
## Children shown only for some looks: metadata "from_look" (default 0) and "until_look" (default 4).
## It and %Puffs keep processing after Game Over (the level is disabled), so the ruin keeps burning.
@onready var _look_decor: Node2D = %LookDecor
@onready var _puffs: Node2D = %Puffs


func _ready() -> void:
	_sprite_rest = _sprite.position
	_last_health = health.current_health
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_health_died)
	_base_max_health = health.max_health
	set_physics_process(false)
	if modifiers != null:
		modifiers.changed.connect(_apply_modifiers)
	_show_look(look_for(health.current_health, health.max_health))


## Repairs the walls by `fraction` of the max HP (an upgrade's instant effect, a reward). Nothing under
## Iron Tithe.
func repair(fraction: float) -> void:
	repair_hp(roundi(health.max_health * fraction))


## Repairs `amount` HP (the Quartermaster's, a merchant's). Nothing under Iron Tithe or No Repairs.
func repair_hp(amount: int) -> void:
	if can_repair():
		health.heal(amount)


## False under the Iron Tithe relic and Pressure's No Repairs: the walls can't be repaired at all.
func can_repair() -> bool:
	return not RunModifiers.relic(modifiers, RunModifiers.RELIC_IRON_TITHE) \
		and not RunModifiers.has_rule(modifiers, PressureRules.RULE_NO_REPAIRS)


func _apply_modifiers() -> void:
	health.set_max_health(modifiers.apply_int(_base_max_health, [RunModifiers.FORTRESS_MAX_HEALTH]))
	set_physics_process(get_thorns_dps() > 0.0)


## Damage per second the walls deal to enemies right at them (0 without the upgrade).
func get_thorns_dps() -> float:
	return modifiers.apply(0.0, [RunModifiers.FORTRESS_THORNS]) if modifiers != null else 0.0


func _physics_process(delta: float) -> void:
	_thorns_left -= delta
	if _thorns_left > 0.0:
		return
	_thorns_left += THORNS_TICK
	if _thorns_hitbox == null:
		_thorns_hitbox = Hitbox.new()
		_thorns_hitbox.collision_layer = 0  # hits are dealt directly, never by overlap
		add_child(_thorns_hitbox)
	_thorns_hitbox.damage = maxi(roundi(get_thorns_dps() * THORNS_TICK), 1)
	for enemy: Enemy in EnemyQuery.in_circle(get_world_2d(), global_position, THORNS_RADIUS):
		enemy.receive_hit(_thorns_hitbox)


## Which sprite frame (a Look) fits this much health.
static func look_for(current_health: int, max_health: int) -> Look:
	if current_health <= 0:
		return Look.DESTROYED
	var ratio: float = float(current_health) / float(max_health)
	if ratio > 2.0 / 3.0:
		return Look.HEALTHY
	if ratio > 1.0 / 3.0:
		return Look.DAMAGED
	return Look.BADLY_DAMAGED


func get_look() -> Look:
	return _sprite.frame as Look


func _show_look(look: Look) -> void:
	_sprite.frame = look
	for child: Node in _look_decor.get_children():
		var item: CanvasItem = child as CanvasItem
		if item == null:
			continue
		var shown: bool = look >= int(item.get_meta(&"from_look", 0)) and look < int(item.get_meta(&"until_look", 4))
		item.visible = shown
		var banner: AnimatedSprite2D = item as AnimatedSprite2D
		if banner != null and banner.sprite_frames.has_animation(&"banner_torn") and String(banner.animation).begins_with("banner"):
			banner.play(&"banner_torn" if look >= Look.BADLY_DAMAGED else &"banner")
		for particles: Node in item.find_children("*", "CPUParticles2D", true, false):
			(particles as CPUParticles2D).emitting = shown


func _on_health_changed(current_health: int, max_health: int) -> void:
	var look: Look = look_for(current_health, max_health)
	if look != get_look():
		_show_look(look)
	if current_health < _last_health:
		_react_to_hit()
	_last_health = current_health


func _react_to_hit() -> void:
	Sfx.play(self, &"fortress_hit")
	Juice.shake(self, HIT_SCREEN_SHAKE, HIT_SCREEN_SHAKE_TIME)
	if _shake != null:
		_shake.kill()
	_shake = create_tween()
	for i: int in 4:
		var offset: Vector2 = Vector2(SHAKE_DISTANCE if i % 2 == 0 else -SHAKE_DISTANCE, 0).round()
		_shake.tween_property(_sprite, "position", _sprite_rest + offset, SHAKE_TIME / 5.0)
	_shake.tween_property(_sprite, "position", _sprite_rest, SHAKE_TIME / 5.0)
	_puff(Vector2(_rng.randf_range(DUST_AREA.position.x, DUST_AREA.end.x), _rng.randf_range(DUST_AREA.position.y, DUST_AREA.end.y)))


func _puff(at: Vector2) -> void:
	var dust: Node2D = DUST_SCENE.instantiate()
	dust.position = at
	_puffs.add_child(dust)


func _on_health_died() -> void:
	for i: int in COLLAPSE_PUFFS:
		_puff(Vector2(_rng.randf_range(DUST_AREA.position.x, DUST_AREA.end.x), _rng.randf_range(DUST_AREA.position.y, DUST_AREA.end.y)))
	destroyed.emit()
