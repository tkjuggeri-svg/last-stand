extends RefCounted
## UI art (dev-time art generator): the small HUD icons. Textures are written at 2x (each art pixel = 2x2 texels)
## because TextureRect draws texels 1:1. The pixel font, framed panels, buttons and bar textures were retired in M15 P2
## (the vector theme, tools/art/build_ui_theme.gd, replaced them).

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")


## 10x10 art icons (saved at 2x): coin, keep, helm, skull, foundation, dash (a boot with speed lines).
func icon(kind: String) -> Image:
	var c: Canvas = Canvas.new(10, 10)
	match kind:
		"coin":
			c.part()
			c.ellipse(Vector2(5, 5), Vector2(4.2, 4.2), P.GOLD, 0.0, 0.1)
			c.rect(Rect2i(4, 3, 2, 4), P.GOLD[1])
			c.px(4, 3, P.GOLD[4])
		"keep":
			c.part()
			c.block(Rect2(2, 3, 6, 1), 5.0, P.STONE.slice(3, 7), P.STONE.slice(2, 6), false)
			for x: int in [2, 4, 6]:
				c.rect(Rect2i(x, 2, 1, 1), P.STONE[5])
			c.rect(Rect2i(4, 6, 2, 3), P.WOOD[1])
			c.px(5, 0, P.BANNER[3])
			c.px(5, 1, P.WOOD[2])
		"helm":
			c.part()
			c.ellipse(Vector2(5, 5.5), Vector2(3.6, 3.8), P.STEEL)
			c.rect(Rect2i(3, 5, 5, 1), P.OUTLINE)
			c.part()
			c.ellipse(Vector2(5, 1.6), Vector2(1.3, 1.4), P.TABARD, 0.0, 0.1)
		"skull":
			c.part()
			c.ellipse(Vector2(5, 4.5), Vector2(3.6, 3.4), P.BONE)
			c.rect(Rect2i(3, 6, 4, 2), P.BONE[2])
			c.px(3, 4, P.OUTLINE)
			c.px(4, 4, P.EYE_GLOW[2])
			c.px(6, 4, P.EYE_GLOW[2])
			c.px(7, 4, P.OUTLINE)
			c.px(4, 7, P.BONE[0])
			c.px(6, 7, P.BONE[0])
		"dash":
			c.part(true)
			for y: int in [3, 5, 7]:
				c.rect(Rect2i(0, y, 2 + (y % 3), 1), P.ICE[4] if y == 5 else P.ICE[3])
			c.part()
			c.polygon(PackedVector2Array([Vector2(4, 1), Vector2(8, 1), Vector2(8, 5.5), Vector2(10, 7), Vector2(10, 9.5),
				Vector2(3.5, 9.5), Vector2(3.5, 7), Vector2(4.5, 5.5)]), P.STEEL.slice(1, 4), Vector3(-0.5, -0.5, 1))
			c.rect(Rect2i(4, 2, 1, 5), P.STEEL[4])
			c.rect(Rect2i(7, 2, 1, 5), P.STEEL[1])
			c.rect(Rect2i(4, 7, 5, 1), P.STEEL[4])
			c.rect(Rect2i(4, 2, 4, 1), P.TABARD[3])
			c.rect(Rect2i(4, 9, 6, 1), P.LEATHER[2])
		"slot":
			c.part()
			c.cylinder(5, 5, 6, 4.4, 2.4, P.STONE, P.STONE.slice(2, 6))
			c.px(5, 3, P.GOLD[3])
	c.finish()
	return _x2(c.image)


func _x2(img: Image) -> Image:
	var out: Image = img.duplicate() as Image
	out.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	return out
