class_name VectorArcher
extends Node2D
## The Archer tower in the vector test style (branch vector-test, never merge), detailed (ArcherPainter): the body
## is baked once per level by the shared VectorPoseCache, the hooded archer per aim (AIM_STEPS) and draw (PULL_STEPS)
## and the pennant per wave step: painted shading clips polygons, too slow to repeat every frame. The torch flames, the
## level pips and the glows are live. The archer turns to the real target and draws on the real shot. Display only.

const AIM_STEPS: int = 24
const PULL_STEPS: int = 3
const WAVE_STEPS: int = 8
const ARCHER_BOX: Rect2 = Rect2(-24, -78, 48, 48)
const PENNANT_BOX: Rect2 = Rect2(-15, -80, 32, 32)

var tower: Tower
var sprite: AnimatedSprite2D
var cache: VectorPoseCache
var _time: float = 0.0
var _angle: float = PI / 2.0
var _recoil: float = 0.0
var _texture: Texture2D
var _archer_texture: Texture2D
var _pennant_texture: Texture2D
var _aim_step: int = 0
var _pull_step: int = 0
var _wave_step: int = 0
var _level: int = 1
var _body: Node2D
var _live: Node2D
var _glow: Node2D


func _ready() -> void:
	_body = Node2D.new()
	_body.name = "Body"
	_body.material = VectorPoseCache.premult_material()
	_body.draw.connect(func() -> void:
		if _texture != null:
			VectorPoseCache.draw_pose(_body, _texture, ArcherPainter.BOX)
		if _pennant_texture != null:
			VectorPoseCache.draw_pose(_body, _pennant_texture, PENNANT_BOX)
		if _archer_texture != null:
			VectorPoseCache.draw_pose(_body, _archer_texture, ARCHER_BOX))
	add_child(_body)
	_live = Node2D.new()
	_live.name = "Live"
	_live.draw.connect(_draw_live)
	add_child(_live)
	_glow = VectorStyle.make_glow_layer(self, _draw_glow)


func _process(delta: float) -> void:
	_time += delta
	var target: Enemy = tower.get_target() if is_instance_valid(tower) else null
	if is_instance_valid(target):
		var want: float = (target.global_position - (global_position + ArcherPainter.TOP)).angle()
		_angle = lerp_angle(_angle, want, minf(1.0, delta * 12.0))
	var s: Dictionary = VectorStyle.sprite_state(sprite)
	# The tower sheet's shot animations are "<id>_fire" and "<id>_fire_<level>".
	_recoil = sin(clampf(float(s.progress), 0.0, 1.0) * PI) if String(sprite.animation).contains("_fire") and bool(s.playing) else 0.0
	_level = tower.get_level() if is_instance_valid(tower) else 1
	var level: int = _level
	_texture = cache.get_pose("archer_%d" % level, ArcherPainter.BOX, func(ci: CanvasItem) -> void: ArcherPainter.paint_body(ci, level)) if cache != null else null
	_aim_step = posmod(roundi(_angle / TAU * AIM_STEPS), AIM_STEPS)
	_pull_step = clampi(int((1.0 - _recoil if _recoil > 0.0 else 0.6) * (PULL_STEPS - 1) + 0.5), 0, PULL_STEPS - 1)
	_wave_step = int(fmod(_time * 0.64, 1.0) * WAVE_STEPS)
	if cache != null:
		var aim: float = _aim_step * TAU / AIM_STEPS
		var pull: float = float(_pull_step) / (PULL_STEPS - 1)
		_archer_texture = cache.get_pose("archer_man_%d_%d" % [_aim_step, _pull_step], ARCHER_BOX, func(ci: CanvasItem) -> void: ArcherPainter.paint_archer(ci, aim, pull))
		var wave: float = sin(float(_wave_step) / WAVE_STEPS * TAU) * 2.0
		_pennant_texture = cache.get_pose("archer_pennant_%d" % _wave_step, PENNANT_BOX, func(ci: CanvasItem) -> void: _paint_pennant(ci, wave))
	modulate.a = 0.55 if tower.is_building() else 1.0
	queue_redraw()
	_body.queue_redraw()
	_live.queue_redraw()
	_glow.queue_redraw()


func _draw() -> void:
	if _texture == null:
		ArcherPainter.paint_body(self, _level)


func _draw_live() -> void:
	if _pennant_texture == null:
		_paint_pennant(_live, sin(float(_wave_step) / WAVE_STEPS * TAU) * 2.0)
	if _archer_texture == null:
		ArcherPainter.paint_archer(_live, _aim_step * TAU / AIM_STEPS, float(_pull_step) / (PULL_STEPS - 1))
	for at: Vector2 in ArcherPainter.TORCHES:
		ArcherPainter.paint_flame(_live, at, _time)
	for i: int in _level:
		var x: float = (i - (_level - 1) / 2.0) * 7.0
		_live.draw_circle(Vector2(x, 11), 2.6, VectorStyle.GOLD, true, -1.0, true)
		_live.draw_circle(Vector2(x, 11), 2.6, VectorStyle.GOLD_DARK, false, 1.0, true)
		_live.draw_circle(Vector2(x - 0.8, 10.2), 0.9, Color(1, 1, 1, 0.6), true, -1.0, true)


func _paint_pennant(ci: CanvasItem, wave: float) -> void:
	var pole: Vector2 = Vector2(-12, -52)
	VectorPaint.line(ci, pole, pole + Vector2(0, -24), Color("4a2e1c"), 1.6)
	ci.draw_circle(pole + Vector2(0, -24.5), 1.1, VectorStyle.GOLD, true, -1.0, true)
	var cloth: PackedVector2Array = PackedVector2Array([pole + Vector2(0, -23), pole + Vector2(7, -22 + wave * 0.5), pole + Vector2(14, -20 + wave), pole + Vector2(10, -18 + wave * 0.6),
		pole + Vector2(14, -15.5 + wave), pole + Vector2(6, -16 + wave * 0.4), pole + Vector2(0, -16)])
	VectorPaint.painted(ci, cloth, ArcherPainter.RED, 1.4, 0.3, 0.8)


func _draw_glow(layer: Node2D) -> void:
	for at: Vector2 in ArcherPainter.TORCHES:
		var flicker: float = 0.75 + 0.25 * sin(_time * 11.0 + at.x)
		VectorStyle.draw_glow(layer, VectorStyle.WARM_GLOW, at + Vector2(0, -7), 16.0 * flicker, 0.7)
		VectorStyle.draw_glow(layer, VectorStyle.WARM_GLOW, at + Vector2(0, -5), 34.0, 0.16 * flicker)
	VectorStyle.draw_glow(layer, VectorStyle.WARM_GLOW, Vector2(0, -26), 12.0, 0.55)
	if _recoil > 0.0:
		VectorStyle.draw_glow(layer, VectorStyle.GOLD, ArcherPainter.TOP + Vector2.from_angle(_angle) * 14.0, 8.0, _recoil)
	# Embers rising from the torches.
	for i: int in 4:
		var t: float = fmod(_time * 0.6 + i * 0.27, 1.0)
		var at: Vector2 = ArcherPainter.TORCHES[i % 2] + Vector2(sin(i * 3.1 + _time * 2.0) * 3.0, -8.0 - t * 18.0)
		VectorStyle.draw_glow(layer, VectorStyle.WARM_GLOW, at, 2.2, 1.0 - t)
