extends RefCounted
## Shared death effects of the undead (dev-time art generator): the pale hit flash, the body crumbling
## to ash and bone, and the green soul escaping. Used by ghoul_art.gd, hound_art.gd and brute_art.gd.

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")


## Eats the body away from the top with an ordered-dither pattern, leaving dark ash and bone bits.
static func crumble(img: Image, step: int, detail: int = 1) -> void:
	var used: Rect2i = img.get_used_rect()
	var cut: float = [0.35, 0.7, 1.0][step]
	for y: int in img.get_height():
		for x: int in img.get_width():
			var c: Color = img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var t: float = 1.0 - float(y - used.position.y) / maxf(used.size.y, 1.0)
			var threshold: float = Canvas.BAYER_4[(y % 4) * 4 + (x % 4)] / 16.0
			if t * 0.6 + threshold * 0.6 < cut:
				var ash: bool = (x * 7 + y * 3) % 5 == 0 and y > used.position.y + used.size.y - 4 * detail
				img.set_pixel(x, y, (P.BONE[1] if (x + y) % 3 == 0 else P.SMOKE[1]) if ash else Color(0, 0, 0, 0))
			elif step >= 1:
				img.set_pixel(x, y, Color(c.lerp(P.SMOKE[1], 0.3 * step), c.a))


## The pale green soul wisp rising out of the remains (`start` = where it leaves the body; `scale`
## makes it bigger for big bodies). `detail` = image pixels per art pixel.
static func soul(img: Image, step: int, start: Vector2, scale: float = 1.0, detail: int = 1) -> void:
	var base: Vector2 = (start - Vector2(0, step * 6 * scale)) * detail
	var radius: float = [2.6, 2.2, 1.6][step] * scale * detail
	for y: int in range(floori(base.y - radius * 2.5), ceili(base.y + radius) + 1):
		for x: int in range(floori(base.x - radius), ceili(base.x + radius) + 1):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var d: Vector2 = Vector2(x + 0.5 - base.x - sin(float(y) / detail * 0.8 + step) * 0.6 * detail, (y + 0.5 - base.y) * (0.4 if y < base.y else 1.0))
			var k: float = d.length() / radius
			if k > 1.0:
				continue
			if step == 2 and Canvas.BAYER_4[(y % 4) * 4 + (x % 4)] < 8:
				continue
			img.set_pixel(x, y, P.SOUL[4] if k < 0.35 else (P.SOUL[3] if k < 0.7 else P.SOUL[2]))


static func tint(img: Image, color: Color, amount: float) -> void:
	for y: int in img.get_height():
		for x: int in img.get_width():
			var c: Color = img.get_pixel(x, y)
			if c.a > 0.5:
				img.set_pixel(x, y, Color(c.lerp(color, amount), c.a))
