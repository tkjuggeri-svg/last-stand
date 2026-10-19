extends RefCounted
## The Lich Warden, boss of wave 15 (dev-time art generator): a floating skeletal sorcerer-king in a
## deep violet robe with gold trim, a gold crown on a bare skull with cold blue eyes, bony hands, and
## a staff crowned by a pale-blue ward crystal. No legs: its hem frays into drifting wisps above the
## ground. Its mechanic is warding the enemies around it, so its cast raises the staff and the crystal
## flares inside a ring of runes. 64x64 art px (boss_art_kit.gd).

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")
const Kit: GDScript = preload("res://tools/art/boss_art_kit.gd")

const FEET: Vector2 = Kit.FEET
## It floats: the hem hangs this far above the ground line.
const HOVER: float = 6.0


func sheet_rows() -> Array[Array]:
	return Kit.sheet_rows(self, ["cast"])


# ---------------------------------------------------------------- poses

## hand_r holds the staff (staff: its direction from the hand), hand_l is free. glow: the crystal's
## brightness 0-1. float: the hover bob.
func pose(state: String, facing: String, i: int) -> Dictionary:
	var side: bool = facing == "side"
	var p: Dictionary = {"float": 0.0, "sway": 0.0, "staff": Vector2.UP, "glow": 0.4, "runes": -1, "flicker": i,
		"hand_l": Vector2(28, 36) if side else Vector2(20, 37),
		"hand_r": Vector2(40, 34) if side else Vector2(45, 35)}
	match state:
		"idle":
			p["float"] = [0.0, -1.0, -2.0, -1.0][i]
		"walk":
			# It glides: the bob and the trailing hem do the walking.
			p["float"] = [0.0, -1.0, -2.0, -2.0, -1.0, 0.0][i]
			p["sway"] = [-1.0, -2.0, -2.0, -1.0, -1.0, -1.0][i] if side else [0.0, 1.0, 1.0, 0.0, -1.0, -1.0][i]
		"attack":
			# 0-5 draw the staff back, the crystal charging; 6 thrust it forward (flash); 7 recover.
			var rise: float = minf(i / 5.0, 1.0)
			if i < 6:
				p["hand_r"] = (p["hand_r"] as Vector2).lerp(Vector2(34, 26) if side else Vector2(44, 26), rise)
				p["staff"] = Vector2.UP.rotated(-rise * (0.9 if side else 0.3))
				p["glow"] = 0.4 + rise * 0.5
			elif i == 6:
				p["hand_r"] = Vector2(48, 34) if side else Vector2(40, 42)
				p["staff"] = Vector2(1, -0.2).normalized() if side else Vector2(0.1, 1).normalized()
				p["glow"] = 1.0
			else:
				p["hand_r"] = Vector2(43, 34) if side else Vector2(44, 37)
				p["staff"] = Vector2(0.4, -1).normalized()
			p["float"] = -1.0
		"cast":
			var lift: float = minf((i + 1) / 3.0, 1.0)
			p["hand_r"] = (p["hand_r"] as Vector2).lerp(Vector2(40, 24) if side else Vector2(44, 24), lift)
			p["hand_l"] = (p["hand_l"] as Vector2).lerp(Vector2(44, 30) if side else Vector2(14, 28), lift)
			p["glow"] = 0.6 + lift * 0.4
			p["runes"] = i
			p["float"] = -2.0 - lift
	return p


# ---------------------------------------------------------------- frames

func frame(facing: String, p: Dictionary) -> Image:
	var c: Canvas = Canvas.new(Kit.SIZE.x, Kit.SIZE.y)
	var lift: Vector2 = Vector2(0, float(p["float"]))
	p["lift"] = lift
	if facing == "side":
		_draw_side(c, p)
	else:
		_draw_front(c, p, facing == "down")
	_draw_soft(c, p)
	c.finish()
	c.ground_shadow(FEET + Vector2(0, -1), Vector2(11, 2.6))
	return c.image


func _draw_front(c: Canvas, p: Dictionary, front: bool) -> void:
	var lift: Vector2 = p["lift"]
	var head_at: Vector2 = Vector2(32, 15) + lift
	if not front:
		_head(c, head_at, "up")
	_staff(c, p, true)
	Kit.robe(c, P.LICH_ROBE, 32, 23 + lift.y, FEET.y - HOVER + lift.y, 8.0, 13.0, float(p["sway"]))
	# The gold trim down the front and along the hem; a high collar.
	if front:
		c.line(Vector2(32, 26) + lift, Vector2(32 + float(p["sway"]), FEET.y - HOVER - 1 + lift.y), P.GOLD[2])
		c.line(Vector2(31, 26) + lift, Vector2(31 + float(p["sway"]), FEET.y - HOVER - 1 + lift.y), P.GOLD[1])
	c.part()
	c.ellipse(Vector2(32, 23) + lift, Vector2(11, 5.5), P.LICH_ROBE, 0.0, 0.04)
	c.line(Vector2(22, 25) + lift, Vector2(42, 25) + lift, P.GOLD[2])
	c.part()
	c.polygon(PackedVector2Array([Vector2(24, 22) + lift, Vector2(25, 13) + lift, Vector2(28, 19) + lift]), P.LICH_ROBE.slice(2, 6), Vector3(-0.5, -0.4, 1))
	c.polygon(PackedVector2Array([Vector2(40, 22) + lift, Vector2(39, 13) + lift, Vector2(36, 19) + lift]), P.LICH_ROBE.slice(1, 5), Vector3(0.5, -0.4, 1))
	_arm(c, Vector2(23, 25) + lift, p["hand_l"])
	_arm(c, Vector2(41, 25) + lift, p["hand_r"])
	if front:
		_head(c, head_at, "down")
	_staff(c, p, false)


func _draw_side(c: Canvas, p: Dictionary) -> void:
	var lift: Vector2 = p["lift"]
	_arm(c, Vector2(31, 25) + lift, p["hand_l"], -0.12)
	_staff(c, p, true)
	Kit.robe(c, P.LICH_ROBE, 30, 23 + lift.y, FEET.y - HOVER + lift.y, 7.0, 11.0, float(p["sway"]) - 2.0)
	c.part()
	c.ellipse(Vector2(30, 23) + lift, Vector2(9, 5.5), P.LICH_ROBE, 0.0, 0.04)
	c.line(Vector2(22, 25) + lift, Vector2(37, 25) + lift, P.GOLD[2])
	c.part()
	c.polygon(PackedVector2Array([Vector2(24, 22) + lift, Vector2(25, 12) + lift, Vector2(29, 19) + lift]), P.LICH_ROBE.slice(2, 6), Vector3(-0.5, -0.4, 1))
	_head(c, Vector2(34, 15) + lift, "side")
	_arm(c, Vector2(33, 26) + lift, p["hand_r"])
	_staff(c, p, false)


# ---------------------------------------------------------------- parts

## A skeletal arm in a wide sleeve.
func _arm(c: Canvas, shoulder: Vector2, hand: Vector2, bias: float = 0.0) -> void:
	var cuff: Vector2 = shoulder.lerp(hand, 0.7)
	c.part()
	c.capsule(shoulder, cuff, 2.6, P.LICH_ROBE, bias)
	c.part()
	c.capsule(cuff, hand, 0.9, P.BONE, bias)
	c.ellipse(hand, Vector2(1.6, 1.5), P.BONE, 0.0, bias)
	c.rect(Rect2i(roundi(cuff.x) - 2, roundi(cuff.y), 5, 1), P.GOLD[2])


func _staff(c: Canvas, p: Dictionary, back: bool) -> void:
	var hand: Vector2 = p["hand_r"]
	var dir: Vector2 = p["staff"]
	if back:
		c.part()
		c.capsule(hand - dir * 12.0, hand, 1.0, P.DARK_STEEL, -0.05)
		return
	var top: Vector2 = hand + dir * 16.0
	c.part()
	c.capsule(hand, top, 1.0, P.DARK_STEEL, 0.0)
	# Two gold prongs hold the crystal.
	var across: Vector2 = Vector2(-dir.y, dir.x)
	c.line(top, top + dir * 3.0 + across * 2.5, P.GOLD[3])
	c.line(top, top + dir * 3.0 - across * 2.5, P.GOLD[2])
	var gem: Vector2 = top + dir * 5.0
	c.part(true)
	c.polygon(PackedVector2Array([gem + dir * 4.0, gem + across * 2.4, gem - dir * 3.0, gem - across * 2.4]),
		P.ICE.slice(2, 6), Vector3(-0.4, -0.5, 1))
	c.px(roundi(gem.x) - 1, roundi(gem.y) - 1, P.ICE[5])
	p["gem_at"] = gem


## A bare skull under a gold crown, with cold blue eyes.
func _head(c: Canvas, at: Vector2, facing: String) -> void:
	c.part()
	c.ellipse(at, Vector2(5.0, 5.0), P.BONE, 0.0, 0.0)
	var e: Vector2i = Vector2i(at.round())
	if facing == "down":
		for dx: int in [-3, 1]:
			c.rect(Rect2i(e.x + dx, e.y - 1, 2, 2), P.OUTLINE)
			c.px(e.x + dx + (1 if dx < 0 else 0), e.y - 1, P.ARCANE_ICE[3])
		c.px(e.x, e.y + 1, P.BONE[0])
		c.rect(Rect2i(e.x - 2, e.y + 3, 5, 1), P.OUTLINE)
		c.px(e.x - 1, e.y + 3, P.BONE[3])
		c.px(e.x + 1, e.y + 3, P.BONE[3])
	elif facing == "side":
		c.rect(Rect2i(e.x + 1, e.y - 1, 2, 2), P.OUTLINE)
		c.px(e.x + 2, e.y - 1, P.ARCANE_ICE[3])
		c.rect(Rect2i(e.x + 1, e.y + 3, 3, 1), P.OUTLINE)
	# The crown.
	c.part()
	c.rect(Rect2i(e.x - 5, e.y - 5, 11, 2), P.GOLD[2])
	c.rect(Rect2i(e.x - 5, e.y - 5, 11, 1), P.GOLD[3])
	for k: int in 4:
		var x: int = e.x - 5 + k * 3 + (1 if k > 1 else 0)
		c.rect(Rect2i(x, e.y - 8, 1, 3), P.GOLD[3])
		c.px(x, e.y - 9, P.GOLD[4])
	c.px(e.x, e.y - 4, P.ARCANE_ICE[3])


## Soft extras: the hem's drifting wisps, the crystal's glow and the rune ring of the cast.
func _draw_soft(c: Canvas, p: Dictionary) -> void:
	var lift: Vector2 = p["lift"]
	var f: int = p["flicker"]
	c.part(true)
	for k: int in 6:
		var x: int = 22 + k * 4 + roundi(float(p["sway"]))
		var y: int = roundi(FEET.y - HOVER + lift.y) + (k + f) % 3
		c.px(x, y, P.LICH_ROBE[4] if k % 2 == 0 else P.ARCANE_ICE[1])
		c.px(x + 1, y + 2, P.ARCANE_ICE[2])
	if p.has("gem_at"):
		var gem: Vector2 = p["gem_at"]
		var glow: float = p["glow"]
		var r: float = 3.0 + glow * 4.0
		for a: int in 10:
			if (a + f) % 2 == 0:
				var spark: Vector2 = gem + Vector2.from_angle(TAU * a / 10.0) * r
				c.px(roundi(spark.x), roundi(spark.y), P.ARCANE_ICE[3] if glow < 0.9 else P.ARCANE_ICE[4])
	var runes: int = p["runes"]
	if runes >= 0:
		for k: int in 8:
			var a2: float = TAU * k / 8.0 + runes * 0.25
			var rune: Vector2 = Vector2(32, 40) + lift + Vector2(cos(a2) * 22.0, sin(a2) * 8.0)
			c.px(roundi(rune.x), roundi(rune.y), P.ARCANE_ICE[3])
			c.px(roundi(rune.x) + 1, roundi(rune.y), P.ARCANE_ICE[2])


# ---------------------------------------------------------------- death

func death_frames() -> Array[Image]:
	var stagger: Dictionary = pose("idle", "down", 0)
	stagger["float"] = 3.0
	stagger["staff"] = Vector2(0.7, -1).normalized()
	stagger["glow"] = 0.1
	var fallen_pose: Dictionary = pose("idle", "side", 0)
	fallen_pose["glow"] = 0.0
	var fallen: Image = Kit.lying(frame("side", fallen_pose), 20.0)
	return Kit.death(frame("down", pose("idle", "down", 0)), frame("down", stagger), fallen, Vector2(32, 50))
