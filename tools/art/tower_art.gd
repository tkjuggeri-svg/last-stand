extends RefCounted
## The three towers and their shots (dev-time art generator), 3/4 view, 32x48 art px frames with the
## base resting on y = BASE. Every tower has idle, fire, build (rising inside scaffolding) and sell
## (dismantled into rubble) animations.
##   Archer: stone keep with a timber fighting platform, a hooded archer with a longbow, a pennant.
##   Cannon: squat round drum tower with an iron cannon on a wooden carriage.
##   Frost:  a dark rune-carved obelisk crowned by a floating, turning ice crystal.

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")

const SIZE: Vector2i = Vector2i(32, 48)
const BASE: float = 45.0
const KINDS: Array[String] = ["archer", "cannon", "frost"]
const FROST_STONE: Array[Color] = [Color("14162a"), Color("1f243b"), Color("2c3350"), Color("3d4769"), Color("546089"), Color("7181a8")]
const PROJECTILE_SIZE: Vector2i = Vector2i(12, 12)
const EXPLOSION_SIZE: Vector2i = Vector2i(56, 56)
const FROST_FX_SIZE: Vector2i = Vector2i(20, 20)

const IDLE_FRAMES: int = 4
const FIRE_FRAMES: Dictionary = {"archer": 4, "cannon": 5, "frost": 4}
const BUILD_FRAMES: int = 6
const SELL_FRAMES: int = 6


## Rows in the order of sheet_layouts.TOWERS: per kind idle, fire, build, sell.
func sheet_rows() -> Array[Array]:
	var rows: Array[Array] = []
	for kind: String in KINDS:
		var idle: Array[Image] = []
		for i: int in IDLE_FRAMES:
			idle.append(tower(kind, "idle", i))
		rows.append(idle)
		var fire: Array[Image] = []
		for i: int in int(FIRE_FRAMES[kind]):
			fire.append(tower(kind, "fire", i))
		rows.append(fire)
		rows.append(_build_frames(kind))
		rows.append(_sell_frames(kind))
	return rows


func tower(kind: String, state: String, frame: int) -> Image:
	var c: Canvas = Canvas.new(SIZE.x, SIZE.y)
	match kind:
		"archer":
			_archer(c, state, frame)
		"cannon":
			_cannon(c, state, frame)
		_:
			_frost(c, state, frame)
	c.finish()
	c.ground_shadow(Vector2(17.5, BASE), Vector2(13, 3.2))
	return c.image


# ---------------------------------------------------------------- archer

func _archer(c: Canvas, state: String, frame: int) -> void:
	var firing: bool = state == "fire"
	# Stone keep.
	c.part()
	c.block(Rect2(8, 26, 16, 6), BASE - 32.0, P.STONE.slice(2, 7), P.STONE.slice(1, 6))
	_masonry(c, Rect2(8, 32, 16, BASE - 32.0))
	c.rect(Rect2i(15, 36, 2, 4), P.OUTLINE)  # arrow slit
	c.rect(Rect2i(15, 41, 2, 4), P.WOOD[1])  # door
	c.px(15, 41, P.OUTLINE)
	# Back railing and the pennant pole (behind the archer).
	c.part()
	for x: int in [6, 11, 21, 26]:
		c.rect(Rect2i(x, 16, 1, 6), P.WOOD[2])
	c.line(Vector2(6, 16), Vector2(26, 16), P.WOOD[3])
	c.part()
	c.rect(Rect2i(26, 4, 1, 18), P.WOOD[2])
	c.px(26, 3, P.GOLD[3])
	var wave: int = [0, 1, 1, 0][frame % 4] if not firing else 1
	c.polygon(PackedVector2Array([Vector2(27, 4), Vector2(31, 5.5 + wave), Vector2(27, 8)]), P.BANNER, Vector3(0.3, 0.3, 1))
	# Timber fighting platform overhanging the keep, with braces.
	c.part()
	c.block(Rect2(5, 21, 22, 6), 3.0, P.WOOD.slice(2, 5), P.WOOD.slice(1, 4), false)
	for x: int in range(7, 27, 3):
		c.line(Vector2(x, 21), Vector2(x, 26), P.WOOD[2])
		c.px(x, 28, P.WOOD[0])
	c.line(Vector2(6, 30), Vector2(9, 33), P.WOOD[1])
	c.line(Vector2(26, 30), Vector2(23, 33), P.WOOD[1])
	_archer_figure(c, state, frame)
	# Front railing (in front of the archer's legs).
	c.part()
	for x: int in [5, 10, 22, 27]:
		c.rect(Rect2i(x, 24, 1, 3), P.WOOD[3])
	c.line(Vector2(5, 24), Vector2(27, 24), P.WOOD[4])
	c.line(Vector2(5, 25), Vector2(27, 25), P.WOOD[2])


## The hooded archer. Idle: glances left and right. Fire: nock, full draw, release, recover.
func _archer_figure(c: Canvas, state: String, frame: int) -> void:
	var firing: bool = state == "fire"
	var look: int = [0, -1, 0, 1][frame] if not firing else 1
	c.part()
	c.ellipse(Vector2(16, 20), Vector2(3.6, 3.8), P.HOOD, 0.0, 0.1)
	c.rect(Rect2i(13, 21, 6, 1), P.LEATHER[2])
	c.px(16, 21, P.GOLD[3])
	c.part()
	c.ellipse(Vector2(16, 15.2), Vector2(2.9, 2.8), P.HOOD, 0.0, 0.15)
	# Face in the hood's shadow.
	c.rect(Rect2i(15 + look, 16, 2, 2), P.HOOD[0])
	c.px(15 + look, 16, P.SKIN[1])
	c.px(16 + look, 16, P.SKIN[2])
	# Quiver over the left shoulder.
	c.line(Vector2(13, 17), Vector2(12, 14), P.LEATHER[2])
	c.px(12, 13, P.BANNER[3])
	# Bow arm, bow and string. draw: 0 rest, 1 nocked, 2 full draw, 3 released.
	var draw: int = 0
	if firing:
		draw = [1, 2, 3, 0][frame]
	var pull: float = [0.0, 1.0, 2.5, 0.0][draw]
	var bow_x: float = 22.5
	var tip_top: Vector2 = Vector2(bow_x - 1.0 - pull * 0.4, 12)
	var tip_bottom: Vector2 = Vector2(bow_x - 1.0 - pull * 0.4, 25)
	c.part()
	c.capsule(Vector2(18, 18.5), Vector2(bow_x - 0.5, 18.5), 0.9, P.HOOD)
	c.line(tip_top, Vector2(bow_x, 15), P.WOOD[4])
	c.line(Vector2(bow_x, 15), Vector2(bow_x + 0.5, 18.5), P.WOOD[3])
	c.line(Vector2(bow_x + 0.5, 18.5), Vector2(bow_x, 22), P.WOOD[3])
	c.line(Vector2(bow_x, 22), tip_bottom, P.WOOD[2])
	var hand: Vector2 = Vector2(bow_x - 1.0 - pull * 2.0, 18.5)
	if draw == 3:
		c.line(tip_top, tip_bottom, P.BONE[2])
		c.px(int(bow_x) + 2, 17, P.BONE[3])  # the string still humming
		c.px(int(bow_x) + 3, 19, P.BONE[2])
	else:
		c.line(tip_top, hand, P.BONE[2])
		c.line(hand, tip_bottom, P.BONE[2])
	if draw in [1, 2]:
		c.line(hand, Vector2(bow_x + 2.5, 18.5), P.WOOD[4])
		c.px(int(bow_x) + 3, 18, P.STEEL[4])
		c.px(int(hand.x), 17, P.BANNER[3])


# ---------------------------------------------------------------- cannon

func _cannon(c: Canvas, state: String, frame: int) -> void:
	var firing: bool = state == "fire"
	var recoil: float = [1.0, 2.0, 2.0, 1.0, 0.0][frame] if firing else 0.0
	# Drum tower with a ring of merlons; the back ones first.
	c.part()
	c.cylinder(16, 30, BASE - 1.5, 12, 4.5, P.STONE, P.STONE.slice(1, 6))
	_masonry_round(c, Vector2(16, BASE), 12.0, 30.0)
	for y: int in [37]:
		for x: int in range(5, 28):
			if c.is_filled(x, y):
				c.px(x, y + 1 if absi(x - 16) > 8 else y, P.IRON[2])
	c.rect(Rect2i(15, 38, 2, 3), P.OUTLINE)
	c.part()
	c.ellipse(Vector2(16, 30), Vector2(9.5, 3.4), P.STONE.slice(0, 3), 1.0)
	_merlon_ring(c, Vector2(16, 30), 11.0, 4.3, false)
	# Ammunition: a stack of balls and a powder keg.
	for p: Vector2 in [Vector2(8, 31), Vector2(10.5, 31), Vector2(9.2, 29.7)]:
		c.part()
		c.ellipse(p, Vector2(1.4, 1.3), P.IRON, 0.0, 0.1)
	c.part()
	c.cylinder(24.5, 27.5, 30.5, 1.9, 0.8, P.WOOD, P.WOOD.slice(1, 4), false)
	c.px(24, 28, P.IRON[3])
	# Carriage and barrel aimed down-right.
	var dir: Vector2 = Vector2(10, 5).normalized()
	var back: Vector2 = -dir * recoil
	c.part()
	c.block(Rect2(Vector2(11, 26) + back, Vector2(8, 4)), 2.0, P.WOOD.slice(2, 5), P.WOOD.slice(1, 4), false)
	c.part()
	c.ellipse(Vector2(12, 31) + back, Vector2(1.6, 1.6), P.WOOD, 0.0, 0.0)
	c.ellipse(Vector2(18, 31) + back, Vector2(1.6, 1.6), P.WOOD, 0.0, 0.0)
	var breech: Vector2 = Vector2(12.5, 25.5) + back
	var muzzle: Vector2 = Vector2(22.5, 30.5) + back
	c.part()
	c.ellipse(breech - dir * 1.8, Vector2(1.3, 1.3), P.IRON, 0.0, 0.1)
	c.capsule(breech, muzzle, 2.4, P.IRON, 0.05)
	var across: Vector2 = Vector2(-dir.y, dir.x)
	for t: float in [0.25, 0.9]:
		var p: Vector2 = breech.lerp(muzzle, t)
		c.line(p - across * 2.2, p + across * 2.2, P.GOLD[1])
	c.part()
	c.ellipse(muzzle + dir * 1.2, Vector2(1.5, 1.5), [P.OUTLINE, P.IRON[0]], 0.0)
	# Effects: a smouldering touch-hole when idle, flash, blast and smoke when firing.
	if not firing:
		c.px(int(breech.x), int(breech.y) - 2, P.FIRE[3] if frame % 2 == 0 else P.FIRE[2])
		for k: int in 2:
			var wisp: Vector2 = Vector2(breech.x + sin(frame + k * 2.0), breech.y - 4.0 - ((frame + k * 2) % 4) * 1.6)
			c.part(true)
			c.px(int(wisp.x), int(wisp.y), P.SMOKE[3] if k == 0 else P.SMOKE[2])
		return
	match frame:
		0:
			c.part(true)
			c.ellipse(Vector2(breech.x, breech.y - 2), Vector2(1.5, 1.5), P.FIRE.slice(3, 6), 0.0, 0.2)
		1:
			c.part(true)
			c.ellipse(muzzle + dir * 4.0, Vector2(4.5, 3.8), P.FIRE.slice(2, 6), 0.0, 0.3)
			c.ellipse(muzzle + dir * 3.0, Vector2(2.0, 1.8), P.FIRE.slice(4, 6), 0.0, 0.3)
		2:
			c.part(true)
			c.ellipse(muzzle + dir * 5.0 + Vector2(0, -1), Vector2(4.8, 4.0), P.SMOKE.slice(1, 5), 0.0, 0.1)
			c.ellipse(muzzle + dir * 3.0, Vector2(1.6, 1.4), P.FIRE.slice(3, 5), 0.0, 0.2)
		3:
			c.part(true)
			c.ellipse(muzzle + dir * 5.5 + Vector2(0, -3), Vector2(4.2, 3.5), P.SMOKE.slice(1, 5), 0.0, 0.0)
			_dither_region(c, Rect2i(Vector2i(muzzle) + Vector2i(0, -9), Vector2i(12, 10)), 0.35)
		4:
			c.part(true)
			c.ellipse(muzzle + dir * 5.5 + Vector2(1, -6), Vector2(3.0, 2.4), P.SMOKE.slice(1, 4), 0.0, 0.0)
			_dither_region(c, Rect2i(Vector2i(muzzle) + Vector2i(0, -10), Vector2i(12, 8)), 0.6)


# ---------------------------------------------------------------- frost

func _frost(c: Canvas, state: String, frame: int) -> void:
	var firing: bool = state == "fire"
	var phase: float = TAU * frame / (IDLE_FRAMES if not firing else 4)
	var bob: float = roundf(sin(phase)) if not firing else -1.0
	var pulse: float = 0.5 + 0.5 * sin(phase)
	if firing:
		pulse = [1.0, 1.0, 0.8, 0.5][frame]
	# Plinth.
	c.part()
	c.block(Rect2(7, 38, 18, 4), BASE - 42.0, FROST_STONE.slice(1, 6), FROST_STONE.slice(0, 5))
	# Obelisk: a lit left face and a shadowed right face, tapering up.
	c.part()
	c.polygon(PackedVector2Array([Vector2(10, 40.5), Vector2(16, 41.5), Vector2(16, 19), Vector2(12.5, 20)]), FROST_STONE, Vector3(-0.8, -0.2, 0.7))
	c.part()
	c.polygon(PackedVector2Array([Vector2(16, 41.5), Vector2(22, 40.5), Vector2(19.5, 20), Vector2(16, 19)]), FROST_STONE, Vector3(0.9, 0.1, 0.5))
	c.line(Vector2(16, 19), Vector2(16, 41), FROST_STONE[4])
	# Runes glowing along both faces, brighter as the tower charges.
	var rune: Color = P.ICE[3].lerp(P.ICE[5], pulse)
	for y: int in range(23, 39, 4):
		c.px(13, y, rune)
		c.px(13, y + 1, P.ICE[2])
		c.px(18, y + 2, P.ICE[2].lerp(rune, 0.6))
	# Cradle prongs.
	c.part()
	c.block(Rect2(12, 17.5, 8, 2), 1.0, FROST_STONE.slice(2, 6), FROST_STONE.slice(1, 5), false)
	c.part()
	c.capsule(Vector2(12.5, 18), Vector2(10.5, 13.5), 0.9, FROST_STONE)
	c.capsule(Vector2(19.5, 18), Vector2(21.5, 13.5), 0.9, FROST_STONE)
	# The crystal: a turning double pyramid (its front ridge moves), floating above the cradle.
	var center: Vector2 = Vector2(16, 9.5 + bob)
	var ridge: float = 16.0 + 1.6 * sin(phase * (1.0 if not firing else 0.5))
	var top: Vector2 = center + Vector2(0, -6)
	var bottom: Vector2 = center + Vector2(0, 5.5)
	var left: Vector2 = center + Vector2(-3.4, 0)
	var right: Vector2 = center + Vector2(3.4, 0)
	var front: Vector2 = Vector2(ridge, center.y + 0.5)
	var ramp: Array = P.ICE if not (firing and frame < 2) else P.ARCANE_ICE
	c.part()
	c.polygon(PackedVector2Array([top, left, front]), ramp, Vector3(-0.8, -0.6, 0.6))
	c.polygon(PackedVector2Array([top, front, right]), ramp, Vector3(0.5, -0.6, 0.6))
	c.polygon(PackedVector2Array([left, bottom, front]), ramp, Vector3(-0.6, 0.6, 0.6))
	c.polygon(PackedVector2Array([front, bottom, right]), ramp, Vector3(0.7, 0.7, 0.4))
	c.line(top, front, P.ICE[5])
	c.px(int(ridge) - 1, int(center.y) - 2, Color("ffffff"))
	# Cold glow and orbiting motes (soft: no outline).
	c.part(true)
	var reach: float = 7.0 if not firing else [7.5, 9.5, 11.5, 12.5][frame]
	for k: int in 10:
		var a: float = phase + k * TAU / 10.0
		var p: Vector2 = center + Vector2(cos(a) * reach, sin(a) * reach * 0.55)
		if firing or k % 3 == frame % 3:
			c.px(int(p.x), int(p.y), P.ICE[5] if k % 2 == 0 else P.ICE[4])
	if firing and frame < 3:
		for k: int in 8:
			var a2: float = k * TAU / 8.0 + 0.2
			var p2: Vector2 = center + Vector2.from_angle(a2) * (reach - 2.5)
			c.px(int(p2.x), int(p2.y), P.ARCANE_ICE[3])


# ---------------------------------------------------------------- build / sell

## The tower rises inside wooden scaffolding, then the scaffolding comes down with a flash.
func _build_frames(kind: String) -> Array[Image]:
	var full: Image = tower(kind, "idle", 0)
	var frames: Array[Image] = []
	var heights: Array[float] = [0.12, 0.35, 0.6, 0.85, 1.0, 1.0]
	for i: int in BUILD_FRAMES:
		var img: Image = _clip(full, heights[i], i)
		if i < BUILD_FRAMES - 1:
			_scaffold(img, heights[i], kind)
		else:
			_rim_light(img)
		_base_dust(img, i, BUILD_FRAMES)
		frames.append(img)
	return frames


## Taken down level by level inside scaffolding until a heap of rubble remains, which then fades.
func _sell_frames(kind: String) -> Array[Image]:
	var full: Image = tower(kind, "idle", 0)
	var frames: Array[Image] = []
	var heights: Array[float] = [1.0, 0.7, 0.42, 0.18, 0.0, 0.0]
	for i: int in SELL_FRAMES:
		var img: Image = _clip(full, heights[i], i + 7)
		if i < 3:
			_scaffold(img, heights[i], kind)
		if i >= 2:
			_rubble(img, kind, i >= 4, i == 5)
		_base_dust(img, i, SELL_FRAMES)
		frames.append(img)
	return frames


## Keeps the lowest `fraction` of the tower's solid art, with a ragged unfinished top edge.
func _clip(full: Image, fraction: float, seed_value: int) -> Image:
	var img: Image = full.duplicate() as Image
	if fraction >= 1.0:
		return img
	var used: Rect2i = full.get_used_rect()
	var cut: float = BASE - (BASE - used.position.y) * fraction
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var col: Color = img.get_pixel(x, y)
			if col.a <= 0.5:
				continue  # keep the ground shadow
			var ragged: float = cut + float((x * 7 + seed_value * 3) % 3)
			if y < ragged:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			elif y < ragged + 1.0 and col != P.OUTLINE:
				img.set_pixel(x, y, col.lerp(P.OUTLINE, 0.5))
	return img


## Wooden poles and planks around the part already built.
func _scaffold(img: Image, fraction: float, kind: String) -> void:
	var top: float = maxf(BASE - (BASE - 8.0) * fraction - 2.0, 6.0)
	var poles: Array[int] = [5, 27]
	if kind == "frost":
		poles = [7, 25]
	for x: int in poles:
		for y: int in range(int(top), int(BASE)):
			img.set_pixel(x, y, P.WOOD[3] if y % 5 != 0 else P.WOOD[1])
			img.set_pixel(x + 1, y, P.WOOD[1])
	for y: int in range(int(BASE) - 3, int(top), -6):
		for x: int in range(poles[0], poles[1] + 2):
			img.set_pixel(x, y, P.WOOD[4] if x % 4 != 0 else P.WOOD[2])
			img.set_pixel(x, y + 1, P.WOOD[1])
	# A cross brace on the lowest bay.
	for k: int in 6:
		var p: Vector2i = Vector2i(poles[0] + 1 + k * 3, int(BASE) - 3 - k)
		if p.y > top and p.x < SIZE.x:
			img.set_pixel(p.x, p.y, P.WOOD[2])


## A one-frame bright rim when the tower is finished (the scaffolding just came down).
func _rim_light(img: Image) -> void:
	var src: Image = img.duplicate() as Image
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			if src.get_pixel(x, y) != P.OUTLINE:
				continue
			if y > 0 and src.get_pixel(x, y - 1).a == 0.0 or x > 0 and src.get_pixel(x - 1, y).a == 0.0:
				img.set_pixel(x, y, P.GOLD[4])


## Fallen blocks and splinters in the tower's colours. fade dithers it away.
func _rubble(img: Image, kind: String, settled: bool, fade: bool) -> void:
	var c: Canvas = Canvas.new(SIZE.x, SIZE.y)
	var ramp: Array = P.STONE.slice(1, 6) if kind != "frost" else FROST_STONE.slice(1, 6)
	var stones: Array[Vector3] = [Vector3(10, 43, 2.6), Vector3(15, 44, 3.2), Vector3(21, 43.5, 2.8), Vector3(12.5, 41, 2.2),
		Vector3(18.5, 41, 2.4), Vector3(7, 44, 1.6), Vector3(25, 44, 1.8), Vector3(16, 39, 1.8)]
	for i: int in stones.size():
		if not settled and i > 4:
			continue
		var s: Vector3 = stones[i]
		c.part()
		c.ellipse(Vector2(s.x, s.y), Vector2(s.z, s.z * 0.7), ramp)
	if kind == "archer":
		c.part()
		c.line(Vector2(8, 40), Vector2(14, 38), P.WOOD[3])
		c.line(Vector2(18, 39), Vector2(24, 41), P.WOOD[2])
	elif kind == "frost":
		c.part(true)
		c.px(15, 38, P.ICE[4])
		c.px(19, 40, P.ICE[3])
	c.finish()
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var col: Color = c.image.get_pixel(x, y)
			if col.a == 0.0:
				continue
			if fade and Canvas.BAYER_4[(y % 4) * 4 + (x % 4)] < 9:
				continue
			img.set_pixel(x, y, col)


## Dust billowing at the foot of the tower while it's being worked on.
func _base_dust(img: Image, frame: int, count: int) -> void:
	var ramp: Array[Color] = [Color("554b41"), Color("736657"), Color("94856f")]
	var strength: float = sin(PI * (frame + 0.5) / count)
	for k: int in 7:
		var p: Vector2 = Vector2(5 + k * 3.6 + (frame % 2) * 1.5, BASE - 1.0 - (k % 3) * 1.4 - frame * 0.4)
		var r: float = 1.2 + strength * 1.6
		for y: int in range(int(p.y - r), int(p.y + r) + 1):
			for x: int in range(int(p.x - r), int(p.x + r) + 1):
				if x < 0 or y < 0 or x >= SIZE.x or y >= SIZE.y:
					continue
				var d: float = Vector2(x + 0.5, y + 0.5).distance_to(p) / r
				if d > 1.0 or Canvas.BAYER_4[(y % 4) * 4 + (x % 4)] / 16.0 > strength * 0.9:
					continue
				if img.get_pixel(x, y).a < 0.5:
					img.set_pixel(x, y, ramp[2] if d < 0.5 else ramp[1])


# ---------------------------------------------------------------- shared masonry

func _masonry(c: Canvas, face: Rect2) -> void:
	for y: int in range(int(face.position.y), int(face.end.y)):
		var row: int = int(y - face.position.y)
		for x: int in range(int(face.position.x), int(face.end.x)):
			if not c.is_filled(x, y):
				continue
			var stagger: int = 2 if floori(row / 3.0) % 2 == 1 else 0
			if row % 3 == 2 or (x + stagger) % 4 == 0:
				c.px(x, y, c.get_color(x, y).lerp(P.STONE[0], 0.4))
			elif face.end.y - y <= 2 and (x * 5 + y) % 3 == 0:
				c.px(x, y, P.MOSS[1])


func _masonry_round(c: Canvas, base: Vector2, radius: float, top_y: float) -> void:
	for y: int in range(int(top_y) + 2, int(base.y) + 1):
		var row: int = int(y - top_y)
		for x: int in range(int(base.x - radius), int(base.x + radius) + 1):
			if not c.is_filled(x, y):
				continue
			if row % 3 == 2 or (x + (2 if floori(row / 3.0) % 2 == 1 else 0)) % 4 == 0:
				c.px(x, y, c.get_color(x, y).lerp(P.STONE[0], 0.35))


## Merlons around an elliptic rim; front ones only (the back ones hide behind the gun).
func _merlon_ring(c: Canvas, center: Vector2, rx: float, ry: float, back: bool) -> void:
	for i: int in 9:
		var a: float = (PI if back else 0.0) + (i + 0.5) * PI / 9.0
		var p: Vector2 = center + Vector2(cos(a) * rx, sin(a) * ry)
		c.part()
		c.block(Rect2(p - Vector2(1, 2), Vector2(2, 1)), 2.0, P.STONE.slice(3, 7), P.STONE.slice(1, 5), false)


func _dither_region(c: Canvas, area: Rect2i, amount: float) -> void:
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			if Canvas.BAYER_4[posmod(y, 4) * 4 + posmod(x, 4)] / 16.0 < amount and c.is_filled(x, y):
				var col: Color = c.get_color(x, y)
				if col in P.SMOKE:
					c.erase(x, y)


# ---------------------------------------------------------------- projectiles

## Rows: arrow_0..7 (1 frame each), cannonball (2 frames, spinning), frost_bolt (4 frames).
func projectile_rows() -> Array[Array]:
	var rows: Array[Array] = []
	for direction: int in 8:
		rows.append([_arrow(direction)])
	var balls: Array[Image] = []
	for frame: int in 2:
		var c: Canvas = Canvas.new(PROJECTILE_SIZE.x, PROJECTILE_SIZE.y)
		c.part()
		c.ellipse(Vector2(6, 6), Vector2(3.0, 3.0), P.IRON, 0.0, 0.1)
		c.px(5 if frame == 0 else 6, 7 if frame == 0 else 4, P.IRON[1])  # a rough spot shows it spin
		c.finish()
		# A trail of sparks from the fuse.
		c.image.set_pixel(10 if frame == 0 else 9, 2 if frame == 0 else 3, P.FIRE[4])
		balls.append(c.image)
	rows.append(balls)
	var bolts: Array[Image] = []
	for frame: int in 4:
		var c2: Canvas = Canvas.new(PROJECTILE_SIZE.x, PROJECTILE_SIZE.y)
		var ridge: float = 6.0 + sin(frame * TAU / 4.0)
		var top: Vector2 = Vector2(6, 1.5)
		var bottom: Vector2 = Vector2(6, 10.5)
		c2.part()
		c2.polygon(PackedVector2Array([top, Vector2(3, 6), Vector2(ridge, 6.5)]), P.ICE, Vector3(-0.8, -0.5, 0.6))
		c2.polygon(PackedVector2Array([top, Vector2(ridge, 6.5), Vector2(9, 6)]), P.ICE, Vector3(0.5, -0.5, 0.6))
		c2.polygon(PackedVector2Array([Vector2(3, 6), bottom, Vector2(ridge, 6.5)]), P.ICE, Vector3(-0.5, 0.6, 0.6))
		c2.polygon(PackedVector2Array([Vector2(ridge, 6.5), bottom, Vector2(9, 6)]), P.ICE, Vector3(0.6, 0.6, 0.4))
		c2.finish(true, P.ICE[0])
		var spark: Vector2i = [Vector2i(1, 2), Vector2i(10, 3), Vector2i(10, 9), Vector2i(1, 9)][frame]
		c2.image.set_pixelv(spark, P.ICE[5])
		bolts.append(c2.image)
	rows.append(bolts)
	return rows


## An arrow along one of 8 directions: steel head, ash shaft, red fletching.
func _arrow(direction: int) -> Image:
	var c: Canvas = Canvas.new(PROJECTILE_SIZE.x, PROJECTILE_SIZE.y)
	var dir: Vector2i = [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
		Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)][direction]
	var center: Vector2i = Vector2i(6, 6)
	c.part()
	for i: int in range(-4, 3):
		c.px(center.x + dir.x * i, center.y + dir.y * i, P.WOOD[4])
	c.px(center.x + dir.x * 3, center.y + dir.y * 3, P.STEEL[3])
	c.px(center.x + dir.x * 4, center.y + dir.y * 4, P.STEEL[5])
	var across: Vector2i = Vector2i(-dir.y, dir.x)
	for k: int in [-4, -3]:
		c.px(center.x + dir.x * k + across.x, center.y + dir.y * k + across.y, P.BANNER[3])
		c.px(center.x + dir.x * k - across.x, center.y + dir.y * k - across.y, P.BANNER[2])
	return c.finish(false)


# ---------------------------------------------------------------- explosion and frost

## Flash, fireball, burning cloud with flying debris, smoke ring, fading smoke (56x56 = the 112 px blast).
func explosion_frames() -> Array[Image]:
	var frames: Array[Image] = []
	var center: Vector2 = Vector2(EXPLOSION_SIZE) / 2.0 + Vector2(0, 2)
	for frame: int in 7:
		var img: Image = Image.create_empty(EXPLOSION_SIZE.x, EXPLOSION_SIZE.y, false, Image.FORMAT_RGBA8)
		var radius: float = [8.0, 16.0, 22.0, 25.0, 26.5, 27.0, 27.0][frame]
		for y: int in EXPLOSION_SIZE.y:
			for x: int in EXPLOSION_SIZE.x:
				var v: Vector2 = Vector2(x + 0.5, y + 0.5) - center
				var wobble: float = sin(v.angle() * 7.0 + frame * 1.3) * 1.6 + sin(v.angle() * 3.0 - frame) * 1.2
				var d: float = v.length()
				if d > radius + wobble:
					continue
				var t: float = d / radius
				var lit: float = Canvas.light_of(Vector3(v.x / radius, v.y / radius, maxf(1.0 - t, 0.1)))
				var threshold: float = Canvas.BAYER_4[(y % 4) * 4 + (x % 4)] / 16.0
				var color: Color
				match frame:
					0:
						color = Color("ffffff") if t < 0.6 else P.FIRE[5]
					1:
						color = Canvas.shade(P.FIRE.slice(2, 6), 1.0 - t * 0.8, x, y, true)
					2:
						color = Canvas.shade(P.FIRE.slice(1, 6), 0.95 - t * 0.9 + lit * 0.2, x, y, true)
						if t > 0.8:
							color = P.SMOKE[2]
					3:
						if t < 0.25:
							color = P.FIRE[3]
						elif t < 0.55:
							color = Canvas.shade(P.FIRE.slice(0, 3), lit, x, y, true)
						else:
							color = Canvas.shade(P.SMOKE.slice(1, 5), lit, x, y, true)
					4:
						if t < 0.45:
							continue  # the smoke ring opens up
						color = Canvas.shade(P.SMOKE.slice(1, 5), lit, x, y, true)
					_:
						if t < 0.6 + (frame - 5) * 0.15 or threshold < (frame - 4) * 0.3:
							continue
						color = Canvas.shade(P.SMOKE.slice(1, 4), lit, x, y, true)
				img.set_pixel(x, y, color)
		# Debris flung outward on frames 2-4.
		if frame >= 2 and frame <= 4:
			for k: int in 10:
				var a: float = k * TAU / 10.0 + 0.3
				var p: Vector2 = center + Vector2.from_angle(a) * (radius + 2.0 + (k % 3)) + Vector2(0, -frame + (frame - 2) * 1.5)
				if Rect2(Vector2.ZERO, Vector2(EXPLOSION_SIZE) - Vector2.ONE).has_point(p):
					img.set_pixel(int(p.x), int(p.y), P.FIRE[4] if frame == 2 else (P.STONE[3] if k % 2 == 0 else P.FIRE[2]))
		frames.append(img)
	return frames


## Row 0: frost burst (5 frames: shards flying out, a ring of frost). Row 1: slowed aura (4 frames,
## ice crystals growing around the feet and twinkling).
func frost_rows() -> Array[Array]:
	var c: Vector2 = Vector2(10, 10)
	var burst: Array[Image] = []
	for frame: int in 5:
		var img: Image = Image.create_empty(FROST_FX_SIZE.x, FROST_FX_SIZE.y, false, Image.FORMAT_RGBA8)
		var reach: float = [2.5, 4.5, 6.5, 8.0, 9.0][frame]
		for y: int in FROST_FX_SIZE.y:
			for x: int in FROST_FX_SIZE.x:
				var v: Vector2 = Vector2(x + 0.5, y + 0.5) - c
				var d: float = v.length()
				var spoke: float = absf(sin(v.angle() * 4.0))  # 8 shards
				var threshold: float = Canvas.BAYER_4[(y % 4) * 4 + (x % 4)] / 16.0
				var color: Color = Color(0, 0, 0, 0)
				if d < reach and spoke < 0.28 + (1.0 - d / reach) * 0.4 and d > reach - 4.5:
					color = P.ICE[5] if d > reach - 1.5 else P.ICE[4]
				elif absf(d - reach * 0.8) < 0.8 and frame >= 2:
					color = P.ICE[3]
				elif d < 2.0 and frame < 2:
					color = Color("ffffff")
				if color.a > 0.0 and threshold >= maxf(frame - 2, 0) * 0.3:
					img.set_pixel(x, y, color)
		burst.append(img)
	var aura: Array[Image] = []
	var crystals: Array[Vector2i] = [Vector2i(3, 15), Vector2i(6, 17), Vector2i(10, 18), Vector2i(14, 17), Vector2i(17, 15), Vector2i(8, 16), Vector2i(12, 16)]
	for frame: int in 4:
		var cc: Canvas = Canvas.new(FROST_FX_SIZE.x, FROST_FX_SIZE.y)
		for i: int in crystals.size():
			var p: Vector2i = crystals[i]
			var height: int = 2 + (i + frame) % 3
			cc.part()
			for k: int in height:
				cc.px(p.x, p.y - k, P.ICE[5] if k == height - 1 else (P.ICE[4] if k > 0 else P.ICE[3]))
			if (i + frame) % 4 == 0:
				cc.px(p.x + 1, p.y - height - 1, Color("ffffff"))
		aura.append(cc.finish(false, P.ICE[1]))
	return [burst, aura]
