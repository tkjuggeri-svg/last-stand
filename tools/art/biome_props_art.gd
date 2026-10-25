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
