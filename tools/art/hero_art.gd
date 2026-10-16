extends RefCounted
## The hero knight (dev-time art generator). Every frame is posed in code: a great helm with a red
## plume, steel cuirass under a red tabard, a dark red cape, a heater shield and a longsword.
## Frames are 32x40 art px; the feet stand on FEET (the sprite is placed so that is +7 art px below
## the hero's origin, as before).

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")

const SIZE: Vector2i = Vector2i(32, 40)
const FEET: Vector2 = Vector2(16, 35)

const IDLE_BOB: Array[int] = [0, 0, 1, 1]
const WALK_FRAMES: int = 6


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
	return rows


# ---------------------------------------------------------------- poses

func _base_pose() -> Dictionary:
	return {
		"bob": 0, "lift_l": 0.0, "lift_r": 0.0, "stride": 0.0, "arm": 0.0,
		"cape": 0.0, "plume": 0.0, "lean": Vector2.ZERO, "kneel": 0.0,
		# The sword: hand position relative to the default, blade angle in degrees (0 = right, 90 = down).
		"hand": Vector2.ZERO, "angle": -1000.0, "sword_behind": false, "shield_up": 0.0,
	}


func _idle_pose(i: int) -> Dictionary:
	var pose: Dictionary = _base_pose()
	pose["bob"] = IDLE_BOB[i]
	pose["plume"] = [0.0, 0.5, 1.0, 0.5][i]
	pose["cape"] = [0.0, 0.5, 1.0, 0.5][i]
	return pose


func _walk_pose(i: int) -> Dictionary:
	var t: float = TAU * i / WALK_FRAMES
	var pose: Dictionary = _base_pose()
	pose["stride"] = sin(t)
	pose["lift_l"] = maxf(sin(t), 0.0)
	pose["lift_r"] = maxf(-sin(t), 0.0)
	pose["bob"] = -1 if absf(sin(t)) < 0.6 else 0
	pose["arm"] = -sin(t)
	pose["cape"] = 1.0 + 0.6 * cos(t)
	pose["plume"] = 1.5 + 0.5 * cos(t)
	return pose


## 0: wind-up (sword cocked back), 1: the cut, 2: follow-through, 3: recover.
func _attack_pose(facing: String, i: int) -> Dictionary:
	var pose: Dictionary = _base_pose()
	pose["cape"] = [0.0, 1.5, 2.0, 1.0][i]
	pose["plume"] = [0.0, 1.5, 2.0, 1.0][i]
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


# ---------------------------------------------------------------- frames

func frame(facing: String, pose: Dictionary) -> Image:
	var c: Canvas = Canvas.new(SIZE.x, SIZE.y)
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
	# Cape: only its edges show behind the body.
	c.part()
	var sway: float = pose["cape"]
	c.polygon(PackedVector2Array([Vector2(11, 18) + up, Vector2(21, 18) + up,
		Vector2(23 + sway * 0.5, 31.5), Vector2(9 - sway * 0.5, 31.5)]), P.CAPE, Vector3(0, 0.2, 1))
	_legs_front(c, pose, up)
	_torso_front(c, up, kneel)
	# Shield arm (the hero's left = screen right).
	var shield_center: Vector2 = Vector2(22, 24.5) + up + Vector2(0, -2.0 * float(pose["shield_up"]))
	c.part()
	c.capsule(Vector2(21, 19.5) + up, shield_center + Vector2(-1, -2), 1.5, P.STEEL, -0.05)
	_shield_front(c, shield_center)
	_pauldron(c, Vector2(21.2, 18.6) + up)
	_pauldron(c, Vector2(10.8, 18.6) + up)
	_helm(c, Vector2(16, 13) + up, "down", pose["plume"])
	_sword_arm(c, Vector2(10.5, 19.5) + up, Vector2(10, 27) + up + _arm_offset(pose), pose)


func _draw_up(c: Canvas, pose: Dictionary) -> void:
	var up: Vector2 = Vector2(0, pose["bob"]) + (pose["lean"] as Vector2)
	var hand: Vector2 = Vector2(22, 27) + up + _arm_offset(pose)
	if pose["sword_behind"]:
		_sword(c, hand, pose)
	_legs_front(c, pose, up)
	# Back of the cuirass and arms, then the shield's back on the left arm.
	c.part()
	c.ellipse(Vector2(16, 21.5) + up, Vector2(5.2, 4.8), P.STEEL)
	c.part()
	c.capsule(Vector2(11, 19.5) + up, Vector2(10, 24) + up, 1.5, P.STEEL, -0.05)
	_shield_back(c, Vector2(9.5, 24.5) + up)
	c.part()
	c.capsule(Vector2(21, 19.5) + up, hand + Vector2(0, -0.5), 1.5, P.STEEL, -0.05)
	c.part()
	c.ellipse(hand, Vector2(1.6, 1.5), P.DARK_STEEL, 0.0, 0.1)
	# The cape covers the back, swaying, with two fold lines.
	c.part()
	var sway: float = pose["cape"]
	var cape: PackedVector2Array = PackedVector2Array([Vector2(11.5, 18.5) + up, Vector2(20.5, 18.5) + up,
		Vector2(22 + sway * 0.5, 32.5), Vector2(16 + sway * 0.3, 33.2), Vector2(10 + sway * 0.5, 32.5)])
	c.polygon(cape, P.CAPE, Vector3(-0.2, -0.3, 1))
	for fold_x: float in [13.5, 18.5]:
		c.line(Vector2(fold_x, 21) + up, Vector2(fold_x + sway * 0.6, 32), P.CAPE[0])
	c.polygon(PackedVector2Array([Vector2(11.5, 18.5) + up, Vector2(20.5, 18.5) + up, Vector2(19, 20.5) + up,
		Vector2(13, 20.5) + up]), P.CAPE, Vector3(-0.3, -1, 1))
	_pauldron(c, Vector2(10.8, 18.6) + up)
	_pauldron(c, Vector2(21.2, 18.6) + up)
	_helm(c, Vector2(16, 13) + up, "up", pose["plume"])
	if not pose["sword_behind"]:
		_sword(c, hand, pose)


func _draw_side(c: Canvas, pose: Dictionary) -> void:
	var up: Vector2 = Vector2(0, pose["bob"]) + (pose["lean"] as Vector2)
	var stride: float = pose["stride"]
	# The cape streams behind (to the left), further when moving.
	c.part()
	var sway: float = pose["cape"]
	c.polygon(PackedVector2Array([Vector2(13.5, 18) + up, Vector2(16, 18.5) + up, Vector2(14.5, 31.5),
		Vector2(10 - sway, 31), Vector2(11 - sway * 0.5, 24)]), P.CAPE, Vector3(-0.5, 0, 1))
	c.line(Vector2(12.5, 21) + up, Vector2(11 - sway, 30), P.CAPE[0])
	# Far (left) arm holding the shield, edge-on in front of the chest.
	c.part()
	c.capsule(Vector2(17, 19.5) + up, Vector2(20, 23) + up, 1.4, P.DARK_STEEL)
	c.part()
	c.ellipse(Vector2(21.5, 23.5) + up, Vector2(1.7, 5.0), P.TABARD, 0.0, -0.05)
	c.line(Vector2(22.5, 19.5) + up, Vector2(22.5, 27.5) + up, P.STEEL[3])
	# Legs: the far leg darker, then the near leg.
	var hip: Vector2 = Vector2(16, 27.5) + up
	_leg(c, hip + Vector2(0.5, 0), Vector2(16 - stride * 3.5, FEET.y - 1.5 - maxf(-stride, 0.0) * 1.2), P.DARK_STEEL, true)
	_leg(c, hip, Vector2(16 + stride * 3.5, FEET.y - 1.5 - maxf(stride, 0.0) * 1.2), P.STEEL, true)
	# Torso in profile with the tabard over it.
	c.part()
	c.ellipse(Vector2(16, 21.5) + up, Vector2(4.0, 4.8), P.STEEL)
	c.part()
	c.polygon(PackedVector2Array([Vector2(13.6, 18.8) + up, Vector2(19.2, 19.5) + up, Vector2(19.6, 30) + up,
		Vector2(13, 30) + up]), P.TABARD, Vector3(0.2, 0.1, 1))
	c.line(Vector2(13.2, 29.5) + up, Vector2(19.4, 29.5) + up, P.GOLD[2])
	c.rect(Rect2i(Vector2i(Vector2(13, 25) + up), Vector2i(7, 1)), P.LEATHER[2])
	c.px(roundi(18 + up.x), roundi(25 + up.y), P.GOLD[3])
	_helm(c, Vector2(16.5, 13) + up, "side", pose["plume"])
	_pauldron(c, Vector2(15.5, 18.8) + up)
	var hand: Vector2 = Vector2(17.5, 26) + up + _arm_offset(pose)
	c.part()
	c.capsule(Vector2(15.5, 19.5) + up, hand, 1.5, P.STEEL, 0.05)
	c.part()
	c.ellipse(hand, Vector2(1.6, 1.5), P.DARK_STEEL, 0.0, 0.1)
	_sword(c, hand, pose)


# ---------------------------------------------------------------- body parts

func _legs_front(c: Canvas, pose: Dictionary, up: Vector2) -> void:
	var kneel: float = pose["kneel"]
	var hip_y: float = 27.5 + up.y * 0.5 + kneel
	_leg(c, Vector2(14, hip_y), Vector2(13.6, FEET.y - 1.5 - float(pose["lift_l"]) * 1.6), P.STEEL, false)
	_leg(c, Vector2(18, hip_y), Vector2(18.4, FEET.y - 1.5 - float(pose["lift_r"]) * 1.6), P.STEEL, false)


## A greave down to a leather boot.
func _leg(c: Canvas, hip: Vector2, foot: Vector2, ramp: Array, side: bool) -> void:
	c.part()
	c.capsule(hip, foot + Vector2(0, -1), 1.7, ramp)
	c.part()
	var toe: Vector2 = Vector2(1.0, 0) if side else Vector2.ZERO
	c.ellipse(foot + toe * 0.6, Vector2(2.2 if side else 1.9, 1.4), P.LEATHER, 0.0, 0.05)


func _torso_front(c: Canvas, up: Vector2, kneel: float) -> void:
	c.part()
	c.ellipse(Vector2(16, 21.5) + up + Vector2(0, kneel * 0.5), Vector2(5.4, 4.9), P.STEEL)
	# Tabard with a gold hem and the order's emblem (a gold tower), belted at the waist.
	c.part()
	var o: Vector2 = up + Vector2(0, kneel * 0.5)
	c.polygon(PackedVector2Array([Vector2(12.6, 18.6) + o, Vector2(19.4, 18.6) + o, Vector2(20.2, 30.6) + o,
		Vector2(16, 31.4) + o, Vector2(11.8, 30.6) + o]), P.TABARD, Vector3(-0.15, -0.1, 1))
	c.line(Vector2(12.2, 30.2) + o, Vector2(16, 31.0) + o, P.GOLD[2])
	c.line(Vector2(16, 31.0) + o, Vector2(19.8, 30.2) + o, P.GOLD[2])
	var e: Vector2i = Vector2i(o.round())
	c.rect(Rect2i(Vector2i(15, 20) + e, Vector2i(2, 4)), P.GOLD[3])
	c.rect(Rect2i(Vector2i(14, 20) + e, Vector2i(4, 1)), P.GOLD[2])
	c.px(14 + e.x, 19 + e.y, P.GOLD[2])
	c.px(17 + e.x, 19 + e.y, P.GOLD[2])
	c.rect(Rect2i(Vector2i(12, 25) + e, Vector2i(8, 1)), P.LEATHER[2])
	c.rect(Rect2i(Vector2i(12, 26) + e, Vector2i(8, 1)), P.LEATHER[1])
	c.px(16 + e.x, 25 + e.y, P.GOLD[4])
	c.px(16 + e.x, 26 + e.y, P.GOLD[2])


func _pauldron(c: Canvas, center: Vector2) -> void:
	c.part()
	c.ellipse(center, Vector2(2.7, 2.2), P.STEEL, 0.0, 0.08)


func _helm(c: Canvas, center: Vector2, facing: String, plume_sway: float) -> void:
	# The plume sits on the crown and streams back.
	c.part()
	match facing:
		"down":
			c.ellipse(center + Vector2(0, -5.2), Vector2(1.8, 2.4), P.TABARD, 0.0, 0.1)
			c.ellipse(center + Vector2(0.4 * plume_sway, -6.8), Vector2(1.3, 1.4), P.TABARD, 0.0, 0.15)
		"up":
			c.ellipse(center + Vector2(0, -4.5), Vector2(1.9, 3.0), P.TABARD, 0.0, 0.05)
			c.ellipse(center + Vector2(0.3 * plume_sway, -1.8), Vector2(1.6, 2.0), P.TABARD, 0.0, -0.05)
		_:
			c.polygon(PackedVector2Array([center + Vector2(0.5, -5.5), center + Vector2(-2.5, -6.2),
				center + Vector2(-6.5 - plume_sway, -3.8), center + Vector2(-5.2 - plume_sway, -2.4),
				center + Vector2(-1.5, -3.2)]), P.TABARD, Vector3(-0.2, -0.6, 1))
	c.part()
	c.ellipse(center, Vector2(4.6, 4.7), P.STEEL, 0.0, -0.06)
	# A darker band where the helm flares over the neck.
	match facing:
		"down":
			# Visor: a dark eye slit with a bright brow ridge above and breathing holes below.
			c.rect(Rect2i(int(center.x) - 3, int(center.y), 7, 1), P.OUTLINE)
			c.rect(Rect2i(int(center.x) - 3, int(center.y) - 1, 7, 1), P.STEEL[4])
			c.rect(Rect2i(int(center.x), int(center.y) + 1, 1, 3), P.STEEL[1])
			c.px(int(center.x) - 2, int(center.y) + 2, P.STEEL[1])
			c.px(int(center.x) + 2, int(center.y) + 2, P.STEEL[1])
			c.px(int(center.x) - 1, int(center.y), P.EYE_GLOW[0])
		"up":
			c.rect(Rect2i(int(center.x) - 3, int(center.y) + 2, 7, 1), P.STEEL[1])
			c.rect(Rect2i(int(center.x), int(center.y) - 4, 1, 6), P.STEEL[4])
		_:
			c.rect(Rect2i(int(center.x) + 1, int(center.y), 4, 1), P.OUTLINE)
			c.rect(Rect2i(int(center.x) + 1, int(center.y) - 1, 4, 1), P.STEEL[4])
			c.px(int(center.x) + 3, int(center.y) + 2, P.STEEL[1])
			c.px(int(center.x) + 3, int(center.y) + 3, P.STEEL[1])
	# A thin gold band around the crown.
	var band_y: int = int(center.y) - 3
	for x: int in range(int(center.x) - 3, int(center.x) + 4):
		if c.is_filled(x, band_y) and facing != "up":
			c.px(x, band_y, P.GOLD[2] if x != int(center.x) - 2 else P.GOLD[3])


func _arm_offset(pose: Dictionary) -> Vector2:
	return (pose["hand"] as Vector2) + Vector2(0, float(pose["arm"]) * 1.2)


## The sword arm (front view, screen left) and the sword in its hand.
func _sword_arm(c: Canvas, shoulder: Vector2, hand: Vector2, pose: Dictionary) -> void:
	if pose["sword_behind"]:
		_sword(c, hand, pose)
	c.part()
	var elbow: Vector2 = shoulder.lerp(hand, 0.5) + Vector2(-1.2, 0)
	c.capsule(shoulder, elbow, 1.6, P.STEEL, -0.05)
	c.capsule(elbow, hand, 1.5, P.STEEL, -0.05)
	c.part()
	c.ellipse(hand, Vector2(1.6, 1.5), P.DARK_STEEL, 0.0, 0.1)
	if not pose["sword_behind"]:
		_sword(c, hand, pose)


## A longsword held at `hand`: gold pommel and crossguard, leather grip, bright steel blade.
func _sword(c: Canvas, hand: Vector2, pose: Dictionary) -> void:
	var angle: float = pose["angle"]
	if angle < -999.0:
		angle = 100.0  # resting: point down, slightly forward
	var dir: Vector2 = Vector2.from_angle(deg_to_rad(angle))
	var across: Vector2 = Vector2(-dir.y, dir.x)
	c.part()
	c.capsule(hand - dir * 1.6, hand + dir * 0.4, 0.7, P.LEATHER)
	c.px(floori(hand.x - dir.x * 2.4), floori(hand.y - dir.y * 2.4), P.GOLD[3])
	var guard: Vector2 = hand + dir * 1.4
	c.line(guard - across * 2.2, guard + across * 2.2, P.GOLD[2])
	c.px(floori(guard.x - across.x * 1.2), floori(guard.y - across.y * 1.2), P.GOLD[3])
	c.part()
	c.capsule(hand + dir * 2.6, hand + dir * 10.5, 0.8, P.STEEL, 0.2)
	c.line(hand + dir * 3.0, hand + dir * 9.5, P.STEEL[5])


func _shield_front(c: Canvas, center: Vector2) -> void:
	var pts: PackedVector2Array = PackedVector2Array([center + Vector2(-3.4, -4.2), center + Vector2(3.4, -4.2),
		center + Vector2(3.4, 0.4), center + Vector2(0, 4.8), center + Vector2(-3.4, 0.4)])
	c.part()
	c.polygon(pts, P.STEEL, Vector3(-0.3, -0.3, 1))
	var inner: PackedVector2Array = PackedVector2Array([center + Vector2(-2.4, -3.2), center + Vector2(2.4, -3.2),
		center + Vector2(2.4, 0.2), center + Vector2(0, 3.5), center + Vector2(-2.4, 0.2)])
	c.polygon(inner, P.TABARD, Vector3(-0.1, -0.2, 1))
	# A gold chevron on the field.
	c.line(center + Vector2(-2.2, -0.6), center + Vector2(0, -2.4), P.GOLD[3])
	c.line(center + Vector2(0, -2.4), center + Vector2(2.2, -0.6), P.GOLD[2])


func _shield_back(c: Canvas, center: Vector2) -> void:
	c.part()
	c.polygon(PackedVector2Array([center + Vector2(-3.4, -4.2), center + Vector2(3.4, -4.2),
		center + Vector2(3.4, 0.4), center + Vector2(0, 4.8), center + Vector2(-3.4, 0.4)]), P.WOOD, Vector3(-0.2, -0.2, 1))
	c.line(center + Vector2(-2.5, -1.5), center + Vector2(2.5, -1.5), P.LEATHER[1])
	c.line(center + Vector2(-2.5, 1.0), center + Vector2(2.5, 1.0), P.LEATHER[1])


# ---------------------------------------------------------------- death

## Hit (pale), buckling, kneeling on the planted sword, then lying face down; the last frame holds.
func _death_frames() -> Array[Image]:
	var frames: Array[Image] = []
	var hit: Dictionary = _base_pose()
	hit["lean"] = Vector2(0, -1)
	hit["cape"] = 1.5
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
	var c: Canvas = Canvas.new(SIZE.x, SIZE.y)
	var pose: Dictionary = _base_pose()
	pose["cape"] = 1.0
	pose["angle"] = 20.0 if settle == 0 else 5.0
	pose["hand"] = Vector2(3, -3)
	_draw_side(c, pose)
	c.finish()
	var body: Image = c.image
	body.rotate_90(CLOCKWISE)
	var used: Rect2i = body.get_used_rect()
	var out: Canvas = Canvas.new(SIZE.x, SIZE.y)
	var at: Vector2i = Vector2i(floori((SIZE.x - used.size.x) / 2.0), int(FEET.y) + 1 - used.size.y + settle)
	out.image.blend_rect(body, used, at)
	out.ground_shadow(Vector2(16, FEET.y - 1), Vector2(12, 2.6))
	return out.image


func _tint(img: Image, color: Color, amount: float) -> void:
	for y: int in img.get_height():
		for x: int in img.get_width():
			var c: Color = img.get_pixel(x, y)
			if c.a > 0.5:
				img.set_pixel(x, y, Color(c.lerp(color, amount), c.a))
