class_name SkeletonPainter
## Paints the vector Skeleton minion (M15 P3, docs/M15_P3_HEROES.md): a hunched bone warrior with a rusty short sword, a cracked
## buckler, teal fire in its sockets and a dim teal glow in its ribs (allies are teal, the dead red and violet). Side view facing
## right (the game mirrors it). Pose units: feet at y 0, about 42 tall (SCALE 1.1). frame() paints one sheet frame
## (sheet_layouts.gd SKELETON): idle, walk, a sword slash and a collapse into a pile of bones with the skull rolling off.

const BONE: Color = Color("e6dfc6")
const BONE_DARK: Color = Color("9a9279")
const RUST: Color = Color("b36c40")
const RUST_DARK: Color = Color("6f3f26")
const WOOD: Color = Color("8f6038")
const SOUL: Color = Color("8ff0dc")
const SCALE: float = 1.1
const WINDUP_END: float = 0.45
const STRIKE_PEAK: float = 0.7
const PULL_BACK: float = -1.0


static func frame(ci: CanvasItem, anim: String, index: int, count: int) -> void:
	var cycle: float = float(index) / count
	var progress: float = float(index) / maxi(count - 1, 1)
	VectorStyle.shadow(ci, Vector2(0, 1), 11, 3.6)
	if anim == "death":
		_death(ci, progress)
		return
	var swing: float = 0.0
	var walk: bool = anim == "walk"
	if anim == "attack":
		swing = VectorFrames.attack_curve(progress, WINDUP_END, STRIKE_PEAK, PULL_BACK)
	var bob: float = -absf(sin(cycle * TAU)) * 1.1 if walk else sin(cycle * TAU) * 0.4
	ci.draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE)
	_figure(ci, cycle, walk, swing, anim == "attack")
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _figure(ci: CanvasItem, cycle: float, walk: bool, swing: float, attacking: bool) -> void:
	var step: float = sin(cycle * TAU) * (4.0 if walk else 0.0)
	var hunch: float = 1.4 + sin(cycle * TAU) * 0.4
	_leg(ci, -1.0, step)
	_arm_back(ci, step)
	_pelvis(ci)
	_ribs(ci, hunch)
	_skull(ci, hunch)
	_leg(ci, 1.0, -step)
	_arm_sword(ci, step, swing, attacking)


static func _leg(ci: CanvasItem, flip: float, step: float) -> void:
	var hip: Vector2 = Vector2(0.4, -17)
	var knee: Vector2 = Vector2(flip * 1.6 + step * flip * -0.2 + 1.6, -9.0)
	var foot: Vector2 = Vector2(flip * step * 0.7 + 1.0, -0.4 - maxf(step * flip, 0.0) * 0.4)
	VectorPaint.limb(ci, hip, knee, foot + Vector2(0, -1.6), 3.2, BONE_DARK if flip < 0.0 else BONE)
	VectorPaint.painted(ci, VectorStyle.ellipse(knee, 2.4, 2.2, 10), BONE, 0.6, 0.4, 0.9)
	VectorPaint.painted(ci, PackedVector2Array([foot + Vector2(-2.0, -1.6), foot + Vector2(1.6, -1.6), foot + Vector2(4.6, 0.2), foot + Vector2(-2.0, 0.2)]), BONE, 0.5, 0.4, 0.9)


static func _pelvis(ci: CanvasItem) -> void:
	VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0.2, -17.4), 4.2, 2.8, 12), BONE_DARK, 0.8, 0.4, 0.9)


static func _ribs(ci: CanvasItem, hunch: float) -> void:
	var cage: Vector2 = Vector2(hunch * 0.6, -27)
	VectorPaint.painted(ci, VectorStyle.ellipse(cage, 5.6, 7.6, 16), Color("5f5944"), 1.6, 0.45, 1.0)
	VectorStyle.draw_glow(ci, SOUL, cage, 8.0, 0.35)
	for i: int in 4:
		var y: float = -32.0 + i * 3.6
		VectorPaint.strand(ci, Vector2(cage.x - 4.4, y), Vector2(cage.x, y - 1.0), Vector2(cage.x + 4.6, y + 1.6), 2.4, BONE)
	for k: int in 5:
		ci.draw_circle(Vector2(cage.x - 4.6 + hunch * 0.2, -34.0 + k * 3.8), 1.2, BONE_DARK, true, -1.0, true)


static func _skull(ci: CanvasItem, hunch: float) -> void:
	var at: Vector2 = Vector2(hunch * 1.4 + 1.4, -37.4)
	VectorPaint.painted(ci, VectorStyle.ellipse(at, 4.8, 4.6, 16), BONE, 1.6, 0.55, 1.1)
	VectorPaint.painted(ci, PackedVector2Array([at + Vector2(0, 1.6), at + Vector2(5.2, 2.0), at + Vector2(4.6, 4.6), at + Vector2(0.4, 4.2)]), BONE_DARK, 0.5, 0.2, 0.8)
	VectorStyle.draw_glow(ci, SOUL, at + Vector2(2.2, -0.4), 4.4, 0.8)
	ci.draw_circle(at + Vector2(2.2, -0.4), 1.0, Color("eafff8"), true, -1.0, true)
	VectorPaint.fill(ci, PackedVector2Array([at + Vector2(4.4, 0.6), at + Vector2(5.6, 1.8), at + Vector2(4.2, 1.8)]), Color("1d2a28"))
	for k: int in 3:
		VectorPaint.line(ci, at + Vector2(1.0 + k * 1.4, 3.0), at + Vector2(1.0 + k * 1.4, 4.4), Color(VectorStyle.INK, 0.8), 0.5)


## The far arm holds the buckler close to the chest.
static func _arm_back(ci: CanvasItem, step: float) -> void:
	var shoulder: Vector2 = Vector2(0.6, -32)
	var hand: Vector2 = Vector2(5.0, -25 + step * 0.05)
	VectorPaint.limb(ci, shoulder, Vector2(3.6, -28), hand, 2.6, BONE_DARK)
	var shield: Vector2 = hand + Vector2(1.6, -0.4)
	VectorPaint.painted(ci, VectorStyle.ellipse(shield, 5.0, 5.4, 16), WOOD, 1.6, 0.5, 1.1)
	VectorPaint.painted(ci, VectorStyle.ellipse(shield, 1.6, 1.6, 8), BONE_DARK, 0.4, 0.4, 0.8)
	VectorPaint.line(ci, shield + Vector2(-2.6, -4.0), shield + Vector2(1.0, 0.6), Color(VectorStyle.INK, 0.9), 0.9)


## The near arm and the rusty sword: resting low, raised back for the wind-up, slashed forward on the strike.
static func _arm_sword(ci: CanvasItem, step: float, swing: float, attacking: bool) -> void:
	var shoulder: Vector2 = Vector2(1.6, -32)
	var angle: float = 0.9 + step * 0.02
	var hand: Vector2 = Vector2(8.6, -26 + step * 0.1)
	if attacking:
		angle = lerpf(0.9, 2.6, clampf(-swing, 0.0, 1.0)) if swing < 0.0 else lerpf(0.9, -0.55, swing)
		hand = Vector2(7.0, -30).lerp(Vector2(9.6, -27), maxf(swing, 0.0))
	VectorPaint.limb(ci, shoulder, shoulder.lerp(hand, 0.5) + Vector2(1.0, 2.0), hand, 2.8, BONE)
	var dir: Vector2 = Vector2.from_angle(angle)
	var across: Vector2 = dir.orthogonal()
	var reach: float = lerpf(1.0, 0.7, absf(cos(angle)))
	var blade_start: Vector2 = hand + dir * 3.0
	var tip: Vector2 = hand + dir * 20.0 * reach
	VectorPaint.painted(ci, PackedVector2Array([blade_start + across * 1.7, tip, blade_start - across * 1.7]), RUST, 0.8, 0.5, 1.0)
	VectorPaint.line(ci, blade_start, tip - dir * 2.0, Color(RUST_DARK, 0.9), 0.6)
	VectorPaint.painted(ci, PackedVector2Array([hand + dir * 2.0 + across * 2.8, hand + dir * 3.4 + across * 2.8, hand + dir * 3.4 - across * 2.8, hand + dir * 2.0 - across * 2.8]), RUST_DARK, 0.4, 0.2, 0.8)
	VectorPaint.painted(ci, VectorStyle.ellipse(hand, 1.9, 1.8, 8), BONE, 0.4, 0.3, 0.8)


## The bones let go: it kneels, the ribcage drops, the skull rolls off and the sword falls into a pile.
static func _death(ci: CanvasItem, progress: float) -> void:
	var fall: float = smoothstep(0.05, 0.85, progress)
	var cage_drop: float = fall * 16.0
	ci.draw_set_transform(Vector2(0, fall * 2.0), 0.0, Vector2(1.0 + fall * 0.35, 1.0 - fall * 0.5))
	_leg(ci, -1.0, 0.0)
	_leg(ci, 1.0, 0.0)
	_pelvis(ci)
	ci.draw_set_transform(Vector2(fall * 3.0, cage_drop), fall * 0.35, Vector2(1.0, 1.0 - fall * 0.3))
	_ribs(ci, 1.4)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var roll: float = smoothstep(0.2, 0.95, progress)
	var home: Vector2 = Vector2(3.4, -37.4)
	var skull: Vector2 = home.lerp(Vector2(13.0, -4.6), roll)
	# _skull paints around `home`: move that point onto `skull` while the head turns about itself.
	ci.draw_set_transform(skull - home.rotated(roll * 4.0), roll * 4.0, Vector2.ONE)
	_skull(ci, 1.4)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var drop: float = smoothstep(0.1, 0.9, progress)
	var hand: Vector2 = Vector2(8.6, -26).lerp(Vector2(-14.0, -2.0), drop)
	var dir: Vector2 = Vector2.from_angle(lerpf(0.9, -0.05, drop))
	var across: Vector2 = dir.orthogonal()
	VectorPaint.painted(ci, PackedVector2Array([hand + across * 1.7, hand + dir * 20.0, hand - across * 1.7]), RUST, 0.8, 0.5, 1.0)
	VectorStyle.draw_glow(ci, SOUL, Vector2(4, -22 + cage_drop), 8.0 * (1.0 - fall), 0.4 * (1.0 - fall))
