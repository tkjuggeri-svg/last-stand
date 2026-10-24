extends RefCounted
## The Huntress's towers (dev-time art generator): Trap Layer, Hawk Perch and Watchtower, each in three
## levels and with its two evolutions, plus the snare / spiked patch and the hawk in flight. 32x48 art
## frames at the double resolution (64x96), base on art row 45 like the other towers, 3/4 view, light
## from the top-left. Per tower: idle (4), fire (4), build (6), sell (6) for level 1, idle + fire for
## levels 2 and 3, then idle + fire for each evolution.
##   Trap Layer: a timber frame with a throwing arm, a rope coil and spiked snares at its foot.
##   Hawk Perch: a tall pole with a crossbar and a hawk (it leaves the perch when it dives).
##   Watchtower: a timber lookout with a thatched roof, a spotter, a banner.

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")

const SIZE: Vector2i = Vector2i(32, 48)
const FX_SIZE: Vector2i = Vector2i(32, 32)
const BASE: float = 45.0
const FRAMES: int = 4
const BUILD_FRAMES: int = 6
## The towers and their evolutions in sheet order (sheet_layouts.HUNTRESS_TOWERS lists the rows).
const TOWERS: Array[String] = ["trap_layer", "hawk_perch", "watchtower"]
const EVOLUTIONS: Dictionary = {
	"trap_layer": ["bear_pit", "caltrop_field"],
	"hawk_perch": ["falconer", "eye_of_the_hunt"],
	"watchtower": ["signal_fire", "marksmans_roost"],
}
const DIRS: int = 8
const HAWK_BROWN: Array[Color] = [Color("1f140f"), Color("3b2619"), Color("5c3d26"), Color("80583a"), Color("a67b52")]

var detail: int = 1


func _init(resolution: int = 1) -> void:
	detail = resolution


## Rows in the order of sheet_layouts.HUNTRESS_TOWERS.
func sheet_rows() -> Array[Array]:
	var rows: Array[Array] = []
	for kind: String in TOWERS:
		rows.append(_row(kind, 1, "idle"))
		rows.append(_row(kind, 1, "fire"))
		rows.append(_build_row(kind, false))
		rows.append(_build_row(kind, true))
		for level: int in [2, 3]:
			rows.append(_row(kind, level, "idle"))
			rows.append(_row(kind, level, "fire"))
		for evolution: String in EVOLUTIONS[kind]:
			rows.append(_row(kind, 3, "idle", evolution))
			rows.append(_row(kind, 3, "fire", evolution))
	return rows


func _row(kind: String, level: int, state: String, evolution: String = "") -> Array[Image]:
	var frames: Array[Image] = []
	for i: int in FRAMES:
		frames.append(tower(kind, level, state == "fire", i, evolution))
	return frames


## The build animation rises from the ground; the sell animation is the same in reverse, ending in rubble.
func _build_row(kind: String, selling: bool) -> Array[Image]:
	var frames: Array[Image] = []
	for i: int in BUILD_FRAMES:
		var reveal: float = float(i + 1) / BUILD_FRAMES
		if selling:
			reveal = 1.0 - reveal + 1.0 / BUILD_FRAMES * 0.0
			reveal = maxf(1.0 - float(i + 1) / BUILD_FRAMES, 0.0)
		var image: Image = tower(kind, 1, false, 0, "")
		_reveal(image, reveal)
		if selling or i < BUILD_FRAMES - 1:
			_rubble(image, 1.0 - reveal if not selling else 0.4 + 0.6 * float(i) / BUILD_FRAMES)
		frames.append(image)
	return frames


func tower(kind: String, level: int, firing: bool, frame: int, evolution: String) -> Image:
	var c: Canvas = Canvas.new(SIZE.x, SIZE.y, detail)
	call("_" + kind, c, level, firing, frame, evolution)
	c.finish()
	c.ground_shadow(Vector2(17.5, BASE), Vector2(13, 3.2))
	return c.image


## Keeps only the lowest `amount` of the tower's height (a building going up or coming down).
func _reveal(image: Image, amount: float) -> void:
	var rect: Rect2i = image.get_used_rect()
	var keep_from: int = rect.end.y - int(rect.size.y * amount) - 2 * detail
	for y: int in range(0, mini(keep_from, image.get_height())):
		for x: int in image.get_width():
			image.set_pixel(x, y, Color(0, 0, 0, 0))


## A heap of stones and planks at the foot (the dust of building or the rubble of selling).
func _rubble(image: Image, amount: float) -> void:
	var c: Canvas = Canvas.new(SIZE.x, SIZE.y, detail)
	var n: int = roundi(5.0 * clampf(amount, 0.0, 1.0))
	for k: int in n:
		var x: float = 10.0 + k * 3.0
		c.part()
		c.ellipse(Vector2(x, BASE - 1.5 - (k % 2) * 1.5), Vector2(2.4, 1.8), P.STONE, 0.0, 0.0)
	c.finish()
	image.blend_rect(c.image, Rect2i(Vector2i.ZERO, c.image.get_size()), Vector2i.ZERO)


# ---------------------------------------------------------------- shared parts

func _footing(c: Canvas, level: int) -> void:
	c.part()
	c.block(Rect2(7, 36, 18, 4), BASE - 40.0, P.STONE.slice(2, 7), P.STONE.slice(1, 6))
	if level >= 2:
		c.line(Vector2(7, 40), Vector2(25, 40), P.STONE[3])
	if level >= 3:
		c.px(8, 38, P.GOLD[3])
		c.px(23, 38, P.GOLD[3])


## A pennant on a pole: red at level 2, gold-tipped at level 3 (not on level 1).
func _pennant(c: Canvas, top: Vector2, level: int, frame: int) -> void:
	if level < 2:
		return
	c.part()
	c.line(top, top + Vector2(0, -5), P.WOOD[3])
	c.part()
	var flutter: float = [0.0, 1.0, 0.5, -0.5][frame % 4]
	c.polygon(PackedVector2Array([top + Vector2(0, -5), top + Vector2(5, -4 + flutter), top + Vector2(0, -2)]), P.BANNER, Vector3(-0.2, -0.3, 1))
	if level >= 3:
		c.px(roundi(top.x), roundi(top.y) - 6, P.GOLD[3])


## A small hooded figure (the archers' look) at `at`.
func _watcher(c: Canvas, at: Vector2) -> void:
	c.part()
	c.ellipse(at + Vector2(0, 3), Vector2(2.4, 2.6), P.HOOD, 0.0, 0.1)
	c.ellipse(at, Vector2(1.9, 1.8), P.HOOD, 0.0, 0.15)
	c.px(roundi(at.x) + 1, roundi(at.y), P.SKIN[2])


# ---------------------------------------------------------------- Trap Layer

func _trap_layer(c: Canvas, level: int, firing: bool, frame: int, evolution: String) -> void:
	_footing(c, level)
	# The frame: two posts and a crossbeam, the throwing arm pivoting on it.
	c.part()
	for x: int in [10, 21]:
		c.rect(Rect2i(x, 22, 2, 14), P.WOOD[2])
	c.part()
	c.rect(Rect2i(10, 21, 13, 2), P.WOOD[3])
	# The arm: down while winding, flung forward on the shot.
	var swing: float = [0.0, 1.0, 0.6, 0.2][frame] if firing else 0.0
	var tip: Vector2 = Vector2(16, 24).lerp(Vector2(26, 14), swing) if firing else Vector2(9, 26)
	c.part()
	c.line(Vector2(16, 24), tip, P.WOOD[4])
	c.line(Vector2(15, 24), tip + Vector2(-1, 0), P.WOOD[3])
	if not firing or frame == 0:
		c.part()
		c.ellipse(tip + Vector2(0, 1), Vector2(2.2, 1.6), P.LEATHER, 0.0, 0.1)  # the snare in its cup
	elif frame == 1:
		c.part(true)
		c.line(tip, tip + Vector2(3, -3), P.BONE[3])
	# A rope coil and spiked snares at the foot.
	c.part()
	c.ellipse(Vector2(12, 37), Vector2(3.0, 1.8), P.LEATHER, 0.0, 0.1)
	c.ellipse(Vector2(12, 36.4), Vector2(1.6, 0.8), P.LEATHER, 0.0, -0.3)
	_spikes(c, Vector2(22, 38), 3 if level < 2 else 5)
	if level >= 3:
		c.part()
		c.line(Vector2(10, 29), Vector2(12, 29), P.STEEL[4])
		c.line(Vector2(21, 29), Vector2(23, 29), P.STEEL[4])
	_pennant(c, Vector2(11, 21), level, frame)
	match evolution:
		"bear_pit":
			# Great iron jaws gaping on the ground in front, teeth to the sky.
			c.part()
			c.polygon(PackedVector2Array([Vector2(3, 43), Vector2(9, 36), Vector2(11, 43)]), P.IRON, Vector3(-0.3, -0.5, 1))
			c.polygon(PackedVector2Array([Vector2(29, 43), Vector2(23, 36), Vector2(21, 43)]), P.IRON, Vector3(0.3, -0.5, 1))
			c.line(Vector2(3, 43), Vector2(29, 43), P.IRON[1])
		"caltrop_field":
			_spikes(c, Vector2(7, 41), 4)
			_spikes(c, Vector2(26, 42), 4)
			c.part()
			c.ellipse(Vector2(16, 43), Vector2(11, 2), P.DIRT, 0.0, -0.1)


func _spikes(c: Canvas, at: Vector2, count: int) -> void:
	for k: int in count:
		var x: float = at.x - count + k * 2.0
		c.part()
		c.line(Vector2(x, at.y), Vector2(x + 0.5, at.y - 3 - (k % 2)), P.STEEL[4])


# ---------------------------------------------------------------- Hawk Perch

func _hawk_perch(c: Canvas, level: int, firing: bool, frame: int, evolution: String) -> void:
	_footing(c, level)
	# A tall pole and the crossbar the hawk stands on.
	c.part()
	c.cylinder(16, 14, 37, 2.0, 0.8, P.WOOD.slice(1, 5), [], false)
	c.part()
	c.block(Rect2(9, 12, 14, 2), 1.0, P.WOOD.slice(2, 5), P.WOOD.slice(1, 4), false)
	if level >= 2:
		c.part()
		c.block(Rect2(12, 22, 8, 2), 1.0, P.WOOD.slice(2, 5), P.WOOD.slice(1, 4), false)  # a lower rest with the lure
		c.px(20, 25, P.TABARD[3])
	if level >= 3:
		c.part()
		c.ellipse(Vector2(16, 11), Vector2(1.6, 1.0), P.GOLD, 0.0, 0.2)  # a gilded finial
	if evolution == "falconer":
		_hawk_on(c, Vector2(11, 11), firing, frame, true)
		_hawk_on(c, Vector2(21, 11), firing, (frame + 2) % 4, false)
	else:
		_hawk_on(c, Vector2(16, 11), firing, frame, true, evolution == "eye_of_the_hunt")
	_pennant(c, Vector2(23, 12), level, frame)
	if evolution == "eye_of_the_hunt":
		c.part(true)
		c.line(Vector2(13, 6), Vector2(19, 6), P.TABARD[4], true)


## A hawk perched at `at` (the crossbar's top): breathing while idle, gone (a puff of feathers) mid-dive.
func _hawk_on(c: Canvas, at: Vector2, firing: bool, frame: int, lead: bool, glowing: bool = false) -> void:
	if firing and lead and frame in [1, 2]:
		c.part(true)
		for k: int in 3:
			c.px(roundi(at.x) - 2 + k * 2, roundi(at.y) - 3 - frame - (k % 2), P.BONE[2])
		return
	var bob: float = 0.5 if (not firing and frame in [1, 2]) else 0.0
	c.part()
	c.ellipse(at + Vector2(0, -2.6 + bob), Vector2(2.6, 3.2), HAWK_BROWN, 0.0, 0.05)
	c.ellipse(at + Vector2(0.6, -6.0 + bob), Vector2(1.8, 1.7), HAWK_BROWN, 0.0, 0.2)
	c.px(roundi(at.x) + 2, roundi(at.y) - 6, P.GOLD[3])  # the beak
	c.px(roundi(at.x) + 1, roundi(at.y) - 7, P.TABARD[4] if glowing else P.GOLD[4])  # the eye
	c.line(at + Vector2(-1, -1), at + Vector2(-3, 1.5), HAWK_BROWN[1])  # the tail


# ---------------------------------------------------------------- Watchtower

func _watchtower(c: Canvas, level: int, firing: bool, frame: int, evolution: String) -> void:
	_footing(c, level)
	# Four legs braced into a tall timber shaft, a deck, rails and a thatched roof.
	c.part()
	c.block(Rect2(11, 20, 10, 3), BASE - 38.0 - 3.0 + 3.0, P.WOOD.slice(2, 5), P.WOOD.slice(1, 4), false)
	for y: int in range(27, 38, 4):
		c.line(Vector2(11, y), Vector2(20, y + 2), P.WOOD[1])
		c.line(Vector2(20, y), Vector2(11, y + 2), P.WOOD[1])
	c.part()
	c.block(Rect2(8, 15, 16, 3), 3.0, P.WOOD.slice(2, 5), P.WOOD.slice(1, 4), false)  # the deck
	for x: int in [8, 23]:
		c.rect(Rect2i(x, 8, 1, 8), P.WOOD[3])  # roof posts
	_watcher(c, Vector2(14, 12))
	var glint: bool = firing and frame in [1, 2]
	if evolution == "marksmans_roost":
		c.part()
		c.line(Vector2(15, 12), Vector2(25 + (1 if glint else 0), 11), P.WOOD[4])
		c.px(26, 11, P.STEEL[5])
	else:
		c.part()
		c.line(Vector2(15, 12), Vector2(19, 10), P.BRONZE[3])  # a spyglass
		if glint:
			c.part(true)
			c.px(20, 9, Color("ffffff"))
	c.part()
	var roof: Array = P.SLATE if evolution == "marksmans_roost" else P.REED
	c.polygon(PackedVector2Array([Vector2(4, 9), Vector2(16, 0), Vector2(28, 9)]), roof, Vector3(-0.3, -0.6, 0.8))
	c.line(Vector2(4, 9), Vector2(28, 9), roof[2])
	if level >= 3:
		c.px(16, -1, P.GOLD[3])
	if evolution == "signal_fire":
		c.part()
		c.ellipse(Vector2(26, 15), Vector2(2.4, 1.2), P.IRON, 0.0, 0.0)  # a brazier on the rail
		c.part(true)
		var rise: float = [0.0, 1.0, 2.0, 1.0][frame]
		c.ellipse(Vector2(26, 12.5 - rise * 0.5), Vector2(2.0, 2.6 + rise * 0.3), P.FIRE, 0.0, 0.2)
	_pennant(c, Vector2(24, 8), level, frame)


# ---------------------------------------------------------------- shots and traps

## The snare and the spiked patch, then the hawk in 8 directions (2 flapping frames each).
func fx_rows() -> Array[Array]:
	var rows: Array[Array] = []
	var armed: Array[Image] = []
	for i: int in 2:
		armed.append(_snare(false, i))
	rows.append(armed)
	var sprung: Array[Image] = []
	for i: int in 3:
		sprung.append(_snare(true, i))
	rows.append(sprung)
	var patch: Array[Image] = []
	for i: int in 4:
		patch.append(_patch(i))
	rows.append(patch)
	for dir: int in DIRS:
		var flap: Array[Image] = []
		for i: int in 2:
			flap.append(_hawk(dir, i))
		rows.append(flap)
	return rows


func _snare(sprung: bool, i: int) -> Image:
	var c: Canvas = Canvas.new(FX_SIZE.x, FX_SIZE.y, detail)
	c.part()
	if not sprung:
		c.ellipse(Vector2(16, 17), Vector2(8.5, 4.2), P.LEATHER, 0.0, 0.0)
		c.ellipse(Vector2(16, 17), Vector2(5.5, 2.6), P.DIRT, 0.0, -0.2)
		for k: int in 6:
			var a: float = TAU * k / 6.0
			c.px(roundi(16 + cos(a) * 7.0), roundi(17 + sin(a) * 3.4), P.STEEL[4])
		if i == 1:
			c.part(true)
			c.px(16, 16, P.STEEL[5])
	else:
		var close: float = [0.4, 0.8, 1.0][i]
		c.ellipse(Vector2(16, 18), Vector2(8.5 * (1.0 - close * 0.4), 4.0), P.LEATHER, 0.0, 0.0)
		for k: int in 6:
			var a: float = TAU * k / 6.0
			var base: Vector2 = Vector2(16 + cos(a) * 6.0 * (1.0 - close * 0.4), 18 + sin(a) * 3.0)
			c.line(base, Vector2(16, 18 - 7.0 * close), P.STEEL[3])
	c.finish()
	return c.image


func _patch(i: int) -> Image:
	var c: Canvas = Canvas.new(FX_SIZE.x, FX_SIZE.y, detail)
	c.part()
	c.ellipse(Vector2(16, 17), Vector2(14, 7), P.DIRT, 0.0, -0.15)
	for k: int in 10:
		var a: float = k * 2.4
		var r: float = 3.0 + (k % 4) * 2.2
		var at: Vector2 = Vector2(16 + cos(a) * r * 1.5, 17 + sin(a) * r * 0.55)
		c.part()
		c.line(at, at + Vector2(0.4, -3 - ((k + i) % 2)), P.STEEL[4])
	c.finish()
	return c.image


## A hawk seen from above and the side, flying along direction `dir` (0 = right, then clockwise by 45 degrees).
func _hawk(dir: int, flap: int) -> Image:
	var c: Canvas = Canvas.new(FX_SIZE.x, FX_SIZE.y, detail)
	var d: Vector2 = Vector2.from_angle(dir * PI / 4.0)
	var across: Vector2 = Vector2(-d.y, d.x)
	var centre: Vector2 = Vector2(16, 15)
	var spread: float = 6.5 if flap == 0 else 4.0
	c.part()
	for sign_i: int in [-1, 1]:
		var tip: Vector2 = centre - d * (2.0 if flap == 0 else 0.5) + across * spread * sign_i
		c.capsule(centre - d * 1.0, tip, 1.3, HAWK_BROWN, 0.0)
	c.part()
	c.capsule(centre - d * 3.5, centre + d * 3.0, 2.0, HAWK_BROWN, 0.1)
	c.ellipse(centre + d * 4.2, Vector2(1.5, 1.5), HAWK_BROWN, 0.0, 0.25)
	c.part()
	c.px(roundi(centre.x + d.x * 6.0), roundi(centre.y + d.y * 6.0), P.GOLD[3])
	c.finish()
	c.ground_shadow(Vector2(16, 24), Vector2(4, 1.4))
	return c.image
