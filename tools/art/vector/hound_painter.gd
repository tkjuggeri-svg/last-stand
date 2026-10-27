class_name HoundPainter
## Paints the vector Grave Hound (M15, docs/M15_VECTOR.md): a starved undead hound, low and long, a bare skull for a head
## with yellow eyes (the fast role's colour), a flayed red-brown hide stretched over a ribcage and a bony spine ridge,
## digitigrade legs with knobby joints, ragged ears and a whip of a tail. Pose units: feet at y 0, about 17 tall and
## 34 long in profile. frame() paints one sheet frame (sheet_layouts.gd HOUND): idle with panting, a gallop, a leap and
## bite timed to the data's 0.25 s wind-up, and a collapse.

const HIDE: Color = Color("a8623f")
const HIDE_DARK: Color = Color("6a3a28")
const BONE: Color = Color("e8dcc0")
const BONE_DARK: Color = Color("a99d82")
const MOUTH: Color = Color("1a0f12")
## The figure's size against the old sprite (M15 Q2).
const SCALE: float = 1.15
const WINDUP_END: float = 0.5
const STRIKE_PEAK: float = 0.727
const PULL_BACK: float = -0.35


static func frame(ci: CanvasItem, anim: String, index: int, count: int) -> void:
	var a: Dictionary = VectorFrames.parse(anim)
	var state: String = a.state
	var facing: String = a.facing
	var cycle: float = float(index) / count
	var progress: float = float(index) / maxi(count - 1, 1)
	if state == "death":
		_death(ci, progress)
		return
	var lunge: float = VectorFrames.attack_curve(progress, WINDUP_END, STRIKE_PEAK, PULL_BACK) if state == "attack" else 0.0
	var pose: Dictionary = {"facing": facing, "walk": state == "walk", "phase": cycle, "lunge": lunge}
	VectorStyle.shadow(ci, Vector2(0, 2), 15 if facing == "side" else 8, 4.4)
	var bob: float = -absf(sin(cycle * TAU)) * 2.2 if state == "walk" else sin(cycle * TAU) * 0.5
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


static func _gait(pose: Dictionary) -> float:
	return sin(float(pose.phase) * TAU)


static func _ear(ci: CanvasItem, at: Vector2, lean: float) -> void:
	var ear: PackedVector2Array = PackedVector2Array([at + Vector2(-2.2, 0), at + Vector2(2.2, 0), at + Vector2(lean + 1.0, -8.0), at + Vector2(lean * 0.6, -5.0)])
	VectorPaint.painted(ci, ear, HIDE_DARK, 1.2, 0.5)
	VectorPaint.fill(ci, PackedVector2Array([at + Vector2(-0.8, -0.5), at + Vector2(1.0, -0.5), at + Vector2(lean * 0.9, -5.5)]), Color("7b3d3a"))


## The skull seen from the front: a broad brow, sunken sockets with a yellow pinpoint each, a long snout, teeth.
static func _skull_front(ci: CanvasItem, at: Vector2, open: float) -> void:
	var skull: PackedVector2Array = PackedVector2Array([at + Vector2(-5.5, -3), at + Vector2(-3.5, -6.5), at + Vector2(3.5, -6.5), at + Vector2(5.5, -3),
		at + Vector2(4.0, 1.5), at + Vector2(2.6, 6.0 + open), at + Vector2(-2.6, 6.0 + open), at + Vector2(-4.0, 1.5)])
	VectorPaint.painted(ci, skull, BONE, 2.2, 0.7)
	for side: float in [-1.0, 1.0]:
		ci.draw_colored_polygon(VectorStyle.ellipse(at + Vector2(side * 2.7, -2.2), 1.9, 1.6, 12), Color("1b1118"))
		ci.draw_circle(at + Vector2(side * 2.7, -2.1), 0.8, VectorStyle.ROLE_FAST, true, -1.0, true)
		ci.draw_circle(at + Vector2(side * 0.9, 3.2), 0.5, Color("2a1c20"), true, -1.0, true)
	VectorPaint.fill(ci, PackedVector2Array([at + Vector2(-2.2, 3.6), at + Vector2(2.2, 3.6), at + Vector2(1.8, 4.8 + open), at + Vector2(-1.8, 4.8 + open)]), MOUTH)
	for k: int in 4:
		var x: float = -1.8 + k * 1.2
		VectorPaint.fill(ci, PackedVector2Array([at + Vector2(x, 3.6), at + Vector2(x + 0.7, 3.6), at + Vector2(x + 0.35, 4.6)]), Color("fff7e2"))
	VectorPaint.line(ci, at + Vector2(0, -6.2), at + Vector2(0, 1.0), Color(BONE_DARK, 0.8), 0.7)


static func _front(ci: CanvasItem, pose: Dictionary) -> void:
	var gait: float = _gait(pose)
	var lunge: float = float(pose.lunge)
	for side: float in [-1.0, 1.0]:
		var swing: float = gait * 2.5 * side
		VectorPaint.limb(ci, Vector2(side * 3.4, -9), Vector2(side * 4.6, -5 - swing * 0.3), Vector2(side * 3.8, -0.8 - swing), 2.2, HIDE)
		VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(side * 3.8, -0.8 - swing), 2.4, 1.3, 10), HIDE_DARK, 0.8, 0.3, 0.7)
	VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -9.5), 6.2, 7.0, 18), HIDE, 2.6, 0.6)
	for k: int in 3:
		ci.draw_arc(Vector2(0, -12 + k * 2.4), 4.6 - k * 0.5, PI * 0.15, PI * 0.85, 8, Color(BONE, 0.85), 0.8, true)
	_ear(ci, Vector2(-4.5, -17), -2.5)
	_ear(ci, Vector2(4.5, -17), 2.5)
	_skull_front(ci, Vector2(0, -15.5 + maxf(lunge, 0.0) * 2.0), maxf(lunge, 0.0) * 1.8)


static func _back(ci: CanvasItem, pose: Dictionary) -> void:
	var gait: float = _gait(pose)
	var whip: float = gait * 2.0
	for side: float in [-1.0, 1.0]:
		var swing: float = gait * 2.5 * side
		VectorPaint.limb(ci, Vector2(side * 3.6, -9), Vector2(side * 5.0, -5 + swing * 0.3), Vector2(side * 3.8, -0.8 + swing), 2.4, HIDE)
		VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(side * 3.8, -0.8 + swing), 2.4, 1.3, 10), HIDE_DARK, 0.8, 0.3, 0.7)
	VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -9.5), 6.6, 7.2, 18), HIDE, 2.6, 0.6)
	for k: int in 5:
		VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -15 + k * 2.4), 1.1, 0.9, 8), BONE, 0.5, 0.3, 0.5)
	VectorPaint.strand(ci, Vector2(0, -6), Vector2(whip * 1.5, -12), Vector2(whip * 3.0, -20), 3.4, HIDE_DARK)
	_ear(ci, Vector2(-3.6, -17), -2.0)
	_ear(ci, Vector2(3.6, -17), 2.0)
	VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -15.5), 4.4, 3.8, 14), BONE_DARK, 1.4, 0.5)


static func _side(ci: CanvasItem, pose: Dictionary) -> void:
	var gait: float = _gait(pose)
	var lunge: float = float(pose.lunge)
	var reach: float = maxf(lunge, 0.0)
	var crouch: float = -lunge if lunge < 0.0 else 0.0
	var run: float = 1.0 if pose.walk else 0.2
	# The far legs (darker), then the body, then the near legs.
	for leg: Array in [[-9.0, true], [7.0, false]]:
		_leg(ci, Vector2(float(leg[0]), -10), gait * run, bool(leg[1]), HIDE_DARK, reach, crouch)
	VectorPaint.strand(ci, Vector2(-13, -13), Vector2(-18, -12 + gait * 2.0), Vector2(-22, -19 - gait * 2.5), 3.0, HIDE_DARK)
	var body: PackedVector2Array = PackedVector2Array([Vector2(-14, -12), Vector2(-9, -17), Vector2(0, -18.5), Vector2(8, -17), Vector2(11, -13), Vector2(8, -8),
		Vector2(0, -7), Vector2(-7, -8.5)])
	VectorPaint.painted(ci, body, HIDE, 3.0, 0.6)
	for k: int in 6:
		VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(-10 + k * 4.0, -18.2 + absf(k - 2.5) * 0.25), 1.1, 0.9, 8), BONE, 0.5, 0.3, 0.5)
	for k: int in 4:
		var x: float = -4.0 + k * 3.2
		ci.draw_arc(Vector2(x, -15.5), 4.6, PI * 0.12, PI * 0.62, 8, Color(BONE, 0.9), 0.9, true)
		ci.draw_arc(Vector2(x - 0.4, -15.9), 4.6, PI * 0.14, PI * 0.5, 8, Color(1, 1, 1, 0.35), 0.5, true)
	for leg: Array in [[-6.5, true], [9.0, false]]:
		_leg(ci, Vector2(float(leg[0]), -10), -gait * run, bool(leg[1]), HIDE, reach, crouch)
	var neck: Vector2 = Vector2(10, -15)
	var head: Vector2 = Vector2(17 + reach * 5.0 - crouch * 2.0, -15 + crouch * 1.5 + gait * 0.4)
	VectorPaint.strand(ci, neck, Vector2(13, -17), head + Vector2(-3, -1), 6.0, HIDE)
	_skull_side(ci, head, reach * 2.6 + (0.6 if pose.walk else 0.0) + sin(float(pose.phase) * TAU * 2.0) * 0.3)
	_ear(ci, head + Vector2(-2.5, -5.5), -3.0)


static func _leg(ci: CanvasItem, hip: Vector2, swing: float, back: bool, color: Color, reach: float, crouch: float) -> void:
	var knee: Vector2 = hip + Vector2(sin(swing) * 4.5 + (-2.0 if back else 2.0) + reach * (2.0 if not back else -1.0), 4.5 + crouch * 1.5)
	var paw: Vector2 = knee + Vector2(sin(swing * 1.2 + 0.8) * 4.0 + (-1.5 if back else 1.0), 5.0 - crouch * 1.5 - maxf(0.0, cos(swing)) * 1.2)
	paw.y = minf(paw.y, -0.5)
	VectorPaint.limb(ci, hip, knee, paw, 2.6, color)
	VectorPaint.painted(ci, VectorStyle.ellipse(paw + Vector2(1.2, 0), 2.6, 1.3, 10), color.darkened(0.2), 0.8, 0.3, 0.7)


static func _skull_side(ci: CanvasItem, at: Vector2, open: float) -> void:
	var cranium: PackedVector2Array = PackedVector2Array([at + Vector2(-4.5, -3.5), at + Vector2(-1, -6), at + Vector2(3, -4.8), at + Vector2(5, -2), at + Vector2(4.2, 0.6),
		at + Vector2(-2.5, 1.5), at + Vector2(-4.8, -0.5)])
	VectorPaint.painted(ci, cranium, BONE, 2.0, 0.7)
	var snout: PackedVector2Array = PackedVector2Array([at + Vector2(2.5, -3.6), at + Vector2(9.2, -2.2), at + Vector2(10.2, 0.2), at + Vector2(3.5, 1.0)])
	VectorPaint.painted(ci, snout, BONE, 1.4, 0.7)
	var jaw: PackedVector2Array = PackedVector2Array([at + Vector2(-1.0, 1.2), at + Vector2(8.6, 0.8 + open * 0.5), at + Vector2(8.0, 2.4 + open), at + Vector2(0.4, 3.0 + open * 0.6)])
	VectorPaint.painted(ci, jaw, BONE_DARK, 1.0, 0.5, 0.9)
	VectorPaint.fill(ci, PackedVector2Array([at + Vector2(3.0, 0.9), at + Vector2(9.0, 0.7), at + Vector2(8.4, 1.4 + open * 0.8), at + Vector2(3.0, 1.8 + open * 0.5)]), MOUTH)
	for k: int in 4:
		var x: float = 4.0 + k * 1.3
		VectorPaint.fill(ci, PackedVector2Array([at + Vector2(x, 0.8), at + Vector2(x + 0.7, 0.8), at + Vector2(x + 0.35, 1.9 + open * 0.3)]), Color("fff7e2"))
	ci.draw_colored_polygon(VectorStyle.ellipse(at + Vector2(1.6, -2.0), 1.7, 1.4, 12), Color("1b1118"))
	ci.draw_circle(at + Vector2(1.8, -2.0), 0.8, VectorStyle.ROLE_FAST, true, -1.0, true)
	ci.draw_circle(at + Vector2(9.6, -1.2), 0.5, Color("2a1c20"), true, -1.0, true)
	VectorPaint.line(ci, at + Vector2(-0.5, -4.5), at + Vector2(3.4, -3.3), Color(1, 1, 1, 0.4), 0.7)


static func _glows(ci: CanvasItem, pose: Dictionary, bob: float) -> void:
	VectorStyle.draw_glow(ci, VectorStyle.COLD_GLOW, Vector2(0, -9 + bob), 20.0, 0.1)
	var reach: float = maxf(float(pose.lunge), 0.0)
	match String(pose.facing):
		"up":
			pass
		"side":
			VectorStyle.draw_glow(ci, VectorStyle.ROLE_FAST, Vector2(18.8 + reach * 5.0, -17 + bob), 3.0, 0.7)
		_:
			for side: float in [-1.0, 1.0]:
				VectorStyle.draw_glow(ci, VectorStyle.ROLE_FAST, Vector2(side * 2.7, -17.7 + reach * 2.0 + bob), 2.6, 0.65)


## It drops on its side, legs curling, and the skull rolls its jaw open.
static func _death(ci: CanvasItem, progress: float) -> void:
	var fall: float = smoothstep(0.0, 0.7, progress)
	VectorStyle.shadow(ci, Vector2(0, 2), 15.0, 4.4 + fall * 1.5)
	# It crumples: the legs fold under it (the crouch pose), then it sinks flat and rolls a little onto its side.
	var crouch: float = -smoothstep(0.0, 0.4, progress)
	ci.draw_set_transform(Vector2(fall * 2.0, fall * 7.0), fall * 0.18, Vector2(1.0 + fall * 0.08, 1.0 - fall * 0.42))
	paint(ci, {"facing": "side", "walk": false, "phase": 0.0, "lunge": crouch})
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if progress < 0.6:
		VectorStyle.draw_glow(ci, VectorStyle.ROLE_FAST, Vector2(18.8 - fall * 2.0, -17 + fall * 11.0), 3.0, 0.7 * (1.0 - progress / 0.6))
