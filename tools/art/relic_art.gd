extends RefCounted
## Relic icons (dev-time art generator), 16x16 art px each like the card icons but each standing on a
## dark violet relic plate with a gold rim, so a relic never looks like a card; saved pre-scaled to 2x
## (32x32) for the choice cards, the merchant and the HUD's relic row. Also the Ossuary Bell's bone
## (a world pickup, 16x12 art, drawn at sprite scale 2).

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")

const SIZE: int = 16
const IDS: Array[String] = ["hourglass", "bloodpact", "ossuary_bell", "siege_ledger", "lantern_of_the_lost", "twin_banners",
	"phoenix_feather", "executioners_mark", "glass_banner", "soul_lantern", "drowned_bell", "iron_tithe",
	"merchants_seal", "second_oath", "ember_heart"]
const PLATE: Array[Color] = [Color("1a1226"), Color("2a1d3c"), Color("3b2a54")]
const BONE_SIZE: Vector2i = Vector2i(16, 12)


func icon(id: String) -> Image:
	var c: Canvas = Canvas.new(SIZE, SIZE)
	_plate(c)
	call("_" + id, c)
	c.finish()
	_rim(c.image)
	var img: Image = c.image
	img.resize(SIZE * 2, SIZE * 2, Image.INTERPOLATE_NEAREST)
	return img


## A bone lying on the ground, a gold glint on it (it pays gold).
func bone() -> Image:
	var c: Canvas = Canvas.new(BONE_SIZE.x, BONE_SIZE.y)
	c.part()
	c.capsule(Vector2(4, 7), Vector2(12, 5), 1.1, P.BONE)
	for end: Vector2 in [Vector2(3, 7), Vector2(13, 5)]:
		c.part()
		c.ellipse(end + Vector2(0, -0.8), Vector2(1.4, 1.1), P.BONE, 0.0, 0.1)
		c.ellipse(end + Vector2(0, 0.8), Vector2(1.4, 1.1), P.BONE, 0.0, 0.0)
	c.finish()
	c.px(9, 5, P.GOLD[4])
	c.px(10, 4, P.GOLD[3])
	c.ground_shadow(Vector2(8, 9.5), Vector2(6, 1.4))
	return c.image


# ---------------------------------------------------------------- the plate

## The relic plate: a dark violet disc behind the object.
func _plate(c: Canvas) -> void:
	c.part(true)
	c.ellipse(Vector2(8, 8), Vector2(7.4, 7.4), PLATE, 0.0, 0.0)


## A gold rim around the plate (over the outline, on its edge pixels).
func _rim(img: Image) -> void:
	for y: int in SIZE:
		for x: int in SIZE:
			var d: float = Vector2(x + 0.5, y + 0.5).distance_to(Vector2(8, 8))
			if d > 7.0 and d <= 8.0 and img.get_pixel(x, y).a > 0.0:
				img.set_pixel(x, y, P.GOLD[3] if x + y < 16 else P.GOLD[1])


# ---------------------------------------------------------------- icons

func _hourglass(c: Canvas) -> void:
	c.part()
	c.rect(Rect2i(4, 2, 8, 1), P.WOOD[3])
	c.rect(Rect2i(4, 13, 8, 1), P.WOOD[2])
	c.part()
	c.polygon(PackedVector2Array([Vector2(5, 3), Vector2(11, 3), Vector2(8.5, 8), Vector2(11, 13), Vector2(5, 13), Vector2(7.5, 8)]),
		P.ICE.slice(2, 6), Vector3(-0.4, -0.4, 1))
	c.rect(Rect2i(6, 4, 4, 2), P.GOLD[3])  # the sand left on top
	c.rect(Rect2i(7, 8, 2, 3), P.GOLD[2])  # running through
	c.rect(Rect2i(6, 11, 4, 2), P.GOLD[3])


func _bloodpact(c: Canvas) -> void:
	c.part()
	c.ellipse(Vector2(6, 7), Vector2(2.6, 2.6), P.TABARD, 0.0, 0.1)
	c.ellipse(Vector2(10, 7), Vector2(2.6, 2.6), P.TABARD, 0.0, 0.1)
	c.polygon(PackedVector2Array([Vector2(3.5, 8), Vector2(12.5, 8), Vector2(8, 13)]), P.TABARD, Vector3(-0.2, -0.2, 1))
	c.part()
	c.line(Vector2(12, 2), Vector2(6, 9), P.STEEL[4])  # the dagger through it
	c.line(Vector2(13, 1), Vector2(12, 2), P.GOLD[3])
	c.px(8, 13, P.TABARD[4])


func _ossuary_bell(c: Canvas) -> void:
	c.part()
	c.polygon(PackedVector2Array([Vector2(6, 3), Vector2(10, 3), Vector2(11, 8), Vector2(13, 12), Vector2(3, 12), Vector2(5, 8)]),
		P.BONE, Vector3(-0.4, -0.3, 1))
	c.rect(Rect2i(7, 1, 2, 2), P.BONE[1])
	c.px(6, 7, P.OUTLINE)
	c.px(9, 7, P.OUTLINE)
	c.rect(Rect2i(7, 9, 2, 1), P.OUTLINE)
	c.part()
	c.ellipse(Vector2(8, 13.5), Vector2(1.2, 1.0), P.GOLD, 0.0, 0.1)


func _siege_ledger(c: Canvas) -> void:
	c.part()
	c.polygon(PackedVector2Array([Vector2(2, 5), Vector2(8, 6), Vector2(14, 5), Vector2(14, 12), Vector2(8, 13), Vector2(2, 12)]),
		P.BONE.slice(1, 4), Vector3(0, -0.3, 1))
	c.line(Vector2(8, 6), Vector2(8, 13), P.BONE[0])
	for y: int in [8, 10]:
		c.line(Vector2(3, y), Vector2(6, y), P.STONE[2])
		c.line(Vector2(10, y), Vector2(13, y), P.STONE[2])
	c.part()
	c.ellipse(Vector2(12, 3.5), Vector2(2.4, 2.4), P.GOLD, 0.0, 0.1)


func _lantern_of_the_lost(c: Canvas) -> void:
	c.part()
	c.line(Vector2(8, 1), Vector2(8, 3), P.IRON[3])
	c.part()
	c.block(Rect2(5, 3, 6, 1), 9.0, P.IRON.slice(1, 5), P.IRON.slice(0, 4), false)
	c.part(true)
	c.rect(Rect2i(6, 5, 4, 6), P.WITCHFIRE[1])
	c.ellipse(Vector2(8, 8), Vector2(1.6, 1.4), [P.WITCHFIRE[2], P.WITCHFIRE[3], P.WITCHFIRE[4]], 0.0)
	c.px(8, 8, P.OUTLINE)  # the pupil: it sees the casters


func _twin_banners(c: Canvas) -> void:
	for x: float in [4.5, 10.5]:
		c.part()
		c.line(Vector2(x, 2), Vector2(x, 14), P.WOOD[3])
		c.part()
		c.polygon(PackedVector2Array([Vector2(x + 0.5, 3), Vector2(x + 4, 4), Vector2(x + 3, 6), Vector2(x + 4, 8), Vector2(x + 0.5, 8)]),
			P.BANNER, Vector3(-0.3, -0.3, 1))
	c.px(5, 1, P.GOLD[3])
	c.px(11, 1, P.GOLD[3])


func _phoenix_feather(c: Canvas) -> void:
	c.part()
	c.polygon(PackedVector2Array([Vector2(4, 13), Vector2(5, 9), Vector2(8, 5), Vector2(12, 2), Vector2(11, 6), Vector2(8, 10), Vector2(5, 13)]),
		P.FIRE.slice(0, 4), Vector3(-0.5, -0.5, 1))
	c.line(Vector2(5, 12), Vector2(11, 3), P.FIRE[4])
	c.px(12, 2, P.FIRE[5])
	c.px(9, 9, P.FIRE[1])


func _executioners_mark(c: Canvas) -> void:
	c.part()
	c.line(Vector2(4, 14), Vector2(11, 3), P.WOOD[3])
	c.part()
	c.polygon(PackedVector2Array([Vector2(9, 2), Vector2(14, 4), Vector2(13, 8), Vector2(10, 6)]), P.STEEL, Vector3(-0.5, -0.5, 1))
	c.line(Vector2(14, 4), Vector2(13, 8), P.STEEL[5])
	c.part()
	c.rect(Rect2i(3, 4, 3, 1), P.BANNER[3])  # the mark: a red tally
	c.rect(Rect2i(4, 3, 1, 3), P.BANNER[3])


func _glass_banner(c: Canvas) -> void:
	c.part()
	c.line(Vector2(5, 1), Vector2(5, 14), P.WOOD[3])
	c.part()
	c.polygon(PackedVector2Array([Vector2(6, 2), Vector2(13, 3), Vector2(11, 6), Vector2(13, 10), Vector2(6, 10)]), P.ICE.slice(1, 5), Vector3(-0.4, -0.4, 1))
	c.line(Vector2(8, 3), Vector2(10, 9), P.ICE[0])  # a crack
	c.line(Vector2(10, 9), Vector2(12, 8), P.ICE[0])
	c.px(7, 4, P.ICE[5])


func _soul_lantern(c: Canvas) -> void:
	c.part()
	c.block(Rect2(4, 9, 8, 1), 4.0, P.STONE.slice(2, 6), P.STONE.slice(1, 5), false)  # the keep's wall
	c.rect(Rect2i(4, 8, 2, 1), P.STONE[4])
	c.rect(Rect2i(10, 8, 2, 1), P.STONE[4])
	c.part(true)
	c.ellipse(Vector2(8, 5), Vector2(2.4, 2.8), P.SOUL.slice(1, 5), 0.0)
	c.px(8, 2, P.SOUL[4])
	c.px(7, 4, P.SOUL[4])


func _drowned_bell(c: Canvas) -> void:
	c.part()
	c.polygon(PackedVector2Array([Vector2(6, 2), Vector2(10, 2), Vector2(11, 7), Vector2(13, 11), Vector2(3, 11), Vector2(5, 7)]),
		P.BRONZE, Vector3(-0.4, -0.3, 1))
	c.line(Vector2(9, 3), Vector2(10, 9), P.OUTLINE)  # the crack
	c.px(6, 5, Color("4f9a80"))
	c.px(7, 8, Color("4f9a80"))
	c.part()
	c.ellipse(Vector2(8, 12.5), Vector2(1.2, 1.0), P.IRON, 0.0, 0.1)
	c.px(4, 14, P.ICE[3])
	c.px(12, 14, P.ICE[3])


func _iron_tithe(c: Canvas) -> void:
	c.part()
	c.polygon(PackedVector2Array([Vector2(3, 3), Vector2(13, 3), Vector2(13, 8), Vector2(8, 14), Vector2(3, 8)]), P.IRON, Vector3(-0.4, -0.4, 1))
	c.line(Vector2(8, 3), Vector2(8, 13), P.IRON[1])
	c.line(Vector2(3, 7), Vector2(13, 7), P.IRON[1])
	c.part()
	c.rect(Rect2i(6, 8, 4, 3), P.GOLD[2])  # the padlock: no repairs
	c.line(Vector2(6.5, 8), Vector2(7, 6), P.GOLD[3])
	c.line(Vector2(9.5, 8), Vector2(9, 6), P.GOLD[3])
	c.px(8, 9, P.OUTLINE)


func _merchants_seal(c: Canvas) -> void:
	c.part()
	c.polygon(PackedVector2Array([Vector2(3, 4), Vector2(13, 4), Vector2(13, 12), Vector2(3, 12)]), P.BONE.slice(1, 4), Vector3(0, -0.3, 1))
	c.part()
	c.ellipse(Vector2(9, 9), Vector2(3.2, 3.0), P.BANNER, 0.0, 0.1)
	c.px(9, 9, P.GOLD[3])
	c.px(8, 8, P.BANNER[4])
	c.line(Vector2(4, 6), Vector2(8, 6), P.STONE[2])


func _second_oath(c: Canvas) -> void:
	c.part(true)
	for k: int in 12:
		var a: float = TAU * k / 12.0
		c.px(roundi(8 + cos(a) * 6.0), roundi(8 + sin(a) * 6.0), P.GOLD[3] if k % 2 == 0 else P.GOLD[2])
	c.part()
	c.ellipse(Vector2(8, 8), Vector2(3.6, 3.4), P.STEEL, 0.0, 0.1)
	c.rect(Rect2i(6, 8, 4, 1), P.OUTLINE)
	c.rect(Rect2i(7, 4, 2, 2), P.BANNER[3])  # the plume


func _ember_heart(c: Canvas) -> void:
	c.part()
	c.ellipse(Vector2(6, 7), Vector2(2.6, 2.6), P.FIRE.slice(0, 5), 0.0, 0.1)
	c.ellipse(Vector2(10, 7), Vector2(2.6, 2.6), P.FIRE.slice(0, 5), 0.0, 0.1)
	c.polygon(PackedVector2Array([Vector2(3.5, 8), Vector2(12.5, 8), Vector2(8, 13)]), P.FIRE.slice(0, 5), Vector3(-0.2, -0.2, 1))
	c.part(true)
	c.px(8, 9, P.FIRE[5])
	c.px(7, 6, P.FIRE[4])
	c.px(10, 3, P.FIRE[3])
	c.px(6, 2, P.FIRE[2])
