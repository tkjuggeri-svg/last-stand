extends "res://tools/art/hero_art.gd"
## The Huntress (dev-time art generator): the Knight's poses and sheet layout with other clothes. A
## green hooded cloak over a leather jerkin, a quiver on her back and a crossbow in her hands instead
## of the sword and shield. Her attack frames aim the crossbow along the facing and kick back on the
## shot (frame 1). Same frame size and anchors as the Knight (sheet_layouts.HERO).

const SKIN_LIT: Color = Color("deae8a")


func _init(resolution: int = 1) -> void:
	super(resolution)
	armor = P.LEATHER
	armor_dark = P.LEATHER
	cloth = P.HOOD


## The crossbow is aimed along the facing; a kick back on frame 1, then lowered.
func _attack_pose(facing: String, i: int) -> Dictionary:
	var pose: Dictionary = _base_pose()
	pose["hem"] = [0.0, 1.5, 1.0, 0.5][i]
	pose["crest"] = pose["hem"]
	var recoil: float = [0.0, 1.0, 0.5, 0.0][i]
	match facing:
		"down":
			pose["hand"] = Vector2(1, -3 - recoil)
			pose["angle"] = 90.0
			pose["lean"] = Vector2(0, -recoil)
		"up":
			pose["hand"] = Vector2(-1, -8 + recoil)
			pose["angle"] = -90.0
			pose["lean"] = Vector2(0, recoil)
		"side":
			pose["hand"] = Vector2(-1 - recoil, -4)
			pose["angle"] = 0.0
			pose["lean"] = Vector2(-recoil, 0)
	return pose


## A hooded cloak: the hood's dome with a shadowed face opening (front, side), a pointed back (up).
func _helm(c: Canvas, center: Vector2, facing: String, crest_sway: float) -> void:
	c.part()
	c.ellipse(center + Vector2(0, 5.0), Vector2(4.0, 2.4), P.HOOD)  # the cowl on the shoulders
	c.part()
	c.ellipse(center, HELM_RADIUS, P.HOOD, 0.0, -0.05)
	var cx: int = roundi(center.x)
	var cy: int = roundi(center.y)
	match facing:
		"down":
			c.part()
			c.ellipse(center + Vector2(0, 1.2), Vector2(3.4, 3.2), P.SKIN, 0.0, -0.1)
			c.rect(Rect2i(cx - 3, cy - 1, 7, 1), P.HOOD[0])  # the hood's shadow over the brow
			c.px(cx - 2, cy + 1, P.OUTLINE)
			c.px(cx + 2, cy + 1, P.OUTLINE)
		"up":
			c.part()
			c.polygon(PackedVector2Array([center + Vector2(-1.8, -7.0), center + Vector2(0.6 + crest_sway * 0.3, -9.0),
				center + Vector2(1.8, -5.0), center + Vector2(1.4, 1.0), center + Vector2(-1.4, 1.0)]), P.HOOD, Vector3(-0.2, -0.5, 1))
		_:
			c.part()
			c.ellipse(center + Vector2(2.2, 1.0), Vector2(2.4, 3.0), P.SKIN, 0.0, -0.1)
			c.rect(Rect2i(cx, cy - 1, 6, 1), P.HOOD[0])
			c.px(cx + 3, cy + 1, P.OUTLINE)
			c.part()
			c.polygon(PackedVector2Array([center + Vector2(-1.0, -4.6), center + Vector2(-4.6 - crest_sway * 0.3, -3.0),
				center + Vector2(-5.2, 1.6), center + Vector2(-2.0, 2.4)]), P.HOOD, Vector3(-0.2, -0.3, 1))


## Leather shoulder straps instead of plate.
func _pauldron(c: Canvas, center: Vector2, _back: bool) -> void:
	c.part()
	c.ellipse(center, Vector2(2.6, 2.2), P.LEATHER, 0.0, 0.08)


## The off hand on the crossbow's fore-end, where the Knight's shield was.
func _kite_face(c: Canvas, center: Vector2, _width: float) -> void:
	c.part()
	c.ellipse(center + Vector2(0, -3.0), Vector2(1.6, 1.5), P.SKIN, 0.0, 0.1)


## The quiver on her back (seen from behind), arrows' fletching above it.
func _kite_back(c: Canvas, center: Vector2) -> void:
	c.part()
	c.capsule(center + Vector2(0.5, -3.5), center + Vector2(-0.5, 2.5), 1.7, P.LEATHER, -0.1)
	c.part()
	for dx: float in [-1.0, 0.0, 1.0]:
		c.line(center + Vector2(dx, -4.0), center + Vector2(dx + 0.3, -7.0), P.BONE[2] if dx == 0.0 else P.BONE[1])
	c.line(center + Vector2(-1.4, -3.0), center + Vector2(0.6, 3.0), P.LEATHER[1])


## A crossbow held at `hand`, pointing along the pose's angle: a wooden stock, steel prod across the
## front and a bolt laid in the groove.
func _sword(c: Canvas, hand: Vector2, pose: Dictionary) -> void:
	var angle: float = pose["angle"]
	if angle < -999.0:
		angle = 100.0
	var dir: Vector2 = Vector2.from_angle(deg_to_rad(angle))
	var across: Vector2 = Vector2(-dir.y, dir.x)
	c.part()
	c.capsule(hand - dir * 2.2, hand + dir * 6.0, 0.9, P.WOOD, 0.1)
	var prod: Vector2 = hand + dir * 5.2
	c.part()
	c.line(prod - across * 3.6 - dir * 0.8, prod, P.STEEL[3])
	c.line(prod, prod + across * 3.6 - dir * 0.8, P.STEEL[3])
	c.line(prod - across * 3.4 - dir * 0.6, prod + across * 3.4 - dir * 0.6, P.BONE[1], true)  # the string
	c.px(floori(hand.x + dir.x * 6.0), floori(hand.y + dir.y * 6.0), P.STEEL[5])  # the bolt's head
