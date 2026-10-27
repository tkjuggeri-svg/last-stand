class_name VectorStyle
## The vector look test (branch vector-test, never merge): shared drawing helpers in the style of
## docs/reference/web_td/ (draw.ts, fx.ts): smooth shapes with gradients lit from the top-left, soft drop
## shadows, thin dark strokes, and additive glow sprites (a cached radial gradient, like fx.ts glowSprite).
## Display only; every vector node reads the state of the real (hidden) sprite it replaces.

## The theme (ART_DIRECTION: warm defenders, cold dead).
const INK: Color = Color("1a141f")
const STEEL_LIGHT: Color = Color("dfe3e6")
const STEEL: Color = Color("9aa3ab")
const STEEL_DARK: Color = Color("4e5560")
const TABARD: Color = Color("b3302c")
const TABARD_DARK: Color = Color("6e1a1d")
const GOLD: Color = Color("f2c25a")
const GOLD_DARK: Color = Color("8a5a1c")
const WOOD: Color = Color("8a5a34")
const WOOD_DARK: Color = Color("4a2e1c")
const WARM_GLOW: Color = Color("ffb84d")
const SKIN_DEAD: Color = Color("cfe2dc")
const SKIN_DEAD_DARK: Color = Color("6f8f89")
## The rags stay lighter than the ground (characters brighter than the ground, test_readability's rule).
const RAG: Color = Color("8592a6")
const RAG_DARK: Color = Color("404a5c")
const EYE_RED: Color = Color("ff3b30")
const COLD_GLOW: Color = Color("7fd8ff")
const SHADOW: Color = Color(0, 0, 0, 0.32)
## The direction light comes from (top-left), for gradients.
const LIGHT_DIR: Vector2 = Vector2(-0.6, -0.8)

static var _glows: Dictionary = {}
static var _add_material: CanvasItemMaterial


## A radial glow: white core, the colour, fading out (fx.ts glowSprite), 64 px, cached per colour.
static func glow_texture(color: Color) -> Texture2D:
	var key: String = color.to_html()
	if _glows.has(key):
		return _glows[key]
	var faded: Color = color
	faded.a = 0.4
	var clear: Color = color
	clear.a = 0.0
	var texture: Texture2D = radial_texture(make_gradient([0.0, 0.14, 0.45, 1.0], [Color.WHITE, color, faded, clear]), 64, Vector2(0.5, 0.5), 0.5)
	_glows[key] = texture
	return texture


## A radial gradient baked into an ImageTexture (`center` and `radius` as shares of the size). Keep a reference
## while it is drawn: draw commands don't hold the texture alive.
static func radial_texture(gradient: Gradient, size: int, center: Vector2, radius: float) -> Texture2D:
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y: int in size:
		for x: int in size:
			var at: Vector2 = (Vector2(x, y) + Vector2(0.5, 0.5)) / size
			image.set_pixel(x, y, gradient.sample(clampf(at.distance_to(center) / radius, 0.0, 1.0)))
	return ImageTexture.create_from_image(image)


## A gradient from stops, point by point (offsets in order).
static func make_gradient(offsets: Array[float], colors: Array[Color]) -> Gradient:
	var gradient: Gradient = Gradient.new()
	gradient.set_offset(0, offsets[0])
	gradient.set_color(0, colors[0])
	gradient.set_offset(1, offsets[offsets.size() - 1])
	gradient.set_color(1, colors[colors.size() - 1])
	for i: int in range(1, offsets.size() - 1):
		gradient.add_point(offsets[i], colors[i])
	return gradient


## The additive blend glows are drawn with (a child canvas item carries it, see make_glow_layer).
static func add_material() -> CanvasItemMaterial:
	if _add_material == null:
		_add_material = CanvasItemMaterial.new()
		_add_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_add_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return _add_material


## A child Node2D drawn additively on top of `owner_node`, calling `painter` (a Callable taking the layer).
static func make_glow_layer(owner_node: Node2D, painter: Callable) -> Node2D:
	var layer: Node2D = Node2D.new()
	layer.name = "Glow"
	layer.material = add_material()
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	layer.draw.connect(func() -> void: painter.call(layer))
	owner_node.add_child(layer)
	return layer


static func draw_glow(ci: CanvasItem, color: Color, at: Vector2, radius: float, alpha: float = 1.0) -> void:
	ci.draw_texture_rect(glow_texture(color), Rect2(at - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, Color(1, 1, 1, alpha))


static func ellipse(center: Vector2, rx: float, ry: float, points: int = 28) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	for i: int in points:
		var a: float = TAU * i / points
		out.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return out


static func regular(center: Vector2, sides: int, rx: float, ry: float, rotation: float = 0.0) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	for i: int in sides:
		var a: float = rotation + TAU * i / sides
		out.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return out


## A filled shape shaded from `light` (the top-left) to `dark`, with a thin antialiased stroke (draw.ts style).
static func shape(ci: CanvasItem, points: PackedVector2Array, light: Color, dark: Color, stroke: Color = INK, stroke_width: float = 1.4) -> void:
	if points.size() < 3:
		return
	var lo: float = INF
	var hi: float = -INF
	for p: Vector2 in points:
		var d: float = p.dot(-LIGHT_DIR)
		lo = minf(lo, d)
		hi = maxf(hi, d)
	var colors: PackedColorArray = PackedColorArray()
	for p: Vector2 in points:
		colors.append(light.lerp(dark, (p.dot(-LIGHT_DIR) - lo) / maxf(hi - lo, 0.001)))
	ci.draw_polygon(points, colors)
	if stroke.a > 0.0:
		var closed: PackedVector2Array = points.duplicate()
		closed.append(points[0])
		ci.draw_polyline(closed, stroke, stroke_width, true)


## A soft oval ground shadow (two layers, so it fades at the edge).
static func shadow(ci: CanvasItem, at: Vector2, rx: float, ry: float) -> void:
	ci.draw_colored_polygon(ellipse(at, rx * 1.15, ry * 1.15), Color(0, 0, 0, SHADOW.a * 0.45))
	ci.draw_colored_polygon(ellipse(at, rx, ry), SHADOW)


## A small highlight blob (a soft white oval, like draw.ts's specular dabs).
static func shine(ci: CanvasItem, at: Vector2, rx: float, ry: float, alpha: float = 0.35) -> void:
	ci.draw_colored_polygon(ellipse(at, rx, ry, 16), Color(1, 1, 1, alpha))


## draw.ts easeOutBack: things pop in slightly past full size.
static func ease_out_back(t: float) -> float:
	var c1: float = 1.70158
	var c3: float = c1 + 1.0
	return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0)


## The state and facing a DirectionalSprite shows ("walk", "side"), and how far into the animation it is.
static func sprite_state(sprite: AnimatedSprite2D) -> Dictionary:
	var anim: String = String(sprite.animation)
	var cut: int = anim.rfind("_")
	var state: String = anim.substr(0, cut) if cut > 0 else anim
	var facing: String = anim.substr(cut + 1) if cut > 0 else "down"
	var frames: int = sprite.sprite_frames.get_frame_count(sprite.animation) if sprite.sprite_frames != null else 1
	var progress: float = (sprite.frame + sprite.frame_progress) / maxf(frames, 1.0)
	return {"state": state, "facing": facing, "flip": sprite.flip_h, "progress": progress, "playing": sprite.is_playing()}
