extends RefCounted
## The hero knight (dev-time art generator), redrawn after docs/reference/knight_concept.png: a rounded
## great helm with a gold-trimmed visor and a red crest, grey plate with gold-rimmed pauldrons, a red
## tabard with a torn hem, a brown belt and boots, a longsword in his right hand and a kite shield with
## a gold crest on his left arm (seen from every side: its face from the front and the side, its rimmed
## back from behind). No cape: the tabard carries the red. Every frame is posed in code.
## Frames are 32x40 art px; the feet stand on FEET (the sprite is placed so that is +7 art px below
## the hero's origin, as before).

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")

const SIZE: Vector2i = Vector2i(32, 40)
const FEET: Vector2 = Vector2(16, 35)

const IDLE_BOB: Array[int] = [0, 0, 1, 1]
const WALK_FRAMES: int = 6
const DASH_FRAMES: int = 3
## The shield's field (a dark red-brown, like the concept's) and the helm's centre in the front view.
const FIELD: Array[Color] = [Color("2a0e0e"), Color("4a1a16"), Color("6b2a1e"), Color("8a3a26")]
const HELM: Vector2 = Vector2(16, 11)
const HELM_RADIUS: Vector2 = Vector2(5.6, 5.4)

## The shield's rampant lion at double resolution (image pixels; g gold, h highlight, d shade).
const LION: Array[String] = [
	".hh.....",
	"hggh..d.",
	".ggg.g..",
	"..gggg..",
	"..dggg..",
	"...gggd.",
	"..gg.gg.",
	".gd...g.",
	".g....gd",
]
## The lion seen three-quarters on the side view's squeezed shield.
const LION_SIDE: Array[String] = [
	".hh..",
	"hgg..",
	".ggg.",
	"..gg.",
	"..dgg",
	"..gg.",
	".gd.g",
	".g..g",
]
const LION_KEYS: Dictionary = {"g": P.GOLD[3], "h": P.GOLD[4], "d": P.GOLD[1]}
## The visor at double resolution: k slit, g / G / d the gold frame (light to dark), h breathing holes.
const VISOR_FRONT: Array[String] = [
	"..hhhhhhhhhhhhhh..",
	".GGGGGGGGGGGGGGGG.",
	"GkkkkkkkkkkkkkkkkG",
	"dkkkkkkkkkkkkkkkkd",
	".dddddddddddddddd.",
	"..................",
	".....s.s....s.s...",
	"....s.s.s..s.s.s..",
	".....s.s....s.s...",
]
const VISOR_SIDE: Array[String] = [
	".hhhhhhhhh",
	"GGGGGGGGGG",
	"kkkkkkkkkk",
	"kkkkkkkkkd",
	"dddddddd..",
	"..........",
	"....s.s...",
	".....s.s..",
]

## Image pixels per art pixel: 2 for the double-resolution sheet the game uses (64x80 frames).
var detail: int = 1


func _init(resolution: int = 1) -> void:
	detail = resolution


## Rows in the order of sheet_layouts.HERO.
func sheet_rows() -> Array[Array]:
	var rows: Array[Array] = []
	for facing: String in ["down", "up", "side"]:
		var idle: Array[Image] = []
		for i: int in IDLE_BOB.size():
			idle.append(frame(facing, _idle_pose(i)))
		rows.append(idle)
	for facing: String in ["down", "up", "side"]:
		var walk: Array[Image] = []
		for i: int in WALK_FRAMES:
			walk.append(frame(facing, _walk_pose(i)))
		rows.append(walk)
	for facing: String in ["down", "up", "side"]:
		var attack: Array[Image] = []
		for i: int in 4:
			attack.append(frame(facing, _attack_pose(facing, i)))
		rows.append(attack)
	rows.append(_death_frames())
	for facing: String in ["down", "up", "side"]:
		var dash: Array[Image] = []
		for i: int in DASH_FRAMES:
			dash.append(frame(facing, _dash_pose(facing, i)))
		rows.append(dash)
	return rows


# ---------------------------------------------------------------- poses

func _base_pose() -> Dictionary:
	return {
		"bob": 0, "lift_l": 0.0, "lift_r": 0.0, "stride": 0.0, "arm": 0.0,
		"crest": 0.0, "lean": Vector2.ZERO, "kneel": 0.0, "hem": 0.0,
		# The sword: hand position relative to the default, blade angle in degrees (0 = right, 90 = down).
		"hand": Vector2.ZERO, "angle": -1000.0, "sword_behind": false, "shield_up": 0.0,
	}


func _idle_pose(i: int) -> Dictionary:
	var pose: Dictionary = _base_pose()
	pose["bob"] = IDLE_BOB[i]
	pose["crest"] = [0.0, 0.5, 1.0, 0.5][i]
	pose["hem"] = [0.0, 0.5, 1.0, 0.5][i]
	return pose


func _walk_pose(i: int) -> Dictionary:
	var t: float = TAU * i / WALK_FRAMES
	var pose: Dictionary = _base_pose()
	pose["stride"] = sin(t)
	pose["lift_l"] = maxf(sin(t), 0.0)
	pose["lift_r"] = maxf(-sin(t), 0.0)
	pose["bob"] = -1 if absf(sin(t)) < 0.6 else 0
	pose["arm"] = -sin(t)
	pose["hem"] = 1.0 + 0.6 * cos(t)
	pose["crest"] = 1.0 + 0.5 * cos(t)
	return pose


## 0: wind-up (sword cocked back), 1: the cut, 2: follow-through, 3: recover. The same frames, timing
## and reach as before the redraw (sheet_layouts.HERO's fps; the hitbox is not drawn).
func _attack_pose(facing: String, i: int) -> Dictionary:
	var pose: Dictionary = _base_pose()
	pose["hem"] = [0.0, 1.5, 2.0, 1.0][i]
	pose["crest"] = [0.0, 1.5, 2.0, 1.0][i]
	match facing:
		"down":
			pose["hand"] = [Vector2(-1, -9), Vector2(2, 1), Vector2(10, 0), Vector2(3, -1)][i]
			pose["angle"] = [-115.0, 75.0, 25.0, 100.0][i]
			pose["lean"] = [Vector2(0, -1), Vector2(0, 1), Vector2(0, 1), Vector2.ZERO][i]
			pose["shield_up"] = [0.0, 1.0, 1.0, 0.5][i]
		"up":
			pose["hand"] = [Vector2(1, -8), Vector2(-3, -12), Vector2(-11, -8), Vector2(-3, -3)][i]
			pose["angle"] = [-40.0, -95.0, -160.0, -120.0][i]
			pose["sword_behind"] = i in [1, 2]
			pose["lean"] = [Vector2(0, 1), Vector2(0, -1), Vector2(0, -1), Vector2.ZERO][i]
		"side":
			pose["hand"] = [Vector2(-6, -8), Vector2(3, -5), Vector2(4, 0), Vector2(2, -1)][i]
			pose["angle"] = [-140.0, -15.0, 40.0, 70.0][i]
			pose["lean"] = [Vector2(-1, 0), Vector2(1, 0), Vector2(2, 1), Vector2(1, 0)][i]
			pose["stride"] = [-0.3, 0.6, 0.9, 0.5][i]
	return pose


## The dash: a crouch, the full lunge behind the raised shield (sword trailing), a settle.
func _dash_pose(facing: String, i: int) -> Dictionary:
	var pose: Dictionary = _base_pose()
	var reach: float = [0.5, 1.0, 0.6][i]
	pose["shield_up"] = reach
	pose["crest"] = 2.0 * reach
	pose["hem"] = 2.0 * reach
	match facing:
		"down":
			pose["lean"] = Vector2(0, roundf(reach))
			pose["bob"] = 1
			pose["lift_l"] = reach
			pose["hand"] = Vector2(-1, -3) * reach
			pose["angle"] = -120.0
		"up":
			pose["lean"] = Vector2(0, -roundf(reach))
			pose["lift_r"] = reach
			pose["hand"] = Vector2(1, 2) * reach
			pose["angle"] = 70.0
		"side":
			pose["lean"] = Vector2(roundf(2.0 * reach), 1)
			pose["stride"] = 1.0 * reach
			pose["hand"] = Vector2(-6, -2) * reach
			pose["angle"] = 190.0
	return pose


# ---------------------------------------------------------------- frames

func frame(facing: String, pose: Dictionary) -> Image:
	var c: Canvas = Canvas.new(SIZE.x, SIZE.y, detail)
	match facing:
		"down":
			_draw_down(c, pose)
		"up":
			_draw_up(c, pose)
		_:
			_draw_side(c, pose)
	c.finish()
	c.ground_shadow(FEET + Vector2(0, -0.5), Vector2(7.5, 2.4))
	return c.image


func _draw_down(c: Canvas, pose: Dictionary) -> void:
	var up: Vector2 = Vector2(0, pose["bob"]) + (pose["lean"] as Vector2)
	var kneel: float = pose["kneel"]
	_legs_front(c, pose, up)
	_torso_front(c, up, kneel, pose["hem"])
	# Shield arm (the hero's left = screen right): the kite shield's face.
	var shield_center: Vector2 = Vector2(22.0, 24) + up + Vector2(0, -2.0 * float(pose["shield_up"]))
	c.part()
	c.capsule(Vector2(21, 19.5) + up, shield_center + Vector2(-1, -2), 1.5, P.STEEL, -0.05)
	_kite_face(c, shield_center, 1.0)
	_pauldron(c, Vector2(21.4, 18.2) + up, false)
	_pauldron(c, Vector2(10.6, 18.2) + up, false)
	_helm(c, HELM + up, "down", pose["crest"])
	_sword_arm(c, Vector2(10.8, 19.5) + up, Vector2(10.4, 26.5) + up + _arm_offset(pose), pose)


func _draw_up(c: Canvas, pose: Dictionary) -> void:
	var up: Vector2 = Vector2(0, pose["bob"]) + (pose["lean"] as Vector2)
	var hand: Vector2 = Vector2(22, 26.5) + up + _arm_offset(pose)
	if pose["sword_behind"]:
		_sword(c, hand, pose)
	_legs_front(c, pose, up)
	# The back of the plate under the tabard's back panel.
	c.part()
	c.ellipse(Vector2(16, 21) + up, Vector2(5.2, 4.4), P.STEEL)
	_tabard(c, up, float(pose["hem"]), true)
	# The shield on the left arm (screen left), seen from behind: its rimmed wooden back and straps.
	c.part()
	c.capsule(Vector2(11, 19.5) + up, Vector2(10, 23) + up, 1.5, P.STEEL, -0.05)
	_kite_back(c, Vector2(9.4, 24) + up + Vector2(0, -2.0 * float(pose["shield_up"])))
	c.part()
	c.capsule(Vector2(21, 19.5) + up, hand + Vector2(0, -0.5), 1.5, P.STEEL, -0.05)
	c.part()
	c.ellipse(hand, Vector2(1.6, 1.5), P.DARK_STEEL, 0.0, 0.1)
	_pauldron(c, Vector2(10.6, 18.2) + up, true)
	_pauldron(c, Vector2(21.4, 18.2) + up, true)
	_helm(c, HELM + up, "up", pose["crest"])
	if not pose["sword_behind"]:
		_sword(c, hand, pose)


func _draw_side(c: Canvas, pose: Dictionary) -> void:
	var up: Vector2 = Vector2(0, pose["bob"]) + (pose["lean"] as Vector2)
	var stride: float = pose["stride"]
	# Legs: the far leg darker, then the near leg.
	var hip: Vector2 = Vector2(16, 27) + up
	_leg(c, hip + Vector2(0.5, 0), Vector2(16 - stride * 3.5, FEET.y - 1.5 - maxf(-stride, 0.0) * 1.2), P.DARK_STEEL, true)
	_leg(c, hip, Vector2(16 + stride * 3.5, FEET.y - 1.5 - maxf(stride, 0.0) * 1.2), P.STEEL, true)
	# Torso in profile with the tabard over it, belted.
	c.part()
	c.ellipse(Vector2(16, 21) + up, Vector2(4.2, 4.4), P.STEEL)
	c.part()
	var hem: float = pose["hem"]
	var tabard: PackedVector2Array = PackedVector2Array([Vector2(13.4, 18.4) + up, Vector2(19.2, 19.0) + up,
		Vector2(19.8, 28.6) + up, Vector2(18.2, 27.8) + up, Vector2(16.6, 28.8) + up, Vector2(15.0, 27.8) + up,
		Vector2(13.2 - hem * 0.6, 28.6) + up])
	c.polygon(tabard, P.TABARD, Vector3(0.2, 0.1, 1))
	_belt(c, Rect2i(Vector2i(Vector2(13, 24) + up), Vector2i(7, 2)), Vector2i(Vector2(18, 24) + up))
	_helm(c, Vector2(16.5, 11) + up, "side", pose["crest"])
	_pauldron(c, Vector2(15.6, 18.4) + up, false)
	# The far arm holds the kite shield out in front of the chest, its face turned three-quarters.
	var shield_center: Vector2 = Vector2(21.4, 23.2) + up + Vector2(0, -2.0 * float(pose["shield_up"]))
	_kite_face(c, shield_center, 0.62)
	var hand: Vector2 = Vector2(17.5, 25.5) + up + _arm_offset(pose)
	c.part()
	c.capsule(Vector2(15.5, 19.5) + up, hand, 1.5, P.STEEL, 0.05)
	c.part()
	c.ellipse(hand, Vector2(1.6, 1.5), P.DARK_STEEL, 0.0, 0.1)
	_sword(c, hand, pose)


# ---------------------------------------------------------------- body parts

func _legs_front(c: Canvas, pose: Dictionary, up: Vector2) -> void:
	var kneel: float = pose["kneel"]
	var hip_y: float = 27.0 + up.y * 0.5 + kneel
	_leg(c, Vector2(14, hip_y), Vector2(13.6, FEET.y - 1.5 - float(pose["lift_l"]) * 1.6), P.STEEL, false)
	_leg(c, Vector2(18, hip_y), Vector2(18.4, FEET.y - 1.5 - float(pose["lift_r"]) * 1.6), P.STEEL, false)


## A short greave over a tall brown boot.
func _leg(c: Canvas, hip: Vector2, foot: Vector2, ramp: Array, side: bool) -> void:
	c.part()
	c.capsule(hip, hip.lerp(foot, 0.45), 1.7, ramp)
	c.part()
	c.capsule(hip.lerp(foot, 0.45), foot + Vector2(0, -0.6), 1.8, P.LEATHER)
	c.part()
	var toe: Vector2 = Vector2(1.0, 0) if side else Vector2.ZERO
	c.ellipse(foot + toe * 0.6, Vector2(2.3 if side else 2.0, 1.4), P.LEATHER, 0.0, 0.05)


func _torso_front(c: Canvas, up: Vector2, kneel: float, hem: float) -> void:
	var o: Vector2 = up + Vector2(0, kneel * 0.5)
	c.part()
	c.ellipse(Vector2(16, 21) + o, Vector2(5.2, 4.4), P.STEEL)
	_tabard(c, o, hem, false)
	_belt(c, Rect2i(Vector2i(12, 24) + Vector2i(o.round()), Vector2i(8, 2)), Vector2i(16, 24) + Vector2i(o.round()))


## The red tabard, its hem torn into points (stirring with `hem`); from behind, a plain back panel.
func _tabard(c: Canvas, o: Vector2, hem: float, back: bool) -> void:
	c.part()
	var sway: float = hem * 0.4
	c.polygon(PackedVector2Array([Vector2(12.4, 18.2) + o, Vector2(19.6, 18.2) + o, Vector2(20.4, 28.4) + o,
		Vector2(19.0 + sway, 27.4) + o, Vector2(17.6, 28.8) + o, Vector2(16.0, 27.6) + o, Vector2(14.4, 28.8) + o,
		Vector2(13.0 - sway, 27.4) + o, Vector2(11.6, 28.4) + o]), P.TABARD, Vector3(-0.15, -0.1, 1))
	if back:
		c.line(Vector2(16, 19) + o, Vector2(16, 23) + o, P.TABARD[1], c.detail > 1)
	if c.detail > 1:
		# Folds falling from the belt and a gold trim along the neckline.
		for x: float in [13.9, 18.1]:
			c.line(Vector2(x, 26.2) + o, Vector2(x + (x - 16.0) * 0.08, 28.0) + o, P.TABARD[1], true)
		c.line(Vector2(12.9, 18.4) + o, Vector2(19.1, 18.4) + o, P.GOLD[2], true)


## The brown belt with a steel buckle at `buckle`.
func _belt(c: Canvas, band: Rect2i, buckle: Vector2i) -> void:
	c.rect(Rect2i(band.position, Vector2i(band.size.x, 1)), P.LEATHER[2])
	c.rect(Rect2i(band.position + Vector2i(0, 1), Vector2i(band.size.x, 1)), P.LEATHER[1])
	c.px(buckle.x, buckle.y, P.STEEL[5])
	c.px(buckle.x, buckle.y + 1, P.STEEL[3])


## A round plate pauldron with a gold rim along its lower edge (from behind too).
func _pauldron(c: Canvas, center: Vector2, back: bool) -> void:
	c.part()
	c.ellipse(center, Vector2(3.0, 2.6), P.STEEL, 0.0, 0.08)
	var rim: int = roundi(center.y + 2.0)
	for x: int in range(roundi(center.x - 2.6), roundi(center.x + 2.6) + 1):
		if c.is_filled(x, rim):
			c.px(x, rim, P.GOLD[2] if back else P.GOLD[3])


## The rounded great helm: a gold-trimmed visor slit, breathing holes, a red crest on the crown from
## brow to nape; a gorget below.
func _helm(c: Canvas, center: Vector2, facing: String, crest_sway: float) -> void:
	c.part()
	c.rect(Rect2i(roundi(center.x) - 3, roundi(center.y) + 5, 7, 2), P.DARK_STEEL[2])
	c.rect(Rect2i(roundi(center.x) - 3, roundi(center.y) + 6, 7, 1), P.DARK_STEEL[1])
	c.part()
	c.ellipse(center, HELM_RADIUS, P.STEEL, 0.0, -0.06)
	var cx: int = roundi(center.x)
	var cy: int = roundi(center.y)
	if c.detail > 1:
		_helm_fine(c, cx, cy, facing)
	match "" if c.detail > 1 else facing:
		"":
			pass
		"down":
			# The visor: a dark slit framed in gold, the brow lit, breathing holes below.
			c.rect(Rect2i(cx - 4, cy, 9, 1), P.OUTLINE)
			c.rect(Rect2i(cx - 4, cy - 1, 9, 1), P.GOLD[3])
			c.rect(Rect2i(cx - 3, cy + 1, 7, 1), P.GOLD[1])
			c.px(cx - 5, cy, P.GOLD[2])
			c.px(cx + 5, cy, P.GOLD[2])
			c.rect(Rect2i(cx, cy + 2, 1, 3), P.STEEL[1])
			for hole: int in [-2, 2]:
				c.px(cx + hole, cy + 3, P.STEEL[1])
		"up":
			c.rect(Rect2i(cx - 3, cy + 3, 7, 1), P.STEEL[1])
		_:
			c.rect(Rect2i(cx + 1, cy, 5, 1), P.OUTLINE)
			c.rect(Rect2i(cx + 1, cy - 1, 5, 1), P.GOLD[3])
			c.rect(Rect2i(cx + 1, cy + 1, 4, 1), P.GOLD[1])
			c.px(cx + 3, cy + 3, P.STEEL[1])
	# The crest, last so it sits on the crown.
	c.part()
	match facing:
		"down":
			c.polygon(PackedVector2Array([center + Vector2(-1.4, -4.2), center + Vector2(-1.8, -7.0),
				center + Vector2(-0.4, -8.2 - crest_sway * 0.4), center + Vector2(1.2, -7.4), center + Vector2(1.8, -8.0),
				center + Vector2(1.6, -4.2)]), P.TABARD, Vector3(-0.2, -0.5, 1))
		"up":
			c.polygon(PackedVector2Array([center + Vector2(-1.6, -7.6), center + Vector2(1.6, -7.6),
				center + Vector2(1.2, 1.0), center + Vector2(-1.2, 1.0)]), P.TABARD, Vector3(0, -0.6, 1))
		_:
			c.polygon(PackedVector2Array([center + Vector2(2.4, -4.4), center + Vector2(1.2, -7.4),
				center + Vector2(-1.6, -8.0), center + Vector2(-4.4 - crest_sway, -6.6), center + Vector2(-5.8 - crest_sway, -3.4),
				center + Vector2(-3.6, -3.4), center + Vector2(-1.0, -5.0)]), P.TABARD, Vector3(-0.2, -0.6, 1))
	if c.detail > 1:
		_crest_strands(c, center, facing, crest_sway)


func _arm_offset(pose: Dictionary) -> Vector2:
	return (pose["hand"] as Vector2) + Vector2(0, float(pose["arm"]) * 1.2)


## The sword arm (front view, screen left) and the sword in its hand.
func _sword_arm(c: Canvas, shoulder: Vector2, hand: Vector2, pose: Dictionary) -> void:
	if pose["sword_behind"]:
		_sword(c, hand, pose)
	c.part()
	var elbow: Vector2 = shoulder.lerp(hand, 0.5) + Vector2(-0.8, 0)
	c.capsule(shoulder, elbow, 1.6, P.STEEL, -0.05)
	c.capsule(elbow, hand, 1.5, P.STEEL, -0.05)
	c.part()
	c.ellipse(hand, Vector2(1.6, 1.5), P.DARK_STEEL, 0.0, 0.1)
	if not pose["sword_behind"]:
		_sword(c, hand, pose)


## A longsword held at `hand`: steel crossguard and pommel, leather grip, a broad bright blade.
func _sword(c: Canvas, hand: Vector2, pose: Dictionary) -> void:
	var angle: float = pose["angle"]
	if angle < -999.0:
		angle = 100.0  # resting: point down, slightly forward
	var dir: Vector2 = Vector2.from_angle(deg_to_rad(angle))
	var across: Vector2 = Vector2(-dir.y, dir.x)
	c.part()
	c.capsule(hand - dir * 1.6, hand + dir * 0.4, 0.7, P.LEATHER)
	c.px(floori(hand.x - dir.x * 2.4), floori(hand.y - dir.y * 2.4), P.STEEL[4])
	var guard: Vector2 = hand + dir * 1.4
	c.line(guard - across * 2.4, guard + across * 2.4, P.STEEL[3])
	c.px(floori(guard.x - across.x * 1.2), floori(guard.y - across.y * 1.2), P.STEEL[5])
	c.part()
	c.capsule(hand + dir * 2.6, hand + dir * 10.5, 0.95, P.STEEL, 0.2)
	c.line(hand + dir * 3.0, hand + dir * 9.5, P.STEEL[5])


## The kite shield's face: a steel rim, the red-brown field and a gold crest (a rampant beast, cut
## down to a few pixels). `width` < 1 squeezes it for the three-quarter side view.
func _kite_face(c: Canvas, center: Vector2, width: float) -> void:
	var w: float = 3.4 * width
	c.part()
	c.polygon(_kite(center, w, 1.0), P.STEEL, Vector3(-0.3, -0.3, 1))
	c.polygon(_kite(center, w - 1.0, 0.82), FIELD, Vector3(-0.1, -0.2, 1))
	if c.detail > 1:
		c.fine_grid(LION if width >= 0.9 else LION_SIDE, center - Vector2(4.0 if width >= 0.9 else 2.5, 4.5) / c.detail, LION_KEYS)
		return
	var cx: int = roundi(center.x)
	var cy: int = roundi(center.y)
	for p: Vector2i in [Vector2i(0, -3), Vector2i(1, -2), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(1, 2)]:
		var x: int = cx + (p.x if width >= 0.9 else mini(p.x, 0))
		c.px(x, cy + p.y, P.GOLD[3] if p.y < 0 else P.GOLD[2])


## The kite shield's back on the arm (seen from behind): a steel rim round a wooden back and straps.
func _kite_back(c: Canvas, center: Vector2) -> void:
	c.part()
	c.polygon(_kite(center, 3.4, 1.0), P.STEEL, Vector3(-0.2, -0.2, 1))
	c.polygon(_kite(center, 2.4, 0.82), P.WOOD, Vector3(-0.2, -0.2, 1))
	c.line(center + Vector2(-2.4, -1.5), center + Vector2(2.4, -1.5), P.LEATHER[1])
	c.line(center + Vector2(-2.0, 1.0), center + Vector2(2.0, 1.0), P.LEATHER[1])


## A kite shape: a flat top, sides tapering to a point, `half_width` wide each side, scaled by `size`.
func _kite(center: Vector2, half_width: float, size: float) -> PackedVector2Array:
	return PackedVector2Array([center + Vector2(-half_width, -4.6 * size), center + Vector2(half_width, -4.6 * size),
		center + Vector2(half_width, 0.2 * size), center + Vector2(0, 6.2 * size), center + Vector2(-half_width, 0.2 * size)])


# ---------------------------------------------------------------- death

## Hit (pale), buckling, kneeling on the planted sword, then lying face down; the last frame holds.
func _death_frames() -> Array[Image]:
	var frames: Array[Image] = []
	var hit: Dictionary = _base_pose()
	hit["lean"] = Vector2(0, -1)
	hit["hem"] = 1.5
	var first: Image = frame("down", hit)
	_tint(first, Color("ffe6dc"), 0.3)
	frames.append(first)
	var buckle: Dictionary = _base_pose()
	buckle["bob"] = 2
	buckle["kneel"] = 1.5
	buckle["hand"] = Vector2(2, 2)
	buckle["angle"] = 95.0
	frames.append(frame("down", buckle))
	var kneel: Dictionary = _base_pose()
	kneel["bob"] = 4
	kneel["kneel"] = 3.0
	kneel["hand"] = Vector2(3, 1)
	kneel["angle"] = 88.0
	kneel["lift_l"] = 2.0
	kneel["lift_r"] = 2.0
	frames.append(frame("down", kneel))
	frames.append(_lying(0))
	frames.append(_lying(1))
	var still: Image = _lying(1)
	_tint(still, P.OUTLINE, 0.3)
	frames.append(still)
	return frames


## The side pose turned onto the ground (rotating by 90 degrees keeps the pixel grid intact).
func _lying(settle: int) -> Image:
	var c: Canvas = Canvas.new(SIZE.x, SIZE.y, detail)
	var pose: Dictionary = _base_pose()
	pose["hem"] = 1.0
	pose["angle"] = 20.0 if settle == 0 else 5.0
	pose["hand"] = Vector2(3, -3)
	_draw_side(c, pose)
	c.finish()
	var body: Image = c.image
	body.rotate_90(CLOCKWISE)
	var used: Rect2i = body.get_used_rect()
	var out: Canvas = Canvas.new(SIZE.x, SIZE.y, detail)
	var at: Vector2i = Vector2i(floori((SIZE.x * detail - used.size.x) / 2.0), (int(FEET.y) + 1 + settle) * detail - used.size.y)
	out.image.blend_rect(body, used, at)
	out.ground_shadow(Vector2(16, FEET.y - 1), Vector2(12, 2.6))
	return out.image


func _tint(img: Image, color: Color, amount: float) -> void:
	for y: int in img.get_height():
		for x: int in img.get_width():
			var c: Color = img.get_pixel(x, y)
			if c.a > 0.5:
				img.set_pixel(x, y, Color(c.lerp(color, amount), c.a))


# ---------------------------------------------------------------- double-resolution detail

## The visor, breathing holes and the gorget's mail drawn in image pixels.
func _helm_fine(c: Canvas, cx: int, cy: int, facing: String) -> void:
	var keys: Dictionary = {"h": P.GOLD[3], "G": P.GOLD[2], "d": P.GOLD[1], "k": P.OUTLINE, "s": P.STEEL[1]}
	match facing:
		"down":
			c.fine_grid(VISOR_FRONT, Vector2(cx - 4.5, cy - 1.0), keys)
			c.line(Vector2(cx + 0.25, cy + 2.0), Vector2(cx + 0.25, cy + 4.5), P.STEEL[2], true)
		"up":
			c.line(Vector2(cx - 3.0, cy + 3.25), Vector2(cx + 4.0, cy + 3.25), P.STEEL[1], true)
			c.line(Vector2(cx - 2.5, cy + 2.75), Vector2(cx + 3.5, cy + 2.75), P.STEEL[4], true)
		_:
			c.fine_grid(VISOR_SIDE, Vector2(cx + 1.0, cy - 1.0), keys)
	# The mail at the gorget: rows of rings, offset every other row.
	for fy: int in 4:
		for fx: int in 14:
			if (fx + fy) % 2 == 0:
				c.fine_px(Vector2(cx - 3, cy + 5) + Vector2(fx, fy) / c.detail, P.DARK_STEEL[3] if fy % 2 == 0 else P.DARK_STEEL[1])


## Feather strands through the crest.
func _crest_strands(c: Canvas, center: Vector2, facing: String, sway: float) -> void:
	match facing:
		"down":
			c.line(center + Vector2(-0.7, -4.4), center + Vector2(-0.6, -7.4 - sway * 0.3), P.TABARD[2], true)
			c.line(center + Vector2(0.9, -4.4), center + Vector2(1.2, -7.2), P.TABARD[2], true)
			c.line(center + Vector2(-1.2, -5.6), center + Vector2(-0.8, -7.8), P.TABARD[4], true)
		"up":
			c.line(center + Vector2(-0.5, -7.2), center + Vector2(-0.5, 0.6), P.TABARD[2], true)
			c.line(center + Vector2(0.75, -7.2), center + Vector2(0.75, 0.6), P.TABARD[4], true)
		_:
			c.line(center + Vector2(1.6, -5.0), center + Vector2(-4.0 - sway, -5.8), P.TABARD[2], true)
			c.line(center + Vector2(0.8, -6.6), center + Vector2(-3.6 - sway, -6.4), P.TABARD[4], true)
