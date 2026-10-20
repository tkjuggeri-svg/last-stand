extends RefCounted
## The ten tower evolutions (dev-time art generator): 32x48 frames, base on art row 45, the same
## 3/4 view and top-left light as tower_art.gd. Each has its own silhouette so a glance tells them
## apart (see ART_DIRECTION.md):
##   Sniper Nest: a tall slim spire with a roofed perch and a marksman with a great bow.
##   Volley Tower: a wide, low timber bastion with three archers aiming high and arrow racks.
##   Siege Mortar: a square stone emplacement with a fat bronze mortar pointing at the sky.
##   Grapeshot Battery: a drum tower with three short, flared barrels in a fan behind an iron shield.
##   Glacier Spire: a jagged spire of glacier ice with a huge crystal.
##   Shatter Shrine: a low shrine of two pillars and a cracked, broken crystal ring of violet ice.
##   Pyre of Souls: a stack of skulls carrying a bowl of green-white soul fire.
##   Beacon Flame: a tall iron beacon post with a great golden fire and a ring of light.
##   Harpoon: a heavy iron ballista with a barbed harpoon and a chain drum.
##   Repeater: a light ballista with a bolt magazine on top and a crank.
## Also their shots and effects: sniper shot and harpoon (8 directions), mortar shell, soul fire,
## soul burst, arrow rain, grapeshot blast (8 directions) and the status marks.

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")

const SIZE: Vector2i = Vector2i(32, 48)
const BASE: float = 45.0
const FRAMES: int = 4
## The evolutions in sheet order (sheet_layouts.TOWERS: idle row, then fire row, for each).
const KINDS: Array[String] = ["sniper_nest", "volley_tower", "siege_mortar", "grapeshot_battery", "glacier_spire",
	"shatter_shrine", "pyre_of_souls", "beacon_flame", "harpoon", "repeater"]
const SHATTER_ICE: Array[Color] = [Color("231a3e"), Color("43327a"), Color("6f5cc0"), Color("a99af0"), Color("e4dcff"), Color("ffffff")]
const FX_SIZE: Vector2i = Vector2i(64, 64)
const STATUS_SIZE: Vector2i = Vector2i(24, 28)
const DIRS: Array[Vector2] = [Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector2(-1, 1), Vector2(-1, 0), Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1)]


## Per evolution: an idle row and a fire row (4 frames each).
func sheet_rows() -> Array[Array]:
	var rows: Array[Array] = []
	for kind: String in KINDS:
		for state: String in ["idle", "fire"]:
			var frames: Array[Image] = []
			for i: int in FRAMES:
				frames.append(tower(kind, state, i))
			rows.append(frames)
	return rows


func tower(kind: String, state: String, frame: int) -> Image:
	var c: Canvas = Canvas.new(SIZE.x, SIZE.y)
	var firing: bool = state == "fire"
	call("_" + kind, c, firing, frame)
	c.finish()
	c.ground_shadow(Vector2(17.5, BASE), Vector2(13, 3.2))
	return c.image


# ---------------------------------------------------------------- archer branches

func _sniper_nest(c: Canvas, firing: bool, frame: int) -> void:
	# A slim stone spire rising almost to the top of the frame.
	c.part()
	c.block(Rect2(11, 22, 10, 4), BASE - 26.0, P.STONE.slice(2, 7), P.STONE.slice(1, 6))
	for y: int in range(29, 44, 4):
		c.line(Vector2(11, y), Vector2(20, y), P.STONE[1])
	c.rect(Rect2i(15, 31, 2, 4), P.OUTLINE)
	# The perch: a jutting timber floor and a pointed slate roof on posts.
	c.part()
	c.block(Rect2(7, 18, 18, 4), 2.0, P.WOOD.slice(2, 5), P.WOOD.slice(1, 4), false)
	c.part()
	for x: int in [8, 23]:
		c.rect(Rect2i(x, 9, 1, 10), P.WOOD[2])
	c.part()
	c.polygon(PackedVector2Array([Vector2(5, 10), Vector2(16, 1), Vector2(27, 10)]), P.SLATE, Vector3(-0.3, -0.6, 0.8))
	c.line(Vector2(5, 10), Vector2(27, 10), P.SLATE[3])
	c.px(16, 0, P.GOLD[3])
	# The marksman, kneeling, drawing a bow taller than himself.
	var draw: int = [1, 2, 3, 0][frame] if firing else 0
	c.part()
	c.ellipse(Vector2(13, 16), Vector2(2.6, 2.8), P.HOOD, 0.0, 0.1)
	c.ellipse(Vector2(13, 12.6), Vector2(2.1, 2.0), P.HOOD, 0.0, 0.15)
	c.px(14, 13, P.SKIN[2])
	var pull: float = [0.0, 1.0, 3.0, 0.0][draw]
	var top: Vector2 = Vector2(20 - pull * 0.3, 8)
	var bottom: Vector2 = Vector2(20 - pull * 0.3, 20)
	c.part()
	c.line(top, Vector2(21.5, 13), P.WOOD[4])
	c.line(Vector2(21.5, 13), bottom, P.WOOD[3])
	var hand: Vector2 = Vector2(17 - pull, 14)
	c.line(top, hand if draw in [1, 2] else Vector2(top.x, 14), P.BONE[2])
	c.line(hand if draw in [1, 2] else Vector2(top.x, 14), bottom, P.BONE[2])
	if draw in [1, 2]:
		c.line(hand, Vector2(24, 14), P.STEEL[4])
	# A scope-like sighting glint that blinks while idle.
	if not firing and frame == 1:
		c.part(true)
		c.px(22, 12, Color("ffffff"))
	if firing and frame == 2:
		c.part(true)
		c.line(Vector2(24, 14), Vector2(31, 14), P.GOLD[4])


func _volley_tower(c: Canvas, firing: bool, frame: int) -> void:
	# A wide, low bastion: stone footing, timber walls, a crenellated fighting deck.
	c.part()
	c.block(Rect2(3, 32, 26, 5), BASE - 37.0, P.STONE.slice(2, 7), P.STONE.slice(1, 6))
	c.part()
	c.block(Rect2(4, 26, 24, 6), 4.0, P.WOOD.slice(2, 5), P.WOOD.slice(1, 4), false)
	for x: int in range(6, 27, 4):
		c.line(Vector2(x, 32), Vector2(x, 35), P.WOOD[1])
	# Arrow racks bristling at both ends.
	for x: int in [5, 26]:
		c.part()
		c.rect(Rect2i(x - 1, 22, 3, 5), P.LEATHER[2])
		for k: int in 3:
			c.line(Vector2(x - 1 + k, 21), Vector2(x - 1 + k, 18 - k % 2), P.WOOD[4])
			c.px(x - 1 + k, 17 - k % 2, P.BANNER[3])
	# Three archers aiming high, loosing one after the other.
	for k: int in 3:
		var x: float = 10.0 + k * 6.0
		var loosed: bool = firing and frame >= k + 1
		c.part()
		c.ellipse(Vector2(x, 23), Vector2(2.4, 2.6), P.HOOD, 0.0, 0.1)
		c.ellipse(Vector2(x, 19.8), Vector2(1.9, 1.8), P.HOOD, 0.0, 0.15)
		c.px(roundi(x) + 1, 20, P.SKIN[2])
		# The bow tilted up toward the sky.
		var tip_a: Vector2 = Vector2(x + 1.5, 13)
		var tip_b: Vector2 = Vector2(x + 5.5, 19)
		c.part()
		c.line(tip_a, Vector2(x + 4.5, 15), P.WOOD[4])
		c.line(Vector2(x + 4.5, 15), tip_b, P.WOOD[3])
		c.line(tip_a, tip_b, P.BONE[2])
		if not loosed:
			c.line(Vector2(x + 2, 18), Vector2(x + 6, 12), P.WOOD[4])
			c.px(roundi(x) + 6, 11, P.STEEL[4])
	if firing:
		c.part(true)
		for k: int in frame + 1:
			c.line(Vector2(12 + k * 6, 9 - frame * 2), Vector2(14 + k * 6, 6 - frame * 2), P.BONE[3])


# ---------------------------------------------------------------- cannon branches

func _siege_mortar(c: Canvas, firing: bool, frame: int) -> void:
	# A square, sandbagged stone emplacement.
	c.part()
	c.block(Rect2(4, 30, 24, 8), BASE - 38.0, P.STONE_WARM.slice(1, 6), P.STONE_WARM.slice(0, 5))
	for y: int in [40, 43]:
		c.line(Vector2(4, y), Vector2(27, y), P.STONE_WARM[0])
	# A pile of great shells at the back corner.
	for p: Vector2 in [Vector2(7, 29), Vector2(10, 29), Vector2(8.5, 27)]:
		c.part()
		c.ellipse(p, Vector2(1.9, 1.8), P.IRON, 0.0, 0.1)
	# The mortar: a fat bronze pot on a wooden bed, mouth to the sky.
	var kick: float = [2.0, 1.0, 0.0, 0.0][frame] if firing else 0.0
	c.part()
	c.block(Rect2(12, 31, 12, 4), 2.0, P.WOOD.slice(2, 5), P.WOOD.slice(1, 4), false)
	c.part()
	c.cylinder(18, 21 + kick, 33, 6.0, 2.2, P.BRONZE, [], true)
	c.ellipse(Vector2(18, 21 + kick), Vector2(6.0, 2.2), P.BRONZE.slice(2, 5), 1.2)
	c.part()
	c.ellipse(Vector2(18, 21 + kick), Vector2(4.2, 1.5), [P.OUTLINE, P.IRON[0]], 1.0)
	for y: float in [25.0, 29.0]:
		c.line(Vector2(12.2, y + kick), Vector2(23.8, y + kick), P.BRONZE[1])
	c.px(14, 27 + roundi(kick), P.GOLD[4])
	if not firing:
		c.part(true)
		c.px(23, 26, P.FIRE[3] if frame % 2 == 0 else P.FIRE[2])  # the slow match
		return
	c.part(true)
	match frame:
		0:
			c.ellipse(Vector2(18, 17), Vector2(5.0, 3.0), P.FIRE.slice(2, 6), 0.0, 0.3)
		1:
			c.ellipse(Vector2(18, 13), Vector2(5.5, 5.0), P.SMOKE.slice(1, 5), 0.0, 0.1)
			c.ellipse(Vector2(18, 17), Vector2(2.5, 1.6), P.FIRE.slice(3, 6), 0.0, 0.3)
		2:
			c.ellipse(Vector2(17, 9), Vector2(6.0, 5.0), P.SMOKE.slice(1, 5), 0.0, 0.0)
		3:
			c.ellipse(Vector2(16, 5), Vector2(5.0, 3.5), P.SMOKE.slice(1, 4), 0.0, 0.0)


func _grapeshot_battery(c: Canvas, firing: bool, frame: int) -> void:
	# Drum tower.
	c.part()
	c.cylinder(16, 31, BASE - 1.5, 12, 4.5, P.STONE, P.STONE.slice(1, 6))
	for x: int in range(6, 27, 3):
		c.line(Vector2(x, 36), Vector2(x, 42), P.STONE[1])
	# An iron shield plate across the front.
	c.part()
	c.polygon(PackedVector2Array([Vector2(6, 28), Vector2(26, 28), Vector2(25, 33), Vector2(7, 33)]), P.IRON, Vector3(-0.2, 0.2, 1))
	for x: int in [9, 16, 23]:
		c.px(x, 30, P.IRON[4])
	# Three short, flared barrels fanned out to the right.
	var recoil: float = [1.5, 1.0, 0.5, 0.0][frame] if firing else 0.0
	var aims: Array[Vector2] = [Vector2(1, -0.55), Vector2(1, 0), Vector2(1, 0.55)]
	for k: int in 3:
		var dir: Vector2 = aims[k].normalized()
		var breech: Vector2 = Vector2(14 - recoil, 21 + k * 3)
		var muzzle: Vector2 = breech + dir * 9.0
		c.part()
		c.capsule(breech, muzzle, 1.8, P.IRON, 0.05)
		c.ellipse(muzzle + dir * 0.6, Vector2(2.4, 2.4), P.IRON.slice(1, 5), 0.0, 0.1)
		c.px(roundi(muzzle.x + dir.x), roundi(muzzle.y + dir.y), P.OUTLINE)
		if firing and frame < 2:
			c.part(true)
			c.ellipse(muzzle + dir * 3.5, Vector2(2.6, 2.2), P.FIRE.slice(2, 6), 0.0, 0.3)
	c.part()
	c.ellipse(Vector2(12 - recoil, 24), Vector2(2.6, 4.5), P.WOOD.slice(1, 5), 0.0)
	if firing and frame >= 2:
		c.part(true)
		c.ellipse(Vector2(27, 22 - frame), Vector2(3.5, 3.0), P.SMOKE.slice(1, 4), 0.0, 0.0)


# ---------------------------------------------------------------- frost branches

func _glacier_spire(c: Canvas, firing: bool, frame: int) -> void:
	var phase: float = TAU * frame / FRAMES
	# A jagged crag of glacier ice: several leaning spikes of different heights.
	var spikes: Array[Array] = [[Vector2(9, 44), 22.0, -1.5], [Vector2(23, 44), 20.0, 1.5], [Vector2(13, 44), 30.0, -0.5],
		[Vector2(19, 44), 27.0, 0.8], [Vector2(16, 44), 34.0, 0.0]]
	for spike: Array in spikes:
		var foot: Vector2 = spike[0]
		var height: float = spike[1]
		var lean: float = spike[2]
		var tip: Vector2 = foot + Vector2(lean * 3.0, -height)
		c.part()
		c.polygon(PackedVector2Array([foot + Vector2(-3.5, 0), tip, foot + Vector2(0, 0.5)]), P.ICE, Vector3(-0.8, -0.3, 0.6))
		c.polygon(PackedVector2Array([foot + Vector2(0, 0.5), tip, foot + Vector2(3.5, 0)]), P.ICE, Vector3(0.7, 0.1, 0.5))
		c.line(tip, foot + Vector2(0, -1), P.ICE[4])
	# The great crystal held at the top, pulsing.
	var bob: float = roundf(sin(phase)) if not firing else -1.0
	var center: Vector2 = Vector2(16, 8 + bob)
	var ramp: Array = P.ARCANE_ICE if firing and frame < 2 else P.ICE
	c.part()
	c.polygon(PackedVector2Array([center + Vector2(0, -7), center + Vector2(-4.5, 0), center + Vector2(0, 6), center + Vector2(4.5, 0)]), ramp, Vector3(-0.5, -0.5, 0.7))
	c.line(center + Vector2(0, -7), center + Vector2(0, 6), P.ICE[5])
	c.px(14, roundi(center.y) - 3, Color("ffffff"))
	c.part(true)
	var reach: float = 8.0 if not firing else [9.0, 12.0, 14.0, 10.0][frame]
	for k: int in 8:
		var a: float = phase + k * TAU / 8.0
		var p: Vector2 = center + Vector2(cos(a) * reach, sin(a) * reach * 0.5)
		if firing or k % 2 == frame % 2:
			c.px(roundi(p.x), roundi(p.y), P.ICE[5] if k % 2 == 0 else P.ICE[4])


func _shatter_shrine(c: Canvas, firing: bool, frame: int) -> void:
	var phase: float = TAU * frame / FRAMES
	# A low dais and two pillars.
	c.part()
	c.block(Rect2(5, 36, 22, 5), BASE - 41.0, P.SLATE.slice(1, 5), P.SLATE.slice(0, 4))
	for x: float in [8.5, 23.5]:
		c.part()
		c.cylinder(x, 22, 37, 2.4, 1.0, P.SLATE, P.SLATE.slice(2, 5))
		c.px(roundi(x) - 1, 28, SHATTER_ICE[3])
		c.px(roundi(x) - 1, 32, SHATTER_ICE[2])
	c.part()
	c.block(Rect2(5, 19, 22, 3), 1.5, P.SLATE.slice(2, 5), P.SLATE.slice(1, 4), false)
	# A broken ring of four violet ice shards turning around a big cracked crystal between the pillars.
	var center: Vector2 = Vector2(16, 28 + roundf(sin(phase) * 0.6))
	var spread: float = 1.0 if not firing else [1.0, 1.3, 1.6, 1.2][frame]
	for k: int in 4:
		var a: float = phase * 0.25 + k * TAU / 4.0 + 0.4
		var p: Vector2 = center + Vector2(cos(a) * 6.5 * spread, sin(a) * 3.5 * spread)
		c.part()
		c.polygon(PackedVector2Array([p + Vector2(0, -2.5), p + Vector2(-1.6, 0.5), p + Vector2(0.4, 2.2), p + Vector2(1.7, -0.2)]), SHATTER_ICE.slice(0, 4), Vector3(-0.5, -0.5, 0.7))
	c.part()
	c.polygon(PackedVector2Array([center + Vector2(0, -6), center + Vector2(-4, 0), center + Vector2(0, 5), center + Vector2(4, 0)]), SHATTER_ICE.slice(1, 4), Vector3(-0.4, -0.6, 0.7))
	c.line(center + Vector2(-1, -4), center + Vector2(1, 0), P.OUTLINE)  # the crack
	c.line(center + Vector2(1, 0), center + Vector2(0, 3), P.OUTLINE)
	c.px(roundi(center.x) - 2, roundi(center.y) - 2, SHATTER_ICE[5])
	if firing:
		c.part(true)
		for k: int in 6:
			var p2: Vector2 = center + Vector2.from_angle(k * TAU / 6.0) * (7.0 + frame * 2.0)
			c.px(roundi(p2.x), roundi(p2.y), SHATTER_ICE[4])


# ---------------------------------------------------------------- brazier branches

func _pyre_of_souls(c: Canvas, firing: bool, frame: int) -> void:
	# A heap of skulls carrying a black iron bowl.
	var skulls: Array[Vector2] = [Vector2(10, 41), Vector2(16, 42), Vector2(22, 41), Vector2(13, 37), Vector2(19, 37), Vector2(16, 33)]
	for p: Vector2 in skulls:
		c.part()
		c.ellipse(p, Vector2(3.0, 2.6), P.BONE, 0.0, 0.05)
		c.px(roundi(p.x) - 1, roundi(p.y), P.SOUL[3] if frame % 2 == 0 else P.SOUL[2])
		c.px(roundi(p.x) + 1, roundi(p.y), P.SOUL[3] if frame % 2 == 0 else P.SOUL[2])
	c.part()
	c.ellipse(Vector2(16, 26), Vector2(9.0, 2.6), P.IRON.slice(0, 3), 1.0)
	c.part()
	c.polygon(PackedVector2Array([Vector2(7, 26.5), Vector2(25, 26.5), Vector2(22, 31), Vector2(10, 31)]), P.IRON, Vector3(-0.3, 0.3, 1))
	c.line(Vector2(7, 26.5), Vector2(25, 26.5), P.SOUL[2])
	# Tall, wavering soul flames.
	var tall: float = 13.0 if not firing else [17.0, 21.0, 16.0, 13.0][frame]
	c.part(true)
	for k: int in 5:
		var x: float = 10.0 + k * 3.0
		var flick: float = [0.0, 2.0, 0.5, -1.5][(frame + k) % 4]
		var height: float = tall * (0.6 + 0.4 * (1.0 - absf(k - 2.0) / 3.0)) + flick
		var sway: float = [0.0, 1.0, 0.0, -1.0][(frame + k * 2) % 4]
		c.polygon(PackedVector2Array([Vector2(x - 2.5, 26), Vector2(x + sway, 26 - height), Vector2(x + 2.5, 26)]), [P.SOUL[2]], Vector3(0, 0, 1))
		c.polygon(PackedVector2Array([Vector2(x - 1.2, 26), Vector2(x + sway * 0.5, 26 - height * 0.6), Vector2(x + 1.2, 26)]), [P.SOUL[4]], Vector3(0, 0, 1))
	# A wisp face rising from the fire.
	var wisp_y: int = 8 - frame
	c.px(15, wisp_y, P.SOUL[4])
	c.px(17, wisp_y, P.SOUL[4])
	c.px(16, wisp_y + 2, P.SOUL[3])


func _beacon_flame(c: Canvas, firing: bool, frame: int) -> void:
	# A stone footing and a tall iron post with braces.
	c.part()
	c.block(Rect2(9, 38, 14, 3), BASE - 41.0, P.STONE.slice(2, 7), P.STONE.slice(1, 6))
	c.part()
	c.capsule(Vector2(16, 38), Vector2(16, 16), 1.6, P.IRON, 0.05)
	c.line(Vector2(11, 38), Vector2(15, 28), P.IRON[2])
	c.line(Vector2(21, 38), Vector2(17, 28), P.IRON[1])
	# The beacon cage on top.
	c.part()
	c.ellipse(Vector2(16, 15), Vector2(6.0, 1.8), P.IRON.slice(0, 3), 1.0)
	for x: int in [10, 13, 19, 22]:
		c.line(Vector2(x, 15), Vector2(x + (1 if x < 16 else -1), 10), P.IRON[3])
	c.line(Vector2(11, 10), Vector2(21, 10), P.GOLD[2])
	# The great golden fire, and a ring of light that pulses (spreads when it "fires").
	var tall: float = 10.0 + [0.0, 1.0, 0.0, -1.0][frame]
	c.part(true)
	for k: int in 3:
		var x: float = 13.0 + k * 3.0
		var flick: float = [0.0, 1.5, 0.5, -1.0][(frame + k) % 4]
		c.polygon(PackedVector2Array([Vector2(x - 2.8, 15), Vector2(x, 15 - tall - flick), Vector2(x + 2.8, 15)]), [P.FIRE[3]], Vector3(0, 0, 1))
		c.polygon(PackedVector2Array([Vector2(x - 1.4, 15), Vector2(x, 15 - tall * 0.6 - flick), Vector2(x + 1.4, 15)]), [P.FIRE[5]], Vector3(0, 0, 1))
	var ring: float = 9.0 if not firing else [10.0, 12.0, 14.0, 15.0][frame]
	for k: int in 12:
		if not firing and k % 3 != frame % 3:
			continue
		var p: Vector2 = Vector2(16, 9) + Vector2.from_angle(k * TAU / 12.0) * ring
		c.px(roundi(p.x), roundi(p.y), P.GOLD[4])


# ---------------------------------------------------------------- ballista branches

func _harpoon(c: Canvas, firing: bool, frame: int) -> void:
	# An iron-bound stone drum.
	c.part()
	c.cylinder(16, 35, BASE - 1.5, 11, 3.6, P.STONE, P.STONE.slice(1, 6))
	for x: int in range(6, 27, 5):
		c.rect(Rect2i(x, 37, 1, 6), P.IRON[2])
	# A chain drum at the back, its chain running to the harpoon.
	c.part()
	c.cylinder(9, 26, 32, 3.2, 1.4, P.WOOD, P.WOOD.slice(1, 4), false)
	for y: int in [27, 29, 31]:
		c.line(Vector2(6, y), Vector2(12, y), P.IRON[3])
	# A heavy iron stock and thick iron limbs.
	var recoil: float = [-1.5, -1.0, -0.5, 0.0][frame] if firing else 0.0
	c.part()
	c.block(Rect2(Vector2(10 + recoil, 27), Vector2(16, 3)), 2.0, P.IRON.slice(2, 5), P.IRON.slice(1, 4), false)
	for tip: Vector2 in [Vector2(20 + recoil, 18), Vector2(20 + recoil, 36)]:
		c.part()
		c.capsule(Vector2(23 + recoil, 28.5), tip, 1.5, P.IRON, 0.0)
	var loaded: bool = not firing or frame == 3
	c.line(Vector2(20 + recoil, 18), Vector2(13 + recoil, 28.5) if loaded else Vector2(21, 28.5), P.BONE[2])
	c.line(Vector2(13 + recoil, 28.5) if loaded else Vector2(21, 28.5), Vector2(20 + recoil, 36), P.BONE[2])
	if loaded:
		# The barbed harpoon.
		c.part()
		c.line(Vector2(13 + recoil, 27.5), Vector2(29 + recoil, 27.5), P.IRON[4])
		for k: int in 2:
			c.px(roundi(29 + recoil) - k * 2, 26, P.IRON[3])
			c.px(roundi(29 + recoil) - k * 2, 29, P.IRON[3])
		c.px(roundi(30 + recoil), 27, P.STEEL[4])
	else:
		c.part(true)
		for x: int in range(12, 31, 3):
			c.px(x, 27 + (1 if x % 6 < 3 else 0), P.IRON[3])  # the chain paying out


func _repeater(c: Canvas, firing: bool, frame: int) -> void:
	# A low drum and a turntable.
	c.part()
	c.cylinder(16, 36, BASE - 1.5, 10, 3.4, P.STONE, P.STONE.slice(1, 6))
	c.part()
	c.ellipse(Vector2(16, 35), Vector2(9.0, 3.0), P.WOOD.slice(1, 5), 1.0)
	# A light stock with small bone limbs.
	var kick: float = [-0.5, 0.0, -0.5, 0.0][frame] if firing else 0.0
	c.part()
	c.block(Rect2(Vector2(8 + kick, 29), Vector2(17, 2)), 1.5, P.WOOD.slice(2, 5), P.WOOD.slice(1, 4), false)
	for tip: Vector2 in [Vector2(20 + kick, 23), Vector2(20 + kick, 35)]:
		c.part()
		c.capsule(Vector2(22 + kick, 30), tip, 0.9, P.BONE, 0.0)
	var string_x: float = 13.0 + kick if not firing or frame % 2 == 1 else 20.0
	c.line(Vector2(20 + kick, 23), Vector2(string_x, 30), P.BONE[2])
	c.line(Vector2(string_x, 30), Vector2(20 + kick, 35), P.BONE[2])
	# The bolt magazine on top: a wooden box with bolt ends showing.
	c.part()
	c.block(Rect2(Vector2(11 + kick, 22), Vector2(8, 4)), 4.0, P.WOOD.slice(2, 5), P.WOOD.slice(1, 4), false)
	var left_in_box: int = 3 if not firing else 3 - frame % 2
	for k: int in left_in_box:
		c.px(roundi(19 + kick), 23 + k, P.IRON[4])
	# The crank on the side, turning.
	c.part()
	var crank: Vector2 = Vector2(9, 28) + Vector2.from_angle(TAU * frame / FRAMES) * 2.0
	c.line(Vector2(9, 28), crank, P.IRON[3])
	c.px(roundi(crank.x), roundi(crank.y), P.WOOD[4])
	if firing and frame % 2 == 0:
		c.part(true)
		c.line(Vector2(24, 29), Vector2(30, 29), P.BONE[3])


# ---------------------------------------------------------------- shots

## A marksman's shot (8 directions): a long dark shaft with a bright streak behind it.
func sniper_shot(direction: int) -> Image:
	var c: Canvas = Canvas.new(12, 12)
	var dir: Vector2 = DIRS[direction]
	var step: Vector2i = Vector2i(dir)
	c.part()
	for i: int in range(-5, 5):
		c.px(6 + step.x * i, 6 + step.y * i, P.GOLD[4] if i < -2 else P.WOOD[4])
	c.px(6 + step.x * 5, 6 + step.y * 5, P.STEEL[5])
	return c.finish(false)


## The harpoon (8 directions): a barbed iron head and a short trailing chain.
func harpoon(direction: int) -> Image:
	var c: Canvas = Canvas.new(12, 12)
	var step: Vector2i = Vector2i(DIRS[direction])
	var across: Vector2i = Vector2i(-step.y, step.x)
	c.part()
	for i: int in range(-5, 4):
		c.px(6 + step.x * i, 6 + step.y * i, P.IRON[3] if i % 2 == 0 else P.IRON[2])
	c.px(6 + step.x * 4, 6 + step.y * 4, P.STEEL[4])
	c.px(6 + step.x * 5, 6 + step.y * 5, P.STEEL[5])
	for side: int in [-1, 1]:
		c.px(6 + step.x * 3 + across.x * side, 6 + step.y * 3 + across.y * side, P.IRON[4])
	return c.finish(false)


## The mortar's great shell (2 frames: its fuse sputters).
func mortar_shell_frames() -> Array[Image]:
	var frames: Array[Image] = []
	for frame: int in 2:
		var c: Canvas = Canvas.new(12, 12)
		c.part()
		c.ellipse(Vector2(6, 6.5), Vector2(4.2, 4.0), P.IRON, 0.0, 0.1)
		c.part(true)
		c.px(7, 1 + frame, P.FIRE[4])
		c.px(8 - frame, 1, P.FIRE[3])
		frames.append(c.finish())
	return frames


# ---------------------------------------------------------------- effects

## Soul fire on the ground (4 frames, 48x32 like the burn): green-white flames on a dark patch.
func soul_burn_frames() -> Array[Image]:
	var frames: Array[Image] = []
	for frame: int in 4:
		var c: Canvas = Canvas.new(48, 32)
		c.part(true)
		c.ellipse(Vector2(24, 18), Vector2(17, 8), [Color(0.04, 0.08, 0.07, 0.6)], 1.0)
		for k: int in 7:
			var x: float = 10.0 + k * 4.5 + [0.0, 1.0, 0.0, -1.0][(frame + k) % 4]
			var y: float = 18.0 + [2.0, -1.0, 3.0, 0.0, -2.0, 1.0, 2.0][k]
			var height: float = 6.0 + ((frame + k * 3) % 4) * 1.5
			c.polygon(PackedVector2Array([Vector2(x - 2, y), Vector2(x, y - height), Vector2(x + 2, y)]), [P.SOUL[2]], Vector3(0, 0, 1))
			c.polygon(PackedVector2Array([Vector2(x - 1, y), Vector2(x, y - height * 0.55), Vector2(x + 1, y)]), [P.SOUL[4]], Vector3(0, 0, 1))
		frames.append(c.finish(false))
	return frames


## A soul burst (7 frames, 56x56): a ring of soul fire flaring out from a corpse, a wailing wisp.
func soul_burst_frames() -> Array[Image]:
	var frames: Array[Image] = []
	for frame: int in 7:
		var c: Canvas = Canvas.new(56, 56)
		var t: float = frame / 6.0
		var radius: float = 6.0 + 20.0 * t
		c.part(true)
		if frame < 3:
			c.ellipse(Vector2(28, 30), Vector2(radius * 0.6, radius * 0.45), P.SOUL.slice(2, 5), 0.0, 0.3)
		for k: int in 14:
			var a: float = k * TAU / 14.0 + t
			var p: Vector2 = Vector2(28, 30) + Vector2(cos(a) * radius, sin(a) * radius * 0.6)
			if frame < 6:
				c.ellipse(p, Vector2(2.0, 2.0) * (1.0 - t * 0.6), P.SOUL.slice(1, 5), 0.0, 0.2)
		if frame >= 1 and frame < 6:
			var wisp_y: float = 26.0 - frame * 3.0
			c.ellipse(Vector2(28, wisp_y), Vector2(3.0, 3.5), [P.SOUL[3]], 0.5)
			c.px(27, roundi(wisp_y), P.SOUL[0])
			c.px(29, roundi(wisp_y), P.SOUL[0])
		frames.append(c.finish(false))
	return frames


## Arrow rain (5 frames, 64x64): arrows streak down into the marked circle and stick in the ground.
func arrow_rain_frames() -> Array[Image]:
	var frames: Array[Image] = []
	var spots: Array[Vector2] = [Vector2(20, 40), Vector2(32, 44), Vector2(44, 38), Vector2(26, 50), Vector2(39, 52),
		Vector2(16, 48), Vector2(48, 47), Vector2(31, 36), Vector2(23, 44), Vector2(42, 44)]
	for frame: int in 5:
		var c: Canvas = Canvas.new(FX_SIZE.x, FX_SIZE.y)
		for k: int in spots.size():
			var spot: Vector2 = spots[k]
			var fall: float = clampf(frame * 1.0 - (k % 3) * 0.5, 0.0, 3.0) / 3.0
			c.part()
			if fall < 1.0:
				var head: Vector2 = spot + Vector2(-6, -24) * (1.0 - fall)
				c.line(head + Vector2(-2, -7), head, P.WOOD[4])
				c.px(roundi(head.x), roundi(head.y), P.STEEL[4])
			else:
				c.line(spot + Vector2(-1, -4), spot, P.WOOD[3])  # stuck in the ground
				c.px(roundi(spot.x) - 1, roundi(spot.y) - 4, P.BANNER[3])
				if frame == 3:
					c.part(true)
					c.px(roundi(spot.x) + 1, roundi(spot.y), P.DIRT[5])
		frames.append(c.finish(false))
	return frames


## A grapeshot blast (4 frames, 64x64, centred on the muzzle) toward one of 8 directions: a flash and
## a fan of pellet streaks and smoke.
func grapeshot_frames(direction: int) -> Array[Image]:
	var frames: Array[Image] = []
	var dir: Vector2 = DIRS[direction].normalized()
	var center: Vector2 = Vector2(32, 32)
	for frame: int in 4:
		var c: Canvas = Canvas.new(FX_SIZE.x, FX_SIZE.y)
		c.part(true)
		if frame < 2:
			c.ellipse(center + dir * 4.0, Vector2(4.0, 4.0), P.FIRE.slice(2, 6), 0.0, 0.3)
		for k: int in 9:
			var a: float = dir.angle() + deg_to_rad(-35.0 + k * 8.75)
			var reach: float = 8.0 + frame * 7.0 + (k % 3) * 2.0
			var p: Vector2 = center + Vector2.from_angle(a) * reach
			c.px(roundi(p.x), roundi(p.y), P.IRON[4] if frame < 3 else P.SMOKE[3])
			if frame < 3:
				var q: Vector2 = center + Vector2.from_angle(a) * (reach - 3.0)
				c.px(roundi(q.x), roundi(q.y), P.FIRE[3])
		if frame >= 1:
			c.ellipse(center + dir * (6.0 + frame * 3.0), Vector2(3.0 + frame, 2.5 + frame * 0.6), P.SMOKE.slice(1, 4), 0.0, 0.0)
		frames.append(c.finish(false))
	return frames


## Status marks (24x28): "frozen" (an ice block around the body, 2 frames), "shattered" (a cracked
## violet rune over the head, 4 frames), "beacon_ember" (the ember over a boosted tower, 4 frames) and
## "silenced" (a cracked bell over a silenced tower, 4 frames).
func status_rows() -> Array[Array]:
	var frozen: Array[Image] = []
	for frame: int in 2:
		var c: Canvas = Canvas.new(STATUS_SIZE.x, STATUS_SIZE.y)
		c.part()
		c.polygon(PackedVector2Array([Vector2(4, 8), Vector2(12, 3), Vector2(20, 8), Vector2(20, 24), Vector2(12, 27), Vector2(4, 24)]),
			[Color(0.31, 0.58, 0.78, 0.55), Color(0.56, 0.82, 0.94, 0.55), Color(0.8, 0.95, 1.0, 0.6)], Vector3(-0.4, -0.4, 0.8))
		c.line(Vector2(6, 9), Vector2(12, 5), P.ICE[5])
		c.line(Vector2(18, 10 + frame * 2), Vector2(18, 16 + frame * 2), P.ICE[5])
		frozen.append(c.finish(true, P.ICE[1]))
	var shattered: Array[Image] = []
	for frame: int in 4:
		var c2: Canvas = Canvas.new(STATUS_SIZE.x, STATUS_SIZE.y)
		var glow: int = [3, 4, 5, 4][frame]
		c2.part()
		c2.polygon(PackedVector2Array([Vector2(12, 8), Vector2(17, 14), Vector2(12, 20), Vector2(7, 14)]), SHATTER_ICE.slice(1, glow + 1), Vector3(-0.4, -0.5, 0.8))
		c2.line(Vector2(10, 11), Vector2(13, 15), P.OUTLINE)
		c2.line(Vector2(13, 15), Vector2(12, 18), P.OUTLINE)
		c2.px(14, 12, SHATTER_ICE[5])
		shattered.append(c2.finish())
	var ember: Array[Image] = []
	for frame: int in 4:
		var c3: Canvas = Canvas.new(STATUS_SIZE.x, STATUS_SIZE.y)
		var flick: float = [0.0, 1.0, 0.5, -0.5][frame]
		c3.part()
		c3.polygon(PackedVector2Array([Vector2(8, 20), Vector2(12, 8 - flick), Vector2(16, 20)]), [P.FIRE[3]], Vector3(0, 0, 1))
		c3.polygon(PackedVector2Array([Vector2(10, 20), Vector2(12, 13 - flick), Vector2(14, 20)]), [P.FIRE[5]], Vector3(0, 0, 1))
		c3.rect(Rect2i(9, 20, 7, 2), P.GOLD[2])
		ember.append(c3.finish())
	# "silenced": a cracked bronze bell over a tower the Tollkeeper's toll silenced.
	var silenced: Array[Image] = []
	for frame: int in 4:
		var c4: Canvas = Canvas.new(STATUS_SIZE.x, STATUS_SIZE.y)
		var swing: float = [0.0, 1.0, 0.0, -1.0][frame]
		c4.part()
		c4.polygon(PackedVector2Array([Vector2(9 + swing, 8), Vector2(15 + swing, 8), Vector2(18 + swing, 18), Vector2(6 + swing, 18)]),
			P.BRONZE, Vector3(-0.4, -0.3, 1))
		c4.ellipse(Vector2(12 + swing, 8), Vector2(3.0, 1.8), P.BRONZE, 0.0, 0.1)
		c4.line(Vector2(13 + swing, 10), Vector2(11 + swing, 16), P.OUTLINE)
		c4.part()
		c4.ellipse(Vector2(12 + swing, 19.5), Vector2(1.4, 1.4), P.IRON, 0.0, 0.1)
		silenced.append(c4.finish())
	return [frozen, shattered, ember, silenced]
