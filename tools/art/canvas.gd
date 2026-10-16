extends RefCounted
## A drawing surface for code-made pixel art (dev tool, not shipped).
## Shapes are shaded like simple 3D volumes lit from the top-left (see ART_DIRECTION.md) and every
## pixel is snapped to a hand-picked colour ramp, so nothing is ever blurred or anti-aliased.
## Each drawn shape belongs to a "part"; finish() darkens a back part where a front part overlaps it
## (crisp interior contours) and adds the 1 px dark outline around the whole silhouette.

const OUTLINE: Color = Color("1a141f")
const SHADOW: Color = Color(0.0, 0.0, 0.0, 0.34)
## Light from the top-left, a little in front of the scene (x right, y down, z toward the viewer).
const LIGHT: Vector3 = Vector3(-0.58, -0.62, 0.53)
const DIRS_4: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const DIRS_8: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]
const BAYER_4: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

var image: Image
var size: Vector2i
## How much brighter (+) or darker (-) shading comes out, applied before picking a ramp colour.
var exposure: float = 0.0

## Draw order of the part that owns each pixel (0 = empty).
var _owner: PackedInt32Array
var _part: int = 0
## Parts that never get contour lines drawn against them (glows, sparks, smoke).
var _soft_parts: Dictionary = {}


func _init(width: int, height: int) -> void:
	size = Vector2i(width, height)
	image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	_owner = PackedInt32Array()
	_owner.resize(width * height)
	part()


## Starts a new part: everything drawn until the next call counts as one piece (one contour).
## A soft part (glow, flame, smoke) neither draws nor receives contour lines.
func part(soft: bool = false) -> void:
	_part += 1
	if soft:
		_soft_parts[_part] = true


# ---------------------------------------------------------------- shading

## Picks a ramp colour (dark -> light) for a brightness in [0, 1]. With dither, pixels near a band
## edge alternate in a fixed 4x4 pattern, which reads as a smooth retro gradient.
static func shade(ramp: Array, value: float, x: int = 0, y: int = 0, dither: bool = false) -> Color:
	var n: int = ramp.size()
	var scaled: float = clampf(value, 0.0, 0.9999) * n
	var index: int = int(scaled)
	if dither:
		var frac: float = scaled - index
		if frac > 0.5 + BAYER_4[(y % 4) * 4 + (x % 4)] / 32.0:
			index += 1
	return ramp[clampi(index, 0, n - 1)]


## Half-Lambert brightness of a surface normal (never pitch black on the shadow side), with a contrast
## curve so the brightest ramp colours only appear as small highlights facing the light.
static func light_of(normal: Vector3) -> float:
	return pow(normal.normalized().dot(LIGHT.normalized()) * 0.5 + 0.5, 1.5)


# ---------------------------------------------------------------- primitives

## A rounded volume (a squashed sphere): heads, bellies, shoulder plates, bushes.
## flat squashes the bulge (0 = sphere, 1 = flat disc lit from the front).
func ellipse(center: Vector2, radius: Vector2, ramp: Array, flat: float = 0.0, bias: float = 0.0) -> void:
	for y: int in range(floori(center.y - radius.y), ceili(center.y + radius.y) + 1):
		for x: int in range(floori(center.x - radius.x), ceili(center.x + radius.x) + 1):
			var d: Vector2 = (Vector2(x + 0.5, y + 0.5) - center) / radius
			var q: float = d.length_squared()
			if q > 1.0:
				continue
			var normal: Vector3 = Vector3(d.x, d.y, sqrt(1.0 - q) + flat * 2.0)
			_put(x, y, shade(ramp, light_of(normal) + bias + exposure))


## A tube between two points (limbs, swords, poles) shaded around its axis.
func capsule(a: Vector2, b: Vector2, radius: float, ramp: Array, bias: float = 0.0) -> void:
	var lo: Vector2 = a.min(b) - Vector2(radius, radius)
	var hi: Vector2 = a.max(b) + Vector2(radius, radius)
	for y: int in range(floori(lo.y), ceili(hi.y) + 1):
		for x: int in range(floori(lo.x), ceili(hi.x) + 1):
			var p: Vector2 = Vector2(x + 0.5, y + 0.5)
			var closest: Vector2 = Geometry2D.get_closest_point_to_segment(p, a, b)
			var d: Vector2 = (p - closest) / radius
			var q: float = d.length_squared()
			if q > 1.0:
				continue
			_put(x, y, shade(ramp, light_of(Vector3(d.x, d.y, sqrt(1.0 - q))) + bias + exposure))


## A thin hard line (1 px), e.g. a bowstring, a crack, a blade edge.
func line(a: Vector2, b: Vector2, color: Color) -> void:
	var steps: int = maxi(ceili(maxf(absf(b.x - a.x), absf(b.y - a.y))), 1)
	for i: int in steps + 1:
		var p: Vector2 = a.lerp(b, float(i) / steps)
		_put(floori(p.x), floori(p.y), color)


## A flat-coloured polygon (cloth, banners, roof planes). Shaded by its own normal if a ramp is given.
func polygon(points: PackedVector2Array, ramp: Array, normal: Vector3 = Vector3(0, 0, 1), dither: bool = false) -> void:
	var box: Rect2 = Rect2(points[0], Vector2.ZERO)
	for p: Vector2 in points:
		box = box.expand(p)
	var value: float = light_of(normal) + exposure
	for y: int in range(floori(box.position.y), ceili(box.end.y) + 1):
		for x: int in range(floori(box.position.x), ceili(box.end.x) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				_put(x, y, shade(ramp, value, x, y, dither))


## A vertical cylinder seen from the 3/4 view: an elliptic top face and a curved front.
## Used for towers, columns and barrels. top_ramp may be empty (open top drawn by the caller).
func cylinder(center_x: float, top_y: float, bottom_y: float, radius: float, cap: float, ramp: Array,
		top_ramp: Array = [], dither: bool = true) -> void:
	for y: int in range(floori(top_y - cap), ceili(bottom_y + cap) + 1):
		for x: int in range(floori(center_x - radius), ceili(center_x + radius) + 1):
			var dx: float = (x + 0.5 - center_x) / radius
			if absf(dx) > 1.0:
				continue
			var bulge: float = sqrt(1.0 - dx * dx)
			var yy: float = y + 0.5
			if yy < top_y - bulge * cap or yy > bottom_y + bulge * cap:
				continue
			# The front wall: lit across its curve, a touch darker toward the ground.
			var value: float = light_of(Vector3(dx, 0.15, bulge)) - 0.12 * (yy - top_y) / maxf(bottom_y - top_y, 1.0)
			_put(x, y, shade(ramp, value + exposure, x, y, dither))
	if not top_ramp.is_empty():
		ellipse(Vector2(center_x, top_y), Vector2(radius, cap), top_ramp, 1.2)


## A box seen from the 3/4 view: a lit top face and a darker front (south) face of the given height.
func block(top: Rect2, height: float, top_ramp: Array, front_ramp: Array, dither: bool = true) -> void:
	var t: float = light_of(Vector3(0, -0.2, 1)) + exposure
	for y: int in range(floori(top.position.y), ceili(top.end.y)):
		for x: int in range(floori(top.position.x), ceili(top.end.x)):
			var edge: float = 0.08 if x == floori(top.position.x) or y == floori(top.position.y) else 0.0
			_put(x, y, shade(top_ramp, t + edge, x, y, dither))
	var f: float = light_of(Vector3(-0.1, 0.35, 0.9)) + exposure
	for y: int in range(ceili(top.end.y), ceili(top.end.y + height)):
		for x: int in range(floori(top.position.x), ceili(top.end.x)):
			var fade: float = -0.1 * (y - top.end.y) / maxf(height, 1.0)
			_put(x, y, shade(front_ramp, f + fade, x, y, dither))


## Fills a rectangle with one colour.
func rect(area: Rect2i, color: Color) -> void:
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			_put(x, y, color)


func px(x: int, y: int, color: Color) -> void:
	_put(x, y, color)


## Pastes a hand-drawn grid: one character per pixel, "." is empty, other keys come from `keys`.
func grid(rows: Array, at: Vector2i, keys: Dictionary) -> void:
	for y: int in rows.size():
		var row: String = rows[y]
		for x: int in row.length():
			var key: String = row[x]
			if key != "." and keys.has(key):
				_put(at.x + x, at.y + y, keys[key])


## Darkens (amount > 0) or lightens (< 0) the pixels already drawn inside a circle, e.g. scorch marks.
func tint_circle(center: Vector2, radius: float, color: Color, amount: float) -> void:
	for y: int in range(floori(center.y - radius), ceili(center.y + radius) + 1):
		for x: int in range(floori(center.x - radius), ceili(center.x + radius) + 1):
			if Vector2(x + 0.5, y + 0.5).distance_to(center) > radius or not _inside(x, y):
				continue
			var c: Color = image.get_pixel(x, y)
			if c.a > 0.0:
				image.set_pixel(x, y, Color(c.lerp(color, amount), c.a))


## Removes pixels (holes, breaches, missing merlons).
func erase(x: int, y: int) -> void:
	if _inside(x, y):
		image.set_pixel(x, y, Color(0, 0, 0, 0))
		_owner[y * size.x + x] = 0


func get_color(x: int, y: int) -> Color:
	return image.get_pixel(x, y) if _inside(x, y) else Color(0, 0, 0, 0)


func is_filled(x: int, y: int) -> bool:
	return _inside(x, y) and image.get_pixel(x, y).a > 0.0


# ---------------------------------------------------------------- finishing

## Contours, then the outer outline. Call once, after everything is drawn.
func finish(contours: bool = true, outline_color: Color = OUTLINE) -> Image:
	if contours:
		_draw_contours()
	_draw_outline(outline_color)
	return image


## A soft oval ground shadow, only where nothing is drawn yet (call after finish()).
func ground_shadow(center: Vector2, radius: Vector2, color: Color = SHADOW) -> void:
	for y: int in range(floori(center.y - radius.y), ceili(center.y + radius.y) + 1):
		for x: int in range(floori(center.x - radius.x), ceili(center.x + radius.x) + 1):
			var d: Vector2 = (Vector2(x + 0.5, y + 0.5) - center) / radius
			if d.length_squared() <= 1.0 and _inside(x, y) and image.get_pixel(x, y).a == 0.0:
				image.set_pixel(x, y, color)


func _draw_contours() -> void:
	var src: Image = image.duplicate() as Image
	for y: int in size.y:
		for x: int in size.x:
			var own: int = _owner[y * size.x + x]
			if own == 0 or _soft_parts.has(own):
				continue
			for d: Vector2i in DIRS_4:
				var q: Vector2i = Vector2i(x, y) + d
				if not _inside(q.x, q.y):
					continue
				var other: int = _owner[q.y * size.x + q.x]
				# The back part gets the line where a later (front) part covers it.
				if other > own and not _soft_parts.has(other):
					image.set_pixel(x, y, _contour_of(src.get_pixel(x, y)))
					break


## A contour is the pixel's own colour pushed toward the outline colour (keeps the hue, like
## hand-drawn "selective outlines").
func _contour_of(c: Color) -> Color:
	return Color(c.lerp(OUTLINE, 0.62), c.a)


func _draw_outline(outline_color: Color) -> void:
	var src: Image = image.duplicate() as Image
	for y: int in size.y:
		for x: int in size.x:
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in DIRS_4:
				var q: Vector2i = Vector2i(x, y) + d
				if _inside(q.x, q.y) and src.get_pixelv(q).a > 0.5 and not _soft_parts.has(_owner[q.y * size.x + q.x]):
					image.set_pixel(x, y, outline_color)
					break


func _put(x: int, y: int, color: Color) -> void:
	if not _inside(x, y):
		return
	if color.a < 1.0:
		var under: Color = image.get_pixel(x, y)
		if under.a > 0.0:
			color = Color(under.lerp(color, color.a), maxf(under.a, color.a))
	image.set_pixel(x, y, color)
	_owner[y * size.x + x] = _part


func _inside(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < size.x and y < size.y
