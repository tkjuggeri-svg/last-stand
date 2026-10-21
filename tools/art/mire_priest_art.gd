extends RefCounted
## The Mire Priest (dev-time art generator): a stooped drowned priest in sodden ochre sackcloth (it
## must pop off the marsh: the player should find it first), a tall mitre of bound reeds, a pale face
## with red eyes, and a crooked staff from whose hook a censer swings, glowing soul-green. Its heal
## is telegraphed: it heaves the staff up and the censer blazes; then a ring of green light spreads.
## Frames are 32x32 art px; the hem stands on FEET, like the Cultist.

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")
const Undead: GDScript = preload("res://tools/art/undead_fx.gd")

const SIZE: Vector2i = Vector2i(32, 32)
const FEET: Vector2 = Vector2(16, 28)
const WALK_FRAMES: int = 6
const ATTACK_FRAMES: int = 6
## The heal: 0-3 raise the staff (the telegraph), 4-5 the pulse.
const HEAL_FRAMES: int = 6


## Rows in the order of sheet_layouts.MIRE_PRIEST.
func sheet_rows() -> Array[Array]:
	var rows: Array[Array] = []
	for facing: String in ["down", "up", "side"]:
		var idle: Array[Image] = []
		for i: int in 4:
			idle.append(frame(facing, _idle_pose(facing, i)))
		rows.append(idle)
	for facing: String in ["down", "up", "side"]:
		var walk: Array[Image] = []
		for i: int in WALK_FRAMES:
			walk.append(frame(facing, _walk_pose(facing, i)))
		rows.append(walk)
	rows.append(_death_frames())
	for facing: String in ["down", "up", "side"]:
		var attack: Array[Image] = []
		for i: int in ATTACK_FRAMES:
			attack.append(frame(facing, _attack_pose(facing, i)))
		rows.append(attack)
	for facing: String in ["down", "up", "side"]:
		var heal: Array[Image] = []
		for i: int in HEAL_FRAMES:
			heal.append(frame(facing, _heal_pose(facing, i)))
		rows.append(heal)
	return rows


# ---------------------------------------------------------------- poses

## hand: the staff hand (the staff runs from `foot` up through it to its hook); censer: where the
## censer hangs from the hook (an offset from the hook); glow: 0-1; ring: the heal pulse (-1 = none).
func _base_pose(facing: String) -> Dictionary:
	var side: bool = facing == "side"
	return {"body": Vector2.ZERO, "sway": 0.0, "glow": 0.4, "ring": -1, "puff": 0,
		"hand": Vector2(22, 19) if not side else Vector2(20, 19), "lift": 0.0, "swing": 0.0, "free": Vector2(11, 20) if not side else Vector2(14, 20)}


func _idle_pose(facing: String, i: int) -> Dictionary:
	var pose: Dictionary = _base_pose(facing)
	pose["body"] = Vector2(0, [0.0, 0.0, 1.0, 1.0][i])
	pose["swing"] = [0.0, 0.5, 0.0, -0.5][i]
	pose["glow"] = [0.35, 0.5, 0.35, 0.5][i]
	pose["puff"] = i
	return pose


## A slow, stooped glide; the censer swings with each step.
func _walk_pose(facing: String, i: int) -> Dictionary:
	var t: float = TAU * i / WALK_FRAMES
	var pose: Dictionary = _base_pose(facing)
	pose["body"] = Vector2(0, 1.0 if absf(sin(t)) > 0.6 else 0.0)
	pose["sway"] = roundf(sin(t))
	pose["swing"] = sin(t) * 0.9
	pose["puff"] = i
	return pose


## A jab with the staff's foot: draw back (0-2), thrust (3), recover.
func _attack_pose(facing: String, i: int) -> Dictionary:
	var pose: Dictionary = _base_pose(facing)
	var side: bool = facing == "side"
	var thrust: Vector2 = Vector2(4, 1) if side else Vector2(0, 3 if facing == "down" else -2)
	if i < 3:
		pose["hand"] = (pose["hand"] as Vector2) - thrust * (i / 3.0) * 0.5
	elif i == 3:
		pose["hand"] = (pose["hand"] as Vector2) + thrust
		pose["swing"] = 1.0
	pose["puff"] = i
	return pose


## The telegraph: the staff rises over the head and the censer blazes brighter (0-3); then the pulse:
## a ring of green light spreads from it (4-5).
func _heal_pose(facing: String, i: int) -> Dictionary:
	var pose: Dictionary = _base_pose(facing)
	var rise: float = minf((i + 1) / 4.0, 1.0)
	pose["lift"] = rise * 7.0
	pose["glow"] = 0.4 + 0.6 * rise
	pose["swing"] = [0.0, 0.6, -0.6, 0.3, 0.0, 0.0][i]
	pose["free"] = (pose["free"] as Vector2).lerp(Vector2(13, 12) if facing != "side" else Vector2(17, 12), rise)
	pose["ring"] = i - 4 if i >= 4 else -1
	pose["puff"] = i
	return pose


# ---------------------------------------------------------------- frames

func frame(facing: String, pose: Dictionary) -> Image:
	var c: Canvas = Canvas.new(SIZE.x, SIZE.y)
	var side: bool = facing == "side"
	var hand: Vector2 = (pose["hand"] as Vector2) + Vector2(0, -float(pose["lift"])) + (pose["body"] as Vector2)
	# The staff: from the ground beside it, up through the hand, to a crooked hook above the head.
	var foot: Vector2 = Vector2(hand.x + (1.0 if not side else 2.0), FEET.y - 0.5 - float(pose["lift"]))
	var hook: Vector2 = hand + Vector2(0.5, -10.0)
	if facing == "up":
		_staff(c, foot, hand, hook)  # seen from behind, the staff is in front of the far shoulder
	_robe(c, pose, facing)
	if facing != "up":
		_staff(c, foot, hand, hook)
	_censer(c, hook, pose)
	# The staff hand over the staff.
	c.part()
	c.ellipse(hand, Vector2(1.4, 1.3), P.BLOAT.slice(2, 6), 0.0, 0.05)
	c.finish()
	_soft(c.image, hook, pose)
	c.ground_shadow(FEET + Vector2(0, -0.5), Vector2(6.5, 2.0))
	return c.image


func _robe(c: Canvas, pose: Dictionary, facing: String) -> void:
	var body: Vector2 = pose["body"]
	var sway: float = pose["sway"]
	var side: bool = facing == "side"
	# A hunched robe flaring to a ragged, wet hem.
	c.part()
	var top: float = 13.0 + body.y
	var hem: float = FEET.y
	var points: PackedVector2Array = PackedVector2Array([Vector2(13.5, top), Vector2(18.5, top), Vector2(21.5 + sway, hem - 1),
		Vector2(20, hem), Vector2(18.5, hem - 1), Vector2(16.5, hem), Vector2(14.5, hem - 1), Vector2(12.5, hem), Vector2(10.5 + sway, hem - 1)])
	if side:
		points = PackedVector2Array([Vector2(13, top + 1), Vector2(18, top), Vector2(20.5 + sway, hem - 1), Vector2(18.5, hem),
			Vector2(16, hem - 1), Vector2(13.5, hem), Vector2(11 + sway, hem - 1), Vector2(11.5, top + 6)])
	c.polygon(points, P.PRIEST_ROBE.slice(0, 5), Vector3(0.15, 0.3, 1), true)
	# Heavy, wet folds down the robe, lit on their left edge.
	for x: float in ([13.5, 16.0, 18.5] if not side else [13.0, 15.5, 18.0]):
		c.line(Vector2(x + sway * 0.5, top + 4), Vector2(x + sway, hem - 2), P.PRIEST_ROBE[1])
		c.line(Vector2(x - 1 + sway * 0.5, top + 5), Vector2(x - 1 + sway, hem - 3), P.PRIEST_ROBE[3])
	# Rope belt and a wet, darker hem.
	c.line(Vector2(13, 20) + body, Vector2(19, 20) + body, P.PRIEST_ROBE[1])
	for x: int in range(11, 22):
		if c.is_filled(x, int(hem) - 1):
			c.px(x, int(hem) - 1, P.PRIEST_ROBE[1])
	if facing == "down":
		# A hanging stole with a green drowned sigil.
		c.line(Vector2(16, top + 2), Vector2(16, hem - 3), P.PRIEST_ROBE[4])
		c.px(16, roundi(top + 6), P.SOUL[2])
	# The free hand (lifted in the heal).
	var free: Vector2 = (pose["free"] as Vector2) + body
	c.part()
	c.capsule(Vector2(14, 15) + body if not side else Vector2(15, 15) + body, free, 1.2, P.PRIEST_ROBE, 0.0)
	c.part()
	c.ellipse(free, Vector2(1.2, 1.1), P.BLOAT.slice(2, 6), 0.0, 0.05)
	# Head: a pale drowned face (from the front), red eyes; the tall mitre of bound reeds.
	var head: Vector2 = Vector2(16 + (1.5 if side else 0.0), 11.5) + body
	c.part()
	c.ellipse(head, Vector2(2.8, 2.7), P.BLOAT.slice(1, 6) if facing != "up" else P.PRIEST_ROBE, 0.0, 0.05)
	if facing == "down":
		c.px(roundi(head.x) - 1, roundi(head.y), P.EYE_GLOW[2])
		c.px(roundi(head.x) + 1, roundi(head.y), P.EYE_GLOW[2])
	elif side:
		c.px(roundi(head.x) + 1, roundi(head.y), P.EYE_GLOW[2])
	c.part()
	c.polygon(PackedVector2Array([head + Vector2(-3, -1.5), head + Vector2(-1.5, -9), head + Vector2(0, -11), head + Vector2(1.5, -9),
		head + Vector2(3, -1.5)]), P.REED, Vector3(-0.4, -0.3, 0.8))
	for k: int in 3:
		c.line(head + Vector2(-2 + k * 2, -2), head + Vector2(-1 + k, -8 + absi(k - 1) * 2), P.REED[1])
	c.line(head + Vector2(-3, -3), head + Vector2(3, -3), P.LILY[2])  # a band of weed around the mitre


func _staff(c: Canvas, foot: Vector2, hand: Vector2, hook: Vector2) -> void:
	c.part()
	c.capsule(foot, hand, 0.6, P.DEAD_WOOD)
	c.capsule(hand, hook, 0.6, P.DEAD_WOOD)
	c.capsule(hook, hook + Vector2(2.5, -0.5), 0.5, P.DEAD_WOOD)
	c.capsule(hook + Vector2(2.5, -0.5), hook + Vector2(3, 1.5), 0.5, P.DEAD_WOOD)


## The censer on its chain, swinging, its slits glowing.
func _censer(c: Canvas, hook: Vector2, pose: Dictionary) -> void:
	var top: Vector2 = hook + Vector2(3, 1.5)
	var at: Vector2 = top + Vector2(float(pose["swing"]) * 2.0, 3.0)
	c.part()
	c.line(top, at - Vector2(0, 1.5), P.IRON[3])
	c.part()
	c.ellipse(at, Vector2(1.8, 1.6), P.BRONZE, 0.0, 0.05)
	c.part(true)
	var glow: float = pose["glow"]
	c.px(roundi(at.x), roundi(at.y), P.SOUL[2 + roundi(glow * 2.0)])
	c.px(roundi(at.x) - 1, roundi(at.y), P.SOUL[2] if glow > 0.6 else P.SOUL[1])


## Soft extras: the censer's smoke and halo, and the heal's ring of light (no outline).
func _soft(img: Image, hook: Vector2, pose: Dictionary) -> void:
	var at: Vector2 = hook + Vector2(3 + float(pose["swing"]) * 2.0, 4.5)
	var puff: int = pose["puff"]
	for k: int in 3:
		var p: Vector2i = Vector2i((at + Vector2(sin(puff + k * 2.1) * 1.5, -2.0 - k * 2.0 - (puff % 2))).round())
		_plot(img, p, Color(P.SOUL[3], 0.55 - k * 0.15))
	var glow: float = pose["glow"]
	if glow > 0.7:
		for k: int in 8:
			var a: float = TAU * k / 8.0
			_plot(img, Vector2i((at + Vector2(cos(a), sin(a)) * 3.0).round()), Color(P.SOUL[3], 0.6))
	var ring: int = pose["ring"]
	if ring >= 0:
		var r: float = 9.0 + ring * 4.0
		for k: int in 28:
			var a: float = TAU * k / 28.0
			_plot(img, Vector2i((Vector2(16, 22) + Vector2(cos(a) * r, sin(a) * r * 0.5)).round()), Color(P.SOUL[4] if k % 2 == 0 else P.SOUL[3], 0.9 - ring * 0.3))


func _plot(img: Image, p: Vector2i, color: Color) -> void:
	if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height():
		img.set_pixelv(p, color)


# ---------------------------------------------------------------- death

## Recoil (pale), the staff falls, the priest sinks to its knees, then crumbles; its soul escapes.
func _death_frames() -> Array[Image]:
	var frames: Array[Image] = []
	var recoil: Dictionary = _base_pose("down")
	recoil["body"] = Vector2(0, -1)
	var first: Image = frame("down", recoil)
	Undead.tint(first, Color("eef5e6"), 0.55)
	frames.append(first)
	var sag: Dictionary = _base_pose("down")
	sag["body"] = Vector2(0, 2)
	sag["glow"] = 0.1
	frames.append(frame("down", sag))
	var kneel: Dictionary = _base_pose("down")
	kneel["body"] = Vector2(0, 5)
	kneel["glow"] = 0.0
	kneel["hand"] = Vector2(24, 25)
	var knelt: Image = frame("down", kneel)
	frames.append(knelt)
	frames.append(knelt.duplicate() as Image)
	for step: int in 3:
		var dissolving: Image = knelt.duplicate() as Image
		Undead.crumble(dissolving, step)
		Undead.soul(dissolving, step, Vector2(16, 20))
		frames.append(dissolving)
	return frames
