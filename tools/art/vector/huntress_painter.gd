class_name HuntressPainter
## Paints the vector Huntress, Wren (M15 P3, docs/M15_P3_HEROES.md): a slim ranger in a forest-green hooded cloak with a torn
## hem, a brown leather jerkin with amber stitching, a red-brown scarf (her accent), a quiver on her back, a braid and a heavy
## crossbow. Pose units: feet at y 0, about 46 tall (SCALE 1.2, the Knight's). frame() paints one sheet frame
## (sheet_layouts.gd HUNTRESS): idle and walk cycles, the shot (the bolt leaves at frame 0, the game fires it at once: a recoil
## kick, a muzzle flash, a puff of smoke), the dash lean with speed streaks, and the fall. Everything is a function of the frame.

const CLOAK: Color = Color("6c9d5c")
const CLOAK_DARK: Color = Color("3f6340")
const LEATHER: Color = Color("94683c")
const LEATHER_DARK: Color = Color("5a3d24")
const AMBER: Color = Color("ecaa44")
const SCARF: Color = Color("c0583e")
const SKIN: Color = Color("ecc3a0")
const SKIN_DARK: Color = Color("b98660")
const HAIR: Color = Color("5a3a24")
const STEEL: Color = Color("b3bcc4")
const STEEL_DARK: Color = Color("5f6872")
const WOOD: Color = Color("8f6038")
const SCALE: float = 1.2
const DASH_LEAN: float = 0.28
const FLASH_TIME: float = 0.35


static func frame(ci: CanvasItem, anim: String, index: int, count: int) -> void:
	var a: Dictionary = VectorFrames.parse(anim)
	var state: String = a.state
	var cycle: float = float(index) / count
	var progress: float = float(index) / maxi(count - 1, 1)
	VectorStyle.shadow(ci, Vector2(0, 2), 12, 4.6)
	ci.draw_arc(Vector2(0, 1), 14.0, 0.0, TAU, 40, Color(AMBER, 0.28), 1.2, true)
	if state == "death":
		_death(ci, progress)
		return
	var pose: Dictionary = {"facing": a.facing, "phase": cycle, "walk": state == "walk" or state == "dash", "recoil": 0.0, "flash": 0.0}
	if state == "attack":
		pose.recoil = pow(1.0 - progress, 2.0)
		pose.flash = clampf(1.0 - progress / FLASH_TIME, 0.0, 1.0)
	var bob: float = -absf(sin(cycle * TAU)) * 1.4 if state == "walk" else sin(cycle * TAU) * 0.5
	var lean: float = DASH_LEAN if state == "dash" and a.facing == "side" else 0.0
	if state == "dash":
		_streaks(ci, a.facing)
		bob = -0.6
	ci.draw_set_transform(Vector2(0, bob), lean, Vector2.ONE)
	_figure(ci, pose)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if state == "attack":
		_smoke(ci, a.facing, progress)


static func _streaks(ci: CanvasItem, facing: String) -> void:
	var back: Vector2 = {"down": Vector2(0, -1), "up": Vector2(0, 1), "side": Vector2(-1, 0)}[facing]
	var across: Vector2 = back.orthogonal()
	for i: int in 4:
		var start: Vector2 = Vector2(0, -22) + across * (i - 1.5) * 6.0 + back * 9.0
		ci.draw_line(start, start + back * (12.0 + i * 3.0), Color(AMBER, 0.4), 2.0, true)


## A puff of smoke where the bolt left.
static func _smoke(ci: CanvasItem, facing: String, progress: float) -> void:
	var dir: Vector2 = {"down": Vector2(0, 1), "up": Vector2(0, -1), "side": Vector2(1, 0)}[facing]
	var at: Vector2 = Vector2(0, -26) + dir * (16.0 + progress * 8.0)
	if facing == "up":
		at.y -= 4.0
	ci.draw_circle(at, 2.5 + progress * 4.0, Color(0.85, 0.85, 0.85, 0.5 * (1.0 - progress)), true, -1.0, true)


static func _figure(ci: CanvasItem, pose: Dictionary) -> void:
	var facing: String = pose.facing
	var back: bool = facing == "up"
	var side: bool = facing == "side"
	var squeeze: float = 0.66 if side else 1.0
	var step: float = sin(float(pose.phase) * TAU) * (3.0 if pose.walk else 0.0)
	var sway: float = sin(float(pose.phase) * TAU + 1.0) * (1.6 if pose.walk else 0.6)
	if back:
		_crossbow(ci, pose, true)
	_cloak(ci, sway, squeeze)
	_legs(ci, step, squeeze, side)
	_torso(ci, squeeze, back)
	if back or side:
		_quiver(ci, back, side)
	_scarf(ci, sway, squeeze, back)
	if side:
		_head_side(ci)
	else:
		_head_front(ci, back)
	if not back:
		_crossbow(ci, pose, false)


static func _legs(ci: CanvasItem, step: float, squeeze: float, side: bool) -> void:
	for flip: float in [-1.0, 1.0]:
		var x: float = flip * 3.6 * squeeze
		var shift: float = step * flip * (0.9 if side else 0.0)
		var lift: float = maxf(step * flip, 0.0) * 0.5
		VectorPaint.painted(ci, PackedVector2Array([Vector2(x - 2.4 + shift * 0.3, -21), Vector2(x + 2.4 + shift * 0.3, -21), Vector2(x + 2.0 + shift, -6 - lift), Vector2(x - 2.0 + shift, -6 - lift)]), LEATHER_DARK, 1.4, 0.4, 1.0)
		var toe: float = 2.4 if side else 0.0
		VectorPaint.painted(ci, PackedVector2Array([Vector2(x - 2.8 + shift, -7 - lift), Vector2(x + 2.8 + shift, -7 - lift), Vector2(x + 3.2 + shift + toe, -0.6 - lift), Vector2(x - 3.0 + shift, -0.6 - lift)]), LEATHER, 1.2, 0.4, 1.0)
		VectorPaint.line(ci, Vector2(x - 2.8 + shift, -5.0 - lift), Vector2(x + 2.8 + shift, -5.0 - lift), Color(AMBER, 0.8), 0.7)


static func _cloak(ci: CanvasItem, sway: float, squeeze: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array([Vector2(-7.5, -34), Vector2(7.5, -34), Vector2(10, -24), Vector2(12 + sway * 0.3, -14)])
	for i: int in 7:
		var x: float = lerpf(12.0, -12.0, i / 6.0) + sway * 0.5
		pts.append(Vector2(x, -9.0 + (2.4 if i % 2 == 0 else -0.6)))
	pts.append_array(PackedVector2Array([Vector2(-12 + sway * 0.3, -14), Vector2(-10, -24)]))
	var squeezed: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in pts:
		squeezed.append(Vector2(p.x * squeeze, p.y))
	VectorPaint.painted(ci, squeezed, CLOAK, 3.0, 0.55, 1.2)
	VectorPaint.strand(ci, Vector2(-3 * squeeze, -31), Vector2(-6 * squeeze, -20), Vector2(-9 * squeeze + sway * 0.4, -10), 2.6, Color(CLOAK_DARK, 0.8))
	VectorPaint.strand(ci, Vector2(3 * squeeze, -31), Vector2(6 * squeeze, -20), Vector2(9 * squeeze + sway * 0.4, -10), 2.6, Color(CLOAK_DARK, 0.8))


static func _torso(ci: CanvasItem, squeeze: float, back: bool) -> void:
	var w: float = 6.6 * squeeze
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-w, -34), Vector2(w, -34), Vector2(w - 1.0 * squeeze, -20), Vector2(-w + 1.0 * squeeze, -20)]), LEATHER, 2.4, 0.5, 1.1)
	if not back:
		VectorPaint.line(ci, Vector2(0, -33), Vector2(0, -21), Color(AMBER, 0.85), 0.8)
		for k: int in 3:
			VectorPaint.line(ci, Vector2(-1.6, -31 + k * 3.6), Vector2(1.6, -31 + k * 3.6), Color(AMBER, 0.9), 0.7)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-w, -21.8), Vector2(w, -21.8), Vector2(w, -19.6), Vector2(-w, -19.6)]), LEATHER_DARK, 0.6, 0.2, 0.8)
	ci.draw_circle(Vector2(0, -20.7), 1.1, AMBER, true, -1.0, true)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(3.4 * squeeze, -20), Vector2(7.2 * squeeze, -20), Vector2(7.4 * squeeze, -15.4), Vector2(3.2 * squeeze, -15.4)]), LEATHER_DARK, 0.8, 0.3, 0.9)


## The quiver on her back with the fletching showing over her shoulder.
static func _quiver(ci: CanvasItem, back: bool, side: bool) -> void:
	var at: Vector2 = Vector2(-4.4, -29) if side else Vector2(4.6, -29)
	var tilt: float = 0.22 if side else -0.2
	ci.draw_set_transform(at, tilt, Vector2.ONE)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-2.4, -8), Vector2(2.4, -8), Vector2(2.8, 7), Vector2(-2.8, 7)]), LEATHER_DARK, 1.0, 0.3, 0.9)
	for k: float in [-1.2, 0.0, 1.2]:
		VectorPaint.painted(ci, PackedVector2Array([Vector2(k - 0.8, -8), Vector2(k + 0.8, -8), Vector2(k + 0.2, -12.4 - absf(k))]), AMBER, 0.3, 0.2, 0.6)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if back:
		VectorPaint.line(ci, Vector2(-5, -33), Vector2(5, -22), LEATHER_DARK, 1.2)


static func _scarf(ci: CanvasItem, sway: float, squeeze: float, back: bool) -> void:
	VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -34.6), 6.4 * squeeze, 2.5, 14), SCARF, 1.0, 0.4, 1.0)
	var tail_x: float = -4.6 * squeeze if not back else 4.6 * squeeze
	VectorPaint.strand(ci, Vector2(tail_x, -34), Vector2(tail_x - 2.0 + sway * 0.4, -28), Vector2(tail_x - 3.0 + sway, -20), 4.0, SCARF)


static func _head_front(ci: CanvasItem, back: bool) -> void:
	var at: Vector2 = Vector2(0, -41)
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(0, -9), at + Vector2(7, -3), at + Vector2(7.4, 4.4), at + Vector2(-7.4, 4.4), at + Vector2(-7, -3)]), CLOAK, 2.4, 0.55, 1.2)
	if back:
		VectorPaint.strand(ci, at + Vector2(0, 3), at + Vector2(1.5, 8), at + Vector2(0.5, 14), 3.6, HAIR)
		VectorPaint.line(ci, at + Vector2(0, -8), at + Vector2(0, 3), Color(CLOAK_DARK, 0.9), 0.9)
		return
	VectorPaint.fill(ci, VectorStyle.ellipse(at + Vector2(0, 0.6), 4.8, 5.0, 16), Color("22301f"))
	VectorPaint.painted(ci, VectorStyle.ellipse(at + Vector2(0, 2.0), 3.7, 3.3, 14), SKIN, 0.9, 0.2, 0.0)
	for x: float in [-1.7, 1.7]:
		ci.draw_circle(at + Vector2(x, 0.6), 0.7, AMBER, true, -1.0, true)
	VectorPaint.line(ci, at + Vector2(-1.2, 3.8), at + Vector2(1.2, 3.8), Color(SKIN_DARK, 0.9), 0.6)
	VectorPaint.line(ci, at + Vector2(-5.6, -3.0), at + Vector2(5.6, -3.0), Color(AMBER, 0.85), 0.8)
	VectorStyle.shine(ci, at + Vector2(-3.6, -5.0), 2.0, 1.2, 0.35)


static func _head_side(ci: CanvasItem) -> void:
	var at: Vector2 = Vector2(1.5, -41)
	VectorPaint.strand(ci, at + Vector2(-5, 2), at + Vector2(-8, 6), at + Vector2(-7, 14), 3.6, HAIR)
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(-1, -9.4), at + Vector2(6, -4), at + Vector2(6.8, 4.4), at + Vector2(-6.6, 4.4), at + Vector2(-6.6, -3)]), CLOAK, 2.4, 0.55, 1.2)
	VectorPaint.fill(ci, PackedVector2Array([at + Vector2(1.5, -2.6), at + Vector2(6.4, -1), at + Vector2(6.4, 4.0), at + Vector2(1.6, 4.0)]), Color("22301f"))
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(2.4, 0), at + Vector2(6.0, 1.0), at + Vector2(5.6, 4.0), at + Vector2(2.4, 4.0)]), SKIN, 0.6, 0.2, 0.0)
	ci.draw_circle(at + Vector2(4.4, 0.6), 0.7, AMBER, true, -1.0, true)
	VectorPaint.line(ci, at + Vector2(-5.6, -3.4), at + Vector2(5.6, -3.4), Color(AMBER, 0.85), 0.8)


## The crossbow, held in both hands at chest height and pointing along the facing; the shot kicks it back and flashes at its tip.
static func _crossbow(ci: CanvasItem, pose: Dictionary, behind: bool) -> void:
	var facing: String = pose.facing
	var kick: float = float(pose.recoil) * 2.6
	var flash: float = float(pose.flash)
	if facing == "side":
		var base: Vector2 = Vector2(5 - kick, -27)
		VectorPaint.painted(ci, PackedVector2Array([base + Vector2(0, -1.8), base + Vector2(19, -1.2), base + Vector2(19, 1.2), base + Vector2(0, 2.0)]), WOOD, 1.0, 0.4, 1.0)
		VectorPaint.painted(ci, PackedVector2Array([base + Vector2(15, -7), base + Vector2(17.4, -6), base + Vector2(18, 0), base + Vector2(17.4, 6), base + Vector2(15, 7), base + Vector2(16, 0)]), STEEL, 0.8, 0.5, 0.9)
		VectorPaint.line(ci, base + Vector2(15.4, -6.6), base + Vector2(15.4 - kick * 0.4, 0), Color(1, 1, 1, 0.7), 0.6)
		VectorPaint.line(ci, base + Vector2(15.4 - kick * 0.4, 0), base + Vector2(15.4, 6.6), Color(1, 1, 1, 0.7), 0.6)
		for k: float in [2.0, 9.0]:
			VectorPaint.painted(ci, VectorStyle.ellipse(base + Vector2(k, 1.4), 2.0, 2.0, 8), SKIN, 0.4, 0.2, 0.8)
		_flash(ci, base + Vector2(20, 0), flash)
		return
	var aim: float = -1.0 if facing == "up" else 1.0
	var c: Vector2 = Vector2(0, -26 - kick * (0.0 if behind else 0.4))
	if behind:
		for flip: float in [-1.0, 1.0]:
			VectorPaint.line(ci, Vector2(flip * 6, -30), Vector2(flip * 9.5, -26), STEEL_DARK, 1.6)
		return
	VectorPaint.painted(ci, PackedVector2Array([c + Vector2(-2.0, -2), c + Vector2(2.0, -2), c + Vector2(2.4, 4), c + Vector2(-2.4, 4)]), WOOD, 0.8, 0.4, 1.0)
	VectorPaint.painted(ci, PackedVector2Array([c + Vector2(-11, 0.4), c + Vector2(-5, -2.4), c + Vector2(5, -2.4), c + Vector2(11, 0.4), c + Vector2(5, -0.6), c + Vector2(-5, -0.6)]), STEEL, 0.8, 0.5, 0.9)
	VectorPaint.line(ci, c + Vector2(-10.6, 0.4), c + Vector2(0, 1.8 + kick * 0.3), Color(1, 1, 1, 0.7), 0.6)
	VectorPaint.line(ci, c + Vector2(0, 1.8 + kick * 0.3), c + Vector2(10.6, 0.4), Color(1, 1, 1, 0.7), 0.6)
	for flip: float in [-1.0, 1.0]:
		VectorPaint.painted(ci, VectorStyle.ellipse(c + Vector2(flip * 3.4, 4.6), 2.0, 2.0, 8), SKIN, 0.4, 0.2, 0.8)
	_flash(ci, c + Vector2(0, 6.0 * aim), flash)


static func _flash(ci: CanvasItem, at: Vector2, strength: float) -> void:
	if strength <= 0.02:
		return
	VectorStyle.draw_glow(ci, AMBER, at, 8.0 + strength * 6.0, 0.8 * strength)
	ci.draw_circle(at, 1.6 + strength * 2.4, Color("fff2c8"), true, -1.0, true)


## She drops to a knee and tips over onto her side, the crossbow falling from her hands.
static func _death(ci: CanvasItem, progress: float) -> void:
	var kneel: float = clampf(progress / 0.35, 0.0, 1.0)
	var fall: float = clampf((progress - 0.3) / 0.6, 0.0, 1.0)
	var eased: float = fall * fall * (3.0 - 2.0 * fall)
	var pose: Dictionary = {"facing": "down", "phase": 0.0, "walk": false, "recoil": 0.0, "flash": 0.0}
	if fall > 0.35:
		ci.draw_set_transform(Vector2(10.0 + fall * 4.0, -3.0), 0.3 * fall, Vector2.ONE)
		VectorPaint.painted(ci, PackedVector2Array([Vector2(-11, -1.4), Vector2(0, -1.4), Vector2(11, -1.4), Vector2(11, 1.4), Vector2(0, 1.4), Vector2(-11, 1.4)]), STEEL, 0.6, 0.4, 0.9)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	ci.draw_set_transform(Vector2(eased * 3.0, kneel * 3.0 + eased * 2.0), eased * 1.15, Vector2(1, 1.0 - kneel * 0.12))
	_figure(ci, pose)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
