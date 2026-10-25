extends RefCounted
## The rubble that blocks a build slot (dev-time art generator, M13 art pass; Pressure's Fewer Slots): a heap of
## broken stone, a splintered beam and dust on the slot's pad, 56x40 like the pad (28x20 art px at the double
## resolution), light from the top-left. One frame; BuildSlot shows it over the pad when the slot is locked.

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")

const SIZE: Vector2i = Vector2i(28, 20)

var detail: int = 1


func _init(resolution: int = 1) -> void:
	detail = resolution


func rubble() -> Image:
	var c: Canvas = Canvas.new(SIZE.x, SIZE.y, detail)
	# A flat scatter of gravel first, then the bigger blocks, a beam, and a dusty haze on top.
	for k: int in 14:
		var x: float = 5.0 + fposmod(k * 7.3, 18.0)
		var y: float = 11.0 + fposmod(k * 3.7, 7.0)
		c.part()
		c.ellipse(Vector2(x, y), Vector2(1.2 + (k % 3) * 0.3, 0.8), P.STONE_WARM, 0.0, 0.0)
	c.part()
	c.capsule(Vector2(6.0, 15.5), Vector2(19.0, 8.0), 1.0, P.WOOD, 0.0)  # a splintered beam
	c.px(19, 7, P.WOOD[4])
	c.px(20, 8, P.WOOD[1])
	for block: Array in [[Vector2(10, 12), Vector2(4.4, 3.4)], [Vector2(17, 13), Vector2(3.6, 2.8)], [Vector2(13.5, 9.5), Vector2(3.4, 2.6)], [Vector2(21.5, 11), Vector2(2.6, 2.2)], [Vector2(6.5, 12.5), Vector2(2.4, 2.0)]]:
		c.part()
		c.ellipse(block[0], block[1], P.STONE, 0.0, 0.0)
		c.part()
		c.ellipse(block[0] + Vector2(-block[1].x * 0.25, -block[1].y * 0.3), block[1] * 0.55, P.STONE, 0.0, 0.2)
	c.part()
	c.line(Vector2(9, 11), Vector2(11, 14), P.STONE[0], true)  # cracks
	c.line(Vector2(16, 12), Vector2(18, 15), P.STONE[0], true)
	c.line(Vector2(13, 8), Vector2(14.5, 11), P.STONE[1], true)
	c.finish()
	c.part(true)
	for k: int in 5:  # dust hanging over the heap (soft: no outline, so it follows finish())
		c.fine_px(Vector2(8.0 + k * 3.2, 8.0 + (k % 2) * 2.0), Color(0.78, 0.74, 0.66, 0.5))
	return c.image
