class_name Consecration
extends LevelHazard
## The Pale Cathedral's mechanic: altars (`altars`) mend the dead that stand within `data.radius` of them,
## `data.amount` HP a second, while a wave is on, unless the altar is covered by fire: burning ground (a
## Brazier's shells, a Cinder Dash) within reach of it puts its light out. A blast or the hero's
## sword does not stop it; fire does, which is the Brazier's job. The altars are glowing slabs made here.

const TICK: float = 0.5
const LIGHT: Texture2D = preload("res://entities/effects/light_soft.tres")
const ALTAR_COLOR: Color = Color(0.85, 0.8, 1.0, 1.0)

@export var altars: PackedVector2Array = PackedVector2Array()

var _tick_left: float = 0.0
var _lights: Array[PointLight2D] = []


func _ready() -> void:
	super()
	for at: Vector2 in altars:
		_make_altar(at)


func _physics_process(delta: float) -> void:
	if not is_active():
		return
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left = TICK
	for i: int in altars.size():
		var lit: bool = not is_covered(altars[i])
		_lights[i].enabled = lit
		if lit:
			for enemy: Enemy in EnemyQuery.in_circle(spawner.get_world_2d(), altars[i], data.radius):
				enemy.heal(maxi(roundi(data.amount * TICK), 1))


## True if burning ground puts altar `at` out.
func is_covered(at: Vector2) -> bool:
	for node: Node in get_tree().get_nodes_in_group(Groups.BURN_ZONES):
		var zone: BurnZone = node as BurnZone
		if zone != null and zone.global_position.distance_to(at) <= data.radius + zone.get_radius():
			return true
	return false


func _make_altar(at: Vector2) -> void:
	var altar: Node2D = Node2D.new()
	altar.position = at
	var slab: Polygon2D = Polygon2D.new()
	slab.polygon = PackedVector2Array([Vector2(-9, 0), Vector2(9, 0), Vector2(9, -8), Vector2(-9, -8)])
	slab.color = Color(0.62, 0.6, 0.7, 1.0)
	altar.add_child(slab)
	var glow: PointLight2D = PointLight2D.new()
	glow.texture = LIGHT
	glow.color = ALTAR_COLOR
	glow.energy = 0.8
	glow.texture_scale = 2.4
	glow.position = Vector2(0, -8)
	altar.add_child(glow)
	_lights.append(glow)
	_effects_root().add_child.call_deferred(altar)
