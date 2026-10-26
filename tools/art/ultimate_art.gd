extends RefCounted
## The hero ultimates' effect art (M14, dev-time art generator), drawn at world resolution (one pixel = one world pixel,
## sprite scale 1): the Knight's Last Stand ring, a ring of golden light racing out to the radius that is hit and fading
## with dither. Two rows, one per radius: the base 160 px and the 224 px of Wider Circle.

const P: GDScript = preload("res://tools/art/palette.gd")
const Canvas: GDScript = preload("res://tools/art/canvas.gd")

const SIZE: Vector2i = Vector2i(480, 480)
const RADII: Array[float] = [160.0, 224.0]
## How far out the ring is in each frame (a share of the radius), and the light left behind it fades after frame 3.
const REACH: Array[float] = [0.3, 0.6, 0.82, 0.94, 1.0, 1.0]
const RING_WIDTH: float = 3.0
const GLOW_WIDTH: float = 22.0


## Both rows of the sheet.
func rows() -> Array[Array]:
	var out: Array[Array] = []
	for radius: float in RADII:
		out.append(ring_frames(radius))
	return out


func ring_frames(radius: float) -> Array[Image]:
	var frames: Array[Image] = []
	var center: Vector2 = Vector2(SIZE) / 2.0
	for frame: int in REACH.size():
		var img: Image = Image.create_empty(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
		var reach: float = radius * REACH[frame]
		var fade: float = maxf(frame - 3, 0) * 0.3
		for y: int in SIZE.y:
			for x: int in SIZE.x:
				var v: Vector2 = Vector2(x + 0.5, y + 0.5) - center
				var d: float = v.length()
				if d > reach + RING_WIDTH or d < reach - GLOW_WIDTH:
					if not (frame == 0 and d < 6.0):
						continue
				var threshold: float = Canvas.BAYER_4[(y % 4) * 4 + (x % 4)] / 16.0
				if threshold < fade:
					continue  # the light thins out with dither as it fades
				var spoke: float = absf(sin(v.angle() * 12.0))  # twelve rays inside the ring
				var color: Color = Color(0, 0, 0, 0)
				if absf(d - reach) < RING_WIDTH * 0.5:
					color = P.GOLD[4]
				elif d <= reach + RING_WIDTH and d > reach - RING_WIDTH:
					color = P.GOLD[3]
				elif d < reach and d > reach - GLOW_WIDTH:
					var depth: float = (reach - d) / GLOW_WIDTH  # 0 at the ring, 1 at the glow's inner edge
					if spoke < 0.16 and threshold < 0.55 - depth * 0.4:
						color = P.GOLD[2]
					elif threshold < 0.32 - depth * 0.3:
						color = P.GOLD[1]
				elif frame == 0 and d < 6.0:
					color = Color("ffffff")
				if color.a > 0.0:
					img.set_pixel(x, y, color)
		frames.append(img)
	return frames
