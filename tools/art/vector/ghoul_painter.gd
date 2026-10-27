class_name GhoulPainter
## Paints the vector Ghoul (M15, docs/M15_VECTOR.md), detailed: a starved, bony body under layered rags with
## holes and hanging tatters, an open chest with ribs, sinewy arms with knobby elbows and long bone claws, a skull-like
## head with sunken sockets, a gaping jaw with teeth and lank hair, spine spurs from behind. Cold palette, a cyan
## moonlight rim. Pose units: feet at y 0, about 32 tall. frame() paints one sheet frame of an animation
## (sheet_layouts.gd GHOUL): idle sway, a walk cycle, an attack with a wind-up, a strike and a recovery timed to the
## data's wind-up (0.35 s of the 0.5 s animation), and a collapse. The eye glow and the cold halo are baked in.

const SKIN: Color = Color("c3d6cf")
const SKIN_DARK: Color = Color("6d8a85")
const BONE: Color = Color("e6e2cf")
## Claws a little darker than bone, so a crowd of hands doesn't read as white noise.
const CLAW: Color = Color("bdb08c")
const RAG: Color = Color("7f8ca0")
const RAG_BACK: Color = Color("4b5568")
const HAIR: Color = Color("3a3f4a")
const MOUTH: Color = Color("140f18")
## The figure's size against the old sprite (M15 Q2: up to 1.25x, collision unchanged).
const SCALE: float = 1.15
## The attack's shape over its progress (0..1): pull back until WINDUP_END, strike up to STRIKE_PEAK, then recover.
const WINDUP_END: float = 0.55
const STRIKE_PEAK: float = 0.727
const PULL_BACK: float = -0.3


## One frame of `anim` ("idle_down", "walk_side", "attack_up", "death"): frame `index` of `count`.
static func frame(ci: CanvasItem, anim: String, index: int, count: int) -> void:
	var cut: int = anim.find("_")
	var state: String = anim.substr(0, cut) if cut > 0 else anim
	var facing: String = anim.substr(cut + 1) if cut > 0 else "down"
	var cycle: float = float(index) / count
	var progress: float = float(index) / maxi(count - 1, 1)
	if state == "death":
		_death(ci, progress)
		return
	VectorStyle.shadow(ci, Vector2(0, 2), 12, 4.8)
	var walking: bool = state == "walk"
	var lunge: float = _lunge(progress) if state == "attack" else 0.0
	var bob: float = -absf(sin(cycle * TAU)) * 1.2 if walking else sin(cycle * TAU) * 0.4
	ci.draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE)
	paint(ci, {"facing": facing, "walk": walking, "phase": cycle, "lunge": lunge})
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_glows(ci, facing, lunge, bob)


static func _lunge(progress: float) -> float:
	if progress < WINDUP_END:
		return PULL_BACK * smoothstep(0.0, WINDUP_END, progress)
	if progress < STRIKE_PEAK:
		return lerpf(PULL_BACK, 1.0, smoothstep(WINDUP_END, STRIKE_PEAK, progress))
	return lerpf(1.0, 0.0, smoothstep(STRIKE_PEAK, 1.0, progress))


## The eye glow and a faint cold halo, as normal-alpha halos in the sheet (additive blending doesn't survive a
## transparent bake).
static func _glows(ci: CanvasItem, facing: String, lunge: float, bob: float) -> void:
	VectorStyle.draw_glow(ci, VectorStyle.COLD_GLOW, Vector2(0, -14 + bob), 24.0, 0.16)
	var lift: float = maxf(lunge, 0.0)
	match facing:
		"up":
			pass
		"side":
			VectorStyle.draw_glow(ci, VectorStyle.EYE_RED, Vector2(13.2 + lift * 4.0, -19.5 + lift + bob), 3.0, 0.75)
		_:
			for x: float in [-2.3, 2.3]:
				VectorStyle.draw_glow(ci, VectorStyle.EYE_RED, Vector2(x, -27.0 + lift * 2.0 + bob), 2.8, 0.7)


## The collapse: it folds forward, tips onto its side and lies in a darkening pool.
static func _death(ci: CanvasItem, progress: float) -> void:
	var fall: float = smoothstep(0.0, 0.8, progress)
	var pool: float = smoothstep(0.35, 1.0, progress)
	VectorStyle.shadow(ci, Vector2(0, 2), 12 + pool * 6.0, 4.8 + pool * 2.0)
	ci.draw_colored_polygon(VectorStyle.ellipse(Vector2(4.0 * pool, 3), 9.0 * pool, 3.0 * pool, 16), Color(0.05, 0.07, 0.12, 0.6 * pool))
	ci.draw_set_transform(Vector2(fall * 5.0, fall * 8.0), fall * 1.4, Vector2(1.0, 1.0 - fall * 0.25))
	paint(ci, {"facing": "down", "walk": false, "phase": 0.0, "lunge": 0.0})
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if progress < 0.7:
		VectorStyle.draw_glow(ci, VectorStyle.EYE_RED, Vector2(fall * 5.0 - 2.0, -26.0 + fall * 10.0), 4.0, 0.9 * (1.0 - progress / 0.7))


## pose: {facing, phase: 0..1, walk: bool, lunge: 0..1}
static func paint(ci: CanvasItem, pose: Dictionary) -> void:
	match String(pose.facing):
		"up":
			_back(ci, pose)
		"side":
			_side(ci, pose)
		_:
			_front(ci, pose)


static func _swing(pose: Dictionary) -> float:
	return sin(float(pose.phase) * TAU) * (1.0 if pose.walk else 0.25)


static func _limb(ci: CanvasItem, a: Vector2, joint: Vector2, b: Vector2, width: float) -> void:
	VectorPaint.strand(ci, a, a.lerp(joint, 0.5) + Vector2(0.5, 0), joint, width + 1.6, VectorStyle.INK)
	VectorPaint.strand(ci, joint, joint.lerp(b, 0.5), b, width + 1.2, VectorStyle.INK)
	VectorPaint.strand(ci, a, a.lerp(joint, 0.5), joint, width, SKIN_DARK)
	VectorPaint.strand(ci, joint, joint.lerp(b, 0.5), b, width * 0.85, SKIN_DARK.lightened(0.12))
	VectorPaint.line(ci, a + Vector2(-0.4, 0), joint + Vector2(-0.4, 0), Color(VectorPaint.light_of(SKIN), 0.5), 0.6)
	ci.draw_circle(joint, width * 0.55, SKIN, true, -1.0, true)


static func _claws(ci: CanvasItem, hand: Vector2, dir: Vector2) -> void:
	VectorPaint.painted(ci, VectorStyle.ellipse(hand, 2.2, 1.8, 10), SKIN_DARK, 0.8, 0.4, 0.8)
	for k: float in [-0.5, 0.0, 0.5]:
		var d: Vector2 = dir.rotated(k)
		VectorPaint.strand(ci, hand + d * 1.5, hand + d * 4.0 + d.orthogonal() * 0.8, hand + d * 6.5 + d.orthogonal() * 1.6, 1.4, CLAW)


static func _rags(ci: CanvasItem, top: float, width: float, hem: float, sway: float, color: Color, holes: bool) -> void:
	var pts: PackedVector2Array = PackedVector2Array([Vector2(-width * 0.6, top), Vector2(width * 0.6, top)])
	var teeth: int = 7
	for i: int in range(teeth, -1, -1):
		var x: float = lerpf(-width, width, float(i) / teeth)
		pts.append(Vector2(x + sway * (1.0 + i * 0.1), hem + (3.5 if i % 2 == 0 else -0.5) + (i % 3) * 0.6))
	VectorPaint.painted(ci, pts, color, 2.4, 0.5)
	for i: int in 3:
		var x: float = lerpf(-width * 0.7, width * 0.7, (i + 0.5) / 3.0)
		VectorPaint.strand(ci, Vector2(x, top + 2), Vector2(x + sway, (top + hem) * 0.5), Vector2(x * 1.1 + sway * 1.5, hem + 1), 1.2, Color(VectorPaint.shadow_of(color), 0.7))
	if holes:
		ci.draw_colored_polygon(VectorStyle.ellipse(Vector2(-width * 0.35, (top + hem) * 0.5 + 1), 1.4, 1.0, 8), Color(MOUTH, 0.8))
		ci.draw_colored_polygon(VectorStyle.ellipse(Vector2(width * 0.4, hem - 2.5), 1.1, 0.8, 8), Color(MOUTH, 0.8))
	# Hanging tatters below the hem.
	for i: int in 3:
		var x: float = lerpf(-width * 0.8, width * 0.8, i / 2.0) + sway
		VectorPaint.strand(ci, Vector2(x, hem + 1), Vector2(x + sway, hem + 3), Vector2(x + sway * 2.0, hem + 6), 1.4, color.darkened(0.15))


static func _head(ci: CanvasItem, at: Vector2, facing: String, open: float) -> void:
	if facing == "up":
		VectorPaint.painted(ci, VectorStyle.ellipse(at, 5.5, 6.0, 18), SKIN_DARK, 2.0, 0.6)
		for i: int in 6:
			var x: float = -4.0 + i * 1.6
			VectorPaint.strand(ci, at + Vector2(x * 0.6, -5), at + Vector2(x, -1), at + Vector2(x * 1.2, 4 + (i % 2) * 2), 1.0, HAIR)
		return
	if facing == "side":
		_skull_profile(ci, at, open)
		return
	var dx: float = 0.0
	var skull: PackedVector2Array = PackedVector2Array([at + Vector2(-5.5 + dx, -3), at + Vector2(-3.5 + dx, -6.8), at + Vector2(3.5 + dx, -6.8), at + Vector2(5.8 + dx, -3),
		at + Vector2(5 + dx * 1.5, 1.5), at + Vector2(3 + dx * 2, 4.5 + open), at + Vector2(-3 + dx, 4.5 + open), at + Vector2(-5 + dx, 1.5)])
	VectorPaint.painted(ci, skull, SKIN, 2.2, 0.7)
	# Sunken sockets (the glow sits in them, drawn live), the nose hole, the jaw and teeth.
	var eyes: Array[float] = []
	if facing == "side":
		eyes.append(3.0 + dx)
	else:
		eyes.append_array([-2.3, 2.3])
	for x: float in eyes:
		ci.draw_colored_polygon(VectorStyle.ellipse(at + Vector2(x, -1.2), 1.9, 1.5, 12), Color("1b1420"))
		ci.draw_circle(at + Vector2(x, -1.0), 0.7, VectorStyle.EYE_RED, true, -1.0, true)
	VectorPaint.fill(ci, PackedVector2Array([at + Vector2(dx - 0.6, 0.6), at + Vector2(dx + 0.6, 0.6), at + Vector2(dx, 1.8)]), Color("1b1420"))
	var mouth: PackedVector2Array = PackedVector2Array([at + Vector2(-2.6 + dx, 2.4), at + Vector2(2.6 + dx * 1.6, 2.4), at + Vector2(2.0 + dx * 1.6, 3.4 + open),
		at + Vector2(-2.0 + dx, 3.4 + open)])
	VectorPaint.fill(ci, mouth, MOUTH)
	for k: int in 4:
		var x: float = -2.0 + dx + k * 1.35
		VectorPaint.fill(ci, PackedVector2Array([at + Vector2(x, 2.4), at + Vector2(x + 0.8, 2.4), at + Vector2(x + 0.4, 3.3)]), BONE)
	for k: float in [-1.4, 0.0, 1.4]:
		VectorPaint.line(ci, at + Vector2(-4.2 + dx, 0.5 + k * 0.6), at + Vector2(-2.8 + dx, 1.4 + k * 0.6), Color(SKIN_DARK, 0.6), 0.5)
	for i: int in 5:
		var x: float = -4.5 + i * 2.2 + dx
		VectorPaint.strand(ci, at + Vector2(x * 0.7, -6.4), at + Vector2(x - 1.5, -4), at + Vector2(x - 2.0 - (i % 2), 1 + (i % 3)), 1.0, HAIR)


## The head from the side, jutting forward on a long neck: a long skull, a deep brow, a sunken socket with a red
## pinpoint, a gaping jaw with teeth, lank hair down the back.
static func _skull_profile(ci: CanvasItem, at: Vector2, open: float) -> void:
	for i: int in 4:
		VectorPaint.strand(ci, at + Vector2(-3.0 + i * 1.2, -4.5), at + Vector2(-6.0 + i * 0.6, -1.0), at + Vector2(-7.0 + i * 0.4, 3.0 + i), 1.1, HAIR)
	var skull: PackedVector2Array = PackedVector2Array([at + Vector2(-4.5, -2.5), at + Vector2(-1.5, -5.2), at + Vector2(3.0, -5.0), at + Vector2(5.8, -2.6),
		at + Vector2(7.0, 0.2), at + Vector2(6.2, 1.6), at + Vector2(3.5, 1.8), at + Vector2(1.0, 3.4), at + Vector2(-3.0, 2.4)])
	VectorPaint.painted(ci, skull, SKIN, 2.2, 0.7)
	var jaw: PackedVector2Array = PackedVector2Array([at + Vector2(0.5, 2.2), at + Vector2(5.6, 2.2 + open * 0.6), at + Vector2(5.0, 3.6 + open), at + Vector2(1.0, 4.4 + open * 0.5)])
	VectorPaint.painted(ci, jaw, SKIN_DARK, 1.0, 0.5, 0.9)
	VectorPaint.fill(ci, PackedVector2Array([at + Vector2(1.5, 1.8), at + Vector2(6.0, 1.8), at + Vector2(5.4, 2.4 + open * 0.6), at + Vector2(1.5, 2.6)]), MOUTH)
	for k: int in 3:
		var x: float = 2.2 + k * 1.3
		VectorPaint.fill(ci, PackedVector2Array([at + Vector2(x, 1.8), at + Vector2(x + 0.7, 1.8), at + Vector2(x + 0.35, 2.6)]), BONE)
	# The brow overhangs a deep socket; the eye is a red pinpoint (its glow is live).
	ci.draw_colored_polygon(VectorStyle.ellipse(at + Vector2(3.4, -1.6), 1.6, 1.3, 12), Color("1b1420"))
	ci.draw_circle(at + Vector2(3.7, -1.5), 0.7, VectorStyle.EYE_RED, true, -1.0, true)
	VectorPaint.line(ci, at + Vector2(1.6, -3.2), at + Vector2(5.4, -2.8), Color(VectorPaint.light_of(SKIN), 0.8), 0.7)
	VectorPaint.line(ci, at + Vector2(-1.5, 0.0), at + Vector2(0.5, 1.2), Color(SKIN_DARK, 0.8), 0.6)


static func _ribs(ci: CanvasItem, at: Vector2, w: float) -> void:
	var chest: PackedVector2Array = PackedVector2Array([at + Vector2(-w, -4), at + Vector2(w, -4), at + Vector2(w * 0.8, 4), at + Vector2(-w * 0.8, 4)])
	VectorPaint.painted(ci, chest, SKIN, 1.6, 0.5, 1.0)
	VectorPaint.line(ci, at + Vector2(0, -4), at + Vector2(0, 3.5), Color(SKIN_DARK, 0.8), 0.7)
	for i: int in 4:
		var y: float = -2.8 + i * 1.8
		for side: float in [-1.0, 1.0]:
			var rib: PackedVector2Array = VectorPaint.curve(at + Vector2(side * 0.6, y), at + Vector2(side * w * 0.6, y - 0.8), at + Vector2(side * w * 0.85, y + 1.0), 5)
			ci.draw_polyline(rib, Color(SKIN_DARK, 0.85), 0.8, true)
			ci.draw_polyline(VectorPaint.moved(rib, Vector2(-0.3, -0.5)), Color(1, 1, 1, 0.35), 0.4, true)


static func _front(ci: CanvasItem, pose: Dictionary) -> void:
	var sw: float = _swing(pose)
	var lunge: float = float(pose.lunge)
	var reach: float = 3.0 + lunge * 8.0
	_rags(ci, -22, 10.0, -6.0, sw * 1.2, RAG_BACK, false)
	for side: float in [-1.0, 1.0]:
		var step: float = sw * 2.2 * side
		_limb(ci, Vector2(side * 3, -9), Vector2(side * 4.2, -4.8 - step * 0.4), Vector2(side * 3.6, -1 - step), 2.0)
		_claws(ci, Vector2(side * 3.6, -0.8 - step), Vector2(side * 0.4, 1).normalized())
	_ribs(ci, Vector2(0, -16), 6.0)
	_rags(ci, -14, 8.5, -6.5, sw * 1.5, RAG, true)
	for side: float in [-1.0, 1.0]:
		var hand: Vector2 = Vector2(side * (10 + sw * side * 1.5), -8 + reach * 0.35)
		_limb(ci, Vector2(side * 6.5, -21), Vector2(side * 9.5, -14), hand, 2.2)
		_claws(ci, hand, Vector2(side * 0.3, 1).normalized())
	_head(ci, Vector2(0, -26 + lunge * 2.0), "down", maxf(lunge, 0.0) * 1.6)


static func _back(ci: CanvasItem, pose: Dictionary) -> void:
	var sw: float = _swing(pose)
	for side: float in [-1.0, 1.0]:
		var step: float = sw * 2.2 * side
		_limb(ci, Vector2(side * 3, -9), Vector2(side * 4.2, -4.8 + step * 0.4), Vector2(side * 3.6, -1 + step), 2.0)
	_rags(ci, -23, 10.5, -5.0, sw * 1.2, RAG, true)
	# The bent spine and shoulder blades push through the rags.
	for i: int in 5:
		var at: Vector2 = Vector2(sw * 0.3, -22 + i * 3.0)
		VectorPaint.painted(ci, VectorStyle.ellipse(at, 1.4 - i * 0.12, 1.0, 10), BONE, 0.6, 0.3, 0.6)
		VectorPaint.fill(ci, PackedVector2Array([at + Vector2(-0.5, -0.6), at + Vector2(0.5, -0.6), at + Vector2(0, -2.6)]), BONE)
	for side: float in [-1.0, 1.0]:
		VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(side * 4.5, -19), 2.8, 2.0, 12), SKIN_DARK, 1.0, 0.4, 0.8)
		_limb(ci, Vector2(side * 7, -20), Vector2(side * 10, -14), Vector2(side * 10.5, -8 - sw * side), 2.2)
		_claws(ci, Vector2(side * 10.5, -7.5 - sw * side), Vector2(side * 0.2, 1).normalized())
	_head(ci, Vector2(0, -27), "up", 0.0)


static func _side(ci: CanvasItem, pose: Dictionary) -> void:
	var sw: float = _swing(pose)
	var lunge: float = float(pose.lunge)
	_limb(ci, Vector2(-1, -20), Vector2(-4 - sw * 2.0, -14), Vector2(-2 - sw * 4.0, -9), 2.0)
	_claws(ci, Vector2(-2 - sw * 4.0, -8.5), Vector2(0.3, 1).normalized())
	for side: float in [-1.0, 1.0]:
		var step: float = sw * 3.6 * side
		_limb(ci, Vector2(0, -9), Vector2(step * 0.4 + 1.5, -5), Vector2(step, -1), 2.0)
		_claws(ci, Vector2(step + 0.5, -0.8), Vector2(1, 0.2).normalized())
	var hunch: PackedVector2Array = PackedVector2Array([Vector2(-9, -15), Vector2(-5, -22), Vector2(1, -24), Vector2(6, -21), Vector2(8, -15), Vector2(6, -8),
		Vector2(2, -4), Vector2(-3, -6.5), Vector2(-9, -3.5), Vector2(-8, -9)])
	VectorPaint.painted(ci, hunch, RAG, 2.6, 0.55)
	for i: int in 4:
		var at: Vector2 = Vector2(-4.5 + i * 2.6, -23.5 + absf(i - 1.5) * 0.8)
		VectorPaint.fill(ci, PackedVector2Array([at + Vector2(-0.7, 0.4), at + Vector2(0.7, 0.4), at + Vector2(-0.4, -2.0)]), BONE)
	ci.draw_colored_polygon(VectorStyle.ellipse(Vector2(1.5, -12), 1.3, 0.9, 8), Color(MOUTH, 0.8))
	VectorPaint.strand(ci, Vector2(-7, -4), Vector2(-9, -1), Vector2(-11, 3), 1.6, RAG.darkened(0.15))
	var head: Vector2 = Vector2(9.5 + lunge * 4.0, -18 + lunge)
	VectorPaint.strand(ci, Vector2(5, -20), Vector2(7, -20), head + Vector2(-3, 0), 3.2, SKIN_DARK)
	_head(ci, head, "side", maxf(lunge, 0.0) * 1.8)
	var hand: Vector2 = Vector2(11 + lunge * 9.0 + sw * 2.0, -12 + lunge * 2.0)
	_limb(ci, Vector2(3.5, -19), Vector2(7 + lunge * 3.0, -14), hand, 2.2)
	_claws(ci, hand, Vector2(1, 0.25).normalized())
