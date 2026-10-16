extends RefCounted
## The fortress (dev-time art generator), drawn in the 3/4 view: a square curtain wall with
## battlements, four round corner towers with slate cones, a gate on the west side where the lane
## arrives, and a tall central keep with lit windows and a banner pole.
## Four looks (healthy, damaged, badly damaged, destroyed) are drawn with the same code: damage lowers
## and breaks the masonry, removes roofs, adds cracks, scorch marks, holes and rubble.
## Frame 96x96 art px; the 48x48 footprint (= the 96x96 world collision box) is FOOT.
## Fire, smoke and the waving banners are separate animated sprites (fx_rows), so they can move.

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")

const SIZE: Vector2i = Vector2i(96, 96)
const FOOT: Rect2 = Rect2(24, 40, 48, 48)
const WALL: float = 6.0
const FX_SIZE: Vector2i = Vector2i(16, 24)

## Per look: curtain wall height, tower height, keep height, roofs left, cracks, scorch marks, rubble.
const LOOKS: Array[Dictionary] = [
	{"wall": 14.0, "tower": 20.0, "keep": 30.0, "roofs": 4, "keep_roof": 2, "cracks": 0, "scorch": 0, "rubble": 0, "lit": 1.0},
	{"wall": 14.0, "tower": 20.0, "keep": 30.0, "roofs": 3, "keep_roof": 2, "cracks": 14, "scorch": 3, "rubble": 4, "lit": 0.7},
	{"wall": 12.0, "tower": 17.0, "keep": 26.0, "roofs": 1, "keep_roof": 1, "cracks": 26, "scorch": 7, "rubble": 9, "lit": 0.3},
	{"wall": 5.0, "tower": 7.0, "keep": 11.0, "roofs": 0, "keep_roof": 0, "cracks": 30, "scorch": 12, "rubble": 18, "lit": 0.0},
]


## The 4 looks, left to right (Fortress.Look order).
func sheet_frames() -> Array[Image]:
	var frames: Array[Image] = []
	for look: int in LOOKS.size():
		frames.append(_fortress(look))
	return frames


func _fortress(look: int) -> Image:
	var cfg: Dictionary = LOOKS[look]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 9100 + look
	var c: Canvas = Canvas.new(SIZE.x, SIZE.y)
	var wall_h: float = cfg["wall"]
	var tower_h: float = cfg["tower"]
	var x0: float = FOOT.position.x
	var x1: float = FOOT.end.x
	var y0: float = FOOT.position.y
	var y1: float = FOOT.end.y
	var roofs: int = cfg["roofs"]

	# Back (north) corner towers, then the north wall facing into the courtyard.
	_tower(c, Vector2(x0, y0), 7.5, tower_h, roofs >= 3, look)
	_tower(c, Vector2(x1, y0), 7.5, tower_h, roofs >= 4, look)
	_wall(c, Rect2(x0 + 4, y0 - WALL * 0.5, x1 - x0 - 8, WALL), wall_h, look, true)
	# The courtyard: packed earth and flagstones.
	c.part()
	c.block(Rect2(x0 + WALL * 0.5, y0 + WALL * 0.5, x1 - x0 - WALL, y1 - y0 - WALL), 0.0, P.DIRT, P.DIRT)
	for i: int in 22:
		var p: Vector2i = Vector2i(rng.randi_range(int(x0) + 5, int(x1) - 7), rng.randi_range(int(y0) + 4, int(y1) - 6))
		c.rect(Rect2i(p, Vector2i(2, 1)), P.DIRT[1])
	# Side walls (only their tops and battlements show in this view).
	_wall(c, Rect2(x0 - WALL * 0.5, y0 + 2, WALL, y1 - y0 - 4), wall_h, look, false, true)
	_wall(c, Rect2(x1 - WALL * 0.5, y0 + 2, WALL, y1 - y0 - 4), wall_h, look, false)
	_courtyard_props(c, look)
	_keep(c, Rect2(37, 50, 22, 15), cfg["keep"], cfg["keep_roof"], cfg["lit"], look)
	# The gate on the west wall: a dark passage with a portcullis, flanked by two small towers.
	_gate(c, Vector2(x0, (y0 + y1) * 0.5), wall_h, look)
	# Front (south) wall and towers.
	_wall(c, Rect2(x0 + 4, y1 - WALL * 0.5, x1 - x0 - 8, WALL), wall_h, look, true)
	_tower(c, Vector2(x0, y1), 7.5, tower_h, roofs >= 1, look)
	_tower(c, Vector2(x1, y1), 7.5, tower_h, roofs >= 2, look)

	_damage(c, cfg, rng)
	c.finish()
	_rubble_piles(c, cfg["rubble"], rng)
	_shadow(c)
	return c.image


# ---------------------------------------------------------------- parts

## A curtain wall standing on `ground` (its footprint), `height` tall: walkway on top, battlements
## on the outer edge, masonry on the visible (south) face.
func _wall(c: Canvas, ground: Rect2, height: float, look: int, horizontal: bool, west: bool = false) -> void:
	c.part()
	var top: Rect2 = Rect2(ground.position - Vector2(0, height), ground.size)
	c.block(top, height, P.STONE.slice(2, 7), P.STONE.slice(1, 6))
	# Walkway planks in the middle of the top.
	if horizontal:
		c.rect(Rect2i(Vector2i(top.position) + Vector2i(1, 2), Vector2i(int(top.size.x) - 2, 2)), P.STONE[2])
	else:
		c.rect(Rect2i(Vector2i(top.position) + Vector2i(2, 1), Vector2i(2, int(top.size.y) - 2)), P.STONE[2])
	_masonry(c, Rect2(top.position.x, top.end.y, top.size.x, height))
	# Battlements: merlons along the outer edge (north/south walls) or the outer side (east/west).
	if look < 3:
		if horizontal:
			for x: int in range(int(top.position.x) + 1, int(top.end.x) - 1, 4):
				_merlon(c, Vector2(x, top.position.y - 1))
		else:
			var mx: float = top.position.x if west else top.end.x - 2
			for y: int in range(int(top.position.y) + 2, int(top.end.y) - 1, 4):
				_merlon(c, Vector2(mx, y))


func _merlon(c: Canvas, at: Vector2) -> void:
	c.block(Rect2(at, Vector2(2, 1)), 2.0, P.STONE.slice(3, 7), P.STONE.slice(1, 5), false)


## Mortar lines on a front face: staggered blocks, moss near the ground.
func _masonry(c: Canvas, face: Rect2) -> void:
	for y: int in range(int(face.position.y), int(face.end.y)):
		var row: int = int(y - face.position.y)
		for x: int in range(int(face.position.x), int(face.end.x)):
			if not c.is_filled(x, y):
				continue
			var stagger: int = 3 if floori(row / 3.0) % 2 == 1 else 0
			if row % 3 == 2 or (x + stagger) % 6 == 0:
				c.px(x, y, c.get_color(x, y).lerp(P.STONE[0], 0.45))
			elif face.end.y - y <= 2 and (x * 5 + y) % 3 == 0:
				c.px(x, y, P.MOSS[1])


## A round corner tower: a cylinder with a ring of merlons and a slate cone (or a broken stump).
## roofed: a slate cone; otherwise an open fighting platform (burnt out from the badly damaged look on).
func _tower(c: Canvas, base: Vector2, radius: float, height: float, roofed: bool, look: int, open_top: bool = false) -> void:
	c.part()
	var top_y: float = base.y - height
	c.cylinder(base.x, top_y, base.y, radius, radius * 0.45, P.STONE, P.STONE.slice(1, 6))
	_masonry_round(c, base, radius, top_y)
	# Arrow slits.
	if height > 12.0:
		for slit_y: float in [top_y + 5.0, top_y + 11.0]:
			c.rect(Rect2i(int(base.x) - 1, int(slit_y), 1, 3), P.OUTLINE)
	if look >= 3:
		_jagged_top(c, base.x, top_y, radius)
		return
	# Merlons around the rim.
	for i: int in 8:
		var a: float = PI + i * PI / 7.0
		var p: Vector2 = Vector2(base.x + cos(a) * (radius - 1.0), top_y + sin(a) * radius * 0.45)
		if i == 0 or i == 7:
			continue
		c.block(Rect2(p - Vector2(1, 2), Vector2(2, 1)), 2.0, P.STONE.slice(3, 7), P.STONE.slice(1, 5), false)
	if roofed:
		_cone(c, Vector2(base.x, top_y - 1.0), radius + 1.0, 13.0)
	elif open_top and look < 2:
		c.part()
		c.ellipse(Vector2(base.x, top_y), Vector2(radius - 1.5, radius * 0.3), P.STONE.slice(1, 4), 1.0)
	else:
		# The roof burned away: charred beams sticking out of a dark shell.
		c.part()
		c.ellipse(Vector2(base.x, top_y), Vector2(radius - 1.5, radius * 0.35), P.SMOKE.slice(0, 3), 1.0)
		c.line(Vector2(base.x - 3, top_y - 1), Vector2(base.x + 1, top_y - 6), P.WOOD[0])
		c.line(Vector2(base.x + 2, top_y), Vector2(base.x + 4, top_y - 4), P.WOOD[1])


func _masonry_round(c: Canvas, base: Vector2, radius: float, top_y: float) -> void:
	for y: int in range(int(top_y) + 1, int(base.y) + 3):
		var row: int = int(y - top_y)
		for x: int in range(int(base.x - radius), int(base.x + radius) + 1):
			if not c.is_filled(x, y):
				continue
			if row % 3 == 2 or (x + (3 if floori(row / 3.0) % 2 == 1 else 0)) % 5 == 0:
				c.px(x, y, c.get_color(x, y).lerp(P.STONE[0], 0.35))


## A conical slate roof seen from the front: lit on the left, dark on the right, dithered bands.
func _cone(c: Canvas, base: Vector2, radius: float, height: float) -> void:
	c.part()
	var apex: Vector2 = base - Vector2(0, height)
	for y: int in range(int(apex.y), int(base.y + radius * 0.4) + 1):
		for x: int in range(int(base.x - radius) - 1, int(base.x + radius) + 2):
			var p: Vector2 = Vector2(x + 0.5, y + 0.5)
			var t: float = (p.y - apex.y) / height  # 0 at the tip
			var half: float = radius * clampf(t, 0.0, 1.0)
			var dx: float = p.x - base.x
			if t < 0.0 or absf(dx) > half:
				continue
			if t > 1.0 and Vector2(dx / radius, (p.y - base.y) / (radius * 0.4)).length() > 1.0:
				continue
			var across: float = dx / maxf(half, 0.5)
			var value: float = Canvas.light_of(Vector3(across, -0.5, 0.8))
			var color: Color = Canvas.shade(P.SLATE, value + 0.08, x, y, true)
			# Shingle rows.
			if int(p.y - apex.y) % 3 == 0 and t > 0.2:
				color = color.lerp(P.SLATE[0], 0.4)
			c.px(x, y, color)
	c.px(int(apex.x), int(apex.y) - 1, P.GOLD[2])
	c.px(int(apex.x), int(apex.y) - 2, P.GOLD[3])


## A ruined top edge: irregular broken masonry.
func _jagged_top(c: Canvas, cx: float, top_y: float, radius: float) -> void:
	for x: int in range(int(cx - radius), int(cx + radius) + 1):
		var cut: int = [0, 2, 1, 3, 1, 0, 2][posmod(x * 3, 7)]
		for k: int in cut:
			c.erase(x, int(top_y - radius * 0.45) + k)


## The keep: a tall stone block with lit arched windows, a door, battlements and a hipped slate roof.
func _keep(c: Canvas, ground: Rect2, height: float, roof: int, lit: float, look: int) -> void:
	c.part()
	var top: Rect2 = Rect2(ground.position - Vector2(0, height), ground.size)
	c.block(top, height, P.STONE_WARM.slice(1, 6), P.STONE_WARM)
	var face: Rect2 = Rect2(top.position.x, top.end.y, top.size.x, height)
	_masonry(c, face)
	# Windows: arched, warm light inside (dark when the keep is burning out).
	var windows: Array[Vector2i] = [Vector2i(-6, 6), Vector2i(0, 6), Vector2i(6, 6), Vector2i(-6, 15), Vector2i(6, 15)]
	for i: int in windows.size():
		var w: Vector2i = Vector2i(int(face.get_center().x), int(face.position.y)) + windows[i]
		if w.y + 4 > face.end.y - 1:
			continue
		var on: bool = float(i) / windows.size() < lit
		c.rect(Rect2i(w.x - 1, w.y, 3, 4), P.OUTLINE)
		if on:
			c.rect(Rect2i(w.x - 1, w.y + 1, 3, 3), P.FIRE[3])
			c.px(w.x, w.y + 1, P.FIRE[5])
			c.px(w.x, w.y + 2, P.FIRE[4])
		c.px(w.x - 1, w.y, c.get_color(w.x - 1, w.y - 1))
		c.px(w.x + 1, w.y, c.get_color(w.x + 1, w.y - 1))
	# Iron-banded oak door.
	var door: Vector2i = Vector2i(int(face.get_center().x) - 2, int(face.end.y) - 6)
	c.rect(Rect2i(door, Vector2i(5, 6)), P.WOOD[1])
	c.rect(Rect2i(door + Vector2i(1, 1), Vector2i(3, 5)), P.WOOD[2])
	c.rect(Rect2i(door + Vector2i(0, 2), Vector2i(5, 1)), P.IRON[1])
	c.px(door.x, door.y, P.OUTLINE)
	c.px(door.x + 4, door.y, P.OUTLINE)
	if look >= 3:
		# Gutted: open top full of darkness and embers.
		c.part()
		c.rect(Rect2i(Vector2i(top.position) + Vector2i(2, 2), Vector2i(top.size) - Vector2i(4, 4)), P.SMOKE[0])
		for i: int in 6:
			c.px(int(top.position.x) + 3 + i * 3, int(top.position.y) + 3 + (i % 3) * 3, P.FIRE[2] if i % 2 == 0 else P.WOOD[0])
		_jagged_edge(c, top)
		return
	for x: int in range(int(top.position.x), int(top.end.x) - 1, 3):
		_merlon(c, Vector2(x, top.position.y - 1))
	if roof > 0:
		_hip_roof(c, top.grow(-2.0), 12.0, roof)


func _jagged_edge(c: Canvas, top: Rect2) -> void:
	for x: int in range(int(top.position.x), int(top.end.x)):
		var cut: int = [1, 3, 0, 2, 4, 1, 2][posmod(x * 5, 7)]
		for k: int in cut:
			c.erase(x, int(top.position.y) + k)


## A hipped roof over `base`: four slate planes meeting at a ridge; holes when damaged.
func _hip_roof(c: Canvas, base: Rect2, height: float, state: int) -> void:
	c.part()
	var ridge_y: float = base.position.y + base.size.y * 0.5 - height
	var inset: float = base.size.y * 0.5
	var ridge_a: Vector2 = Vector2(base.position.x + inset, ridge_y)
	var ridge_b: Vector2 = Vector2(base.end.x - inset, ridge_y)
	var bottom_left: Vector2 = Vector2(base.position.x, base.end.y)
	var bottom_right: Vector2 = base.end
	var top_left: Vector2 = base.position
	var top_right: Vector2 = Vector2(base.end.x, base.position.y)
	c.polygon(PackedVector2Array([top_left, top_right, ridge_b, ridge_a]), P.SLATE, Vector3(0, -1, 0.6), true)
	c.polygon(PackedVector2Array([ridge_a, ridge_b, bottom_right, bottom_left]), P.SLATE, Vector3(-0.2, 0.3, 1), true)
	c.polygon(PackedVector2Array([top_left, ridge_a, bottom_left]), P.SLATE, Vector3(-1, 0, 0.5), true)
	c.polygon(PackedVector2Array([top_right, bottom_right, ridge_b]), P.SLATE, Vector3(1, 0, 0.5), true)
	c.line(ridge_a, ridge_b, P.SLATE[4])
	c.line(ridge_a, bottom_left, P.SLATE[3])
	c.line(ridge_b, bottom_right, P.SLATE[1])
	# Shingle rows on the front plane.
	for y: int in range(int(ridge_y) + 3, int(bottom_left.y), 3):
		for x: int in range(int(bottom_left.x), int(bottom_right.x)):
			if c.is_filled(x, y) and (x + y) % 2 == 0:
				c.px(x, y, c.get_color(x, y).lerp(P.SLATE[0], 0.35))
	if state < 2:
		# A burnt hole showing the rafters.
		var hole: Vector2 = Vector2(base.get_center().x + 3, base.get_center().y - 2)
		for y: int in range(-2, 3):
			for x: int in range(-3, 4):
				if absf(x) + absf(y) * 1.4 <= 3.5:
					c.px(int(hole.x) + x, int(hole.y) + y, P.SMOKE[0] if (x + y) % 3 != 0 else P.WOOD[1])


## The west gate: a gap in the wall with the lane running in, a raised portcullis and two flanking
## round towers. The north flank is drawn before the passage, the south flank in front of it.
func _gate(c: Canvas, center: Vector2, wall_h: float, look: int) -> void:
	var gap: float = 6.0
	_tower(c, center + Vector2(0, -gap - 3), 5.0, wall_h + 4.0, false, look, true)
	c.part()
	# The passage seen through the gap: dark archway with the portcullis teeth showing.
	var arch: Rect2i = Rect2i(int(center.x) - 3, int(center.y - gap - wall_h * 0.5), 6, int(wall_h * 0.5 + gap * 2))
	c.rect(arch, P.OUTLINE)
	c.rect(Rect2i(arch.position + Vector2i(1, 1), arch.size - Vector2i(2, 2)), P.SMOKE[0])
	if look < 3:
		for x: int in range(arch.position.x + 1, arch.end.x - 1, 2):
			c.rect(Rect2i(x, arch.position.y + 1, 1, 4), P.IRON[3])
			c.px(x, arch.position.y + 5, P.IRON[4])
	c.rect(Rect2i(arch.position.x - 1, arch.end.y - 2, arch.size.x + 2, 2), P.DIRT[2])
	_tower(c, center + Vector2(0, gap + 4), 5.0, wall_h + 4.0, false, look, true)


## Barrels, crates and a well in the courtyard corners (mostly hidden by the keep).
func _courtyard_props(c: Canvas, look: int) -> void:
	if look >= 3:
		return
	c.part()
	c.block(Rect2(32, 66, 4, 2), 3.0, P.WOOD.slice(2, 5), P.WOOD.slice(1, 4), false)
	c.part()
	c.block(Rect2(61, 64, 3, 2), 3.0, P.WOOD.slice(2, 5), P.WOOD.slice(1, 4), false)
	c.part()
	c.cylinder(64.5, 68, 71, 2.0, 1.0, P.WOOD, P.WOOD.slice(1, 4), false)


# ---------------------------------------------------------------- damage

func _damage(c: Canvas, cfg: Dictionary, rng: RandomNumberGenerator) -> void:
	# Scorch marks: soot over the stone.
	for i: int in int(cfg["scorch"]):
		var p: Vector2 = Vector2(rng.randf_range(20, 76), rng.randf_range(16, 90))
		c.tint_circle(p, rng.randf_range(2.5, 5.5), P.SMOKE[0], rng.randf_range(0.35, 0.6))
	# Cracks: short jagged dark lines on solid masonry.
	for i: int in int(cfg["cracks"]):
		var p: Vector2i = Vector2i(rng.randi_range(18, 78), rng.randi_range(12, 92))
		if not c.is_filled(p.x, p.y):
			continue
		for step: int in rng.randi_range(3, 6):
			if c.is_filled(p.x, p.y):
				c.px(p.x, p.y, P.STONE[0])
			p += Vector2i(rng.randi_range(-1, 1), 1)
	# Missing merlons and chunks bitten out of the top edges.
	for i: int in floori(int(cfg["cracks"]) / 2.0):
		var p: Vector2i = Vector2i(rng.randi_range(20, 76), rng.randi_range(8, 80))
		for k: int in 3:
			if c.is_filled(p.x + k, p.y) and not c.is_filled(p.x + k, p.y - 1):
				c.erase(p.x + k, p.y)


## Fallen stones around the base (after the outline, so each pile gets its own).
func _rubble_piles(c: Canvas, count: int, rng: RandomNumberGenerator) -> void:
	var rubble: Canvas = Canvas.new(SIZE.x, SIZE.y)
	for i: int in count:
		var side: int = i % 3
		var p: Vector2 = Vector2(rng.randf_range(20, 76), 90.0 + rng.randf_range(-1, 2))
		if side == 1:
			p = Vector2(rng.randf_range(15, 20), rng.randf_range(45, 88))
		elif side == 2:
			p = Vector2(rng.randf_range(76, 81), rng.randf_range(45, 88))
		rubble.part()
		rubble.ellipse(p, Vector2(rng.randf_range(1.2, 2.4), rng.randf_range(1.0, 1.6)), P.STONE.slice(1, 6))
	rubble.finish()
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var col: Color = rubble.image.get_pixel(x, y)
			if col.a > 0.0 and not c.is_filled(x, y):
				c.image.set_pixel(x, y, col)


## A soft drop shadow toward the lower right, only on empty pixels.
func _shadow(c: Canvas) -> void:
	var src: Image = c.image.duplicate() as Image
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			if src.get_pixel(x, y).a > 0.5 or y < 40:
				continue
			var from: Vector2i = Vector2i(x - 4, y - 3)
			if from.x >= 0 and from.y >= 0 and src.get_pixelv(from).a > 0.5:
				c.image.set_pixel(x, y, Canvas.SHADOW)


# ---------------------------------------------------------------- animated pieces

## A soft round smoke puff (8x8) for smoke particles: shaded, dithered rim, no outline.
func smoke_puff() -> Image:
	var c: Canvas = Canvas.new(8, 8)
	c.part(true)
	c.ellipse(Vector2(4, 4), Vector2(3.6, 3.4), P.SMOKE.slice(1, 5), 0.0, 0.05)
	for y: int in 8:
		for x: int in 8:
			if Vector2(x + 0.5, y + 0.5).distance_to(Vector2(4, 4)) > 2.6 and (x + y) % 2 == 0:
				c.erase(x, y)
	return c.image


## Rows (16x24 frames): banner (4), banner_torn (4), fire (6), brazier (4).
func fx_rows() -> Array[Array]:
	var banner: Array[Image] = []
	var torn: Array[Image] = []
	for i: int in 4:
		banner.append(_banner(i, false))
		torn.append(_banner(i, true))
	var fire: Array[Image] = []
	for i: int in 6:
		fire.append(_fire(i))
	var brazier: Array[Image] = []
	for i: int in 4:
		brazier.append(_brazier(i))
	return [banner, torn, fire, brazier]


## A red banner with the gold tower emblem on a pole, waving (the pole stands at x 3, foot at y 23).
func _banner(frame: int, torn: bool) -> Image:
	var c: Canvas = Canvas.new(FX_SIZE.x, FX_SIZE.y)
	c.part()
	c.rect(Rect2i(3, 1, 1, 23), P.WOOD[2])
	c.px(3, 0, P.GOLD[3])
	c.part()
	var pts: PackedVector2Array = PackedVector2Array()
	var length: float = 9.0 if not torn else 7.0
	for i: int in 7:
		var t: float = i / 6.0
		pts.append(Vector2(4 + t * length, 2 + sin(t * 3.0 + frame * PI / 2.0) * 1.2 * t))
	for i: int in range(6, -1, -1):
		var t: float = i / 6.0
		var tail: float = 9.0 - (2.0 if torn and i % 2 == 1 else 0.0)
		pts.append(Vector2(4 + t * length, 2 + tail + sin(t * 3.0 + frame * PI / 2.0) * 1.2 * t))
	c.polygon(pts, P.BANNER, Vector3(0.35, 0.3, 1))
	# Shade the folds of the wave.
	for x: int in range(5, 4 + int(length)):
		var fold: float = cos((x - 4) / length * 3.0 + frame * PI / 2.0)
		if fold < -0.3:
			for y: int in FX_SIZE.y:
				if c.is_filled(x, y) and c.get_color(x, y) != P.WOOD[2]:
					c.px(x, y, c.get_color(x, y).lerp(P.BANNER[0], 0.4))
	var e: Vector2i = Vector2i(7, 5 + int(sin(0.5 + frame * PI / 2.0) * 0.6))
	c.rect(Rect2i(e.x, e.y, 2, 4), P.GOLD[3])
	c.rect(Rect2i(e.x - 1, e.y, 4, 1), P.GOLD[2])
	return c.finish()


## A flame licking upward (soft, unoutlined), flickering over 6 frames; base at y 22.
func _fire(frame: int) -> Image:
	var img: Image = Image.create_empty(FX_SIZE.x, FX_SIZE.y, false, Image.FORMAT_RGBA8)
	var height: float = [13.0, 15.0, 12.0, 16.0, 14.0, 13.5][frame]
	var sway: float = [0.0, 0.8, -0.6, 0.4, -0.9, 0.5][frame]
	for y: int in FX_SIZE.y:
		for x: int in FX_SIZE.x:
			var t: float = (22.5 - (y + 0.5)) / height  # 0 at the base, 1 at the tip
			if t < 0.0 or t > 1.0:
				continue
			var cx: float = 8.0 + sway * t * t * 3.0 + sin(t * 9.0 + frame) * 0.7 * t
			var half: float = 4.6 * sqrt(maxf(1.0 - t, 0.0)) * (1.0 - t * 0.3)
			var dx: float = absf(x + 0.5 - cx)
			if dx > half:
				continue
			var heat: float = (1.0 - dx / maxf(half, 0.1)) * (1.0 - t * 0.85)
			if t > 0.7 and Canvas.BAYER_4[(y % 4) * 4 + (x % 4)] / 16.0 < (t - 0.7) * 2.5:
				continue
			img.set_pixel(x, y, Canvas.shade(P.FIRE, heat * 1.1 + 0.1, x, y, true))
	return img


## A stone brazier bowl with fire (base at y 23).
func _brazier(frame: int) -> Image:
	var c: Canvas = Canvas.new(FX_SIZE.x, FX_SIZE.y)
	c.part()
	c.capsule(Vector2(8, 19), Vector2(8, 22), 1.2, P.IRON)
	c.part()
	c.ellipse(Vector2(8, 17.5), Vector2(4.2, 2.2), P.IRON, 0.0, 0.05)
	c.finish()
	var flame: Image = _fire(frame)
	flame.resize(8, 12, Image.INTERPOLATE_NEAREST)
	c.image.blend_rect(flame, Rect2i(Vector2i.ZERO, flame.get_size()), Vector2i(4, 7))
	return c.image
