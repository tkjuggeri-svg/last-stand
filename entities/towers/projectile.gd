class_name Projectile
extends Node2D
## A tower's shot. Flies at its target, following it while it lives and stays within the tower's reach
## (attack range + RANGE_SLACK from the tower's base); a target that dies or runs out of reach is
## lost: the shot flies on to the last point it aimed at and fizzles (or explodes there, for splash).
## On arrival it either hits that one enemy or explodes. Damage always goes through the enemy's
## Hurtbox / HealthComponent. The sprite is display only.
## Shells (TowerData.homing = false) are different: fired at a ground point, they never follow anyone.
## They travel along the ground from the tower's base while the sprite rises from the muzzle in an
## arc (with a shadow below it), a LandingMarker shows the blast area, and they explode on the point:
## whatever stands there is hit, an enemy that got away is not.
## An evolved tower's shot can also freeze (Glacier Spire: `freezes`), drag its enemy back along the
## lane (Harpoon) or leave soul fire (Pyre of Souls): see TowerEvolution.

## Close enough to count as arrived, in pixels.
const ARRIVE_DISTANCE: float = 8.0
## Safety net: a shot never lives longer than this.
const MAX_LIFETIME: float = 5.0
## How far past the tower's range a shot still follows its target (the target keeps walking while
## the shot is in the air).
const RANGE_SLACK: float = 32.0
## A shell's arc: how high above its ground path it is at mid-flight (display only).
const SHELL_ARC_HEIGHT: float = 34.0
const SHADOW_COLOR: Color = Color(0, 0, 0, 0.34)
const LANDING_MARKER_SCENE: PackedScene = preload("res://entities/towers/landing_marker.tscn")
const EXPLOSION_SCENE: PackedScene = preload("res://entities/towers/explosion.tscn")
const FROST_BURST_SCENE: PackedScene = preload("res://entities/effects/frost_burst.tscn")
const FROST_NOVA_SCENE: PackedScene = preload("res://entities/effects/frost_nova.tscn")
const BURN_ZONE_SCENE: PackedScene = preload("res://entities/towers/burn_zone.tscn")
## Piercing shots: how far past their first target they fly on, and how close an enemy must be to the
## shot's path to be hit.
const PIERCE_REACH: float = 160.0
const PIERCE_HIT_RADIUS: float = 10.0
## Looks drawn in 8 directions ("arrow_0".."arrow_7"), never rotated.
const DIRECTIONAL_LOOKS: Array[StringName] = [&"arrow", &"bolt", &"sniper_shot", &"harpoon"]

var data: TowerData
## The firing tower's stats at its level (damage, blast, slow, look).
var stats: TowerTier
var target: Enemy
## The firing tower's evolution (null = none) and whether this shot is one of its freezing ones.
var evolution: TowerEvolution
var freezes: bool = false

var _destination: Vector2
var _life: float = 0.0
## The tower's base and how far from it the shot may follow its target.
var _anchor: Vector2
var _reach: float = INF
var _lost: bool = false
## Ground-targeted shell: the muzzle's height above the ground path and the flight length.
var _shell: bool = false
var _muzzle: Vector2 = Vector2.ZERO
var _flight: float = 1.0
var _marker: Node2D
## Line flight (a piercing shot after its target, or a bolt): straight on, hitting each enemy once.
var _line: bool = false
var _line_dir: Vector2 = Vector2.RIGHT
var _line_left: float = 0.0
var _pierce_left: int = 0
var _pierced: Array[Enemy] = []
var _last_dir: Vector2 = Vector2.RIGHT

@onready var _sprite: AnimatedSprite2D = %Sprite
@onready var _hitbox: Hitbox = %Hitbox


## Call before adding it to the tree. Shots are top-level, so they fly free of the tower.
## `anchor` is the tower's base: the shot never chases beyond its range (from `level_stats`).
func launch(tower_data: TowerData, level_stats: TowerTier, enemy: Enemy, from: Vector2, anchor: Vector2) -> void:
	data = tower_data
	stats = level_stats
	target = enemy
	top_level = true
	position = from
	_destination = enemy.global_position
	_anchor = anchor
	_reach = level_stats.attack_range + RANGE_SLACK


## A shell (see the class doc): call before adding it to the tree. It lands on `point` and explodes.
func launch_at_point(tower_data: TowerData, level_stats: TowerTier, point: Vector2, base: Vector2, muzzle_offset: Vector2) -> void:
	data = tower_data
	stats = level_stats
	target = null
	top_level = true
	position = base
	_destination = point
	_shell = true
	_muzzle = muzzle_offset
	_flight = maxf(base.distance_to(point), 1.0)


## A bolt (TowerData.line_shot): from the tower's base straight along the ground through `aim` to the
## range (+ RANGE_SLACK), hitting up to 1 + pierce enemies; the sprite flies at the muzzle's height.
func launch_line(tower_data: TowerData, level_stats: TowerTier, aim: Vector2, base: Vector2, muzzle_offset: Vector2) -> void:
	data = tower_data
	stats = level_stats
	top_level = true
	position = base
	_anchor = base
	_destination = aim
	_muzzle = Vector2(0, muzzle_offset.y)
	_start_line(aim - base, level_stats.attack_range + RANGE_SLACK, level_stats.pierce + 1, [])


## Where the shot will end (a shell's landing point; a homing shot's current aim).
func get_destination() -> Vector2:
	return _destination


func is_shell() -> bool:
	return _shell


func _ready() -> void:
	if data == null:
		queue_free()  # opened on its own, never launched: nothing to fly at
		set_physics_process(false)
		return
	_hitbox.damage = stats.damage
	_update_look(_destination - position)
	if _line:
		_sprite.position = _muzzle  # a bolt flies level, at the height it was loosed from
	if _shell:
		_marker = LANDING_MARKER_SCENE.instantiate()
		_marker.top_level = true
		_marker.position = _destination
		(_marker as LandingMarker).setup(stats.splash_radius if stats.splash_radius > 0.0 else stats.burn_radius)
		add_child(_marker)
		_update_arc()


func _physics_process(delta: float) -> void:
	_life += delta
	if _life > MAX_LIFETIME:
		queue_free()
		return
	if _line:
		_fly_line(stats.shot_speed(data.projectile_speed) * delta)
		return
	if not _lost and _target_alive():
		if target.global_position.distance_to(_anchor) <= _reach:
			_destination = target.global_position
		else:
			_lost = true  # out of reach: fly on to the last aim point and fizzle there
	var to_destination: Vector2 = _destination - global_position
	var step: float = stats.shot_speed(data.projectile_speed) * delta
	if to_destination.length() <= maxf(step, ARRIVE_DISTANCE):
		global_position = _destination
		_impact()
		return
	_last_dir = to_destination.normalized()
	global_position += _last_dir * step
	_update_look(to_destination)
	if _shell:
		_update_arc()


func _target_alive() -> bool:
	return is_instance_valid(target) and target.is_alive()


## True once the target ran out of the tower's reach (the shot no longer follows it).
func is_lost() -> bool:
	return _lost


## The shell's sprite: from the muzzle down to the ground point, lifted by a parabola (display only).
func _update_arc() -> void:
	var t: float = clampf(1.0 - global_position.distance_to(_destination) / _flight, 0.0, 1.0)
	_sprite.position = (_muzzle * (1.0 - t) + Vector2(0, -SHELL_ARC_HEIGHT * 4.0 * t * (1.0 - t))).round()


## A shell's shadow on the ground, under its sprite.
func _draw() -> void:
	if _shell and _sprite.visible:
		draw_rect(Rect2(-6, -2, 12, 4), SHADOW_COLOR)  # a small oval: no overlapping (darker) pixels
		draw_rect(Rect2(-4, -4, 8, 2), SHADOW_COLOR)
		draw_rect(Rect2(-4, 2, 8, 2), SHADOW_COLOR)


func _impact() -> void:
	if _marker != null:
		_marker.hide()
	if _shell or stats.splash_radius > 0.0:
		_leave_burn()
	if stats.splash_radius > 0.0:
		var explosion: Explosion = EXPLOSION_SCENE.instantiate()
		explosion.setup(stats.damage, stats.splash_radius, stats.large_blast)
		_finish_with(explosion)
		return
	if _shell:
		queue_free()  # a fire glob: the burning ground it left does the work
		return
	if _target_alive() and not _lost:
		_hitbox.damage = roundi(stats.damage * (1.0 + target.get_status().get_mark_bonus()))
		if not target.receive_shot(_hitbox, _last_dir):
			queue_free()  # stopped by a shield (or already gone): no chill, no pierce
			return
		if stats.slow_factor < 1.0:
			_chill(target)
			Sfx.play(self, &"frost_impact")
			if stats.slow_area > 0.0:
				_slow_area()
				_finish_with(FROST_NOVA_SCENE.instantiate())
			else:
				_finish_with(FROST_BURST_SCENE.instantiate())
			return
		if stats.pierce > 0:
			# On along the ground line from the tower through its target (not the arrow's tilted path
			# from the raised muzzle), so it finds the enemies walking behind.
			_start_line(target.global_position - _anchor, PIERCE_REACH, stats.pierce, [target])
			return
	# An arrow that hit, or a shot whose target is already gone, just disappears.
	queue_free()


## Flies straight on along `direction` for `reach` px, hitting up to `count` enemies (not `already`).
func _start_line(direction: Vector2, reach: float, count: int, already: Array[Enemy]) -> void:
	_line = true
	_line_dir = direction.normalized()
	_line_left = reach
	_pierce_left = count
	_pierced = already
	if is_node_ready():
		_update_look(_line_dir)  # before that, _ready() sets the look


func _fly_line(step: float) -> void:
	global_position += _line_dir * step
	_line_left -= step
	for enemy: Enemy in EnemyQuery.in_circle(get_world_2d(), global_position, PIERCE_HIT_RADIUS):
		if _pierce_left <= 0:
			break
		if _pierced.has(enemy):
			continue
		_pierced.append(enemy)
		_hitbox.damage = roundi(stats.damage * (1.0 + enemy.get_status().get_mark_bonus()))
		if not enemy.receive_shot(_hitbox, _line_dir):
			queue_free()  # a shield stops a piercing shot dead
			return
		if _pierced.size() == 1 and evolution != null and evolution.drag_distance > 0.0:
			enemy.drag_back(evolution.drag_distance * (evolution.boss_drag_factor if enemy.data.is_boss else 1.0))
		_pierce_left -= 1
	if _pierce_left <= 0 or _line_left <= 0.0:
		queue_free()


## Burning ground where a shell lands (hellfire upgrade, the brazier). It outlives the shot, so it
## goes next to it (on the tower), not under it.
func _leave_burn() -> void:
	if stats.burn_dps <= 0.0:
		return
	var zone: BurnZone = BURN_ZONE_SCENE.instantiate()
	zone.setup(stats.burn_dps, stats.burn_radius, stats.burn_duration)
	if evolution != null and evolution.death_burst_damage > 0:
		zone.set_death_burst(evolution.death_burst_damage, evolution.death_burst_radius)
	zone.top_level = true
	zone.position = global_position
	get_parent().add_child(zone)


## Frost nova: every living enemy whose body is within slow_area of the impact is slowed too.
func _slow_area() -> void:
	for enemy: Enemy in EnemyQuery.in_circle(get_world_2d(), global_position, stats.slow_area):
		_chill(enemy)


## Slows the enemy; a freezing shot freezes it instead (a boss only gets the slow).
func _chill(enemy: Enemy) -> void:
	enemy.apply_slow(stats.slow_factor, stats.slow_duration)
	if freezes and not enemy.data.is_boss:
		enemy.get_status().freeze(evolution.freeze_time)


## Stops here and shows an impact effect; the shot removes itself once the effect is done.
func _finish_with(effect: Node2D) -> void:
	set_physics_process(false)
	_sprite.hide()
	queue_redraw()
	effect.tree_exiting.connect(queue_free)
	add_child(effect)


## Arrows and bolts point where they fly (8 pre-drawn directions, never rotated); other shots just play.
func _update_look(direction: Vector2) -> void:
	var look: StringName = stats.projectile_look if stats.projectile_look != &"" else data.projectile_look
	if look in DIRECTIONAL_LOOKS:
		if not direction.is_zero_approx():
			_sprite.play(StringName("%s_%d" % [look, posmod(roundi(direction.angle() / (PI / 4.0)), 8)]))
	elif _sprite.animation != look:
		_sprite.play(look)
