extends RefCounted
## The M5 towers (dev-time art generator), same 32x48 frames, base on art row 45, 3/4 view and light
## as tower_art.gd, which calls draw() for them and adds their build/sell animations:
##   Brazier: a squat stone plinth carrying a great iron fire bowl that lobs burning pitch.
##   Bone Ballista: a low stone drum with a turntable and a giant crossbow strung with bone limbs.
## Levels 2 and 3 add to the look (gold rim and spikes / a burning skull; iron-shod limbs and a skull /
## a second pair of limbs and a banner). Also their shots: the fire glob and the 8-direction bolt.

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")

const BASE: float = 45.0
const PROJECTILE_SIZE: Vector2i = Vector2i(12, 12)


func draw(c: Canvas, kind: String, state: String, frame: int, level: int) -> void:
	if kind == "brazier":
		_brazier(c, state, frame, level)
	else:
		_ballista(c, state, frame, level)


# ---------------------------------------------------------------- brazier

func _brazier(c: Canvas, state: String, frame: int, level: int) -> void:
	var firing: bool = state == "fire"
	var bowl_r: float = 9.0 if level < 2 else 10.0
	# Plinth and a stout round shaft.
	c.part()
	c.block(Rect2(8, 37, 16, 3), BASE - 40.0, P.STONE.slice(2, 7), P.STONE.slice(1, 6))
	c.part()
	c.cylinder(16, 28, 37, 4.2, 1.6, P.STONE, P.STONE.slice(2, 6))
	for y: int in [31, 34]:
		c.line(Vector2(12.5, y), Vector2(19.5, y), P.STONE[1])
	# The iron bowl: a back rim, the glowing coals, the front of the bowl with its bands.
	c.part()
	c.ellipse(Vector2(16, 23), Vector2(bowl_r, 2.6), P.IRON.slice(0, 3), 1.0)
	c.part()
	c.ellipse(Vector2(16, 23.5), Vector2(bowl_r - 1.5, 1.8), P.FIRE.slice(0, 3), 1.0)
	c.part()
	c.polygon(PackedVector2Array([Vector2(16 - bowl_r, 23.5), Vector2(16 + bowl_r, 23.5), Vector2(16 + bowl_r - 3, 29),
		Vector2(16 - bowl_r + 3, 29)]), P.IRON, Vector3(-0.3, 0.3, 1))
	for x: float in [16 - bowl_r * 0.5, 16.0, 16 + bowl_r * 0.5]:
		c.line(Vector2(x, 24), Vector2(x + (16 - x) * 0.25, 28.5), P.IRON[0])
	c.line(Vector2(16 - bowl_r, 23.5), Vector2(16 + bowl_r, 23.5), P.GOLD[3] if level >= 2 else P.IRON[3])
	if level >= 2:
		# Iron spikes around the rim.
		for x: float in [16 - bowl_r + 1, 16 - bowl_r * 0.4, 16 + bowl_r * 0.4, 16 + bowl_r - 1]:
			c.part()
			c.polygon(PackedVector2Array([Vector2(x - 0.8, 23), Vector2(x, 19.5), Vector2(x + 0.8, 23)]), P.IRON, Vector3(-0.5, -0.5, 1))
	if level >= 3:
		# A burning skull set into the bowl's front.
		c.part()
		c.ellipse(Vector2(16, 27), Vector2(3.2, 2.8), P.BONE, 0.0, 0.05)
		c.px(15, 27, P.FIRE[4])
		c.px(17, 27, P.FIRE[4])
		c.rect(Rect2i(15, 29, 3, 1), P.BONE[1])
	_brazier_flames(c, firing, frame, level, bowl_r)


func _brazier_flames(c: Canvas, firing: bool, frame: int, level: int, bowl_r: float) -> void:
	var tall: float = (7.0 + level * 1.5) if not firing else [12.0, 15.0, 11.0, 8.0][frame] + level
	c.part(true)
	var count: int = 3 + level
	for k: int in count:
		var x: float = 16.0 - bowl_r * 0.6 + (bowl_r * 1.2) * k / float(count - 1)
		var flick: float = [0.0, 1.5, 0.5, -1.0][(frame + k) % 4]
		var height: float = tall * (0.65 + 0.35 * (1.0 - absf(k - (count - 1) / 2.0) / count)) + flick
		var sway: float = [0.0, 1.0, 0.0, -1.0][(frame + k * 2) % 4]
		c.polygon(PackedVector2Array([Vector2(x - 2.6, 23), Vector2(x + sway, 23 - height), Vector2(x + 2.6, 23)]), [P.FIRE[2]], Vector3(0, 0, 1))
		c.polygon(PackedVector2Array([Vector2(x - 1.4, 23), Vector2(x + sway * 0.5, 23 - height * 0.6), Vector2(x + 1.4, 23)]), [P.FIRE[3]], Vector3(0, 0, 1))
	c.rect(Rect2i(roundi(16 - bowl_r * 0.5), 22, roundi(bowl_r), 1), P.FIRE[4])
	for k: int in 3:
		c.px(13 + k * 3 + frame % 2, roundi(23 - tall - 2 - ((frame + k) % 3) * 2), P.FIRE[4])
	if firing and frame >= 1 and frame <= 2:
		# A glob of burning pitch flung out.
		var glob: Vector2 = Vector2(20 + frame * 3, 23 - tall - frame * 2)
		c.ellipse(glob, Vector2(2.0, 2.0), P.FIRE.slice(2, 6), 0.0, 0.3)


# ---------------------------------------------------------------- ballista

func _ballista(c: Canvas, state: String, frame: int, level: int) -> void:
	var firing: bool = state == "fire"
	# Low stone drum and the wooden turntable on it.
	c.part()
	c.cylinder(16, 35, BASE - 1.5, 11, 3.6, P.STONE, P.STONE.slice(1, 6))
	for x: int in range(6, 27, 4):
		c.line(Vector2(x, 38), Vector2(x, 43), P.STONE[1])
	if level >= 2:
		# A skull mounted on the drum's front.
		c.part()
		c.ellipse(Vector2(16, 40), Vector2(2.6, 2.3), P.BONE, 0.0, 0.05)
		c.px(15, 40, P.OUTLINE)
		c.px(17, 40, P.OUTLINE)
	c.part()
	c.ellipse(Vector2(16, 34), Vector2(9.5, 3.2), P.WOOD.slice(1, 5), 1.0)
	if level >= 3:
		# A war banner on a pole at the back.
		c.part()
		c.rect(Rect2i(7, 16, 1, 18), P.WOOD[2])
		c.px(7, 15, P.GOLD[3])
		var wave: int = [0, 1, 1, 0][frame % 4]
		c.polygon(PackedVector2Array([Vector2(8, 16), Vector2(12, 17.5 + wave), Vector2(11, 20.5 + wave), Vector2(8, 22)]), P.BANNER, Vector3(0.3, 0.3, 1))
	# The stock, aimed right (side art; it shoots wherever the bolt flies).
	var recoil: float = [0.0, -1.0, -1.0, 0.0][frame] if firing else 0.0
	var nut: Vector2 = Vector2(11 + recoil, 29)
	c.part()
	c.block(Rect2(Vector2(8 + recoil, 28), Vector2(17, 2)), 1.5, P.WOOD.slice(2, 5), P.WOOD.slice(1, 4), false)
	c.part()
	c.rect(Rect2i(14, 31, 4, 3), P.WOOD[1])  # the post on the turntable
	var limb_x: float = 22.0 + recoil
	var limb_ramp: Array = P.BONE
	var pairs: int = 1 if level < 3 else 2
	for p: int in pairs:
		var spread: float = 8.0 + p * 3.0
		var x: float = limb_x - p * 2.5
		var tips: Array[Vector2] = [Vector2(x - 3.5, 29 - spread), Vector2(x - 3.5, 29 + spread * 0.6)]
		for tip: Vector2 in tips:
			var mid: Vector2 = Vector2(x, 29).lerp(tip, 0.5) + Vector2(1.2, 0)
			c.part()
			c.capsule(Vector2(x, 29), mid, 1.2, limb_ramp, 0.0)
			c.capsule(mid, tip, 0.9, limb_ramp, -0.04)
			for k: int in 2:
				var knob: Vector2 = Vector2(x, 29).lerp(tip, 0.3 + k * 0.35)
				c.px(roundi(knob.x + 1), roundi(knob.y), P.BONE[3])
			if level >= 2:
				c.px(roundi(tip.x), roundi(tip.y), P.IRON[3])
		# The string: drawn back to the nut while loaded, snapping forward on release.
		var drawn: bool = not firing or frame == 3
		var string_at: Vector2 = nut if drawn else Vector2(x - (2.0 if frame == 1 else 3.0), 29)
		c.line(tips[0], string_at, P.BONE[2])
		c.line(string_at, tips[1], P.BONE[2])
	# The loaded bolt (gone after the release, sliding back in on the last frame).
	if not firing or frame == 3:
		var slide: float = 4.0 if firing else 0.0
		c.part()
		c.line(nut + Vector2(slide, -1), Vector2(27 + slide * 0.5, 28), P.BONE[3])
		c.px(roundi(27 + slide * 0.5), 28, P.IRON[4])
		c.px(roundi(28 + slide * 0.5), 28, P.IRON[3])


# ---------------------------------------------------------------- shots

## A glob of burning pitch (2 frames, flickering).
func fire_glob_frames() -> Array[Image]:
	var frames: Array[Image] = []
	for frame: int in 2:
		var c: Canvas = Canvas.new(PROJECTILE_SIZE.x, PROJECTILE_SIZE.y)
		c.part(true)
		c.ellipse(Vector2(6, 6.5), Vector2(3.4, 3.2), P.FIRE.slice(1, 5), 0.0, 0.2)
		c.ellipse(Vector2(5.5, 6), Vector2(1.6, 1.5), P.FIRE.slice(4, 6), 0.0, 0.2)
		c.px(2 + frame, 2, P.FIRE[3])
		c.px(9 - frame, 3, P.FIRE[2])
		frames.append(c.finish(false, P.FIRE[0]))
	return frames


## The ballista bolt along one of 8 directions (bolt_0 points right, then every 45 degrees clockwise):
## a long bone shaft, an iron head, bone fins.
func bolt(direction: int) -> Image:
	var c: Canvas = Canvas.new(PROJECTILE_SIZE.x, PROJECTILE_SIZE.y)
	var dir: Vector2i = [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
		Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)][direction]
	var center: Vector2i = Vector2i(6, 6)
	var across: Vector2i = Vector2i(-dir.y, dir.x)
	c.part()
	for i: int in range(-5, 4):
		c.px(center.x + dir.x * i, center.y + dir.y * i, P.BONE[3] if i % 2 == 0 else P.BONE[2])
	c.px(center.x + dir.x * 4, center.y + dir.y * 4, P.IRON[3])
	c.px(center.x + dir.x * 5, center.y + dir.y * 5, P.IRON[4])
	c.px(center.x + dir.x * 4 + across.x, center.y + dir.y * 4 + across.y, P.IRON[2])
	c.px(center.x + dir.x * 4 - across.x, center.y + dir.y * 4 - across.y, P.IRON[2])
	for k: int in [-5, -4]:
		c.px(center.x + dir.x * k + across.x, center.y + dir.y * k + across.y, P.BONE[1])
		c.px(center.x + dir.x * k - across.x, center.y + dir.y * k - across.y, P.BONE[1])
	return c.finish(false)
