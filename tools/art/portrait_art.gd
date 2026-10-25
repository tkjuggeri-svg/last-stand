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


func _shoulders(c: Canvas, ramp: Array, trim: Array = []) -> void:
	c.part()
	c.polygon(PackedVector2Array([Vector2(2, 48), Vector2(5, 36), Vector2(14, 32), Vector2(34, 32), Vector2(43, 36), Vector2(46, 48)]), ramp, Vector3(-0.3, -0.4, 1))
	if not trim.is_empty():
		c.line(Vector2(14, 33), Vector2(34, 33), trim[2])


func _face(c: Canvas, at: Vector2, radius: Vector2, ramp: Array) -> void:
	c.part()
	c.ellipse(at, radius, ramp, 0.0, 0.1)


func _eyes(c: Canvas, y: int, color: Color, glow: bool = false) -> void:
	for x: int in [19, 28]:
		c.px(x, y, P.OUTLINE)
		c.px(x + 1, y, color if glow else P.OUTLINE)


func _knight(c: Canvas) -> void:
	_shoulders(c, P.STEEL, P.GOLD)
	c.part()
	c.polygon(PackedVector2Array([Vector2(8, 38), Vector2(14, 32), Vector2(34, 32), Vector2(40, 38), Vector2(36, 36), Vector2(12, 36)]), P.GOLD, Vector3(-0.3, -0.4, 1))
	c.part()
	c.ellipse(Vector2(24, 20), Vector2(11, 12.5), P.STEEL, 0.0, -0.05)
	c.part()
	c.rect(Rect2i(14, 19, 20, 2), P.OUTLINE)  # the visor slit
	c.rect(Rect2i(14, 17, 20, 2), P.GOLD[3])
	c.rect(Rect2i(14, 21, 20, 1), P.GOLD[1])
	c.rect(Rect2i(23, 22, 2, 10), P.STEEL[1])
	for x: int in [18, 30]:
		c.px(x, 27, P.STEEL[1])
		c.px(x, 29, P.STEEL[1])
	c.part()
	c.polygon(PackedVector2Array([Vector2(20, 9), Vector2(22, 1), Vector2(26, 4), Vector2(29, 0), Vector2(31, 9)]), P.TABARD, Vector3(-0.2, -0.5, 1))


func _huntress(c: Canvas) -> void:
	_shoulders(c, P.LEATHER)
	c.part()
	c.line(Vector2(10, 34), Vector2(40, 44), P.LEATHER[0])  # the quiver strap
	c.ellipse(Vector2(24, 18), Vector2(14, 15), P.HOOD, 0.0, -0.05)
	_face(c, Vector2(24, 23), Vector2(8.5, 9.5), P.SKIN)
	c.part()
	c.rect(Rect2i(16, 14, 17, 3), P.HOOD[0])  # the hood's shadow
	_eyes(c, 22, P.OUTLINE)
	c.rect(Rect2i(22, 27, 5, 1), P.SKIN[1])
	c.part()
	c.polygon(PackedVector2Array([Vector2(18, 7), Vector2(24, 0), Vector2(30, 7)]), P.HOOD, Vector3(-0.2, -0.5, 1))
	c.part()
	c.line(Vector2(33, 36), Vector2(39, 28), P.WOOD[3])  # a crossbow limb at the shoulder
	c.line(Vector2(33, 36), Vector2(41, 36), P.STEEL[3])


func _necromancer(c: Canvas) -> void:
	_shoulders(c, P.LICH_ROBE)
	c.part()
	c.ellipse(Vector2(24, 18), Vector2(14, 15), P.LICH_ROBE, 0.0, -0.05)
	_face(c, Vector2(24, 23), Vector2(8.0, 9.0), P.BONE)
	c.part()
	c.rect(Rect2i(16, 14, 17, 3), P.LICH_ROBE[0])
	_eyes(c, 22, P.SOUL[3], true)
	c.part(true)
	c.px(19, 21, P.SOUL[2])
	c.px(29, 21, P.SOUL[2])
	c.part()
	c.polygon(PackedVector2Array([Vector2(18, 7), Vector2(24, 0), Vector2(30, 7)]), P.LICH_ROBE, Vector3(-0.2, -0.5, 1))
	c.part()
	c.ellipse(Vector2(40, 30), Vector2(3.0, 3.0), P.BONE, 0.0, 0.2)  # the staff's skull
	c.rect(Rect2i(39, 33, 2, 15), P.WOOD[2])
	c.part(true)
	c.ellipse(Vector2(40, 25), Vector2(1.6, 2.2), P.SOUL, 0.0, 0.3)


func _quartermaster(c: Canvas) -> void:
	_shoulders(c, P.LEATHER)
	c.part()
	c.line(Vector2(16, 34), Vector2(32, 34), P.GOLD[2])
	_face(c, Vector2(24, 21), Vector2(9.5, 11), P.SKIN)
	c.part()
	c.ellipse(Vector2(24, 11), Vector2(11, 5), P.LEATHER, 0.0, 0.0)  # a cap
	c.rect(Rect2i(13, 12, 22, 2), P.LEATHER[1])
	_eyes(c, 20, P.OUTLINE)
	c.part()
	c.ellipse(Vector2(24, 30), Vector2(8, 4.2), P.STEEL.slice(1, 5), 0.0, 0.1)  # a grey beard
	c.rect(Rect2i(21, 25, 7, 1), P.STEEL[2])
	c.part()
	c.rect(Rect2i(36, 36, 8, 10), P.WOOD[2])  # the ledger
	c.line(Vector2(37, 40), Vector2(43, 40), P.BONE[2])


func _ilse(c: Canvas) -> void:
	_shoulders(c, P.CULT_ROBE)
	c.part()
	c.ellipse(Vector2(24, 19), Vector2(14.5, 16), P.CULT_ROBE, 0.0, 0.05)  # the wimple
	_face(c, Vector2(24, 22), Vector2(7.6, 9.2), P.SKIN)
	_eyes(c, 21, P.OUTLINE)
	c.rect(Rect2i(22, 27, 5, 1), P.SKIN[1])
	c.part()
	c.rect(Rect2i(17, 12, 14, 2), P.CULT_ROBE[3])
	c.part()
	c.ellipse(Vector2(24, 38), Vector2(1.6, 2.0), P.GOLD, 0.0, 0.3)  # a small pendant
	c.line(Vector2(19, 33), Vector2(24, 36), P.GOLD[2])
	c.line(Vector2(29, 33), Vector2(24, 36), P.GOLD[2])


func _orm(c: Canvas) -> void:
	_shoulders(c, P.LEATHER)
	c.part()
	c.polygon(PackedVector2Array([Vector2(12, 48), Vector2(14, 36), Vector2(34, 36), Vector2(36, 48)]), P.WOOD, Vector3(-0.2, -0.4, 1))  # an apron
	_face(c, Vector2(24, 20), Vector2(10.5, 11.5), P.SKIN)
	c.part()
	c.rect(Rect2i(14, 15, 20, 3), P.SKIN[1])  # a heavy brow
	_eyes(c, 19, P.OUTLINE)
	c.part()
	c.ellipse(Vector2(24, 29), Vector2(10.5, 6.5), P.TABARD.slice(0, 4), 0.0, 0.0)  # a red-brown beard
	c.rect(Rect2i(20, 24, 8, 1), P.TABARD[1])
	c.part()
	c.ellipse(Vector2(31, 14), Vector2(2.0, 1.2), P.STONE_WARM.slice(0, 3), 0.0, 0.0)  # soot
