extends RefCounted
## Portraits (dev-time art generator, M11): busts of the three heroes and the War Room's three characters, 48x48
## art px (96x96 at the double resolution), drawn from the front with the usual 1 px outline and light from
## the top-left, on a transparent ground (the screens frame them). One method per person.
##   godot --headless --path . --script res://tools/art/generate_art.gd -- --only=portraits

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")

const SIZE: Vector2i = Vector2i(48, 48)
const PEOPLE: Array[String] = ["knight", "huntress", "necromancer", "quartermaster", "ilse", "orm"]

var detail: int = 1


func _init(resolution: int = 1) -> void:
	detail = resolution


## The six portraits side by side (one row), in PEOPLE's order.
func sheet_rows() -> Array[Array]:
	var row: Array[Image] = []
	for who: String in PEOPLE:
		row.append(portrait(who))
	return [row]


func portrait(who: String) -> Image:
	var c: Canvas = Canvas.new(SIZE.x, SIZE.y, detail)
	call("_" + who, c)
	c.finish()
	return c.image


## Shoulders and chest as a polygon in `ramp`, with an optional 2-colour trim line along the collar.
func _shoulders(c: Canvas, ramp: Array, trim: Array = []) -> void:
	c.part()
	c.polygon(PackedVector2Array([Vector2(1, 48), Vector2(4, 37), Vector2(12, 32.5), Vector2(36, 32.5), Vector2(44, 37), Vector2(47, 48)]), ramp, Vector3(-0.3, -0.4, 1))
	if not trim.is_empty():
		c.line(Vector2(13, 33.5), Vector2(35, 33.5), trim[2])


func _neck(c: Canvas, ramp: Array) -> void:
	c.part()
	c.ellipse(Vector2(24, 31), Vector2(4.6, 5.2), ramp, 0.0, -0.15)


## An eye in image pixels (5 wide, 3 tall) at art position `at`: lash line, white, iris, a lit pixel, lower lid.
func _eye(c: Canvas, at: Vector2, iris: Color, white: Color = Color("e8e0d0"), glow: bool = false) -> void:
	var keys: Dictionary = {"o": P.OUTLINE, "w": white, "i": iris, "h": Color("ffffff"), "s": Color(0.0, 0.0, 0.0, 0.25)}
	c.fine_grid([".ooo.", "wihwo" if not glow else "iiiio", ".sss."], at, keys)


func _brow(c: Canvas, from: Vector2, to: Vector2, color: Color) -> void:
	c.line(from, to, color, true)


func _knight(c: Canvas) -> void:
	# Cloak and tabard behind the plate, then the gorget and pauldrons.
	c.part()
	c.polygon(PackedVector2Array([Vector2(0, 48), Vector2(2, 36), Vector2(12, 31), Vector2(36, 31), Vector2(46, 36), Vector2(48, 48)]), P.CAPE, Vector3(-0.2, -0.3, 1))
	_shoulders(c, P.STEEL.slice(1, 5), P.GOLD)
	for side: float in [-1.0, 1.0]:
		var at: Vector2 = Vector2(24 + side * 17.5, 37.0)
		c.part()
		c.ellipse(at, Vector2(8.0, 5.5), P.STEEL, 0.0, 0.0)
		c.part()
		c.ellipse(at + Vector2(side * 1.5, -1.5), Vector2(5.0, 3.0), P.STEEL, 0.0, 0.12)
		c.part()
		c.line(at + Vector2(-5.0 * side, 2.5), at + Vector2(5.0 * side, 2.0), P.GOLD[2])
		for k: int in 3:
			c.px(roundi(at.x - 3.0 + k * 3.0), roundi(at.y + 0.5), P.GOLD[3])
	c.part()
	c.rect(Rect2i(21, 33, 6, 15), P.TABARD[2])  # the tabard's front, a red band down the chest
	c.rect(Rect2i(21, 33, 2, 15), P.TABARD[3])
	c.rect(Rect2i(24, 36, 1, 8), P.GOLD[2])
	c.rect(Rect2i(22, 39, 3, 1), P.GOLD[2])
	_neck(c, P.SKIN)
	c.part()
	c.ellipse(Vector2(24, 31.5), Vector2(7.5, 3.0), P.STEEL, 0.0, 0.0)  # the gorget
	# The head: skin under an open visor, a worn great helm above and around.
	c.part()
	c.ellipse(Vector2(24, 22.5), Vector2(8.6, 9.8), P.SKIN, 0.0, 0.05)
	var dome: PackedVector2Array = PackedVector2Array()
	for step: int in 13:
		var angle: float = PI + PI * step / 12.0
		dome.append(Vector2(24.0 + cos(angle) * 12.0, 19.0 + sin(angle) * 12.5))
	c.part()
	c.polygon(dome, P.STEEL, Vector3(-0.35, -0.55, 0.8))  # the helm's dome, shaded like a sphere's top
	c.ellipse(Vector2(20.0, 11.0), Vector2(6.0, 4.0), P.STEEL, 0.0, 0.18)
	c.part()
	c.polygon(PackedVector2Array([Vector2(12.2, 18), Vector2(35.8, 18), Vector2(34, 22), Vector2(29.5, 21.5), Vector2(24, 20.5), Vector2(18.5, 21.5), Vector2(14, 22)]), P.STEEL, Vector3(-0.1, -0.2, 1))  # the raised visor's edge
	c.part()
	c.rect(Rect2i(12, 18, 24, 1), P.GOLD[3])
	c.rect(Rect2i(12, 19, 24, 1), P.GOLD[1])
	for x: int in [14, 18, 30, 34]:
		c.px(x, 20, P.GOLD[3])
	c.part()
	c.polygon(PackedVector2Array([Vector2(12.5, 19), Vector2(15.5, 19), Vector2(15, 30), Vector2(13.5, 31)]), P.STEEL, Vector3(-0.2, -0.3, 1))  # cheek plates
	c.polygon(PackedVector2Array([Vector2(32.5, 19), Vector2(35.5, 19), Vector2(34.5, 31), Vector2(33, 30)]), P.STEEL, Vector3(0.3, -0.1, 1))
	c.part()
	c.rect(Rect2i(23, 11, 2, 7), P.STEEL[1])  # the crest ridge
	c.rect(Rect2i(23, 11, 1, 7), P.STEEL[4])
	# The face: shadowed eyes, a broken nose, stubble, a scar, a set mouth.
	c.part(true)
	c.ellipse(Vector2(24, 21.2), Vector2(8.0, 1.5), [Color(0.0, 0.0, 0.0, 0.2)], 0.0, 0.0)  # the visor's shadow on the face
	_eye(c, Vector2(18.5, 23.0), Color("5b7a96"))
	_eye(c, Vector2(26.8, 23.0), Color("5b7a96"))
	_brow(c, Vector2(17.5, 22.0), Vector2(21.5, 22.4), P.LEATHER[0])
	_brow(c, Vector2(26.5, 22.4), Vector2(30.5, 22.0), P.LEATHER[0])
	c.part(true)
	c.line(Vector2(24, 23.5), Vector2(23.4, 26.6), P.SKIN[1], true)  # the nose
	c.px(23, 27, P.SKIN[0])
	c.px(25, 27, P.SKIN[1])
	c.line(Vector2(21, 29.6), Vector2(27, 29.6), P.SKIN[0], true)  # the mouth
	c.line(Vector2(28.5, 20.5), Vector2(31, 26.0), P.SKIN[3], true)  # the scar
	for k: int in 9:
		c.fine_px(Vector2(19.0 + k * 1.1, 27.6 + (k % 3) * 0.9), P.STEEL[3])  # a few grey stubble hairs
	# The red plume over the crest.
	c.part()
	c.polygon(PackedVector2Array([Vector2(21, 11.5), Vector2(19.5, 5), Vector2(22.5, 2.5), Vector2(26, 0.5), Vector2(30, 3), Vector2(29, 9), Vector2(27, 11.5)]), P.TABARD, Vector3(-0.2, -0.5, 1))
	c.part()
	c.line(Vector2(23, 10), Vector2(24.5, 3.5), P.TABARD[4])
	c.line(Vector2(26, 10), Vector2(28.0, 4.0), P.TABARD[1])
	# Dents and scratches in the steel.
	c.part(true)
	c.line(Vector2(17, 12), Vector2(20, 14.5), P.STEEL[1], true)
	c.line(Vector2(30, 13), Vector2(32.5, 15.5), P.STEEL[1], true)
	c.px(16, 14, P.STEEL[5])
	c.px(31, 12, P.STEEL[5])


func _huntress(c: Canvas) -> void:
	c.part()
	c.ellipse(Vector2(24, 19), Vector2(15.5, 16.5), P.HOOD, 0.0, -0.1)  # the hood's back and sides
	_shoulders(c, P.LEATHER, P.GOLD)
	c.part()
	c.polygon(PackedVector2Array([Vector2(3, 48), Vector2(5, 38), Vector2(14, 33), Vector2(34, 33), Vector2(43, 38), Vector2(45, 48)]), P.HOOD, Vector3(-0.2, -0.3, 1))  # the cloak over the jerkin
	c.part()
	c.polygon(PackedVector2Array([Vector2(16, 34), Vector2(24, 40), Vector2(32, 34), Vector2(33, 36), Vector2(24, 43), Vector2(15, 36)]), P.LEATHER, Vector3(-0.2, -0.4, 1))  # the lacing of the jerkin
	c.part()
	c.line(Vector2(9, 36), Vector2(40, 47), P.LEATHER[0])  # the quiver strap
	c.line(Vector2(9, 37), Vector2(40, 48), P.LEATHER[2])
	c.part()
	c.ellipse(Vector2(25, 41), Vector2(2.2, 2.2), P.GOLD, 0.0, 0.2)  # its buckle
	_neck(c, P.SKIN)
	c.part()
	c.ellipse(Vector2(24, 31), Vector2(7.5, 3.2), P.BANNER, 0.0, 0.0)  # a scarf
	c.ellipse(Vector2(21, 33.5), Vector2(3.0, 2.2), P.BANNER, 0.0, -0.1)
	c.part()
	c.ellipse(Vector2(24, 23), Vector2(7.8, 9.2), P.SKIN, 0.0, 0.08)  # the face
	c.part()
	c.polygon(PackedVector2Array([Vector2(15.5, 17), Vector2(18, 13), Vector2(24, 15.5), Vector2(30, 13), Vector2(32.5, 17), Vector2(31, 20), Vector2(27, 18.5), Vector2(24, 19.5), Vector2(21, 18.5), Vector2(17, 20)]), P.LEATHER, Vector3(-0.2, -0.4, 1))  # dark hair across the brow
	c.part()
	c.polygon(PackedVector2Array([Vector2(9, 26), Vector2(14, 14), Vector2(18, 8), Vector2(24, 1), Vector2(30, 8), Vector2(34, 14), Vector2(39, 26), Vector2(33, 22), Vector2(34, 15), Vector2(30, 11), Vector2(24, 9), Vector2(18, 11), Vector2(14, 15), Vector2(15, 22)]), P.HOOD, Vector3(-0.3, -0.5, 1))  # the hood's rim, drawn over
	c.part(true)
	c.ellipse(Vector2(24, 15), Vector2(8.0, 1.6), [Color(0.0, 0.0, 0.0, 0.22)], 0.0, 0.0)
	_eye(c, Vector2(19.0, 22.5), Color("6aa04a"))
	_eye(c, Vector2(26.4, 22.5), Color("6aa04a"))
	_brow(c, Vector2(18.0, 21.2), Vector2(22.0, 21.6), P.LEATHER[0])
	_brow(c, Vector2(26.0, 21.6), Vector2(30.0, 20.8), P.LEATHER[0])
	c.line(Vector2(24, 23.8), Vector2(23.6, 26.4), P.SKIN[1], true)
	c.line(Vector2(21.5, 29.2), Vector2(26.5, 29.0), P.SKIN[0], true)
	c.px(27, 28, P.SKIN[1])
	for k: int in 3:  # war paint: three strokes under the right eye
		c.line(Vector2(27.5 + k * 1.2, 25.0), Vector2(26.5 + k * 1.2, 27.6), P.HOOD[1], true)
	c.part()
	c.line(Vector2(34, 14), Vector2(41, 7), P.TABARD[3])  # a red feather at the hood
	c.line(Vector2(34, 15), Vector2(40, 10), P.TABARD[2])
	c.part()
	c.capsule(Vector2(15.5, 27), Vector2(13.5, 41), 0.95, P.LEATHER.slice(0, 3), 0.0)  # a braid over the shoulder
	for k: int in 4:
		c.px(14 + (k % 2), 30 + k * 3, P.LEATHER[0])
	c.rect(Rect2i(12, 41, 3, 1), P.GOLD[2])
	c.part()
	c.line(Vector2(34, 38), Vector2(41, 29), P.WOOD[3])  # a crossbow limb at the shoulder
	c.line(Vector2(34, 38), Vector2(43, 38), P.STEEL[3])
	c.line(Vector2(41, 29), Vector2(43, 38), P.STEEL[5], true)


func _necromancer(c: Canvas) -> void:
	c.part()
	c.ellipse(Vector2(24, 19), Vector2(15.5, 16.5), P.LICH_ROBE, 0.0, -0.1)
	_shoulders(c, P.LICH_ROBE.slice(1, 6), P.GOLD)
	c.part()
	c.ellipse(Vector2(8.5, 38), Vector2(6.2, 4.0), P.BONE.slice(0, 4), 0.0, 0.0)  # a bone pauldron
	c.part()
	c.ellipse(Vector2(8.5, 37), Vector2(1.9, 2.0), P.BONE, 0.0, 0.2)
	c.rect(Rect2i(7, 37, 1, 1), P.OUTLINE)
	c.rect(Rect2i(9, 37, 1, 1), P.OUTLINE)
	for k: int in 6:  # a necklace of knucklebones
		c.part()
		c.ellipse(Vector2(17.5 + k * 2.6, 34.5 + absf(k - 2.5) * -0.4 + 1.2), Vector2(1.1, 1.0), P.BONE, 0.0, 0.1)
	_neck(c, P.BONE)
	c.part()
	c.ellipse(Vector2(24, 23), Vector2(7.6, 9.0), P.BONE, 0.0, 0.1)  # the face, bone pale
	c.part()
	c.polygon(PackedVector2Array([Vector2(16.5, 18), Vector2(19, 13.5), Vector2(24, 16), Vector2(29, 13.5), Vector2(31.5, 18), Vector2(29.5, 21), Vector2(26, 19), Vector2(24, 20.5), Vector2(22, 19), Vector2(18.5, 21)]), P.BONE, Vector3(-0.3, -0.5, 1))  # white fringe
	c.part()
	c.polygon(PackedVector2Array([Vector2(8.5, 27), Vector2(13, 14), Vector2(18, 8), Vector2(24, 0.5), Vector2(30, 8), Vector2(35, 14), Vector2(39.5, 27), Vector2(33, 22), Vector2(34, 15), Vector2(30, 11), Vector2(24, 9), Vector2(18, 11), Vector2(14, 15), Vector2(15, 22)]), P.LICH_ROBE, Vector3(-0.3, -0.5, 1))
	c.part()
	c.line(Vector2(14.5, 20), Vector2(14, 26), P.SOUL[3])  # runes along the hood's edge
	c.line(Vector2(33.5, 20), Vector2(34, 26), P.SOUL[3])
	c.px(14, 17, P.SOUL[4])
	c.px(34, 17, P.SOUL[4])
	c.part(true)
	c.ellipse(Vector2(24, 15), Vector2(8.0, 1.6), [Color(0.0, 0.0, 0.0, 0.25)], 0.0, 0.0)
	c.fine_grid([".ooo.", "ssss.", ".sss."], Vector2(18.2, 24.0), {"o": P.LICH_ROBE[1], "s": Color(0.13, 0.1, 0.25, 0.55)})  # dark rings under the eyes
	c.fine_grid([".ooo.", "ssss.", ".sss."], Vector2(26.2, 24.0), {"o": P.LICH_ROBE[1], "s": Color(0.13, 0.1, 0.25, 0.55)})
	_eye(c, Vector2(19.0, 22.5), P.SOUL[3], P.SOUL[4], true)
	_eye(c, Vector2(26.4, 22.5), P.SOUL[3], P.SOUL[4], true)
	_brow(c, Vector2(18.0, 21.0), Vector2(22.5, 21.6), P.LICH_ROBE[1])
	_brow(c, Vector2(26.0, 21.6), Vector2(30.5, 21.0), P.LICH_ROBE[1])
	c.line(Vector2(24, 24.0), Vector2(23.7, 26.4), P.BONE[1], true)
	c.line(Vector2(21.5, 29.0), Vector2(26.5, 29.2), P.LICH_ROBE[2], true)  # dark lips
	c.tint_circle(Vector2(14, 24), 10.0, P.SOUL[3], 0.18)  # the soul-light on the left of her face
	c.tint_circle(Vector2(20.0, 23.2), 2.6, P.SOUL[4], 0.45)  # her eyes glow
	c.tint_circle(Vector2(27.8, 23.2), 2.6, P.SOUL[4], 0.45)
	c.part()
	c.capsule(Vector2(41, 46), Vector2(41, 28), 0.9, P.WOOD, 0.0)  # the staff, its skull and its soul
	c.ellipse(Vector2(41, 26), Vector2(3.0, 3.0), P.BONE, 0.0, 0.2)
	c.px(40, 26, P.OUTLINE)
	c.px(42, 26, P.OUTLINE)
	c.part(true)
	c.ellipse(Vector2(41, 20), Vector2(2.0, 3.0), P.SOUL, 0.0, 0.3)
	c.part(true)
	for k: int in 4:
		c.px(37 + (k % 2) * 6, 14 + k * 4, P.SOUL[3 + k % 2])  # motes


func _quartermaster(c: Canvas) -> void:
	_shoulders(c, P.LEATHER.slice(0, 4), P.GOLD)
	c.part()
	c.polygon(PackedVector2Array([Vector2(8, 36), Vector2(16, 31), Vector2(21, 34), Vector2(24, 44), Vector2(18, 48), Vector2(6, 48)]), P.LEATHER, Vector3(-0.3, -0.4, 1))  # the coat's left lapel
	c.polygon(PackedVector2Array([Vector2(40, 36), Vector2(32, 31), Vector2(27, 34), Vector2(24, 44), Vector2(30, 48), Vector2(42, 48)]), P.LEATHER, Vector3(0.2, -0.3, 1))
	c.part()
	c.ellipse(Vector2(24, 36), Vector2(4.0, 2.4), P.BONE, 0.0, 0.1)  # a shirt collar
	for k: int in 3:  # a ring of keys at the belt
		c.part()
		c.ellipse(Vector2(10 + k * 2.5, 46), Vector2(1.4, 1.4), P.GOLD, 0.0, 0.1)
		c.rect(Rect2i(9 + k * 3, 47, 1, 1), P.GOLD[1])
	_neck(c, P.SKIN)
	c.part()
	c.ellipse(Vector2(24, 21.5), Vector2(9.0, 10.5), P.SKIN, 0.0, 0.05)
	c.part()
	c.ellipse(Vector2(15, 23), Vector2(1.5, 2.4), P.SKIN, 0.0, 0.0)  # ears
	c.ellipse(Vector2(33, 23), Vector2(1.5, 2.4), P.SKIN, 0.0, -0.1)
	c.part()
	c.ellipse(Vector2(24, 10.5), Vector2(11.5, 4.5), P.LEATHER, 0.0, 0.0)  # a flat cap
	c.rect(Rect2i(13, 11, 22, 2), P.LEATHER[1])
	c.rect(Rect2i(12, 12, 24, 1), P.LEATHER[0])
	c.part()
	c.polygon(PackedVector2Array([Vector2(14, 14), Vector2(16, 18), Vector2(15, 22), Vector2(13.5, 17)]), P.STEEL, Vector3(-0.3, -0.5, 1))  # grey hair at the temples
	c.polygon(PackedVector2Array([Vector2(34, 14), Vector2(32, 18), Vector2(33, 22), Vector2(34.5, 17)]), P.STEEL, Vector3(0.3, -0.5, 1))
	c.part(true)
	c.ellipse(Vector2(24, 14.5), Vector2(8.0, 1.2), [Color(0.0, 0.0, 0.0, 0.18)], 0.0, 0.0)
	_eye(c, Vector2(18.5, 20.5), Color("6b4a2a"))
	_eye(c, Vector2(26.8, 20.5), Color("6b4a2a"))
	for centre: float in [20.4, 28.4]:  # round spectacles
		for a: int in 18:
			var t: float = a * TAU / 18.0
			c.fine_px(Vector2(centre + cos(t) * 2.5, 21.4 + sin(t) * 2.0), P.STEEL[4])
	c.line(Vector2(22.9, 21.0), Vector2(25.9, 21.0), P.STEEL[4], true)
	_brow(c, Vector2(17.0, 18.4), Vector2(22.0, 18.8), P.STEEL[3])
	_brow(c, Vector2(26.0, 18.8), Vector2(31.0, 18.4), P.STEEL[3])
	c.line(Vector2(24, 22.5), Vector2(23.4, 25.5), P.SKIN[1], true)  # a nose, a little red at the tip
	c.px(23, 25, P.TABARD[3])
	c.part(true)
	c.line(Vector2(16.5, 24.5), Vector2(18.5, 28), P.SKIN[1], true)  # lines of age
	c.line(Vector2(31.5, 24.5), Vector2(29.5, 28), P.SKIN[1], true)
	c.part()
	c.ellipse(Vector2(24, 29.5), Vector2(7.5, 4.8), P.STEEL.slice(1, 6), 0.0, 0.1)  # a trimmed grey beard
	c.ellipse(Vector2(24, 26.2), Vector2(4.6, 1.3), P.STEEL.slice(1, 6), 0.0, 0.15)  # a moustache
	c.rect(Rect2i(22, 27, 4, 1), P.STEEL[1])
	c.part()
	c.rect(Rect2i(34, 38, 10, 10), P.WOOD[2])  # the ledger and a quill
	c.rect(Rect2i(34, 38, 1, 10), P.WOOD[0])
	c.line(Vector2(36, 41), Vector2(42, 41), P.BONE[2])
	c.line(Vector2(36, 43), Vector2(41, 43), P.BONE[2])
	c.line(Vector2(36, 45), Vector2(42, 45), P.BONE[2])
	c.line(Vector2(43, 37), Vector2(39, 31), P.BONE[3])
	c.px(43, 37, P.OUTLINE)


func _ilse(c: Canvas) -> void:
	_shoulders(c, P.CULT_ROBE.slice(0, 5), P.GOLD)
	c.part()
	c.polygon(PackedVector2Array([Vector2(3, 48), Vector2(6, 37), Vector2(14, 32), Vector2(34, 32), Vector2(42, 37), Vector2(45, 48)]), P.CULT_ROBE, Vector3(-0.2, -0.3, 1))
	c.part()
	c.polygon(PackedVector2Array([Vector2(14, 33), Vector2(24, 48), Vector2(34, 33), Vector2(30, 33), Vector2(24, 41), Vector2(18, 33)]), P.SLATE, Vector3(-0.2, -0.4, 1))  # a dark scapular
	c.part()
	c.line(Vector2(17, 33), Vector2(24, 42), P.GOLD[2])  # the bell's cord
	c.line(Vector2(31, 33), Vector2(24, 42), P.GOLD[2])
	c.part()
	c.polygon(PackedVector2Array([Vector2(21, 42), Vector2(27, 42), Vector2(28.5, 46.5), Vector2(19.5, 46.5)]), P.GOLD, Vector3(-0.3, -0.4, 1))  # a small bell
	c.rect(Rect2i(23, 47, 2, 1), P.GOLD[3])
	_neck(c, P.SKIN)
	c.part()
	c.ellipse(Vector2(24, 20), Vector2(14.5, 16.5), P.CULT_ROBE, 0.0, 0.05)  # the wimple, wide
	c.part()
	c.ellipse(Vector2(24, 23), Vector2(7.2, 8.8), P.SKIN, 0.0, 0.1)
	c.part()
	c.polygon(PackedVector2Array([Vector2(15.5, 12), Vector2(24, 8), Vector2(32.5, 12), Vector2(30, 15), Vector2(24, 13.5), Vector2(18, 15)]), P.CULT_ROBE, Vector3(-0.2, -0.5, 1))  # the headband
	c.part()
	c.polygon(PackedVector2Array([Vector2(9, 33), Vector2(11, 20), Vector2(16, 13), Vector2(17, 21), Vector2(16, 30), Vector2(13, 36)]), P.CULT_ROBE, Vector3(-0.3, -0.4, 1))  # the veil's folds
	c.polygon(PackedVector2Array([Vector2(39, 33), Vector2(37, 20), Vector2(32, 13), Vector2(31, 21), Vector2(32, 30), Vector2(35, 36)]), P.CULT_ROBE, Vector3(0.3, -0.4, 1))
	c.part(true)
	c.ellipse(Vector2(24, 17), Vector2(7.0, 1.2), [Color(0.0, 0.0, 0.0, 0.14)], 0.0, 0.0)
	_eye(c, Vector2(19.4, 22.0), Color("7a8a98"))
	_eye(c, Vector2(26.2, 22.0), Color("7a8a98"))
	_brow(c, Vector2(18.5, 20.6), Vector2(22.0, 20.8), P.STEEL[3])
	_brow(c, Vector2(26.0, 20.8), Vector2(29.5, 20.6), P.STEEL[3])
	c.line(Vector2(24, 23.0), Vector2(23.6, 25.8), P.SKIN[1], true)
	c.line(Vector2(21.8, 28.6), Vector2(26.2, 28.6), P.SKIN[1], true)  # a thin, kind smile
	c.px(21, 28, P.SKIN[1])
	c.px(27, 28, P.SKIN[1])
	c.line(Vector2(17.5, 22.5), Vector2(16.5, 24), P.SKIN[1], true)  # lines at the eyes
	c.line(Vector2(30.5, 22.5), Vector2(31.5, 24), P.SKIN[1], true)
	c.tint_circle(Vector2(36, 28), 12.0, Color("ffb050"), 0.2)  # a candle's glow on the right
	c.part()
	c.rect(Rect2i(41, 38, 3, 8), P.BONE[3])  # the candle
	c.part(true)
	c.ellipse(Vector2(42.5, 35.5), Vector2(1.5, 2.6), P.FIRE.slice(2, 6), 0.0, 0.2)


func _orm(c: Canvas) -> void:
	c.part()
	c.rect(Rect2i(34, 22, 3, 22), P.WOOD[2])  # a hammer's haft behind the shoulder
	c.part()
	c.rect(Rect2i(30, 16, 13, 8), P.IRON_WORN[2])  # its head
	c.rect(Rect2i(30, 16, 13, 2), P.IRON_WORN[4])
	c.rect(Rect2i(30, 22, 13, 2), P.IRON_WORN[0])
	_shoulders(c, P.SKIN.slice(0, 4), [])
	c.part()
	c.polygon(PackedVector2Array([Vector2(12, 48), Vector2(14, 36), Vector2(20, 35), Vector2(24, 40), Vector2(28, 35), Vector2(34, 36), Vector2(36, 48)]), P.WOOD, Vector3(-0.2, -0.4, 1))  # the apron
	c.part()
	c.line(Vector2(14, 36), Vector2(8, 33), P.LEATHER[1])  # its straps over the shoulders
	c.line(Vector2(34, 36), Vector2(40, 33), P.LEATHER[1])
	c.line(Vector2(17, 40), Vector2(31, 40), P.LEATHER[0])
	for k: int in 5:  # burn scars on the shoulder
		c.px(6 + k, 38 + (k % 2), P.SKIN[1])
	_neck(c, P.SKIN)
	c.part()
	c.ellipse(Vector2(24, 19.5), Vector2(10.8, 12.0), P.SKIN, 0.0, 0.05)  # the bald head
	c.part()
	c.ellipse(Vector2(13.6, 21), Vector2(1.6, 2.6), P.SKIN, 0.0, -0.05)
	c.ellipse(Vector2(34.4, 21), Vector2(1.6, 2.6), P.SKIN, 0.0, -0.1)
	c.part()
	c.rect(Rect2i(14, 14, 20, 3), P.SKIN[1])  # the brow ridge
	c.part(true)
	c.ellipse(Vector2(24, 17.8), Vector2(9.0, 1.4), [Color(0.0, 0.0, 0.0, 0.25)], 0.0, 0.0)
	_eye(c, Vector2(18.2, 19.0), Color("8a5a1c"))
	_eye(c, Vector2(26.6, 19.0), Color("8a5a1c"))
	_brow(c, Vector2(16.5, 17.2), Vector2(22.5, 18.4), P.TABARD[1])
	_brow(c, Vector2(25.5, 18.4), Vector2(31.5, 17.2), P.TABARD[1])
	c.part()
	c.ellipse(Vector2(24, 23.8), Vector2(3.0, 2.6), P.SKIN, 0.0, 0.15)  # a big nose
	c.px(22, 25, P.SKIN[0])
	c.px(26, 25, P.SKIN[0])
	c.part()
	c.ellipse(Vector2(24, 33.5), Vector2(10.0, 7.0), P.TABARD.slice(0, 4), 0.0, 0.0)  # the beard
	c.ellipse(Vector2(24, 27.5), Vector2(6.5, 1.9), P.TABARD.slice(0, 4), 0.0, 0.1)  # the moustache
	for k: int in 6:  # braided strands, tied with iron rings
		c.line(Vector2(17 + k * 2.8, 31), Vector2(16 + k * 2.8 + (k % 2) * 1.4, 39), P.TABARD[1 + k % 2], true)
	for k: int in 2:
		c.part()
		c.ellipse(Vector2(20 + k * 8.0, 38.5), Vector2(1.6, 1.0), P.IRON_WORN, 0.0, 0.2)
	c.part(true)
	for k: int in 7:  # soot on the scalp and brow
		c.fine_px(Vector2(28.0 + (k % 4) * 1.3, 10.0 + floorf(k / 4.0) * 1.4 + (k % 3) * 0.6), P.STONE_WARM[1])
	c.tint_circle(Vector2(8, 24), 13.0, Color("ff8a2a"), 0.28)  # the forge's glow on the left
