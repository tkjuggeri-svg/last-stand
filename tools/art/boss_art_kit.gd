extends RefCounted
## Shared helpers for the three bosses' art (dev-time art generator): 64x64 art px frames (feet on
## FEET), the sheet's row order, a shaded flared robe, and the big undead death (pale flash, collapse,
## crumbling to ash, a large soul escaping). Each boss file (gravelord_art.gd, colossus_art.gd,
## lich_art.gd, tollkeeper_art.gd) poses and draws its own figure through pose() and frame().

const Canvas: GDScript = preload("res://tools/art/canvas.gd")
const P: GDScript = preload("res://tools/art/palette.gd")
const Undead: GDScript = preload("res://tools/art/undead_fx.gd")

const SIZE: Vector2i = Vector2i(64, 64)
const FEET: Vector2 = Vector2(32, 58)
const FACINGS: Array[String] = ["down", "up", "side"]
## Frames per state (the attack's blow lands on frame 6 at 10 fps = a 0.6 s wind-up).
const FRAMES: Dictionary = {"idle": 4, "walk": 6, "attack": 8, "cast": 6, "brace": 4, "charge": 4, "stun": 4, "toll": 6}


## Rows in the order of the boss layouts in sheet_layouts.gd: idle, walk (per facing), death, attack
## (per facing), then each ability state per facing. `art` has pose(state, facing, i) and frame().
static func sheet_rows(art: RefCounted, ability_states: Array) -> Array[Array]:
	var rows: Array[Array] = []
	for state: String in ["idle", "walk"]:
		for facing: String in FACINGS:
			rows.append(_row(art, state, facing))
	rows.append(art.call("death_frames"))
	for state: String in ["attack"] + ability_states:
		for facing: String in FACINGS:
			rows.append(_row(art, state, facing))
	return rows


static func _row(art: RefCounted, state: String, facing: String) -> Array[Image]:
	var row: Array[Image] = []
	for i: int in FRAMES[state]:
		row.append(art.call("frame", facing, art.call("pose", state, facing, i)))
	return row


## A flared robe from the shoulders (top_y, half width `top`) to the hem (bottom_y, `bottom`),
## shaded as a cone, with a ragged hem (every third column a pixel short), shifted by `sway` at the hem.
static func robe(c: Canvas, ramp: Array, cx: float, top_y: float, bottom_y: float, top: float, bottom: float,
		sway: float, bias: float = 0.0) -> void:
	c.part()
	for y: int in range(floori(top_y), ceili(bottom_y)):
		var t: float = (y + 0.5 - top_y) / (bottom_y - top_y)
		var half: float = lerpf(top, bottom, t)
		var mid: float = cx + sway * t
		for x: int in range(floori(mid - half), ceili(mid + half)):
			var nx: float = (x + 0.5 - mid) / half
			if absf(nx) > 1.0:
				continue
			if y == ceili(bottom_y) - 1 and posmod(x + roundi(sway * 2.0), 3) == 0:
				continue
			c.px(x, y, Canvas.shade(ramp, Canvas.light_of(Vector3(nx, -0.15, sqrt(1.0 - nx * nx))) + bias))


## The big death: a pale flash, a stagger, the collapse (`fallen`), then the remains crumble while a
## large soul rises. `upright` and `stagger` are full frames of the figure.
static func death(upright: Image, stagger: Image, fallen: Image, soul_at: Vector2) -> Array[Image]:
	var frames: Array[Image] = []
	var flash: Image = upright.duplicate() as Image
	Undead.tint(flash, Color("f4f8ee"), 0.6)
	frames.append(flash)
	frames.append(stagger)
	var flash2: Image = stagger.duplicate() as Image
	Undead.tint(flash2, Color("f4f8ee"), 0.3)
	frames.append(flash2)
	frames.append(fallen)
	for step: int in 3:
		var crumbling: Image = fallen.duplicate() as Image
		Undead.crumble(crumbling, step)
		Undead.soul(crumbling, step, soul_at, 2.2)
		frames.append(crumbling)
	var last: Image = Image.create_empty(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	Undead.soul(last, 2, soul_at - Vector2(0, 14), 1.4)
	frames.append(last)
	return frames


## A figure image laid on its side on the ground line (for the collapse frame).
static func lying(figure: Image, shadow_radius: float) -> Image:
	var body: Image = figure.duplicate() as Image
	body.rotate_90(CLOCKWISE)
	var used: Rect2i = body.get_used_rect()
	var out: Canvas = Canvas.new(SIZE.x, SIZE.y)
	out.image.blend_rect(body, used, Vector2i(floori((SIZE.x - used.size.x) / 2.0), int(FEET.y) + 1 - used.size.y))
	out.ground_shadow(Vector2(32, FEET.y - 1), Vector2(shadow_radius, 3.4))
	return out.image
