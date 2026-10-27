class_name VectorKnight
extends Node2D
## The Knight in the vector test style (branch vector-test, never merge): steel plate, a red tabard and plume,
## a round warm shield, a sword whose swing leaves a gold arc. Drawn every frame from the real hero's hidden
## DirectionalSprite (state, facing, progress) and its attack pivot (the aim), so it never drives gameplay.

const WALK_BOB: float = 1.6
const SWING_SPREAD: float = 1.25
const SWING_RADIUS: float = 30.0

var sprite: AnimatedSprite2D
var pivot: Node2D
var _time: float = 0.0
var _glow: Node2D
var _swing: float = 0.0  # 0..1 into the current swing, -1 when not swinging
var _aim: float = 0.0


func _ready() -> void:
	_glow = VectorStyle.make_glow_layer(self, _draw_glow)


func _process(delta: float) -> void:
	_time += delta
	var s: Dictionary = VectorStyle.sprite_state(sprite)
	_swing = float(s.progress) if s.state == "attack" and bool(s.playing) else -1.0
	if pivot != null:
		_aim = pivot.rotation
	modulate = sprite.modulate  # the respawn blink
	queue_redraw()
	_glow.queue_redraw()


func _draw() -> void:
	var s: Dictionary = VectorStyle.sprite_state(sprite)
	var state: String = s.state
	VectorStyle.shadow(self, Vector2(0, 2), 13, 5)
	draw_arc(Vector2(0, 1), 15.0, 0.0, TAU, 32, Color(VectorStyle.GOLD, 0.45), 1.5, true)
	var bob: float = sin(_time * 18.0) * WALK_BOB if state == "walk" else sin(_time * 3.0) * 0.6
	var lean: float = 0.0
	if state == "death":
		var p: float = clampf(float(s.progress), 0.0, 1.0)
		draw_set_transform(Vector2(0, -2 + p * 6), p * 1.3 * (-1.0 if s.flip else 1.0), Vector2(1, 1 - p * 0.35))
	elif state == "dash":
		lean = 0.25
		draw_set_transform(Vector2(0, bob), lean * (-1.0 if s.flip else 1.0), Vector2.ONE)
	else:
		draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE)
	match String(s.facing):
		"up":
			_draw_back(state)
		"side":
			if s.flip:
				draw_set_transform(Vector2(0, bob), -lean, Vector2(-1, 1))
			_draw_side(state)
		_:
			_draw_front(state)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _legs(spread: float, state: String) -> void:
	var step: float = sin(_time * 18.0) * 2.5 if state == "walk" else 0.0
	for side: float in [-1.0, 1.0]:
		var x: float = side * spread
		var lift: float = step * side
		VectorStyle.shape(self, PackedVector2Array([Vector2(x - 3.5, -13), Vector2(x + 3.5, -13), Vector2(x + 3.2, -1 - lift), Vector2(x - 3.2, -1 - lift)]),
			VectorStyle.STEEL, VectorStyle.STEEL_DARK)
		VectorStyle.shape(self, VectorStyle.ellipse(Vector2(x, -1 - lift), 4.2, 2.2, 12), VectorStyle.STEEL_DARK, VectorStyle.INK)


func _helm(at: Vector2, facing: String) -> void:
	# The plume first, so the helm sits over its root.
	var plume: PackedVector2Array
	if facing == "side":
		plume = PackedVector2Array([at + Vector2(0, -7), at + Vector2(3, -9), at + Vector2(0, -14), at + Vector2(-8, -12), at + Vector2(-13, -5), at + Vector2(-6, -5)])
	else:
		var trail: float = 6.0 if facing == "up" else 0.0
		plume = PackedVector2Array([at + Vector2(-2, -6), at + Vector2(2, -6), at + Vector2(3, -12), at + Vector2(0, -15 + trail * 0.3), at + Vector2(-3, -12)])
	VectorStyle.shape(self, plume, VectorStyle.TABARD, VectorStyle.TABARD_DARK)
	VectorStyle.shape(self, VectorStyle.ellipse(at, 7.5, 8.0, 24), VectorStyle.STEEL_LIGHT, VectorStyle.STEEL_DARK)
	if facing == "down":
		draw_line(at + Vector2(-5, 0.5), at + Vector2(5, 0.5), VectorStyle.INK, 2.0, true)
		draw_line(at + Vector2(0, -3), at + Vector2(0, 5), VectorStyle.INK, 1.6, true)
	elif facing == "side":
		draw_line(at + Vector2(1.5, 0.5), at + Vector2(7, 0.5), VectorStyle.INK, 2.0, true)
	VectorStyle.shine(self, at + Vector2(-2.5, -3.5), 2.6, 1.6, 0.45)


func _torso(width: float, with_tabard: bool) -> void:
	var w: float = width
	VectorStyle.shape(self, PackedVector2Array([Vector2(-w, -30), Vector2(w, -30), Vector2(w - 1.5, -12), Vector2(1, -10), Vector2(-1, -10), Vector2(-w + 1.5, -12)]),
		VectorStyle.STEEL_LIGHT, VectorStyle.STEEL_DARK)
	if with_tabard:
		VectorStyle.shape(self, PackedVector2Array([Vector2(-4.5, -27), Vector2(4.5, -27), Vector2(5.5, -8), Vector2(0, -6), Vector2(-5.5, -8)]),
			VectorStyle.TABARD, VectorStyle.TABARD_DARK, VectorStyle.TABARD_DARK, 1.0)
		draw_line(Vector2(0, -25), Vector2(0, -9), Color(VectorStyle.GOLD, 0.8), 1.2, true)
	VectorStyle.shape(self, PackedVector2Array([Vector2(-w + 1, -14), Vector2(w - 1, -14), Vector2(w - 1, -11.5), Vector2(-w + 1, -11.5)]),
		VectorStyle.WOOD, VectorStyle.WOOD_DARK, VectorStyle.INK, 1.0)
	for side: float in [-1.0, 1.0]:
		VectorStyle.shape(self, VectorStyle.ellipse(Vector2(side * (w - 0.5), -28), 4.6, 3.6, 16), VectorStyle.STEEL_LIGHT, VectorStyle.STEEL_DARK)


func _shield(at: Vector2, scale_x: float) -> void:
	var rim: PackedVector2Array = VectorStyle.ellipse(at, 7.5 * scale_x, 8.5, 24)
	VectorStyle.shape(self, rim, VectorStyle.GOLD, VectorStyle.GOLD_DARK)
	VectorStyle.shape(self, VectorStyle.ellipse(at, 5.8 * scale_x, 6.8, 24), VectorStyle.TABARD, VectorStyle.TABARD_DARK, Color(0, 0, 0, 0))
	VectorStyle.shape(self, VectorStyle.ellipse(at, 1.8 * scale_x, 1.8, 10), VectorStyle.STEEL_LIGHT, VectorStyle.STEEL_DARK, VectorStyle.INK, 1.0)
	VectorStyle.shine(self, at + Vector2(-2.5 * scale_x, -3.5), 2.2 * scale_x, 1.4, 0.3)


## The sword from `hand`, pointing at `angle` (radians, 0 = right).
func _sword(hand: Vector2, angle: float, length: float = 22.0) -> void:
	var dir: Vector2 = Vector2.from_angle(angle)
	var side: Vector2 = dir.orthogonal()
	var tip: Vector2 = hand + dir * length
	VectorStyle.shape(self, PackedVector2Array([hand + side * 1.8 + dir * 3, tip - dir * 3 + side * 1.4, tip, tip - dir * 3 - side * 1.4, hand - side * 1.8 + dir * 3]),
		VectorStyle.STEEL_LIGHT, VectorStyle.STEEL, VectorStyle.INK, 1.0)
	draw_line(hand + side * 4.5 + dir * 3, hand - side * 4.5 + dir * 3, VectorStyle.GOLD, 2.4, true)
	draw_line(hand - dir * 3, hand + dir * 2, VectorStyle.WOOD_DARK, 2.6, true)


func _swing_angle() -> float:
	return _aim - SWING_SPREAD + 2.0 * SWING_SPREAD * VectorStyle.ease_out_back(clampf(_swing, 0.0, 1.0)) if _swing >= 0.0 else 0.0


func _draw_front(state: String) -> void:
	VectorStyle.shape(self, PackedVector2Array([Vector2(-11, -29), Vector2(11, -29), Vector2(13, -8), Vector2(-13, -8)]), VectorStyle.TABARD, VectorStyle.TABARD_DARK)
	_legs(4.0, state)
	_torso(10.0, true)
	_helm(Vector2(0, -38), "down")
	_shield(Vector2(-11, -19), 0.8)
	var hand: Vector2 = Vector2(11, -18)
	_sword(hand, _swing_angle() if _swing >= 0.0 else -1.35)


func _draw_back(state: String) -> void:
	var hand: Vector2 = Vector2(-11, -18)
	if _swing >= 0.0:
		_sword(hand, _swing_angle())
	_legs(4.0, state)
	_torso(10.0, false)
	VectorStyle.shape(self, PackedVector2Array([Vector2(-10, -30), Vector2(10, -30), Vector2(13, -5), Vector2(0, -3), Vector2(-13, -5)]), VectorStyle.TABARD, VectorStyle.TABARD_DARK)
	_shield(Vector2(9, -19), 0.75)
	_helm(Vector2(0, -38), "up")
	if _swing < 0.0:
		_sword(hand, -1.8)


func _draw_side(state: String) -> void:
	var swinging: bool = _swing >= 0.0
	VectorStyle.shape(self, PackedVector2Array([Vector2(-8, -29), Vector2(-2, -29), Vector2(-4, -6), Vector2(-12, -7)]), VectorStyle.TABARD, VectorStyle.TABARD_DARK)
	if not swinging:
		_sword(Vector2(-3, -19), -2.0)
	_legs(2.0, state)
	_torso(7.0, true)
	_helm(Vector2(1, -38), "side")
	_shield(Vector2(7, -19), 0.55)
	if swinging:
		# The aim is in world space; mirrored art mirrors it back.
		var aim_local: float = PI - _swing_angle() if sprite.flip_h else _swing_angle()
		_sword(Vector2(2, -20), aim_local)


func _draw_glow(layer: Node2D) -> void:
	var s: Dictionary = VectorStyle.sprite_state(sprite)
	VectorStyle.draw_glow(layer, VectorStyle.WARM_GLOW, Vector2(0, -20), 30.0, 0.16)
	if _swing >= 0.0:
		var center: Vector2 = Vector2(0, -18)
		var from_angle: float = _aim - SWING_SPREAD
		var to_angle: float = _swing_angle()
		var fade: float = 1.0 - clampf(_swing, 0.0, 1.0) * 0.6
		layer.draw_arc(center, SWING_RADIUS, from_angle, to_angle, 24, Color(VectorStyle.WARM_GLOW, 0.35 * fade), 9.0, true)
		layer.draw_arc(center, SWING_RADIUS, from_angle, to_angle, 24, Color(1.0, 0.95, 0.8, 0.8 * fade), 2.5, true)
		VectorStyle.draw_glow(layer, VectorStyle.GOLD, center + Vector2.from_angle(to_angle) * SWING_RADIUS, 10.0, 0.9 * fade)
	if s.state == "dash":
		for i: int in 3:
			var back: float = -1.0 if not s.flip else 1.0
			layer.draw_line(Vector2(back * (8 + i * 6), -26 + i * 8), Vector2(back * (22 + i * 8), -26 + i * 8), Color(VectorStyle.WARM_GLOW, 0.35), 2.0, true)
