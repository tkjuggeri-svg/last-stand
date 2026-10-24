extends RefCounted
## The Gravelord, boss of wave 5 (dev-time art generator): a towering, hunched corpse-priest in a
## grave-moss shroud, a crown of bone spikes burning with green fire, red eyes, long grey arms, and a
## crooked staff with a soul lantern. Its mechanic is raising the dead, so its cast lifts the lantern
## high while its free claw rakes at the ground and green wisps rise. 64x64 art px (boss_art_kit.gd).

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")
const Kit: GDScript = preload("res://tools/art/boss_art_kit.gd")

const FEET: Vector2 = Kit.FEET
const STAFF_LENGTH: float = 30.0


## Image pixels per art pixel: Layouts.FINE (2) for the double-resolution sheets the game uses.
var detail: int = 1


func _init(resolution: int = 1) -> void:
	detail = resolution


func sheet_rows() -> Array[Array]:
	return Kit.sheet_rows(self, ["cast"])


# ---------------------------------------------------------------- poses

## hand_l: the free claw (screen left from the front, the far side in profile); hand_r holds the
## staff; staff: the staff's direction from the hand (up = upright). lantern: glow strength 0-1.
func pose(state: String, facing: String, i: int) -> Dictionary:
	var side: bool = facing == "side"
	var p: Dictionary = {"body": Vector2.ZERO, "head": Vector2.ZERO, "sway": 0.0, "staff": Vector2.UP,
		"lantern": 0.5, "flicker": i, "wisps": 0, "dust": false,
		"hand_l": Vector2(28, 36) if side else Vector2(19, 39),
		"hand_r": Vector2(42, 35) if side else Vector2(45, 37)}
	match state:
		"idle":
			var breath: float = [0.0, 0.0, 1.0, 1.0][i]
			p["body"] = Vector2(0, breath)
			p["head"] = Vector2(0, breath + [0.0, 0.0, 0.0, 1.0][i])
			p["hand_l"] = (p["hand_l"] as Vector2) + Vector2(0, [0.0, 1.0, 1.0, 0.0][i])
			p["staff"] = Vector2.UP.rotated([0.0, 0.03, 0.05, 0.03][i])
		"walk":
			var t: float = TAU * i / 6.0
			var bob: float = 1.0 if absf(cos(t)) > 0.7 else 0.0
			p["body"] = Vector2(0, bob)
			p["head"] = Vector2(roundf(sin(t)) if not side else 0.0, bob)
			p["sway"] = roundf(sin(t) * 1.5)
			p["hand_l"] = (p["hand_l"] as Vector2) + Vector2(roundf(-sin(t) * 2.0) if side else 0.0, bob + roundf(sin(t)))
			p["hand_r"] = (p["hand_r"] as Vector2) + Vector2(roundf(sin(t) * 2.0) if side else 0.0, bob)
			p["staff"] = Vector2.UP.rotated(sin(t) * 0.12)
		"attack":
			# 0-5 heave the staff back overhead, 6 bring it crashing down (dust), 7 recover.
			var rise: float = minf(i / 5.0, 1.0)
			if i < 6:
				p["hand_r"] = (p["hand_r"] as Vector2).lerp(Vector2(38, 25) if side else Vector2(43, 25), rise)
				p["staff"] = Vector2.UP.rotated(-rise * (1.2 if side else 0.5))
				p["body"] = Vector2(-roundf(rise) if side else 0.0, -roundf(rise))
				p["lantern"] = 0.5 + rise * 0.3
			elif i == 6:
				p["hand_r"] = Vector2(48, 40) if side else Vector2(40, 44)
				p["staff"] = Vector2(1, 0.25).normalized() if side else Vector2(0.15, 1).normalized()
				p["body"] = Vector2(2 if side else 0, 2)
				p["head"] = Vector2(2 if side else 0, 3)
				p["dust"] = true
			else:
				p["hand_r"] = Vector2(45, 38) if side else Vector2(43, 40)
				p["staff"] = Vector2(0.6, -1).normalized() if side else Vector2(0.2, -1).normalized()
				p["body"] = Vector2(1 if side else 0, 1)
		"cast":
			# The lantern rises overhead and flares; the claw rakes the ground; wisps rise.
			var lift: float = minf((i + 1) / 3.0, 1.0)
			p["hand_r"] = (p["hand_r"] as Vector2).lerp(Vector2(43, 25) if side else Vector2(46, 25), lift)
			p["staff"] = Vector2.UP.rotated(lift * 0.15)
			p["hand_l"] = (p["hand_l"] as Vector2).lerp(Vector2(34, 50) if side else Vector2(16, 50), lift)
			p["body"] = Vector2(0, roundf(lift))
			p["head"] = Vector2(0, -roundf(lift))
			p["lantern"] = 0.6 + lift * 0.4
			p["wisps"] = i + 1
	return p


# ---------------------------------------------------------------- frames

func frame(facing: String, p: Dictionary) -> Image:
	var c: Canvas = Canvas.new(Kit.SIZE.x, Kit.SIZE.y, detail)
	p["side"] = facing == "side"
	match facing:
		"down":
			_draw_front(c, p, true)
		"up":
			_draw_front(c, p, false)
		_:
			_draw_side(c, p)
	_draw_glow(c, p)
	c.finish()
	c.ground_shadow(FEET + Vector2(0, -1), Vector2(15, 3.6))
	return c.image


func _draw_front(c: Canvas, p: Dictionary, front: bool) -> void:
	var body: Vector2 = p["body"]
	var head_at: Vector2 = Vector2(32, 15) + (p["head"] as Vector2)
	if not front:
		_head(c, head_at + Vector2(0, 1), "up")
	_staff(c, p, true)
	# The shroud: a heavy mantle over hunched shoulders, the skirt flaring to a ragged hem.
	Kit.robe(c, P.GRAVE_SHROUD, 32 + body.x, 25 + body.y, FEET.y, 9.0, 15.0, float(p["sway"]))
	c.part()
	c.ellipse(Vector2(32, 25) + body, Vector2(12.5, 6.5), P.GRAVE_SHROUD, 0.0, 0.03)
	for k: int in [-7, -2, 4, 8]:
		c.line(Vector2(32 + k * 0.6, 31) + body, Vector2(32 + k * 1.1 + float(p["sway"]) * 0.6, FEET.y - 2), P.GRAVE_SHROUD[1])
	if front:
		# The shroud hangs open over a black inner robe and the ribs; a belt of bones and skulls.
		c.part()
		c.polygon(PackedVector2Array([Vector2(28, 28) + body, Vector2(36, 28) + body, Vector2(38.5 + float(p["sway"]), FEET.y - 1),
			Vector2(25.5 + float(p["sway"]), FEET.y - 1)]), P.CULT_DARK, Vector3(0, 0, 1))
		c.part()
		c.ellipse(Vector2(32, 31) + body, Vector2(3.6, 4.0), P.GHOUL_SKIN, 0.0, -0.02)
		for k: int in 3:
			var y: float = 29.5 + body.y + k * 1.4
			c.line(Vector2(29.5 + body.x, y), Vector2(31, y + 0.6), P.GHOUL_SKIN[1])
			c.line(Vector2(33 + body.x, y + 0.6), Vector2(34.5 + body.x, y), P.GHOUL_SKIN[1])
		_belt(c, Vector2(32, 37) + body)
	_arm(c, Vector2(21, 26) + body, p["hand_l"], -1.0)
	_arm(c, Vector2(43, 26) + body, p["hand_r"], 1.0)
	if front:
		_head(c, head_at, "down")
	_staff(c, p, false)


func _draw_side(c: Canvas, p: Dictionary) -> void:
	var body: Vector2 = p["body"]
	_arm(c, Vector2(32, 25) + body, p["hand_l"], 1.0, -0.12)
	_staff(c, p, true)
	Kit.robe(c, P.GRAVE_SHROUD, 30 + body.x, 25 + body.y, FEET.y, 8.0, 13.0, float(p["sway"]) + 1.0)
	c.part()
	# The hunched back: a hump of shroud, the head thrust forward.
	c.ellipse(Vector2(29, 26) + body, Vector2(9.5, 6.5), P.GRAVE_SHROUD, 0.0, 0.03)
	c.line(Vector2(22, 28) + body, Vector2(21 + float(p["sway"]), FEET.y - 2), P.GRAVE_SHROUD[1])
	c.part()
	c.rect(Rect2i(roundi(25 + body.x), roundi(37 + body.y), 14, 2), P.BONE[1])
	c.px(roundi(37 + body.x), roundi(38 + body.y), P.BONE[3])
	_head(c, Vector2(42, 18) + (p["head"] as Vector2), "side")
	_arm(c, Vector2(35, 26) + body, p["hand_r"], 1.0)
	_staff(c, p, false)


# ---------------------------------------------------------------- parts

## A long, gaunt arm ending in a claw.
func _arm(c: Canvas, shoulder: Vector2, hand: Vector2, side: float, bias: float = 0.0) -> void:
	var elbow: Vector2 = shoulder.lerp(hand, 0.5) + Vector2(side * 2.5, 1.0)
	c.part()
	c.capsule(shoulder, elbow, 2.2, P.GRAVE_SHROUD, bias)  # the sleeve
	c.capsule(elbow, hand, 1.6, P.GHOUL_SKIN, bias - 0.03)
	c.part()
	c.ellipse(hand, Vector2(2.2, 2.0), P.GHOUL_SKIN, 0.0, bias)
	var reach: Vector2 = (hand - elbow).normalized()
	var across: Vector2 = Vector2(-reach.y, reach.x)
	for k: int in [-1, 0, 1]:
		var base: Vector2 = hand + reach * 1.6 + across * k * 1.3
		c.line(base, base + reach * 2.2 + across * k * 0.6, P.BONE[2])


## The crooked staff; the back half (behind the hand) is drawn first, the lantern last.
func _staff(c: Canvas, p: Dictionary, back: bool) -> void:
	var hand: Vector2 = p["hand_r"]
	var dir: Vector2 = p["staff"]
	if back:
		c.part()
		c.capsule(hand - dir * 10.0, hand, 1.1, P.DEAD_WOOD, -0.05)
		return
	var top: Vector2 = hand + dir * (STAFF_LENGTH - 10.0)
	var across: Vector2 = Vector2(-dir.y, dir.x)
	c.part()
	c.capsule(hand, top, 1.1, P.DEAD_WOOD, 0.0)
	var crook: Vector2 = top + across * 4.0 + dir * 1.5
	c.capsule(top, crook, 1.0, P.DEAD_WOOD, 0.0)
	# The lantern hangs from the crook.
	var lantern: Vector2 = crook + Vector2(0, 4)
	c.line(crook, lantern - Vector2(0, 2), P.IRON[3])
	c.part()
	c.rect(Rect2i(roundi(lantern.x) - 2, roundi(lantern.y) - 2, 5, 6), P.IRON[1])
	c.rect(Rect2i(roundi(lantern.x) - 1, roundi(lantern.y) - 1, 3, 4), P.SOUL[3] if float(p["lantern"]) < 0.8 else P.SOUL[4])
	c.rect(Rect2i(roundi(lantern.x) - 2, roundi(lantern.y) - 3, 5, 1), P.IRON[3])
	p["lantern_at"] = lantern


## A big skull for a face: deep sockets with red eyes, a jaw of teeth, a crown of bone spikes.
func _head(c: Canvas, at: Vector2, facing: String) -> void:
	c.part()
	c.ellipse(at, Vector2(7.0, 6.4), P.BONE, 0.0, 0.0)
	var e: Vector2i = Vector2i(at.round())
	match facing:
		"down":
			for dx: int in [-5, 2]:
				c.rect(Rect2i(e.x + dx, e.y - 1, 3, 3), P.OUTLINE)
				c.px(e.x + dx + 1, e.y, P.EYE_GLOW[3])
				c.px(e.x + dx + (2 if dx < 0 else 0), e.y, P.EYE_GLOW[2])
			c.px(e.x, e.y + 2, P.BONE[0])
			c.rect(Rect2i(e.x - 3, e.y + 4, 7, 2), P.OUTLINE)
			for x: int in [-3, -1, 1, 3]:
				c.px(e.x + x, e.y + 4, P.BONE[3])
		"side":
			c.rect(Rect2i(e.x + 2, e.y - 1, 3, 3), P.OUTLINE)
			c.px(e.x + 3, e.y, P.EYE_GLOW[3])
			c.part()
			c.ellipse(Vector2(e.x + 4, e.y + 5), Vector2(3.0, 1.8), P.BONE, 0.0, -0.1)
			c.rect(Rect2i(e.x + 2, e.y + 4, 5, 1), P.OUTLINE)
			c.px(e.x + 3, e.y + 4, P.BONE[3])
			c.px(e.x + 5, e.y + 4, P.BONE[3])
		_:
			c.line(Vector2(e.x - 3, e.y - 3), Vector2(e.x - 1, e.y + 3), P.BONE[1])
	# The crown of bone spikes.
	c.part()
	for k: int in 5:
		var x: float = at.x - 5.0 + k * 2.5
		var height: float = [3.0, 5.0, 6.5, 5.0, 3.0][k]
		c.polygon(PackedVector2Array([Vector2(x - 1.2, at.y - 4.5), Vector2(x, at.y - 4.5 - height), Vector2(x + 1.2, at.y - 4.5)]),
			P.GOLD.slice(0, 4), Vector3(-0.5, -0.4, 1))
	c.rect(Rect2i(roundi(at.x) - 6, roundi(at.y) - 5, 13, 1), P.GOLD[1])


## Soft things last (no outline): crown flames, the lantern's glow, rising wisps, slam dust.
func _draw_glow(c: Canvas, p: Dictionary) -> void:
	var f: int = p["flicker"]
	c.part(true)
	var head_at: Vector2 = (Vector2(42, 18) if p.get("side", false) else Vector2(32, 15)) + (p["head"] as Vector2)
	for k: int in [1, 2, 3]:
		var x: float = head_at.x - 5.0 + k * 2.5
		var height: float = [0.0, 5.0, 6.5, 5.0][k]
		var top: float = head_at.y - 5.0 - height
		var flick: int = (f + k) % 3
		c.px(roundi(x), roundi(top) - 1 - flick % 2, P.WITCHFIRE[3])
		c.px(roundi(x), roundi(top) - 2 - flick, P.WITCHFIRE[2])
	if p.has("lantern_at"):
		var at: Vector2 = p["lantern_at"]
		var r: float = 2.5 + float(p["lantern"]) * 3.0
		for a: int in 8:
			if (a + f) % 2 == 0:
				var spark: Vector2 = at + Vector2.from_angle(TAU * a / 8.0) * r
				c.px(roundi(spark.x), roundi(spark.y), P.SOUL[3] if float(p["lantern"]) < 0.9 else P.SOUL[4])
	var wisps: int = p["wisps"]
	for k: int in wisps:
		var base: Vector2 = Vector2(10 + k * 9, FEET.y - 2)
		for h: int in 3:
			c.px(roundi(base.x + sin(k + h + f) * 1.2), roundi(base.y - h * 3 - (f % 2)), P.SOUL[2 + h % 3])
	if p["dust"]:
		for k: int in 6:
			c.px(roundi(32 + (k - 2.5) * 6), roundi(FEET.y - 1 - (k % 2) * 2), P.SMOKE[3])


## A belt of bones with three small skulls hanging from it.
func _belt(c: Canvas, at: Vector2) -> void:
	c.part()
	c.rect(Rect2i(roundi(at.x) - 9, roundi(at.y), 19, 2), P.BONE[1])
	for k: int in 3:
		var skull: Vector2 = at + Vector2(-6 + k * 6, 3.5)
		c.part()
		c.ellipse(skull, Vector2(1.8, 1.6), P.BONE, 0.0, 0.05)
		c.px(roundi(skull.x) - 1, roundi(skull.y), P.OUTLINE)
		c.px(roundi(skull.x) + 1, roundi(skull.y), P.OUTLINE)


# ---------------------------------------------------------------- death

func death_frames() -> Array[Image]:
	var stagger: Dictionary = pose("idle", "down", 0)
	stagger["body"] = Vector2(2, 2)
	stagger["head"] = Vector2(3, 4)
	stagger["hand_l"] = Vector2(18, 46)
	stagger["staff"] = Vector2(0.6, -1).normalized()
	stagger["lantern"] = 0.2
	var fallen_pose: Dictionary = pose("idle", "side", 0)
	fallen_pose["lantern"] = 0.0
	var fallen: Image = Kit.lying(frame("side", fallen_pose), 22.0)
	return Kit.death(frame("down", pose("idle", "down", 0)), frame("down", stagger), fallen, Vector2(32, 50))
