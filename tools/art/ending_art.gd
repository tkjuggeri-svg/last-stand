extends RefCounted
## The four ending illustrations (dev-time art generator, M13 art pass): wide scenes, 224x100 art px (448x200 at
## the double resolution) in the game's palette, drawn from shapes and banded skies, light from the focal point:
##   marshal: dawn over the ash and the broken keep, the Marshal kneeling by his planted sword.
##   warden: the Deep gone still: a cave mouth of pale light, black water, a lantern left on a rock.
##   bishop: the nave, a rose window's light falling on a bell that hangs silent.
##   secret: Last Light at night and an open door onto a dawn that belongs to no fire.
##   godot --headless --path . --script res://tools/art/generate_art.gd -- --only=endings

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")

const SIZE: Vector2i = Vector2i(224, 100)
const IDS: Array[String] = ["marshal", "warden", "bishop", "secret"]
const DARK: Color = Color("14101a")

var detail: int = 1


func _init(resolution: int = 1) -> void:
	detail = resolution


func scene(id: String) -> Image:
	var c: Canvas = Canvas.new(SIZE.x, SIZE.y, detail)
	call("_" + id, c)
	c.finish(false, DARK)
	return c.image


## Horizontal bands of `colors` filling [top, bottom): a banded sky or wall.
func _bands(c: Canvas, colors: Array, top: int, bottom: int) -> void:
	var height: float = float(bottom - top) / colors.size()
	for i: int in colors.size():
		c.part()
		c.rect(Rect2i(0, top + roundi(i * height), SIZE.x, roundi(height) + 1), colors[i])


## A glow: stepped discs of `color` (alpha rising toward the middle).
func _glow(c: Canvas, at: Vector2, radius: float, color: Color, steps: int = 5) -> void:
	for i: int in steps:
		c.part(true)
		var k: float = 1.0 - float(i) / steps
		c.ellipse(at, Vector2(radius * k, radius * k * 0.8), [Color(color.r, color.g, color.b, color.a * (0.35 + 0.65 * (1.0 - k)))], 0.0, 0.0)


func _specks(c: Canvas, count: int, seed_value: int, area: Rect2, color: Color) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	for k: int in count:
		c.part(true)
		c.px(roundi(rng.randf_range(area.position.x, area.end.x)), roundi(rng.randf_range(area.position.y, area.end.y)), color)


# ---------------------------------------------------------------- The Marshal Rests

func _marshal(c: Canvas) -> void:
	_bands(c, [Color("1a1426"), Color("2a1c36"), Color("4a2a3c"), Color("7a3a40"), Color("b4543a"), Color("e0803c"), Color("f2b05a")], 0, 78)
	_glow(c, Vector2(150, 64), 34.0, Color(1.0, 0.8, 0.45, 0.22))
	c.part()
	c.ellipse(Vector2(150, 66), Vector2(11.0, 11.0), [Color("ffe8b0"), Color("fff6d8")], 0.0, 0.3)  # the low sun
	# The ruined keep against the light: curtain wall, a tower, broken battlements.
	c.part()
	c.polygon(PackedVector2Array([Vector2(96, 70), Vector2(96, 44), Vector2(102, 44), Vector2(102, 40), Vector2(108, 40), Vector2(108, 44), Vector2(116, 44), Vector2(116, 34), Vector2(122, 34), Vector2(122, 30), Vector2(126, 33), Vector2(132, 31), Vector2(132, 70)]), [DARK], Vector3(0, 0, 1))
	c.part()
	c.polygon(PackedVector2Array([Vector2(168, 70), Vector2(168, 48), Vector2(174, 48), Vector2(174, 44), Vector2(180, 46), Vector2(184, 42), Vector2(190, 46), Vector2(196, 46), Vector2(196, 70)]), [DARK], Vector3(0, 0, 1))
	c.part()
	c.polygon(PackedVector2Array([Vector2(0, 74), Vector2(30, 64), Vector2(64, 68), Vector2(96, 62), Vector2(132, 66), Vector2(168, 62), Vector2(200, 66), Vector2(224, 63), Vector2(224, 100), Vector2(0, 100)]), [Color("1c1620"), Color("241c28")], Vector3(0, 0, 1))
	_bands(c, [Color("2a2230"), Color("201a28"), Color("181320")], 76, 100)
	_specks(c, 90, 3, Rect2(0, 62, 224, 38), Color("5a4a50"))
	# The Marshal, kneeling in the foreground against the glow: helm, shoulders, bowed back, the sword in front.
	var x: float = 70.0
	c.part()
	c.polygon(PackedVector2Array([Vector2(x - 12, 94), Vector2(x - 11, 78), Vector2(x - 5, 70), Vector2(x + 4, 69), Vector2(x + 10, 74), Vector2(x + 11, 94)]), P.STEEL.slice(0, 4), Vector3(0.6, -0.2, 0.5))
	c.part()
	c.ellipse(Vector2(x + 2, 66), Vector2(5.0, 5.4), P.STEEL.slice(0, 5), 0.0, 0.0)  # the helm, head bowed
	c.part()
	c.polygon(PackedVector2Array([Vector2(x - 2, 62), Vector2(x - 6, 52), Vector2(x - 2, 59)]), P.TABARD, Vector3(0, 0, 1))  # a torn plume
	c.part()
	c.capsule(Vector2(x + 14, 96), Vector2(x + 14, 60), 0.9, P.STEEL.slice(1, 6), 0.0)  # the sword planted before him
	c.rect(Rect2i(roundi(x) + 9, 62, 11, 2), P.GOLD[2])
	c.part()
	c.capsule(Vector2(x - 24, 96), Vector2(x - 28, 52), 0.7, P.WOOD, 0.0)  # a leaning banner pole
	c.polygon(PackedVector2Array([Vector2(x - 28, 52), Vector2(x - 16, 54), Vector2(x - 20, 58), Vector2(x - 15, 62), Vector2(x - 27, 62)]), P.BANNER, Vector3(-0.3, -0.3, 1))
	_specks(c, 40, 8, Rect2(20, 10, 190, 80), Color(1.0, 0.85, 0.55, 0.45))  # embers and ash on the air


# ---------------------------------------------------------------- The Deep Is Quiet

func _warden(c: Canvas) -> void:
	_bands(c, [Color("060a10"), Color("0a121a"), Color("0e1a22"), Color("14262d"), Color("1c3a3e"), Color("2c5a58")], 0, 63)
	_glow(c, Vector2(112, 52), 48.0, Color(0.55, 0.95, 0.9, 0.2))
	c.part()
	c.ellipse(Vector2(112, 52), Vector2(15.0, 13.0), [Color("a8f0e0"), Color("e8fff8")], 0.0, 0.3)  # the way out, a mouth of pale light
	# Stalactites hanging across the top, stalagmites at the sides.
	for k: int in 26:
		var sx: float = k * 9.0 + float((k * 5) % 4)
		var length: float = 8.0 + float((k * 7) % 9) + (6.0 if k % 5 == 0 else 0.0)
		c.part()
		c.polygon(PackedVector2Array([Vector2(sx - 3.5, 0), Vector2(sx + 3.5, 0), Vector2(sx + 0.5, length)]), [Color("0c1218"), Color("141e26")], Vector3(-0.4, -0.2, 1))
	for side: float in [0.0, 1.0]:
		var base_x: float = 0.0 if side == 0.0 else 224.0
		for k: int in 4:
			var tx: float = base_x + (1.0 - 2.0 * side) * (6.0 + k * 11.0)
			c.part()
			c.polygon(PackedVector2Array([Vector2(tx - 5, 62), Vector2(tx + 5, 62), Vector2(tx + (1.0 - 2.0 * side) * -1.0, 62 - 16 - k * 5 - float((k * 3) % 4))]), [Color("0c1218"), Color("16212a")], Vector3(-0.4, -0.2, 1))
	# Black water below, the light on it in broken stripes.
	_bands(c, [Color("0a1218"), Color("0c1a20"), Color("10242a")], 62, 100)
	for k: int in 9:
		var y: float = 64.0 + k * 3.8
		var w: float = 26.0 - k * 2.2
		c.part(true)
		c.rect(Rect2i(roundi(112.0 - w / 2.0 + sin(k * 1.7) * 3.0), roundi(y), maxi(roundi(w), 2), 1), Color(0.6, 0.95, 0.9, 0.5 - k * 0.04))
	# A lantern left on a rock at the left, its warm light a small defiance.
	c.part()
	c.ellipse(Vector2(44, 84), Vector2(14.0, 6.0), P.STONE_WARM, 0.0, -0.1)
	_glow(c, Vector2(44, 76), 14.0, Color(1.0, 0.75, 0.35, 0.3), 4)
	c.part()
	c.rect(Rect2i(42, 74, 5, 7), P.BRONZE[2])
	c.part(true)
	c.rect(Rect2i(43, 75, 3, 4), P.FIRE[4])
	c.part()
	c.line(Vector2(44, 71), Vector2(44, 74), P.IRON[3])
	_specks(c, 30, 12, Rect2(60, 20, 110, 40), Color(0.7, 0.95, 0.9, 0.35))


# ---------------------------------------------------------------- The Last Toll

func _bishop(c: Canvas) -> void:
	_bands(c, [Color("14101c"), Color("1c1626"), Color("261e32"), Color("30283e")], 0, 76)
	# The nave's arches: ribs radiating from the vanishing point at the rose window.
	var vp: Vector2 = Vector2(112, 34)
	for k: int in 7:
		var x: float = 6.0 + k * 35.0
		c.part()
		c.line(Vector2(x, 100), vp.lerp(Vector2(x, 100), 0.42), Color("3a3048"))
	# Columns on both sides, receding.
	for side: float in [-1.0, 1.0]:
		for k: int in 4:
			var scale: float = 1.0 - k * 0.2
			var cx: float = 112.0 + side * (92.0 - k * 22.0)
			c.part()
			c.polygon(PackedVector2Array([Vector2(cx - 7.0 * scale, 100 - k * 8), Vector2(cx - 5.0 * scale, 6 + k * 6), Vector2(cx + 5.0 * scale, 6 + k * 6), Vector2(cx + 7.0 * scale, 100 - k * 8)]), P.SLATE, Vector3(-0.5 * side, -0.2, 0.7))
	# The rose window and its light.
	_glow(c, vp, 40.0, Color(1.0, 0.92, 0.6, 0.18))
	c.part()
	c.ellipse(vp, Vector2(15.0, 15.0), [Color("6a5a8c"), Color("9a8ac0"), Color("e8d49a")], 0.0, 0.2)
	for k: int in 12:
		var a: float = k * TAU / 12.0
		c.part()
		c.line(vp, vp + Vector2.from_angle(a) * 15.0, Color("2a2038"), true)
	c.part()
	c.ellipse(vp, Vector2(4.0, 4.0), [Color("f4e4a8"), Color("fff6d8")], 0.0, 0.3)
	# Shafts of light across the floor.
	for k: int in 4:
		var x0: float = 78.0 + k * 22.0
		c.part(true)
		c.polygon(PackedVector2Array([Vector2(vp.x - 6.0 + k * 4.0, 40), Vector2(vp.x + 2.0 + k * 4.0, 40), Vector2(x0 + 14.0, 100), Vector2(x0 - 10.0, 100)]), [Color(1.0, 0.92, 0.6, 0.12)], Vector3(0, 0, 1))
	# The floor and the pews.
	_bands(c, [Color("1e1828"), Color("261e30"), Color("2e2438")], 74, 100)
	for k: int in 5:
		var y: float = 72.0 + k * 6.0
		var half: float = 22.0 + k * 14.0
		for side: float in [-1.0, 1.0]:
			c.part()
			c.rect(Rect2i(roundi(112.0 + side * (10.0 + k * 3.0)) - (0 if side > 0.0 else roundi(half)), roundi(y), roundi(half), 3), P.WOOD[1])
	# The bell: hung from its beam, still, a little gold on its lip.
	c.part()
	c.rect(Rect2i(96, 22, 32, 3), P.WOOD[2])
	c.part()
	c.line(Vector2(112, 25), Vector2(112, 40), P.IRON[3])
	c.part()
	c.polygon(PackedVector2Array([Vector2(103, 60), Vector2(106, 44), Vector2(112, 40), Vector2(118, 44), Vector2(121, 60)]), P.BRONZE, Vector3(-0.4, -0.5, 1))
	c.part()
	c.rect(Rect2i(102, 59, 20, 2), P.GOLD[3])
	c.part()
	c.ellipse(Vector2(112, 63), Vector2(2.2, 2.2), P.IRON_WORN, 0.0, 0.1)
	_specks(c, 50, 21, Rect2(70, 24, 84, 60), Color(1.0, 0.95, 0.7, 0.4))


# ---------------------------------------------------------------- The First Dawn

func _secret(c: Canvas) -> void:
	_bands(c, [Color("0a0a18"), Color("101226"), Color("181a36"), Color("22244a"), Color("2e3260")], 0, 80)
	_specks(c, 70, 4, Rect2(0, 0, 224, 50), Color("c8d0f0"))
	# Last Light at the left: wall, towers, lit windows and the bell tower with its nine bells.
	c.part()
	c.polygon(PackedVector2Array([Vector2(0, 78), Vector2(0, 52), Vector2(14, 52), Vector2(14, 44), Vector2(20, 44), Vector2(20, 52), Vector2(40, 52), Vector2(40, 34), Vector2(44, 28), Vector2(48, 34), Vector2(48, 52), Vector2(66, 52), Vector2(66, 78)]), [DARK], Vector3(0, 0, 1))
	for k: int in 6:
		c.part(true)
		c.rect(Rect2i(8 + k * 9, 58 + (k % 2) * 6, 2, 3), Color("f2b05a"))
	c.part(true)
	c.rect(Rect2i(43, 37, 2, 4), Color("f2b05a"))
	# The ground, and the door: a tall arch whose far side is light.
	_bands(c, [Color("14142a"), Color("101024"), Color("0c0c1c")], 78, 100)
	_glow(c, Vector2(150, 62), 62.0, Color(1.0, 0.97, 0.82, 0.22), 6)
	c.part()
	c.polygon(PackedVector2Array([Vector2(130, 100), Vector2(130, 40), Vector2(134, 30), Vector2(142, 24), Vector2(150, 22), Vector2(158, 24), Vector2(166, 30), Vector2(170, 40), Vector2(170, 100)]), [DARK], Vector3(0, 0, 1))
	c.part()
	c.polygon(PackedVector2Array([Vector2(136, 100), Vector2(136, 42), Vector2(139, 34), Vector2(145, 29), Vector2(150, 27), Vector2(155, 29), Vector2(161, 34), Vector2(164, 42), Vector2(164, 100)]), [Color("e8dcb0"), Color("f6efd0"), Color("fffbe8")], Vector3(0, -0.3, 1))
	for k: int in 7:  # rays through the doorway
		var a: float = -PI / 2.0 + (k - 3) * 0.28
		c.part(true)
		c.line(Vector2(150, 70), Vector2(150, 70) + Vector2.from_angle(a) * 50.0, Color(1.0, 0.97, 0.8, 0.28))
	c.part(true)
	c.polygon(PackedVector2Array([Vector2(138, 100), Vector2(162, 100), Vector2(190, 100), Vector2(110, 100)]), [Color(1.0, 0.97, 0.82, 0.2)], Vector3(0, 0, 1))
	# The hero, small and dark in the doorway, looking in.
	c.part()
	c.ellipse(Vector2(150, 78), Vector2(2.6, 2.8), [DARK], 0.0, 0.0)
	c.polygon(PackedVector2Array([Vector2(146, 100), Vector2(147, 81), Vector2(153, 81), Vector2(154, 100)]), [DARK], Vector3(0, 0, 1))
	c.part()
	c.polygon(PackedVector2Array([Vector2(147, 76), Vector2(146, 70), Vector2(150, 74)]), [Color("3a1018")], Vector3(0, 0, 1))  # a red plume against the light
