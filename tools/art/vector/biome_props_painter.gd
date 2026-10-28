class_name BiomePropsPainter
## The props of the seven other maps and the marsh (M15 P4): eight each, in the order of tools/art/biome_props_art.gd (the
## marsh: tools/art/marsh_art.gd PROPS). frame(ci, biome, index) paints one 64x96 cell, the feet at (0, 0). The shapes are
## built from PropKit; the colours come from each map's palette so a prop belongs to its map.

const LISTS: Dictionary = {
	"ember_orchard": ["apple_tree_burnt", "apple_cart", "scarecrow_post", "hay_bale", "broken_fence", "cider_barrel", "tree_stump", "ember_pile"],
	"bone_quarry": ["stone_slab", "quarry_crane", "bone_heap", "cut_blocks", "cracked_pillar", "ore_cart", "rock_pile", "pickaxe_rack"],
	"frostbound_pass": ["snow_pine", "snow_drift", "ice_boulder", "frozen_banner", "icicle_rocks", "snowy_stump", "cairn", "frozen_bones"],
	"gloam_wood": ["twisted_tree", "glow_mushrooms", "fallen_log", "fern_bush", "root_knot", "hollow_stump", "bone_moss", "wisp_stone"],
	"ashen_keep": ["broken_wall", "charred_tree", "rubble", "torn_banner", "pillar_stump", "cold_brazier", "stuck_shield", "ash_mound"],
	"sunless_mines": ["timber_support", "ore_cart", "stalagmites", "glow_crystals", "pickaxe_rack", "mine_lamp", "rock_pile", "ore_barrels"],
	"pale_cathedral": ["broken_pew", "saint_statue", "candle_stand", "nave_pillar", "broken_arch", "altar_slab", "white_banner", "pilgrim_bones"],
	"drowned_marsh": ["reeds", "cattails", "willow", "stump", "sunken_boat", "marsh_lantern", "drowned_tomb", "mushrooms"],
}
const CHAR: Color = Color("2b2420")
const ASH_STONE: Color = Color("5e5750")
const COLD_STONE: Color = Color("7d8794")
const ICE: Color = Color("8fd0f0")
const WARM_STONE: Color = Color("8b8170")


static func frame(ci: CanvasItem, biome: String, index: int) -> void:
	var name: String = LISTS[biome][index]
	var wide: bool = name in ["apple_cart", "broken_fence", "quarry_crane", "stone_slab", "sunken_boat", "broken_wall", "ore_cart", "broken_pew", "fallen_log", "altar_slab", "timber_support"]
	PropKit.shadow(ci, 24.0 if wide else 16.0, 6.5 if wide else 5.5)
	match name:
		# ---- Ember Orchard
		"apple_tree_burnt":
			PropKit.dead_tree(ci, 78.0, CHAR, Color("3a2418"))
			for p: Vector2 in [Vector2(-18, -52), Vector2(14, -60), Vector2(-4, -70), Vector2(22, -46)]:
				VectorStyle.draw_glow(ci, PropKit.EMBER, p, 5.0, 0.7)
				ci.draw_circle(p, 1.7, Color("ff5a20"), true, -1.0, true)
		"apple_cart":
			PropKit.shadow(ci, 26.0, 7.0)
			VectorPaint.painted(ci, PackedVector2Array([Vector2(-20, -8), Vector2(20, -8), Vector2(17, -22), Vector2(-17, -22)]), PropKit.WOOD_LIGHT, 3.0, 0.4, 1.4)
			for x: float in [-12.0, -4.0, 4.0, 12.0]:
				VectorPaint.line(ci, Vector2(x, -9), Vector2(x * 0.9, -21), Color(PropKit.INK, 0.4), 1.0)
			for w: float in [-14.0, 14.0]:
				VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(w, -6), 6.5, 6.5, 16), PropKit.WOOD, 1.6, 0.4, 1.3)
				ci.draw_circle(Vector2(w, -6), 1.6, PropKit.IRON, true, -1.0, true)
			for k: int in 6:
				ci.draw_circle(Vector2(-12 + k * 5.0, -23 - (k % 2) * 2.0), 3.0, Color("6b1d18") if k % 3 else Color("3a1a14"), true, -1.0, true)
			PropKit.beam(ci, Vector2(18, -10), Vector2(34, -16), 2.4)
		"scarecrow_post":
			PropKit.post(ci, 0.0, 52.0, 2.4)
			PropKit.beam(ci, Vector2(-17, -38), Vector2(17, -38), 2.6)
			VectorPaint.painted(ci, PackedVector2Array([Vector2(-7, -36), Vector2(7, -36), Vector2(9, -18), Vector2(-9, -18), Vector2(-11, -28)]), Color("6b4a2e"), 2.0, 0.4, 1.2)
			VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -50), 7.0, 7.5, 16), Color("c9a574"), 2.2, 0.5, 1.2)
			VectorPaint.painted(ci, PackedVector2Array([Vector2(-10, -54), Vector2(10, -54), Vector2(6, -66), Vector2(-6, -66)]), Color("3a2418"), 1.6, 0.4, 1.1)
			for x: float in [-3.0, 3.0]:
				ci.draw_circle(Vector2(x, -50), 1.4, Color("1a1015"), true, -1.0, true)
			for k: int in 3:
				VectorPaint.strand(ci, Vector2(-15 + k * 2.0, -38), Vector2(-17, -34), Vector2(-18 + k * 2.4, -28), 1.6, Color("d6b25a"))
				VectorPaint.strand(ci, Vector2(15 - k * 2.0, -38), Vector2(17, -34), Vector2(18 - k * 2.4, -28), 1.6, Color("d6b25a"))
		"hay_bale":
			for p: Vector2 in [Vector2(-9, 0), Vector2(9, 0), Vector2(0, -13)]:
				VectorPaint.painted(ci, PackedVector2Array([p + Vector2(-10, 0), p + Vector2(10, 0), p + Vector2(10, -13), p + Vector2(-10, -13)]), Color("c9a24a"), 3.0, 0.5, 1.3)
				for k: int in 6:
					VectorPaint.line(ci, p + Vector2(-9 + k * 3.4, -2), p + Vector2(-8 + k * 3.4, -11), Color("8a6a2a"), 0.8)
				VectorPaint.line(ci, p + Vector2(-10, -4), p + Vector2(10, -4), Color("6a4a20"), 1.0)
				VectorPaint.line(ci, p + Vector2(-10, -9), p + Vector2(10, -9), Color("6a4a20"), 1.0)
		"broken_fence":
			PropKit.fence(ci, -22.0, 22.0, 22.0, true, PropKit.WOOD)
			PropKit.moss_tuft(ci, Vector2(-20, 1), 1.0, Color("6a7a34"))
		"cider_barrel":
			PropKit.barrel(ci, Vector2(-6, 0), 10.0, 20.0)
			PropKit.barrel(ci, Vector2(11, 0), 8.0, 15.0)
			VectorPaint.fill(ci, PackedVector2Array([Vector2(-3, -9), Vector2(1, -9), Vector2(1, -5), Vector2(-3, -5)]), Color("c9a24a"))
		"tree_stump":
			PropKit.stump(ci, Vector2.ZERO, 12.0, 12.0, CHAR.lightened(0.25))
			VectorStyle.draw_glow(ci, PropKit.EMBER, Vector2(4, -12), 7.0, 0.55)
		"ember_pile":
			PropKit.fire_pit(ci, Vector2.ZERO, 0.8)
			for k: int in 5:
				VectorStyle.draw_glow(ci, PropKit.EMBER, Vector2(-12 + k * 6.0, -3 - (k % 2) * 2.0), 3.0, 0.8)
		# ---- Bone Quarry
		"stone_slab":
			PropKit.slab(ci, Vector2(0, 0), 24.0, 16.0, WARM_STONE)
			PropKit.slab(ci, Vector2(8, -16), 15.0, 10.0, WARM_STONE.darkened(0.12))
		"quarry_crane":
			PropKit.post(ci, -14.0, 66.0, 3.4)
			PropKit.beam(ci, Vector2(-14, -62), Vector2(20, -56), 3.4)
			PropKit.beam(ci, Vector2(-14, -40), Vector2(8, -58), 2.2)
			VectorPaint.line(ci, Vector2(18, -56), Vector2(18, -26), PropKit.IRON_LIGHT, 1.2)
			PropKit.slab(ci, Vector2(18, -14), 8.0, 11.0, WARM_STONE)
		"bone_heap":
			PropKit.bones(ci, Vector2(-6, 0), 1.4)
			PropKit.bones(ci, Vector2(8, -2), 1.1)
			PropKit.skull(ci, Vector2(0, -14), 6.0)
		"cut_blocks":
			PropKit.slab(ci, Vector2(-9, 0), 11.0, 12.0, WARM_STONE)
			PropKit.slab(ci, Vector2(10, 0), 10.0, 9.0, WARM_STONE.darkened(0.1))
			PropKit.slab(ci, Vector2(0, -12), 10.0, 10.0, WARM_STONE.lightened(0.05))
		"cracked_pillar":
			PropKit.pillar(ci, Vector2.ZERO, 9.0, 56.0, WARM_STONE, true)
			ci.draw_polyline(PackedVector2Array([Vector2(2, -52), Vector2(-1, -38), Vector2(3, -28), Vector2(-1, -14)]), Color(PropKit.INK, 0.9), 1.6, true)
		"ore_cart":
			_cart(ci, Color("5a4a3c"), Color("2f2a30"))
		"rock_pile":
			PropKit.pile(ci, Vector2(0, 0), 18.0, 18.0, WARM_STONE, 5)
		"pickaxe_rack":
			PropKit.post(ci, -16.0, 30.0)
			PropKit.post(ci, 16.0, 30.0)
			PropKit.beam(ci, Vector2(-16, -26), Vector2(16, -26), 2.6)
			for x: float in [-9.0, 0.0, 9.0]:
				PropKit.beam(ci, Vector2(x, -4), Vector2(x * 0.7, -24), 2.0, PropKit.WOOD_LIGHT)
				VectorPaint.fill(ci, PackedVector2Array([Vector2(x * 0.7 - 5, -26), Vector2(x * 0.7 + 5, -26), Vector2(x * 0.7 + 2, -22), Vector2(x * 0.7 - 2, -22)]), Color("c3c9d2"))
		# ---- Frostbound Pass
		"snow_pine":
			PropKit.pine(ci, 80.0, Color("28486a"), true)
		"snow_drift":
			for p: Vector2 in [Vector2(-12, 0), Vector2(10, 0), Vector2(0, -6)]:
				VectorPaint.painted(ci, VectorStyle.ellipse(p + Vector2(0, -5), 15.0, 8.0, 18), PropKit.SNOW, 4.0, 0.4, 1.0)
			VectorStyle.draw_glow(ci, ICE, Vector2(0, -8), 22.0, 0.14)
		"ice_boulder":
			PropKit.rock(ci, Vector2(-4, 0), 16.0, Color("9ec6e8"), 4, true)
			PropKit.rock(ci, Vector2(14, 0), 9.0, Color("86b4da"), 6, true)
			VectorStyle.draw_glow(ci, ICE, Vector2(0, -10), 24.0, 0.2)
		"frozen_banner":
			PropKit.banner_pole(ci, 58.0, Color("6a3a44"), true, true)
		"icicle_rocks":
			PropKit.pile(ci, Vector2(0, 0), 16.0, 12.0, COLD_STONE, 7)
			for k: int in 6:
				var x: float = -12.0 + k * 5.0
				PropKit.crystal(ci, Vector2(x, -10 - (k % 3) * 2.0), 11.0 + (k % 2) * 4.0, ICE, false)
		"snowy_stump":
			PropKit.stump(ci, Vector2.ZERO, 11.0, 11.0, Color("5a4a40"))
			VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -12), 12.0, 4.6, 16), PropKit.SNOW, 1.6, 0.3, 0.0)
		"cairn":
			for i: int in 5:
				PropKit.rock(ci, Vector2(sin(i * 2.0) * 1.5, -i * 7.0), 12.0 - i * 2.0, COLD_STONE.darkened(i * 0.04), i + 9, i == 4)
		"frozen_bones":
			PropKit.bones(ci, Vector2.ZERO, 1.3)
			VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -2), 18.0, 4.0, 16), Color(PropKit.SNOW, 0.7), 1.0, 0.3, 0.0)
		# ---- Gloam Wood
		"twisted_tree":
			PropKit.dead_tree(ci, 82.0, Color("3a2a20"), Color("1f3a2a"))
			VectorStyle.draw_glow(ci, Color("a8f0c8"), Vector2(0, -56), 28.0, 0.12)
		"glow_mushrooms":
			for k: int in 5:
				PropKit.glow_mushroom(ci, Vector2(-14 + k * 7.0, -(k % 2) * 3.0), 8.0 + (k % 3) * 3.0, Color("57e0b8") if k % 2 == 0 else Color("a8f0c8"))
		"fallen_log":
			VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -7), 25.0, 8.0, 24), Color("4a3426"), 3.0, 0.4, 1.4)
			VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(-23, -7), 3.5, 7.0, 12), Color("8a6a4a"), 1.2, 0.3, 1.0)
			PropKit.moss_tuft(ci, Vector2(-4, -13), 1.8, Color("4a8a58"))
			PropKit.moss_tuft(ci, Vector2(12, -13), 1.4, Color("4a8a58"))
		"fern_bush":
			for k: int in 8:
				var a: float = -PI * 0.5 + (k - 3.5) * 0.4
				var tip: Vector2 = Vector2.from_angle(a) * (16.0 + (k % 3) * 3.0)
				VectorPaint.strand(ci, Vector2(0, -2), Vector2.from_angle(a - 0.4) * 10.0, tip, 3.4, Color("2f5a3c").lightened(k * 0.03))
		"root_knot":
			for k: int in 6:
				var a: float = PI + k * PI / 5.0
				VectorPaint.strand(ci, Vector2(0, -8), Vector2(cos(a) * 10.0, -14.0 - sin(a) * 8.0), Vector2(cos(a) * 22.0, -4.0 + sin(a) * 2.0), 5.0, Color("3d2e22"))
		"hollow_stump":
			PropKit.stump(ci, Vector2.ZERO, 14.0, 22.0, Color("3d2e22"))
			ci.draw_colored_polygon(VectorStyle.ellipse(Vector2(0, -22), 9.0, 3.6, 14), Color(0.03, 0.04, 0.05, 0.95))
			VectorStyle.draw_glow(ci, Color("a8f0c8"), Vector2(0, -21), 12.0, 0.35)
		"bone_moss":
			PropKit.bones(ci, Vector2.ZERO, 1.2)
			for k: int in 5:
				PropKit.moss_tuft(ci, Vector2(-12 + k * 6.0, -1), 1.4, Color("4a8a58"))
		"wisp_stone":
			PropKit.pillar(ci, Vector2.ZERO, 8.0, 42.0, Color("4a5a58"))
			ci.draw_arc(Vector2(0, -26), 4.0, 0.0, TAU, 14, Color("a8f0c8"), 1.2, true)
			VectorStyle.draw_glow(ci, Color("a8f0c8"), Vector2(0, -26), 20.0, 0.5)
			VectorStyle.draw_glow(ci, Color("e8fff0"), Vector2(0, -48), 8.0, 0.8)
		# ---- Ashen Keep
		"broken_wall":
			_wall(ci, ASH_STONE)
		"charred_tree":
			PropKit.dead_tree(ci, 74.0, CHAR)
			VectorStyle.draw_glow(ci, PropKit.EMBER, Vector2(0, -22), 8.0, 0.4)
		"rubble":
			PropKit.pile(ci, Vector2(0, 0), 20.0, 12.0, ASH_STONE, 11)
		"torn_banner":
			PropKit.banner_pole(ci, 56.0, Color("7a2a28"), true)
		"pillar_stump":
			PropKit.pillar(ci, Vector2.ZERO, 11.0, 26.0, ASH_STONE, true)
			PropKit.pile(ci, Vector2(14, 0), 8.0, 5.0, ASH_STONE, 12)
		"cold_brazier":
			VectorPaint.painted(ci, PackedVector2Array([Vector2(-4, 0), Vector2(4, 0), Vector2(2, -22), Vector2(-2, -22)]), PropKit.IRON, 1.6, 0.4, 1.2)
			VectorPaint.painted(ci, PackedVector2Array([Vector2(-11, -22), Vector2(11, -22), Vector2(7, -32), Vector2(-7, -32)]), PropKit.IRON_LIGHT, 2.4, 0.5, 1.3)
			VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -32), 11.0, 3.6, 16), Color("201c20"), 1.0, 0.0, 0.0)
		"stuck_shield":
			PropKit.beam(ci, Vector2(0, 0), Vector2(2, -34), 2.4)
			VectorPaint.painted(ci, PackedVector2Array([Vector2(-12, -42), Vector2(12, -42), Vector2(11, -26), Vector2(0, -14), Vector2(-11, -26)]), Color("5a5f6e"), 3.0, 0.5, 1.3)
			VectorPaint.painted(ci, PackedVector2Array([Vector2(-8, -38), Vector2(8, -38), Vector2(7, -28), Vector2(0, -20), Vector2(-7, -28)]), Color("7a2a28"), 2.0, 0.3, 0.0)
		"ash_mound":
			VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -6), 20.0, 9.0, 20), Color("6a6663"), 4.0, 0.4, 1.2)
			for k: int in 5:
				VectorStyle.draw_glow(ci, PropKit.EMBER, Vector2(-9 + k * 4.5, -8 - (k % 2) * 2.0), 3.0, 0.7)
		# ---- Sunless Mines
		"timber_support":
			PropKit.post(ci, -18.0, 56.0, 3.2)
			PropKit.post(ci, 18.0, 56.0, 3.2)
			PropKit.beam(ci, Vector2(-22, -54), Vector2(22, -54), 4.0)
			PropKit.beam(ci, Vector2(-18, -36), Vector2(-4, -52), 2.4)
			PropKit.beam(ci, Vector2(18, -36), Vector2(4, -52), 2.4)
		"ore_cart":
			_cart(ci, Color("4a4552"), Color("2c2a34"))
			for k: int in 4:
				VectorStyle.draw_glow(ci, Color("57e0c8") if k % 2 else Color("e8c060"), Vector2(-9 + k * 6.0, -24), 4.0, 0.6)
		"stalagmites":
			for k: int in 5:
				var x: float = -14.0 + k * 7.0
				VectorPaint.painted(ci, PackedVector2Array([Vector2(x - 4.4, 0), Vector2(x + 4.4, 0), Vector2(x + 0.6, -18 - (k % 3) * 8.0)]), Color("57535f").lightened(k * 0.03), 2.0, 0.5, 1.2)
		"glow_crystals":
			PropKit.crystal(ci, Vector2(-8, 0), 22.0, Color("57e0c8"))
			PropKit.crystal(ci, Vector2(5, 0), 30.0, Color("b58cff"))
			PropKit.crystal(ci, Vector2(14, 0), 16.0, Color("57e0c8"))
		"pickaxe_rack":
			PropKit.post(ci, -16.0, 30.0)
			PropKit.post(ci, 16.0, 30.0)
			PropKit.beam(ci, Vector2(-16, -26), Vector2(16, -26), 2.6)
			for x: float in [-9.0, 0.0, 9.0]:
				PropKit.beam(ci, Vector2(x, -4), Vector2(x * 0.7, -24), 2.0, PropKit.WOOD_LIGHT)
				VectorPaint.fill(ci, PackedVector2Array([Vector2(x * 0.7 - 5, -26), Vector2(x * 0.7 + 5, -26), Vector2(x * 0.7 + 2, -22), Vector2(x * 0.7 - 2, -22)]), Color("b58cff").lightened(0.2))
		"mine_lamp":
			PropKit.lamp_post(ci, 46.0, Color("ffc96a"))
		"ore_barrels":
			PropKit.barrel(ci, Vector2(-8, 0), 9.0, 17.0, Color("5a4a3c"))
			PropKit.barrel(ci, Vector2(10, 0), 8.0, 14.0, Color("5a4a3c"))
			for p: Vector2 in [Vector2(-8, -17), Vector2(10, -14)]:
				VectorStyle.draw_glow(ci, Color("57e0c8"), p + Vector2(0, -2), 8.0, 0.5)
		# ---- Pale Cathedral
		"broken_pew":
			VectorPaint.painted(ci, PackedVector2Array([Vector2(-22, 0), Vector2(22, 0), Vector2(22, -10), Vector2(-22, -10)]), Color("8a7a68"), 3.0, 0.4, 1.4)
			VectorPaint.painted(ci, PackedVector2Array([Vector2(-22, -10), Vector2(10, -10), Vector2(10, -26), Vector2(-22, -24)]), Color("9a8a76"), 3.0, 0.4, 1.4)
			ci.draw_polyline(PackedVector2Array([Vector2(6, -12), Vector2(9, -22), Vector2(4, -26)]), Color(PropKit.INK, 0.9), 1.4, true)
		"saint_statue":
			VectorPaint.painted(ci, PackedVector2Array([Vector2(-10, 0), Vector2(10, 0), Vector2(8, -8), Vector2(-8, -8)]), Color("a8a6b6"), 2.0, 0.4, 1.3)
			VectorPaint.painted(ci, PackedVector2Array([Vector2(-7, -8), Vector2(7, -8), Vector2(5, -36), Vector2(-5, -36)]), Color("d4d2e0"), 4.0, 0.6, 1.3)
			VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(0, -42), 5.5, 6.0, 14), Color("e2e0ee"), 2.0, 0.6, 1.2)
			VectorPaint.line(ci, Vector2(-7, -30), Vector2(-14, -22), Color("d4d2e0"), 3.0)
			VectorPaint.line(ci, Vector2(7, -30), Vector2(14, -24), Color("d4d2e0"), 3.0)
		"candle_stand":
			PropKit.lamp_post(ci, 34.0, Color("ffe6a0"))
			for k: int in 3:
				VectorStyle.draw_glow(ci, Color("ffe6a0"), Vector2(-8 + k * 8.0, -34 - (k % 2) * 3.0), 8.0, 0.4)
		"nave_pillar":
			PropKit.pillar(ci, Vector2.ZERO, 11.0, 84.0, Color("c8c6d6"))
		"broken_arch":
			PropKit.pillar(ci, Vector2(-18, 0), 7.0, 60.0, Color("c8c6d6"))
			PropKit.pillar(ci, Vector2(18, 0), 7.0, 38.0, Color("c8c6d6"), true)
			VectorPaint.painted(ci, PackedVector2Array([Vector2(-22, -58), Vector2(-8, -72), Vector2(4, -74), Vector2(-4, -60)]), Color("d4d2e0"), 2.4, 0.5, 1.3)
		"altar_slab":
			PropKit.slab(ci, Vector2(0, 0), 22.0, 14.0, Color("c8c6d6"))
			VectorPaint.painted(ci, PackedVector2Array([Vector2(-24, -14), Vector2(24, -14), Vector2(22, -18), Vector2(-22, -18)]), Color("e2e0ee"), 1.4, 0.5, 1.2)
			VectorStyle.draw_glow(ci, Color("e4d4ff"), Vector2(0, -20), 16.0, 0.3)
		"white_banner":
			PropKit.banner_pole(ci, 62.0, Color("d8d6e6"), false)
		"pilgrim_bones":
			PropKit.bones(ci, Vector2.ZERO, 1.2)
			VectorPaint.painted(ci, PackedVector2Array([Vector2(-14, -2), Vector2(14, -2), Vector2(10, -8), Vector2(-10, -8)]), Color("c8c6d6"), 1.4, 0.4, 1.0)
		# ---- Drowned Marsh
		"reeds", "cattails":
			for k: int in 9:
				var x: float = -14.0 + k * 3.6
				var h: float = 40.0 + (k % 4) * 8.0
				VectorPaint.strand(ci, Vector2(x, 0), Vector2(x + sin(k) * 3.0, -h * 0.6), Vector2(x + sin(k * 2.0) * 5.0, -h), 2.6, Color("3f6b4a").lightened((k % 3) * 0.05))
				if name == "cattails" and k % 2 == 0:
					VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(x + sin(k * 2.0) * 5.0, -h + 2.0), 1.8, 5.0, 8), Color("6b4a2c"), 0.8, 0.3, 0.8)
		"willow":
			PropKit.dead_tree(ci, 70.0, Color("4a3a2c"))
			for k: int in 9:
				var x: float = -22.0 + k * 5.4
				VectorPaint.strand(ci, Vector2(x * 0.6, -62.0 + absf(x) * 0.2), Vector2(x, -46), Vector2(x * 1.1, -22.0 - (k % 3) * 6.0), 2.4, Color("3f6b4a"))
		"stump":
			PropKit.stump(ci, Vector2.ZERO, 14.0, 13.0, Color("4a3a2c"))
			PropKit.moss_tuft(ci, Vector2(-8, -12), 1.2, Color("4a8a58"))
		"sunken_boat":
			VectorPaint.painted(ci, PackedVector2Array([Vector2(-26, -4), Vector2(26, -8), Vector2(20, -14), Vector2(-18, -16)]), Color("5a4030"), 3.0, 0.4, 1.4)
			for k: int in 4:
				VectorPaint.line(ci, Vector2(-18 + k * 11.0, -5.0 - k * 0.8), Vector2(-16 + k * 11.0, -15), Color(PropKit.INK, 0.5), 1.0)
			PropKit.beam(ci, Vector2(0, -12), Vector2(2, -40), 2.4)
			ci.draw_arc(Vector2(0, -3), 22.0, 0.2, PI - 0.2, 16, Color(0.7, 0.9, 0.9, 0.35), 1.0, true)
		"marsh_lantern":
			PropKit.lamp_post(ci, 44.0, Color("8fe8c8"))
		"drowned_tomb":
			PropKit.slab(ci, Vector2(0, 0), 20.0, 18.0, Color("5a6a68"))
			VectorStyle.draw_glow(ci, Color("57e0c8"), Vector2(0, -10), 18.0, 0.18)
			PropKit.moss_tuft(ci, Vector2(-12, -18), 1.5, Color("4a8a58"))
		"mushrooms":
			for k: int in 5:
				PropKit.glow_mushroom(ci, Vector2(-12 + k * 6.0, -(k % 2) * 2.0), 7.0 + (k % 3) * 3.0, Color("57e0b8") if k % 2 == 0 else Color("c8f57a"))


static func _wall(ci: CanvasItem, stone: Color) -> void:
	var wall: PackedVector2Array = PackedVector2Array([Vector2(-26, 0), Vector2(-26, -26), Vector2(-20, -32), Vector2(-14, -27), Vector2(-9, -38), Vector2(-3, -28), Vector2(4, -31), Vector2(10, -23), Vector2(17, -29), Vector2(26, -20), Vector2(26, 0)])
	VectorPaint.painted(ci, wall, stone, 4.0, 0.5, 1.4)
	for row: int in 4:
		var y: float = -4.0 - row * 7.0
		VectorPaint.line(ci, Vector2(-25, y), Vector2(25, y), Color(PropKit.INK, 0.4), 0.9)
		for k: int in 5:
			var x: float = -21.0 + k * 10.0 + (5.0 if row % 2 == 0 else 0.0)
			VectorPaint.line(ci, Vector2(x, y), Vector2(x, y - 7.0), Color(PropKit.INK, 0.3), 0.8)


static func _cart(ci: CanvasItem, body: Color, wheel: Color) -> void:
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-20, -10), Vector2(20, -10), Vector2(17, -26), Vector2(-17, -26)]), body, 3.0, 0.45, 1.4)
	VectorPaint.painted(ci, PackedVector2Array([Vector2(-20, -10), Vector2(20, -10), Vector2(20, -13), Vector2(-20, -13)]), wheel, 1.0, 0.3, 1.0)
	for w: float in [-12.0, 12.0]:
		VectorPaint.painted(ci, VectorStyle.ellipse(Vector2(w, -5), 6.0, 6.0, 14), wheel, 1.6, 0.4, 1.3)
		ci.draw_circle(Vector2(w, -5), 1.5, PropKit.IRON_LIGHT, true, -1.0, true)
	for k: int in 6:
		PropKit.rock(ci, Vector2(-12 + k * 5.0, -26), 3.2, Color("6a6070").darkened((k % 3) * 0.1), k + 20)
