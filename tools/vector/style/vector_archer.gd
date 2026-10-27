class_name VectorArcher
extends Node2D
## The Archer tower in the vector test style (branch vector-test, never merge): a warm stone tower on an octagonal
## base, a lit arrow slit, a wooden deck with a red pennant and a bow that turns toward the tower's real target
## and recoils when the real sprite plays its shot. Level pips in gold. Display only.

const TOP: Vector2 = Vector2(0, -50)
const STONE_LIGHT: Color = Color("b3a490")
const STONE_DARK: Color = Color("5a4d42")
const BASE_LIGHT: Color = Color("8f8a84")
const BASE_DARK: Color = Color("413d3a")

var tower: Tower
var sprite: AnimatedSprite2D
var _time: float = 0.0
var _angle: float = PI / 2.0
var _recoil: float = 0.0
var _glow: Node2D


func _ready() -> void:
	_glow = VectorStyle.make_glow_layer(self, _draw_glow)


func _process(delta: float) -> void:
	_time += delta
	var target: Enemy = tower.get_target() if is_instance_valid(tower) else null
	if is_instance_valid(target):
		var want: float = (target.global_position - (global_position + TOP)).angle()
		_angle = lerp_angle(_angle, want, minf(1.0, delta * 12.0))
	var s: Dictionary = VectorStyle.sprite_state(sprite)
	_recoil = sin(clampf(float(s.progress), 0.0, 1.0) * PI) if s.state.begins_with("attack") and bool(s.playing) else 0.0
	modulate.a = 0.55 if tower.is_building() else 1.0
	queue_redraw()
	_glow.queue_redraw()


func _draw() -> void:
	VectorStyle.shadow(self, Vector2(3, 4), 27, 10)
	# The octagonal plinth: its top face, then the front band for the 3/4 depth.
	var plinth: PackedVector2Array = VectorStyle.regular(Vector2(0, -3), 8, 23, 11, PI / 8.0)
	var band: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in plinth:
		if p.y >= -3.0:
			band.append(p)
	band.sort()
	var front: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in band:
		front.append(p)
	for i: int in range(band.size() - 1, -1, -1):
		front.append(band[i] + Vector2(0, 6))
	VectorStyle.shape(self, front, BASE_DARK, Color("2a2725"))
	VectorStyle.shape(self, plinth, BASE_LIGHT, BASE_DARK)
	# The tower: a tapered stone body with brick courses.
	var body: PackedVector2Array = PackedVector2Array([Vector2(-14, -4), Vector2(14, -4), Vector2(11.5, -46), Vector2(-11.5, -46)])
	VectorStyle.shape(self, body, STONE_LIGHT, STONE_DARK)
	for row: int in 6:
		var y: float = -9.0 - row * 6.5
		var half: float = lerpf(13.6, 11.8, (row + 1) / 7.0)
		draw_line(Vector2(-half, y), Vector2(half, y), Color(VectorStyle.INK, 0.35), 1.0, true)
		var offset: float = 3.0 if row % 2 == 0 else -2.0
		for x: float in [-6.0 + offset, 2.0 + offset]:
			draw_line(Vector2(x, y), Vector2(x, y - 6.5), Color(VectorStyle.INK, 0.25), 1.0, true)
	draw_line(Vector2(-11.5, -46), Vector2(-14, -4), Color(1, 1, 1, 0.18), 2.0, true)
	# The arrow slit, lit warm from inside.
	VectorStyle.shape(self, PackedVector2Array([Vector2(-1.6, -30), Vector2(1.6, -30), Vector2(1.6, -20), Vector2(-1.6, -20)]), VectorStyle.WARM_GLOW, Color("c46a1a"), VectorStyle.INK, 1.0)
	# The wooden deck and its rim.
	VectorStyle.shape(self, VectorStyle.ellipse(Vector2(0, -47), 17, 7.5, 28), VectorStyle.WOOD, VectorStyle.WOOD_DARK)
	draw_arc(Vector2(0, -47), 14.5, 0.0, TAU, 28, Color(VectorStyle.GOLD, 0.25), 1.0, true)
	_pennant()
	_bow()
	_pips()


func _pennant() -> void:
	var pole: Vector2 = Vector2(-13, -48)
	draw_line(pole, pole + Vector2(0, -24), VectorStyle.WOOD_DARK, 1.8, true)
	var wave: float = sin(_time * 4.0) * 2.0
	VectorStyle.shape(self, PackedVector2Array([pole + Vector2(0, -24), pole + Vector2(12, -21 + wave), pole + Vector2(9, -18 + wave * 0.5), pole + Vector2(12, -15 + wave),
		pole + Vector2(0, -16)]), VectorStyle.TABARD, VectorStyle.TABARD_DARK, VectorStyle.INK, 1.0)


func _bow() -> void:
	draw_set_transform(TOP, _angle, Vector2.ONE)
	var pull: float = _recoil * 4.0
	VectorStyle.shape(self, VectorStyle.ellipse(Vector2.ZERO, 7.0, 7.0, 16), VectorStyle.WOOD, VectorStyle.WOOD_DARK)
	draw_arc(Vector2(4 - pull * 0.3, 0), 12.0, -1.15, 1.15, 18, VectorStyle.INK, 4.6, true)
	draw_arc(Vector2(4 - pull * 0.3, 0), 12.0, -1.15, 1.15, 18, VectorStyle.GOLD, 2.6, true)
	var tip: Vector2 = Vector2(4 - pull * 0.3 + cos(1.15) * 12.0, sin(1.15) * 12.0)
	var nock: Vector2 = Vector2(1 - pull, 0)
	draw_polyline(PackedVector2Array([Vector2(tip.x, -tip.y), nock, tip]), Color(1, 1, 1, 0.75), 1.0, true)
	if _recoil < 0.5:
		draw_line(nock, Vector2(19 - pull, 0), Color("ece4d4"), 1.8, true)
		draw_colored_polygon(PackedVector2Array([Vector2(23 - pull, 0), Vector2(18 - pull, -2.5), Vector2(18 - pull, 2.5)]), VectorStyle.STEEL_LIGHT)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _pips() -> void:
	var level: int = tower.get_level() if is_instance_valid(tower) else 1
	for i: int in level:
		var x: float = (i - (level - 1) / 2.0) * 7.0
		draw_circle(Vector2(x, 9), 2.6, VectorStyle.GOLD, true, -1.0, true)
		draw_circle(Vector2(x, 9), 2.6, VectorStyle.GOLD_DARK, false, 1.0, true)


func _draw_glow(layer: Node2D) -> void:
	VectorStyle.draw_glow(layer, VectorStyle.WARM_GLOW, Vector2(0, -25), 14.0, 0.55 + 0.1 * sin(_time * 5.0))
	VectorStyle.draw_glow(layer, VectorStyle.WARM_GLOW, TOP, 26.0, 0.18 + _recoil * 0.4)
	if _recoil > 0.0:
		VectorStyle.draw_glow(layer, VectorStyle.GOLD, TOP + Vector2.from_angle(_angle) * 20.0, 9.0, _recoil)
