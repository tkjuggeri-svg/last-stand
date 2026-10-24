extends RefCounted
## The six combo evolutions' looks (dev-time art generator): 32x48 art frames at the double resolution
## (64x96), base on art row 45, idle (4) and fire (4) each. Each one is the base tower's idea turned up:
##   Heart of the Pyre (Brazier + Ember Heart): a bronze bowl holding a crimson heart of fire.
##   Stillwater (Frost + Hourglass): a still pool of ice ringed by an hourglass of white sand.
##   Headsman's Bolt (Bone Ballista + Executioner's Mark): a black iron ballista with an axe-blade bolt.
##   Sky Tyrant (Hawk Perch + Falcon's Hood): a tall perch with a great crowned eagle.
##   Legion (Bone Pit + Grave Crown): a pit crowded with skeletal hands under a crown of bone.
##   Banner Guard (Archer + Twin Banners): a timber archer tower flying two great banners.

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")

const SIZE: Vector2i = Vector2i(32, 48)
const BASE: float = 45.0
const KINDS: Array[String] = ["heart_of_the_pyre", "stillwater", "headsmans_bolt", "sky_tyrant", "legion", "banner_guard"]

var detail: int = 1


func _init(resolution: int = 1) -> void:
	detail = resolution


func sheet_rows() -> Array[Array]:
	var rows: Array[Array] = []
	for kind: String in KINDS:
		for firing: bool in [false, true]:
			var frames: Array[Image] = []
			for i: int in 4:
				var c: Canvas = Canvas.new(SIZE.x, SIZE.y, detail)
				call("_" + kind, c, firing, i)
				c.finish()
				c.ground_shadow(Vector2(17.5, BASE), Vector2(13, 3.2))
				frames.append(c.image)
			rows.append(frames)
	return rows


func _plinth(c: Canvas) -> void:
	c.part()
	c.block(Rect2(7, 37, 18, 4), BASE - 41.0, P.STONE.slice(2, 7), P.STONE.slice(1, 6))


func _heart_of_the_pyre(c: Canvas, firing: bool, frame: int) -> void:
	_plinth(c)
	c.part()
	c.cylinder(16, 26, 37, 4.0, 1.4, P.BRONZE.slice(0, 4), [], false)
	c.part()
	c.polygon(PackedVector2Array([Vector2(7, 21), Vector2(25, 21), Vector2(21, 28), Vector2(11, 28)]), P.BRONZE, Vector3(-0.3, -0.4, 1))
	c.line(Vector2(7, 21), Vector2(25, 21), P.GOLD[3])
	var rise: float = [0.0, 1.0, 2.0, 1.0][frame] + (2.0 if firing else 0.0)
	c.part(true)
	c.polygon(PackedVector2Array([Vector2(16, 21), Vector2(10, 13 - rise), Vector2(13, 8 - rise), Vector2(16, 11 - rise), Vector2(19, 8 - rise), Vector2(22, 13 - rise)]), P.FIRE, Vector3(-0.2, -0.5, 1))
	c.ellipse(Vector2(16, 15 - rise * 0.5), Vector2(3, 3.4), P.TABARD, 0.0, 0.4)  # the heart
	c.px(15, 14 - roundi(rise * 0.5), P.TABARD[4])


func _stillwater(c: Canvas, firing: bool, frame: int) -> void:
	_plinth(c)
	c.part()
	c.ellipse(Vector2(16, 31), Vector2(9, 4.2), P.ARCANE_ICE, 0.0, -0.1)
	c.ellipse(Vector2(16, 31), Vector2(6.6, 2.8), P.ICE, 0.0, 0.3)
	# An hourglass above the pool, its sand falling.
	c.part()
	c.polygon(PackedVector2Array([Vector2(11, 8), Vector2(21, 8), Vector2(16, 17)]), P.ICE, Vector3(-0.3, -0.4, 1))
	c.polygon(PackedVector2Array([Vector2(16, 17), Vector2(11, 26), Vector2(21, 26)]), P.ICE, Vector3(-0.3, -0.4, 1))
	c.line(Vector2(10, 7.5), Vector2(22, 7.5), P.GOLD[2])
	c.line(Vector2(10, 26.5), Vector2(22, 26.5), P.GOLD[2])
	c.part(true)
	c.line(Vector2(16, 17), Vector2(16, 24 - frame * 0.4), P.BONE[3])
	if firing:
		c.line(Vector2(5, 31), Vector2(27, 31), Color("ffffff"))


func _headsmans_bolt(c: Canvas, firing: bool, frame: int) -> void:
	_plinth(c)
	c.part()
	c.block(Rect2(6, 24, 20, 5), 8.0, P.IRON.slice(1, 5), P.IRON.slice(0, 4))
	var draw: float = [0.0, 1.0, 2.0, 0.0][frame] if firing else 0.0
	c.part()
	c.line(Vector2(5, 22 - draw), Vector2(16, 24), P.IRON[4])
	c.line(Vector2(27, 22 - draw), Vector2(16, 24), P.IRON[4])
	c.line(Vector2(5, 22 - draw), Vector2(27, 22 - draw), P.BONE[2])
	c.part()
	c.line(Vector2(16, 24), Vector2(16, 12 + draw * 2), P.WOOD[4])
	c.polygon(PackedVector2Array([Vector2(16, 6 + draw * 2), Vector2(21, 11 + draw * 2), Vector2(16, 13 + draw * 2), Vector2(11, 11 + draw * 2)]), P.STEEL, Vector3(-0.3, -0.5, 1))  # an axe-blade head
	c.px(14, 10 + roundi(draw * 2.0), P.TABARD[3])
	c.part()
	c.rect(Rect2i(24, 30, 5, 7), P.WOOD[2])  # the block


func _sky_tyrant(c: Canvas, firing: bool, frame: int) -> void:
	_plinth(c)
	c.part()
	c.cylinder(16, 18, 38, 2.2, 0.8, P.WOOD.slice(1, 5), [], false)
	c.part()
	c.block(Rect2(7, 17, 18, 2), 1.0, P.WOOD.slice(2, 5), P.WOOD.slice(1, 4), false)
	var spread: float = [0.0, 1.5, 3.0, 1.5][frame] if firing else [0.0, 0.0, 0.5, 0.0][frame]
	c.part()
	c.ellipse(Vector2(16, 11), Vector2(4.2, 5.4), P.GOLD.slice(0, 4), 0.0, -0.1)  # the great eagle's body
	c.polygon(PackedVector2Array([Vector2(12, 9), Vector2(3, 6 - spread), Vector2(5, 13)]), P.GOLD, Vector3(-0.3, -0.4, 1))
	c.polygon(PackedVector2Array([Vector2(20, 9), Vector2(29, 6 - spread), Vector2(27, 13)]), P.GOLD, Vector3(0.3, -0.4, 1))
	c.ellipse(Vector2(17, 5), Vector2(2.2, 2.0), P.BONE, 0.0, 0.2)
	c.px(18, 5, P.TABARD[4])
	c.part()
	c.polygon(PackedVector2Array([Vector2(14.5, 3), Vector2(15.5, 0), Vector2(17, 2), Vector2(18.5, 0), Vector2(19.5, 3)]), P.GOLD, Vector3(0, -0.4, 1))  # a crown


func _legion(c: Canvas, firing: bool, frame: int) -> void:
	c.part()
	c.ellipse(Vector2(16, 38), Vector2(13, 6), P.STONE, 0.0, 0.1)
	c.part()
	c.ellipse(Vector2(16, 38.5), Vector2(10, 4), P.CULT_DARK, 0.0, -0.4)
	for k: int in 5:
		var x: float = 8.0 + k * 4.0
		var reach: float = [1.0, 3.0, 5.0, 2.0][(frame + k) % 4] + (3.0 if firing else 0.0)
		c.part()
		c.capsule(Vector2(x, 38), Vector2(x, 36 - reach), 1.0, P.BONE, 0.1)
		c.line(Vector2(x - 1, 35.5 - reach), Vector2(x - 1.5, 33.5 - reach), P.BONE[3])
		c.line(Vector2(x + 1, 35.5 - reach), Vector2(x + 1.5, 33.5 - reach), P.BONE[3])
	c.part()
	c.polygon(PackedVector2Array([Vector2(8, 22), Vector2(10, 14), Vector2(13, 19), Vector2(16, 12), Vector2(19, 19), Vector2(22, 14), Vector2(24, 22)]), P.BONE, Vector3(-0.3, -0.5, 1))  # a crown of bone
	c.line(Vector2(8, 22), Vector2(24, 22), P.GOLD[2])
	c.part(true)
	c.px(16, 17, P.SOUL[3])


func _banner_guard(c: Canvas, firing: bool, frame: int) -> void:
	_plinth(c)
	c.part()
	c.block(Rect2(11, 22, 10, 3), BASE - 38.0 - 3.0 + 3.0, P.WOOD.slice(2, 5), P.WOOD.slice(1, 4), false)
	c.part()
	c.block(Rect2(8, 16, 16, 3), 3.0, P.WOOD.slice(2, 5), P.WOOD.slice(1, 4), false)
	c.part()
	c.ellipse(Vector2(16, 13), Vector2(2.4, 2.6), P.HOOD, 0.0, 0.1)
	c.px(17, 13, P.SKIN[2])
	var draw: float = [0.0, 1.0, 2.0, 0.0][frame] if firing else 0.0
	c.line(Vector2(20 - draw * 0.4, 8), Vector2(20 - draw * 0.4, 18), P.WOOD[4])
	for side: int in 2:
		var x: float = 4.0 if side == 0 else 28.0
		var dir: float = 1.0 if side == 0 else -1.0
		var flutter: float = [0.0, 1.0, 0.5, -0.5][(frame + side * 2) % 4]
		c.part()
		c.line(Vector2(x, 36), Vector2(x, 4), P.WOOD[3])
		c.polygon(PackedVector2Array([Vector2(x, 5), Vector2(x + dir * 7, 7 + flutter), Vector2(x + dir * 7, 16 + flutter), Vector2(x, 18)]), P.BANNER, Vector3(-0.2, -0.3, 1))
		c.px(roundi(x) + int(dir * 3), 11, P.GOLD[3])
