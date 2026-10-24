class_name MinionPool
extends Node
## Raises the level's minions (M9) and counts them per raiser (the hero, each Bone Pit), so a raiser
## never has more than its cap alive. Minions are children of `parent_node` (the level's y-sorted
## Effects), health scaled by the run's cards. Rules only: the Minion fights by itself. Created by the
## Level, which wires its signals (the Soul Feast heal, the Reliquary's souls).

signal raised(minion: Minion)
signal minion_fell(minion: Minion)
signal minion_struck(minion: Minion, enemy: Enemy, killed: bool)

const MINION_SCENE: PackedScene = preload("res://entities/minions/minion.tscn")

@export var parent_node: Node
@export var modifiers: RunModifiers

## Raiser -> its living minions.
var _by_raiser: Dictionary = {}


## How many minions `raiser` has alive.
func count_for(raiser: Object) -> int:
	_prune(raiser)
	return (_by_raiser.get(raiser, []) as Array).size()


## Raises a minion of `data` at `at` for `raiser` unless it already has `cap` alive. Returns it, or null.
func raise(data: MinionData, at: Vector2, raiser: Object, cap: int, anchor: Node2D = null) -> Minion:
	if data == null or count_for(raiser) >= cap or parent_node == null:
		return null
	var minion: Minion = MINION_SCENE.instantiate()
	minion.setup(data, at, anchor, RunModifiers.value(modifiers, 1.0, [RunModifiers.MINION_HEALTH]))
	minion.fell.connect(func(m: Minion) -> void: minion_fell.emit(m))
	minion.struck.connect(func(enemy: Enemy, killed: bool) -> void: minion_struck.emit(minion, enemy, killed))
	parent_node.add_child(minion)
	if not _by_raiser.has(raiser):
		_by_raiser[raiser] = []
	(_by_raiser[raiser] as Array).append(minion)
	Sfx.play(minion, &"minion_raise")
	raised.emit(minion)
	return minion


## Every minion alive (any raiser).
func get_minions() -> Array[Minion]:
	var all: Array[Minion] = []
	for raiser: Variant in _by_raiser.keys():
		_prune(raiser)
		for minion: Variant in _by_raiser.get(raiser, []):
			all.append(minion)
	return all


## Forgets freed or fallen minions of `raiser` (a freed raiser too: a sold tower's minions stay until
## they expire, but no longer count against anything).
func _prune(raiser: Variant) -> void:
	if not is_instance_valid(raiser):
		_by_raiser.erase(raiser)
		return
	var alive: Array = []
	for minion: Variant in _by_raiser.get(raiser, []):
		if is_instance_valid(minion) and not (minion as Minion).is_fallen():
			alive.append(minion)
	_by_raiser[raiser] = alive
