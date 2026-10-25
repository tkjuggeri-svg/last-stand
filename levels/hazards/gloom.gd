class_name Gloom
extends LevelHazard
## The Gloam Wood's mechanic: the wood is dark. A tower sees only a share of its range (`data.amount` less:
## 0.3 = 70% of it) unless a lamp stands near it (within `data.radius` px of one of `lamps`): towers in the
## light keep their whole range. Always on, in a wave or not, so the player sees it while building. The lamps
## are posts with a warm light, made here from the positions.

const CHECK_EVERY: float = 0.5
const LIGHT: Texture2D = preload("res://entities/effects/light_soft.tres")
const LAMP_COLOR: Color = Color(1.0, 0.82, 0.5, 1.0)

@export var lamps: PackedVector2Array = PackedVector2Array()
@export var builder: TowerBuilder

var _check_left: float = 0.0


func _ready() -> void:
	super()
	for at: Vector2 in lamps:
		_make_lamp(at)


func _physics_process(delta: float) -> void:
	_check_left -= delta
	if _check_left > 0.0 or builder == null:
		return
	_check_left = CHECK_EVERY
	for tower: Tower in builder.get_towers():
		tower.set_weather_range(0.0 if is_lit(tower.global_position) else -data.amount)


## True if a lamp lights `point`.
func is_lit(point: Vector2) -> bool:
	for at: Vector2 in lamps:
		if at.distance_to(point) <= data.radius:
			return true
	return false


func _make_lamp(at: Vector2) -> void:
	var lamp: Node2D = Node2D.new()
	lamp.position = at
	var post: Polygon2D = Polygon2D.new()
	post.polygon = PackedVector2Array([Vector2(-1, 0), Vector2(1, 0), Vector2(1, -22), Vector2(-1, -22)])
	post.color = Color(0.2, 0.15, 0.1, 1.0)
	lamp.add_child(post)
	var top: Polygon2D = Polygon2D.new()
	top.polygon = PackedVector2Array([Vector2(-3, -22), Vector2(3, -22), Vector2(3, -28), Vector2(-3, -28)])
	top.color = LAMP_COLOR
	lamp.add_child(top)
	var glow: PointLight2D = PointLight2D.new()
	glow.texture = LIGHT
	glow.color = LAMP_COLOR
	glow.energy = 0.9
	glow.texture_scale = data.radius / 40.0
	glow.position = Vector2(0, -24)
	lamp.add_child(glow)
	_effects_root().add_child.call_deferred(lamp)
