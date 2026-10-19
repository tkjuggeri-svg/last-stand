extends RefCounted
## The Ghoul (dev-time art generator): a gaunt, hunched corpse with grey-green skin, visible ribs,
## tattered rags, long bone claws and glowing red eyes. Frames are 32x32 art px; the feet stand on
## FEET (7 art px below the enemy's origin).

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")
const Undead: GDScript = preload("res://tools/art/undead_fx.gd")

const SIZE: Vector2i = Vector2i(32, 32)
const FEET: Vector2 = Vector2(16, 28)
const WALK_FRAMES: int = 6


## Rows in the order of sheet_layouts.GHOUL.
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
		for i: int in 6:
			attack.append(frame(facing, _attack_pose(facing, i)))
		rows.append(attack)
	return rows


# ---------------------------------------------------------------- poses

## Hands are absolute art positions. Front/back views: hand_l is on the screen left.
## Side view (facing right): hand_l is the far arm, hand_r the near arm.
func _base_pose(facing: String) -> Dictionary:
	var pose: Dictionary = {"body": Vector2.ZERO, "head": Vector2.ZERO, "lift_l": 0.0, "lift_r": 0.0,
		"stride": 0.0, "mouth": false, "smear": false, "crouch": 0.0}
	if facing == "side":
		pose["hand_l"] = Vector2(19.5, 22.5)
		pose["hand_r"] = Vector2(18.5, 23.5)
	else:
		pose["hand_l"] = Vector2(11, 22.5)
		pose["hand_r"] = Vector2(21, 22.5)
	return pose


func _idle_pose(facing: String, i: int) -> Dictionary:
	var pose: Dictionary = _base_pose(facing)
	var breath: int = [0, 0, 1, 1][i]
	pose["body"] = Vector2(0, breath)
	pose["head"] = Vector2([0, 0, 0, 1][i] if facing != "side" else 0, [0, 1, 1, 0][i])
	pose["hand_l"] = (pose["hand_l"] as Vector2) + Vector2(0, breath)
	pose["hand_r"] = (pose["hand_r"] as Vector2) + Vector2(0, [0, 1, 1, 0][i])
	return pose


## A shambling gait: the upper body rolls from side to side and the arms dangle a beat behind.
func _walk_pose(facing: String, i: int) -> Dictionary:
	var t: float = TAU * i / WALK_FRAMES
	var pose: Dictionary = _base_pose(facing)
	var roll: float = roundf(sin(t))
	var bob: float = 1.0 if absf(sin(t)) > 0.6 else 0.0
	if facing == "side":
		pose["stride"] = sin(t)
		pose["body"] = Vector2(0, bob)
		pose["head"] = Vector2(0, roundf(cos(t) * 0.6))
		pose["hand_l"] = Vector2(19.5 - sin(t - 0.8) * 2.5, 22.5 + bob)
		pose["hand_r"] = Vector2(18.5 + sin(t - 0.8) * 2.5, 23.5 + bob)
	else:
		pose["lift_l"] = maxf(sin(t), 0.0)
		pose["lift_r"] = maxf(-sin(t), 0.0)
		pose["body"] = Vector2(roll, bob)
		pose["head"] = Vector2(roll, 0)
		pose["hand_l"] = Vector2(11 + roll, 22.5 + bob + roundf(sin(t - 0.8)))
		pose["hand_r"] = Vector2(21 + roll, 22.5 + bob - roundf(sin(t - 0.8)))
	return pose


## 0-3 wind-up (rear back, claws high, 0.33 s at 12 fps = the data's 0.35 s wind-up), 4 strike
## (lunge, claws raking forward with a smear), 5 recover.
func _attack_pose(facing: String, i: int) -> Dictionary:
	var pose: Dictionary = _base_pose(facing)
	pose["mouth"] = i >= 1 and i <= 4
	pose["smear"] = i == 4
	match facing:
		"down":
			var lift: Array[Vector2] = [Vector2(9.5, 18), Vector2(9, 11), Vector2(8.5, 10), Vector2(9, 10.5), Vector2(9.5, 27.5), Vector2(11, 24)]
			var body: Array[Vector2] = [Vector2(0, -1), Vector2(0, -2), Vector2(0, -2), Vector2(0, -1), Vector2(0, 2), Vector2(0, 1)]
			pose["body"] = body[i]
			pose["head"] = body[i]
			pose["hand_l"] = lift[i] + (Vector2(0, 0) if i < 4 else Vector2.ZERO)
			pose["hand_r"] = Vector2(32 - lift[i].x, lift[i].y)
		"up":
			var lift_up: Array[Vector2] = [Vector2(9.5, 20), Vector2(9, 14), Vector2(8.5, 13), Vector2(9, 13.5), Vector2(12, 7), Vector2(11, 15)]
			var body_up: Array[Vector2] = [Vector2(0, 1), Vector2(0, 1), Vector2(0, 2), Vector2(0, 1), Vector2(0, -2), Vector2(0, -1)]
			pose["body"] = body_up[i]
			pose["head"] = body_up[i]
			pose["hand_l"] = lift_up[i]
			pose["hand_r"] = Vector2(32 - lift_up[i].x, lift_up[i].y)
		"side":
			var near: Array[Vector2] = [Vector2(14, 15), Vector2(12, 9), Vector2(11, 8), Vector2(11.5, 8.5), Vector2(28, 20), Vector2(24, 22)]
			var far: Array[Vector2] = [Vector2(16, 14), Vector2(14, 8), Vector2(13, 7), Vector2(13.5, 7.5), Vector2(27, 17), Vector2(23, 20)]
			var lean: Array[Vector2] = [Vector2(-1, 0), Vector2(-2, -1), Vector2(-2, -1), Vector2(-2, -1), Vector2(3, 1), Vector2(1, 0)]
			pose["body"] = lean[i]
			pose["head"] = lean[i] + (Vector2(1, 0) if i == 4 else Vector2.ZERO)
			pose["hand_r"] = near[i]
			pose["hand_l"] = far[i]
			pose["stride"] = [0.0, -0.3, -0.4, -0.4, 0.9, 0.5][i]
	return pose


# ---------------------------------------------------------------- frames

func frame(facing: String, pose: Dictionary) -> Image:
	var c: Canvas = _draw(facing, pose)
	c.finish()
	c.ground_shadow(FEET + Vector2(0, -0.5), Vector2(6.5, 2.2))
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


## Front (facing the camera) and back views share the skeleton; only the face, ribs and spine differ.
func _draw_front(c: Canvas, pose: Dictionary, front: bool) -> void:
	var body: Vector2 = pose["body"]
	var head_at: Vector2 = Vector2(16, 13.5) + (pose["head"] as Vector2) + Vector2(0, float(pose["crouch"]))
	var hand_l: Vector2 = pose["hand_l"]
	var hand_r: Vector2 = pose["hand_r"]
	var arms_up: bool = hand_l.y < 17.0
	if not front:
		# Seen from behind, the head sits low between the shoulders: draw it before them.
		_head(c, head_at + Vector2(0, 0.5), "up", false)
	# Legs: thin, bent, with clawed feet.
	var hip_y: float = 21.5 + body.y * 0.5
	_leg(c, Vector2(14.2 + body.x * 0.5, hip_y), Vector2(13.3, FEET.y - 1 - float(pose["lift_l"]) * 1.5), P.GHOUL_SKIN, 0.0)
	_leg(c, Vector2(17.8 + body.x * 0.5, hip_y), Vector2(18.7, FEET.y - 1 - float(pose["lift_r"]) * 1.5), P.GHOUL_SKIN, 0.0)
	# Torn rags around the hips.
	c.part()
	var r: Vector2 = Vector2(body.x * 0.5, body.y)
	c.polygon(PackedVector2Array([Vector2(11.8, 19.5) + r, Vector2(20.2, 19.5) + r, Vector2(20.8, 23.2) + r,
		Vector2(19.2, 22.4) + r, Vector2(18, 24.2) + r, Vector2(16.4, 22.6) + r, Vector2(14.6, 24.4) + r,
		Vector2(13.2, 22.6) + r, Vector2(11.4, 23.4) + r]), P.RAGS, Vector3(-0.2, -0.1, 1))
	c.line(Vector2(12, 20) + r, Vector2(20, 20) + r, P.RAGS[1])
	# The hunched torso: ribs at the front, a knobbly spine at the back.
	c.part()
	c.ellipse(Vector2(16, 17.2) + body, Vector2(4.0, 4.0), P.GHOUL_SKIN, 0.0, -0.05)
	if front:
		for i: int in 3:
			var y: int = roundi(16.0 + body.y + i * 1.4)
			c.line(Vector2(13.4 + body.x, y), Vector2(14.8 + body.x, y + 0.5), P.GHOUL_SKIN[1])
			c.line(Vector2(17.2 + body.x, y + 0.5), Vector2(18.6 + body.x, y), P.GHOUL_SKIN[1])
		# A strip of rotten cloth across the chest.
		c.line(Vector2(12.5, 14.8) + body, Vector2(19.5, 19.6) + body, P.RAGS[2])
		c.line(Vector2(12.5, 15.8) + body, Vector2(18.5, 20.0) + body, P.RAGS[1])
	else:
		for i: int in 4:
			c.px(roundi(16 + body.x), roundi(15 + body.y + i * 1.3), P.GHOUL_SKIN[4] if i % 2 == 0 else P.GHOUL_SKIN[1])
		c.line(Vector2(13, 16) + body, Vector2(14.2, 18) + body, P.GHOUL_SKIN[1])
		c.line(Vector2(19, 16) + body, Vector2(17.8, 18) + body, P.GHOUL_SKIN[1])
	# Shoulders hunched up around the head.
	var shoulder_l: Vector2 = Vector2(12.2, 15.2) + body
	var shoulder_r: Vector2 = Vector2(19.8, 15.2) + body
	if arms_up:
		_arm(c, shoulder_l, hand_l, -1.0, pose["smear"])
		_arm(c, shoulder_r, hand_r, 1.0, pose["smear"])
	c.part()
	c.ellipse(shoulder_l, Vector2(1.9, 1.7), P.GHOUL_SKIN, 0.0, 0.02)
	c.part()
	c.ellipse(shoulder_r, Vector2(1.9, 1.7), P.GHOUL_SKIN, 0.0, 0.02)
	if front:
		_head(c, head_at, "down", pose["mouth"])
	if not arms_up:
		_arm(c, shoulder_l, hand_l, -1.0, pose["smear"])
		_arm(c, shoulder_r, hand_r, 1.0, pose["smear"])


func _draw_side(c: Canvas, pose: Dictionary) -> void:
	var body: Vector2 = pose["body"]
	var stride: float = pose["stride"]
	var shoulder: Vector2 = Vector2(17, 15.5) + body
	# Far arm (darker), behind everything.
	_arm(c, shoulder + Vector2(1, -0.5), pose["hand_l"], 1.0, false, -0.12)
	# Legs bent at the knee, the far one darker.
	var hip: Vector2 = Vector2(14.5, 21.5) + Vector2(body.x * 0.5, body.y * 0.5)
	_leg(c, hip + Vector2(0.5, 0), Vector2(15 - stride * 3.2, FEET.y - 1 - maxf(-stride, 0.0) * 1.3), P.GHOUL_SKIN, -0.12, true)
	_leg(c, hip, Vector2(15 + stride * 3.2, FEET.y - 1 - maxf(stride, 0.0) * 1.3), P.GHOUL_SKIN, 0.0, true)
	c.part()
	c.polygon(PackedVector2Array([Vector2(11.5, 19.5) + body, Vector2(17, 19.8) + body, Vector2(17.5, 23) + body,
		Vector2(15.8, 22.2) + body, Vector2(14.2, 24) + body, Vector2(12.6, 22.4) + body, Vector2(11, 23.6) + body]), P.RAGS, Vector3(0, -0.1, 1))
	# The torso leans far forward: a long back with the spine showing, the head thrust out in front.
	c.part()
	c.ellipse(Vector2(15, 17.5) + body, Vector2(4.4, 3.6), P.GHOUL_SKIN, 0.0, -0.05)
	for i: int in 3:
		c.px(roundi(12.5 + i * 1.6 + body.x), roundi(14.6 + body.y - i * 0.3), P.GHOUL_SKIN[4])
	c.line(Vector2(15.5, 18.5) + body, Vector2(17.8, 19.2) + body, P.GHOUL_SKIN[1])
	c.part()
	c.ellipse(shoulder, Vector2(2.0, 1.8), P.GHOUL_SKIN, 0.0, 0.03)
	_head(c, Vector2(20.5, 14.5) + (pose["head"] as Vector2), "side", pose["mouth"])
	_arm(c, shoulder, pose["hand_r"], 1.0, pose["smear"])


# ---------------------------------------------------------------- body parts

func _leg(c: Canvas, hip: Vector2, foot: Vector2, ramp: Array, bias: float, side: bool = false) -> void:
	var knee: Vector2 = hip.lerp(foot, 0.5) + (Vector2(1.2, 0) if side else Vector2((hip.x - 16) * 0.25, 0))
	c.part()
	c.capsule(hip, knee, 1.3, ramp, bias - 0.05)
	c.capsule(knee, foot, 1.1, ramp, bias - 0.1)
	c.part()
	var toe: Vector2 = Vector2(1.2, 0.2) if side else Vector2(0, 0.3)
	c.ellipse(foot + toe * 0.5, Vector2(1.8 if side else 1.4, 1.0), ramp, 0.0, bias - 0.12)


## A long bony arm ending in three claws. smear adds pale motion streaks behind the claws.
func _arm(c: Canvas, shoulder: Vector2, hand: Vector2, side: float, smear: bool, bias: float = 0.0) -> void:
	var elbow: Vector2 = shoulder.lerp(hand, 0.5) + Vector2(side * 1.3, 0.6)
	c.part()
	c.capsule(shoulder, elbow, 1.2, P.GHOUL_SKIN, bias - 0.02)
	c.capsule(elbow, hand, 1.0, P.GHOUL_SKIN, bias - 0.04)
	c.part()
	c.ellipse(hand, Vector2(1.4, 1.2), P.GHOUL_SKIN, 0.0, bias)
	var reach: Vector2 = (hand - elbow).normalized()
	var across: Vector2 = Vector2(-reach.y, reach.x)
	c.part()
	for k: int in [-1, 0, 1]:
		var base: Vector2 = hand + reach * 1.0 + across * k * 0.9
		c.line(base, base + reach * 1.4 + across * k * 0.5, P.BONE[2] if k <= 0 else P.BONE[1])
	if smear:
		c.part(true)
		for k: int in [-1, 0, 1]:
			var tip: Vector2 = hand + reach * 3.0 + across * k * 1.4
			c.line(tip - reach * 6.0 + across * 2.0, tip - reach * 1.5, Color(0.85, 0.95, 0.85, 0.55))


func _head(c: Canvas, at: Vector2, facing: String, mouth_open: bool) -> void:
	c.part()
	match facing:
		"down":
			c.ellipse(at, Vector2(3.6, 3.4), P.GHOUL_SKIN, 0.0, 0.04)
			# Sunken sockets with glowing eyes, a lipless mouth full of teeth.
			var e: Vector2i = Vector2i(at.round())
			for dx: int in [-2, 1]:
				c.rect(Rect2i(e.x + dx, e.y - 1, 2, 2), P.GHOUL_SKIN[0])
				c.px(e.x + dx + (1 if dx < 0 else 0), e.y - 1, P.EYE_GLOW[2])
				c.px(e.x + dx + (1 if dx < 0 else 0), e.y, P.EYE_GLOW[1])
			c.rect(Rect2i(e.x - 2, e.y + 2, 4, 1 if not mouth_open else 2), P.OUTLINE)
			c.px(e.x - 1, e.y + 2, P.BONE[3])
			c.px(e.x + 1, e.y + 2, P.BONE[2])
			if mouth_open:
				c.px(e.x, e.y + 3, P.BONE[2])
			c.px(e.x - 3, e.y - 3, P.GHOUL_SKIN[1])  # a few wisps of hair
			c.px(e.x + 2, e.y - 4, P.GHOUL_SKIN[1])
		"up":
			c.ellipse(at, Vector2(3.5, 3.3), P.GHOUL_SKIN, 0.0, 0.0)
			var e2: Vector2i = Vector2i(at.round())
			c.line(Vector2(e2.x - 2, e2.y - 2), Vector2(e2.x - 1, e2.y + 1), P.GHOUL_SKIN[1])
			c.px(e2.x + 1, e2.y - 3, P.GHOUL_SKIN[1])
		_:
			c.ellipse(at, Vector2(3.3, 3.1), P.GHOUL_SKIN, 0.0, 0.04)
			var e3: Vector2i = Vector2i(at.round())
			c.rect(Rect2i(e3.x + 1, e3.y - 1, 2, 2), P.GHOUL_SKIN[0])
			c.px(e3.x + 2, e3.y - 1, P.EYE_GLOW[2])
			c.px(e3.x + 2, e3.y, P.EYE_GLOW[1])
			# Jaw jutting forward, hanging open when it attacks.
			c.part()
			c.ellipse(Vector2(e3.x + 2.5, e3.y + 2.5 + (0.8 if mouth_open else 0.0)), Vector2(1.8, 1.0), P.GHOUL_SKIN, 0.0, -0.1)
			c.px(e3.x + 3, e3.y + 2 + (1 if mouth_open else 0), P.BONE[3])
			c.px(e3.x + 1, e3.y + 2 + (1 if mouth_open else 0), P.BONE[2])
			if mouth_open:
				c.rect(Rect2i(e3.x + 1, e3.y + 2, 3, 1), P.OUTLINE)


# ---------------------------------------------------------------- death

## Recoil (pale), stagger, knees buckle, collapse, then the body crumbles while its soul escapes.
func _death_frames() -> Array[Image]:
	var frames: Array[Image] = []
	var recoil: Dictionary = _base_pose("down")
	recoil["body"] = Vector2(0, -1)
	recoil["head"] = Vector2(0, -2)
	recoil["mouth"] = true
	recoil["hand_l"] = Vector2(9.5, 20)
	recoil["hand_r"] = Vector2(22.5, 20)
	var first: Image = frame("down", recoil)
	Undead.tint(first, Color("eef5e6"), 0.55)
	frames.append(first)
	var stagger: Dictionary = _base_pose("down")
	stagger["body"] = Vector2(1, 1)
	stagger["head"] = Vector2(2, 1)
	stagger["mouth"] = true
	stagger["hand_l"] = Vector2(11, 25)
	stagger["hand_r"] = Vector2(22.5, 22)
	frames.append(frame("down", stagger))
	var buckle: Dictionary = _base_pose("down")
	buckle["body"] = Vector2(1, 4)
	buckle["head"] = Vector2(1, 5)
	buckle["crouch"] = 0.0
	buckle["lift_l"] = 2.0
	buckle["lift_r"] = 2.0
	buckle["hand_l"] = Vector2(10, 27)
	buckle["hand_r"] = Vector2(22, 27)
	frames.append(frame("down", buckle))
	var lying: Image = _lying()
	frames.append(lying)
	for step: int in 3:
		var dissolving: Image = lying.duplicate() as Image
		Undead.crumble(dissolving, step)
		Undead.soul(dissolving, step, Vector2(16, 22))
		frames.append(dissolving)
	return frames


func _lying() -> Image:
	var pose: Dictionary = _base_pose("side")
	pose["hand_r"] = Vector2(22, 24)
	pose["hand_l"] = Vector2(23, 22)
	var body_canvas: Canvas = _draw("side", pose)
	body_canvas.finish()
	var body: Image = body_canvas.image
	body.rotate_90(CLOCKWISE)
	var used: Rect2i = body.get_used_rect()
	var out: Canvas = Canvas.new(SIZE.x, SIZE.y)
	out.image.blend_rect(body, used, Vector2i(floori((SIZE.x - used.size.x) / 2.0), int(FEET.y) + 1 - used.size.y))
	out.ground_shadow(Vector2(16, FEET.y - 1), Vector2(11, 2.4))
	return out.image
