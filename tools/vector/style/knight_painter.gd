class_name KnightPainter
## Paints the vector Knight's body (branch vector-test, never merge), detailed: a cape with folds, greaves with knee
## cops, a chainmail skirt, a breastplate with a ridge and faulds, a tabard with gold trim and the keep emblem,
## layered riveted pauldrons, a kite shield with a chevron, a great helm with a visor slit, breaths and a brass band,
## and a plume of strands. Pose units: feet at y 0, about 46 tall. The sword arm is painted live (paint_sword_arm).

const STEEL: Color = Color("aab3bb")
const STEEL_DARK: Color = Color("5d6570")
const CHAIN: Color = Color("6c737c")
const RED: Color = Color("b02b2a")
const CAPE: Color = Color("8a2124")
const GOLD: Color = Color("e8b54e")
const LEATHER: Color = Color("6b4428")
const BOX: Rect2 = Rect2(-26, -64, 52, 70)


## pose: {facing: down|up|side, phase: 0..1 (walk cycle or idle breath), walk: bool}
static func paint(ci: CanvasItem, pose: Dictionary) -> void:
	match String(pose.facing):
		"up":
			_back(ci, pose)
		"side":
			_side(ci, pose)
		_:
			_front(ci, pose)


static func _step(pose: Dictionary) -> float:
	return sin(float(pose.phase) * TAU) * (2.6 if pose.walk else 0.0)


static func _breath(pose: Dictionary) -> float:
	return 0.0 if pose.walk else sin(float(pose.phase) * TAU) * 0.5


static func _cape(ci: CanvasItem, top: float, width: float, sway: float, folds: int) -> void:
	var hem: float = -3.0
	var pts: PackedVector2Array = PackedVector2Array([Vector2(-width * 0.8, top), Vector2(width * 0.8, top)])
	for i: int in range(8, -1, -1):
		var x: float = lerpf(-width, width, i / 8.0) + sway
		pts.append(Vector2(x, hem + (1.6 if i % 2 == 0 else -0.6)))
	VectorPaint.painted(ci, pts, CAPE, 3.2)
	for i: int in folds:
		var x: float = lerpf(-width * 0.6, width * 0.6, (i + 0.5) / folds)
		VectorPaint.strand(ci, Vector2(x * 0.6, top + 3), Vector2(x + sway * 0.5, (top + hem) * 0.5), Vector2(x * 1.15 + sway, hem - 1), 1.6, Color(VectorPaint.shadow_of(CAPE), 0.7))


static func _leg(ci: CanvasItem, x: float, lift: float) -> void:
	var shin: PackedVector2Array = PackedVector2Array([Vector2(x - 3.4, -12), Vector2(x + 3.4, -12), Vector2(x + 3.0, -2 - lift), Vector2(x - 3.0, -2 - lift)])
	VectorPaint.painted(ci, shin, STEEL, 1.8)
	VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(x, -11.5), 3.3, 2.6, 14), STEEL, 1.2)
	VectorPaint.rivet(ci, Vector2(x, -11.5), 0.7)
	var foot: PackedVector2Array = VectorStyle.ellipse(Vector2(x, -1.5 - lift), 4.2, 2.3, 14)
	VectorPaint.painted(ci, foot, STEEL_DARK, 1.2)
	VectorPaint.line(ci, Vector2(x - 3, -1.8 - lift), Vector2(x + 3, -1.8 - lift), Color(VectorStyle.INK, 0.5), 0.7)


static func _chain_skirt(ci: CanvasItem, top: float, width: float) -> void:
	var skirt: PackedVector2Array = PackedVector2Array([Vector2(-width, top), Vector2(width, top), Vector2(width + 1, top + 7), Vector2(-width - 1, top + 7)])
	VectorPaint.painted(ci, skirt, CHAIN, 1.5, 0.3)
	for row: int in 3:
		for col: int in int(width * 2 / 2.2):
			var c: Vector2 = Vector2(-width + 1.1 + col * 2.2 + (row % 2) * 1.1, top + 1.5 + row * 2.0)
			ci.draw_arc(c, 1.0, 0.2, PI - 0.2, 5, Color(VectorPaint.light_of(CHAIN), 0.55), 0.6, true)


static func _breastplate(ci: CanvasItem, w: float, breath: float) -> void:
	var plate: PackedVector2Array = PackedVector2Array([Vector2(-w, -31 - breath), Vector2(w, -31 - breath), Vector2(w - 1, -21), Vector2(w - 2.5, -15),
		Vector2(0, -13), Vector2(-w + 2.5, -15), Vector2(-w + 1, -21)])
	VectorPaint.painted(ci, plate, STEEL, 2.6)
	VectorPaint.line(ci, Vector2(0, -30 - breath), Vector2(0, -14), Color(1, 1, 1, 0.55), 1.0)
	VectorPaint.line(ci, Vector2(0.8, -30 - breath), Vector2(0.8, -14), Color(VectorStyle.INK, 0.35), 0.7)
	for i: int in 2:
		var y: float = -15.5 + i * 2.4
		ci.draw_arc(Vector2(0, y - 10), 10.5, PI * 0.28, PI * 0.72, 12, Color(VectorStyle.INK, 0.5), 0.8, true)


static func _tabard(ci: CanvasItem, top: float, bottom: float) -> void:
	var cloth: PackedVector2Array = PackedVector2Array([Vector2(-5, top), Vector2(5, top), Vector2(6, bottom - 2), Vector2(3, bottom), Vector2(0, bottom - 1.5),
		Vector2(-3, bottom), Vector2(-6, bottom - 2)])
	VectorPaint.painted(ci, cloth, RED, 2.0, 0.35)
	var trim: PackedVector2Array = cloth.duplicate()
	trim.append(cloth[0])
	ci.draw_polyline(trim, Color(GOLD, 0.9), 0.8, true)
	keep_emblem(ci, Vector2(0, top + 8), 1.0)


## The fortress's keep in gold: the house of the defenders.
static func keep_emblem(ci: CanvasItem, at: Vector2, s: float) -> void:
	var g: Color = GOLD
	VectorPaint.fill(ci, PackedVector2Array([at + Vector2(-3, 3) * s, at + Vector2(3, 3) * s, at + Vector2(3, -1.5) * s, at + Vector2(-3, -1.5) * s]), g)
	for x: float in [-3.0, -1.0, 1.0]:
		VectorPaint.fill(ci, PackedVector2Array([at + Vector2(x, -1.5) * s, at + Vector2(x + 1.0, -1.5) * s, at + Vector2(x + 1.0, -3) * s, at + Vector2(x, -3) * s]), g)
	VectorPaint.fill(ci, PackedVector2Array([at + Vector2(-0.8, 3) * s, at + Vector2(0.8, 3) * s, at + Vector2(0.8, 0.8) * s, at + Vector2(-0.8, 0.8) * s]), VectorPaint.shadow_of(RED))


static func _belt(ci: CanvasItem, w: float) -> void:
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-w, -14.8), Vector2(w, -14.8), Vector2(w, -12.6), Vector2(-w, -12.6)]), LEATHER, 1.0, 0.2, 0.8)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-1.5, -15.2), Vector2(1.5, -15.2), Vector2(1.5, -12.2), Vector2(-1.5, -12.2)]), GOLD, 0.8, 0.0, 0.7)


static func _pauldron(ci: CanvasItem, at: Vector2, side: float) -> void:
	var big: PackedVector2Array = PackedVector2Array([at + Vector2(-5 * side, -3), at + Vector2(0, -4.5), at + Vector2(5 * side, -2), at + Vector2(5.5 * side, 2.5),
		at + Vector2(0, 3.5), at + Vector2(-4 * side, 2)])
	if side < 0:
		big.reverse()
	VectorPaint.painted(ci, big, STEEL, 2.2)
	var lame: PackedVector2Array = PackedVector2Array([at + Vector2(-3 * side, 2.5), at + Vector2(5 * side, 3), at + Vector2(4.5 * side, 6), at + Vector2(-2 * side, 5.5)])
	if side < 0:
		lame.reverse()
	VectorPaint.painted(ci, lame, STEEL_DARK.lightened(0.15), 1.4)
	for k: float in [-2.0, 1.0, 3.5]:
		VectorPaint.rivet(ci, at + Vector2(k * side, 1.0), 0.6)


static func _shield(ci: CanvasItem, at: Vector2, width_scale: float) -> void:
	var w: float = 8.0 * width_scale
	var kite: PackedVector2Array = PackedVector2Array([at + Vector2(-w, -9), at + Vector2(0, -10.5), at + Vector2(w, -9), at + Vector2(w * 0.9, -1),
		at + Vector2(0, 11), at + Vector2(-w * 0.9, -1)])
	VectorPaint.painted(ci, kite, Color("9aa2aa"), 1.6)
	var inner: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in kite:
		inner.append(at + (p - at) * 0.82)
	VectorPaint.painted(ci, inner, RED, 2.4, 0.3, 0.0)
	var chevron: PackedVector2Array = PackedVector2Array([at + Vector2(-w * 0.78, 1.5), at + Vector2(0, -4), at + Vector2(w * 0.78, 1.5), at + Vector2(w * 0.7, 4.2),
		at + Vector2(0, -1.2), at + Vector2(-w * 0.7, 4.2)])
	VectorPaint.painted(ci, chevron, GOLD, 1.0, 0.2, 0.6)
	for p: Vector2 in kite:
		VectorPaint.rivet(ci, at + (p - at) * 0.91, 0.55)
	VectorPaint.line(ci, at + Vector2(-w * 0.5, -6), at + Vector2(-w * 0.2, -3), Color(1, 1, 1, 0.3), 0.6)


static func _helm(ci: CanvasItem, at: Vector2, facing: String, phase: float) -> void:
	# The plume: strands behind the helm, swaying a little.
	var sway: float = sin(phase * TAU) * 1.2
	var back: float = -1.0 if facing == "side" else 0.0
	for i: int in 7:
		var spread: float = (i - 3) * 1.1
		var tip: Vector2 = at + Vector2(back * 13 + spread * (0.6 if facing == "side" else 1.4) + sway, -15 + absf(spread) * 0.8 + (6 if facing == "side" else 0))
		var color: Color = RED.lerp(VectorPaint.light_of(RED), 0.5) if i % 3 == 0 else (RED if i % 2 == 0 else CAPE)
		VectorPaint.strand(ci, at + Vector2(spread * 0.4, -7), at + Vector2(back * 6 + spread, -16), tip, 2.4, color)
	var shell: PackedVector2Array = PackedVector2Array([at + Vector2(-7, -5), at + Vector2(-4.5, -8.5), at + Vector2(4.5, -8.5), at + Vector2(7, -5), at + Vector2(7.5, 4),
		at + Vector2(5, 7.5), at + Vector2(-5, 7.5), at + Vector2(-7.5, 4)])
	if facing == "side":
		shell = PackedVector2Array([at + Vector2(-6, -6), at + Vector2(-2, -8.5), at + Vector2(5, -8), at + Vector2(8, -3), at + Vector2(8.5, 4), at + Vector2(5, 7.5),
			at + Vector2(-5, 7.5), at + Vector2(-7, 3)])
	VectorPaint.painted(ci, shell, STEEL, 2.8, 0.6, 1.3)
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-7.4, 4.5), at + Vector2(7.6, 4.5), at + Vector2(7.2, 6.3), at + Vector2(-7.2, 6.3)]), Color("c79a45"), 0.6, 0.0, 0.6)
	match facing:
		"down":
			VectorPaint.fill(ci, PackedVector2Array([at + Vector2(-5.5, -0.6), at + Vector2(5.5, -0.6), at + Vector2(5.5, 1.1), at + Vector2(-5.5, 1.1)]), Color("0d0a12"))
			VectorPaint.line(ci, at + Vector2(0, -8), at + Vector2(0, 4.2), Color(1, 1, 1, 0.45), 1.0)
			for k: int in 3:
				ci.draw_circle(at + Vector2(3 + k * 1.2, 2.8), 0.4, Color("0d0a12"), true, -1.0, true)
		"side":
			VectorPaint.fill(ci, PackedVector2Array([at + Vector2(2, -0.6), at + Vector2(8.3, -0.6), at + Vector2(8.3, 1.1), at + Vector2(2, 1.1)]), Color("0d0a12"))
		_:
			VectorPaint.line(ci, at + Vector2(0, -8), at + Vector2(0, 4.2), Color(1, 1, 1, 0.35), 1.0)
	VectorStyle.shine(ci, at + Vector2(-3, -4.5), 2.0, 1.2, 0.55)


static func _front(ci: CanvasItem, pose: Dictionary) -> void:
	var step: float = _step(pose)
	var breath: float = _breath(pose)
	_cape(ci, -30, 13, step * 0.3, 4)
	_leg(ci, -4, step)
	_leg(ci, 4, -step)
	_chain_skirt(ci, -15, 7.5)
	_breastplate(ci, 9.5, breath)
	_tabard(ci, -29, -6)
	_belt(ci, 8.5)
	VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -31.5 - breath), 6, 2.4, 14), STEEL_DARK, 1.0)
	_helm(ci, Vector2(0, -40 - breath), "down", float(pose.phase))
	_pauldron(ci, Vector2(-9.5, -29 - breath), -1.0)
	_pauldron(ci, Vector2(9.5, -29 - breath), 1.0)
	_shield(ci, Vector2(-12, -18), 0.85)


static func _back(ci: CanvasItem, pose: Dictionary) -> void:
	var step: float = _step(pose)
	var breath: float = _breath(pose)
	_shield(ci, Vector2(11, -18), 0.8)
	_leg(ci, -4, -step)
	_leg(ci, 4, step)
	_chain_skirt(ci, -15, 7.5)
	_breastplate(ci, 9.5, breath)
	_pauldron(ci, Vector2(-9.5, -29 - breath), -1.0)
	_pauldron(ci, Vector2(9.5, -29 - breath), 1.0)
	_helm(ci, Vector2(0, -40 - breath), "up", float(pose.phase))
	_cape(ci, -32, 13.5, step * 0.4, 5)


static func _side(ci: CanvasItem, pose: Dictionary) -> void:
	var step: float = _step(pose)
	var breath: float = _breath(pose)
	_cape(ci, -30, 9, -3.0 - absf(step) * 0.6, 3)
	_leg(ci, -1.5 + step * 0.8, 0.0)
	_leg(ci, 1.5 - step * 0.8, 0.0)
	_chain_skirt(ci, -15, 5.5)
	_breastplate(ci, 6.5, breath)
	_tabard(ci, -29, -6)
	_belt(ci, 6.0)
	_helm(ci, Vector2(1, -40 - breath), "side", float(pose.phase))
	_pauldron(ci, Vector2(-1, -29 - breath), 1.0)
	_shield(ci, Vector2(8, -18), 0.5)


## The sword arm, painted live (it follows the real aim): a vambrace and gauntlet from `shoulder` to the hand, then
## the sword at `angle`: a fullered blade, a gold crossguard with a gem, a wrapped grip and a pommel.
static func paint_sword_arm(ci: CanvasItem, shoulder: Vector2, angle: float, reach: float = 9.0) -> void:
	var dir: Vector2 = Vector2.from_angle(angle)
	var hand: Vector2 = shoulder + dir * reach
	var side: Vector2 = dir.orthogonal()
	VectorPaint.painted(ci, PackedVector2Array([shoulder + side * 2.4, hand + side * 2.0, hand - side * 2.0, shoulder - side * 2.4]), STEEL, 1.2, 0.4, 1.0)
	var length: float = 24.0
	var base: Vector2 = hand + dir * 3.0
	var tip: Vector2 = base + dir * length
	var blade: PackedVector2Array = PackedVector2Array([base + side * 1.9, tip - dir * 4.0 + side * 1.5, tip, tip - dir * 4.0 - side * 1.5, base - side * 1.9])
	VectorPaint.painted(ci, blade, Color("d8dee3"), 1.0, 0.7, 1.0)
	VectorPaint.line(ci, base + dir * 1.5, tip - dir * 5.0, Color("7d8792"), 0.8)
	VectorPaint.line(ci, base + dir * 1.5 + side * 0.6, tip - dir * 6.0 + side * 0.5, Color(1, 1, 1, 0.7), 0.5)
	VectorPaint.painted(ci, PackedVector2Array([base + side * 5.0 - dir * 0.6, base + side * 5.0 + dir * 1.2, base - side * 5.0 + dir * 1.2, base - side * 5.0 - dir * 0.6]), GOLD, 0.8, 0.0, 0.7)
	ci.draw_circle(base + dir * 0.3, 1.1, Color("ff5a3c"), true, -1.0, true)
	VectorPaint.line(ci, hand - dir * 2.5, base - dir * 0.5, LEATHER, 2.4)
	for k: int in 3:
		var at: Vector2 = hand - dir * (2.0 - k * 1.4)
		VectorPaint.line(ci, at + side * 1.2, at - side * 1.2, Color(VectorStyle.INK, 0.5), 0.5)
	ci.draw_circle(hand - dir * 3.2, 1.6, GOLD, true, -1.0, true)
	VectorPaint.painted(ci, VectorStyle.ellipse(hand, 2.6, 2.4, 10), STEEL_DARK, 0.8, 0.3, 0.9)
