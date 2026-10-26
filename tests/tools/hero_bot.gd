extends RefCounted
## A simple hero player for the balance tool (not shipped): each physics frame it walks toward the
## nearest enemy on the busiest lane (the lane with the most living enemies), swings at whatever is
## in reach, and at low HP dashes away from the nearest enemy and falls back to the fortress (it is
## healed when the wave ends). Between waves it waits in front of the fortress. It presses the real move actions, so the hero moves exactly as for a player.

const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]
## Swing when the target is this close (a bit inside the 68 px reach).
const SWING_RANGE: float = 56.0
## Stop walking this close to the target.
const CLOSE_ENOUGH: float = 40.0
## Dash away when HP drops below this share and an enemy is this close.
const LOW_HEALTH: float = 0.35
const DANGER_RANGE: float = 70.0
## A ranged hero (the Huntress, the Necromancer: her kills raise skeletons) keeps this far from the nearest enemy: backs off inside the first, walks
## up outside the second, and shoots whatever is furthest along its lane within bolt range.
const KITE_MIN: float = 150.0
const KITE_MAX: float = 260.0
## Shoot only this far inside the bolt's range.
const BOLT_MARGIN: float = 20.0
## It spends its ultimate when this many enemies are within its reach.
const ULT_CROWD: int = 5
## Where it waits between waves.
const HOME: Vector2 = Vector2(-90, 80)

var _hero: Hero
var _spawner: WaveSpawner
var _reach: float = 1.0


func _init(hero: Hero, spawner: WaveSpawner) -> void:
	_hero = hero
	_spawner = spawner


func step(modifiers: RunModifiers) -> void:
	_reach = RunModifiers.value(modifiers, 1.0, [RunModifiers.HERO_REACH])
	if _hero.health.is_dead():
		_steer(Vector2.ZERO)
		return
	var enemies: Array[Enemy] = _living()
	if enemies.is_empty():
		_walk_to(HOME, 8.0)
		return
	_use_ultimate(enemies)
	if _hero.data != null and _hero.data.attack_kind == HeroData.AttackKind.BOLT:
		_step_ranged(enemies)
		return
	var nearest: Enemy = _nearest(enemies)
	var hp: float = float(_hero.health.current_health) / _hero.health.max_health
	if hp < LOW_HEALTH:
		if nearest.global_position.distance_to(_hero.global_position) < DANGER_RANGE:
			_hero.dash(_hero.global_position - nearest.global_position)
		_walk_to(HOME, 8.0)
		if nearest.global_position.distance_to(_hero.global_position) <= SWING_RANGE * _reach:
			_hero.attack(nearest.global_position)
		return
	var target: Enemy = _nearest(_busiest_lane(enemies))
	_walk_to(target.global_position, CLOSE_ENOUGH)
	# Swing at anything in reach (the target, or something in the way).
	if nearest.global_position.distance_to(_hero.global_position) <= SWING_RANGE * _reach:
		_hero.attack(nearest.global_position)


## Spends a full ultimate when a crowd is close (UltimateData.radius for a ring, the volley's line toward the leader, a boss
## being close to the hero too), aiming the Volley at the enemy furthest along its lane.
func _use_ultimate(enemies: Array[Enemy]) -> void:
	var ult: HeroUltimate = _hero.get_ultimate()
	if not ult.is_ready():
		return
	var data: UltimateData = ult.get_data()
	var reach: float = data.line_length if data.kind == UltimateData.Kind.VOLLEY else data.radius
	var close: int = enemies.filter(func(e: Enemy) -> bool: return e.global_position.distance_to(_hero.global_position) <= reach).size()
	if close < ULT_CROWD:
		return
	var runner: UltimateRunner = _hero.get_parent().get_node_or_null("UltimateRunner") as UltimateRunner
	if runner != null:
		runner.aim_override = (_leader(enemies).global_position - _hero.global_position).normalized()
	ult.use()


## The ranged policy: kite at KITE_MIN to KITE_MAX from the nearest enemy, loose bolts at the leader.
func _step_ranged(enemies: Array[Enemy]) -> void:
	var nearest: Enemy = _nearest(enemies)
	var distance: float = nearest.global_position.distance_to(_hero.global_position)
	var hp: float = float(_hero.health.current_health) / _hero.health.max_health
	if hp < LOW_HEALTH and distance < DANGER_RANGE:
		_hero.dash(_hero.global_position - nearest.global_position)
	if distance < KITE_MIN or hp < LOW_HEALTH:
		_steer((_hero.global_position - nearest.global_position).normalized() if hp >= LOW_HEALTH
			else (HOME - _hero.global_position).normalized())
	else:
		_walk_to(_leader(enemies).global_position, KITE_MAX)
	var reach: float = _hero.data.bolt_range * _reach - BOLT_MARGIN
	var aim: Enemy = _leader(enemies)
	if aim.global_position.distance_to(_hero.global_position) > reach:
		aim = nearest
	if aim.global_position.distance_to(_hero.global_position) <= reach:
		_hero.attack(aim.global_position)


## The enemy furthest along its lane.
func _leader(enemies: Array[Enemy]) -> Enemy:
	var best: Enemy = enemies[0]
	for enemy: Enemy in enemies:
		if enemy.get_lane_progress() > best.get_lane_progress():
			best = enemy
	return best


## Lets go of every key (call when the run ends).
func release() -> void:
	_steer(Vector2.ZERO)


func _living() -> Array[Enemy]:
	var found: Array[Enemy] = []
	for child: Node in _spawner.get_children():
		var enemy: Enemy = child as Enemy
		if enemy != null and enemy.is_alive():
			found.append(enemy)
	return found


func _busiest_lane(enemies: Array[Enemy]) -> Array[Enemy]:
	var counts: Dictionary = {}
	for enemy: Enemy in enemies:
		counts[enemy.lane] = int(counts.get(enemy.lane, 0)) + 1
	var busiest: Variant = enemies[0].lane
	for lane: Variant in counts:
		if int(counts[lane]) > int(counts[busiest]):
			busiest = lane
	return enemies.filter(func(e: Enemy) -> bool: return e.lane == busiest)


func _nearest(enemies: Array[Enemy]) -> Enemy:
	var best: Enemy = enemies[0]
	for enemy: Enemy in enemies:
		if enemy.global_position.distance_squared_to(_hero.global_position) < best.global_position.distance_squared_to(_hero.global_position):
			best = enemy
	return best


func _walk_to(point: Vector2, stop_at: float) -> void:
	var to: Vector2 = point - _hero.global_position
	_steer(to.normalized() if to.length() > stop_at else Vector2.ZERO)


## Holds the move actions with the strengths of `direction` (what Input.get_vector() reads back).
func _steer(direction: Vector2) -> void:
	var strengths: Array[float] = [maxf(-direction.x, 0.0), maxf(direction.x, 0.0), maxf(-direction.y, 0.0), maxf(direction.y, 0.0)]
	for i: int in MOVE_ACTIONS.size():
		if strengths[i] > 0.01:
			Input.action_press(MOVE_ACTIONS[i], strengths[i])
		else:
			Input.action_release(MOVE_ACTIONS[i])
