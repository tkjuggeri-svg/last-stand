extends "res://tools/art/huntress_towers_art.gd"
## The Necromancer's towers (dev-time art generator) on the same sheet layout as the Huntress's
## (levels, evolutions, build and sell rows): Bone Pit, Soul Siphon and Ossuary, each in three levels
## with two evolutions. 32x48 art frames at the double resolution, base on art row 45.
##   Bone Pit: a ring of stone round a dark pit, bones heaped about it, a skeletal hand clawing out.
##   Soul Siphon: a slim obelisk carrying a floating green soul crystal in a cage of ribs.
##   Ossuary: a drum of stacked skulls and bones with a glowing core under a ribbed dome.

const KINDS: Array[String] = ["bone_pit", "soul_siphon", "ossuary"]
const EVOS: Dictionary = {
	"bone_pit": ["charnel_gate", "plague_pit"],
	"soul_siphon": ["soul_harvester", "wither_beam"],
	"ossuary": ["bone_storm", "death_knell"],
}


func kinds() -> Array[String]:
	return KINDS


func evolutions_of(kind: String) -> Array:
	return EVOS[kind]


func _bones(c: Canvas, at: Vector2, count: int) -> void:
	for k: int in count:
		var x: float = at.x + k * 2.6 - count
		c.part()
		c.line(Vector2(x, at.y), Vector2(x + 1.6, at.y - 1.2 - (k % 2)), P.BONE[2])
		c.px(roundi(x), roundi(at.y), P.BONE[3])


func _skull(c: Canvas, at: Vector2, glow: bool = true) -> void:
	c.part()
	c.ellipse(at, Vector2(2.4, 2.2), P.BONE, 0.0, 0.15)
	c.px(roundi(at.x) - 1, roundi(at.y), P.OUTLINE)
	c.px(roundi(at.x) + 1, roundi(at.y), P.SOUL[3] if glow else P.OUTLINE)


# ---------------------------------------------------------------- Bone Pit

func _bone_pit(c: Canvas, level: int, firing: bool, frame: int, evolution: String) -> void:
	c.part()
	c.ellipse(Vector2(16, 38), Vector2(12.5, 5.5), P.STONE, 0.0, 0.1)
	c.part()
	c.ellipse(Vector2(16, 38.5), Vector2(9.0, 3.6), P.ICHOR if evolution == "plague_pit" else P.CULT_DARK, 0.0, -0.4)
	c.part(true)
	c.ellipse(Vector2(16, 39.0), Vector2(6.0, 2.0), [Color(0.35, 0.95, 0.65, 0.22 + 0.06 * [0.0, 1.0, 2.0, 1.0][frame])], 0.0, 0.0)  # a faint green glow in the pit
	for k: int in 9:  # the rim: stones round the pit's front, a skull on every third
		var angle: float = PI * 0.05 + PI * 0.9 * k / 8.0
		var at: Vector2 = Vector2(16.0 + cos(angle) * 11.6, 38.0 + sin(angle) * 5.0)
		c.part()
		c.ellipse(at, Vector2(1.9, 1.3), P.STONE_WARM, 0.0, 0.05 + 0.04 * (k % 2))
		if k % 3 == 1:
			c.part()
			c.ellipse(at + Vector2(0, -0.8), Vector2(1.2, 1.0), P.BONE, 0.0, 0.2)
			c.px(roundi(at.x), roundi(at.y) - 1, P.OUTLINE)
	_bones(c, Vector2(5, 41), 4 + level)
	_bones(c, Vector2(20, 42), 3 + level)
	# A skull on a stake at the back.
	c.part()
	c.line(Vector2(24, 36), Vector2(24, 24), P.WOOD[3])
	_skull(c, Vector2(24, 22))
	if level >= 2:
		c.part()
		c.polygon(PackedVector2Array([Vector2(24, 17), Vector2(29, 18.5), Vector2(24, 20)]), P.LICH_ROBE, Vector3(-0.2, -0.3, 1))
	if level >= 3:
		c.px(24, 19, P.GOLD[3])
	# The hand clawing out of the pit: reaches up on the fire frames.
	var reach: float = [1.0, 6.0, 9.0, 4.0][frame] if firing else [0.0, 1.0, 1.5, 1.0][frame]
	c.part()
	c.capsule(Vector2(14, 38), Vector2(14, 37.5 - reach), 1.1, P.BONE, 0.1)
	for k: int in 3:
		c.line(Vector2(13 + k, 37.5 - reach), Vector2(12.5 + k * 1.3, 35.5 - reach), P.BONE[3])
	match evolution:
		"charnel_gate":
			c.part()
			c.rect(Rect2i(4, 24, 2, 15), P.STONE[3])
			c.rect(Rect2i(26, 24, 2, 15), P.STONE[3])
			c.polygon(PackedVector2Array([Vector2(3, 24), Vector2(16, 14), Vector2(29, 24)]), P.STONE, Vector3(-0.3, -0.5, 1))
			for x: int in range(8, 25, 4):
				c.line(Vector2(x, 24), Vector2(x, 36), P.IRON[3])
			_skull(c, Vector2(16, 17))
		"plague_pit":
			c.part(true)
			var bubble: float = [0.0, 1.0, 2.0, 1.0][frame]
			c.ellipse(Vector2(12, 36 - bubble), Vector2(1.4, 1.4), P.ICHOR, 0.0, 0.4)
			c.ellipse(Vector2(20, 37 - fposmod(bubble + 1.0, 3.0)), Vector2(1.2, 1.2), P.ICHOR, 0.0, 0.4)


# ---------------------------------------------------------------- Soul Siphon

func _soul_siphon(c: Canvas, level: int, firing: bool, frame: int, evolution: String) -> void:
	_footing(c, level)
	# A tapered obelisk with a capital, carved with runes that glow in step with the crystal.
	c.part()
	c.block(Rect2(12, 16, 8, 3), 20.0, P.STONE.slice(2, 7), P.STONE.slice(1, 6))
	c.part()
	c.block(Rect2(11, 14, 10, 2), 2.5, P.STONE.slice(2, 7), P.STONE.slice(1, 6))
	c.line(Vector2(12, 28), Vector2(19, 28), P.STONE[1])
	c.line(Vector2(12, 33), Vector2(19, 33), P.STONE[1])
	var pulse: float = [0.0, 0.5, 1.0, 0.5][frame]
	c.part(true)
	for k: int in 3:
		var y: float = 21.0 + k * 5.0
		var rune: Color = P.SOUL[2 + (1 if (k + frame) % 3 == 0 else 0)]
		c.line(Vector2(15, y), Vector2(17, y), rune)
		c.px(15 + (k % 2), roundi(y) + 1, rune)
		c.px(16, roundi(y) - 1, P.SOUL[1])
	# Ribs curving up round the crystal, four of them meeting at the apex.
	var lift: float = pulse
	c.part()
	c.line(Vector2(11, 14), Vector2(10, 8), P.BONE[2])
	c.line(Vector2(21, 14), Vector2(22, 8), P.BONE[2])
	c.line(Vector2(10, 8), Vector2(16, 2), P.BONE[3])
	c.line(Vector2(22, 8), Vector2(16, 2), P.BONE[3])
	c.line(Vector2(13, 14), Vector2(13, 8), P.BONE[1])
	c.line(Vector2(19, 14), Vector2(19, 8), P.BONE[1])
	c.line(Vector2(13, 8), Vector2(16, 2), P.BONE[2])
	c.line(Vector2(19, 8), Vector2(16, 2), P.BONE[2])
	# The soul crystal floats and brightens when it fires; two lesser souls circle it.
	c.part(true)
	var bright: float = 0.5 if firing and frame in [1, 2] else 0.0
	c.ellipse(Vector2(16, 8.5 - lift), Vector2(3.0, 3.8), P.SOUL, 0.0, 0.1 + bright)
	c.px(15, 7, P.SOUL[4])
	for k: int in 2:
		var angle: float = frame * PI * 0.5 + k * PI
		c.ellipse(Vector2(16 + cos(angle) * 6.0, 8.5 - lift + sin(angle) * 1.8), Vector2(0.9, 0.9), P.SOUL.slice(2, 5), 0.0, 0.3)
	if level >= 2:
		c.part()
		c.ellipse(Vector2(16, 15), Vector2(6.5, 1.4), P.IRON, 0.0, 0.1)
	if level >= 3:
		c.px(10, 14, P.GOLD[3])
		c.px(22, 14, P.GOLD[3])
	match evolution:
		"soul_harvester":
			c.part()
			c.line(Vector2(22, 22), Vector2(27, 12), P.WOOD[3])
			c.line(Vector2(27, 12), Vector2(30, 14), P.STEEL[4])  # a scythe's blade
			c.part()
			c.ellipse(Vector2(8, 24), Vector2(2.0, 2.6), P.SOUL, 0.0, 0.0)  # a jar of souls
		"wither_beam":
			c.part(true)
			c.ellipse(Vector2(9, 12 - lift), Vector2(2.0, 2.6), P.SOUL, 0.0, 0.1)
			c.ellipse(Vector2(23, 12 - lift), Vector2(2.0, 2.6), P.SOUL, 0.0, 0.1)


# ---------------------------------------------------------------- Ossuary

func _ossuary(c: Canvas, level: int, firing: bool, frame: int, evolution: String) -> void:
	_footing(c, level)
	# A drum of stacked bone.
	c.part()
	c.cylinder(16, 22, 36, 8.5, 3.0, P.BONE.slice(0, 4), P.BONE.slice(1, 4), false)
	for y: int in [26, 30, 34]:
		_skull(c, Vector2(11, y), false)
		_skull(c, Vector2(21, y), false)
	for y: int in [24, 32]:  # iron bands with rivets
		c.part()
		c.line(Vector2(8, y), Vector2(24, y), P.IRON_WORN[2])
		c.px(9, y, P.STEEL[5])
		c.px(15, y, P.STEEL[5])
		c.px(23, y, P.STEEL[5])
	for x: int in [7, 25]:  # candles on the footing
		c.part()
		c.rect(Rect2i(x, 35, 1, 3), P.BONE[3])
		c.part(true)
		c.px(x, 34, P.FIRE[4])
	# A ribbed dome and the glowing core.
	c.part()
	c.polygon(PackedVector2Array([Vector2(8, 22), Vector2(16, 12), Vector2(24, 22)]), P.STONE, Vector3(-0.3, -0.5, 1))
	c.line(Vector2(16, 12), Vector2(12, 22), P.STONE[1])
	c.line(Vector2(16, 12), Vector2(20, 22), P.STONE[1])
	c.part(true)
	var flare: float = [0.0, 1.0, 2.0, 1.0][frame] if firing else [0.0, 0.3, 0.6, 0.3][frame]
	c.ellipse(Vector2(16, 17), Vector2(1.6 + flare * 0.5, 1.8 + flare * 0.5), P.SOUL, 0.0, 0.2 + flare * 0.1)
	if level >= 2:
		c.px(8, 21, P.GOLD[2])
		c.px(24, 21, P.GOLD[2])
	if level >= 3:
		c.part()
		c.line(Vector2(16, 12), Vector2(16, 7), P.WOOD[3])
		_skull(c, Vector2(16, 6))
	match evolution:
		"bone_storm":
			c.part()
			for k: int in 5:
				var x: float = 6.0 + k * 5.0
				c.line(Vector2(x, 24 + (k % 2) * 4), Vector2(x - 2 + (frame % 2), 18 + (k % 2) * 3), P.BONE[3])
		"death_knell":
			c.part()
			c.polygon(PackedVector2Array([Vector2(12, 5), Vector2(20, 5), Vector2(22, 12), Vector2(10, 12)]), P.IRON_WORN, Vector3(-0.3, -0.4, 1))
			c.px(16, 13, P.IRON_WORN[4])
