class_name NecromancerPainter
## Paints the vector Necromancer, Maren (M15 P3, docs/M15_P3_HEROES.md): a tall hooded gravecaller in deep teal robes with
## ivory trim, a gold sash, one bone pauldron, a little lantern and skulls at the belt, and a skull-topped staff with a pale-teal
## flame (her soul fire; the dead are red and violet, she is teal and gold). Pose units: feet at y 0, about 48 tall (SCALE 1.2, the
## Knight's). frame() paints one sheet frame (sheet_layouts.gd NECROMANCER): idle and walk cycles, the cast (the bolt leaves at
## frame 0: a staff thrust and a teal flash at the skull), the dash as a blur of mist, and the fall into the robe.

const ROBE: Color = Color("4f9aa3")
const ROBE_DARK: Color = Color("28595f")
const IVORY: Color = Color("efe6cf")
const IVORY_DARK: Color = Color("a89f86")
const GOLD: Color = Color("e8b54e")
const SKIN: Color = Color("d9d4c6")
const SKIN_DARK: Color = Color("8f8a7c")
const SOUL: Color = Color("8ff0dc")
const WOOD: Color = Color("6b4a30")
const LANTERN: Color = Color("ffb84d")
const SCALE: float = 1.2
const DASH_LEAN: float = 0.22
const FLASH_TIME: float = 0.4
## Kept short (about her own height) so the flame and its glow stay inside the cell.
const STAFF_LENGTH: float = 40.0


static func frame(ci: CanvasItem, anim: String, index: int, count: int) -> void:
	var a: Dictionary = VectorFrames.parse(anim)
	var state: String = a.state
	var cycle: float = float(index) / count
	var progress: float = float(index) / maxi(count - 1, 1)
	VectorStyle.shadow(ci, Vector2(0, 2), 13, 4.8)
	ci.draw_arc(Vector2(0, 1), 14.0, 0.0, TAU, 40, Color(SOUL, 0.28), 1.2, true)
	if state == "death":
		_death(ci, progress)
		return
	var pose: Dictionary = {"facing": a.facing, "phase": cycle, "walk": state == "walk" or state == "dash", "thrust": 0.0, "flash": 0.0, "mist": state == "dash"}
	if state == "attack":
		pose.thrust = pow(1.0 - progress, 2.0)
		pose.flash = clampf(1.0 - progress / FLASH_TIME, 0.0, 1.0)
	var bob: float = -absf(sin(cycle * TAU)) * 1.0 if state == "walk" else sin(cycle * TAU) * 0.5
	var lean: float = DASH_LEAN if state == "dash" and a.facing == "side" else 0.0
	if state == "dash":
		_mist(ci, a.facing)
	ci.draw_set_transform(Vector2(0, bob), lean, Vector2.ONE)
	_figure(ci, pose)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _mist(ci: CanvasItem, facing: String) -> void:
	var back: Vector2 = {"down": Vector2(0, -1), "up": Vector2(0, 1), "side": Vector2(-1, 0)}[facing]
	var across: Vector2 = back.orthogonal()
	for i: int in 4:
		var at: Vector2 = Vector2(0, -20) + across * (i - 1.5) * 6.0 + back * (8.0 + i * 3.0)
		ci.draw_circle(at, 4.0 + i, Color(SOUL, 0.3 - i * 0.05), true, -1.0, true)


static func _figure(ci: CanvasItem, pose: Dictionary) -> void:
	var facing: String = pose.facing
	var back: bool = facing == "up"
	var side: bool = facing == "side"
	var squeeze: float = 0.64 if side else 1.0
	var sway: float = sin(float(pose.phase) * TAU) * (2.2 if pose.walk else 0.8)
	var staff_x: float = 15.0 * squeeze + 2.0 if not side else 12.0
	var staff_base: Vector2 = Vector2(staff_x, -2.0)
	var tilt: float = float(pose.thrust) * 0.5 * (1.0 if side else 0.3)
	if back:
		_staff(ci, staff_base, tilt, pose, true)
	_robe(ci, sway, squeeze)
	_belt(ci, squeeze, back)
	_pauldron(ci, squeeze, back, side)
	if side:
		_head_side(ci)
	else:
		_head_front(ci, back)
	_arms(ci, staff_base, squeeze, side)
	if not back:
		_staff(ci, staff_base, tilt, pose, false)


static func _robe(ci: CanvasItem, sway: float, squeeze: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array([Vector2(-8, -35), Vector2(8, -35), Vector2(11, -24), Vector2(13 + sway * 0.3, -12)])
	for i: int in 7:
		var x: float = lerpf(15.0, -15.0, i / 6.0) + sway * 0.5
		pts.append(Vector2(x, -2.0 + (2.0 if i % 2 == 0 else -0.8)))
	pts.append_array(PackedVector2Array([Vector2(-13 + sway * 0.3, -12), Vector2(-11, -24)]))
	var squeezed: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in pts:
		squeezed.append(Vector2(p.x * squeeze, p.y))
	VectorPaint.painted(ci, squeezed, ROBE, 3.2, 0.55, 1.3)
	for flip: float in [-1.0, 1.0]:
		VectorPaint.strand(ci, Vector2(flip * 4 * squeeze, -32), Vector2(flip * 8 * squeeze, -18), Vector2(flip * 11 * squeeze + sway * 0.4, -4), 2.8, Color(ROBE_DARK, 0.8))
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-14 * squeeze + sway * 0.4, -3.6), Vector2(14 * squeeze + sway * 0.4, -3.6), Vector2(15 * squeeze + sway * 0.5, -1.4), Vector2(-15 * squeeze + sway * 0.5, -1.4)]), IVORY_DARK, 0.5, 0.3, 0.8)


## The gold sash, a few small skulls and a lantern hanging from the belt.
static func _belt(ci: CanvasItem, squeeze: float, back: bool) -> void:
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-9 * squeeze, -23), Vector2(9 * squeeze, -23), Vector2(9.4 * squeeze, -20.4), Vector2(-9.4 * squeeze, -20.4)]), GOLD, 0.8, 0.4, 0.9)
	if back:
		return
	for k: float in [-0.5, 0.2]:
		var at: Vector2 = Vector2(k * 12.0 * squeeze, -17.4)
		VectorPaint.painted(ci, VectorStyle.ellipse(at, 1.7, 1.9, 8), IVORY, 0.4, 0.3, 0.7)
	var lamp: Vector2 = Vector2(-7.4 * squeeze, -15.6)
	VectorStyle.draw_glow(ci, LANTERN, lamp, 8.0, 0.45)
	VectorPaint.painted(ci, PackedVector2Array([lamp + Vector2(-1.4, -1.6), lamp + Vector2(1.4, -1.6), lamp + Vector2(1.8, 2.4), lamp + Vector2(-1.8, 2.4)]), IVORY_DARK, 0.4, 0.3, 0.7)
	VectorPaint.fill(ci, PackedVector2Array([lamp + Vector2(-0.9, -0.8), lamp + Vector2(0.9, -0.8), lamp + Vector2(1.1, 1.6), lamp + Vector2(-1.1, 1.6)]), LANTERN)


static func _pauldron(ci: CanvasItem, squeeze: float, back: bool, side: bool) -> void:
	var at: Vector2 = Vector2(-8.6 * squeeze, -33.4)
	if side:
		at = Vector2(0.6, -33.4)
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-4.6, 2.4), at + Vector2(-2.6, -3.4), at + Vector2(3.4, -3.8), at + Vector2(5.0, 2.6), at + Vector2(0, 4.4)]), IVORY, 1.6, 0.5, 1.0)
	if not back:
		VectorPaint.line(ci, at + Vector2(-2.6, -0.6), at + Vector2(3.0, -0.6), Color(IVORY_DARK, 0.9), 0.7)
		VectorPaint.line(ci, at + Vector2(-2.0, 1.6), at + Vector2(2.6, 1.6), Color(IVORY_DARK, 0.9), 0.7)


static func _head_front(ci: CanvasItem, back: bool) -> void:
	var at: Vector2 = Vector2(0, -41)
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(0, -9), at + Vector2(7.2, -3), at + Vector2(7.6, 5.0), at + Vector2(-7.6, 5.0), at + Vector2(-7.2, -3)]), ROBE, 2.6, 0.55, 1.3)
	if back:
		VectorPaint.line(ci, at + Vector2(0, -8), at + Vector2(0, 4), Color(ROBE_DARK, 0.9), 0.9)
		return
	VectorPaint.fill(ci, VectorStyle.ellipse(at + Vector2(0, 0.8), 5.0, 5.2, 16), Color("0f1f22"))
	VectorPaint.painted(ci, VectorStyle.ellipse(at + Vector2(0, 2.6), 3.4, 2.8, 14), SKIN, 0.8, 0.2, 0.0)
	for x: float in [-1.8, 1.8]:
		VectorStyle.draw_glow(ci, SOUL, at + Vector2(x, 0.2), 3.0, 0.8)
		ci.draw_circle(at + Vector2(x, 0.2), 0.8, Color("eafff8"), true, -1.0, true)
	VectorPaint.line(ci, at + Vector2(-1.0, 3.4), at + Vector2(1.6, 4.4), Color(SKIN_DARK, 0.9), 0.6)
	VectorPaint.line(ci, at + Vector2(-5.8, -3.4), at + Vector2(5.8, -3.4), Color(GOLD, 0.9), 0.9)


static func _head_side(ci: CanvasItem) -> void:
	var at: Vector2 = Vector2(1.4, -41)
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-1, -9.4), at + Vector2(6.2, -4), at + Vector2(7.0, 5.0), at + Vector2(-6.8, 5.0), at + Vector2(-6.8, -3)]), ROBE, 2.6, 0.55, 1.3)
	VectorPaint.fill(ci, PackedVector2Array([at + Vector2(1.4, -2.6), at + Vector2(6.6, -1), at + Vector2(6.6, 4.4), at + Vector2(1.6, 4.4)]), Color("0f1f22"))
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(2.4, 0.6), at + Vector2(6.0, 1.6), at + Vector2(5.6, 4.4), at + Vector2(2.4, 4.4)]), SKIN, 0.6, 0.2, 0.0)
	VectorStyle.draw_glow(ci, SOUL, at + Vector2(4.4, 0.4), 3.0, 0.8)
	ci.draw_circle(at + Vector2(4.4, 0.4), 0.8, Color("eafff8"), true, -1.0, true)
	VectorPaint.line(ci, at + Vector2(-5.8, -3.6), at + Vector2(5.8, -3.6), Color(GOLD, 0.9), 0.9)


## Sleeves to the staff hand (right) and the free hand (left, a pale claw).
static func _arms(ci: CanvasItem, staff_base: Vector2, squeeze: float, side: bool) -> void:
	var hold: Vector2 = staff_base + Vector2(0, -24)
	var right_shoulder: Vector2 = Vector2(9 * squeeze, -32) if not side else Vector2(2, -32)
	var left_shoulder: Vector2 = Vector2(-9 * squeeze, -32) if not side else Vector2(-1, -32)
	VectorPaint.limb(ci, right_shoulder, right_shoulder.lerp(hold, 0.5) + Vector2(2, 2), hold, 5.4, ROBE)
	var free: Vector2 = Vector2(-13 * squeeze, -22) if not side else Vector2(8.0, -24)
	VectorPaint.limb(ci, left_shoulder, left_shoulder.lerp(free, 0.5) + Vector2(-2, 2), free, 5.0, ROBE)
	VectorPaint.painted(ci, VectorStyle.ellipse(hold, 2.2, 2.0, 10), SKIN, 0.5, 0.3, 0.9)
	VectorPaint.painted(ci, VectorStyle.ellipse(free, 2.0, 1.9, 10), SKIN, 0.5, 0.3, 0.9)


## The staff: a dark haft topped by a small skull with a flame; the cast flashes at the skull as the bolt leaves it.
static func _staff(ci: CanvasItem, base: Vector2, tilt: float, pose: Dictionary, behind: bool) -> void:
	var top: Vector2 = base + Vector2(sin(tilt) * STAFF_LENGTH, -cos(tilt) * STAFF_LENGTH)
	VectorPaint.painted(ci, PackedVector2Array([base + Vector2(-1.2, 0), top + Vector2(-1.2, 0), top + Vector2(1.2, 0), base + Vector2(1.2, 0)]), WOOD, 0.6, 0.3, 1.0)
	if behind:
		return
	VectorPaint.painted(ci, VectorStyle.ellipse(top + Vector2(0, -3.0), 3.6, 3.4, 12), IVORY, 1.0, 0.5, 1.0)
	for x: float in [-1.2, 1.2]:
		ci.draw_circle(top + Vector2(x, -3.2), 0.8, Color("123a3a"), true, -1.0, true)
	var flare: float = float(pose.flash)
	VectorStyle.draw_glow(ci, SOUL, top + Vector2(0, -8.0), 8.0 + flare * 5.0, 0.5 + flare * 0.4)
	var flick: float = sin(float(pose.phase) * TAU * 2.0) * 0.8
	VectorPaint.fill(ci, PackedVector2Array([top + Vector2(-2.2, -6), top + Vector2(2.2, -6), top + Vector2(flick, -13.0 - flare * 3.0)]), Color(SOUL, 0.95))
	VectorPaint.fill(ci, PackedVector2Array([top + Vector2(-1.0, -6), top + Vector2(1.0, -6), top + Vector2(flick * 0.5, -10.0)]), Color("eafff8"))


## She folds into her robes, the staff falls and its flame goes out.
static func _death(ci: CanvasItem, progress: float) -> void:
	var fold: float = smoothstep(0.1, 0.9, progress)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0 + fold * 0.5, 1.0 - fold * 0.8))
	_robe(ci, 0.0, 1.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if fold < 0.5:
		var down: float = fold / 0.5
		ci.draw_set_transform(Vector2(0, down * 18.0), 0.0, Vector2(1.0, 1.0 - down * 0.15))
		_belt(ci, 1.0, false)
		_pauldron(ci, 1.0, false, false)
		_head_front(ci, false)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		var settle: float = smoothstep(0.45, 0.95, progress)
		var hood_at: Vector2 = Vector2(0, -41 + 18.0).lerp(Vector2(4, -7), settle)
		ci.draw_set_transform(hood_at + Vector2(0, 41), 0.0, Vector2.ONE)
		_head_front(ci, false)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var drop: float = smoothstep(0.1, 0.85, progress)
	var base: Vector2 = Vector2(15, -2).lerp(Vector2(-4, -3), drop)
	ci.draw_set_transform(base, lerpf(0.0, -0.95, drop), Vector2.ONE)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-1.2, 0), Vector2(-1.2, -STAFF_LENGTH), Vector2(1.2, -STAFF_LENGTH), Vector2(1.2, 0)]), WOOD, 0.6, 0.3, 1.0)
	VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -STAFF_LENGTH - 3.0), 3.6, 3.4, 12), IVORY, 1.0, 0.5, 1.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	VectorStyle.draw_glow(ci, SOUL, Vector2(15, -20).lerp(Vector2(-22, -12), drop), 9.0 * (1.0 - drop), 0.6 * (1.0 - drop))
