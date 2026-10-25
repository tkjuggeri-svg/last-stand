class_name DryGrass
extends LevelHazard
## The Ember Orchard's mechanic: patches of dry grass (`patches`, drawn into the ground) catch fire when
## something burns on them: a burning enemy, or burning ground (a Brazier's shell, a Cinder Dash). A burning
## patch is a FirePatch for `data.effect_time` s: it hurts the hero and minions in it and sets enemies on
## fire at `data.amount` damage per second (fire hurts friends and foes), then it is ash and cannot burn
## again. No timer strikes: the player's own fire starts it.

const CHECK_EVERY: float = 0.25
const HERO_DAMAGE_PER_PULSE: int = 5

@export var patches: PackedVector2Array = PackedVector2Array()
@export var patch_radius: float = 56.0

## Per patch: 0 dry, 1 burning, 2 ash.
var _state: Array[int] = []
var _check_left: float = 0.0


func _ready() -> void:
	super()
	_state.resize(patches.size())
	_state.fill(0)


func _physics_process(delta: float) -> void:
	if not is_active():
		return
	_check_left -= delta
	if _check_left > 0.0:
		return
	_check_left = CHECK_EVERY
	for i: int in patches.size():
		if _state[i] == 0 and _catches(patches[i]):
			ignite(i)


## 0 dry, 1 burning, 2 ash.
func get_state(index: int) -> int:
	return _state[index]


## Sets patch `index` alight (also called by tests).
func ignite(index: int) -> void:
	if _state[index] != 0:
		return
	_state[index] = 1
	var fire: FirePatch = FirePatch.new()
	fire.setup(patches[index], patch_radius, HERO_DAMAGE_PER_PULSE, data.effect_time, data.amount)
	fire.tree_exited.connect(func() -> void: _state[index] = 2)
	_effects_root().add_child(fire)


func _catches(at: Vector2) -> bool:
	for enemy: Enemy in EnemyQuery.in_circle(spawner.get_world_2d(), at, patch_radius):
		if enemy.get_status().is_burning():
			return true
	for node: Node in get_tree().get_nodes_in_group(Groups.BURN_ZONES):
		var zone: BurnZone = node as BurnZone
		if zone != null and zone.global_position.distance_to(at) <= patch_radius + zone.get_radius():
			return true
	return false
