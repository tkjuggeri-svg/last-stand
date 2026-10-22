extends RefCounted
## The Bloater and its Bloatlings (dev-time art generator). The Bloater: a drowned corpse swollen with
## marsh gas into a huge round belly, pallid skin stretched over dark veins, glowing gas sacs that
## swell and dim, a small head sunk into the fat, stubby legs. It waddles; it slams with its belly;
## killed, it swells and bursts into a gas cloud (three Bloatlings crawl out: the gameplay spawns them).
## A Bloatling is the same creature drawn small (never a scaled sprite): a fist-sized swollen thing
## scuttling on thin legs. Every point is given relative to the feet and multiplied by the size `k`.
## Bloater frames are 40x40 art px (feet on BLOATER_FEET), Bloatlings 24x24 (BLOATLING_FEET).

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")
const Undead: GDScript = preload("res://tools/art/undead_fx.gd")

const BLOATER_SIZE: Vector2i = Vector2i(40, 40)
const BLOATER_FEET: Vector2 = Vector2(20, 35)
const BLOATLING_SIZE: Vector2i = Vector2i(24, 24)
const BLOATLING_FEET: Vector2 = Vector2(12, 20)
const WALK_FRAMES: int = 6
const ATTACK_FRAMES: int = 6

var _size: Vector2i = BLOATER_SIZE
var _feet: Vector2 = BLOATER_FEET
var _k: float = 1.0
## Its eyes' role colour (ART_DIRECTION 5): a splitter's magenta, the Bloatling's fast yellow.
var _eyes: Array[Color] = P.EYES_SPLITTER


## small = the Bloatling.
func _init(small: bool = false) -> void:
	if small:
		_size = BLOATLING_SIZE
		_feet = BLOATLING_FEET
		_k = 0.5
		_eyes = P.EYES_FAST


## Rows in the order of sheet_layouts.BLOATER / BLOATLING.
func sheet_rows() -> Array[Array]:
	var rows: Array[Array] = []
	for facing: String in ["down", "up", "side"]:
		var idle: Array[Image] = []
		for i: int in 4:
			idle.append(frame(facing, _idle_pose(i)))
		rows.append(idle)
	for facing: String in ["down", "up", "side"]:
		var walk: Array[Image] = []
		for i: int in WALK_FRAMES:
			walk.append(frame(facing, _walk_pose(i)))
		rows.append(walk)
	rows.append(_death_frames())
	for facing: String in ["down", "up", "side"]:
		var attack: Array[Image] = []
		for i: int in ATTACK_FRAMES:
			attack.append(frame(facing, _attack_pose(i)))
		rows.append(attack)
	return rows


# ---------------------------------------------------------------- poses

## body: the belly's offset; swell: how much bigger the belly is (1 = rest); glow: the gas sacs'
## brightness (0-1); step: which foot is up (-1, 0, 1); lean: forward lean of the belly (side view).
func _base_pose() -> Dictionary:
	return {"body": Vector2.ZERO, "swell": 1.0, "glow": 0.4, "step": 0.0, "lean": 0.0, "arms": 0.0}


## The gas sacs pulse while it stands: the telegraph that it is full of something.
func _idle_pose(i: int) -> Dictionary:
	var pose: Dictionary = _base_pose()
	pose["swell"] = [1.0, 1.03, 1.06, 1.03][i]
	pose["glow"] = [0.3, 0.55, 0.8, 0.55][i]
	pose["body"] = Vector2(0, [0.0, 0.0, -1.0, 0.0][i])
	return pose


## A heavy waddle: the belly rolls from side to side over short steps.
func _walk_pose(i: int) -> Dictionary:
	var t: float = TAU * i / WALK_FRAMES
	var pose: Dictionary = _base_pose()
	pose["body"] = Vector2(roundf(sin(t) * 1.2), 1.0 if absf(sin(t)) > 0.6 else 0.0)
	pose["step"] = sin(t)
	pose["glow"] = 0.35 + 0.25 * (0.5 + 0.5 * sin(t * 2.0))
	return pose


## 0-3: it rears back, swelling (the wind-up); 4: the belly slams forward and down; 5: recover.
func _attack_pose(i: int) -> Dictionary:
	var pose: Dictionary = _base_pose()
	var rear: float = minf(i / 3.0, 1.0)
	if i < 4:
		pose["body"] = Vector2(0, -2.0 * rear)
		pose["lean"] = -1.5 * rear
		pose["swell"] = 1.0 + 0.08 * rear
		pose["glow"] = 0.4 + 0.5 * rear
		pose["arms"] = rear
	elif i == 4:
		pose["body"] = Vector2(0, 2.0)
		pose["lean"] = 3.0
		pose["swell"] = 0.97
		pose["glow"] = 1.0
		pose["arms"] = -1.0
	return pose


# ---------------------------------------------------------------- frames

func frame(facing: String, pose: Dictionary) -> Image:
	var c: Canvas = Canvas.new(_size.x, _size.y)
	if facing == "side":
		_draw_side(c, pose)
	else:
		_draw_front(c, pose, facing == "down")
	c.finish()
	c.ground_shadow(_feet + Vector2(0, -0.5), Vector2(9.0, 2.6) * _k * float(pose["swell"]) + Vector2(1, 0.4))
	return c.image


## A point `p` given relative to the feet at full size, placed for this size.
func _at(p: Vector2) -> Vector2:
	return _feet + p * _k


func _draw_front(c: Canvas, pose: Dictionary, front: bool) -> void:
	var body: Vector2 = pose["body"]
	var swell: float = pose["swell"]
	var step: float = pose["step"]
	# Stubby legs under the belly.
	for side: float in [-1.0, 1.0]:
		var lift: float = maxf(step * side, 0.0) * 1.5
		c.part()
		c.capsule(_at(Vector2(4.0 * side, -6)), _at(Vector2(4.5 * side, -1.5 - lift)), 1.8 * _k + 0.3, P.BLOAT, -0.1)
		c.part()
		c.ellipse(_at(Vector2(4.5 * side, -1.0 - lift)), Vector2(2.2, 1.2) * _k + Vector2(0.3, 0.2), P.BLOAT, 0.0, -0.12)
	# The belly: a huge round sack, darker below, with veins and glowing gas sacs.
	var belly: Vector2 = _at(Vector2(0, -12.5) + body)
	var radius: Vector2 = Vector2(9.5, 8.6) * _k * swell
	c.part()
	c.ellipse(belly, radius, P.BLOAT, 0.0, -0.02)
	_veins(c, belly, radius, front)
	_sacs(c, belly, radius, float(pose["glow"]), front)
	# Short arms hanging at the sides (raised in the wind-up, thrown out in the slam).
	var arms: float = pose["arms"]
	for side: float in [-1.0, 1.0]:
		var shoulder: Vector2 = belly + Vector2(radius.x * 0.75 * side, -radius.y * 0.35)
		var hand: Vector2 = shoulder + Vector2(2.0 * side, 4.0 - arms * 6.0) * _k
		c.part()
		c.capsule(shoulder, hand, 1.3 * _k + 0.3, P.BLOAT, 0.0)
		c.part()
		c.ellipse(hand, Vector2(1.5, 1.3) * _k + Vector2(0.3, 0.3), P.BLOAT, 0.0, 0.04)
	# The small head sunk into the top of the belly.
	var head: Vector2 = belly + Vector2(0, -radius.y - 1.2 * _k)
	c.part()
	c.ellipse(head, Vector2(3.6, 3.2) * _k + Vector2(0.4, 0.4), P.BLOAT, 0.0, 0.05)
	if front:
		var e: Vector2i = Vector2i(head.round())
		var gap: int = 1 if _k < 1.0 else 2
		c.px(e.x - gap, e.y, _eyes[2])
		c.px(e.x + gap - (0 if _k < 1.0 else 1), e.y, _eyes[2])
		if _k >= 1.0:
			c.rect(Rect2i(e.x - 1, e.y + 2, 2, 1), P.OUTLINE)  # a slack, drooling mouth
			c.px(e.x, e.y + 3, P.GAS[2])


func _draw_side(c: Canvas, pose: Dictionary) -> void:
	var body: Vector2 = pose["body"]
	var swell: float = pose["swell"]
	var step: float = pose["step"]
	var lean: float = pose["lean"]
	for side: float in [-1.0, 1.0]:
		var lift: float = maxf(step * side, 0.0) * 1.5
		c.part()
		c.capsule(_at(Vector2(side * 2.0 - 1.0, -6)), _at(Vector2(side * 3.0 - 1.0 + step * side, -1.5 - lift)), 1.8 * _k + 0.3, P.BLOAT,
			-0.1 if side > 0 else -0.2)
		c.part()
		c.ellipse(_at(Vector2(side * 3.0 + step * side, -1.0 - lift)), Vector2(2.4, 1.2) * _k + Vector2(0.3, 0.2), P.BLOAT, 0.0, -0.12)
	var belly: Vector2 = _at(Vector2(1.0 + lean, -12.5) + body)
	var radius: Vector2 = Vector2(9.0, 8.6) * _k * swell
	c.part()
	c.ellipse(belly, radius, P.BLOAT, 0.0, -0.02)
	_veins(c, belly, radius, true)
	_sacs(c, belly, radius, float(pose["glow"]), true)
	var arms: float = pose["arms"]
	var shoulder: Vector2 = belly + Vector2(radius.x * 0.2, -radius.y * 0.3)
	var hand: Vector2 = shoulder + Vector2(3.0 + maxf(-arms, 0.0) * 3.0, 4.0 - arms * 6.0) * _k
	var head: Vector2 = belly + Vector2(radius.x * 0.45, -radius.y - 0.6 * _k)
	c.part()
	c.ellipse(head, Vector2(3.4, 3.0) * _k + Vector2(0.4, 0.4), P.BLOAT, 0.0, 0.05)
	var e: Vector2i = Vector2i((head + Vector2(1.5, 0) * _k).round())
	c.px(e.x, e.y, _eyes[2])
	c.part()
	c.capsule(shoulder, hand, 1.3 * _k + 0.3, P.BLOAT, 0.0)
	c.part()
	c.ellipse(hand, Vector2(1.5, 1.3) * _k + Vector2(0.3, 0.3), P.BLOAT, 0.0, 0.04)


## Dark veins over the stretched skin.
func _veins(c: Canvas, belly: Vector2, radius: Vector2, front: bool) -> void:
	if _k < 1.0:
		return
	var lines: Array[Array] = [[Vector2(-0.6, -0.5), Vector2(-0.2, 0.1), Vector2(-0.35, 0.6)], [Vector2(0.5, -0.6), Vector2(0.3, 0.0), Vector2(0.55, 0.45)]]
	if not front:
		lines = [[Vector2(-0.1, -0.8), Vector2(0.0, 0.0), Vector2(-0.1, 0.7)]]
	for vein: Array in lines:
		for i: int in vein.size() - 1:
			var a: Vector2 = belly + (vein[i] as Vector2) * radius
			var b: Vector2 = belly + (vein[i + 1] as Vector2) * radius
			c.line(a, b, P.BLOAT[1])


## The gas sacs: soft-glowing blisters (a lit core when `glow` is high). Drawn as soft parts so the
## outline never cuts them out.
func _sacs(c: Canvas, belly: Vector2, radius: Vector2, glow: float, front: bool) -> void:
	var spots: Array[Vector3] = [Vector3(-0.45, 0.15, 1.0), Vector3(0.35, -0.3, 0.8), Vector3(0.15, 0.5, 0.7)]
	if not front:
		spots = [Vector3(-0.3, -0.35, 1.0), Vector3(0.4, 0.1, 0.9), Vector3(-0.1, 0.45, 0.7), Vector3(0.45, -0.5, 0.6)]
	for s: Vector3 in spots:
		var at: Vector2 = belly + Vector2(s.x, s.y) * radius
		var r: float = maxf(1.9 * s.z * _k * (0.9 + glow * 0.3), 0.8)
		c.part(true)
		c.ellipse(at, Vector2(r, r * 0.85), P.GAS.slice(0, 3 + roundi(glow * 2.0)), 0.0, 0.1)
		if glow > 0.6:
			c.px(roundi(at.x - r * 0.3), roundi(at.y - r * 0.3), P.GAS[4])


# ---------------------------------------------------------------- death

## Recoil (pale), swell, swell more (the sacs blaze), burst into a gas cloud, the cloud thins out
## over a burst husk. The Bloatlings are real enemies, spawned by the gameplay.
func _death_frames() -> Array[Image]:
	var frames: Array[Image] = []
	var recoil: Dictionary = _base_pose()
	recoil["body"] = Vector2(0, -1)
	var first: Image = frame("down", recoil)
	Undead.tint(first, Color("eef5e6"), 0.55)
	frames.append(first)
	for s: float in [1.14, 1.28]:
		var swollen: Dictionary = _base_pose()
		swollen["swell"] = s
		swollen["glow"] = 1.0
		frames.append(frame("down", swollen))
	for step: int in 4:
		frames.append(_burst(step))
	return frames


## The burst: a gas cloud billowing out and thinning (dithered away), over the flattened husk.
func _burst(step: int) -> Image:
	var c: Canvas = Canvas.new(_size.x, _size.y)
	# The husk: a burst sack of skin on the ground.
	c.part()
	c.ellipse(_at(Vector2(0, -2.5)), Vector2(8.0, 2.6) * _k + Vector2(0.5, 0.4), P.BLOAT.slice(0, 4), 0.0, -0.1)
	c.part()
	c.ellipse(_at(Vector2(-2, -3.5)), Vector2(2.4, 1.2) * _k + Vector2(0.3, 0.2), P.BLOAT.slice(1, 5), 0.0, 0.0)
	c.finish()
	var img: Image = c.image
	var centre: Vector2 = _at(Vector2(0, -12.0 - step * 1.5))
	var radius: float = (10.0 + step * 2.5) * _k
	for y: int in _size.y:
		for x: int in _size.x:
			var d: float = Vector2(x + 0.5, y + 0.5).distance_to(centre) / radius
			if d > 1.0:
				continue
			var threshold: int = Canvas.BAYER_4[(y % 4) * 4 + (x % 4)]
			if threshold < step * 4 or (d > 0.75 and threshold < 8):
				continue
			var shade: int = 3 if d < 0.35 and step < 2 else (2 if d < 0.7 else 1)
			img.set_pixel(x, y, Color(P.GAS[shade], 0.85))
	# Flecks of skin flung out in the first frame.
	if step == 0:
		for k: int in 6:
			var a: float = TAU * k / 6.0 + 0.4
			var p: Vector2i = Vector2i((centre + Vector2(cos(a), sin(a) * 0.7) * radius * 1.1).round())
			if p.x >= 0 and p.y >= 0 and p.x < _size.x and p.y < _size.y:
				img.set_pixelv(p, P.BLOAT[3])
	return img
