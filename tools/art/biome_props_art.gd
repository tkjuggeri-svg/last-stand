extends RefCounted
## The props and the spawn gate of the new biomes (dev-time art generator, M10), drawn in code at the
## double resolution: 32x48 art frames (64x96), base on art row 44 like every prop, the gate 48x48 art
## (96x96) with its base on row 45. One method per prop; each biome lists the eight it uses.
##   godot --headless --path . --script res://tools/art/generate_art.gd -- --only=<biome>_props,<biome>_gate

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")

const PROP_SIZE: Vector2i = Vector2i(32, 48)
const GATE_SIZE: Vector2i = Vector2i(48, 48)
const BASE: float = 44.0
const PROPS: Dictionary = {
	"ashen_keep": ["broken_wall", "charred_tree", "rubble", "torn_banner", "pillar_stump", "cold_brazier", "stuck_shield", "ash_mound"],
	"ember_orchard": ["apple_tree_burnt", "apple_cart", "scarecrow_post", "hay_bale", "broken_fence", "cider_barrel", "tree_stump", "ember_pile"],
	"frostbound_pass": ["snow_pine", "snow_drift", "ice_boulder", "frozen_banner", "icicle_rocks", "snowy_stump", "cairn", "frozen_bones"],
	"sunless_mines": ["timber_support", "ore_cart", "stalagmites", "glow_crystals", "pickaxe_rack", "mine_lamp", "rock_pile", "ore_barrels"],
	"bone_quarry": ["stone_slab", "quarry_crane", "bone_heap", "cut_blocks", "cracked_pillar", "ore_cart", "rock_pile", "pickaxe_rack"],
	"gloam_wood": ["twisted_tree", "glow_mushrooms", "fallen_log", "fern_bush", "root_knot", "hollow_stump", "bone_moss", "wisp_stone"],
	"pale_cathedral": ["broken_pew", "saint_statue", "candle_stand", "nave_pillar", "broken_arch", "altar_slab", "white_banner", "pilgrim_bones"],
}

var detail: int = 1


func _init(resolution: int = 1) -> void:
	detail = resolution


func prop_frames(biome: String) -> Array[Image]:
	var frames: Array[Image] = []
	for prop: String in PROPS[biome]:
		var c: Canvas = Canvas.new(PROP_SIZE.x, PROP_SIZE.y, detail)
		call("_" + prop, c)
		c.finish()
		c.ground_shadow(Vector2(17, BASE - 0.5), Vector2(9, 2.4))
		frames.append(c.image)
	return frames


func gate(biome: String) -> Image:
	var c: Canvas = Canvas.new(GATE_SIZE.x, GATE_SIZE.y, detail)
	call("_gate_" + biome, c)
	c.finish()
	c.ground_shadow(Vector2(24, 45.5), Vector2(18, 3.0))
	return c.image


# ---------------------------------------------------------------- Ashen Keep

func _broken_wall(c: Canvas) -> void:
	c.part()
	c.block(Rect2(5, 36, 22, 5), 5.0, P.STONE_WARM.slice(1, 6), P.STONE_WARM.slice(0, 5))
	var tops: Array[int] = [28, 24, 30, 22, 27, 31, 26]
	for i: int in tops.size():
		c.part()
		c.block(Rect2(5 + i * 3, tops[i], 3, 8), float(36 - tops[i] - 8), P.STONE_WARM.slice(1, 6), P.STONE_WARM.slice(0, 5))
	c.line(Vector2(8, 30), Vector2(12, 36), P.STONE_WARM[0])
	c.part(true)
	c.px(10, 25, P.FIRE[2])
	c.px(21, 29, P.FIRE[1])


func _charred_tree(c: Canvas) -> void:
	var base: Vector2 = Vector2(16, BASE - 1)
	c.part()
	c.capsule(base, base + Vector2(0, -18), 2.4, P.DEAD_WOOD.slice(0, 3))
	for b: Array in [[Vector2(0, -10), Vector2(-8, -18), 1.0], [Vector2(0, -14), Vector2(7, -23), 0.9], [Vector2(0, -18), Vector2(-3, -28), 0.8], [Vector2(-8, -18), Vector2(-11, -24), 0.6]]:
		c.capsule(base + (b[0] as Vector2), base + (b[1] as Vector2), float(b[2]), P.DEAD_WOOD.slice(0, 3))
	c.part(true)
	c.px(int(base.x) + 1, int(base.y) - 9, P.FIRE[2])
	c.px(int(base.x) - 1, int(base.y) - 5, P.FIRE[1])


func _rubble(c: Canvas) -> void:
	for r: Vector3 in [Vector3(11, 39, 4.2), Vector3(19, 40, 3.6), Vector3(15, 36, 3.0), Vector3(23, 42, 2.2), Vector3(9, 42, 2.0)]:
		c.part()
		c.ellipse(Vector2(r.x, r.y), Vector2(r.z, r.z * 0.8), P.STONE_WARM.slice(1, 6), 0.0, 0.0)
	c.part()
	c.line(Vector2(13, 41), Vector2(24, 38), P.WOOD[2])  # a splintered beam


func _torn_banner(c: Canvas) -> void:
	c.part()
	c.rect(Rect2i(15, 12, 2, 32), P.WOOD[2])
	c.rect(Rect2i(16, 12, 1, 32), P.WOOD[1])
	c.part()
	c.polygon(PackedVector2Array([Vector2(17, 13), Vector2(27, 15), Vector2(25, 21), Vector2(27, 27), Vector2(22, 25), Vector2(19, 30), Vector2(17, 26)]), P.BANNER, Vector3(-0.2, -0.3, 1))
	c.px(21, 18, P.GOLD[2])
	c.px(22, 18, P.GOLD[1])


func _pillar_stump(c: Canvas) -> void:
	c.part()
	c.block(Rect2(9, 37, 14, 4), 3.0, P.STONE_WARM.slice(1, 6), P.STONE_WARM.slice(0, 5))
	c.part()
	c.cylinder(16, 28, 38, 4.5, 2.0, P.STONE_WARM, P.STONE_WARM.slice(2, 6))
	c.line(Vector2(12, 30), Vector2(20, 33), P.STONE_WARM[0])
	c.part()
	c.ellipse(Vector2(25, 41.5), Vector2(3.0, 2.0), P.STONE_WARM.slice(1, 6))


func _cold_brazier(c: Canvas) -> void:
	c.part()
	c.cylinder(16, 33, 41, 1.6, 0.8, P.IRON.slice(0, 4), [], false)
	c.part()
	c.polygon(PackedVector2Array([Vector2(9, 27), Vector2(23, 27), Vector2(20, 34), Vector2(12, 34)]), P.IRON, Vector3(-0.3, -0.4, 1))
	c.part()
	c.ellipse(Vector2(16, 27), Vector2(7, 1.8), P.STONE_WARM.slice(0, 4), 0.0, 0.0)  # ash
	c.part(true)
	c.px(15, 27, P.FIRE[1])


func _stuck_shield(c: Canvas) -> void:
	c.part()
	c.line(Vector2(16, 28), Vector2(17, 42), P.STEEL[3])  # a planted sword
	c.line(Vector2(13, 31), Vector2(21, 31), P.STEEL[4])
	c.part()
	c.polygon(PackedVector2Array([Vector2(8, 36), Vector2(15, 34), Vector2(15, 41), Vector2(11, 43)]), P.IRON_WORN, Vector3(-0.3, -0.3, 1))
	c.px(12, 38, P.TABARD[2])


func _ash_mound(c: Canvas) -> void:
	c.part()
	c.ellipse(Vector2(16, 40), Vector2(9, 3.6), P.STONE_WARM.slice(0, 4), 0.0, -0.1)
	c.part(true)
	for p: Vector2i in [Vector2i(12, 38), Vector2i(17, 37), Vector2i(20, 39), Vector2i(14, 40)]:
		c.px(p.x, p.y, P.FIRE[(p.x + p.y) % 3 + 1])


## A burned gatehouse arch the dead come through, a red glow in the opening.
func _gate_ashen_keep(c: Canvas) -> void:
	c.part()
	c.block(Rect2(8, 38, 32, 6), 3.0, P.STONE_WARM.slice(1, 6), P.STONE_WARM.slice(0, 5))
	for x: float in [11.0, 37.0]:
		c.part()
		c.cylinder(x, 16, 40, 3.8, 1.6, P.STONE_WARM, P.STONE_WARM.slice(2, 6))
	c.part()
	c.polygon(PackedVector2Array([Vector2(8, 18), Vector2(11, 10), Vector2(18, 13), Vector2(24, 6), Vector2(31, 12), Vector2(37, 9), Vector2(40, 18)]), P.STONE_WARM, Vector3(-0.2, -0.6, 1))
	c.part()
	c.rect(Rect2i(16, 20, 16, 20), P.OUTLINE)
	c.part(true)
	for y: int in range(21, 40):
		for x: int in range(17, 31):
			var glow: float = 1.0 - Vector2(x - 24.0, (y - 38.0) * 1.2).length() / 11.0
			if glow > 0.0:
				c.px(x, y, Canvas.shade(P.FIRE.slice(0, 5), glow * 0.8, x, y, true))
	c.part()
	c.line(Vector2(14, 20), Vector2(34, 20), P.IRON[3])
	for x: int in range(18, 31, 3):
		c.rect(Rect2i(x, 20, 1, 7), P.IRON[3])


# ---------------------------------------------------------------- Ember Orchard

func _apple_tree_burnt(c: Canvas) -> void:
	var base: Vector2 = Vector2(16, BASE - 1)
	c.part()
	c.capsule(base, base + Vector2(-1, -14), 2.6, P.DEAD_WOOD.slice(0, 3))
	for b: Array in [[Vector2(-1, -8), Vector2(-9, -16), 1.3], [Vector2(-1, -11), Vector2(8, -19), 1.2], [Vector2(-1, -14), Vector2(-2, -24), 1.0]]:
		c.capsule(base + (b[0] as Vector2), base + (b[1] as Vector2), float(b[2]), P.DEAD_WOOD.slice(0, 3))
	for blob: Vector3 in [Vector3(-9, -17, 3.4), Vector3(8, -20, 3.2), Vector3(-2, -25, 3.0)]:
		c.part()
		c.ellipse(base + Vector2(blob.x, blob.y), Vector2(blob.z, blob.z * 0.8), P.STONE_WARM.slice(0, 4), 0.0, -0.1)  # scorched leaves
	c.part(true)
	c.px(int(base.x) - 8, int(base.y) - 15, P.FIRE[3])
	c.px(int(base.x) + 9, int(base.y) - 18, P.FIRE[2])


func _apple_cart(c: Canvas) -> void:
	c.part()
	c.block(Rect2(7, 32, 18, 5), 5.0, P.WOOD.slice(1, 5), P.WOOD.slice(0, 4), false)
	c.part()
	c.ellipse(Vector2(10, 40), Vector2(3.4, 3.4), P.WOOD.slice(0, 4), 0.0, 0.0)  # a wheel
	c.part()
	c.line(Vector2(25, 34), Vector2(30, 38), P.WOOD[2])
	c.part(true)
	c.px(12, 31, P.FIRE[1])
	c.px(20, 30, P.FIRE[2])


func _scarecrow_post(c: Canvas) -> void:
	c.part()
	c.rect(Rect2i(15, 16, 2, 28), P.WOOD[2])
	c.line(Vector2(8, 22), Vector2(24, 22), P.WOOD[3])
	c.part()
	c.polygon(PackedVector2Array([Vector2(11, 22), Vector2(21, 22), Vector2(22, 32), Vector2(10, 32)]), P.PRIEST_ROBE, Vector3(-0.2, -0.3, 1))
	c.ellipse(Vector2(16, 17), Vector2(3, 3), [Color("a88c3e"), Color("d4b65a"), Color("f0dc94")], 0.0, 0.1)
	c.px(15, 17, P.OUTLINE)
	c.px(17, 17, P.OUTLINE)


func _hay_bale(c: Canvas) -> void:
	c.part()
	c.block(Rect2(7, 34, 18, 6), 4.0, [Color("a88c3e"), Color("c2a44c"), Color("dcc468")], [Color("6e5a28"), Color("8a7434"), Color("a88c3e")], false)
	c.line(Vector2(11, 34), Vector2(11, 44), Color("6e5a28"))
	c.line(Vector2(21, 34), Vector2(21, 44), Color("6e5a28"))


func _broken_fence(c: Canvas) -> void:
	for x: int in [7, 13, 19, 25]:
		c.part()
		c.rect(Rect2i(x, 32 - (x % 3) * 2, 2, 12 + (x % 3) * 2), P.WOOD[2])
	c.part()
	c.line(Vector2(7, 36), Vector2(19, 38), P.WOOD[3])
	c.line(Vector2(19, 34), Vector2(26, 36), P.WOOD[3])


func _cider_barrel(c: Canvas) -> void:
	c.part()
	c.cylinder(16, 30, 41, 5.5, 2.2, P.WOOD.slice(1, 5), P.WOOD.slice(2, 5), false)
	c.line(Vector2(11, 33), Vector2(21, 33), P.IRON[3])
	c.line(Vector2(11, 38), Vector2(21, 38), P.IRON[3])


func _tree_stump(c: Canvas) -> void:
	c.part()
	c.cylinder(16, 34, 42, 5.0, 2.0, P.DEAD_WOOD.slice(0, 4), [P.WOOD[2], P.WOOD[3], P.WOOD[4]], false)
	c.ellipse(Vector2(25, 41), Vector2(2.6, 1.6), P.DEAD_WOOD.slice(0, 3), 0.0, 0.0)


func _ember_pile(c: Canvas) -> void:
	c.part()
	c.ellipse(Vector2(16, 40), Vector2(9, 3.6), P.STONE_WARM.slice(0, 4), 0.0, -0.1)
	c.part(true)
	for p: Vector2i in [Vector2i(12, 38), Vector2i(16, 37), Vector2i(20, 39), Vector2i(15, 40), Vector2i(18, 41)]:
		c.px(p.x, p.y, P.FIRE[(p.x + p.y) % 3 + 2])


func _gate_ember_orchard(c: Canvas) -> void:
	c.part()
	for x: float in [10.0, 38.0]:
		c.cylinder(x, 14, 42, 2.8, 1.2, P.WOOD.slice(0, 4), [], false)
	c.part()
	c.block(Rect2(8, 12, 32, 3), 2.0, P.WOOD.slice(1, 5), P.WOOD.slice(0, 4), false)
	c.part()
	c.polygon(PackedVector2Array([Vector2(12, 16), Vector2(36, 16), Vector2(34, 38), Vector2(14, 40)]), P.CULT_DARK, Vector3(0, 0, 1))
	c.part(true)
	for y: int in range(18, 40):
		for x: int in range(14, 35):
			var glow: float = 1.0 - Vector2(x - 24.0, (y - 38.0) * 1.1).length() / 12.0
			if glow > 0.0:
				c.px(x, y, Canvas.shade(P.FIRE.slice(0, 5), glow * 0.7, x, y, true))
	c.part()
	for x: int in range(16, 34, 4):
		c.rect(Rect2i(x, 16, 1, 20), P.WOOD[2])


# ---------------------------------------------------------------- Frostbound Pass

func _snow_pine(c: Canvas) -> void:
	c.part()
	c.rect(Rect2i(15, 36, 2, 8), P.WOOD[2])
	for tier: int in 4:
		var y: float = 36.0 - tier * 7.0
		var w: float = 9.0 - tier * 1.6
		c.part()
		c.polygon(PackedVector2Array([Vector2(16 - w, y), Vector2(16 + w, y), Vector2(16, y - 9)]), P.GRASS.slice(0, 4), Vector3(-0.3, -0.4, 1))
		c.polygon(PackedVector2Array([Vector2(16 - w * 0.8, y - 2), Vector2(16 + w * 0.8, y - 2), Vector2(16, y - 9)]), P.ICE.slice(3, 6), Vector3(-0.3, -0.5, 1))


func _snow_drift(c: Canvas) -> void:
	c.part()
	c.ellipse(Vector2(16, 40), Vector2(11, 4.4), P.ICE.slice(2, 6), 0.0, 0.2)
	c.ellipse(Vector2(12, 38), Vector2(6, 3.4), P.ICE.slice(3, 6), 0.0, 0.3)


func _ice_boulder(c: Canvas) -> void:
	c.part()
	c.polygon(PackedVector2Array([Vector2(8, 41), Vector2(10, 32), Vector2(16, 28), Vector2(23, 32), Vector2(25, 41)]), P.ICE, Vector3(-0.4, -0.5, 1))
	c.line(Vector2(13, 31), Vector2(18, 38), P.ICE[5])


func _frozen_banner(c: Canvas) -> void:
	c.part()
	c.rect(Rect2i(15, 14, 2, 30), P.WOOD[2])
	c.part()
	c.polygon(PackedVector2Array([Vector2(17, 15), Vector2(27, 17), Vector2(26, 25), Vector2(24, 28), Vector2(17, 27)]), P.ICE.slice(1, 5), Vector3(-0.2, -0.3, 1))
	c.line(Vector2(20, 28), Vector2(20, 33), P.ICE[5])
	c.line(Vector2(24, 28), Vector2(24, 31), P.ICE[5])


func _icicle_rocks(c: Canvas) -> void:
	for r: Vector3 in [Vector3(11, 39, 4.4), Vector3(20, 40, 3.8), Vector3(16, 36, 3.0)]:
		c.part()
		c.ellipse(Vector2(r.x, r.y), Vector2(r.z, r.z * 0.8), P.STONE.slice(1, 6), 0.0, 0.0)
	c.part()
	c.line(Vector2(14, 33), Vector2(14, 38), P.ICE[5])
	c.line(Vector2(18, 34), Vector2(18, 39), P.ICE[4])


func _snowy_stump(c: Canvas) -> void:
	c.part()
	c.cylinder(16, 35, 42, 4.6, 1.8, P.DEAD_WOOD.slice(0, 4), P.ICE.slice(3, 6), false)


func _cairn(c: Canvas) -> void:
	for r: Vector3 in [Vector3(16, 41, 6.0), Vector3(16, 36, 4.4), Vector3(16, 32, 3.0)]:
		c.part()
		c.ellipse(Vector2(r.x, r.y), Vector2(r.z, r.z * 0.7), P.STONE.slice(1, 7), 0.0, 0.0)
	c.px(16, 29, P.ICE[5])


func _frozen_bones(c: Canvas) -> void:
	c.part()
	c.ellipse(Vector2(14, 40), Vector2(2.6, 2.2), P.BONE, 0.0, 0.05)
	c.capsule(Vector2(18, 42), Vector2(25, 40), 0.7, P.BONE)
	c.part()
	c.ellipse(Vector2(16, 42), Vector2(9, 2.2), P.ICE.slice(3, 6), 0.0, 0.3)


func _gate_frostbound_pass(c: Canvas) -> void:
	c.part()
	c.polygon(PackedVector2Array([Vector2(6, 44), Vector2(10, 14), Vector2(18, 8), Vector2(24, 4), Vector2(30, 8), Vector2(38, 14), Vector2(42, 44)]), P.ICE.slice(1, 6), Vector3(-0.4, -0.6, 1))
	c.part()
	c.polygon(PackedVector2Array([Vector2(15, 44), Vector2(16, 24), Vector2(24, 18), Vector2(32, 24), Vector2(33, 44)]), P.CULT_DARK, Vector3(0, 0, 1))
	c.part(true)
	for y: int in range(24, 44):
		for x: int in range(17, 32):
			var glow: float = 1.0 - Vector2(x - 24.0, (y - 42.0) * 1.2).length() / 11.0
			if glow > 0.0:
				c.px(x, y, Canvas.shade(P.ICE.slice(0, 5), glow * 0.9, x, y, true))
	c.part()
	for x: int in [14, 19, 29, 34]:
		c.line(Vector2(x, 20), Vector2(x, 20 + 5 + x % 3), P.ICE[5])


# ---------------------------------------------------------------- Sunless Mines

func _timber_support(c: Canvas) -> void:
	c.part()
	c.rect(Rect2i(9, 20, 3, 24), P.WOOD[2])
	c.rect(Rect2i(21, 20, 3, 24), P.WOOD[2])
	c.part()
	c.block(Rect2(7, 17, 18, 3), 2.0, P.WOOD.slice(1, 5), P.WOOD.slice(0, 4), false)
	c.line(Vector2(9, 40), Vector2(14, 32), P.WOOD[3])


func _ore_cart(c: Canvas) -> void:
	c.part()
	c.block(Rect2(7, 33, 18, 5), 5.0, P.IRON.slice(1, 5), P.IRON.slice(0, 4), false)
	for x: float in [11.0, 22.0]:
		c.part()
		c.ellipse(Vector2(x, 42), Vector2(2.6, 2.6), P.IRON.slice(0, 4), 0.0, 0.0)
	c.part(true)
	for p: Vector2i in [Vector2i(10, 31), Vector2i(14, 30), Vector2i(19, 31), Vector2i(22, 30)]:
		c.px(p.x, p.y, P.SOUL[(p.x % 3) + 1] if p.x % 2 == 0 else P.GOLD[3])


func _stalagmites(c: Canvas) -> void:
	for x: float in [10.0, 16.0, 22.0]:
		c.part()
		c.polygon(PackedVector2Array([Vector2(x - 3.0, 42), Vector2(x, 42.0 - 8.0 - fmod(x, 7.0)), Vector2(x + 3.0, 42)]), P.STONE.slice(1, 6), Vector3(-0.3, -0.5, 1))


func _glow_crystals(c: Canvas) -> void:
	for p: Vector3 in [Vector3(12, 40, 7), Vector3(18, 41, 10), Vector3(23, 40, 6)]:
		c.part(true)
		c.polygon(PackedVector2Array([Vector2(p.x - 2.0, p.y), Vector2(p.x, p.y - p.z), Vector2(p.x + 2.0, p.y)]), P.SOUL, Vector3(-0.3, -0.5, 1))
	c.part()
	c.ellipse(Vector2(17, 42), Vector2(9, 2.4), P.STONE.slice(0, 4), 0.0, 0.0)


func _pickaxe_rack(c: Canvas) -> void:
	c.part()
	c.rect(Rect2i(8, 26, 2, 18), P.WOOD[2])
	c.rect(Rect2i(22, 26, 2, 18), P.WOOD[2])
	c.line(Vector2(8, 28), Vector2(24, 28), P.WOOD[3])
	for x: float in [12.0, 16.0, 20.0]:
		c.part()
		c.line(Vector2(x, 26), Vector2(x, 38), P.WOOD[3])
		c.line(Vector2(x - 3, 27), Vector2(x + 3, 27), P.STEEL[3])


func _mine_lamp(c: Canvas) -> void:
	c.part()
	c.rect(Rect2i(15, 20, 2, 24), P.IRON[2])
	c.part()
	c.block(Rect2(13, 16, 6, 1), 5.0, P.IRON.slice(1, 5), P.IRON.slice(0, 4), false)
	c.part(true)
	c.rect(Rect2i(14, 18, 4, 4), P.GOLD[3])
	c.px(15, 19, P.GOLD[4])


func _rock_pile(c: Canvas) -> void:
	for r: Vector3 in [Vector3(12, 39, 4.6), Vector3(20, 40, 3.8), Vector3(16, 36, 3.4), Vector3(23, 42, 2.0)]:
		c.part()
		c.ellipse(Vector2(r.x, r.y), Vector2(r.z, r.z * 0.8), P.STONE.slice(0, 5), 0.0, 0.0)


func _ore_barrels(c: Canvas) -> void:
	for x: float in [11.0, 21.0]:
		c.part()
		c.cylinder(x, 33, 42, 4.4, 1.8, P.WOOD.slice(1, 5), P.WOOD.slice(2, 5), false)
		c.line(Vector2(x - 4, 36), Vector2(x + 4, 36), P.IRON[3])
	c.part(true)
	c.px(11, 31, P.GOLD[3])
	c.px(21, 31, P.SOUL[3])


func _gate_sunless_mines(c: Canvas) -> void:
	c.part()
	c.block(Rect2(6, 40, 36, 5), 3.0, P.STONE.slice(1, 6), P.STONE.slice(0, 5))
	c.part()
	c.polygon(PackedVector2Array([Vector2(6, 42), Vector2(10, 14), Vector2(24, 6), Vector2(38, 14), Vector2(42, 42)]), P.STONE.slice(0, 5), Vector3(-0.3, -0.6, 1))
	c.part()
	c.rect(Rect2i(15, 18, 18, 24), P.OUTLINE)
	c.part()
	c.rect(Rect2i(13, 16, 3, 27), P.WOOD[2])
	c.rect(Rect2i(32, 16, 3, 27), P.WOOD[2])
	c.block(Rect2(12, 14, 24, 3), 2.0, P.WOOD.slice(1, 5), P.WOOD.slice(0, 4), false)
	c.part(true)
	c.px(24, 24, P.SOUL[3])
	c.px(20, 30, P.SOUL[2])


# ---------------------------------------------------------------- Bone Quarry

func _stone_slab(c: Canvas) -> void:
	c.part()
	c.block(Rect2(6, 33, 20, 6), 4.0, P.STONE_WARM.slice(1, 6), P.STONE_WARM.slice(0, 5))
	c.line(Vector2(10, 33), Vector2(14, 43), P.STONE_WARM[0])


func _quarry_crane(c: Canvas) -> void:
	c.part()
	c.rect(Rect2i(8, 16, 3, 28), P.WOOD[2])
	c.line(Vector2(9, 16), Vector2(26, 22), P.WOOD[3])
	c.line(Vector2(26, 22), Vector2(26, 33), P.IRON[3])
	c.part()
	c.block(Rect2(22, 33, 8, 4), 3.0, P.STONE_WARM.slice(1, 6), P.STONE_WARM.slice(0, 5))


func _bone_heap(c: Canvas) -> void:
	c.part()
	c.ellipse(Vector2(16, 40), Vector2(10, 4), P.BONE.slice(0, 4), 0.0, 0.0)
	for k: int in 5:
		c.line(Vector2(9 + k * 3, 40), Vector2(11 + k * 3, 33 - k % 2 * 2), P.BONE[3])
	c.part()
	c.ellipse(Vector2(17, 36), Vector2(2.6, 2.3), P.BONE, 0.0, 0.1)
	c.px(16, 36, P.OUTLINE)
	c.px(18, 36, P.OUTLINE)


func _cut_blocks(c: Canvas) -> void:
	for b: Rect2 in [Rect2(5, 36, 10, 5), Rect2(16, 37, 10, 5), Rect2(9, 31, 10, 5)]:
		c.part()
		c.block(b, 3.0, P.STONE_WARM.slice(2, 7), P.STONE_WARM.slice(0, 5))


func _cracked_pillar(c: Canvas) -> void:
	c.part()
	c.cylinder(16, 22, 40, 5.0, 2.0, P.STONE_WARM, P.STONE_WARM.slice(2, 6))
	c.line(Vector2(14, 24), Vector2(18, 34), P.STONE_WARM[0])
	c.line(Vector2(18, 34), Vector2(15, 40), P.STONE_WARM[0])


func _gate_bone_quarry(c: Canvas) -> void:
	c.part()
	c.polygon(PackedVector2Array([Vector2(4, 44), Vector2(8, 16), Vector2(24, 8), Vector2(40, 16), Vector2(44, 44)]), P.STONE_WARM.slice(0, 5), Vector3(-0.3, -0.6, 1))
	c.part()
	c.rect(Rect2i(15, 20, 18, 24), P.OUTLINE)
	c.part()
	c.rect(Rect2i(13, 18, 3, 26), P.WOOD[2])
	c.rect(Rect2i(32, 18, 3, 26), P.WOOD[2])
	c.part()
	c.ellipse(Vector2(24, 12), Vector2(3.0, 2.6), P.BONE, 0.0, 0.2)
	c.px(23, 12, P.OUTLINE)
	c.px(25, 12, P.OUTLINE)
	c.part(true)
	c.px(24, 30, P.GOLD[3])


# ---------------------------------------------------------------- Gloam Wood

func _twisted_tree(c: Canvas) -> void:
	var base: Vector2 = Vector2(16, BASE - 1)
	c.part()
	c.capsule(base, base + Vector2(-2, -12), 2.8, P.DEAD_WOOD.slice(0, 4))
	c.capsule(base + Vector2(-2, -12), base + Vector2(3, -22), 2.2, P.DEAD_WOOD.slice(0, 4))
	for b: Array in [[Vector2(3, -22), Vector2(-6, -30), 1.2], [Vector2(3, -22), Vector2(10, -30), 1.1], [Vector2(-2, -12), Vector2(-10, -18), 1.1]]:
		c.capsule(base + (b[0] as Vector2), base + (b[1] as Vector2), float(b[2]), P.DEAD_WOOD.slice(0, 4))
	c.part()
	for blob: Vector3 in [Vector3(-7, -31, 4.0), Vector3(10, -31, 3.6), Vector3(2, -27, 4.4)]:
		c.ellipse(base + Vector2(blob.x, blob.y), Vector2(blob.z, blob.z * 0.8), P.MOSS, 0.0, -0.1)
	c.part(true)
	c.px(int(base.x) - 1, int(base.y) - 8, P.SOUL[3])


func _glow_mushrooms(c: Canvas) -> void:
	for p: Vector3 in [Vector3(11, 40, 4), Vector3(17, 41, 6), Vector3(23, 40, 3)]:
		c.part()
		c.rect(Rect2i(int(p.x), int(p.y) - int(p.z), 1, int(p.z)), P.BONE[1])
		c.part(true)
		c.ellipse(Vector2(p.x + 0.5, p.y - p.z), Vector2(3.0, 1.8), P.SOUL, 0.0, 0.3)


func _fallen_log(c: Canvas) -> void:
	c.part()
	c.capsule(Vector2(7, 40), Vector2(25, 38), 3.2, P.DEAD_WOOD.slice(0, 4))
	c.part()
	c.ellipse(Vector2(25, 38), Vector2(2.2, 3.0), P.WOOD.slice(1, 5), 0.0, 0.1)
	c.part()
	c.ellipse(Vector2(13, 36), Vector2(3.0, 1.6), P.MOSS, 0.0, 0.0)


func _fern_bush(c: Canvas) -> void:
	for p: Vector3 in [Vector3(11, 40, 8), Vector3(17, 41, 11), Vector3(22, 40, 7)]:
		c.part()
		c.line(Vector2(p.x, p.y), Vector2(p.x - 4, p.y - p.z), P.MOSS[2])
		c.line(Vector2(p.x, p.y), Vector2(p.x + 4, p.y - p.z + 2), P.MOSS[1])
		c.line(Vector2(p.x, p.y), Vector2(p.x, p.y - p.z - 2), P.MOSS[2])


func _root_knot(c: Canvas) -> void:
	c.part()
	c.capsule(Vector2(6, 42), Vector2(16, 36), 1.8, P.DEAD_WOOD.slice(0, 4))
	c.capsule(Vector2(26, 42), Vector2(16, 36), 1.8, P.DEAD_WOOD.slice(0, 4))
	c.capsule(Vector2(16, 36), Vector2(15, 30), 2.4, P.DEAD_WOOD.slice(0, 4))


func _hollow_stump(c: Canvas) -> void:
	c.part()
	c.cylinder(16, 33, 42, 5.4, 2.2, P.DEAD_WOOD.slice(0, 4), P.CULT_DARK, false)
	c.part(true)
	c.px(15, 33, P.SOUL[2])


func _bone_moss(c: Canvas) -> void:
	c.part()
	c.ellipse(Vector2(16, 41), Vector2(9, 3), P.MOSS, 0.0, 0.0)
	c.part()
	c.capsule(Vector2(12, 40), Vector2(20, 38), 0.8, P.BONE)
	c.ellipse(Vector2(22, 40), Vector2(2.2, 1.9), P.BONE, 0.0, 0.1)


func _wisp_stone(c: Canvas) -> void:
	c.part()
	c.polygon(PackedVector2Array([Vector2(10, 42), Vector2(12, 28), Vector2(20, 28), Vector2(22, 42)]), P.STONE.slice(0, 5), Vector3(-0.3, -0.3, 1))
	c.part(true)
	c.ellipse(Vector2(16, 24), Vector2(2.2, 3.0), P.SOUL, 0.0, 0.4)


func _gate_gloam_wood(c: Canvas) -> void:
	c.part()
	for x: float in [10.0, 38.0]:
		c.capsule(Vector2(x, 44), Vector2(x - 2.0, 10), 3.4, P.DEAD_WOOD.slice(0, 4))
	c.part()
	c.capsule(Vector2(8, 14), Vector2(40, 14), 2.6, P.DEAD_WOOD.slice(0, 4))
	c.part()
	c.rect(Rect2i(14, 16, 20, 28), P.OUTLINE)
	c.part(true)
	for y: int in range(18, 44):
		for x: int in range(15, 33):
			var glow: float = 1.0 - Vector2(x - 24.0, (y - 42.0) * 1.1).length() / 12.0
			if glow > 0.0:
				c.px(x, y, Canvas.shade(P.SOUL.slice(0, 4), glow * 0.8, x, y, true))
	c.part()
	c.polygon(PackedVector2Array([Vector2(8, 14), Vector2(24, 4), Vector2(40, 14)]), P.MOSS, Vector3(-0.2, -0.5, 1))


# ---------------------------------------------------------------- Pale Cathedral

func _broken_pew(c: Canvas) -> void:
	c.part()
	c.block(Rect2(6, 36, 20, 3), 4.0, P.WOOD.slice(1, 5), P.WOOD.slice(0, 4), false)
	c.rect(Rect2i(6, 28, 2, 10), P.WOOD[2])
	c.rect(Rect2i(24, 30, 2, 8), P.WOOD[2])
	c.line(Vector2(6, 28), Vector2(14, 31), P.WOOD[3])


func _saint_statue(c: Canvas) -> void:
	c.part()
	c.block(Rect2(10, 38, 12, 4), 3.0, P.STONE.slice(2, 7), P.STONE.slice(0, 5))
	c.part()
	c.polygon(PackedVector2Array([Vector2(12, 38), Vector2(12, 22), Vector2(16, 16), Vector2(20, 22), Vector2(20, 38)]), P.STONE.slice(2, 7), Vector3(-0.3, -0.3, 1))
	c.ellipse(Vector2(16, 14), Vector2(3.0, 3.2), P.STONE.slice(2, 7), 0.0, 0.1)
	c.line(Vector2(12, 24), Vector2(8, 31), P.STONE[4])


func _candle_stand(c: Canvas) -> void:
	c.part()
	c.rect(Rect2i(15, 26, 2, 18), P.IRON[2])
	c.part()
	c.block(Rect2(10, 24, 12, 2), 2.0, P.IRON.slice(1, 5), P.IRON.slice(0, 4), false)
	c.part(true)
	for x: int in [11, 15, 20]:
		c.rect(Rect2i(x, 19, 1, 4), P.BONE[3])
		c.px(x, 18, P.FIRE[4])


func _nave_pillar(c: Canvas) -> void:
	c.part()
	c.block(Rect2(9, 38, 14, 4), 3.0, P.STONE.slice(2, 7), P.STONE.slice(0, 5))
	c.part()
	c.cylinder(16, 8, 39, 4.6, 2.0, P.STONE, P.STONE.slice(2, 7))
	for y: int in range(12, 38, 5):
		c.line(Vector2(12, y), Vector2(20, y), P.STONE[1])


func _broken_arch(c: Canvas) -> void:
	c.part()
	c.cylinder(8, 18, 42, 3.0, 1.4, P.STONE, P.STONE.slice(2, 7))
	c.part()
	c.cylinder(24, 26, 42, 3.0, 1.4, P.STONE, P.STONE.slice(2, 7))
	c.part()
	c.polygon(PackedVector2Array([Vector2(5, 18), Vector2(12, 11), Vector2(17, 13), Vector2(11, 20)]), P.STONE.slice(1, 6), Vector3(-0.3, -0.5, 1))


func _altar_slab(c: Canvas) -> void:
	c.part()
	c.block(Rect2(6, 34, 20, 5), 5.0, P.STONE.slice(2, 7), P.STONE.slice(0, 5))
	c.part(true)
	c.ellipse(Vector2(16, 33), Vector2(4.0, 1.4), P.SOUL, 0.0, 0.3)


func _white_banner(c: Canvas) -> void:
	c.part()
	c.rect(Rect2i(15, 12, 2, 32), P.WOOD[2])
	c.part()
	c.polygon(PackedVector2Array([Vector2(17, 13), Vector2(27, 15), Vector2(26, 26), Vector2(22, 29), Vector2(17, 27)]), P.CULT_ROBE, Vector3(-0.2, -0.3, 1))
	c.px(21, 20, P.GOLD[3])


func _pilgrim_bones(c: Canvas) -> void:
	c.part()
	c.ellipse(Vector2(14, 40), Vector2(2.6, 2.2), P.BONE, 0.0, 0.05)
	c.capsule(Vector2(17, 42), Vector2(25, 40), 0.7, P.BONE)
	c.part()
	c.polygon(PackedVector2Array([Vector2(8, 43), Vector2(20, 42), Vector2(18, 44)]), P.CULT_ROBE, Vector3(0, 0, 1))


func _gate_pale_cathedral(c: Canvas) -> void:
	c.part()
	c.block(Rect2(6, 40, 36, 5), 3.0, P.STONE.slice(2, 7), P.STONE.slice(0, 5))
	for x: float in [10.0, 38.0]:
		c.part()
		c.cylinder(x, 14, 41, 3.4, 1.4, P.STONE, P.STONE.slice(2, 7))
	c.part()
	c.polygon(PackedVector2Array([Vector2(7, 16), Vector2(24, 2), Vector2(41, 16), Vector2(36, 18), Vector2(24, 9), Vector2(12, 18)]), P.STONE.slice(1, 6), Vector3(-0.3, -0.6, 1))
	c.part()
	c.rect(Rect2i(15, 20, 18, 21), P.OUTLINE)
	c.part(true)
	for y: int in range(21, 41):
		for x: int in range(16, 33):
			var glow: float = 1.0 - Vector2(x - 24.0, (y - 40.0) * 1.1).length() / 12.0
			if glow > 0.0:
				c.px(x, y, Canvas.shade(P.LICH_ROBE.slice(0, 5), glow * 0.8 + 0.1, x, y, true))
	c.part()
	c.line(Vector2(24, 9), Vector2(24, 4), P.GOLD[3])
	c.line(Vector2(22, 6), Vector2(26, 6), P.GOLD[3])
