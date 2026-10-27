class_name VectorGhoul
extends Node2D
## The Ghoul in the vector test style (branch vector-test, never merge): a hunched, pale, cold dead thing in a
## ragged cloak, long arms reaching, red-glowing eyes (the common dead's role colour) and a faint cold wisp.
## Drawn from the real enemy's hidden DirectionalSprite (state, facing, progress) and its hit flash.

var sprite: AnimatedSprite2D
var _time: float = 0.0
var _phase: float = 0.0
var _glow: Node2D


func _ready() -> void:
	_phase = fmod(absf(global_position.x * 0.37 + global_position.y * 0.11), TAU)
	_glow = VectorStyle.make_glow_layer(self, _draw_glow)


func _process(delta: float) -> void:
	_time += delta
	var flash: float = 0.0
	var shader: ShaderMaterial = sprite.material as ShaderMaterial
	if shader != null:
		flash = float(shader.get_shader_parameter(&"flash"))
	modulate = Color(1.0 + flash * 2.5, 1.0 + flash * 2.5, 1.0 + flash * 2.5, sprite.modulate.a)
	queue_redraw()
	_glow.queue_redraw()


func _draw() -> void:
	var s: Dictionary = VectorStyle.sprite_state(sprite)
	var state: String = s.state
	var walk: float = sin(_time * 9.0 + _phase)
	VectorStyle.shadow(self, Vector2(0, 2), 11, 4.5)
	var sink: float = 0.0
	var tilt: float = 0.0
	if state == "death":
		var p: float = clampf(float(s.progress), 0.0, 1.0)
		sink = p * 8.0
		tilt = p * 0.9
		modulate.a *= 1.0 - p * 0.7
	var bob: float = absf(walk) * -1.5 if state == "walk" else sin(_time * 2.5 + _phase) * 0.6
	var mirror: float = -1.0 if s.flip else 1.0
	draw_set_transform(Vector2(0, bob + sink), tilt * mirror, Vector2(mirror if s.facing == "side" else 1.0, 1.0))
	var lunge: float = sin(clampf(float(s.progress), 0.0, 1.0) * PI) if state == "attack" else 0.0
	match String(s.facing):
		"up":
			_draw_back(walk)
		"side":
			_draw_side(walk, lunge)
		_:
			_draw_front(walk, lunge)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _rags(top: float, width: float, hem: float, walk: float) -> PackedVector2Array:
	# A ragged hem: points zig-zag and sway a little with the walk.
	var out: PackedVector2Array = PackedVector2Array([Vector2(-width * 0.55, top), Vector2(width * 0.55, top)])
	var teeth: int = 5
	for i: int in range(teeth, -1, -1):
		var x: float = lerpf(-width, width, float(i) / teeth)
		out.append(Vector2(x + walk * 1.2, hem + (3.0 if i % 2 == 0 else -1.0)))
	return out


func _arm(shoulder: Vector2, hand: Vector2) -> void:
	draw_line(shoulder, hand, VectorStyle.INK, 4.6, true)
	draw_line(shoulder, hand, VectorStyle.SKIN_DEAD_DARK, 3.0, true)
	for k: float in [-1.0, 0.0, 1.0]:
		var dir: Vector2 = (hand - shoulder).normalized()
		var claw: Vector2 = hand + dir.rotated(k * 0.45) * 4.5
		draw_line(hand, claw, VectorStyle.SKIN_DEAD, 1.3, true)


func _head(at: Vector2, eyes: bool) -> void:
	VectorStyle.shape(self, PackedVector2Array([at + Vector2(-5.5, -2), at + Vector2(-3, -6.5), at + Vector2(3, -6.5), at + Vector2(5.5, -2),
		at + Vector2(4, 4), at + Vector2(0, 6), at + Vector2(-4, 4)]), VectorStyle.SKIN_DEAD, VectorStyle.SKIN_DEAD_DARK)
	if eyes:
		for side: float in [-1.0, 1.0]:
			draw_colored_polygon(VectorStyle.ellipse(at + Vector2(side * 2.3, -0.5), 1.6, 1.2, 10), VectorStyle.EYE_RED)
		draw_line(at + Vector2(-2, 3.2), at + Vector2(2, 3.2), VectorStyle.INK, 1.2, true)


func _draw_front(walk: float, lunge: float) -> void:
	var reach: float = 4.0 + lunge * 7.0
	_arm(Vector2(-6, -17), Vector2(-9 - walk * 1.5, -6 + reach * 0.3))
	_arm(Vector2(6, -17), Vector2(9 + walk * 1.5, -6 + reach * 0.3))
	for side: float in [-1.0, 1.0]:
		var step: float = walk * 2.0 * side
		draw_line(Vector2(side * 3, -8), Vector2(side * 4, -1 - step), VectorStyle.INK, 3.8, true)
		draw_line(Vector2(side * 3, -8), Vector2(side * 4, -1 - step), VectorStyle.SKIN_DEAD_DARK, 2.4, true)
	VectorStyle.shape(self, _rags(-20, 9.0, -6.0, walk), VectorStyle.RAG, VectorStyle.RAG_DARK)
	_head(Vector2(0, -23 + lunge * 2.0), true)


func _draw_back(walk: float) -> void:
	for side: float in [-1.0, 1.0]:
		var step: float = walk * 2.0 * side
		draw_line(Vector2(side * 3, -8), Vector2(side * 4, -1 - step), VectorStyle.SKIN_DEAD_DARK, 2.6, true)
	VectorStyle.shape(self, _rags(-21, 9.5, -5.0, walk), VectorStyle.RAG, VectorStyle.RAG_DARK)
	# The bent spine shows through the rags.
	for i: int in 4:
		draw_circle(Vector2(0, -19 + i * 3.2), 1.1, Color(VectorStyle.SKIN_DEAD_DARK, 0.9), true, -1.0, true)
	_head(Vector2(0, -24), false)
	_arm(Vector2(-7, -17), Vector2(-10, -9 + walk))
	_arm(Vector2(7, -17), Vector2(10, -9 - walk))


func _draw_side(walk: float, lunge: float) -> void:
	_arm(Vector2(-1, -17), Vector2(6 - walk * 3.0, -9))
	for side: float in [-1.0, 1.0]:
		var step: float = walk * 3.5 * side
		draw_line(Vector2(0, -8), Vector2(step, -1), VectorStyle.INK, 3.8, true)
		draw_line(Vector2(0, -8), Vector2(step, -1), VectorStyle.SKIN_DEAD_DARK, 2.4, true)
	var hunch: PackedVector2Array = PackedVector2Array([Vector2(-7, -18), Vector2(-2, -22), Vector2(5, -20), Vector2(7, -12), Vector2(5, -5),
		Vector2(1, -3), Vector2(-3, -6), Vector2(-8, -4), Vector2(-6, -10)])
	VectorStyle.shape(self, hunch, VectorStyle.RAG, VectorStyle.RAG_DARK)
	var head: Vector2 = Vector2(6 + lunge * 4.0, -21)
	VectorStyle.shape(self, PackedVector2Array([head + Vector2(-4, -4), head + Vector2(3, -5), head + Vector2(6, -1), head + Vector2(4, 4), head + Vector2(-3, 3)]),
		VectorStyle.SKIN_DEAD, VectorStyle.SKIN_DEAD_DARK)
	draw_colored_polygon(VectorStyle.ellipse(head + Vector2(3, -1), 1.5, 1.1, 10), VectorStyle.EYE_RED)
	_arm(Vector2(3, -16), Vector2(12 + lunge * 8.0 + walk * 2.0, -11 + lunge * 2.0))


func _draw_glow(layer: Node2D) -> void:
	var s: Dictionary = VectorStyle.sprite_state(sprite)
	if s.state == "death":
		return
	VectorStyle.draw_glow(layer, VectorStyle.COLD_GLOW, Vector2(0, -12), 22.0, 0.13 + 0.04 * sin(_time * 3.0 + _phase))
	var mirror: float = -1.0 if s.flip else 1.0
	match String(s.facing):
		"up":
			pass
		"side":
			var lunge: float = sin(clampf(float(s.progress), 0.0, 1.0) * PI) if s.state == "attack" else 0.0
			VectorStyle.draw_glow(layer, VectorStyle.EYE_RED, Vector2((9.0 + lunge * 4.0) * mirror, -22), 6.0, 0.95)
		_:
			for side: float in [-1.0, 1.0]:
				VectorStyle.draw_glow(layer, VectorStyle.EYE_RED, Vector2(side * 2.3, -23.5), 5.0, 0.9)
