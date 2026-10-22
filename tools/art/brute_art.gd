extends RefCounted
## The Brute (dev-time art generator): a hulking, stitched-together corpse of bruised violet-grey
## flesh, massive shoulders with bone spurs, a small sunken head with an underbite and red eyes, an
## iron collar, shackles with chain ends on the wrists and two huge fists. It must read as "big and
## slow" at a glance: the frame is 48x48 art px (the Ghoul's is 32) and the feet stand on FEET.

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")
const Undead: GDScript = preload("res://tools/art/undead_fx.gd")

const SIZE: Vector2i = Vector2i(48, 48)
const FEET: Vector2 = Vector2(24, 44)
const WALK_FRAMES: int = 6
const ATTACK_FRAMES: int = 8


## Rows in the order of sheet_layouts.BRUTE.
func sheet_rows() -> Array[Array]:
	var rows: Array[Array] = []
	for facing: String in ["down", "up", "side"]:
		var idle: Array[Image] = []
		for i: int in 4:
			idle.append(frame(facing, _idle_pose(facing, i)))
		rows.append(idle)
	for facing: String in ["down", "up", "side"]:
		var walk: Array[Image] = []
		for i: int in WALK_FRAMES:
			walk.append(frame(facing, _walk_pose(facing, i)))
		rows.append(walk)
	rows.append(_death_frames())
	for facing: String in ["down", "up", "side"]:
		var attack: Array[Image] = []
		for i: int in ATTACK_FRAMES:
			attack.append(frame(facing, _attack_pose(facing, i)))
		rows.append(attack)
	return rows


# ---------------------------------------------------------------- poses

## Fists are absolute art positions. Front/back: fist_l is on the screen left. Side (facing right):
## fist_l is the far arm, fist_r the near arm.
func _base_pose(facing: String) -> Dictionary:
	var pose: Dictionary = {"body": Vector2.ZERO, "head": Vector2.ZERO, "lift_l": 0.0, "lift_r": 0.0,
		"stride": 0.0, "mouth": false, "smear": false, "dust": false}
	if facing == "side":
		pose["fist_l"] = Vector2(27, 35)
		pose["fist_r"] = Vector2(30, 37)
	else:
		pose["fist_l"] = Vector2(11.5, 36)
		pose["fist_r"] = Vector2(36.5, 36)
	return pose


## Slow, heavy breathing: the chest rises, the fists sway a little.
func _idle_pose(facing: String, i: int) -> Dictionary:
	var pose: Dictionary = _base_pose(facing)
	var breath: int = [0, 0, 1, 1][i]
	pose["body"] = Vector2(0, -breath)
	pose["head"] = Vector2(0, -breath + [0, 0, 0, 1][i])
	pose["fist_l"] = (pose["fist_l"] as Vector2) + Vector2(0, [0, 1, 1, 0][i])
	pose["fist_r"] = (pose["fist_r"] as Vector2) + Vector2(0, [1, 1, 0, 0][i])
	return pose


## A lumbering stomp: the whole bulk rolls onto each leg in turn, fists swinging the other way.
func _walk_pose(facing: String, i: int) -> Dictionary:
	var t: float = TAU * i / WALK_FRAMES
	var pose: Dictionary = _base_pose(facing)
	var bob: float = 1.0 if absf(cos(t)) > 0.7 else 0.0  # lands heavily on each step
	if facing == "side":
		pose["stride"] = sin(t)
		pose["body"] = Vector2(0, bob)
		pose["head"] = Vector2(0, bob)
		pose["fist_l"] = Vector2(27 - sin(t) * 3.0, 35 + bob)
		pose["fist_r"] = Vector2(30 + sin(t) * 3.0, 37 + bob)
	else:
		var roll: float = roundf(sin(t) * 1.2)
		pose["lift_l"] = maxf(sin(t), 0.0) * 2.5
		pose["lift_r"] = maxf(-sin(t), 0.0) * 2.5
		pose["body"] = Vector2(roll, bob)
		pose["head"] = Vector2(roll, bob)
		pose["fist_l"] = Vector2(11.5 + roll, 36 + bob - roundf(sin(t)))
		pose["fist_r"] = Vector2(36.5 + roll, 36 + bob + roundf(sin(t)))
	return pose


## 0-5 the fists rise together high over the head (6 frames at 10 fps = the data's 0.6 s wind-up),
## 6 the slam into the ground in front (smear, dust), 7 recover.
func _attack_pose(facing: String, i: int) -> Dictionary:
	var pose: Dictionary = _base_pose(facing)
	pose["mouth"] = i >= 2 and i <= 6
	pose["smear"] = i == 6
	pose["dust"] = i == 6 or i == 7
	var rise: float = [0.15, 0.35, 0.6, 0.85, 1.0, 1.0][i] if i < 6 else 0.0
	match facing:
		"down", "up":
			var high: Vector2 = Vector2(19.5, 6.5) if facing == "down" else Vector2(20.5, 5.5)
			pose["body"] = Vector2(0, -roundf(rise * 2.0)) if i < 6 else Vector2(0, 2.0 if i == 6 else 1.0)
			pose["head"] = pose["body"]
			if i < 6:
				pose["fist_l"] = Vector2(11.5, 36).lerp(high, rise)
			elif facing == "down":
				pose["fist_l"] = Vector2(19, 42) if i == 6 else Vector2(15, 39)
			else:
				pose["fist_l"] = Vector2(19, 26) if i == 6 else Vector2(15, 33)
			var fist_l: Vector2 = pose["fist_l"]
			pose["fist_r"] = Vector2(48 - fist_l.x, fist_l.y)
		"side":
			pose["body"] = Vector2(-roundf(rise * 2.0), -roundf(rise * 1.0)) if i < 6 else Vector2(2.0 if i == 6 else 1.0, 1.0)
			pose["head"] = pose["body"]
			if i < 6:
				pose["fist_r"] = Vector2(30, 37).lerp(Vector2(22, 7), rise)
				pose["fist_l"] = Vector2(27, 35).lerp(Vector2(20, 6), rise)
			else:
				pose["fist_r"] = Vector2(39, 41) if i == 6 else Vector2(35, 39)
				pose["fist_l"] = Vector2(37, 40) if i == 6 else Vector2(33, 38)
			pose["stride"] = -0.3 * rise if i < 6 else 0.6
	return pose


# ---------------------------------------------------------------- frames

func frame(facing: String, pose: Dictionary) -> Image:
	var c: Canvas = _draw(facing, pose)
	if pose["dust"]:
		_dust(c, facing, pose)
	c.finish()
	_rim_light(c.image)
	c.ground_shadow(FEET + Vector2(0, -0.5), Vector2(11.0, 3.2))
	return c.image


func _draw(facing: String, pose: Dictionary) -> Canvas:
	var c: Canvas = Canvas.new(SIZE.x, SIZE.y)
	match facing:
		"down":
			_draw_front(c, pose, true)
		"up":
			_draw_front(c, pose, false)
		_:
			_draw_side(c, pose)
	return c


## Front and back views share the bulk; the face, belly stitches and chest differ.
func _draw_front(c: Canvas, pose: Dictionary, front: bool) -> void:
	var body: Vector2 = pose["body"]
	var head_at: Vector2 = Vector2(24, 18.5) + (pose["head"] as Vector2)
	var fist_l: Vector2 = pose["fist_l"]
	var fist_r: Vector2 = pose["fist_r"]
	var fists_up: bool = fist_l.y < 24.0
	if not front:
		_head(c, head_at + Vector2(0, 0.5), "up", false)
	# Short, thick legs and big feet.
	var hip_y: float = 34.5 + body.y * 0.5
	_leg(c, Vector2(19.5 + body.x * 0.5, hip_y), Vector2(18.5, FEET.y - 1.5 - float(pose["lift_l"])), 0.0)
	_leg(c, Vector2(28.5 + body.x * 0.5, hip_y), Vector2(29.5, FEET.y - 1.5 - float(pose["lift_r"])), 0.0)
	# A ragged loincloth under a heavy belt.
	c.part()
	var r: Vector2 = Vector2(body.x * 0.5, body.y)
	c.polygon(PackedVector2Array([Vector2(16.5, 32) + r, Vector2(31.5, 32) + r, Vector2(32, 37.5) + r, Vector2(29.5, 36.5) + r,
		Vector2(27.5, 39) + r, Vector2(25, 36.8) + r, Vector2(22.5, 39.2) + r, Vector2(20.2, 36.6) + r, Vector2(18, 38.2) + r,
		Vector2(16, 37) + r]), P.RAGS, Vector3(-0.2, -0.1, 1))
	# The barrel of a torso, with a sagging belly.
	c.part()
	c.ellipse(Vector2(24, 27) + body, Vector2(9.0, 7.6), P.BRUTE_SKIN, 0.0, -0.03)
	c.part()
	c.ellipse(Vector2(24, 30.5) + body, Vector2(6.6, 4.4), P.BRUTE_SKIN, 0.0, 0.02 if front else -0.06)
	c.part()
	c.rect(Rect2i(roundi(16.5 + body.x * 0.5), roundi(32.5 + body.y), 15, 2), P.LEATHER[1])
	c.px(roundi(23.5 + body.x * 0.5), roundi(32.5 + body.y), P.IRON[4])  # buckle
	c.px(roundi(24.5 + body.x * 0.5), roundi(33.5 + body.y), P.IRON[3])
	if front:
		# Crude stitches across the chest and belly (where the corpse was sewn together).
		_stitches(c, Vector2(18.5, 22.5) + body, Vector2(23, 31) + body)
		_stitches(c, Vector2(29.5, 24) + body, Vector2(26, 29.5) + body)
		c.line(Vector2(20, 26) + body, Vector2(22, 27) + body, P.BRUTE_SKIN[1])  # chest crease
		c.line(Vector2(28, 26) + body, Vector2(26, 27) + body, P.BRUTE_SKIN[1])
	else:
		for k: int in 5:
			c.px(roundi(24 + body.x), roundi(21.5 + body.y + k * 1.8), P.BRUTE_SKIN[4] if k % 2 == 0 else P.BRUTE_SKIN[1])
		_stitches(c, Vector2(17.5, 23.5) + body, Vector2(30.5, 27.5) + body)
	# Massive shoulders with bone spurs breaking through.
	var shoulder_l: Vector2 = Vector2(15, 21.5) + body
	var shoulder_r: Vector2 = Vector2(33, 21.5) + body
	if fists_up:
		_arm(c, shoulder_l, fist_l, -1.0, pose["smear"])
		_arm(c, shoulder_r, fist_r, 1.0, pose["smear"])
	for s: Vector2 in [shoulder_l, shoulder_r]:
		c.part()
		c.ellipse(s, Vector2(4.4, 3.8), P.BRUTE_SKIN, 0.0, 0.04)
		c.part()
		var out: float = -1.0 if s.x < 24.0 else 1.0
		c.polygon(PackedVector2Array([s + Vector2(-1.2 * out, -2.6), s + Vector2(1.8 * out, -6.2), s + Vector2(1.6 * out, -2.2)]),
			P.BONE, Vector3(-0.4, -0.5, 1))
	# The iron collar.
	c.part()
	c.ellipse(Vector2(24, 21.8) + body, Vector2(4.6, 1.5), P.IRON, 0.4, 0.05)
	if front:
		_head(c, head_at, "down", pose["mouth"])
	if not fists_up:
		_arm(c, shoulder_l, fist_l, -1.0, pose["smear"])
		_arm(c, shoulder_r, fist_r, 1.0, pose["smear"])


## Side view, facing right: a hunched back and hump, the head thrust forward low, arms hanging long.
func _draw_side(c: Canvas, pose: Dictionary) -> void:
	var body: Vector2 = pose["body"]
	var stride: float = pose["stride"]
	var shoulder: Vector2 = Vector2(26, 22) + body
	var fists_up: bool = (pose["fist_r"] as Vector2).y < 24.0
	_arm(c, shoulder + Vector2(-2, -0.5), pose["fist_l"], 1.0, false, -0.14)
	var hip: Vector2 = Vector2(21, 34) + Vector2(body.x * 0.5, body.y * 0.5)
	_leg(c, hip + Vector2(1, 0), Vector2(22 - stride * 4.0, FEET.y - 1.5 - maxf(-stride, 0.0) * 2.0), -0.14, true)
	_leg(c, hip, Vector2(21 + stride * 4.0, FEET.y - 1.5 - maxf(stride, 0.0) * 2.0), 0.0, true)
	c.part()
	c.polygon(PackedVector2Array([Vector2(15, 31.5) + body, Vector2(26, 32) + body, Vector2(27, 37) + body,
		Vector2(24.5, 36) + body, Vector2(22.5, 38.6) + body, Vector2(19.8, 36.4) + body, Vector2(16.8, 38) + body,
		Vector2(14.6, 36.2) + body]), P.RAGS, Vector3(0, -0.1, 1))
	# Torso: a hump of a back, the belly hanging in front.
	c.part()
	c.ellipse(Vector2(21, 26.5) + body, Vector2(7.6, 7.8), P.BRUTE_SKIN, 0.0, -0.04)
	c.part()
	c.ellipse(Vector2(24.5, 30.5) + body, Vector2(5.0, 4.6), P.BRUTE_SKIN, 0.0, 0.0)
	c.part()
	c.rect(Rect2i(roundi(15 + body.x), roundi(32 + body.y), 14, 2), P.LEATHER[1])
	for k: int in 4:
		c.px(roundi(16.5 + k * 1.6 + body.x), roundi(20.5 + body.y + absf(k - 1.5) * 0.8), P.BRUTE_SKIN[4])
	_stitches(c, Vector2(16, 24) + body, Vector2(21, 31) + body)
	c.part()
	c.ellipse(shoulder, Vector2(4.6, 4.0), P.BRUTE_SKIN, 0.0, 0.04)
	c.part()
	c.polygon(PackedVector2Array([shoulder + Vector2(-2.5, -2.4), shoulder + Vector2(-4.8, -6.4), shoulder + Vector2(-0.6, -3.4)]),
		P.BONE, Vector3(-0.4, -0.5, 1))
	c.part()
	c.ellipse(shoulder + Vector2(3.4, 0.2), Vector2(1.6, 2.2), P.IRON, 0.4, 0.0)  # collar, seen edge-on
	if fists_up:
		_arm(c, shoulder, pose["fist_r"], 1.0, pose["smear"])
	_head(c, Vector2(31, 22.5) + (pose["head"] as Vector2), "side", pose["mouth"])
	if not fists_up:
		_arm(c, shoulder, pose["fist_r"], 1.0, pose["smear"])


## A 1 px rim of light along the silhouette's top-left edges (the key light's side), so the big
## dark bulk reads against the ground even under the dusk light.
func _rim_light(img: Image) -> void:
	var src: Image = img.duplicate() as Image
	for y: int in range(1, img.get_height()):
		for x: int in range(1, img.get_width()):
			var c: Color = src.get_pixel(x, y)
			if c.a < 1.0 or c.is_equal_approx(Canvas.OUTLINE):
				continue
			if src.get_pixel(x - 1, y).is_equal_approx(Canvas.OUTLINE) or src.get_pixel(x, y - 1).is_equal_approx(Canvas.OUTLINE):
				img.set_pixel(x, y, c.lerp(P.BRUTE_SKIN[5], 0.45))


# ---------------------------------------------------------------- body parts

func _leg(c: Canvas, hip: Vector2, foot: Vector2, bias: float, side: bool = false) -> void:
	var knee: Vector2 = hip.lerp(foot, 0.5) + (Vector2(1.4, 0) if side else Vector2((hip.x - 24) * 0.12, 0))
	c.part()
	c.capsule(hip, knee, 2.8, P.BRUTE_SKIN, bias - 0.04)
	c.capsule(knee, foot, 2.4, P.BRUTE_SKIN, bias - 0.08)
	c.part()
	c.ellipse(foot + (Vector2(1.4, 0.4) if side else Vector2(0, 0.5)), Vector2(3.2 if side else 2.8, 1.5), P.BRUTE_SKIN, 0.0, bias - 0.12)


## A thick arm ending in a huge fist, with an iron shackle and a dangling chain end on the wrist.
func _arm(c: Canvas, shoulder: Vector2, fist: Vector2, side: float, smear: bool, bias: float = 0.0) -> void:
	var elbow: Vector2 = shoulder.lerp(fist, 0.5) + Vector2(side * 1.8, 0.5)
	c.part()
	c.capsule(shoulder, elbow, 2.6, P.BRUTE_SKIN, bias - 0.02)
	c.capsule(elbow, fist, 2.2, P.BRUTE_SKIN, bias - 0.05)
	var wrist: Vector2 = elbow.lerp(fist, 0.68)
	c.part()
	c.capsule(wrist - (fist - elbow).normalized() * 0.8, wrist + (fist - elbow).normalized() * 0.8, 2.6, P.IRON, bias)
	c.part()
	c.ellipse(fist, Vector2(3.3, 3.0), P.BRUTE_SKIN, 0.0, bias + 0.03)
	var f: Vector2i = Vector2i(fist.round())
	c.line(Vector2(f.x - 2, f.y), Vector2(f.x + 1, f.y), P.BRUTE_SKIN[1])  # knuckle crease
	# Two broken chain links hanging from the shackle (iron, 1 px each).
	c.part()
	var hang: Vector2 = wrist + Vector2(side * 2.2, 1.6)
	c.px(roundi(hang.x), roundi(hang.y), P.IRON[3])
	c.px(roundi(hang.x), roundi(hang.y + 1.0), P.IRON[1])
	c.px(roundi(hang.x + side), roundi(hang.y + 2.0), P.IRON[3])
	if smear:
		c.part(true)
		for k: int in [-1, 0, 1]:
			var tip: Vector2 = fist + Vector2(k * 1.6, -3.0)
			c.line(tip - Vector2(0, 9.0), tip, Color(0.88, 0.85, 0.95, 0.55))


## A sewn seam: a dark cut with short pale-thread ticks across it every few pixels.
func _stitches(c: Canvas, a: Vector2, b: Vector2) -> void:
	c.line(a, b, P.BRUTE_SKIN[0])
	var across: Vector2 = (b - a).normalized().orthogonal()
	var steps: int = maxi(roundi(a.distance_to(b) / 3.0), 1)
	for k: int in range(1, steps):
		var p: Vector2 = a.lerp(b, float(k) / steps)
		c.px(roundi(p.x + across.x), roundi(p.y + across.y), P.RAGS[3])
		c.px(roundi(p.x - across.x), roundi(p.y - across.y), P.BRUTE_SKIN[1])


## A small head sunk between the shoulders: heavy brow, burning eyes, an underbite with tusks.
func _head(c: Canvas, at: Vector2, facing: String, mouth_open: bool) -> void:
	c.part()
	match facing:
		"down":
			c.ellipse(at, Vector2(3.8, 3.5), P.BRUTE_SKIN, 0.0, 0.05)
			var e: Vector2i = Vector2i(at.round())
			c.line(Vector2(e.x - 3, e.y - 1), Vector2(e.x + 2, e.y - 1), P.BRUTE_SKIN[1])  # brow
			for dx: int in [-2, 1]:
				c.px(e.x + dx + (1 if dx < 0 else 0), e.y, P.EYES_TANK[2])
				c.px(e.x + dx + (0 if dx < 0 else 1), e.y, P.EYES_TANK[1])
			c.rect(Rect2i(e.x - 2, e.y + 2, 4, 2 if mouth_open else 1), P.OUTLINE)
			c.px(e.x - 2, e.y + 1, P.BONE[3])  # tusks
			c.px(e.x + 1, e.y + 1, P.BONE[2])
			c.px(e.x - 1, e.y - 3, P.BRUTE_SKIN[1])  # stitched scalp
			c.px(e.x + 1, e.y - 3, P.BRUTE_SKIN[1])
		"up":
			c.ellipse(at, Vector2(3.6, 3.3), P.BRUTE_SKIN, 0.0, -0.02)
			var e2: Vector2i = Vector2i(at.round())
			c.line(Vector2(e2.x - 2, e2.y - 2), Vector2(e2.x + 2, e2.y), P.BRUTE_SKIN[1])
			c.px(e2.x - 1, e2.y + 1, P.BRUTE_SKIN[1])
		_:
			c.ellipse(at, Vector2(3.2, 3.1), P.BRUTE_SKIN, 0.0, 0.05)
			var e3: Vector2i = Vector2i(at.round())
			c.line(Vector2(e3.x, e3.y - 1), Vector2(e3.x + 3, e3.y - 1), P.BRUTE_SKIN[1])
			c.px(e3.x + 2, e3.y, P.EYES_TANK[2])
			c.px(e3.x + 1, e3.y, P.EYES_TANK[1])
			c.part()
			c.ellipse(Vector2(e3.x + 1.8, e3.y + 2.4 + (0.8 if mouth_open else 0.0)), Vector2(2.2, 1.2), P.BRUTE_SKIN, 0.0, -0.08)
			c.px(e3.x + 3, e3.y + 1 + (1 if mouth_open else 0), P.BONE[3])  # tusk
			if mouth_open:
				c.rect(Rect2i(e3.x + 1, e3.y + 2, 3, 1), P.OUTLINE)


## Grit thrown up where the fists hit the ground (soft: no outline).
func _dust(c: Canvas, facing: String, pose: Dictionary) -> void:
	c.part(true)
	var at: Vector2 = (pose["fist_l"] as Vector2).lerp(pose["fist_r"], 0.5) + Vector2(0, 2.0)
	if facing == "up":
		at = Vector2(24, 23)
	for k: int in 7:
		var p: Vector2 = at + Vector2((k - 3) * 2.4, -absf(k - 3.0) * 0.6 - (k % 2) * 1.5)
		c.px(roundi(p.x), roundi(p.y), P.DIRT[4] if k % 2 == 0 else P.DIRT[3])


# ---------------------------------------------------------------- death

## Roar (pale flash), stagger back, drop to the knees, topple forward, then crumble and release a soul.
func _death_frames() -> Array[Image]:
	var frames: Array[Image] = []
	var roar: Dictionary = _base_pose("down")
	roar["body"] = Vector2(0, -1)
	roar["head"] = Vector2(0, -2)
	roar["mouth"] = true
	roar["fist_l"] = Vector2(10, 31)
	roar["fist_r"] = Vector2(38, 31)
	var first: Image = frame("down", roar)
	Undead.tint(first, Color("f0ecf6"), 0.55)
	frames.append(first)
	var stagger: Dictionary = _base_pose("down")
	stagger["body"] = Vector2(1, 1)
	stagger["head"] = Vector2(2, 1)
	stagger["mouth"] = true
	stagger["fist_l"] = Vector2(12, 38)
	stagger["fist_r"] = Vector2(37, 35)
	frames.append(frame("down", stagger))
	var kneel: Dictionary = _base_pose("down")
	kneel["body"] = Vector2(0, 5)
	kneel["head"] = Vector2(0, 6)
	kneel["lift_l"] = 3.0
	kneel["lift_r"] = 3.0
	kneel["fist_l"] = Vector2(13, 42)
	kneel["fist_r"] = Vector2(35, 42)
	frames.append(frame("down", kneel))
	var lying: Image = _lying()
	frames.append(lying)
	for step: int in 3:
		var dissolving: Image = lying.duplicate() as Image
		Undead.crumble(dissolving, step)
		Undead.soul(dissolving, step, Vector2(24, 36), 1.5)
		frames.append(dissolving)
	return frames


## Fallen flat on its side: the side profile turned onto the ground.
func _lying() -> Image:
	var pose: Dictionary = _base_pose("side")
	pose["fist_r"] = Vector2(34, 38)
	pose["fist_l"] = Vector2(33, 36)
	var body_canvas: Canvas = _draw("side", pose)
	body_canvas.finish()
	var body: Image = body_canvas.image
	body.rotate_90(CLOCKWISE)
	var used: Rect2i = body.get_used_rect()
	var out: Canvas = Canvas.new(SIZE.x, SIZE.y)
	out.image.blend_rect(body, used, Vector2i(floori((SIZE.x - used.size.x) / 2.0), int(FEET.y) + 1 - used.size.y))
	out.ground_shadow(Vector2(24, FEET.y - 1), Vector2(17, 3.2))
	return out.image
