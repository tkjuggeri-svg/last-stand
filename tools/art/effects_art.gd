extends RefCounted
## Combat effects (dev-time art generator): sword swing trail, hit spark and dust.
## Effects use bright, saturated cores with darker rims and ordered-dither fades (never alpha blur),
## and stay short so they never hide the fight.

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")

const SWING_SIZE: Vector2i = Vector2i(72, 72)
const SWING_REACH: float = 34.0
## Long Reach trails: the swing drawn at these multiples of the normal reach (1 to 4 stacks of
## +15%), in bigger frames. Sprites never scale, so a longer swing needs its own art.
const REACH_TIERS: Array[float] = [1.15, 1.3, 1.45, 1.6]
const SWING_LONG_SIZE: Vector2i = Vector2i(128, 128)
const SPARK_SIZE: Vector2i = Vector2i(16, 16)
const DUST_SIZE: Vector2i = Vector2i(24, 24)


# ---------------------------------------------------------------- sword swing

## 8 rows (swing_0 points right, then every 45 degrees clockwise) of 4 frames.
func swing_rows() -> Array[Array]:
	var rows: Array[Array] = []
	for direction: int in 8:
		var frames: Array[Image] = []
		for frame: int in 4:
			frames.append(_swing_frame(direction * PI / 4.0, frame))
		rows.append(frames)
	return rows


## The Long Reach trails: per reach tier, 8 rows (one per direction) of 4 frames.
func swing_long_rows() -> Array[Array]:
	var rows: Array[Array] = []
	for tier: float in REACH_TIERS:
		for direction: int in 8:
			var frames: Array[Image] = []
			for frame: int in 4:
				frames.append(_swing_frame(direction * PI / 4.0, frame, SWING_LONG_SIZE, SWING_REACH * tier))
			rows.append(frames)
	return rows


## A crescent along the swing at the hitbox's 68 px reach (34 art px): a white-hot leading edge,
## a cool steel-blue body and a tail that breaks up into dither, plus a few flying glints.
func _swing_frame(facing: float, frame: int, size: Vector2i = SWING_SIZE, reach: float = SWING_REACH) -> Image:
	var img: Image = Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(size) / 2.0
	var grow: float = reach / SWING_REACH  # a longer swing has a proportionally thicker crescent
	var lead: float = deg_to_rad([-10.0, 30.0, 52.0, 56.0][frame])
	var trail: float = deg_to_rad([55.0, 95.0, 105.0, 90.0][frame])
	var fade: float = [0.0, 0.0, 0.35, 0.75][frame]
	var ramp: Array[Color] = [Color("3c4a6a"), Color("6f88b0"), Color("a9c2df"), Color("e4f0fa"), Color("ffffff")]
	for y: int in size.y:
		for x: int in size.x:
			var v: Vector2 = Vector2(x + 0.5, y + 0.5) - center
			var radius: float = v.length()
			var angle: float = wrapf(v.angle() - facing, -PI, PI)
			if angle > lead or angle < lead - trail or angle < deg_to_rad(-55.0):
				continue
			var t: float = (lead - angle) / trail  # 0 at the leading edge, 1 at the tail
			var thickness: float = lerpf(13.0, 2.5, t) * ([0.8, 1.0, 0.85, 0.6][frame]) * grow
			var depth: float = reach - radius  # 0 at the outer rim
			if depth < 0.0 or depth > thickness:
				continue
			var threshold: float = Canvas.BAYER_4[(y % 4) * 4 + (x % 4)] / 16.0
			if threshold < maxf(t - 0.6, 0.0) * 2.4 + fade:
				continue
			# Brightest at the outer rim and the leading edge, darker toward the inside and the tail.
			var value: float = 1.0 - t * 0.75 - (depth / maxf(thickness, 1.0)) * 0.45
			if depth < 1.2:
				value += 0.25
			img.set_pixel(x, y, Canvas.shade(ramp, value, x, y, true))
	# Glints thrown off the leading edge.
	if frame in [1, 2]:
		for k: int in 3:
			var a: float = facing + lead - deg_to_rad(8.0 + k * 22.0)
			var p: Vector2 = center + Vector2.from_angle(a) * (reach + 2.0 + k + frame)
			if p.x >= 0 and p.y >= 0 and p.x < size.x and p.y < size.y:
				img.set_pixel(int(p.x), int(p.y), Color("ffffff") if k == 0 else ramp[2])
	return img


# ---------------------------------------------------------------- hit spark

## A white flash that bursts into a four-point star, sheds sparks and fades (16x16, 4 frames).
func spark_frames() -> Array[Image]:
	var frames: Array[Image] = []
	var c: Vector2 = Vector2(8, 8)
	for frame: int in 4:
		var img: Image = Image.create_empty(SPARK_SIZE.x, SPARK_SIZE.y, false, Image.FORMAT_RGBA8)
		var reach: float = [3.5, 6.5, 7.5, 7.5][frame]
		var core: float = [2.4, 1.6, 0.0, 0.0][frame]
		for y: int in SPARK_SIZE.y:
			for x: int in SPARK_SIZE.x:
				var d: Vector2 = Vector2(x + 0.5, y + 0.5) - c
				# A four-point star: thin along the axes, round in the middle.
				var star: float = minf(absf(d.x), absf(d.y)) * 2.2 + d.length() * 0.35
				var diag: float = minf(absf(d.x - d.y), absf(d.x + d.y)) * 1.6 + d.length() * 0.6
				var color: Color = Color(0, 0, 0, 0)
				if d.length() <= core:
					color = Color("ffffff")
				elif star <= reach * 0.62 and frame < 3:
					var t: float = d.length() / reach
					color = Color("fffbe6") if t < 0.4 else (P.FIRE[4] if t < 0.75 else P.FIRE[3])
					if frame == 2 and d.length() < 3.5:
						color = Color(0, 0, 0, 0)  # the burst opens up
				elif diag <= reach * 0.45 and frame in [1, 2] and d.length() > 2.0:
					color = P.FIRE[3] if frame == 1 else P.FIRE[2]
				if color.a > 0.0:
					img.set_pixel(x, y, color)
		# Sparks flying outward in the last frames.
		if frame >= 2:
			for k: int in 6:
				var dir: Vector2 = Vector2.from_angle(k * TAU / 6.0 + 0.4)
				var p: Vector2 = c + dir * (5.0 + frame * 1.5)
				if Rect2(Vector2.ZERO, Vector2(SPARK_SIZE)).has_point(p):
					img.set_pixel(int(p.x), int(p.y), P.FIRE[4] if frame == 2 else P.FIRE[2])
		frames.append(img)
	return frames


# ---------------------------------------------------------------- dust

## A ground-level dust cloud: shaded puffs that billow outward and up, then thin out (24x24, 6 frames).
func dust_frames() -> Array[Image]:
	var frames: Array[Image] = []
	var ramp: Array[Color] = [Color("3a332d"), Color("554b41"), Color("736657"), Color("94856f"), Color("b3a48a")]
	var puffs: Array[Vector3] = [Vector3(12, 17, 3.2), Vector3(7, 16, 2.6), Vector3(17, 16, 2.6),
		Vector3(9.5, 12.5, 2.4), Vector3(14.5, 12, 2.6), Vector3(4, 18, 1.8), Vector3(20, 18, 1.8)]
	for frame: int in 6:
		var c: Canvas = Canvas.new(DUST_SIZE.x, DUST_SIZE.y)
		var grow: float = 0.85 + frame * 0.2
		for p: Vector3 in puffs:
			var at: Vector2 = Vector2(p.x, p.y)
			at += (at - Vector2(12, 16)) * frame * 0.16 + Vector2(0, -frame * 0.7)
			c.part(true)
			c.ellipse(at, Vector2(p.z, p.z * 0.85) * grow, ramp, 0.0, -0.05)
		var img: Image = c.image
		# Thin it out with ordered dither as it settles.
		for y: int in DUST_SIZE.y:
			for x: int in DUST_SIZE.x:
				if Canvas.BAYER_4[(y % 4) * 4 + (x % 4)] / 16.0 < maxf(frame - 2, 0) * 0.24:
					img.set_pixel(x, y, Color(0, 0, 0, 0))
		frames.append(img)
	return frames
