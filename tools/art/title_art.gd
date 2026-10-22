extends RefCounted
## The title screen's key art (M8.5): the last knight, seen from behind on a ledge, watches the horde
## of the dead come down the road toward the fortress at dusk. 640 x 360 art px (one screen), saved
## pre-scaled to 2x like every UI texture. Drawn with plain pixel fills (no sprite outlines): a dusk
## sky in dithered bands, a moon, layered mountains and fog, the fortress dark against the sky with
## moon rim-light, lit windows, banners and wall fires, the horde as silhouettes with red eyes fading
## into the fog, and the knight in the foreground, his red plume and cape the accent (ART_DIRECTION:
## red is the accent, the dead have red eyes, light from the moon at the top right here).

const P: GDScript = preload("res://tools/art/palette.gd")

const W: int = 640
const H: int = 360
## Sky bands from the top to the horizon glow.
const SKY: Array[Color] = [Color("0d0a15"), Color("140f20"), Color("1c152b"), Color("261b35"), Color("33203c"), Color("47253f"),
	Color("62293f"), Color("843a3f"), Color("a85440")]
const HORIZON_Y: int = 236
const MOON: Vector2 = Vector2(478, 74)
const MOON_RADIUS: float = 28.0
const RIM: Color = Color("6a6288")
const FOG: Color = Color("4b3b58")
const NIGHT: Color = Color("0b0810")
const BAYER: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
## The road from the bottom left to the fortress gate (a quadratic curve).
const ROAD: Array[Vector2] = [Vector2(372, 360), Vector2(372, 280), Vector2(470, 232)]
## Where the knight stands (his drawing is made around x 222, moved here).
const KNIGHT_SHIFT: Vector2 = Vector2(22, 0)

var _img: Image
## Added to every point drawn (the knight is drawn around his own spot, then moved).
var _offset: Vector2 = Vector2.ZERO
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## The key art at screen size (1280 x 720).
func scene() -> Image:
	_rng.seed = 1347
	_img = Image.create(W, H, false, Image.FORMAT_RGBA8)
	_sky()
	_stars()
	_moon()
	_mountains()
	_fortress()
	_fog(222, 268, 0.55)
	_field()
	_road()
	_horde()
	_fog(268, 300, 0.25)
	_ledge()
	_tree()
	_crosses()
	_knight()
	_vignette()
	var big: Image = _img.duplicate() as Image
	big.resize(W * 2, H * 2, Image.INTERPOLATE_NEAREST)
	return big


# ---------------------------------------------------------------- sky

func _sky() -> void:
	for y: int in H:
		var t: float = clampf(float(y) / HORIZON_Y, 0.0, 1.0) * (SKY.size() - 1)
		for x: int in W:
			var band: int = mini(floori(t), SKY.size() - 2)
			_img.set_pixel(x, y, SKY[band + 1] if _dither(x, y, t - band) else SKY[band])


func _stars() -> void:
	for _i: int in 90:
		var at: Vector2i = Vector2i(_rng.randi_range(0, W - 1), _rng.randi_range(0, 170))
		if Vector2(at).distance_to(MOON) < MOON_RADIUS + 20.0:
			continue
		var bright: bool = _rng.randf() < 0.2
		_img.set_pixelv(at, Color("d8d0e4") if bright else Color("7f7596"))
		if bright and _rng.randf() < 0.4:
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				_blend(at.x + d.x, at.y + d.y, Color("7f7596"), 0.8)


func _moon() -> void:
	for y: int in range(int(MOON.y - 70), int(MOON.y + 70)):
		for x: int in range(int(MOON.x - 70), int(MOON.x + 70)):
			var d: float = Vector2(x, y).distance_to(MOON)
			if d <= MOON_RADIUS:
				var shade: float = (Vector2(x, y) - MOON).dot(Vector2(-0.6, 0.7)) / MOON_RADIUS
				var c: Color = Color("ece5d0") if shade < 0.35 else Color("d2c8ad")
				if shade > 0.75:
					c = Color("b4a98e")
				_img.set_pixel(x, y, c)
			elif d < MOON_RADIUS + 40.0 and _dither(x, y, 1.0 - (d - MOON_RADIUS) / 40.0):
				_blend(x, y, Color("8a7a96"), 0.35)
	for crater: Vector3 in [Vector3(-8, -6, 5), Vector3(7, 4, 4), Vector3(-2, 12, 3), Vector3(11, -10, 2)]:
		_disc(MOON + Vector2(crater.x, crater.y), crater.z, Color("c6bb9e"))


# ---------------------------------------------------------------- land

func _mountains() -> void:
	for x: int in W:
		var far: int = roundi(200.0 + 14.0 * sin(x / 61.0) + 8.0 * sin(x / 23.0 + 1.3) + 3.0 * sin(x / 7.0))
		var near: int = roundi(226.0 + 10.0 * sin(x / 47.0 + 2.0) + 5.0 * sin(x / 17.0) + 2.0 * sin(x / 5.0 + 0.4))
		for y: int in range(far, H):
			_img.set_pixel(x, y, Color("2b1f36") if y > far else Color("4a3a5a"))
		for y: int in range(near, H):
			_img.set_pixel(x, y, Color("1d1528") if y > near else Color("3a2d4a"))


func _fog(top: int, bottom: int, strength: float) -> void:
	var middle: float = (top + bottom) / 2.0
	for y: int in range(top, bottom):
		var t: float = (1.0 - absf(y - middle) / ((bottom - top) / 2.0)) * strength
		for x: int in W:
			var wave: float = t * (0.75 + 0.25 * sin(x / 37.0 + y / 9.0))
			if _dither(x, y, wave):
				_blend(x, y, FOG, 0.55)


func _field() -> void:
	# The hill the fortress stands on and the dark plain before it.
	for x: int in W:
		var hill: float = 250.0 - 26.0 * exp(-pow((x - 478.0) / 80.0, 2.0))
		var top: int = roundi(minf(hill, 262.0 + 4.0 * sin(x / 13.0)))
		for y: int in range(top, H):
			_img.set_pixel(x, y, Color("120d18") if y > top else Color("2c2238"))


func _road() -> void:
	for i: int in 400:
		var t: float = i / 399.0
		var at: Vector2 = _road_point(t)
		var width: float = lerpf(46.0, 5.0, t)
		for dx: int in range(-ceili(width), ceili(width) + 1):
			var x: int = roundi(at.x + dx)
			var y: int = roundi(at.y)
			var edge: float = absf(dx) / width
			if edge <= 1.0 and _inside(x, y):
				_img.set_pixel(x, y, Color("2a2030") if edge > 0.55 or _dither(x, y, 0.3) else Color("352838"))


func _road_point(t: float) -> Vector2:
	return ROAD[0].lerp(ROAD[1], t).lerp(ROAD[1].lerp(ROAD[2], t), t)


# ---------------------------------------------------------------- the fortress

func _fortress() -> void:
	var dark: Color = Color("17111e")
	# Curtain wall with battlements, two corner towers, the gate tower and the keep.
	_box(Rect2i(424, 196, 112, 32), dark)
	for x: int in range(424, 536, 6):
		_box(Rect2i(x, 192, 3, 4), dark)
	for tower: Vector3i in [Vector3i(410, 176, 18), Vector3i(532, 178, 18), Vector3i(469, 186, 20)]:
		_box(Rect2i(tower.x, tower.y, tower.z, 228 - tower.y), dark)
		_triangle(Vector2(tower.x - 2, tower.y), Vector2(tower.x + tower.z + 2, tower.y), Vector2(tower.x + tower.z / 2.0, tower.y - 16), Color("1d1626"))
	_box(Rect2i(458, 152, 42, 44), dark)
	_triangle(Vector2(455, 152), Vector2(503, 152), Vector2(479, 128), Color("1d1626"))
	_box(Rect2i(478, 112, 2, 18), dark)
	_banner(Vector2i(480, 112), 10)
	_banner(Vector2i(419, 160), 6)
	_banner(Vector2i(541, 162), 6)
	_rim(Rect2i(404, 108, 150, 124), dark)
	for window: Vector2i in [Vector2i(466, 162), Vector2i(476, 162), Vector2i(488, 162), Vector2i(466, 176), Vector2i(488, 176),
			Vector2i(416, 190), Vector2i(538, 192), Vector2i(477, 200)]:
		_glow(window, 6.0, P.FIRE[2], 0.35)
		_box(Rect2i(window.x, window.y, 2, 3), P.FIRE[4])
	for fire: Vector2i in [Vector2i(434, 190), Vector2i(524, 190)]:
		_glow(fire, 9.0, P.FIRE[2], 0.45)
		_box(Rect2i(fire.x - 1, fire.y - 3, 3, 3), P.FIRE[3])
		_img.set_pixel(fire.x, fire.y - 4, P.FIRE[4])


func _banner(top: Vector2i, length: int) -> void:
	for i: int in length:
		var wave: int = roundi(sin(i / 2.0) * 1.0)
		for y: int in range(0, 5 - i / 4):
			_img.set_pixel(top.x + 1 + i, top.y + 1 + y + wave, P.BANNER[2] if y == 0 else P.BANNER[1])


## Moon rim-light: the right edge of every dark shape inside `area`.
func _rim(area: Rect2i, dark: Color) -> void:
	var before: Image = _img.duplicate() as Image
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			if before.get_pixel(x, y).is_equal_approx(dark) and not before.get_pixel(x + 1, y).is_equal_approx(dark):
				_img.set_pixel(x, y, Color("3d3150"))


# ---------------------------------------------------------------- the dead

func _horde() -> void:
	var walkers: Array[Vector3] = []
	for _i: int in 90:
		var t: float = _rng.randf_range(0.05, 0.95)
		var across: float = _rng.randf_range(-1.0, 1.0) * lerpf(110.0, 10.0, t)
		var at: Vector2 = _road_point(t) + Vector2(across, absf(across) * 0.12)
		walkers.append(Vector3(at.x, at.y, t))
	walkers.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.y < b.y)  # far ones first
	for walker: Vector3 in walkers:
		var scale: float = lerpf(1.35, 0.3, walker.z)
		var shade: Color = NIGHT.lerp(FOG, clampf(walker.z * 0.9, 0.0, 0.75))
		_dead_one(Vector2(walker.x, walker.y), scale * (1.6 if _rng.randf() < 0.12 else 1.0), shade)


## A hunched figure of the dead, feet at `at`, with red eyes.
func _dead_one(at: Vector2, scale: float, shade: Color) -> void:
	var height: float = 26.0 * scale
	var lean: float = 3.0 * scale
	_ellipse(at + Vector2(lean * 0.4, -height * 0.45), Vector2(5.0 * scale, height * 0.32), shade)
	_disc(at + Vector2(lean, -height * 0.78), maxf(2.6 * scale, 1.0), shade)
	_line(at + Vector2(-2.0 * scale, -height * 0.2), at + Vector2(-3.0 * scale, 0), maxf(scale * 1.6, 1.0), shade)
	_line(at + Vector2(2.0 * scale, -height * 0.2), at + Vector2(3.0 * scale, 0), maxf(scale * 1.6, 1.0), shade)
	_line(at + Vector2(lean + 3.0 * scale, -height * 0.6), at + Vector2(lean + 6.0 * scale, -height * 0.25), maxf(scale * 1.2, 1.0), shade)
	if scale > 0.6:
		# The moon catches the top of the head and the hunched back.
		_line(at + Vector2(lean + 1.0 * scale, -height * 0.9), at + Vector2(lean + 3.0 * scale, -height * 0.84), 1.0, Color("3a2e48"))
		_line(at + Vector2(lean * 0.4 + 4.0 * scale, -height * 0.66), at + Vector2(lean * 0.4 + 5.0 * scale, -height * 0.4), 1.0, Color("2e2440"))
	var eye: Vector2i = Vector2i((at + Vector2(lean + 1.0 * scale, -height * 0.8)).round())
	if scale > 0.45:
		_glow(eye, 3.0 * scale, P.EYE_GLOW[1], 0.5)
	_img.set_pixel(eye.x, eye.y, P.EYE_GLOW[2])
	if scale > 0.7:
		_img.set_pixel(eye.x + 2, eye.y, P.EYE_GLOW[2])


# ---------------------------------------------------------------- the foreground

func _ledge() -> void:
	for x: int in W:
		var top: int = roundi(326.0 + 8.0 * sin(x / 31.0) + 4.0 * sin(x / 11.0 + 2.0) - 10.0 * exp(-pow((x - 222.0 - KNIGHT_SHIFT.x) / 70.0, 2.0)))
		for y: int in range(top, H):
			_img.set_pixel(x, y, NIGHT if y > top else Color("221a2a"))
		if _rng.randf() < 0.35:
			var blade: int = _rng.randi_range(2, 6)
			_line(Vector2(x, top), Vector2(x + _rng.randi_range(-2, 2), top - blade), 1.0, NIGHT)


func _tree() -> void:
	# A dead tree framing the right edge, a crow on its bough watching the road.
	var dark: Color = Color("0d0a12")
	_line(Vector2(612, 340), Vector2(600, 214), 7.0, dark)
	_line(Vector2(602, 246), Vector2(640, 198), 3.0, dark)
	_line(Vector2(601, 236), Vector2(560, 196), 3.0, dark)
	_line(Vector2(570, 204), Vector2(546, 202), 2.0, dark)
	_line(Vector2(600, 218), Vector2(594, 166), 3.0, dark)
	_line(Vector2(596, 184), Vector2(578, 160), 2.0, dark)
	_ellipse(Vector2(566, 196), Vector2(4, 3), dark)
	_disc(Vector2(562, 192), 2.0, dark)
	_img.set_pixel(559, 192, dark)
	_img.set_pixel(562, 191, P.EYE_GLOW[2])


func _crosses() -> void:
	var dark: Color = Color("0e0b13")
	for cross: Vector3 in [Vector3(26, 334, 1.0), Vector3(62, 326, 0.75), Vector3(240, 344, 0.55)]:
		var size: float = 30.0 * cross.z
		_box(Rect2i(roundi(cross.x - 2 * cross.z), roundi(cross.y - size), maxi(roundi(4 * cross.z), 2), roundi(size)), dark)
		_box(Rect2i(roundi(cross.x - 9 * cross.z), roundi(cross.y - size * 0.72), roundi(18 * cross.z), maxi(roundi(4 * cross.z), 2)), dark)


func _knight() -> void:
	_offset = KNIGHT_SHIFT
	var plate: Color = Color("1b1a26")
	var plate_light: Color = P.DARK_STEEL[2]
	# Legs and boots (standing on the ledge), cut by the bottom of the screen.
	_quad([Vector2(204, 296), Vector2(216, 296), Vector2(214, 338), Vector2(200, 338)], plate)
	_quad([Vector2(222, 296), Vector2(234, 296), Vector2(238, 338), Vector2(224, 338)], plate)
	_quad([Vector2(196, 334), Vector2(216, 334), Vector2(216, 346), Vector2(194, 346)], Color("120f18"))
	_quad([Vector2(222, 334), Vector2(242, 334), Vector2(244, 346), Vector2(222, 346)], Color("120f18"))
	# The cape, blown to the left by the wind off the plain, its hem torn.
	var hem: PackedVector2Array = PackedVector2Array([Vector2(190, 236), Vector2(248, 236), Vector2(262, 290), Vector2(254, 318)])
	for i: int in 11:
		hem.append(Vector2(254 - i * 9.5, 318 + (6 if i % 2 == 0 else -2) + i * 1.2))
	hem.append(Vector2(150, 316))
	hem.append(Vector2(170, 276))
	_poly(hem, P.CAPE[1])
	for fold: Array in [[Vector2(206, 244), Vector2(186, 318)], [Vector2(222, 244), Vector2(214, 324)], [Vector2(236, 244), Vector2(240, 320)]]:
		_line(fold[0], fold[1], 2.0, P.CAPE[0])
	for light: Array in [[Vector2(246, 242), Vector2(258, 300)], [Vector2(230, 248), Vector2(232, 318)]]:
		_line(light[0], light[1], 1.0, P.CAPE[2])
	# Shoulders and pauldrons, the great helm, the plume.
	_ellipse(Vector2(194, 240), Vector2(13, 8), plate)
	_ellipse(Vector2(244, 240), Vector2(13, 8), plate)
	_box(Rect2i(206, 230, 26, 16), plate)
	_quad([Vector2(207, 204), Vector2(231, 204), Vector2(233, 232), Vector2(205, 232)], plate)
	_ellipse(Vector2(219, 205), Vector2(12, 6), plate)
	var plume: PackedVector2Array = PackedVector2Array([Vector2(219, 198), Vector2(214, 188), Vector2(198, 186), Vector2(176, 196),
		Vector2(160, 212), Vector2(172, 206), Vector2(186, 200), Vector2(200, 199)])
	_poly(plume, P.TABARD[2])
	_line(Vector2(216, 190), Vector2(178, 200), 1.0, P.TABARD[3])
	_line(Vector2(200, 195), Vector2(168, 208), 1.0, P.TABARD[1])
	# The sword, point down on the rock at his right side.
	_line(Vector2(268, 292), Vector2(268, 340), 3.0, P.STEEL[2])
	_line(Vector2(269, 294), Vector2(269, 336), 1.0, P.STEEL[4])
	_box(Rect2i(259, 286, 19, 3), P.GOLD[1])
	_box(Rect2i(266, 274, 4, 12), P.LEATHER[2])
	_disc(Vector2(268, 272), 2.5, P.GOLD[2])
	_line(Vector2(250, 248), Vector2(266, 282), 4.0, plate)  # his arm, down to the hilt
	# The helm's crest and eye slit (seen from behind: the crest ridge), the pauldrons' plates.
	_line(Vector2(219, 199), Vector2(219, 230), 1.0, P.DARK_STEEL[1])
	for pauldron: Vector2 in [Vector2(194, 240), Vector2(244, 240)]:
		_line(pauldron + Vector2(-10, -3), pauldron + Vector2(9, -5), 1.0, P.DARK_STEEL[1])
		_line(pauldron + Vector2(-11, 1), pauldron + Vector2(10, -1), 1.0, P.DARK_STEEL[1])
	_offset = Vector2.ZERO
	# Moon rim-light down the right side of the armour and the cape.
	var shift: int = roundi(KNIGHT_SHIFT.x)
	for y: int in range(186, 346):
		for x: int in range(272 + shift, 150 + shift, -1):
			var c: Color = _img.get_pixel(x, y)
			if (c.is_equal_approx(plate) or c.is_equal_approx(P.CAPE[1])) and not _img.get_pixel(x + 1, y).is_equal_approx(c):
				_img.set_pixel(x, y, plate_light if c.is_equal_approx(plate) else P.CAPE[3])
				break


func _vignette() -> void:
	var center: Vector2 = Vector2(W / 2.0, H / 2.0)
	for y: int in H:
		for x: int in W:
			var d: float = (Vector2(x, y) - center).length() / center.length()
			if d > 0.62 and _dither(x, y, (d - 0.62) / 0.38 * 0.7):
				_blend(x, y, NIGHT, 0.6)


# ---------------------------------------------------------------- pixels

func _dither(x: int, y: int, amount: float) -> bool:
	return amount * 16.0 > BAYER[(y % 4) * 4 + x % 4] + 0.5


func _blend(x: int, y: int, color: Color, amount: float) -> void:
	if _inside(x, y):
		_img.set_pixel(x, y, _img.get_pixel(x, y).lerp(color, amount))


func _glow(at: Vector2i, radius: float, color: Color, strength: float) -> void:
	for y: int in range(at.y - ceili(radius), at.y + ceili(radius) + 1):
		for x: int in range(at.x - ceili(radius), at.x + ceili(radius) + 1):
			var d: float = Vector2(x, y).distance_to(Vector2(at))
			if d <= radius and _dither(x, y, (1.0 - d / radius) * strength * 2.0):
				_blend(x, y, color, strength)


func _inside(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < W and y < H


func _box(area: Rect2i, color: Color) -> void:
	area.position += Vector2i(_offset.round())
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			if _inside(x, y):
				_img.set_pixel(x, y, color)


func _disc(center: Vector2, radius: float, color: Color) -> void:
	_ellipse(center, Vector2(radius, radius), color)


func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	center += _offset
	for y: int in range(floori(center.y - radius.y), ceili(center.y + radius.y) + 1):
		for x: int in range(floori(center.x - radius.x), ceili(center.x + radius.x) + 1):
			var d: Vector2 = (Vector2(x, y) + Vector2(0.5, 0.5) - center) / radius
			if d.length_squared() <= 1.0 and _inside(x, y):
				_img.set_pixel(x, y, color)


func _line(a: Vector2, b: Vector2, width: float, color: Color) -> void:
	if width > 1.0:
		var shift: Vector2 = _offset
		_offset = Vector2.ZERO
		_line_wide(a + shift, b + shift, width, color)
		_offset = shift
		return
	a += _offset
	b += _offset
	var steps: int = maxi(ceili(a.distance_to(b)), 1)
	for i: int in steps + 1:
		var at: Vector2 = a.lerp(b, float(i) / steps)
		if _inside(roundi(at.x), roundi(at.y)):
			_img.set_pixel(roundi(at.x), roundi(at.y), color)


func _line_wide(a: Vector2, b: Vector2, width: float, color: Color) -> void:
	var steps: int = maxi(ceili(a.distance_to(b)), 1)
	for i: int in steps + 1:
		_disc(a.lerp(b, float(i) / steps), width / 2.0, color)


func _triangle(a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
	_poly(PackedVector2Array([a, b, c]), color)


func _quad(points: Array, color: Color) -> void:
	_poly(PackedVector2Array(points), color)


func _poly(points: PackedVector2Array, color: Color) -> void:
	for i: int in points.size():
		points[i] += _offset
	var box: Rect2 = Rect2(points[0], Vector2.ZERO)
	for p: Vector2 in points:
		box = box.expand(p)
	for y: int in range(floori(box.position.y), ceili(box.end.y) + 1):
		for x: int in range(floori(box.position.x), ceili(box.end.x) + 1):
			if _inside(x, y) and Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				_img.set_pixel(x, y, color)
