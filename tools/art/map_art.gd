extends RefCounted
## The run map's node icons (dev-time art generator): 16x16 art (the boss 24x24), saved at 2x like the
## other UI art, 1 px dark outline, light from the top-left (ART_DIRECTION.md). Each kind has its own
## shape so the map reads at a glance:
##   battle: crossed swords; elite: a horned red skull; event: a sealed scroll with a "?";
##   shrine: a stone altar with a green flame; merchant: a coin purse; boss: a crowned skull.

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")

const KINDS: Array[String] = ["battle", "elite", "event", "shrine", "merchant", "boss"]


func icon(kind: String) -> Image:
	var size: int = 24 if kind == "boss" else 16
	var c: Canvas = Canvas.new(size, size)
	call("_" + kind, c)
	c.finish()
	return _x2(c.image)


func _battle(c: Canvas) -> void:
	for flip: int in [0, 1]:
		var a: Vector2 = Vector2(2.5, 2.5) if flip == 0 else Vector2(13.5, 2.5)
		var b: Vector2 = Vector2(12, 12) if flip == 0 else Vector2(4, 12)
		c.part()
		c.capsule(a, b, 1.0, P.STEEL, 0.05)
		var guard: Vector2 = a.lerp(b, 0.72)
		var across: Vector2 = Vector2(1, -1) if flip == 0 else Vector2(1, 1)
		c.line(guard - across * 2.0, guard + across * 2.0, P.GOLD[2])
		c.capsule(b, b + (b - a).normalized() * 2.2, 0.9, P.LEATHER)


func _elite(c: Canvas) -> void:
	c.part()
	c.polygon(PackedVector2Array([Vector2(2, 1), Vector2(5, 6), Vector2(3, 7)]), P.BONE, Vector3(-0.5, -0.5, 1))
	c.polygon(PackedVector2Array([Vector2(14, 1), Vector2(11, 6), Vector2(13, 7)]), P.BONE, Vector3(0.5, -0.5, 1))
	c.part()
	c.ellipse(Vector2(8, 8.5), Vector2(5.2, 4.8), P.TABARD, 0.0, 0.05)
	c.rect(Rect2i(5, 11, 6, 3), P.TABARD[2])
	c.rect(Rect2i(5, 8, 2, 2), P.OUTLINE)
	c.rect(Rect2i(9, 8, 2, 2), P.OUTLINE)
	c.px(6, 8, P.EYE_GLOW[3])
	c.px(9, 8, P.EYE_GLOW[3])
	for x: int in [6, 8, 10]:
		c.px(x, 13, P.OUTLINE)


func _event(c: Canvas) -> void:
	c.part()
	c.polygon(PackedVector2Array([Vector2(3, 3), Vector2(13, 3), Vector2(13, 13), Vector2(3, 13)]), P.BONE, Vector3(-0.2, -0.2, 1))
	c.capsule(Vector2(3, 3), Vector2(13, 3), 1.3, P.WOOD)
	c.capsule(Vector2(3, 13), Vector2(13, 13), 1.3, P.WOOD)
	# The question mark.
	for p: Vector2i in [Vector2i(6, 5), Vector2i(7, 5), Vector2i(8, 5), Vector2i(9, 6), Vector2i(9, 7), Vector2i(8, 8),
			Vector2i(7, 9), Vector2i(7, 11)]:
		c.px(p.x, p.y, P.BANNER[2])
	c.part()
	c.ellipse(Vector2(12, 12), Vector2(1.6, 1.6), P.BANNER, 0.0, 0.1)


func _shrine(c: Canvas) -> void:
	c.part()
	c.block(Rect2(3, 9, 10, 2), 4.0, P.STONE.slice(2, 7), P.STONE.slice(1, 6), false)
	c.part(true)
	c.polygon(PackedVector2Array([Vector2(5, 9), Vector2(8, 1), Vector2(11, 9)]), [P.SOUL[2]], Vector3(0, 0, 1))
	c.polygon(PackedVector2Array([Vector2(6.5, 9), Vector2(8, 4), Vector2(9.5, 9)]), [P.SOUL[4]], Vector3(0, 0, 1))


func _merchant(c: Canvas) -> void:
	c.part()
	c.ellipse(Vector2(8, 10), Vector2(5.5, 4.5), P.LEATHER, 0.0, 0.05)
	c.rect(Rect2i(6, 4, 4, 3), P.LEATHER[2])
	c.line(Vector2(5, 6), Vector2(11, 6), P.GOLD[2])
	c.part()
	c.ellipse(Vector2(8, 10.5), Vector2(2.2, 2.2), P.GOLD, 0.0, 0.1)
	c.px(8, 10, P.GOLD[1])


func _boss(c: Canvas) -> void:
	c.part()
	c.polygon(PackedVector2Array([Vector2(5, 7), Vector2(6, 2), Vector2(9, 5), Vector2(12, 1), Vector2(15, 5), Vector2(18, 2), Vector2(19, 7)]),
		P.GOLD, Vector3(-0.3, -0.5, 1))
	c.part()
	c.ellipse(Vector2(12, 13), Vector2(7.5, 6.5), P.BONE, 0.0, 0.05)
	c.rect(Rect2i(8, 17, 8, 4), P.BONE[2])
	c.rect(Rect2i(8, 12, 3, 3), P.OUTLINE)
	c.rect(Rect2i(13, 12, 3, 3), P.OUTLINE)
	c.px(9, 13, P.EYE_GLOW[2])
	c.px(14, 13, P.EYE_GLOW[2])
	for x: int in [9, 11, 13, 15]:
		c.px(x, 19, P.OUTLINE)


func _x2(img: Image) -> Image:
	var out: Image = img.duplicate() as Image
	out.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	return out
