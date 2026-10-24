extends RefCounted
## The skeleton minion (dev-time art generator): 32x32 art frames at the double resolution (64x64),
## drawn from the side facing right (the game mirrors it). Bone-white skull with dark sockets and a
## green glow, a ribcage on a spine, thin limbs and a rusty blade. Rows: idle (4), walk (6), attack
## (4), death (5), in the order of sheet_layouts.SKELETON.

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")

const SIZE: Vector2i = Vector2i(32, 32)
const FEET: float = 28.0
const RUST: Array[Color] = [Color("2a1710"), Color("4a2a1a"), Color("7a4528"), Color("a8683a")]

var detail: int = 1


func _init(resolution: int = 1) -> void:
	detail = resolution


func sheet_rows() -> Array[Array]:
	var rows: Array[Array] = []
	var idle: Array[Image] = []
	for i: int in 4:
		idle.append(frame({"bob": [0, 0, 1, 1][i], "stride": 0.0, "arm": 0.2 * i, "angle": 100.0}))
	rows.append(idle)
	var walk: Array[Image] = []
	for i: int in 6:
		var t: float = TAU * i / 6.0
		walk.append(frame({"bob": -1 if absf(sin(t)) < 0.5 else 0, "stride": sin(t), "arm": -sin(t), "angle": 100.0}))
	rows.append(walk)
	var attack: Array[Image] = []
	for i: int in 4:
		attack.append(frame({"bob": 0, "stride": 0.3, "arm": 0.0, "angle": [-120.0, -10.0, 40.0, 80.0][i], "reach": [-3.0, 3.0, 4.0, 1.0][i]}))
	rows.append(attack)
	rows.append(_death())
	return rows


func frame(pose: Dictionary) -> Image:
	var c: Canvas = Canvas.new(SIZE.x, SIZE.y, detail)
	_draw(c, pose)
	c.finish()
	c.ground_shadow(Vector2(16, FEET + 0.5), Vector2(6.5, 2.0))
	return c.image


func _draw(c: Canvas, pose: Dictionary) -> void:
	var up: Vector2 = Vector2(0, pose["bob"])
	var stride: float = pose["stride"]
	var hip: Vector2 = Vector2(16, 20) + up
	# The legs: a far one (darker) and a near one, thin bones.
	for leg: int in 2:
		var s: float = stride if leg == 1 else -stride
		var foot: Vector2 = Vector2(16 + s * 3.5, FEET - maxf(s, 0.0) * 1.5)
		c.part()
		c.capsule(hip + Vector2(leg * 0.5, 0), foot, 0.9, P.BONE if leg == 1 else [P.BONE[0], P.BONE[1], P.BONE[1], P.BONE[2]], 0.0)
		c.ellipse(foot + Vector2(1, 0), Vector2(1.6, 0.9), P.BONE, 0.0, 0.0)
	# Pelvis, spine and ribs.
	c.part()
	c.ellipse(hip, Vector2(2.4, 1.4), P.BONE, 0.0, 0.0)
	c.capsule(hip + Vector2(0, -1), Vector2(16, 11) + up, 0.8, P.BONE, 0.0)
	for k: int in 3:
		var y: float = 12.5 + k * 2.2
		c.part()
		c.ellipse(Vector2(16, y) + up, Vector2(3.6 - k * 0.4, 0.9), P.BONE, 0.0, 0.0)
	# The skull: a cranium, dark sockets with a green glow, a jaw.
	var head: Vector2 = Vector2(17, 7.5) + up
	c.part()
	c.ellipse(head, Vector2(3.3, 3.1), P.BONE, 0.0, 0.1)
	c.ellipse(head + Vector2(1.2, 2.6), Vector2(2.2, 1.0), P.BONE, 0.0, -0.1)
	c.part(true)
	c.px(floori(head.x) + 1, floori(head.y), P.SOUL[3])
	c.px(floori(head.x) + 2, floori(head.y), P.SOUL[2])
	# The arm and the blade.
	var shoulder: Vector2 = Vector2(16, 12) + up
	var hand: Vector2 = shoulder + Vector2(4.0 + float(pose.get("reach", 0.0)), 5.0 + float(pose["arm"]))
	c.part()
	c.capsule(shoulder, hand, 0.8, P.BONE, 0.0)
	var dir: Vector2 = Vector2.from_angle(deg_to_rad(pose["angle"]))
	c.part()
	c.capsule(hand, hand + dir * 8.0, 0.8, RUST, 0.1)
	c.line(hand + dir * 1.0, hand + dir * 7.0, RUST[3])


## Hit, falling apart, a heap of bones; the last frame holds.
func _death() -> Array[Image]:
	var frames: Array[Image] = []
	for i: int in 5:
		var c: Canvas = Canvas.new(SIZE.x, SIZE.y, detail)
		if i < 2:
			_draw(c, {"bob": i, "stride": 0.0, "arm": 1.0 * i, "angle": 100.0 + 20.0 * i})
		else:
			var spread: float = float(i - 1)
			c.part()
			c.ellipse(Vector2(16, FEET - 1.5), Vector2(5.0 + spread, 1.8), P.BONE, 0.0, 0.0)
			c.part()
			c.ellipse(Vector2(12 - spread, FEET - 2.5), Vector2(2.4, 2.2), P.BONE, 0.0, 0.1)
			c.px(11 - int(spread), int(FEET) - 3, P.OUTLINE)
			for k: int in 3:
				c.line(Vector2(15 + k * 2.0, FEET - 2.0), Vector2(17 + k * 2.0 + spread, FEET - 1.0), P.BONE[2])
		c.finish()
		c.ground_shadow(Vector2(16, FEET + 0.5), Vector2(6.5, 2.0))
		frames.append(c.image)
	return frames


## The Necromancer's soul bolt in 8 directions (0 flies right, then every 45 degrees clockwise), 2
## flickering frames each: a green-white orb with a fading tail. 16x16 art.
func soul_bolt_rows() -> Array[Array]:
	var rows: Array[Array] = []
	for dir: int in 8:
		var flicker: Array[Image] = []
		for f: int in 2:
			var c: Canvas = Canvas.new(16, 16, detail)
			var d: Vector2 = Vector2.from_angle(dir * PI / 4.0)
			c.part(true)
			c.line(Vector2(8, 8) - d * 5.0, Vector2(8, 8) - d * 1.5, P.SOUL[1])
			c.line(Vector2(8, 8) - d * 3.5, Vector2(8, 8) - d * 1.5, P.SOUL[2])
			c.ellipse(Vector2(8, 8), Vector2(2.4 + f * 0.4, 2.4 + f * 0.4), P.SOUL, 0.0, 0.3)
			c.px(8, 8, P.SOUL[4])
			c.finish(false)
			flicker.append(c.image)
		rows.append(flicker)
	return rows
