class_name ColossusPainter
## Paints the vector Bone Colossus (M15 P2, docs/M15_P2_BOSSES.md): a hulking heap of fused bone, thick leg columns, a
## ribcage with a violet soul glowing inside, plate shoulders with tusks, long arms with knuckled bone fists and a slab
## skull with violet pits (the boss role's colour). Pose units: feet at y 0, about 72 tall (SCALE makes the body ~94 world
## px; fists overhead reach the old sprite's ~118). frame() paints one sheet frame (sheet_layouts.gd COLOSSUS): idle, a
## lumbering walk, a two-fisted slam timed to the data's 0.6 s wind-up, the brace (a crouch that loops through the 1.0 s
## telegraph), the charge (head down, dust), the stun (swaying, bone dust circling) and a shattering collapse.

const BONE: Color = Color("e2dcc2")
const BONE_DARK: Color = Color("9d957b")
const BONE_SHADE: Color = Color("5f5944")
const BOSS_VIOLET: Color = Color("c27aff")
const PIT: Color = Color("120d1a")
const DUST: Color = Color("cdbfa8")
const SCALE: float = 1.3
const WINDUP_END: float = 0.6
const STRIKE_PEAK: float = 0.82
const PULL_BACK: float = -1.0
const LEAN: float = 0.3
## The skull is drawn this much bigger than its sketch coordinates.
const HEAD: float = 1.2


static func frame(ci: CanvasItem, anim: String, index: int, count: int) -> void:
	var a: Dictionary = VectorFrames.parse(anim)
	var state: String = a.state
	var cycle: float = float(index) / count
	var progress: float = float(index) / maxi(count - 1, 1)
	VectorStyle.shadow(ci, Vector2(0, 1), 24, 5.6)
	if state == "death":
		_shatter(ci, progress)
		return
	var pose: Dictionary = {"facing": a.facing, "phase": cycle, "walk": state == "walk", "raise": 0.0, "crouch": 0.0,
		"droop": 0.0, "flare": 0.0, "lean": 0.0, "stun": false}
	var offset: Vector2 = Vector2.ZERO
	match state:
		"idle":
			offset.y = sin(cycle * TAU) * 0.5
		"walk":
			offset.y = -absf(sin(cycle * TAU)) * 1.5
		"attack":
			pose.raise = _slam(progress)
			offset.y = maxf(-float(pose.raise), 0.0) * 3.0
		"brace":
			pose.crouch = 1.0
			pose.droop = 0.5
			pose.flare = 0.5 + 0.5 * sin(cycle * TAU * 2.0)
			offset = Vector2(sin(cycle * TAU * 4.0) * 0.5, 5.0)
		"charge":
			pose.lean = LEAN
			pose.droop = 0.8
			pose.flare = 1.0
			offset.y = -absf(sin(cycle * TAU * 2.0)) * 1.2
			_dust(ci, cycle, a.facing)
		"stun":
			pose.droop = 1.0
			pose.stun = true
			offset = Vector2(sin(cycle * TAU) * 2.2, 1.0)
	var lean: float = float(pose.lean) * (1.0 if a.facing == "side" else 0.0)
	ci.draw_set_transform(offset, lean, Vector2(1.0, 0.93) if state == "charge" and a.facing != "side" else Vector2.ONE)
	_figure(ci, pose)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if state == "stun":
		_stars(ci, cycle)


## The slam: 0 arms down, 1 fists overhead after the wind-up, then slammed (negative) at the peak and back up.
static func _slam(progress: float) -> float:
	var curve: float = VectorFrames.attack_curve(progress, WINDUP_END, STRIKE_PEAK, PULL_BACK)
	var raise: float = clampf(-curve, 0.0, 1.0)
	if progress >= STRIKE_PEAK:
		return -0.4 * (1.0 - smoothstep(STRIKE_PEAK, 1.0, progress))
	if progress >= WINDUP_END:
		return lerpf(1.0, -0.4, smoothstep(WINDUP_END, STRIKE_PEAK, progress))
	return raise


## Dust kicked up behind a charging Colossus.
static func _dust(ci: CanvasItem, cycle: float, facing: String) -> void:
	for k: int in 5:
		var t: float = fposmod(cycle + k * 0.2, 1.0)
		var at: Vector2 = Vector2((k - 2) * 9.0, -2.0 - t * 4.0)
		if facing == "side":
			at = Vector2(-12.0 - t * 22.0, -2.0 - t * 3.0 - (k % 2) * 3.0)
		ci.draw_circle(at, 3.0 + t * 5.0, Color(DUST, 0.5 * (1.0 - t)), true, -1.0, true)


## A ring of bone chips circling the lowered head.
static func _stars(ci: CanvasItem, cycle: float) -> void:
	for k: int in 4:
		var ang: float = cycle * TAU + k * PI * 0.5
		var at: Vector2 = Vector2(cos(ang) * 16.0, -62.0 + sin(ang) * 4.5)
		VectorPaint.painted(ci, VectorStyle.regular(at, 4, 2.4, 2.4, ang), BONE, 0.5, 0.2, 0.7)


static func _figure(ci: CanvasItem, pose: Dictionary) -> void:
	var facing: String = pose.facing
	var back: bool = facing == "up"
	var side: bool = facing == "side"
	var squeeze: float = 0.86 if side else 1.0
	var step: float = sin(float(pose.phase) * TAU) * (4.0 if pose.walk else 0.0)
	var breath: float = sin(float(pose.phase) * TAU) * 0.5 if not pose.walk else 0.0
	var crouch: float = float(pose.crouch)
	var drop: float = crouch * 6.0
	if side:
		_arm(ci, -1.0, pose, step, drop)
	_legs(ci, step, crouch, squeeze)
	_torso(ci, breath, squeeze, back, drop)
	if not side:
		_arm(ci, -1.0, pose, step, drop)
	_skull(ci, pose, drop)
	_arm(ci, 1.0, pose, -step, drop)


static func _legs(ci: CanvasItem, step: float, crouch: float, squeeze: float) -> void:
	for flip: float in [-1.0, 1.0]:
		var x: float = flip * 8.5 * squeeze
		var lift: float = maxf(step * flip, 0.0) * 0.6
		var hip: Vector2 = Vector2(x, -27.0 + crouch * 4.0)
		var knee: Vector2 = Vector2(x * 1.25 + (crouch * flip * 2.0), -14.0 + crouch * 1.5)
		var foot: Vector2 = Vector2(x * 1.1 + step * flip * (0.5 if squeeze == 1.0 else 0.9), -lift)
		VectorPaint.limb(ci, hip, knee, foot + Vector2(0, -3.0), 12.0, BONE_DARK)
		VectorPaint.painted(ci, VectorStyle.ellipse(knee, 6.4, 5.6, 14), BONE, 1.4, 0.5, 1.0)
		VectorPaint.painted(ci, VectorStyle.ellipse(foot + Vector2(1.5 * (1.0 if squeeze < 1.0 else 0.0), -1.6), 7.0, 3.2, 14), BONE, 1.2, 0.5, 1.0)
		for k: int in 3:
			VectorPaint.line(ci, foot + Vector2(-3.0 + k * 3.0, -3.8), foot + Vector2(-3.4 + k * 3.0, -0.4), Color(VectorStyle.INK, 0.6), 0.7)


static func _torso(ci: CanvasItem, breath: float, squeeze: float, back: bool, drop: float) -> void:
	var y: float = drop
	VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -28 + y), 13.0 * squeeze, 5.4, 16), BONE_DARK, 1.6, 0.5, 1.1)
	var cage: PackedVector2Array = VectorStyle.ellipse(Vector2(0, -45 + y - breath), 19.5 * squeeze, 15.0, 22)
	VectorPaint.painted(ci, cage, BONE_SHADE, 3.0, 0.5, 1.3)
	if not back:
		VectorStyle.draw_glow(ci, BOSS_VIOLET, Vector2(0, -45 + y), 12.0, 0.7)
	for i: int in 4:
		var ry: float = -53.0 + i * 5.2 + y - breath
		for flip: float in [-1.0, 1.0]:
			VectorPaint.strand(ci, Vector2(flip * 1.5, ry), Vector2(flip * 12.5 * squeeze, ry - 3.0), Vector2(flip * 18.5 * squeeze, ry + 3.6), 3.8, BONE)
	for k: int in 6:
		ci.draw_circle(Vector2(0, -56.0 + k * 4.2 + y - breath), 1.5, BONE_DARK if back else BONE, true, -1.0, true)
	if back:
		for flip: float in [-1.0, 1.0]:
			VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(flip * 9.0 * squeeze, -47 + y), 6.0 * squeeze, 8.0, 12), BONE_DARK, 1.4, 0.4, 1.0)


## An arm: plate shoulder with tusks, a long bone arm and a knuckled fist. `flip` -1 is the left (far in profile).
static func _arm(ci: CanvasItem, flip: float, pose: Dictionary, step: float, drop: float) -> void:
	var side: bool = pose.facing == "side"
	var raise: float = float(pose.raise)
	var shoulder: Vector2 = Vector2(flip * 21.0, -52.0 + drop)
	if side:
		shoulder = Vector2(flip * 5.0 + 1.0, -52.0 + drop)
	var swing: float = step * (0.5 if not side else 0.0)
	var rest: Vector2 = Vector2(flip * 26.0, -10.0 + drop * 0.6 + swing * flip * 0.4)
	if side:
		rest = Vector2(6.0 + flip * step * 0.9, -10.0 + drop * 0.6)
	if float(pose.crouch) > 0.0:
		rest = Vector2(flip * 18.0 if not side else 8.0, -14.0 + drop * 0.7)
	if bool(pose.stun):
		rest = Vector2(flip * 24.0 if not side else 2.0, -4.0)
	var fist: Vector2 = rest
	if raise > 0.0:
		fist = rest.lerp(Vector2(flip * 10.0 if not side else 12.0, -80.0), raise)
	elif raise < 0.0:
		fist = rest.lerp(Vector2(flip * 11.0 if not side else 14.0, -5.0), -raise * 2.2)
	var slam: float = maxf(-raise, 0.0)
	var elbow: Vector2 = shoulder.lerp(fist, 0.5) + Vector2(flip * (4.0 if not side else 0.0), 2.0 if raise >= 0.0 else 0.0)
	VectorPaint.limb(ci, shoulder, elbow, fist, 11.0, BONE_DARK)
	VectorPaint.painted(ci, VectorStyle.ellipse(elbow, 6.0, 5.6, 14), BONE, 1.4, 0.5, 1.0)
	VectorPaint.fill(ci, PackedVector2Array([elbow + Vector2(-1.5, -3.0), elbow + Vector2(1.5, -3.0), elbow + Vector2(flip * 1.0, -8.0)]), BONE)
	var r: float = 8.8 + slam * 1.4
	VectorPaint.painted(ci, VectorStyle.ellipse(fist, r, r * 0.9, 18), BONE, 2.2, 0.6, 1.2)
	for k: int in 4:
		var kn: Vector2 = fist + Vector2(-r * 0.6 + k * r * 0.4, r * 0.4)
		ci.draw_circle(kn, 1.7, BONE_DARK, true, -1.0, true)
	if not side or flip > 0.0:
		_pauldron(ci, shoulder, flip)


static func _pauldron(ci: CanvasItem, at: Vector2, flip: float) -> void:
	VectorPaint.painted(ci, VectorStyle.ellipse(at + Vector2(0, -2.0), 10.4, 7.2, 18), BONE, 2.6, 0.6, 1.2)
	for k: float in [-0.6, 0.6]:
		var base: Vector2 = at + Vector2(k * 7.0 + flip * 1.5, -7.0)
		VectorPaint.painted(ci, PackedVector2Array([base + Vector2(-3.0, 0), base + Vector2(3.0, 0), base + Vector2(k * 3.0 + flip * 2.0, -10.0)]), BONE, 0.6, 0.4, 0.9)


static func _skull(ci: CanvasItem, pose: Dictionary, drop: float) -> void:
	var facing: String = pose.facing
	var droop: float = float(pose.droop)
	var at: Vector2 = Vector2(0, -63.0 + drop + droop * 5.0)
	if facing == "side":
		at.x = 4.0 + droop * 2.0
	_skull_at(ci, at, facing, float(pose.flare))


static func _skull_at(ci: CanvasItem, at: Vector2, facing: String, flare: float) -> void:
	var k: float = HEAD
	var slab: PackedVector2Array = PackedVector2Array([at + Vector2(-9.4, -6.4) * k, at + Vector2(9.4, -6.4) * k, at + Vector2(10.4, 1.6) * k, at + Vector2(7.2, 8.0) * k, at + Vector2(-7.2, 8.0) * k, at + Vector2(-10.4, 1.6) * k])
	if facing == "side":
		slab = PackedVector2Array([at + Vector2(-7.0, -6.4) * k, at + Vector2(7.4, -6.4) * k, at + Vector2(10.4, 0.0) * k, at + Vector2(8.6, 8.0) * k, at + Vector2(-5.6, 8.0) * k, at + Vector2(-8.0, 1.4) * k])
	VectorPaint.painted(ci, slab, BONE, 2.6, 0.6, 1.4)
	if facing == "up":
		VectorPaint.line(ci, at + Vector2(0, -6) * k, at + Vector2(0, 7) * k, Color(BONE_SHADE, 0.8), 1.0)
		return
	var brow: PackedVector2Array = PackedVector2Array([at + Vector2(-9.6, -3.2) * k, at + Vector2(9.6, -3.2) * k, at + Vector2(9.6, -0.2) * k, at + Vector2(-9.6, -0.2) * k]) if facing == "down" else PackedVector2Array([at + Vector2(-3.0, -3.2) * k, at + Vector2(10.0, -3.2) * k, at + Vector2(10.0, -0.2) * k, at + Vector2(-3.0, -0.2) * k])
	VectorPaint.painted(ci, brow, BONE_DARK, 0.5, 0.2, 0.9)
	var pits: PackedFloat32Array = PackedFloat32Array([-4.4, 4.4]) if facing == "down" else PackedFloat32Array([4.6])
	for x: float in pits:
		var pit: Vector2 = at + Vector2(x, 2.4) * k
		VectorPaint.painted(ci, VectorStyle.ellipse(pit, 2.7, 2.9, 10), PIT, 0.4, 0.0, 0.0)
		VectorStyle.draw_glow(ci, BOSS_VIOLET, pit, 3.8 + flare * 3.8, 0.55 + flare * 0.4)
		ci.draw_circle(pit, 1.0, Color("f1d6ff"), true, -1.0, true)
	var tusks: PackedFloat32Array = PackedFloat32Array([-5.4, 5.4]) if facing == "down" else PackedFloat32Array([7.2])
	for x: float in tusks:
		VectorPaint.painted(ci, PackedVector2Array([at + Vector2(x - 2.0, 7.6) * k, at + Vector2(x + 2.0, 7.6) * k, at + Vector2(x, 13.6) * k]), BONE, 0.5, 0.4, 0.9)
	VectorPaint.line(ci, at + Vector2(-3.4, 6.8) * k, (at + Vector2(3.4, 6.8) * k) if facing == "down" else (at + Vector2(7.4, 6.8) * k), Color(VectorStyle.INK, 0.7), 0.9)


## The collapse: the pieces fly apart, tumble and fall, then lie still: skull, ribcage, two arms, legs.
static func _shatter(ci: CanvasItem, progress: float) -> void:
	var t: float = smoothstep(0.0, 0.8, progress)
	var fall: float = t * t
	var pose: Dictionary = {"facing": "down", "phase": 0.0, "walk": false, "raise": 0.0, "crouch": 0.0, "droop": 0.0, "flare": 0.0, "lean": 0.0, "stun": false}
	# legs sink and spread
	ci.draw_set_transform(Vector2(0, fall * 1.5), 0.0, Vector2(1.0 + t * 0.2, 1.0 - t * 0.35))
	_legs(ci, 0.0, t, 1.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# ribcage drops and tilts
	ci.draw_set_transform(Vector2(t * 3.0, fall * 16.0), t * 0.35, Vector2(1.0, 1.0 - t * 0.3))
	_torso(ci, 0.0, 1.0, false, 0.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# arms fly out to each side and land on the ground (turning about their shoulders)
	for flip: float in [-1.0, 1.0]:
		var shoulder: Vector2 = Vector2(flip * 21.0, -52.0)
		var turn: float = -flip * t * 1.0
		var travel: Vector2 = Vector2(-flip * t * 21.0, -t * 6.0 * (1.0 - t) + fall * 30.0)
		ci.draw_set_transform(shoulder + travel - shoulder.rotated(turn), turn, Vector2.ONE)
		_arm(ci, flip, pose, 0.0, 0.0)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# the skull pops up, then rolls down to the ground
	var hop: float = sin(clampf(t * 1.25, 0.0, 1.0) * PI) * 10.0
	var rest: Vector2 = Vector2(6.0 * t, -63.0 + 52.0 * fall - hop)
	_skull_at(ci, rest, "down", 1.0 - t)
	VectorStyle.draw_glow(ci, BOSS_VIOLET, Vector2(0, -45 + 30.0 * fall), 14.0 * (1.0 - t), 0.8 * (1.0 - t))
