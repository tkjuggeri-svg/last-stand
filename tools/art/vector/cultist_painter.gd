class_name CultistPainter
## Paints the vector Cultist (M15, docs/M15_VECTOR.md): a robed caster in a pale grey hooded robe with a ragged hem and
## a dark sash, a hood that opens on a void with two green eyes (the ranged role's colour), a glowing green orb held in
## one hand and a rune sewn on the back. Pose units: feet at y 0, about 33 tall. frame() paints one sheet frame
## (sheet_layouts.gd CULTIST): a swaying idle, a gliding walk, an attack that lifts the orb, gathers light and throws it
## (the release lands at the data's 0.5 s wind-up), and a collapse into the robe with the orb rolling away.

const ROBE: Color = Color("b5b0a8")
const ROBE_DARK: Color = Color("5f5b66")
const SASH: Color = Color("3b2f3f")
const VOID: Color = Color("0c0a12")
const SKIN: Color = Color("c9c0b0")
const ORB: Color = Color("7fd13b")
## The figure's size against the old sprite (M15 Q2).
const SCALE: float = 1.15
const WINDUP_END: float = 0.6
const STRIKE_PEAK: float = 0.8
const PULL_BACK: float = 0.0
## Where the orb sits in the hand at rest, per facing, and how far a throw sends it (pose units).
const ORB_REST: Dictionary = {"down": Vector2(10, -14), "up": Vector2(-9, -15), "side": Vector2(9, -15)}
const THROW_REACH: float = 9.0


static func frame(ci: CanvasItem, anim: String, index: int, count: int) -> void:
	var a: Dictionary = VectorFrames.parse(anim)
	var state: String = a.state
	var facing: String = a.facing
	var cycle: float = float(index) / count
	var progress: float = float(index) / maxi(count - 1, 1)
	if state == "death":
		_death(ci, progress)
		return
	# `gather` raises and charges the orb until the release; `throw` pushes it out and down again.
	var gather: float = 0.0
	var throw_: float = 0.0
	if state == "attack":
		gather = smoothstep(0.0, WINDUP_END, progress) * (1.0 - smoothstep(WINDUP_END, STRIKE_PEAK, progress))
		throw_ = VectorFrames.attack_curve(progress, WINDUP_END, STRIKE_PEAK, PULL_BACK)
	var pose: Dictionary = {"facing": facing, "walk": state == "walk", "phase": cycle, "gather": gather, "throw": throw_}
	VectorStyle.shadow(ci, Vector2(0, 2), 11, 4.4)
	var bob: float = -absf(sin(cycle * TAU)) * 0.8 if state == "walk" else sin(cycle * TAU) * 0.5
	ci.draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE)
	paint(ci, pose)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_glows(ci, pose, bob)


static func paint(ci: CanvasItem, pose: Dictionary) -> void:
	match String(pose.facing):
		"up":
			_back(ci, pose)
		"side":
			_side(ci, pose)
		_:
			_front(ci, pose)


static func _sway(pose: Dictionary) -> float:
	return sin(float(pose.phase) * TAU) * (2.0 if pose.walk else 0.8)


static func _orb_pos(pose: Dictionary) -> Vector2:
	var rest: Vector2 = ORB_REST[String(pose.facing)]
	var forward: Vector2 = Vector2(1, 0) if pose.facing == "side" else (Vector2(0, -1) if pose.facing == "up" else Vector2(0, 1))
	var lifted: Vector2 = rest + Vector2(0, -9.0 * float(pose.gather))
	var sent: float = maxf(float(pose.throw), 0.0)
	return lifted + forward * THROW_REACH * sent


## The robe: a tapered cone with a ragged hem, sway at the bottom, folds and a darker inner side.
static func _robe(ci: CanvasItem, top: float, width: float, sway: float, hem_y: float) -> void:
	var robe: PackedVector2Array = PackedVector2Array([Vector2(-width * 0.45, top), Vector2(width * 0.45, top), Vector2(width * 0.8, top + 12.0)])
	for i: int in 7:
		var x: float = lerpf(width, -width, i / 6.0)
		robe.append(Vector2(x + sway, hem_y + (2.4 if i % 2 == 0 else -0.6)))
	robe.append(Vector2(-width * 0.8, top + 12.0))
	VectorPaint.painted(ci, robe, ROBE, 3.0, 0.6)
	for k: int in 4:
		var x: float = lerpf(-width * 0.5, width * 0.5, (k + 0.5) / 4.0)
		VectorPaint.strand(ci, Vector2(x * 0.35, top + 6.0), Vector2(x * 0.9 + sway * 0.5, (top + hem_y) * 0.5), Vector2(x * 1.25 + sway, hem_y - 0.5), 1.6, Color(VectorPaint.shadow_of(ROBE), 0.75))


static func _sash(ci: CanvasItem, y: float, width: float) -> void:
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-width, y), Vector2(width, y), Vector2(width - 0.6, y + 2.4), Vector2(-width + 0.6, y + 2.4)]), SASH, 1.0, 0.2, 0.8)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(1.5, y + 2.0), Vector2(4.0, y + 2.0), Vector2(4.6, y + 7.0), Vector2(2.2, y + 6.2)]), SASH, 0.8, 0.2, 0.8)


static func _hood(ci: CanvasItem, at: Vector2, facing: String) -> void:
	var shell: PackedVector2Array = PackedVector2Array([at + Vector2(-6.4, 4), at + Vector2(-5.2, -3), at + Vector2(-2.6, -8), at + Vector2(0.6, -12.6), at + Vector2(3.0, -8),
		at + Vector2(5.4, -3), at + Vector2(6.4, 4), at + Vector2(0, 6)])
	if facing == "side":
		shell = PackedVector2Array([at + Vector2(-6.4, 4), at + Vector2(-5.6, -3), at + Vector2(-3.0, -8), at + Vector2(-0.8, -12.6), at + Vector2(2.6, -8), at + Vector2(5.4, -2),
			at + Vector2(6.0, 4), at + Vector2(0, 6)])
	VectorPaint.painted(ci, shell, ROBE, 3.0, 0.65)
	if facing == "down":
		VectorPaint.fill(ci, PackedVector2Array([at + Vector2(-4.0, 3), at + Vector2(-3.6, -3), at + Vector2(0, -6), at + Vector2(3.6, -3), at + Vector2(4.0, 3), at + Vector2(0, 4.6)]), VOID)
		for side: float in [-1.0, 1.0]:
			ci.draw_circle(at + Vector2(side * 1.8, -0.4), 0.8, ORB, true, -1.0, true)
		VectorPaint.line(ci, at + Vector2(-5.0, 3.4), at + Vector2(-3.8, -3.4), Color(VectorPaint.shadow_of(ROBE), 0.9), 0.9)
		VectorPaint.line(ci, at + Vector2(5.0, 3.4), at + Vector2(3.8, -3.4), Color(VectorPaint.shadow_of(ROBE), 0.9), 0.9)
	elif facing == "side":
		VectorPaint.fill(ci, PackedVector2Array([at + Vector2(0.4, 3), at + Vector2(0.8, -3), at + Vector2(3.4, -5.4), at + Vector2(5.4, -2), at + Vector2(5.8, 3), at + Vector2(3.0, 4.4)]), VOID)
		ci.draw_circle(at + Vector2(3.8, -0.4), 0.85, ORB, true, -1.0, true)
	else:
		VectorPaint.line(ci, at + Vector2(0.4, -11), at + Vector2(0.2, 3), Color(VectorPaint.shadow_of(ROBE), 0.9), 0.9)
		_rune(ci, at + Vector2(0, 9.5), 1.0)


## A small sewn rune: a ring with a stroke through it.
static func _rune(ci: CanvasItem, at: Vector2, s: float) -> void:
	ci.draw_arc(at, 2.6 * s, 0.0, TAU, 14, Color(ORB, 0.85), 0.8, true)
	VectorPaint.line(ci, at + Vector2(0, -3.6) * s, at + Vector2(0, 3.6) * s, Color(ORB, 0.85), 0.8)
	VectorPaint.line(ci, at + Vector2(-1.8, 1.2) * s, at + Vector2(1.8, -1.2) * s, Color(ORB, 0.85), 0.7)


static func _sleeve(ci: CanvasItem, shoulder: Vector2, hand: Vector2) -> void:
	VectorPaint.limb(ci, shoulder, shoulder.lerp(hand, 0.5) + Vector2(0, 1.4), hand, 4.2, ROBE)
	VectorPaint.painted(ci, VectorStyle.ellipse(hand, 2.3, 2.0, 10), SKIN, 0.9, 0.4, 0.8)


static func _orb(ci: CanvasItem, at: Vector2, charge: float) -> void:
	var r: float = 2.8 + charge * 1.4
	VectorStyle.draw_glow(ci, ORB, at, 9.0 + charge * 6.0, 0.55 + charge * 0.3)
	VectorPaint.painted(ci, VectorStyle.ellipse(at, r, r, 14), Color("a6f05a"), 1.4, 0.0, 0.8)
	ci.draw_circle(at + Vector2(-0.7, -0.8), r * 0.38, Color("f2ffd0"), true, -1.0, true)


static func _front(ci: CanvasItem, pose: Dictionary) -> void:
	var sway: float = _sway(pose)
	_robe(ci, -24, 11.0, sway * 0.7, -4.0)
	_sash(ci, -14, 7.4)
	_sleeve(ci, Vector2(-6.5, -22), Vector2(-4.0, -13))
	_hood(ci, Vector2(0, -26), "down")
	var orb: Vector2 = _orb_pos(pose)
	_sleeve(ci, Vector2(6.5, -22), orb + Vector2(-1.0, 2.0))
	_orb(ci, orb, float(pose.gather))


static func _back(ci: CanvasItem, pose: Dictionary) -> void:
	var sway: float = _sway(pose)
	var orb: Vector2 = _orb_pos(pose)
	_sleeve(ci, Vector2(-6.5, -22), orb + Vector2(1.0, 2.0))
	_orb(ci, orb, float(pose.gather))
	_robe(ci, -24, 11.5, -sway * 0.7, -4.0)
	_sash(ci, -14, 7.8)
	_sleeve(ci, Vector2(6.5, -22), Vector2(4.5, -13))
	_hood(ci, Vector2(0, -26), "up")


static func _side(ci: CanvasItem, pose: Dictionary) -> void:
	var sway: float = _sway(pose)
	_robe(ci, -24, 8.0, -sway * 0.9 - 2.0, -4.0)
	_sash(ci, -14, 5.6)
	_sleeve(ci, Vector2(-1, -22), Vector2(-3.0 - sway * 0.4, -12))
	_hood(ci, Vector2(0.5, -26), "side")
	var orb: Vector2 = _orb_pos(pose)
	_sleeve(ci, Vector2(2.0, -22), orb + Vector2(-1.5, 2.0))
	_orb(ci, orb, float(pose.gather))


static func _glows(ci: CanvasItem, pose: Dictionary, bob: float) -> void:
	VectorStyle.draw_glow(ci, VectorStyle.COLD_GLOW, Vector2(0, -14 + bob), 20.0, 0.1)
	match String(pose.facing):
		"up":
			pass
		"side":
			VectorStyle.draw_glow(ci, ORB, Vector2(4.3, -26.4 + bob), 3.2, 0.7)
		_:
			for side: float in [-1.0, 1.0]:
				VectorStyle.draw_glow(ci, ORB, Vector2(side * 1.8, -26.4 + bob), 3.0, 0.65)


## It folds into its robe; the orb drops, rolls away and dims.
static func _death(ci: CanvasItem, progress: float) -> void:
	var fall: float = smoothstep(0.0, 0.7, progress)
	VectorStyle.shadow(ci, Vector2(0, 2), 11.0 + fall * 4.0, 4.4 + fall * 1.2)
	ci.draw_set_transform(Vector2(fall * 1.5, fall * 12.0), fall * 0.12, Vector2(1.0 + fall * 0.35, 1.0 - fall * 0.62))
	var pose: Dictionary = {"facing": "down", "walk": false, "phase": 0.0, "gather": 0.0, "throw": 0.0}
	_robe(ci, -24, 11.0, 0.0, -4.0)
	_sash(ci, -14, 7.4)
	_hood(ci, Vector2(0, -26), "down")
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var orb: Vector2 = _orb_pos(pose).lerp(Vector2(15.0, -2.0), fall)
	if progress < 0.95:
		_orb(ci, orb, 0.0)
