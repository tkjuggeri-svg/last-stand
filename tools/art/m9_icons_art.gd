extends RefCounted
## The M9 card and relic icons (dev-time art generator): 32x32, one subject each on a transparent
## ground with the 1 px dark outline, light from the top-left. Barbed Bolts, Quick Hands, Snare Mastery,
## Hunter's Mark (cards) and Quiver of Plenty (relic).

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")

const SIZE: Vector2i = Vector2i(32, 32)
## Icon id -> drawing method (and where it is saved).
const ICONS: Dictionary = {
	"barbed_bolts": "res://assets/sprites/ui/upgrades/barbed_bolts.png",
	"quick_hands": "res://assets/sprites/ui/upgrades/quick_hands.png",
	"snare_mastery": "res://assets/sprites/ui/upgrades/snare_mastery.png",
	"hunters_mark": "res://assets/sprites/ui/upgrades/hunters_mark.png",
	"quiver_of_plenty": "res://assets/sprites/ui/relics/quiver_of_plenty.png",
	"bone_armour": "res://assets/sprites/ui/upgrades/bone_armour.png",
	"gravecaller": "res://assets/sprites/ui/upgrades/gravecaller.png",
	"soul_feast": "res://assets/sprites/ui/upgrades/soul_feast.png",
	"dark_bargain": "res://assets/sprites/ui/upgrades/dark_bargain.png",
	"reliquary_of_bones": "res://assets/sprites/ui/relics/reliquary_of_bones.png",
	"iron_teeth": "res://assets/sprites/ui/upgrades/iron_teeth.png",
	"long_cord": "res://assets/sprites/ui/upgrades/long_cord.png",
	"falcons_hood": "res://assets/sprites/ui/relics/falcons_hood.png",
	"grave_crown": "res://assets/sprites/ui/relics/grave_crown.png",
	"shield_bash": "res://assets/sprites/ui/upgrades/shield_bash.png",
	"oathkeeper": "res://assets/sprites/ui/upgrades/oathkeeper.png",
	"rally": "res://assets/sprites/ui/upgrades/rally.png",
	"iron_will": "res://assets/sprites/ui/upgrades/iron_will.png",
	"crown_of_thorns": "res://assets/sprites/ui/relics/crown_of_thorns.png",
	"banner_of_the_last_keep": "res://assets/sprites/ui/relics/banner_of_the_last_keep.png",
}


func icon(id: String) -> Image:
	var c: Canvas = Canvas.new(SIZE.x, SIZE.y)
	call("_" + id, c)
	c.finish()
	return c.image


func _bolt(c: Canvas, from: Vector2, to: Vector2) -> void:
	c.part()
	c.capsule(from, to, 1.1, P.WOOD, 0.1)
	var dir: Vector2 = (to - from).normalized()
	c.part()
	c.polygon(PackedVector2Array([to + dir * 4.0, to + Vector2(-dir.y, dir.x) * 2.0, to - Vector2(-dir.y, dir.x) * 2.0]), P.STEEL, Vector3(-0.3, -0.4, 1))
	c.part()
	var across: Vector2 = Vector2(-dir.y, dir.x)
	for k: int in 2:
		var at: Vector2 = from + dir * (1.5 + k * 2.0)
		c.line(at, at + across * 2.4 - dir * 1.5, P.BANNER[3])
		c.line(at, at - across * 2.4 - dir * 1.5, P.BANNER[3])


func _barbed_bolts(c: Canvas) -> void:
	_bolt(c, Vector2(5, 26), Vector2(24, 7))
	c.part()
	for t: float in [0.5, 0.7]:
		var at: Vector2 = Vector2(5, 26).lerp(Vector2(24, 7), t)
		c.line(at, at + Vector2(3, 2.5), P.STEEL[4])
		c.line(at, at + Vector2(-2.5, -3), P.STEEL[4])


func _quick_hands(c: Canvas) -> void:
	c.part()
	c.ellipse(Vector2(17, 17), Vector2(7, 6.5), P.SKIN, 0.0, 0.1)
	for k: int in 4:
		c.capsule(Vector2(14 + k * 3.0, 14), Vector2(14 + k * 3.0, 8 - (k % 2)), 1.4, P.SKIN, 0.1)
	c.capsule(Vector2(11, 18), Vector2(7, 14), 1.5, P.SKIN, 0.1)
	c.part(true)
	for k: int in 3:
		c.line(Vector2(2, 20 + k * 3), Vector2(8, 20 + k * 3), P.BONE[3])


func _snare_mastery(c: Canvas) -> void:
	c.part()
	c.ellipse(Vector2(16, 19), Vector2(11, 7), P.LEATHER, 0.0, 0.0)
	c.ellipse(Vector2(16, 19), Vector2(7, 4), P.DIRT, 0.0, -0.3)
	for k: int in 8:
		var a: float = TAU * k / 8.0
		var base: Vector2 = Vector2(16 + cos(a) * 9.0, 19 + sin(a) * 5.5)
		c.part()
		c.line(base, base + Vector2(cos(a) * 1.5, sin(a) * 1.0 - 4.0), P.STEEL[4])
	c.part()
	c.capsule(Vector2(16, 12), Vector2(16, 6), 1.2, P.LEATHER, 0.0)


func _hunters_mark(c: Canvas) -> void:
	c.part()
	c.ellipse(Vector2(16, 16), Vector2(10, 10), P.TABARD, 0.0, 0.1)
	c.ellipse(Vector2(16, 16), Vector2(6.5, 6.5), P.DIRT, 0.0, -0.4)
	c.part()
	c.rect(Rect2i(15, 2, 2, 28), P.TABARD[4])
	c.rect(Rect2i(2, 15, 28, 2), P.TABARD[4])
	c.part()
	c.ellipse(Vector2(16, 16), Vector2(2, 2), P.GOLD, 0.0, 0.3)


func _quiver_of_plenty(c: Canvas) -> void:
	for k: int in 5:
		var x: float = 9.0 + k * 3.5
		c.part()
		c.line(Vector2(x, 14), Vector2(x - 6.0 + k * 3.0, 3), P.WOOD[4])
		c.px(roundi(x - 6.0 + k * 3.0), 2, P.STEEL[4])
	c.part()
	c.capsule(Vector2(16, 12), Vector2(15, 27), 5.0, P.LEATHER, 0.0)
	c.part()
	c.line(Vector2(11, 14), Vector2(20, 14), P.GOLD[2])
	c.line(Vector2(11.5, 23), Vector2(19.5, 23), P.GOLD[2])


func _skull(c: Canvas, at: Vector2, radius: float) -> void:
	c.part()
	c.ellipse(at, Vector2(radius, radius * 0.95), P.BONE, 0.0, 0.15)
	c.ellipse(at + Vector2(0, radius * 0.9), Vector2(radius * 0.6, radius * 0.4), P.BONE, 0.0, -0.1)
	c.part()
	c.ellipse(at + Vector2(-radius * 0.4, 0), Vector2(radius * 0.22, radius * 0.28), P.SOUL, 0.0, 0.3)
	c.ellipse(at + Vector2(radius * 0.4, 0), Vector2(radius * 0.22, radius * 0.28), P.SOUL, 0.0, 0.3)


func _bone_armour(c: Canvas) -> void:
	c.part()
	c.polygon(PackedVector2Array([Vector2(6, 8), Vector2(26, 8), Vector2(24, 26), Vector2(16, 30), Vector2(8, 26)]), P.BONE, Vector3(-0.3, -0.4, 1))
	for k: int in 4:
		c.part()
		c.line(Vector2(9, 12 + k * 4), Vector2(23, 12 + k * 4), P.BONE[0])
	c.part()
	c.rect(Rect2i(15, 8, 2, 20), P.BONE[0])


func _gravecaller(c: Canvas) -> void:
	c.part()
	c.ellipse(Vector2(16, 26), Vector2(12, 4.5), P.DIRT, 0.0, -0.1)
	c.part()
	c.capsule(Vector2(16, 26), Vector2(16, 12), 1.8, P.BONE, 0.1)
	for k: int in 4:
		c.line(Vector2(12 + k * 2.6, 12), Vector2(11 + k * 3.0, 6 + (k % 2)), P.BONE[3])
	c.part(true)
	c.ellipse(Vector2(16, 18), Vector2(3, 3), P.SOUL, 0.0, 0.2)


func _soul_feast(c: Canvas) -> void:
	_skull(c, Vector2(16, 18), 8.0)
	c.part(true)
	for k: int in 3:
		c.ellipse(Vector2(7 + k * 9, 6 + (k % 2) * 3), Vector2(1.6, 2.4), P.SOUL, 0.0, 0.3)


func _dark_bargain(c: Canvas) -> void:
	c.part()
	c.ellipse(Vector2(16, 16), Vector2(11, 11), P.GOLD, 0.0, 0.0)
	c.ellipse(Vector2(16, 16), Vector2(8, 8), P.GOLD, 0.0, -0.3)
	_skull(c, Vector2(16, 16), 5.0)
	c.part()
	c.line(Vector2(6, 6), Vector2(26, 26), P.TABARD[3])


func _reliquary_of_bones(c: Canvas) -> void:
	c.part()
	c.block(Rect2(6, 12, 20, 6), 10.0, P.GOLD.slice(1, 5), P.GOLD.slice(0, 4))
	c.part()
	c.polygon(PackedVector2Array([Vector2(5, 12), Vector2(16, 5), Vector2(27, 12)]), P.GOLD, Vector3(-0.3, -0.5, 1))
	_skull(c, Vector2(16, 21), 3.4)


func _falcons_hood(c: Canvas) -> void:
	c.part()
	c.ellipse(Vector2(16, 17), Vector2(10, 11), P.LEATHER, 0.0, 0.0)
	c.ellipse(Vector2(16, 20), Vector2(5.5, 6.5), P.CULT_DARK, 0.0, -0.3)
	c.part()
	c.polygon(PackedVector2Array([Vector2(13, 6), Vector2(16, 1), Vector2(19, 6)]), P.TABARD, Vector3(-0.2, -0.5, 1))
	c.part(true)
	c.px(14, 18, P.GOLD[4])
	c.px(18, 18, P.GOLD[4])


func _grave_crown(c: Canvas) -> void:
	c.part()
	c.polygon(PackedVector2Array([Vector2(4, 24), Vector2(6, 9), Vector2(11, 17), Vector2(16, 6), Vector2(21, 17), Vector2(26, 9), Vector2(28, 24)]), P.BONE, Vector3(-0.3, -0.5, 1))
	c.line(Vector2(4, 24), Vector2(28, 24), P.GOLD[2])
	c.part(true)
	c.ellipse(Vector2(16, 17), Vector2(2, 2.4), P.SOUL, 0.0, 0.3)


func _iron_teeth(c: Canvas) -> void:
	c.part()
	c.ellipse(Vector2(16, 22), Vector2(12, 5), P.IRON, 0.0, 0.0)
	for k: int in 6:
		c.part()
		c.polygon(PackedVector2Array([Vector2(6 + k * 4, 21), Vector2(8 + k * 4, 21), Vector2(7 + k * 4, 8 + (k % 2) * 3)]), P.STEEL, Vector3(-0.3, -0.4, 1))


func _long_cord(c: Canvas) -> void:
	c.part()
	c.capsule(Vector2(5, 26), Vector2(14, 12), 1.5, P.LEATHER, 0.1)
	c.capsule(Vector2(14, 12), Vector2(27, 7), 1.5, P.LEATHER, 0.1)
	c.part()
	c.ellipse(Vector2(27, 7), Vector2(3, 3), P.IRON, 0.0, 0.1)
	c.part(true)
	c.line(Vector2(4, 28), Vector2(10, 28), P.BONE[3])
	c.line(Vector2(6, 30), Vector2(12, 30), P.BONE[3])


## The Knight's cards and relics (M13 follow-up).
func _shield_bash(c: Canvas) -> void:
	c.part()
	c.ellipse(Vector2(18, 16), Vector2(9, 10), P.STEEL, 0.0, 0.1)
	c.part()
	c.ellipse(Vector2(18, 16), Vector2(3.5, 3.5), P.GOLD, 0.0, 0.3)
	c.part(true)
	for k: int in 3:
		c.line(Vector2(2, 10 + k * 5), Vector2(8, 10 + k * 5), P.BONE[3])


func _oathkeeper(c: Canvas) -> void:
	c.part()
	c.capsule(Vector2(16, 3), Vector2(16, 21), 2.0, P.STEEL, 0.1)
	c.part()
	c.rect(Rect2i(9, 21, 14, 3), P.GOLD[3])
	c.part()
	c.capsule(Vector2(16, 24), Vector2(16, 29), 1.5, P.LEATHER, 0.0)
	c.part(true)
	c.ellipse(Vector2(16, 9), Vector2(5, 3), P.GOLD, 0.0, 0.2)


func _rally(c: Canvas) -> void:
	c.part()
	c.capsule(Vector2(8, 4), Vector2(8, 29), 1.4, P.WOOD, 0.0)
	c.part()
	c.polygon(PackedVector2Array([Vector2(9, 5), Vector2(27, 8), Vector2(22, 13), Vector2(27, 18), Vector2(9, 16)]), P.TABARD, Vector3(-0.3, -0.4, 1))
	c.part(true)
	c.line(Vector2(12, 10), Vector2(21, 11), P.GOLD[2])


func _iron_will(c: Canvas) -> void:
	c.part()
	c.polygon(PackedVector2Array([Vector2(6, 5), Vector2(26, 5), Vector2(26, 17), Vector2(16, 28), Vector2(6, 17)]), P.STEEL, Vector3(-0.3, -0.4, 1))
	c.part()
	c.rect(Rect2i(15, 7, 2, 16), P.GOLD[3])
	c.rect(Rect2i(9, 12, 14, 2), P.GOLD[3])


func _crown_of_thorns(c: Canvas) -> void:
	c.part()
	c.ellipse(Vector2(16, 20), Vector2(11, 5), P.GOLD, 0.0, 0.1)
	c.part()
	c.ellipse(Vector2(16, 20), Vector2(8, 2.5), P.DIRT, 0.0, -0.3)
	for k: int in 5:
		var x: float = 7.0 + k * 4.5
		c.part()
		c.polygon(PackedVector2Array([Vector2(x - 2.0, 19), Vector2(x, 7.0 + absi(k - 2) * 2.0), Vector2(x + 2.0, 19)]), P.STEEL, Vector3(-0.3, -0.4, 1))


func _banner_of_the_last_keep(c: Canvas) -> void:
	c.part()
	c.capsule(Vector2(8, 3), Vector2(8, 29), 1.4, P.WOOD, 0.0)
	c.part()
	c.polygon(PackedVector2Array([Vector2(9, 4), Vector2(27, 4), Vector2(27, 21), Vector2(18, 26), Vector2(9, 21)]), P.TABARD, Vector3(-0.3, -0.4, 1))
	c.part(true)
	c.rect(Rect2i(14, 12, 8, 7), P.STEEL[4])
	c.rect(Rect2i(14, 10, 2, 2), P.STEEL[4])
	c.rect(Rect2i(18, 10, 2, 2), P.STEEL[4])
	c.rect(Rect2i(22, 10, 0, 2), P.STEEL[4])
