class_name VectorKnight
extends Node2D
## The Knight in the vector test style (branch vector-test, never merge), detailed (KnightPainter). The body is
## baked per pose (facing, walk or idle, 12 / 8 phases) by the shared VectorPoseCache; the sword arm and the swing's
## gold arc are painted live from the real aim. Bob, the dash lean and the death fall are transforms of the baked
## body. All of it reads the real hero's hidden DirectionalSprite and attack pivot.

const WALK_HZ: float = 1.5
const IDLE_HZ: float = 0.45
const WALK_PHASES: int = 12
const IDLE_PHASES: int = 8
const SWING_SPREAD: float = 1.25
const SWING_RADIUS: float = 32.0
const SHOULDER: Vector2 = Vector2(10, -27)
const REST_ANGLE: float = -1.25

var sprite: AnimatedSprite2D
var pivot: Node2D
var cache: VectorPoseCache
var _time: float = 0.0
var _swing: float = -1.0
var _aim: float = 0.0
var _pose: Dictionary = {}
var _texture: Texture2D
var _behind: Node2D
var _body: Node2D
var _front: Node2D
var _glow: Node2D


func _ready() -> void:
	_behind = _layer("Behind", _draw_arm_behind)
	_body = _layer("Body", _draw_body)
	_body.material = VectorPoseCache.premult_material()
	_front = _layer("Front", _draw_arm_front)
	_glow = VectorStyle.make_glow_layer(self, _draw_glow)


func _layer(layer_name: String, painter: Callable) -> Node2D:
	var layer: Node2D = Node2D.new()
	layer.name = layer_name
	layer.draw.connect(painter)
	add_child(layer)
	return layer


func _process(delta: float) -> void:
	_time += delta
	var s: Dictionary = VectorStyle.sprite_state(sprite)
	_swing = float(s.progress) if s.state == "attack" and bool(s.playing) else -1.0
	if pivot != null:
		_aim = pivot.rotation
	var walking: bool = s.state == "walk" or s.state == "dash"
	var phases: int = WALK_PHASES if walking else IDLE_PHASES
	var cycle: float = fmod(_time * (WALK_HZ if walking else IDLE_HZ), 1.0)
	var index: int = int(cycle * phases)
	_pose = {"facing": s.facing, "walk": walking, "phase": float(index) / phases}
	var key: String = "knight_%s_%s_%d" % [s.facing, "w" if walking else "i", index]
	_texture = cache.get_pose(key, KnightPainter.BOX, func(ci: CanvasItem) -> void: KnightPainter.paint(ci, _pose_for(s.facing, walking, float(index) / phases))) if cache != null else null
	_place(s)
	modulate = sprite.modulate  # the respawn blink
	for item: CanvasItem in [self, _behind, _body, _front, _glow]:
		item.queue_redraw()


func _pose_for(facing: String, walking: bool, phase: float) -> Dictionary:
	return {"facing": facing, "walk": walking, "phase": phase}


## Bob, lean, fall and the side mirror, as transforms of the layers.
func _place(s: Dictionary) -> void:
	var mirror: float = -1.0 if s.flip and s.facing == "side" else 1.0
	var bob: float = 0.0
	var tilt: float = 0.0
	var squash: float = 1.0
	if s.state == "death":
		var p: float = clampf(float(s.progress), 0.0, 1.0)
		tilt = p * 1.35 * (-1.0 if s.flip else 1.0)
		bob = p * 5.0
		squash = 1.0 - p * 0.3
	elif s.state == "dash":
		tilt = 0.28 * (-1.0 if s.flip else 1.0)
	elif s.state == "walk":
		bob = -absf(sin(_time * WALK_HZ * TAU)) * 1.6
	_body.position = Vector2(0, bob)
	_body.rotation = tilt
	_body.scale = Vector2(mirror, squash)
	for arm: Node2D in [_behind, _front]:
		arm.position = Vector2(0, bob)
		arm.rotation = tilt
		arm.visible = s.state != "death"


func _draw() -> void:
	VectorStyle.shadow(self, Vector2(0, 2), 14, 5.5)
	draw_arc(Vector2(0, 1), 16.0, 0.0, TAU, 40, Color(VectorStyle.GOLD, 0.35), 1.2, true)
	if _texture == null and not _pose.is_empty():
		# Not baked yet: paint it live this frame.
		draw_set_transform(_body.position, _body.rotation, _body.scale)
		KnightPainter.paint(self, _pose)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_body() -> void:
	if _texture != null:
		VectorPoseCache.draw_pose(_body, _texture, KnightPainter.BOX)


func _arm_angle() -> float:
	if _swing < 0.0:
		return REST_ANGLE if not sprite.flip_h else PI - REST_ANGLE
	return _aim - SWING_SPREAD + 2.0 * SWING_SPREAD * VectorStyle.ease_out_back(clampf(_swing, 0.0, 1.0))


func _shoulder() -> Vector2:
	var s: Dictionary = VectorStyle.sprite_state(sprite)
	match String(s.facing):
		"up":
			return Vector2(-SHOULDER.x, SHOULDER.y)
		"side":
			return Vector2(2.0 * (-1.0 if s.flip else 1.0), SHOULDER.y)
	return SHOULDER


func _draw_arm_behind() -> void:
	if String(VectorStyle.sprite_state(sprite).facing) == "up":
		KnightPainter.paint_sword_arm(_behind, _shoulder(), _arm_angle())


func _draw_arm_front() -> void:
	if String(VectorStyle.sprite_state(sprite).facing) != "up":
		KnightPainter.paint_sword_arm(_front, _shoulder(), _arm_angle())


func _draw_glow(layer: Node2D) -> void:
	var s: Dictionary = VectorStyle.sprite_state(sprite)
	VectorStyle.draw_glow(layer, VectorStyle.WARM_GLOW, Vector2(0, -22), 34.0, 0.14)
	if _swing >= 0.0:
		var center: Vector2 = _shoulder() + Vector2(0, 6)
		var from_angle: float = _aim - SWING_SPREAD
		var to_angle: float = _arm_angle()
		var fade: float = 1.0 - clampf(_swing, 0.0, 1.0) * 0.6
		layer.draw_arc(center, SWING_RADIUS, from_angle, to_angle, 28, Color(VectorStyle.WARM_GLOW, 0.3 * fade), 11.0, true)
		layer.draw_arc(center, SWING_RADIUS, from_angle, to_angle, 28, Color(1.0, 0.9, 0.65, 0.55 * fade), 4.0, true)
		layer.draw_arc(center, SWING_RADIUS, from_angle, to_angle, 28, Color(1, 1, 1, 0.9 * fade), 1.4, true)
		var tip: Vector2 = center + Vector2.from_angle(to_angle) * SWING_RADIUS
		VectorStyle.draw_glow(layer, VectorStyle.GOLD, tip, 12.0, 0.9 * fade)
		# Sparks thrown off the edge of the swing.
		for i: int in 5:
			var a: float = lerpf(from_angle, to_angle, 0.55 + i * 0.09)
			var r: float = SWING_RADIUS + 3.0 + fmod(i * 7.3 + _swing * 40.0, 9.0)
			VectorStyle.draw_glow(layer, VectorStyle.WARM_GLOW, center + Vector2.from_angle(a) * r, 3.0, fade)
	# The sword's gem.
	VectorStyle.draw_glow(layer, Color("ff5a3c"), _shoulder() + Vector2.from_angle(_arm_angle()) * 12.0, 4.0, 0.7)
	if s.state == "dash":
		var back: float = -1.0 if not s.flip else 1.0
		for i: int in 4:
			layer.draw_line(Vector2(back * (8 + i * 5), -30 + i * 7), Vector2(back * (26 + i * 7), -30 + i * 7), Color(VectorStyle.WARM_GLOW, 0.32), 2.0, true)
