extends RefCounted
## The Shieldbearer (dev-time art generator): a drowned soldier in rust-eaten mail and a dented
## kettle helm (red eyes behind the visor slit), carrying a huge tower shield of tarred planks bound in
## rusted iron, a pale drowned skull painted on it. The shield is always on the side it walks toward,
## so the player reads at a glance where shots will be blocked: from the front it hides the whole
## body; from behind only its rim shows; from the side it is a thick slab in front. It bashes with it.
## Frames are 32x32 art px; the feet stand on FEET, like the Ghoul.

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")
const Undead: GDScript = preload("res://tools/art/undead_fx.gd")

const SIZE: Vector2i = Vector2i(32, 32)
const FEET: Vector2 = Vector2(16, 28)
const WALK_FRAMES: int = 6
const ATTACK_FRAMES: int = 6


## Rows in the order of sheet_layouts.SHIELDBEARER.
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

## shield: the shield's offset toward the front (bash); stride: -1..1; body: the torso's bob.
func _base_pose() -> Dictionary:
	return {"body": Vector2.ZERO, "shield": 0.0, "stride": 0.0, "smear": false}


func _idle_pose(i: int) -> Dictionary:
	var pose: Dictionary = _base_pose()
	pose["body"] = Vector2(0, [0.0, 0.0, 1.0, 1.0][i])
	return pose


func _walk_pose(i: int) -> Dictionary:
	var t: float = TAU * i / WALK_FRAMES
	var pose: Dictionary = _base_pose()
	pose["stride"] = sin(t)
	pose["body"] = Vector2(0, 1.0 if absf(sin(t)) > 0.6 else 0.0)
	return pose


## 0-2: the shield is drawn back (the wind-up), 3: bashed forward, 4-5: recover.
func _attack_pose(i: int) -> Dictionary:
	var pose: Dictionary = _base_pose()
	pose["shield"] = [-1.0, -2.0, -2.5, 4.0, 2.0, 0.5][i]
	pose["body"] = Vector2(0, [0.0, 1.0, 1.0, 0.0, 0.0, 0.0][i])
	pose["smear"] = i == 3
	return pose


# ---------------------------------------------------------------- frames

func frame(facing: String, pose: Dictionary) -> Image:
	var c: Canvas = Canvas.new(SIZE.x, SIZE.y)
	match facing:
		"down":
			_draw_front(c, pose)
		"up":
			_draw_back(c, pose)
		_:
			_draw_side(c, pose)
	c.finish()
	c.ground_shadow(FEET + Vector2(0, -0.5), Vector2(7.5, 2.2))
	return c.image


## Facing the camera: helm over the shield's top edge, boots below it; the shield hides the rest.
func _draw_front(c: Canvas, pose: Dictionary) -> void:
	var body: Vector2 = pose["body"]
	var stride: float = pose["stride"]
	_legs(c, body, stride, false)
	c.part()
	c.ellipse(Vector2(16, 17) + body, Vector2(5.0, 4.5), P.IRON, 0.0, 0.0)  # the mailed shoulders behind
	_helm(c, Vector2(16, 10.5) + body, "down")
	_shield_face(c, Vector2(16, 19.5 + float(pose["shield"]) * 0.5) + body, pose["smear"])


## From behind: a mail back and a ragged cloak; the shield's rim sticks out on both sides and over the top.
func _draw_back(c: Canvas, pose: Dictionary) -> void:
	var body: Vector2 = pose["body"]
	var stride: float = pose["stride"]
	# The shield's back, beyond the body: only its iron-bound edges show around it.
	c.part()
	c.rect(Rect2i(9, roundi(12 + body.y), 14, 14), P.WOOD[1])
	c.rect(Rect2i(9, roundi(12 + body.y), 14, 1), P.IRON[4])
	c.rect(Rect2i(9, roundi(12 + body.y), 1, 14), P.IRON[3])
	c.rect(Rect2i(22, roundi(12 + body.y), 1, 14), P.IRON[1])
	_legs(c, body, stride, true)
	c.part()
	c.ellipse(Vector2(16, 18) + body, Vector2(5.0, 5.4), P.IRON.slice(1, 5), 0.0, 0.05)
	for y: int in range(15, 23, 2):
		c.line(Vector2(12, y) + body, Vector2(20, y) + body, P.IRON[1])
	c.line(Vector2(16, 14) + body, Vector2(16, 22) + body, P.IRON[4])  # the lit spine of the mail
	# A short, torn cloak over the shoulders.
	c.part()
	c.polygon(PackedVector2Array([Vector2(12, 14) + body, Vector2(20, 14) + body, Vector2(20.5, 18) + body, Vector2(18.5, 17.5) + body,
		Vector2(16, 19) + body, Vector2(13.5, 17.5) + body, Vector2(11.5, 18) + body]), P.SLATE.slice(1, 5), Vector3(0, -0.2, 1))
	_helm(c, Vector2(16, 10.5) + body, "up")


## Facing right: the body behind, the shield a thick slab held out in front.
func _draw_side(c: Canvas, pose: Dictionary) -> void:
	var body: Vector2 = pose["body"]
	var stride: float = pose["stride"]
	_legs(c, body, stride, true, true)
	c.part()
	c.ellipse(Vector2(15, 18) + body, Vector2(4.0, 5.0), P.IRON, 0.0, 0.0)
	for y: int in range(15, 23, 2):
		c.line(Vector2(12, y) + body, Vector2(18, y) + body, P.IRON[1])
	_helm(c, Vector2(15.5, 10.5) + body, "side")
	var x: float = 20.0 + float(pose["shield"])
	c.part()
	c.block(Rect2(x, 12 + body.y, 3, 1), 15.0, P.RUST, P.WOOD.slice(0, 4), false)
	c.line(Vector2(x + 3, 12 + body.y), Vector2(x + 3, 27 + body.y), P.IRON[3])  # the iron rim catching the light
	c.line(Vector2(x, 12 + body.y), Vector2(x + 3, 12 + body.y), P.IRON[4])
	if pose["smear"]:
		c.part(true)
		for k: int in 3:
			c.line(Vector2(x - 6, 14 + k * 5) + body, Vector2(x - 1, 14 + k * 5) + body, Color(0.85, 0.9, 0.95, 0.5))


func _legs(c: Canvas, body: Vector2, stride: float, dark: bool, side: bool = false) -> void:
	for s: float in [-1.0, 1.0]:
		var hip: Vector2 = Vector2(16 + s * 2.5 * (0.4 if side else 1.0), 22) + Vector2(0, body.y * 0.5)
		var foot: Vector2 = Vector2(16 + s * 2.6 + (stride * s * 2.5 if side else 0.0), FEET.y - 1 - maxf(stride * s, 0.0) * 1.5)
		if side:
			foot.x = 16 + stride * s * 3.0
		c.part()
		c.capsule(hip, foot, 1.5, P.IRON if not dark or s > 0 else P.IRON.slice(0, 4), -0.05)
		c.part()
		c.ellipse(foot + Vector2(0.8 if side else 0.0, 0.3), Vector2(2.0 if side else 1.6, 1.1), P.RUST, 0.0, -0.1)


## A dented kettle helm, rusting; from the front a dark visor slit with two red eyes.
func _helm(c: Canvas, at: Vector2, facing: String) -> void:
	c.part()
	c.ellipse(at, Vector2(3.6, 3.3), P.IRON, 0.0, 0.08)
	c.part()
	c.ellipse(at + Vector2(0, 1.5), Vector2(5.2, 1.3), P.RUST.slice(1, 5), 0.0, 0.0)  # the wide brim
	if facing == "down":
		c.rect(Rect2i(roundi(at.x) - 2, roundi(at.y) + 2, 4, 1), P.OUTLINE)
		c.px(roundi(at.x) - 1, roundi(at.y) + 2, P.EYE_GLOW[2])
		c.px(roundi(at.x) + 1, roundi(at.y) + 2, P.EYE_GLOW[2])
	elif facing == "side":
		c.px(roundi(at.x) + 2, roundi(at.y) + 2, P.EYE_GLOW[2])
	c.px(roundi(at.x) - 1, roundi(at.y) - 2, P.RUST[3])  # rust streaks on the dome
	c.px(roundi(at.x) + 1, roundi(at.y) - 1, P.RUST[2])


## The tower shield seen from the front: tarred planks, iron rim and bands, a pale drowned skull.
func _shield_face(c: Canvas, centre: Vector2, smear: bool) -> void:
	var r: Rect2 = Rect2(centre - Vector2(6.5, 7.5), Vector2(13, 15))
	c.part()
	c.block(Rect2(r.position.x, r.position.y, r.size.x, 1), r.size.y - 1, P.RUST, P.WOOD.slice(0, 4), false)
	for x: int in range(int(r.position.x) + 3, int(r.end.x), 3):
		c.line(Vector2(x, r.position.y + 1), Vector2(x, r.end.y - 1), P.WOOD[0])
	for y: float in [r.position.y + 3.0, r.end.y - 4.0]:
		c.line(Vector2(r.position.x, y), Vector2(r.end.x - 1, y), P.IRON[3])
		c.line(Vector2(r.position.x, y + 1), Vector2(r.end.x - 1, y + 1), P.IRON[1])
	# The rim: lit along the top and the left edge (light from the top-left).
	c.line(r.position, Vector2(r.end.x - 1, r.position.y), P.IRON[4])
	c.line(r.position, Vector2(r.position.x, r.end.y - 1), P.IRON[3])
	c.line(Vector2(r.end.x - 1, r.position.y), r.end - Vector2(1, 1), P.IRON[1])
	# The painted skull.
	var s: Vector2i = Vector2i(centre.round()) + Vector2i(0, -1)
	c.rect(Rect2i(s.x - 2, s.y - 2, 5, 3), P.BONE[2])
	c.rect(Rect2i(s.x - 1, s.y + 1, 3, 1), P.BONE[1])
	c.px(s.x - 1, s.y - 1, P.OUTLINE)
	c.px(s.x + 1, s.y - 1, P.OUTLINE)
	if smear:
		c.part(true)
		for k: int in 3:
			c.line(Vector2(r.position.x + 2 + k * 4, r.end.y + 1), Vector2(r.position.x + 2 + k * 4, r.end.y + 3), Color(0.85, 0.9, 0.95, 0.5))


# ---------------------------------------------------------------- death

## Recoil (pale), the shield sags, the soldier sinks behind it, then crumbles; the shield stays.
func _death_frames() -> Array[Image]:
	var frames: Array[Image] = []
	var recoil: Dictionary = _base_pose()
	recoil["body"] = Vector2(0, -1)
	var first: Image = frame("down", recoil)
	Undead.tint(first, Color("eef5e6"), 0.55)
	frames.append(first)
	# The shield stays planted (its offset cancels the body's drop) while the soldier sinks behind it.
	for drop: float in [2.0, 4.0]:
		var sag: Dictionary = _base_pose()
		sag["body"] = Vector2(0, drop)
		sag["shield"] = -drop * 2.0
		frames.append(frame("down", sag))
	var down: Dictionary = _base_pose()
	down["body"] = Vector2(0, 6)
	down["shield"] = -12.0
	var fallen: Image = frame("down", down)
	frames.append(fallen)
	for step: int in 3:
		var dissolving: Image = fallen.duplicate() as Image
		Undead.crumble(dissolving, step)
		Undead.soul(dissolving, step, Vector2(16, 16))
		frames.append(dissolving)
	return frames
