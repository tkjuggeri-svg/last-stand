class_name BrutePainter
## Paints the vector Brute (M15, docs/M15_VECTOR.md): a slow armoured hulk, purple-grey flesh under iron plates and
## studded straps, spiked pauldrons, huge gauntleted fists, a brown loincloth, a bucket helm whose visor glows blue (the
## tank role's colour). Pose units: feet at y 0, about 48 tall and 40 wide. frame() paints one sheet frame
## (sheet_layouts.gd BRUTE): a heavy idle breath, a lumbering walk, a two-fisted overhead slam timed to the data's 0.6 s
## wind-up, and a toppling collapse.

## Lighter than first drawn: a Brute in the dark purple-greys vanished against the Crypt Road's ground in grayscale
## (test_readability): characters stay brighter than the ground.
const FLESH: Color = Color("b3a4d4")
const FLESH_DARK: Color = Color("6c5f92")
const IRON: Color = Color("aeb6ca")
const IRON_DARK: Color = Color("5a6078")
const CLOTH: Color = Color("94683f")
const LEATHER: Color = Color("4a3426")
## The figure's size against the old sprite (M15 Q2).
const SCALE: float = 1.12
const WINDUP_END: float = 0.6
const STRIKE_PEAK: float = 0.8
const PULL_BACK: float = -1.0


static func frame(ci: CanvasItem, anim: String, index: int, count: int) -> void:
	var a: Dictionary = VectorFrames.parse(anim)
	var state: String = a.state
	var facing: String = a.facing
	var cycle: float = float(index) / count
	var progress: float = float(index) / maxi(count - 1, 1)
	if state == "death":
		_death(ci, progress)
		return
	# For the slam, `raise` runs 0 (arms down) to 1 (fists overhead) in the wind-up, then -0.2 at the slam's end.
	var raise: float = 0.0
	if state == "attack":
		raise = clampf(-VectorFrames.attack_curve(progress, WINDUP_END, STRIKE_PEAK, PULL_BACK), 0.0, 1.0)
		if progress >= STRIKE_PEAK:
			raise = -0.25 * (1.0 - smoothstep(STRIKE_PEAK, 1.0, progress))
		elif progress >= WINDUP_END:
			raise = lerpf(1.0, -0.25, smoothstep(WINDUP_END, STRIKE_PEAK, progress))
	var pose: Dictionary = {"facing": facing, "walk": state == "walk", "phase": cycle, "raise": raise}
	VectorStyle.shadow(ci, Vector2(0, 3), 20, 7.0)
	var bob: float = -absf(sin(cycle * TAU)) * 1.6 if state == "walk" else sin(cycle * TAU) * 0.7
	var slam: float = maxf(-raise, 0.0) * 5.0
	ci.draw_set_transform(Vector2(0, bob + slam), 0.0, Vector2.ONE)
	paint(ci, pose)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	VectorStyle.draw_glow(ci, VectorStyle.COLD_GLOW, Vector2(0, -22 + bob), 30.0, 0.1)
	_visor_glow(ci, pose, bob + slam)


static func paint(ci: CanvasItem, pose: Dictionary) -> void:
	match String(pose.facing):
		"up":
			_back(ci, pose)
		"side":
			_side(ci, pose)
		_:
			_front(ci, pose)


static func _step(pose: Dictionary) -> float:
	return sin(float(pose.phase) * TAU) * (3.0 if pose.walk else 0.0)


static func _leg(ci: CanvasItem, x: float, lift: float) -> void:
	VectorPaint.painted(ci, PackedVector2Array([Vector2(x - 5.5, -18), Vector2(x + 5.5, -18), Vector2(x + 5.0, -3 - lift), Vector2(x - 5.0, -3 - lift)]), FLESH_DARK, 2.4)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(x - 5.0, -12), Vector2(x + 5.0, -12), Vector2(x + 4.6, -5 - lift), Vector2(x - 4.6, -5 - lift)]), IRON_DARK, 1.6)
	VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(x, -11.5), 4.6, 3.4, 14), IRON, 1.6)
	VectorPaint.rivet(ci, Vector2(x, -11.5), 0.9)
	VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(x + 0.5, -2.2 - lift), 6.2, 2.8, 14), IRON_DARK, 1.2)


static func _loincloth(ci: CanvasItem, width: float, sway: float) -> void:
	var cloth: PackedVector2Array = PackedVector2Array([Vector2(-width, -22), Vector2(width, -22), Vector2(width + 1, -9)])
	for i: int in 6:
		cloth.append(Vector2(lerpf(width, -width, i / 5.0) + sway * 0.4, -8.0 + (2.5 if i % 2 == 0 else -0.5)))
	cloth.append(Vector2(-width - 1, -9))
	VectorPaint.painted(ci, cloth, CLOTH, 2.0, 0.4)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-width, -23), Vector2(width, -23), Vector2(width, -20.5), Vector2(-width, -20.5)]), LEATHER, 1.0, 0.2, 0.8)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-1.8, -23.4), Vector2(1.8, -23.4), Vector2(1.8, -20.2), Vector2(-1.8, -20.2)]), IRON, 0.8, 0.0, 0.7)


static func _torso(ci: CanvasItem, top: float, width: float, breath: float) -> void:
	var chest: PackedVector2Array = PackedVector2Array([Vector2(-width, top - breath), Vector2(width, top - breath), Vector2(width - 2.5, -22), Vector2(-width + 2.5, -22)])
	VectorPaint.painted(ci, chest, FLESH, 3.4, 0.6)
	for k: int in 3:
		var y: float = top + 7.0 + k * 3.4
		ci.draw_arc(Vector2(0, y - 9), width * 0.8, PI * 0.28, PI * 0.72, 12, Color(FLESH_DARK, 0.8), 0.9, true)


static func _strap(ci: CanvasItem, from: Vector2, to: Vector2) -> void:
	var dir: Vector2 = (to - from).normalized()
	var side: Vector2 = dir.orthogonal()
	VectorPaint.painted(ci, PackedVector2Array([from + side * 1.8, to + side * 1.8, to - side * 1.8, from - side * 1.8]), LEATHER, 0.8, 0.2, 0.8)
	for k: int in 4:
		VectorPaint.rivet(ci, from.lerp(to, (k + 0.5) / 4.0), 0.8)


static func _pauldron(ci: CanvasItem, at: Vector2, side: float) -> void:
	VectorPaint.painted(ci, VectorStyle.ellipse(at, 7.0, 5.6, 18), IRON, 3.0, 0.6)
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-5.6 * side, 2), at + Vector2(5.6 * side, 2.4), at + Vector2(5.0 * side, 5.0), at + Vector2(-4.4 * side, 4.6)]), IRON_DARK, 1.2)
	for k: float in [-1.0, 0.0, 1.0]:
		var base: Vector2 = at + Vector2(k * 3.0, -4.4 + absf(k) * 1.0)
		VectorPaint.fill(ci, PackedVector2Array([base + Vector2(-1.5, 0), base + Vector2(1.5, 0), base + Vector2(k * 1.2, -5.5)]), Color("c7ccd8"))
	VectorPaint.rivet(ci, at + Vector2(0, 0.5), 0.9)


## An arm from the shoulder to a fist at `fist`, with a gauntlet; `slam` makes the fist larger as it lands.
static func _arm(ci: CanvasItem, shoulder: Vector2, fist: Vector2, slam: float) -> void:
	var elbow: Vector2 = shoulder.lerp(fist, 0.5) + Vector2(signf(shoulder.x) * 3.0, 1.0)
	VectorPaint.limb(ci, shoulder, elbow, fist, 6.6, FLESH)
	VectorPaint.painted(ci, VectorStyle.ellipse(elbow, 4.2, 4.0, 14), IRON, 1.6)
	VectorPaint.rivet(ci, elbow, 0.8)
	var r: float = 5.4 + slam * 1.0
	VectorPaint.painted(ci, VectorStyle.ellipse(fist, r, r * 0.92, 18), IRON, 2.2, 0.6)
	for k: int in 3:
		VectorPaint.line(ci, fist + Vector2(-r * 0.6 + k * r * 0.6, -r * 0.5), fist + Vector2(-r * 0.6 + k * r * 0.6, r * 0.6), Color(VectorStyle.INK, 0.6), 0.8)
	VectorPaint.painted(ci, PackedVector2Array([fist + Vector2(-r * 0.7, -r * 0.2 - 1.8), fist + Vector2(r * 0.7, -r * 0.2 - 1.8), fist + Vector2(r * 0.7, -r * 0.2), fist + Vector2(-r * 0.7, -r * 0.2)]), IRON_DARK, 0.6, 0.0, 0.6)


static func _helm(ci: CanvasItem, at: Vector2, facing: String) -> void:
	var shell: PackedVector2Array = PackedVector2Array([at + Vector2(-6.6, -2), at + Vector2(-4.6, -7), at + Vector2(4.6, -7), at + Vector2(6.6, -2), at + Vector2(6.2, 5), at + Vector2(-6.2, 5)])
	if facing == "side":
		shell = PackedVector2Array([at + Vector2(-5.6, -2), at + Vector2(-3.6, -7), at + Vector2(4.6, -6.6), at + Vector2(7.0, -1), at + Vector2(6.4, 5), at + Vector2(-5.6, 5)])
	VectorPaint.painted(ci, shell, IRON, 2.8, 0.6)
	VectorPaint.line(ci, at + Vector2(-5.6, -3.4), at + Vector2(5.6, -3.4), Color(VectorStyle.INK, 0.5), 0.8)
	if facing == "down":
		VectorPaint.fill(ci, PackedVector2Array([at + Vector2(-5.0, -0.6), at + Vector2(5.0, -0.6), at + Vector2(5.0, 1.6), at + Vector2(-5.0, 1.6)]), Color("0d0a14"))
		for x: float in [-3.0, 3.0]:
			VectorPaint.fill(ci, PackedVector2Array([at + Vector2(x - 1.4, 0), at + Vector2(x + 1.4, 0), at + Vector2(x + 1.4, 1.0), at + Vector2(x - 1.4, 1.0)]), VectorStyle.ROLE_TANK)
		VectorPaint.line(ci, at + Vector2(0, -7), at + Vector2(0, 5), Color(1, 1, 1, 0.3), 0.9)
	elif facing == "side":
		VectorPaint.fill(ci, PackedVector2Array([at + Vector2(1.5, -0.6), at + Vector2(7.0, -0.6), at + Vector2(7.0, 1.6), at + Vector2(1.5, 1.6)]), Color("0d0a14"))
		VectorPaint.fill(ci, PackedVector2Array([at + Vector2(3.4, 0), at + Vector2(6.2, 0), at + Vector2(6.2, 1.0), at + Vector2(3.4, 1.0)]), VectorStyle.ROLE_TANK)
	VectorStyle.shine(ci, at + Vector2(-2.5, -4.6), 2.2, 1.2, 0.45)


static func _front(ci: CanvasItem, pose: Dictionary) -> void:
	var step: float = _step(pose)
	var raise: float = float(pose.raise)
	var breath: float = sin(float(pose.phase) * TAU) * 0.6 if not pose.walk else 0.0
	_leg(ci, -7, step)
	_leg(ci, 7, -step)
	_loincloth(ci, 11.0, step * 0.4)
	_torso(ci, -42, 13.0, breath)
	_strap(ci, Vector2(-11, -39), Vector2(10, -24))
	_strap(ci, Vector2(11, -39), Vector2(-10, -24))
	VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -42 - breath), 8.5, 3.4, 16), IRON_DARK, 1.2)
	_arm_pair(ci, raise, step, -42 - breath, 15.0)
	_helm(ci, Vector2(0, -47 - breath), "down")


## Both arms and pauldrons: down at the sides, fists swinging; raised, fists over the head; slammed, fists in front.
static func _arm_pair(ci: CanvasItem, raise: float, step: float, shoulder_y: float, spread: float) -> void:
	for side: float in [-1.0, 1.0]:
		var shoulder: Vector2 = Vector2(side * spread, shoulder_y + 3.0)
		var rest: Vector2 = Vector2(side * (spread + 3.0), -17 + step * side * 0.8)
		var up: Vector2 = Vector2(side * 9.0, shoulder_y - 16.0)
		var fist: Vector2 = rest.lerp(up, clampf(raise, 0.0, 1.0)) if raise >= 0.0 else rest.lerp(Vector2(side * 8.0, -10.0), -raise * 3.0)
		_arm(ci, shoulder, fist, maxf(-raise, 0.0))
		_pauldron(ci, shoulder + Vector2(0, -2.5), side)


static func _back(ci: CanvasItem, pose: Dictionary) -> void:
	var step: float = _step(pose)
	var raise: float = float(pose.raise)
	_leg(ci, -7, -step)
	_leg(ci, 7, step)
	_loincloth(ci, 11.0, -step * 0.4)
	_torso(ci, -42, 13.5, 0.0)
	_strap(ci, Vector2(-11, -39), Vector2(10, -24))
	_strap(ci, Vector2(11, -39), Vector2(-10, -24))
	for k: int in 5:
		VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -39 + k * 3.6), 1.6, 1.3, 8), FLESH_DARK, 0.6, 0.3, 0.6)
	_helm(ci, Vector2(0, -47), "up")
	_arm_pair(ci, raise, -step, -42, 15.0)


static func _side(ci: CanvasItem, pose: Dictionary) -> void:
	var step: float = _step(pose)
	var raise: float = float(pose.raise)
	var breath: float = sin(float(pose.phase) * TAU) * 0.6 if not pose.walk else 0.0
	# The far arm behind the body, then legs, body, head, and the near arm in front.
	var far_fist: Vector2 = Vector2(-3.0 - step * 0.6, -17.0).lerp(Vector2(7.0, -56.0), clampf(raise, 0.0, 1.0)) if raise >= 0.0 else Vector2(10.0, -10.0)
	_arm(ci, Vector2(-1, -39), far_fist, maxf(-raise, 0.0))
	_leg(ci, -3, step)
	_leg(ci, 4, -step)
	_loincloth(ci, 10.5, step * 0.4)
	_torso(ci, -42, 12.5, breath)
	_strap(ci, Vector2(-10, -39), Vector2(10, -24))
	_helm(ci, Vector2(3, -47 - breath), "side")
	var near_fist: Vector2 = Vector2(5.0 + step * 0.8, -17.0).lerp(Vector2(11.0, -58.0), clampf(raise, 0.0, 1.0)) if raise >= 0.0 else Vector2(12.0, -10.0)
	_arm(ci, Vector2(2, -39), near_fist, maxf(-raise, 0.0))
	_pauldron(ci, Vector2(1, -42.5 - breath), 1.0)


static func _visor_glow(ci: CanvasItem, pose: Dictionary, shift: float) -> void:
	match String(pose.facing):
		"up":
			pass
		"side":
			VectorStyle.draw_glow(ci, VectorStyle.ROLE_TANK, Vector2(7.0, -46 + shift), 5.0, 0.65)
		_:
			for x: float in [-3.0, 3.0]:
				VectorStyle.draw_glow(ci, VectorStyle.ROLE_TANK, Vector2(x, -46.5 + shift), 4.4, 0.6)


## It staggers, topples forward onto its fists and lies still, the fists spread.
static func _death(ci: CanvasItem, progress: float) -> void:
	var fall: float = smoothstep(0.1, 0.9, progress)
	VectorStyle.shadow(ci, Vector2(0, 3), 20.0 + fall * 6.0, 7.0 + fall * 2.0)
	ci.draw_set_transform(Vector2(fall * 4.0, fall * 20.0), fall * 0.3, Vector2(1.0 + fall * 0.15, 1.0 - fall * 0.5))
	paint(ci, {"facing": "down", "walk": false, "phase": 0.0, "raise": 0.0})
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if progress < 0.55:
		VectorStyle.draw_glow(ci, VectorStyle.ROLE_TANK, Vector2(fall * 4.0 - 1.0, -46.5 + fall * 12.0), 4.0, 0.6 * (1.0 - progress / 0.55))
