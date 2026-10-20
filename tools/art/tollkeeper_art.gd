extends RefCounted
## The Tollkeeper, boss of chapter 2 (dev-time art generator): a hulking drowned bell-ringer in a
## sodden green-grey habit, stooped under a wooden yoke, with a cracked bronze bell green with
## verdigris hanging on its back above its head. A hollow hood with two cold eyes; big bloated hands;
## water dripping from the hem. Its mechanic is the toll, so its toll pose heaves the bell up over its
## head and swings it. A broad, hunched silhouette with the bell rising above it, unlike the thin Lich,
## the tall Gravelord and the horned Colossus. 64x64 art px (boss_art_kit.gd).

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")
const Kit: GDScript = preload("res://tools/art/boss_art_kit.gd")

const FEET: Vector2 = Kit.FEET
const HABIT: Array[Color] = [Color("141a19"), Color("233230"), Color("35494a"), Color("4a6463"), Color("66807c"), Color("8aa39c")]
const FLESH: Array[Color] = [Color("2a2f2c"), Color("4a554e"), Color("6f7d70"), Color("97a593"), Color("bccab4")]
const VERDIGRIS: Array[Color] = [Color("1f3d34"), Color("2f6b5a"), Color("4f9a80"), Color("82c4a6")]


func sheet_rows() -> Array[Array]:
	return Kit.sheet_rows(self, ["toll"])


# ---------------------------------------------------------------- poses

## bell: the bell's centre offset from its rest place above the back; tilt: its swing (-1..1);
## hand_l / hand_r: the hands; bob: the whole body's vertical bob; ring: the toll's sound ring (-1 = none).
func pose(state: String, facing: String, i: int) -> Dictionary:
	var side: bool = facing == "side"
	var p: Dictionary = {"bob": 0.0, "sway": 0.0, "bell": Vector2.ZERO, "tilt": 0.0, "ring": -1, "drip": i,
		"hand_l": Vector2(30, 42) if side else Vector2(18, 43),
		"hand_r": Vector2(40, 41) if side else Vector2(46, 43)}
	match state:
		"idle":
			p["bob"] = [0.0, 1.0, 1.0, 0.0][i]
			p["tilt"] = [0.0, 0.2, 0.0, -0.2][i]
		"walk":
			# A heavy, rolling gait: the bell lags behind every step.
			p["bob"] = [0.0, 1.0, 2.0, 1.0, 0.0, 1.0][i]
			p["sway"] = [-1.0, 0.0, 1.0, 1.0, 0.0, -1.0][i]
			p["tilt"] = [-0.3, 0.0, 0.3, 0.3, 0.0, -0.3][i]
		"attack":
			# 0-5 raise a fist; 6 the blow (the fist low and forward); 7 recover.
			var rise: float = minf(i / 5.0, 1.0)
			if i < 6:
				p["hand_r"] = (p["hand_r"] as Vector2).lerp(Vector2(38, 24) if side else Vector2(44, 22), rise)
			elif i == 6:
				p["hand_r"] = Vector2(50, 46) if side else Vector2(40, 52)
			p["bob"] = 1.0 if i == 6 else 0.0
		"toll":
			# Heave the bell up over the head (0-2), swing it (3-5): the sound ring spreads.
			var lift: float = minf((i + 1) / 3.0, 1.0)
			p["bell"] = Vector2(0, -2.0 * lift)
			p["tilt"] = 0.0 if i < 3 else [0.9, -0.9, 0.5][i - 3]
			p["hand_l"] = (p["hand_l"] as Vector2).lerp(Vector2(22, 12) if not side else Vector2(27, 12), lift)
			p["hand_r"] = (p["hand_r"] as Vector2).lerp(Vector2(42, 12) if not side else Vector2(30, 14), lift)
			p["ring"] = i - 3 if i >= 3 else -1
	return p


# ---------------------------------------------------------------- frames

func frame(facing: String, p: Dictionary) -> Image:
	var c: Canvas = Canvas.new(Kit.SIZE.x, Kit.SIZE.y)
	var lift: Vector2 = Vector2(0, float(p["bob"]))
	p["lift"] = lift
	p["side"] = facing == "side"
	if facing == "up":
		_body(c, p, false)
		_frame_and_bell(c, p)  # seen from behind, the bell hangs over the back
	else:
		_frame_and_bell(c, p)
		_body(c, p, facing == "down")
	_draw_soft(c, p)
	c.finish()
	c.ground_shadow(FEET + Vector2(0, -1), Vector2(14, 3.0))
	return c.image


func _body(c: Canvas, p: Dictionary, front: bool) -> void:
	var lift: Vector2 = p["lift"]
	var side: bool = p["side"]
	# The habit: broad and hunched (a hump behind the hood), the hem dragging on the ground.
	if side:
		Kit.robe(c, HABIT, 30, 26 + lift.y, FEET.y + lift.y * 0.3, 9.0, 13.0, float(p["sway"]) - 2.0)
		c.part()
		c.ellipse(Vector2(26, 27) + lift, Vector2(7.0, 6.0), HABIT, 0.0, 0.04)
	else:
		Kit.robe(c, HABIT, 32, 26 + lift.y, FEET.y + lift.y * 0.3, 11.0, 15.0, float(p["sway"]))
	# The yoke across the shoulders (end-on from the side).
	c.part()
	if side:
		c.capsule(Vector2(25, 25) + lift, Vector2(33, 25) + lift, 1.8, P.WOOD, 0.05)
	else:
		c.capsule(Vector2(15, 25) + lift, Vector2(49, 25) + lift, 1.8, P.WOOD, 0.05)
	if front:
		c.line(Vector2(22, 38) + lift, Vector2(42, 38) + lift, P.LEATHER[3])
		c.line(Vector2(30, 38) + lift, Vector2(29, 44) + lift, P.LEATHER[2])
	if side:
		_arm(c, Vector2(30, 28) + lift, p["hand_l"])
		_hood(c, Vector2(36, 22) + lift, "side")
		_arm(c, Vector2(33, 29) + lift, p["hand_r"])
	else:
		_arm(c, Vector2(22, 28) + lift, p["hand_l"])
		_arm(c, Vector2(42, 28) + lift, p["hand_r"])
		_hood(c, Vector2(32, 21) + lift, "down" if front else "up")


## A heavy sleeve and a big, bloated hand.
func _arm(c: Canvas, shoulder: Vector2, hand: Vector2) -> void:
	var cuff: Vector2 = shoulder.lerp(hand, 0.65)
	c.part()
	c.capsule(shoulder, cuff, 3.4, HABIT, 0.02)
	c.part()
	c.capsule(cuff, hand, 1.6, FLESH, 0.0)
	c.ellipse(hand, Vector2(2.8, 2.6), FLESH, 0.0, 0.05)


## The hood, low over the shoulders: a hollow with two cold eyes from the front, one from the side.
func _hood(c: Canvas, at: Vector2, facing: String) -> void:
	c.part()
	c.ellipse(at, Vector2(6.5, 6.0), HABIT, 0.0, 0.06)
	if facing == "down":
		c.part()
		c.ellipse(at + Vector2(0, 1.5), Vector2(3.8, 3.4), [P.OUTLINE, HABIT[0]], 0.0)
		var e: Vector2i = Vector2i((at + Vector2(0, 1)).round())
		c.px(e.x - 2, e.y, P.ICE[4])
		c.px(e.x + 1, e.y, P.ICE[4])
	elif facing == "side":
		c.part()
		c.ellipse(at + Vector2(3, 1.5), Vector2(2.6, 3.2), [P.OUTLINE, HABIT[0]], 0.0)
		var s: Vector2i = Vector2i((at + Vector2(3.5, 1)).round())
		c.px(s.x, s.y, P.ICE[4])


## The ringing frame: two posts up from the yoke and a crossbar, the cracked bronze bell hanging from
## it (verdigris on its shoulder, a crack down its side, the clapper below its mouth).
func _frame_and_bell(c: Canvas, p: Dictionary) -> void:
	var lift: Vector2 = p["lift"] + (p["bell"] as Vector2)
	var side: bool = p["side"]
	var bar_y: float = 2.0
	c.part()
	if side:
		c.capsule(Vector2(27, 26) + lift, Vector2(27, bar_y) + lift, 1.2, P.WOOD, 0.0)
		c.capsule(Vector2(21, bar_y) + lift, Vector2(33, bar_y) + lift, 1.2, P.WOOD, 0.05)
	else:
		for x: float in [22.0, 42.0]:
			c.capsule(Vector2(x, 26) + lift, Vector2(x, bar_y) + lift, 1.2, P.WOOD, 0.0)
		c.capsule(Vector2(21, bar_y) + lift, Vector2(43, bar_y) + lift, 1.2, P.WOOD, 0.05)
	var tilt: float = p["tilt"]
	var hang: Vector2 = Vector2(27 if side else 32, bar_y + 1.0) + lift
	var down: Vector2 = Vector2(sin(tilt * 0.6), cos(tilt * 0.6))
	var across: Vector2 = Vector2(down.y, -down.x)
	# The bell's outline from the crown down to the flared lip, as a curved profile.
	var profile: Array[Vector2] = [Vector2(2.5, 1.0), Vector2(4.5, 3.0), Vector2(5.0, 6.0), Vector2(5.5, 9.0), Vector2(7.5, 12.0), Vector2(8.5, 13.0)]
	var points: PackedVector2Array = PackedVector2Array()
	for k: Vector2 in profile:
		points.append(hang + across * k.x + down * k.y)
	for i: int in range(profile.size() - 1, -1, -1):
		points.append(hang - across * profile[i].x + down * profile[i].y)
	c.part()
	c.polygon(points, P.BRONZE.slice(0, 4), Vector3(-0.5, -0.3, 1))
	c.line(hang - across * 8.5 + down * 13.0, hang + across * 8.5 + down * 13.0, P.BRONZE[3])
	for k: int in 6:
		var spot: Vector2 = hang + across * (-3.5 + (k % 3) * 2.5) + down * (3.0 + floorf(k / 3.0) * 2.0)
		c.rect(Rect2i(roundi(spot.x), roundi(spot.y), 2, 1), VERDIGRIS[2] if k % 2 == 0 else VERDIGRIS[1])
	c.line(hang + across * 1.0 + down * 6.0, hang + across * 3.0 + down * 12.0, P.OUTLINE)
	c.part()
	c.ellipse(hang + down * 14.5, Vector2(1.6, 1.6), P.IRON, 0.0, 0.1)


## Soft extras: water dripping from the hem, and the toll's sound ring.
func _draw_soft(c: Canvas, p: Dictionary) -> void:
	var lift: Vector2 = p["lift"]
	var f: int = p["drip"]
	c.part(true)
	for k: int in 4:
		var x: int = 20 + k * 8 + roundi(float(p["sway"]))
		var y: int = roundi(FEET.y - 1 + lift.y * 0.3) + (k + f) % 3
		c.px(x, y, P.ICE[2])
	var ring: int = p["ring"]
	if ring >= 0:
		var r: float = 12.0 + ring * 8.0
		for k: int in 16:
			var a: float = TAU * k / 16.0
			var at: Vector2 = Vector2(32, 12) + lift + (p["bell"] as Vector2) + Vector2(cos(a) * r, sin(a) * r * 0.6)
			if at.x >= 0 and at.y >= 0 and at.x < Kit.SIZE.x and at.y < Kit.SIZE.y:
				c.px(roundi(at.x), roundi(at.y), P.BRONZE[4] if k % 2 == 0 else P.BRONZE[3])


# ---------------------------------------------------------------- death

func death_frames() -> Array[Image]:
	var stagger: Dictionary = pose("idle", "down", 0)
	stagger["bob"] = 3.0
	stagger["tilt"] = 0.8
	var fallen: Image = Kit.lying(frame("side", pose("idle", "side", 0)), 22.0)
	return Kit.death(frame("down", pose("idle", "down", 0)), frame("down", stagger), fallen, Vector2(32, 48))
