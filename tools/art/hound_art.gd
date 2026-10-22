extends RefCounted
## The Grave Hound (dev-time art generator): a starved undead hound, low and long, with a bare skull
## for a head, exposed ribs and spine, a flayed red-brown hide, a whip of a tail and glowing red eyes.
## It must read as "fast, low beast" next to the upright Ghoul. Frames are 32x32 art px; the paws
## stand on FEET (7 art px below the enemy's origin, like the Ghoul).

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")
const Undead: GDScript = preload("res://tools/art/undead_fx.gd")

const SIZE: Vector2i = Vector2i(32, 32)
const FEET: Vector2 = Vector2(16, 28)
const RUN_FRAMES: int = 6
const ATTACK_FRAMES: int = 6


## Rows in the order of sheet_layouts.HOUND.
func sheet_rows() -> Array[Array]:
	var rows: Array[Array] = []
	for facing: String in ["down", "up", "side"]:
		var idle: Array[Image] = []
		for i: int in 4:
			idle.append(frame(facing, _idle_pose(i)))
		rows.append(idle)
	for facing: String in ["down", "up", "side"]:
		var run: Array[Image] = []
		for i: int in RUN_FRAMES:
			run.append(frame(facing, _run_pose(facing, i)))
		rows.append(run)
	rows.append(_death_frames())
	for facing: String in ["down", "up", "side"]:
		var attack: Array[Image] = []
		for i: int in ATTACK_FRAMES:
			attack.append(frame(facing, _attack_pose(facing, i)))
		rows.append(attack)
	return rows


# ---------------------------------------------------------------- poses

## Legs are [swing, lift] pairs: swing moves the paw forward (+) / back (-), lift raises it.
## Front/back views use only the lifts (l = screen left).
func _base_pose() -> Dictionary:
	return {"body": Vector2.ZERO, "head": Vector2.ZERO, "jaw": 0.0, "tail": 0.0, "smear": false,
		"front_near": Vector2.ZERO, "front_far": Vector2.ZERO, "hind_near": Vector2.ZERO, "hind_far": Vector2.ZERO,
		"lift_l": 0.0, "lift_r": 0.0, "stretch": 0.0}


## Panting: the ribcage heaves, the jaw hangs a little open, the tail twitches.
func _idle_pose(i: int) -> Dictionary:
	var pose: Dictionary = _base_pose()
	pose["body"] = Vector2(0, [0, 0, 1, 1][i])
	pose["head"] = Vector2(0, [0, 1, 1, 0][i])
	pose["jaw"] = [0.3, 0.5, 0.5, 0.3][i]
	pose["tail"] = [0.0, 0.4, 0.0, -0.4][i]
	return pose


## A gallop: the legs work in pairs (hind then front), the back flexes and the body bobs.
func _run_pose(facing: String, i: int) -> Dictionary:
	var t: float = TAU * i / RUN_FRAMES
	var pose: Dictionary = _base_pose()
	var bob: float = -1.0 if sin(t) > 0.5 else 0.0
	pose["body"] = Vector2(0, bob)
	pose["head"] = Vector2(0, roundf(cos(t) * 0.7))
	pose["tail"] = sin(t + 1.0) * 0.8
	pose["jaw"] = 0.3
	pose["stretch"] = sin(t)
	pose["front_near"] = Vector2(sin(t) * 3.0, maxf(cos(t), 0.0) * 2.0)
	pose["front_far"] = Vector2(sin(t - 0.6) * 3.0, maxf(cos(t - 0.6), 0.0) * 2.0)
	pose["hind_near"] = Vector2(-sin(t) * 3.0, maxf(-cos(t), 0.0) * 2.0)
	pose["hind_far"] = Vector2(-sin(t - 0.6) * 3.0, maxf(-cos(t - 0.6), 0.0) * 2.0)
	if facing != "side":
		pose["lift_l"] = maxf(sin(t), 0.0) * 2.0
		pose["lift_r"] = maxf(-sin(t), 0.0) * 2.0
		pose["body"] = Vector2(roundf(sin(t) * 0.6), bob)
	return pose


## 0-3 crouch back with the jaws opening (4 frames at 16 fps = the data's 0.25 s wind-up), 4 the lunge
## and bite (jaws wide, a motion smear), 5 recover.
func _attack_pose(facing: String, i: int) -> Dictionary:
	var pose: Dictionary = _base_pose()
	pose["jaw"] = [0.4, 0.7, 1.0, 1.0, 1.0, 0.4][i]
	pose["smear"] = i == 4
	pose["tail"] = [0.3, 0.6, 0.8, 0.8, -0.6, 0.0][i]
	var back: Array[float] = [-1.0, -1.5, -2.0, -2.0, 3.0, 1.0]
	var low: Array[float] = [0.0, 1.0, 1.0, 1.0, 0.0, 0.0]
	match facing:
		"side":
			pose["body"] = Vector2(back[i] * 0.5, low[i])
			pose["head"] = Vector2(back[i] * 0.5 + (1.0 if i == 4 else 0.0), low[i] + (1.0 if i == 4 else 0.0))
			pose["front_near"] = Vector2(-1.0 if i < 4 else 2.0, 0.0)
			pose["front_far"] = Vector2(-0.5 if i < 4 else 2.5, 0.0)
			pose["hind_near"] = Vector2(0.5, 0.0)
			pose["hind_far"] = Vector2(1.0, 0.0)
		"down":
			pose["body"] = Vector2(0, -back[i] * 0.5 + low[i] * 0.5)
			pose["head"] = Vector2(0, -back[i] * 0.7)
		"up":
			pose["body"] = Vector2(0, back[i] * 0.4)
			pose["head"] = Vector2(0, back[i] * 0.7 - low[i])
	return pose


# ---------------------------------------------------------------- frames

func frame(facing: String, pose: Dictionary) -> Image:
	var c: Canvas = _draw(facing, pose)
	c.finish()
	c.ground_shadow(FEET + Vector2(0, -0.5), Vector2(9.0, 2.2) if facing == "side" else Vector2(5.5, 2.4))
	return c.image


func _draw(facing: String, pose: Dictionary) -> Canvas:
	var c: Canvas = Canvas.new(SIZE.x, SIZE.y)
	match facing:
		"down":
			_draw_front(c, pose)
		"up":
			_draw_back(c, pose)
		_:
			_draw_side(c, pose)
	return c


## Side view, facing right: hind legs at the left, the long ribbed body, the skull thrust forward.
func _draw_side(c: Canvas, pose: Dictionary) -> void:
	var body: Vector2 = pose["body"]
	var stretch: float = pose["stretch"]
	var hip: Vector2 = Vector2(11.5 - stretch * 0.6, 19.0) + body
	var shoulder: Vector2 = Vector2(20.0 + stretch * 0.6, 19.0) + body
	# Far legs first (darker), then the tail, body, near legs, neck and head.
	_hind_leg(c, hip + Vector2(1, 0), pose["hind_far"], -0.14)
	_front_leg(c, shoulder + Vector2(1, 0), pose["front_far"], -0.14)
	_tail(c, hip + Vector2(-2.5, -1.5), pose["tail"])
	c.part()
	c.ellipse(hip + Vector2(0.5, -0.5), Vector2(3.8, 3.0), P.HOUND_HIDE, 0.0, -0.04)
	c.part()
	c.ellipse(Vector2(16, 18.8) + body, Vector2(4.4, 2.4), P.HOUND_HIDE, 0.0, -0.08)  # thin waist
	c.part()
	c.ellipse(shoulder + Vector2(-0.5, -0.3), Vector2(4.0, 3.4), P.HOUND_HIDE, 0.0, 0.0)
	# Exposed ribs along the chest, knobbly spine along the back.
	for k: int in 3:
		var x: float = shoulder.x - 3.0 + k * 1.6
		c.line(Vector2(x, shoulder.y - 1.6), Vector2(x - 0.4, shoulder.y + 1.8), P.HOUND_HIDE[0])
		c.px(roundi(x + 0.6), roundi(shoulder.y - 0.6), P.BONE[2])
		c.px(roundi(x + 0.4), roundi(shoulder.y + 0.8), P.BONE[1])
	for k: int in 5:
		var spine: Vector2 = hip.lerp(shoulder, k / 4.0) + Vector2(0, -3.0 + absf(k - 2.0) * 0.2)
		c.px(roundi(spine.x), roundi(spine.y), P.BONE[3] if k % 2 == 0 else P.BONE[1])
	_hind_leg(c, hip, pose["hind_near"], 0.0)
	_front_leg(c, shoulder, pose["front_near"], 0.0)
	var head: Vector2 = Vector2(25.0, 14.5) + (pose["head"] as Vector2) + body * Vector2(1, 0.5)
	c.part()
	c.capsule(shoulder + Vector2(1.0, -1.6), head + Vector2(-1.2, 0.6), 1.7, P.HOUND_HIDE, 0.02)
	_skull_side(c, head, pose["jaw"], pose["smear"])


## Front view (running at the camera): the long body recedes up the screen behind the head, so the
## haunches and hind legs show above and behind the chest; the skull is low and in front.
func _draw_front(c: Canvas, pose: Dictionary) -> void:
	var body: Vector2 = pose["body"]
	var lift_l: float = pose["lift_l"]
	var lift_r: float = pose["lift_r"]
	# Furthest away: the tail tip over the haunches, then the hind legs (paws higher up the screen).
	_tail(c, Vector2(16.5, 11.0) + body, pose["tail"], true)
	_simple_leg(c, Vector2(12.4, 14.0) + body, Vector2(12.0, FEET.y - 4 - lift_r), -0.18)
	_simple_leg(c, Vector2(19.6, 14.0) + body, Vector2(20.0, FEET.y - 4 - lift_l), -0.18)
	c.part()
	c.ellipse(Vector2(16, 12.8) + body, Vector2(4.0, 2.6), P.HOUND_HIDE, 0.0, -0.08)  # haunches
	c.part()
	c.ellipse(Vector2(16, 16.5) + body, Vector2(3.4, 3.8), P.HOUND_HIDE, 0.0, -0.03)  # the back
	for k: int in 4:
		c.px(roundi(16 + body.x), roundi(11.5 + body.y + k * 1.5), P.BONE[3] if k % 2 == 0 else P.BONE[1])
	# The deep, ribbed chest and the front legs, nearest to us.
	c.part()
	c.ellipse(Vector2(16, 20.5) + body, Vector2(4.4, 3.0), P.HOUND_HIDE, 0.0, 0.02)
	for k: int in 2:
		var y: float = 20.0 + body.y + k * 1.4
		c.line(Vector2(12.6 + body.x, y), Vector2(14.0 + body.x, y + 0.5), P.HOUND_HIDE[0])
		c.line(Vector2(18.0 + body.x, y + 0.5), Vector2(19.4 + body.x, y), P.HOUND_HIDE[0])
		c.px(roundi(13.2 + body.x), roundi(y - 0.6), P.BONE[2])
		c.px(roundi(18.8 + body.x), roundi(y - 0.6), P.BONE[1])
	_simple_leg(c, Vector2(13.4, 22.0) + body, Vector2(13.0, FEET.y - 1 - lift_l), 0.0)
	_simple_leg(c, Vector2(18.6, 22.0) + body, Vector2(19.0, FEET.y - 1 - lift_r), 0.0)
	_skull_front(c, Vector2(16, 19.5) + (pose["head"] as Vector2) + body * Vector2(1, 0.5), pose["jaw"], pose["smear"])


## Back view (running away): haunches and tail nearest, the body recedes up the screen to the small
## skull at the top; the front legs are further away, their paws higher up.
func _draw_back(c: Canvas, pose: Dictionary) -> void:
	var body: Vector2 = pose["body"]
	var lift_l: float = pose["lift_l"]
	var lift_r: float = pose["lift_r"]
	var head: Vector2 = Vector2(16, 10.5) + (pose["head"] as Vector2) + body * Vector2(1, 0.5)
	_simple_leg(c, Vector2(13.6, 14.5) + body, Vector2(13.4, FEET.y - 4 - lift_r), -0.18)
	_simple_leg(c, Vector2(18.4, 14.5) + body, Vector2(18.6, FEET.y - 4 - lift_l), -0.18)
	_ears(c, head, false)
	c.part()
	c.ellipse(head, Vector2(2.6, 2.2), P.BONE, 0.0, -0.1)  # back of the skull
	c.part()
	c.capsule(head + Vector2(0, 1.5), Vector2(16, 13.5) + body, 1.6, P.HOUND_HIDE, -0.04)
	c.part()
	c.ellipse(Vector2(16, 15.5) + body, Vector2(3.4, 3.8), P.HOUND_HIDE, 0.0, -0.03)  # the back
	c.part()
	c.ellipse(Vector2(16, 20.2) + body, Vector2(4.6, 3.4), P.HOUND_HIDE, 0.0, 0.02)  # haunches
	for k: int in 5:
		c.px(roundi(16 + body.x), roundi(12.5 + body.y + k * 1.4), P.BONE[3] if k % 2 == 0 else P.BONE[1])
	c.line(Vector2(13.0, 19.0) + body, Vector2(14.2, 22.0) + body, P.HOUND_HIDE[1])
	c.line(Vector2(19.0, 19.0) + body, Vector2(17.8, 22.0) + body, P.HOUND_HIDE[1])
	_simple_leg(c, Vector2(12.6, 21.5) + body, Vector2(12.2, FEET.y - 1 - lift_l), 0.0)
	_simple_leg(c, Vector2(19.4, 21.5) + body, Vector2(19.8, FEET.y - 1 - lift_r), 0.0)
	_tail(c, Vector2(16, 22.5) + body, pose["tail"], true)


# ---------------------------------------------------------------- body parts

## Hind leg in profile: thigh forward, the hock bent back, a long shin to the paw.
func _hind_leg(c: Canvas, hip: Vector2, swing_lift: Vector2, bias: float) -> void:
	var paw: Vector2 = Vector2(hip.x + 0.5 + swing_lift.x, FEET.y - 1 - swing_lift.y)
	var knee: Vector2 = Vector2(hip.x + 1.5 + swing_lift.x * 0.5, hip.y + 2.6)
	var hock: Vector2 = Vector2(paw.x - 1.6, paw.y - 2.4)
	c.part()
	c.capsule(hip, knee, 1.6, P.HOUND_HIDE, bias - 0.02)
	c.capsule(knee, hock, 1.0, P.HOUND_HIDE, bias - 0.06)
	c.capsule(hock, paw, 0.8, P.HOUND_HIDE, bias - 0.1)
	_paw(c, paw, bias, true)


## Front leg in profile: nearly straight, a little bend at the wrist.
func _front_leg(c: Canvas, shoulder: Vector2, swing_lift: Vector2, bias: float) -> void:
	var paw: Vector2 = Vector2(shoulder.x + swing_lift.x, FEET.y - 1 - swing_lift.y)
	var elbow: Vector2 = Vector2(shoulder.x - 0.6 + swing_lift.x * 0.4, shoulder.y + 3.0)
	c.part()
	c.capsule(shoulder + Vector2(0, 0.5), elbow, 1.3, P.HOUND_HIDE, bias - 0.03)
	c.capsule(elbow, paw, 0.9, P.HOUND_HIDE, bias - 0.08)
	_paw(c, paw, bias, true)


## A straight leg for the front/back views.
func _simple_leg(c: Canvas, top: Vector2, paw: Vector2, bias: float) -> void:
	c.part()
	c.capsule(top, paw, 1.0, P.HOUND_HIDE, bias - 0.06)
	_paw(c, paw, bias, false)


func _paw(c: Canvas, at: Vector2, bias: float, side: bool) -> void:
	c.part()
	c.ellipse(at + (Vector2(0.6, 0.3) if side else Vector2(0, 0.3)), Vector2(1.5 if side else 1.2, 0.8), P.HOUND_HIDE, 0.0, bias - 0.12)
	c.px(roundi(at.x + (1.8 if side else 0.0)), roundi(at.y + 0.8), P.BONE[1])  # a claw


## A thin, ragged whip of a tail. In the front/back views it rises straight up from the body.
func _tail(c: Canvas, root: Vector2, swing: float, upright: bool = false) -> void:
	c.part()
	if upright:
		var tip: Vector2 = root + Vector2(swing * 2.5, -4.5 if root.y < 18.0 else 3.5)
		c.capsule(root, root.lerp(tip, 0.5) + Vector2(swing, 0), 0.8, P.HOUND_HIDE, -0.06)
		c.capsule(root.lerp(tip, 0.5) + Vector2(swing, 0), tip, 0.6, P.HOUND_HIDE, -0.1)
		return
	var mid: Vector2 = root + Vector2(-2.2, -1.2 - swing)
	var tip2: Vector2 = mid + Vector2(-2.2, 0.6 - swing * 1.5)
	c.capsule(root, mid, 0.8, P.HOUND_HIDE, -0.04)
	c.capsule(mid, tip2, 0.6, P.HOUND_HIDE, -0.1)


func _ears(c: Canvas, head: Vector2, front: bool) -> void:
	c.part()
	var lift: float = 0.0 if front else 0.5
	c.polygon(PackedVector2Array([head + Vector2(-2.8, -1.2), head + Vector2(-3.6, -4.6 + lift), head + Vector2(-1.0, -2.4)]),
		P.HOUND_HIDE, Vector3(-0.4, -0.3, 1))
	c.polygon(PackedVector2Array([head + Vector2(2.8, -1.2), head + Vector2(3.6, -4.6 + lift), head + Vector2(1.0, -2.4)]),
		P.HOUND_HIDE, Vector3(0.3, -0.3, 1))


## The bare skull in profile: cranium, long snout, sunken burning eye; the jaw drops as `jaw` -> 1.
func _skull_side(c: Canvas, at: Vector2, jaw: float, smear: bool) -> void:
	c.part()
	c.polygon(PackedVector2Array([at + Vector2(-1.8, -1.6), at + Vector2(-3.0, -4.8), at + Vector2(-0.2, -2.4)]),
		P.HOUND_HIDE, Vector3(-0.4, -0.3, 1))
	c.part()
	var drop: float = jaw * 2.2
	# Lower jaw first (behind the snout).
	c.capsule(at + Vector2(0.5, 1.4), at + Vector2(4.2, 1.6 + drop), 0.8, P.BONE, -0.12)
	c.part()
	c.ellipse(at, Vector2(2.6, 2.2), P.BONE, 0.0, 0.0)
	c.capsule(at + Vector2(1.2, 0.4), at + Vector2(4.6, 0.8), 1.15, P.BONE, -0.02)
	var e: Vector2i = Vector2i(at.round())
	c.rect(Rect2i(e.x, e.y - 1, 2, 2), P.OUTLINE)
	c.px(e.x + 1, e.y - 1, P.EYES_FAST[2])
	c.px(e.x, e.y, P.EYES_FAST[1])
	c.px(e.x + 5, e.y, P.OUTLINE)  # nostril
	if jaw > 0.2:
		# The open maw: a dark gap with a red glow and teeth.
		c.line(at + Vector2(1.2, 1.8), at + Vector2(4.2, 1.8 + drop * 0.6), P.EYES_FAST[0])
		c.px(e.x + 2, e.y + 2, P.BONE[3])
		c.px(e.x + 4, e.y + 2, P.BONE[3])
	if smear:
		c.part(true)
		for k: int in 3:
			var y: float = at.y - 1.0 + k * 1.5
			c.line(Vector2(at.x - 9.0, y), Vector2(at.x - 3.5, y), Color(0.95, 0.85, 0.78, 0.5))


## The skull facing the camera: two burning sockets, a short snout toward us, the jaw below.
func _skull_front(c: Canvas, at: Vector2, jaw: float, smear: bool) -> void:
	_ears(c, at, true)
	var drop: float = roundf(jaw * 2.0)
	c.part()
	c.ellipse(at + Vector2(0, 2.4 + drop), Vector2(1.9, 1.0), P.BONE, 0.0, -0.14)  # lower jaw
	c.part()
	c.ellipse(at, Vector2(3.0, 2.6), P.BONE, 0.0, 0.02)
	c.part()
	c.ellipse(at + Vector2(0, 1.8), Vector2(1.8, 1.4), P.BONE, 0.0, 0.05)  # snout
	var e: Vector2i = Vector2i(at.round())
	for dx: int in [-2, 1]:
		c.rect(Rect2i(e.x + dx, e.y - 1, 2, 2), P.OUTLINE)
		c.px(e.x + dx + (1 if dx < 0 else 0), e.y - 1, P.EYES_FAST[2])
		c.px(e.x + dx + (1 if dx < 0 else 0), e.y, P.EYES_FAST[1])
	c.px(e.x, e.y + 1, P.OUTLINE)  # nose
	if drop > 0.0:
		c.rect(Rect2i(e.x - 1, e.y + 3, 3, int(drop)), P.EYES_FAST[0])
		c.px(e.x - 1, e.y + 3, P.BONE[3])
		c.px(e.x + 1, e.y + 3, P.BONE[3])
	if smear:
		c.part(true)
		for dx: int in [-5, 5]:
			c.line(Vector2(at.x + dx, at.y - 6.0), Vector2(at.x + dx * 0.8, at.y - 2.0), Color(0.95, 0.85, 0.78, 0.5))


# ---------------------------------------------------------------- death

## Yelp (pale flash), rear up, legs give way, collapse on its side, then crumble and release a soul.
func _death_frames() -> Array[Image]:
	var frames: Array[Image] = []
	var yelp: Dictionary = _base_pose()
	yelp["jaw"] = 1.0
	yelp["head"] = Vector2(0, -1)
	var first: Image = frame("side", yelp)
	Undead.tint(first, Color("f5ece6"), 0.55)
	frames.append(first)
	var rear: Dictionary = _base_pose()
	rear["jaw"] = 1.0
	rear["head"] = Vector2(-1, -2)
	rear["body"] = Vector2(0, -1)
	rear["front_near"] = Vector2(1.5, 2.0)
	rear["front_far"] = Vector2(2.0, 1.5)
	frames.append(frame("side", rear))
	var buckle: Dictionary = _base_pose()
	buckle["jaw"] = 0.6
	buckle["body"] = Vector2(0, 3)
	buckle["head"] = Vector2(0, 4)
	buckle["front_near"] = Vector2(2.5, 0.0)
	buckle["front_far"] = Vector2(3.0, 0.0)
	buckle["hind_near"] = Vector2(-2.5, 0.0)
	buckle["hind_far"] = Vector2(-2.0, 0.0)
	frames.append(frame("side", buckle))
	var lying: Image = _lying()
	frames.append(lying)
	for step: int in 3:
		var dissolving: Image = lying.duplicate() as Image
		Undead.crumble(dissolving, step)
		Undead.soul(dissolving, step, Vector2(17, 23))
		frames.append(dissolving)
	return frames


## Fallen on its side: the profile squashed flat against the ground, legs stuck out stiff.
func _lying() -> Image:
	var pose: Dictionary = _base_pose()
	pose["jaw"] = 0.8
	pose["front_near"] = Vector2(3.0, 1.0)
	pose["front_far"] = Vector2(3.5, 2.0)
	pose["hind_near"] = Vector2(-3.0, 1.0)
	pose["hind_far"] = Vector2(-3.5, 2.0)
	var body_canvas: Canvas = _draw("side", pose)
	body_canvas.finish()
	var body: Image = body_canvas.image
	var used: Rect2i = body.get_used_rect()
	var region: Image = body.get_region(used)
	region.resize(used.size.x, maxi(roundi(used.size.y * 0.62), 1), Image.INTERPOLATE_NEAREST)
	var out: Canvas = Canvas.new(SIZE.x, SIZE.y)
	out.image.blend_rect(region, Rect2i(Vector2i.ZERO, region.get_size()),
		Vector2i(floori((SIZE.x - region.get_width()) / 2.0), int(FEET.y) + 1 - region.get_height()))
	out.ground_shadow(Vector2(16, FEET.y - 1), Vector2(11, 2.2))
	return out.image
