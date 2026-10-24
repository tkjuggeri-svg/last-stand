extends "res://tools/art/huntress_art.gd"
## The Necromancer (dev-time art generator): the Huntress's poses and sheet layout in a hooded violet
## robe with a pale face and glowing green eyes, a bone-topped staff in her hands instead of the
## crossbow. Her attack frames raise the staff along the facing and flare its soul-fire on the cast
## (frame 1). Same frame size and anchors as the Knight (sheet_layouts.HERO).


func _init(resolution: int = 1) -> void:
	super(resolution)
	armor = P.LICH_ROBE
	armor_dark = P.LICH_ROBE
	cloth = P.LICH_ROBE
	hood = P.LICH_ROBE
	skin = P.BONE
	glow_eyes = true


## A skull on her belt where the Huntress carried a quiver (seen from behind: a hanging bone charm).
func _kite_back(c: Canvas, center: Vector2) -> void:
	c.part()
	c.ellipse(center + Vector2(0, 1.0), Vector2(1.8, 1.7), P.BONE, 0.0, 0.1)
	c.line(center + Vector2(0, -1.0), center + Vector2(0, -4.5), P.LEATHER[2])


## A staff along the pose's angle: a long wooden pole with a skull on top and a green soul-fire.
func _sword(c: Canvas, hand: Vector2, pose: Dictionary) -> void:
	var angle: float = pose["angle"]
	if angle < -999.0:
		angle = 100.0
	var dir: Vector2 = Vector2.from_angle(deg_to_rad(angle))
	c.part()
	c.capsule(hand - dir * 5.0, hand + dir * 8.5, 0.8, P.WOOD, 0.1)
	var top: Vector2 = hand + dir * 10.0
	c.part()
	c.ellipse(top, Vector2(2.1, 2.0), P.BONE, 0.0, 0.2)
	c.px(floori(top.x) - 1, floori(top.y), P.OUTLINE)
	c.px(floori(top.x) + 1, floori(top.y), P.OUTLINE)
	c.part(true)
	c.ellipse(top + dir * 2.6, Vector2(1.3, 1.5), P.SOUL, 0.0, 0.3)
