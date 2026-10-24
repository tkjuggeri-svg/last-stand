extends RefCounted
## The Bone Colossus, boss of wave 10 (dev-time art generator): a hulking brute of dark red sinew
## armoured in bone, a bull's skull for a head with two huge horns, bone pauldrons, iron-shod hooves
## and fists like boulders. Its mechanic is the charge: it braces (head down, pawing the ground),
## charges head-first, then stands stunned with stars round its head. 64x64 art px (boss_art_kit.gd).

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")
const Kit: GDScript = preload("res://tools/art/boss_art_kit.gd")

const FEET: Vector2 = Kit.FEET


## Image pixels per art pixel: Layouts.FINE (2) for the double-resolution sheets the game uses.
var detail: int = 1


func _init(resolution: int = 1) -> void:
	detail = resolution


func sheet_rows() -> Array[Array]:
	return Kit.sheet_rows(self, ["brace", "charge", "stun"])


# ---------------------------------------------------------------- poses

## Fists are absolute art positions (side view: fist_r is the near arm). lean: how far the head and
## chest are thrust forward and down (0 upright .. 1 charging).
func pose(state: String, facing: String, i: int) -> Dictionary:
	var side: bool = facing == "side"
	var p: Dictionary = {"body": Vector2.ZERO, "lean": 0.0, "lift_l": 0.0, "lift_r": 0.0, "stride": 0.0,
		"flicker": i, "dust": 0, "streaks": false, "stars": -1,
		"fist_l": Vector2(30, 44) if side else Vector2(15, 45),
		"fist_r": Vector2(36, 46) if side else Vector2(49, 45)}
	match state:
		"idle":
			var breath: float = [0.0, 0.0, 1.0, 1.0][i]
			p["body"] = Vector2(0, -breath)
			p["fist_l"] = (p["fist_l"] as Vector2) + Vector2(0, [0.0, 1.0, 1.0, 0.0][i])
			p["fist_r"] = (p["fist_r"] as Vector2) + Vector2(0, [1.0, 1.0, 0.0, 0.0][i])
		"walk":
			var t: float = TAU * i / 6.0
			var bob: float = 1.0 if absf(cos(t)) > 0.7 else 0.0
			p["body"] = Vector2(roundf(sin(t)) if not side else 0.0, bob)
			p["stride"] = sin(t)
			p["lift_l"] = maxf(sin(t), 0.0) * 3.0
			p["lift_r"] = maxf(-sin(t), 0.0) * 3.0
			p["fist_l"] = (p["fist_l"] as Vector2) + Vector2(-roundf(sin(t) * 3.0) if side else 0.0, bob + roundf(-sin(t)))
			p["fist_r"] = (p["fist_r"] as Vector2) + Vector2(roundf(sin(t) * 3.0) if side else 0.0, bob + roundf(sin(t)))
		"attack":
			# 0-5 both fists rise overhead, 6 the slam (dust), 7 recover.
			var rise: float = minf(i / 5.0, 1.0)
			if i < 6:
				var up_l: Vector2 = Vector2(30, 14) if side else Vector2(24, 12)
				var up_r: Vector2 = Vector2(34, 12) if side else Vector2(40, 12)
				p["fist_l"] = (p["fist_l"] as Vector2).lerp(up_l, rise)
				p["fist_r"] = (p["fist_r"] as Vector2).lerp(up_r, rise)
				p["body"] = Vector2(-roundf(rise * 2.0) if side else 0.0, -roundf(rise * 2.0))
			elif i == 6:
				p["fist_l"] = Vector2(48, 52) if side else Vector2(26, 54)
				p["fist_r"] = Vector2(52, 54) if side else Vector2(38, 54)
				p["body"] = Vector2(3 if side else 0, 3)
				p["lean"] = 0.5
				p["dust"] = 2
			else:
				p["fist_l"] = Vector2(40, 48) if side else Vector2(20, 48)
				p["fist_r"] = Vector2(44, 49) if side else Vector2(44, 48)
				p["body"] = Vector2(1 if side else 0, 1)
		"brace":
			# Head down, horns forward, one hoof pawing the ground.
			p["lean"] = 0.7
			p["body"] = Vector2(-2 if side else 0, 2)
			p["lift_r"] = [0.0, 3.0, 0.0, 0.0][i]
			p["lift_l"] = [0.0, 0.0, 0.0, 3.0][i]
			p["dust"] = 1 if i == 2 or i == 0 else 0
			p["fist_l"] = Vector2(26, 46) if side else Vector2(14, 47)
			p["fist_r"] = Vector2(34, 48) if side else Vector2(50, 47)
		"charge":
			var t2: float = TAU * i / 4.0
			p["lean"] = 1.0
			p["body"] = Vector2(4 if side else 0, 2 + roundf(absf(sin(t2))))
			p["stride"] = sin(t2) * 1.4
			p["lift_l"] = maxf(sin(t2), 0.0) * 4.0
			p["lift_r"] = maxf(-sin(t2), 0.0) * 4.0
			p["streaks"] = true
			p["fist_l"] = Vector2(30 - sin(t2) * 4.0, 44) if side else Vector2(16, 44 + roundf(sin(t2)))
			p["fist_r"] = Vector2(40 + sin(t2) * 4.0, 46) if side else Vector2(48, 44 - roundf(sin(t2)))
		"stun":
			p["lean"] = 0.4
			p["body"] = Vector2([0.0, 1.0, 0.0, -1.0][i], 2)
			p["stars"] = i
			p["fist_l"] = Vector2(28, 50) if side else Vector2(16, 51)
			p["fist_r"] = Vector2(34, 51) if side else Vector2(48, 51)
	return p


# ---------------------------------------------------------------- frames

func frame(facing: String, p: Dictionary) -> Image:
	var c: Canvas = Canvas.new(Kit.SIZE.x, Kit.SIZE.y, detail)
	if facing == "side":
		_draw_side(c, p)
	else:
		_draw_front(c, p, facing == "down")
	_draw_soft(c, p, facing)
	c.finish()
	c.ground_shadow(FEET + Vector2(0, -1), Vector2(17, 3.8))
	return c.image


func _draw_front(c: Canvas, p: Dictionary, front: bool) -> void:
	var body: Vector2 = p["body"]
	var lean: float = p["lean"]
	var head_at: Vector2 = Vector2(32, 18 + lean * 9.0) + body
	if not front:
		_head(c, head_at - Vector2(0, 2), "up", lean)
	_leg(c, Vector2(25, 41) + body * 0.5, Vector2(24, FEET.y - 2 - float(p["lift_l"])))
	_leg(c, Vector2(39, 41) + body * 0.5, Vector2(40, FEET.y - 2 - float(p["lift_r"])))
	# The barrel chest; from the front, a cage of bone plates over the sinew.
	c.part()
	c.ellipse(Vector2(32, 32) + body, Vector2(14, 11), P.HOUND_HIDE, 0.0, 0.0)
	if front:
		for k: int in 3:
			c.part()
			var y: float = 27.0 + k * 4.0
			c.ellipse(Vector2(32, y) + body, Vector2(8.5 - k * 1.5, 1.6), P.BONE, 0.5, 0.0)
		c.line(Vector2(32, 25) + body, Vector2(32, 39) + body, P.BONE[1])
	else:
		for k: int in 5:
			c.part()
			c.ellipse(Vector2(32, 24 + k * 3.5) + body, Vector2(1.8, 1.3), P.BONE, 0.0, 0.05)
	_arm(c, Vector2(19, 27) + body, p["fist_l"])
	_arm(c, Vector2(45, 27) + body, p["fist_r"])
	_pauldron(c, Vector2(19, 25) + body, -1.0)
	_pauldron(c, Vector2(45, 25) + body, 1.0)
	if front:
		_head(c, head_at, "down", lean)


func _draw_side(c: Canvas, p: Dictionary) -> void:
	var body: Vector2 = p["body"]
	var lean: float = p["lean"]
	var stride: float = p["stride"]
	_arm(c, Vector2(31, 27) + body, p["fist_l"], -0.12)
	_leg(c, Vector2(28, 41) + body * 0.5, Vector2(28 - stride * 6.0, FEET.y - 2 - float(p["lift_l"])), -0.12)
	_leg(c, Vector2(31, 41) + body * 0.5, Vector2(31 + stride * 6.0, FEET.y - 2 - float(p["lift_r"])))
	c.part()
	c.ellipse(Vector2(30 + lean * 2.0, 32 + lean * 2.0) + body, Vector2(13, 10.5), P.HOUND_HIDE, 0.0, 0.0)
	# Bone plates down the spine (behind) and over the chest (in front).
	for k: int in 4:
		c.part()
		c.ellipse(Vector2(20 + k * 2.5, 24 + k * 1.2) + body, Vector2(2.0, 1.4), P.BONE, 0.0, 0.05)
	c.part()
	c.ellipse(Vector2(39 + lean * 2.0, 34 + lean * 2.0) + body, Vector2(3.5, 6.0), P.BONE, 0.3, 0.0)
	_pauldron(c, Vector2(31, 25) + body, 1.0)
	_head(c, Vector2(42 + lean * 7.0, 21 + lean * 8.0) + body, "side", lean)
	_arm(c, Vector2(33, 28) + body, p["fist_r"])


# ---------------------------------------------------------------- parts

func _leg(c: Canvas, hip: Vector2, hoof: Vector2, bias: float = 0.0) -> void:
	var knee: Vector2 = hip.lerp(hoof, 0.5) + Vector2(0, -1)
	c.part()
	c.capsule(hip, knee, 4.0, P.HOUND_HIDE, bias)
	c.capsule(knee, hoof, 3.2, P.HOUND_HIDE, bias - 0.05)
	c.part()
	c.ellipse(knee, Vector2(2.4, 2.0), P.BONE, 0.0, bias)
	c.part()
	c.ellipse(hoof + Vector2(0, 0.5), Vector2(3.8, 2.0), P.IRON, 0.0, bias)


func _arm(c: Canvas, shoulder: Vector2, fist: Vector2, bias: float = 0.0) -> void:
	var elbow: Vector2 = shoulder.lerp(fist, 0.5) + Vector2(0, 1.5)
	c.part()
	c.capsule(shoulder, elbow, 4.0, P.HOUND_HIDE, bias)
	c.capsule(elbow, fist, 3.4, P.HOUND_HIDE, bias - 0.03)
	c.part()
	c.ellipse(fist, Vector2(4.4, 4.0), P.HOUND_HIDE, 0.0, bias + 0.03)
	for k: int in 3:
		c.px(roundi(fist.x - 2 + k * 2), roundi(fist.y - 2), P.BONE[3])


func _pauldron(c: Canvas, at: Vector2, side: float) -> void:
	c.part()
	c.ellipse(at, Vector2(6.5, 5.0), P.BONE, 0.0, 0.0)
	c.part()
	c.polygon(PackedVector2Array([at + Vector2(-1.5, -3.5), at + Vector2(side * 3.0, -9.5), at + Vector2(1.5, -3.5)]), P.BONE, Vector3(-0.5, -0.5, 1))


## The bull's skull: a long bone face with red-glowing sockets and two great horns.
func _head(c: Canvas, at: Vector2, facing: String, lean: float) -> void:
	var horn_rise: float = 6.0 - lean * 6.0  # head down: the horns point forward
	if facing == "side":
		c.part()
		c.capsule(at + Vector2(-2, -3), at + Vector2(6, -6 - horn_rise * 0.5), 1.8, P.BONE, 0.05)
		c.capsule(at + Vector2(6, -6 - horn_rise * 0.5), at + Vector2(10, -4 - horn_rise), 1.2, P.BONE, 0.08)
		c.part()
		c.ellipse(at, Vector2(5.5, 4.8), P.BONE, 0.0, 0.0)
		c.part()
		c.ellipse(at + Vector2(5, 2.5), Vector2(3.5, 2.6), P.BONE, 0.0, -0.05)
		c.rect(Rect2i(roundi(at.x) + 1, roundi(at.y) - 1, 2, 2), P.OUTLINE)
		c.px(roundi(at.x) + 2, roundi(at.y) - 1, P.EYE_GLOW[3])
		c.px(roundi(at.x) + 7, roundi(at.y) + 3, P.OUTLINE)
		return
	for s: float in [-1.0, 1.0]:
		c.part()
		var base: Vector2 = at + Vector2(s * 4.5, -3)
		var bend: Vector2 = at + Vector2(s * 11.0, -4 - horn_rise * 0.6)
		var tip: Vector2 = at + Vector2(s * 13.0, -8 - horn_rise)
		c.capsule(base, bend, 2.0, P.BONE, 0.05)
		c.capsule(bend, tip, 1.3, P.BONE, 0.1)
	c.part()
	c.ellipse(at, Vector2(5.5, 6.0), P.BONE, 0.0, 0.0)
	if facing == "down":
		var e: Vector2i = Vector2i(at.round())
		for dx: int in [-3, 2]:
			c.rect(Rect2i(e.x + dx, e.y - 2, 2, 2), P.OUTLINE)
			c.px(e.x + dx + (1 if dx < 0 else 0), e.y - 2, P.EYE_GLOW[3])
		c.part()
		c.ellipse(at + Vector2(0, 4), Vector2(3.4, 2.4), P.BONE, 0.0, -0.06)
		c.px(e.x - 1, e.y + 4, P.OUTLINE)
		c.px(e.x + 1, e.y + 4, P.OUTLINE)


## Soft extras (no outline): dust from the hooves, speed streaks, the stun stars.
func _draw_soft(c: Canvas, p: Dictionary, facing: String) -> void:
	c.part(true)
	var dust: int = p["dust"]
	for k: int in dust * 4:
		c.px(roundi(20 + k * 3.5 + (k % 2) * 2), roundi(FEET.y - 1 - (k % 3)), P.SMOKE[3 + k % 2])
	if p["streaks"]:
		for k: int in 4:
			var y: int = 22 + k * 7
			if facing == "side":
				c.rect(Rect2i(4 + (k % 2) * 3, y, 9 - (k % 2) * 3, 1), Color(0.9, 0.85, 0.75, 0.55))
			else:
				c.rect(Rect2i(8 + k * 14, 8 + (k % 2) * 4, 1, 6), Color(0.9, 0.85, 0.75, 0.55))
	var stars: int = p["stars"]
	if stars >= 0:
		var lean: float = p["lean"]
		var head_at: Vector2 = Vector2(32 if facing != "side" else 44, 12 + lean * 8.0)
		for k: int in 3:
			var a: float = TAU * k / 3.0 + stars * TAU / 12.0
			var star: Vector2 = head_at + Vector2(cos(a) * 9.0, sin(a) * 3.0 - 6.0)
			c.px(roundi(star.x), roundi(star.y), P.GOLD[4])
			c.px(roundi(star.x) + 1, roundi(star.y), P.GOLD[3])
			c.px(roundi(star.x) - 1, roundi(star.y), P.GOLD[3])
			c.px(roundi(star.x), roundi(star.y) - 1, P.GOLD[3])
			c.px(roundi(star.x), roundi(star.y) + 1, P.GOLD[3])


# ---------------------------------------------------------------- death

func death_frames() -> Array[Image]:
	var stagger: Dictionary = pose("stun", "down", 1)
	stagger["stars"] = -1
	stagger["body"] = Vector2(2, 4)
	var fallen: Image = Kit.lying(frame("side", pose("idle", "side", 0)), 24.0)
	return Kit.death(frame("down", pose("idle", "down", 0)), frame("down", stagger), fallen, Vector2(32, 50))
