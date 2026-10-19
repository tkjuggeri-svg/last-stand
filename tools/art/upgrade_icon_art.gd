extends RefCounted
## Run upgrade icons (dev-time art generator): 16x16 art px each, lit from the top-left with a dark
## outline like every other UI icon, saved pre-scaled to 2x (32x32) for the cards and the HUD row.

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")

const SIZE: int = 16
const IDS: Array[String] = ["honed_blade", "long_reach", "battle_rhythm", "iron_body", "second_wind", "berserker",
	"fletching", "eagle_eye", "quick_masons", "overcharge", "piercing", "hellfire", "deep_freeze",
	"masonry", "repairs", "thorns", "bounty", "treasury", "guild", "war_tax"]


func icon(id: String) -> Image:
	var c: Canvas = Canvas.new(SIZE, SIZE)
	call("_" + id, c)
	c.finish()
	var img: Image = c.image
	img.resize(SIZE * 2, SIZE * 2, Image.INTERPOLATE_NEAREST)
	return img


# ---------------------------------------------------------------- shared shapes

## A longsword from `hilt` to `tip`.
func _sword(c: Canvas, hilt: Vector2, tip: Vector2, blade: Array = P.STEEL) -> void:
	var dir: Vector2 = (tip - hilt).normalized()
	var across: Vector2 = Vector2(-dir.y, dir.x)
	c.part()
	c.capsule(hilt + dir * 2.5, tip, 1.0, blade, 0.1)
	c.line(hilt + dir * 3.0 - across * 0.4, tip - dir * 1.0 - across * 0.4, blade[blade.size() - 1])
	c.part()
	c.line(hilt + dir * 2.0 - across * 2.6, hilt + dir * 2.0 + across * 2.6, P.GOLD[2])
	c.capsule(hilt - dir * 0.5, hilt + dir * 1.5, 0.7, P.LEATHER)
	c.px(roundi(hilt.x - dir.x * 1.5), roundi(hilt.y - dir.y * 1.5), P.GOLD[3])


func _coin(c: Canvas, at: Vector2, radius: float = 4.5) -> void:
	c.part()
	c.ellipse(at, Vector2(radius, radius), P.GOLD, 0.0, 0.1)
	c.rect(Rect2i(roundi(at.x) - 1, roundi(at.y) - 2, 2, 4), P.GOLD[1])
	c.px(roundi(at.x) - 1, roundi(at.y) - 2, P.GOLD[4])


func _arrow(c: Canvas, tail: Vector2, head: Vector2) -> void:
	var dir: Vector2 = (head - tail).normalized()
	var across: Vector2 = Vector2(-dir.y, dir.x)
	c.part()
	c.line(tail, head - dir * 2.0, P.WOOD[3])
	c.polygon(PackedVector2Array([head, head - dir * 3.0 + across * 1.8, head - dir * 3.0 - across * 1.8]), P.STEEL, Vector3(-0.5, -0.5, 1))
	c.line(tail, tail + dir * 2.0 + across * 1.5, P.BANNER[3])
	c.line(tail + dir * 1.0, tail + dir * 3.0 + across * 1.5, P.BANNER[2])
	c.line(tail, tail + dir * 2.0 - across * 1.5, P.BANNER[3])


func _plus(c: Canvas, at: Vector2i, color: Color) -> void:
	c.part()
	c.rect(Rect2i(at.x - 1, at.y - 3, 3, 7), color)
	c.rect(Rect2i(at.x - 3, at.y - 1, 7, 3), color)


func _flame(c: Canvas, at: Vector2, height: float) -> void:
	c.part(true)
	c.polygon(PackedVector2Array([at + Vector2(-3, 0), at + Vector2(-1.5, -height * 0.6), at + Vector2(0, -height),
		at + Vector2(1.5, -height * 0.5), at + Vector2(3, 0)]), P.FIRE.slice(2, 5), Vector3(-0.3, -0.5, 1))
	c.polygon(PackedVector2Array([at + Vector2(-1.5, 0), at + Vector2(0, -height * 0.6), at + Vector2(1.5, 0)]), P.FIRE.slice(4, 6), Vector3(0, 0, 1))


# ---------------------------------------------------------------- hero

func _honed_blade(c: Canvas) -> void:
	_sword(c, Vector2(3.5, 12.5), Vector2(13, 3))
	c.part(true)
	c.px(11, 2, Color("ffffff"))
	c.px(13, 5, P.STEEL[5])


func _long_reach(c: Canvas) -> void:
	c.part(true)
	for k: int in 7:
		var a: float = -PI * 0.9 + k * 0.28
		c.px(roundi(8 + cos(a) * 6.5), roundi(9 + sin(a) * 6.5), P.STEEL[4] if k % 2 == 0 else P.STEEL[3])
	_sword(c, Vector2(4, 13), Vector2(13.5, 2.5))


func _battle_rhythm(c: Canvas) -> void:
	_sword(c, Vector2(3, 13), Vector2(12, 4))
	_sword(c, Vector2(13, 13), Vector2(4, 4))
	c.part(true)
	for y: int in [2, 5, 8]:
		c.px(1, y, P.GOLD[3])


func _iron_body(c: Canvas) -> void:
	c.part()
	c.polygon(PackedVector2Array([Vector2(8, 14), Vector2(1.5, 7), Vector2(2.5, 3), Vector2(5.5, 2), Vector2(8, 4.5),
		Vector2(10.5, 2), Vector2(13.5, 3), Vector2(14.5, 7)]), P.TABARD, Vector3(-0.4, -0.4, 1))
	c.part()
	c.rect(Rect2i(6, 5, 4, 5), P.STEEL[3])
	c.rect(Rect2i(6, 5, 4, 1), P.STEEL[5])
	_plus(c, Vector2i(12, 12), P.SOUL[3])


func _second_wind(c: Canvas) -> void:
	c.part()
	c.ellipse(Vector2(8, 9), Vector2(5, 5.2), P.STEEL)
	c.rect(Rect2i(4, 9, 9, 1), P.OUTLINE)
	c.part()
	c.ellipse(Vector2(8, 3.2), Vector2(1.6, 1.6), P.TABARD, 0.0, 0.1)
	c.part(true)
	for k: int in 4:
		c.px(13 - k % 2, 13 - k * 3, P.SOUL[3 if k % 2 == 0 else 4])


func _berserker(c: Canvas) -> void:
	_sword(c, Vector2(3.5, 12.5), Vector2(13, 3), P.TABARD)
	c.part()
	c.ellipse(Vector2(12, 12), Vector2(2.6, 2.4), P.BONE)
	c.px(11, 12, P.EYE_GLOW[2])
	c.px(13, 12, P.EYE_GLOW[2])


# ---------------------------------------------------------------- towers

func _fletching(c: Canvas) -> void:
	_arrow(c, Vector2(2, 14), Vector2(14, 2))
	_plus(c, Vector2i(4, 4), P.GOLD[3])


func _eagle_eye(c: Canvas) -> void:
	c.part()
	c.ellipse(Vector2(8, 8), Vector2(6.5, 4.0), P.BONE, 1.0)
	c.part()
	c.ellipse(Vector2(8, 8), Vector2(2.8, 2.8), P.ICE, 0.0, 0.1)
	c.rect(Rect2i(7, 7, 2, 2), P.OUTLINE)
	c.px(7, 6, Color("ffffff"))


func _quick_masons(c: Canvas) -> void:
	c.part()
	c.capsule(Vector2(3, 13), Vector2(10, 6), 0.9, P.WOOD)
	c.part()
	c.block(Rect2(8, 2, 7, 3), 3.0, P.IRON.slice(2, 5), P.IRON.slice(1, 4), false)
	c.part(true)
	for k: int in 3:
		c.px(2 + k * 2, 3 + k, P.GOLD[3])


func _overcharge(c: Canvas) -> void:
	c.part()
	c.block(Rect2(4, 7, 8, 2), 6.0, P.STONE.slice(3, 7), P.STONE.slice(2, 6), false)
	c.part(true)
	c.polygon(PackedVector2Array([Vector2(10, 0), Vector2(5, 7), Vector2(8, 7), Vector2(6, 14), Vector2(12, 5), Vector2(9, 5)]),
		[P.GOLD[3]], Vector3(0, 0, 1))
	c.line(Vector2(9, 1), Vector2(6, 6), Color("ffffff"))


func _piercing(c: Canvas) -> void:
	for at: Vector2 in [Vector2(6, 9), Vector2(11, 6)]:
		c.part()
		c.ellipse(at, Vector2(2.4, 2.4), P.GHOUL_SKIN, 0.0, 0.0)
	_arrow(c, Vector2(1, 13), Vector2(15, 3))


func _hellfire(c: Canvas) -> void:
	# A flaming shell plunging down to the right, fire streaming out behind it.
	c.part(true)
	c.polygon(PackedVector2Array([Vector2(1, 2), Vector2(6, 4), Vector2(11, 8), Vector2(8, 12), Vector2(4, 8)]), [P.FIRE[2]], Vector3(0, 0, 1))
	c.polygon(PackedVector2Array([Vector2(4, 5), Vector2(10, 9), Vector2(7, 11)]), [P.FIRE[4]], Vector3(0, 0, 1))
	c.part()
	c.ellipse(Vector2(11, 11), Vector2(3.4, 3.4), P.IRON, 0.0, 0.1)
	c.px(10, 10, P.IRON[4])


func _deep_freeze(c: Canvas) -> void:
	c.part()
	for k: int in 3:
		var dir: Vector2 = Vector2.from_angle(k * PI / 3.0)
		c.line(Vector2(8, 8) - dir * 6.5, Vector2(8, 8) + dir * 6.5, P.ICE[4])
	c.part(true)
	for k: int in 6:
		var tip: Vector2 = Vector2(8, 8) + Vector2.from_angle(k * PI / 3.0) * 6.0
		c.px(roundi(tip.x), roundi(tip.y), P.ICE[5])
	c.px(8, 8, Color("ffffff"))


# ---------------------------------------------------------------- fortress

func _masonry(c: Canvas) -> void:
	c.part()
	c.block(Rect2(1, 3, 14, 2), 9.0, P.STONE.slice(3, 7), P.STONE.slice(2, 6), false)
	for y: int in [8, 11]:
		c.line(Vector2(1, y), Vector2(14, y), P.STONE[1])
	for x: int in [5, 10]:
		c.line(Vector2(x, 5), Vector2(x, 7), P.STONE[1])
		c.line(Vector2(x - 2, 9), Vector2(x - 2, 10), P.STONE[1])
	_plus(c, Vector2i(12, 3), P.SOUL[3])


func _repairs(c: Canvas) -> void:
	c.part()
	c.block(Rect2(1, 8, 9, 2), 5.0, P.STONE.slice(3, 7), P.STONE.slice(2, 6), false)
	c.part()
	c.capsule(Vector2(6, 14), Vector2(12, 5), 0.8, P.WOOD)
	c.part()
	c.block(Rect2(9, 1, 6, 3), 2.0, P.IRON.slice(2, 5), P.IRON.slice(1, 4), false)


func _thorns(c: Canvas) -> void:
	c.part()
	c.block(Rect2(1, 7, 14, 2), 6.0, P.STONE.slice(3, 7), P.STONE.slice(2, 6), false)
	c.part()
	for x: int in [2, 6, 10, 14]:
		c.polygon(PackedVector2Array([Vector2(x - 1.5, 7.5), Vector2(x, 1.5), Vector2(x + 1.5, 7.5)]), P.IRON, Vector3(-0.5, -0.4, 1))
		c.px(x, 2, P.TABARD[3])


# ---------------------------------------------------------------- economy

func _bounty(c: Canvas) -> void:
	_coin(c, Vector2(10, 10), 4.5)
	c.part()
	c.ellipse(Vector2(5, 5), Vector2(3.2, 3.0), P.BONE)
	c.px(4, 5, P.OUTLINE)
	c.px(6, 5, P.OUTLINE)


func _treasury(c: Canvas) -> void:
	c.part()
	c.block(Rect2(2, 7, 12, 2), 6.0, P.WOOD.slice(2, 5), P.WOOD.slice(1, 4), false)
	c.rect(Rect2i(2, 10, 12, 1), P.GOLD[2])
	c.rect(Rect2i(7, 9, 2, 3), P.GOLD[3])
	for at: Vector2 in [Vector2(5, 5), Vector2(9, 4.5), Vector2(12, 5.5)]:
		_coin(c, at, 2.2)


func _guild(c: Canvas) -> void:
	c.part()
	c.polygon(PackedVector2Array([Vector2(2, 3), Vector2(12, 3), Vector2(12, 13), Vector2(2, 13)]), P.BONE, Vector3(-0.3, -0.3, 1))
	for y: int in [5, 7, 9]:
		c.line(Vector2(4, y), Vector2(10, y), P.BONE[0])
	c.part()
	c.ellipse(Vector2(11.5, 11.5), Vector2(3, 3), P.TABARD, 0.0, 0.1)
	c.px(11, 11, P.GOLD[3])


func _war_tax(c: Canvas) -> void:
	_coin(c, Vector2(6, 8), 4.5)
	_coin(c, Vector2(11, 10), 3.5)
	c.part()
	c.line(Vector2(9, 2), Vector2(14, 6), P.TABARD[3])
	c.line(Vector2(13, 2), Vector2(14, 3), P.TABARD[3])
