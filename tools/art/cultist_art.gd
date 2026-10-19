extends RefCounted
## The Cultist (dev-time art generator): a gaunt caster in a tall pointed hood and a pale, ash-grey
## ritual robe, its face a black hollow with two green eyes, a ball of witchfire in its hand.
## Frames are 32x32 art px; the hem stands on FEET (7 art px below the enemy's origin), like the Ghoul.
## Also its shot (a witchfire bolt) and the bolt's burst, on a 16x16 sheet.

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")
const Undead: GDScript = preload("res://tools/art/undead_fx.gd")

const SIZE: Vector2i = Vector2i(32, 32)
const FEET: Vector2 = Vector2(16, 28)
const WALK_FRAMES: int = 6
## Attack: 8 frames at 12 fps; the release is frame 6 (0.5 s = the data's wind-up).
const ATTACK_FRAMES: int = 8
const RELEASE_FRAME: int = 6
const FX_SIZE: Vector2i = Vector2i(16, 16)


## Rows in the order of sheet_layouts.CULTIST.
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

## Hands are absolute art positions (side view: hand_r is the near arm). orb: where the witchfire
## floats and how big it is (radius 0 = none).
func _base_pose(facing: String) -> Dictionary:
	var pose: Dictionary = {"body": Vector2.ZERO, "sway": 0.0, "orb_r": 1.6, "flicker": 0, "flash": false, "kneel": 0.0}
	if facing == "side":
		pose["hand_l"] = Vector2(14, 20)
		pose["hand_r"] = Vector2(19.5, 19.5)
		pose["orb"] = Vector2(20.5, 17.5)
	else:
		pose["hand_l"] = Vector2(11.5, 20.5)
		pose["hand_r"] = Vector2(20.5, 20)
		pose["orb"] = Vector2(21, 17.5)
	return pose


func _idle_pose(facing: String, i: int) -> Dictionary:
	var pose: Dictionary = _base_pose(facing)
	var breath: float = [0.0, 0.0, 1.0, 1.0][i]
	pose["body"] = Vector2(0, breath)
	pose["hand_l"] = (pose["hand_l"] as Vector2) + Vector2(0, breath)
	pose["hand_r"] = (pose["hand_r"] as Vector2) + Vector2(0, breath)
	pose["orb"] = (pose["orb"] as Vector2) + Vector2(0, [0.0, -1.0, -1.0, 0.0][i])
	pose["orb_r"] = [1.6, 1.9, 1.6, 1.4][i]
	pose["flicker"] = i
	return pose


## The robe glides: no legs show, the hem swings and the body bobs a little.
func _walk_pose(facing: String, i: int) -> Dictionary:
	var t: float = TAU * i / WALK_FRAMES
	var pose: Dictionary = _base_pose(facing)
	var bob: float = 1.0 if absf(sin(t)) > 0.6 else 0.0
	pose["body"] = Vector2(0, bob)
	pose["sway"] = roundf(sin(t))
	pose["hand_l"] = (pose["hand_l"] as Vector2) + Vector2(0, bob - roundf(sin(t) * 0.6))
	pose["hand_r"] = (pose["hand_r"] as Vector2) + Vector2(0, bob + roundf(sin(t) * 0.6))
	pose["orb"] = (pose["orb"] as Vector2) + Vector2(0, bob + roundf(sin(t) * 0.6))
	pose["flicker"] = i
	return pose


## 0-5: both hands rise and the witchfire swells between them, burning brighter (the telegraph),
## 6: the hands thrust out and the bolt is gone (release, with a flash), 7: recover.
func _attack_pose(facing: String, i: int) -> Dictionary:
	var pose: Dictionary = _base_pose(facing)
	var rise: float = minf(i / 5.0, 1.0)
	pose["flicker"] = i
	pose["flash"] = i == RELEASE_FRAME
	if facing == "side":
		if i < RELEASE_FRAME:
			pose["hand_r"] = Vector2(19.5, 19.5).lerp(Vector2(18.5, 10.5), rise)
			pose["hand_l"] = Vector2(14, 20).lerp(Vector2(16, 10), rise)
			pose["orb"] = Vector2(20.5, 17.5).lerp(Vector2(18.5, 7.5), rise)
			pose["body"] = Vector2(-roundf(rise), 0)
		elif i == RELEASE_FRAME:
			pose["hand_r"] = Vector2(25, 15.5)
			pose["hand_l"] = Vector2(23, 16.5)
			pose["orb"] = Vector2(27.5, 15)
			pose["body"] = Vector2(1, 0)
		else:
			pose["hand_r"] = Vector2(22, 18)
			pose["hand_l"] = Vector2(18, 19)
	else:
		var up: bool = facing == "up"
		if i < RELEASE_FRAME:
			pose["hand_l"] = Vector2(11.5, 20.5).lerp(Vector2(9.5, 8.5), rise)
			pose["hand_r"] = Vector2(20.5, 20).lerp(Vector2(22.5, 8.5), rise)
			pose["orb"] = Vector2(21, 17.5).lerp(Vector2(16, 4.0), rise)
			pose["body"] = Vector2(0, -roundf(rise))
		elif i == RELEASE_FRAME:
			pose["hand_l"] = Vector2(13, 13.5 if up else 21.5)
			pose["hand_r"] = Vector2(19, 13.5 if up else 21.5)
			pose["orb"] = Vector2(16, 8.0 if up else 24.0)
			pose["body"] = Vector2(0, -1 if up else 1)
		else:
			pose["hand_l"] = Vector2(12, 19.5)
			pose["hand_r"] = Vector2(20, 19.5)
	pose["orb_r"] = 0.0 if i == ATTACK_FRAMES - 1 else (1.6 + rise * 2.0 if i < RELEASE_FRAME else 2.6)
	return pose


# ---------------------------------------------------------------- frames

func frame(facing: String, pose: Dictionary) -> Image:
	var c: Canvas = Canvas.new(SIZE.x, SIZE.y)
	if facing == "side":
		_draw_side(c, pose)
	else:
		_draw_front(c, pose, facing == "down")
	c.finish()
	c.ground_shadow(FEET + Vector2(0, -0.5), Vector2(6.5, 2.0))
	return c.image


## Front (facing the camera) and back views: the same robe and hood; the face and the chest
## pendant only show from the front.
func _draw_front(c: Canvas, pose: Dictionary, front: bool) -> void:
	var body: Vector2 = pose["body"]
	var kneel: float = pose["kneel"]
	var hand_l: Vector2 = pose["hand_l"]
	var hand_r: Vector2 = pose["hand_r"]
	var arms_up: bool = hand_l.y < 17.0
	if not front:
		_orb(c, pose)  # in front of it, so behind the body from the back
	# The robe: narrow at the shoulders, flaring to a ragged hem on the ground.
	_robe(c, 16.0 + body.x, 14.5 + body.y + kneel, FEET.y, 4.2, 6.8, float(pose["sway"]), front)
	c.part()
	c.ellipse(Vector2(16, 16) + body + Vector2(0, kneel), Vector2(4.4, 2.6), P.CULT_ROBE, 0.0, 0.02)
	if front:
		# A dark sash and a bone pendant on the chest.
		c.rect(Rect2i(roundi(12.5 + body.x), roundi(19 + body.y + kneel), 7, 1), P.CULT_DARK[2])
		c.px(roundi(16 + body.x), roundi(17 + body.y + kneel), P.BONE[3])
		c.px(roundi(16 + body.x), roundi(18 + body.y + kneel), P.BONE[1])
	if arms_up:
		# Raised arms beside the hood: over the robe, under the hood.
		_sleeve(c, Vector2(12, 15.5) + body, hand_l)
		_sleeve(c, Vector2(20, 15.5) + body, hand_r)
	_hood(c, Vector2(16, 11.5) + body + Vector2(0, kneel), "down" if front else "up", pose)
	if not arms_up:
		_sleeve(c, Vector2(12.5, 15.5) + body + Vector2(0, kneel), hand_l)
		_sleeve(c, Vector2(19.5, 15.5) + body + Vector2(0, kneel), hand_r)
	if front:
		_orb(c, pose)


func _draw_side(c: Canvas, pose: Dictionary) -> void:
	var body: Vector2 = pose["body"]
	_sleeve(c, Vector2(16, 15.5) + body, pose["hand_l"], -0.1)  # the far arm, darker
	_robe(c, 15.5 + body.x, 14.5 + body.y, FEET.y, 3.8, 6.2, float(pose["sway"]), false, 0.6)
	c.part()
	c.ellipse(Vector2(15.5, 16) + body, Vector2(3.8, 2.6), P.CULT_ROBE, 0.0, 0.02)
	_hood(c, Vector2(16.5, 11.5) + body, "side", pose)
	_sleeve(c, Vector2(15.5, 15.5) + body, pose["hand_r"])
	_orb(c, pose)


# ---------------------------------------------------------------- body parts

## A flared robe from the shoulders (top_y, half width `top`) to the hem (bottom_y, `bottom`),
## shaded as a cone, with fold lines and a ragged hem. lean shifts the hem forward (side view).
func _robe(c: Canvas, cx: float, top_y: float, bottom_y: float, top: float, bottom: float, sway: float,
		opening: bool, lean: float = 0.0) -> void:
	c.part()
	for y: int in range(floori(top_y), ceili(bottom_y)):
		var t: float = (y + 0.5 - top_y) / (bottom_y - top_y)
		var half: float = lerpf(top, bottom, t)
		var mid: float = cx + (sway * 0.8 + lean) * t
		for x: int in range(floori(mid - half), ceili(mid + half)):
			var nx: float = (x + 0.5 - mid) / half
			if absf(nx) > 1.0:
				continue
			# Ragged hem: every other fold hangs one pixel lower.
			if y == ceili(bottom_y) - 1 and posmod(x + roundi(sway), 3) == 0:
				continue
			var normal: Vector3 = Vector3(nx, -0.15, sqrt(1.0 - nx * nx))
			c.px(x, y, Canvas.shade(P.CULT_ROBE, Canvas.light_of(normal) - 0.05))
	# Folds down the skirt.
	for k: float in [-0.5, 0.45]:
		var x0: float = cx + top * k * 0.6
		var x1: float = cx + bottom * k + sway * 0.8 + lean
		c.line(Vector2(x0, top_y + 4), Vector2(x1, bottom_y - 2), P.CULT_ROBE[1] if k < 0 else P.CULT_ROBE[2])
	if opening:
		c.line(Vector2(cx, top_y + 4), Vector2(cx + sway * 0.8, bottom_y - 1), P.CULT_ROBE[2])


## A wide sleeve from the shoulder to a pale, bony hand.
func _sleeve(c: Canvas, shoulder: Vector2, hand: Vector2, bias: float = 0.0) -> void:
	var cuff: Vector2 = shoulder.lerp(hand, 0.8)
	c.part()
	c.capsule(shoulder, cuff, 1.6, P.CULT_ROBE, bias)
	c.part()
	c.ellipse(hand, Vector2(1.1, 1.1), P.BONE, 0.0, bias)


## The tall pointed hood. From the front: a black hollow with two witchfire eyes.
func _hood(c: Canvas, at: Vector2, facing: String, pose: Dictionary) -> void:
	var tip: Vector2 = at + (Vector2(-2.5, -6.5) if facing == "side" else Vector2(0, -7))
	c.part()
	c.polygon(PackedVector2Array([at + Vector2(-3.2, -1.5), tip, at + Vector2(3.2, -1.5)]), P.CULT_ROBE.slice(1, 5), Vector3(-0.4, -0.6, 1))
	c.ellipse(at, Vector2(4.0, 3.8), P.CULT_ROBE, 0.0, 0.03)
	var bright: int = 4 if int(pose["flicker"]) % 2 == 0 else 3
	match facing:
		"down":
			var e: Vector2i = Vector2i((at + Vector2(0, 1)).round())
			c.ellipse(Vector2(e) + Vector2(0, 0.2), Vector2(2.4, 2.2), P.CULT_DARK, 0.0, -0.3)
			c.px(e.x - 1, e.y, P.WITCHFIRE[bright])
			c.px(e.x + 1, e.y, P.WITCHFIRE[bright])
			c.px(e.x - 1, e.y + 1, P.WITCHFIRE[2])
			c.px(e.x + 1, e.y + 1, P.WITCHFIRE[2])
		"up":
			c.line(at + Vector2(0, -3), at + Vector2(0, 3), P.CULT_ROBE[2])
		_:
			var f: Vector2i = Vector2i((at + Vector2(2.2, 1)).round())
			c.ellipse(Vector2(f), Vector2(1.6, 2.0), P.CULT_DARK, 0.0, -0.3)
			c.px(f.x, f.y, P.WITCHFIRE[bright])
			c.px(f.x, f.y + 1, P.WITCHFIRE[2])


## The ball of witchfire (soft: no outline) with a few sparks; brighter while it swells.
func _orb(c: Canvas, pose: Dictionary) -> void:
	var r: float = pose["orb_r"]
	if r <= 0.0:
		return
	var at: Vector2 = pose["orb"]
	c.part(true)
	c.ellipse(at, Vector2(r, r), P.WITCHFIRE.slice(1, 4), 0.0, 0.25)
	c.ellipse(at + Vector2(-0.3, -0.3), Vector2(r * 0.5, r * 0.5), P.WITCHFIRE.slice(3, 5), 0.0, 0.3)
	var f: int = pose["flicker"]
	for k: int in 2:
		var spark: Vector2 = at + Vector2([-1.0, 1.5, 0.5, -1.5][(f + k) % 4] * (r + 0.5), -r - 1.0 - (f + k) % 3)
		c.px(roundi(spark.x), roundi(spark.y), P.WITCHFIRE[3 + k % 2])
	if pose["flash"]:
		for d: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
			c.px(roundi(at.x + d.x * (r + 1.5)), roundi(at.y + d.y * (r + 1.5)), P.WITCHFIRE[4])


# ---------------------------------------------------------------- death

## A pale flash, it reels with the fire guttering, sinks to its knees, the robe falls empty in a heap,
## and the witchfire escapes as a soul.
func _death_frames() -> Array[Image]:
	var frames: Array[Image] = []
	var hit: Dictionary = _base_pose("down")
	hit["body"] = Vector2(0, -1)
	hit["hand_l"] = Vector2(10, 17)
	hit["hand_r"] = Vector2(22, 17)
	hit["orb_r"] = 2.4
	var first: Image = frame("down", hit)
	Undead.tint(first, Color("eef5e6"), 0.55)
	frames.append(first)
	var reel: Dictionary = _base_pose("down")
	reel["body"] = Vector2(1, 0)
	reel["sway"] = 1.0
	reel["hand_l"] = Vector2(11, 22)
	reel["hand_r"] = Vector2(22, 19)
	reel["orb_r"] = 1.0
	frames.append(frame("down", reel))
	var kneel: Dictionary = _base_pose("down")
	kneel["kneel"] = 4.0
	kneel["body"] = Vector2(0, 0)
	kneel["hand_l"] = Vector2(11, 25)
	kneel["hand_r"] = Vector2(21, 25)
	kneel["orb_r"] = 0.0
	frames.append(frame("down", kneel))
	var heap: Image = _heap()
	frames.append(heap)
	for step: int in 3:
		var fading: Image = heap.duplicate() as Image
		Undead.crumble(fading, step)
		Undead.soul(fading, step, Vector2(16, 22))
		frames.append(fading)
	return frames


## The empty robe in a heap on the ground, the hood on top.
func _heap() -> Image:
	var c: Canvas = Canvas.new(SIZE.x, SIZE.y)
	c.part()
	c.ellipse(Vector2(16, 26), Vector2(7.5, 2.6), P.CULT_ROBE, 0.4, -0.05)
	c.part()
	c.ellipse(Vector2(13.5, 24.5), Vector2(3.4, 2.4), P.CULT_ROBE, 0.0, 0.02)
	c.line(Vector2(10, 26), Vector2(21, 27), P.CULT_ROBE[1])
	c.px(13, 24, P.CULT_DARK[0])
	c.px(14, 24, P.CULT_DARK[0])
	c.finish()
	c.ground_shadow(Vector2(16, FEET.y - 1), Vector2(10, 2.2))
	return c.image


# ---------------------------------------------------------------- the shot

## Row 0: the flying bolt (2 frames, flickering, a short tail). Row 1: its burst (4 frames).
func fx_rows() -> Array[Array]:
	var bolt: Array[Image] = []
	for f: int in 2:
		var c: Canvas = Canvas.new(FX_SIZE.x, FX_SIZE.y)
		c.part(true)
		c.ellipse(Vector2(8, 8), Vector2(3.6, 3.4), P.WITCHFIRE.slice(1, 4), 0.0, 0.2)
		c.ellipse(Vector2(7.5, 7.5), Vector2(1.8, 1.7), P.WITCHFIRE.slice(3, 5), 0.0, 0.3)
		for k: int in 3:
			c.px(3 + k * 5 - f, 2 + (k + f) % 2 * 11, P.WITCHFIRE[2 + (k + f) % 2])
		bolt.append(c.finish(false))
	var burst: Array[Image] = []
	for f: int in 4:
		var c: Canvas = Canvas.new(FX_SIZE.x, FX_SIZE.y)
		c.part(true)
		var r: float = 2.5 + f * 1.6
		for a: int in 10:
			var angle: float = TAU * a / 10.0 + f * 0.3
			var p: Vector2 = Vector2(8, 8) + Vector2(cos(angle), sin(angle)) * r
			if f == 3 and a % 2 == 0:
				continue
			c.px(roundi(p.x), roundi(p.y), P.WITCHFIRE[4 - mini(f, 2)])
		if f < 2:
			c.ellipse(Vector2(8, 8), Vector2(2.4 - f, 2.4 - f), P.WITCHFIRE.slice(3, 5), 0.0, 0.3)
		burst.append(c.finish(false))
	return [bolt, burst]
