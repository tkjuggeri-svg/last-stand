extends "res://experiments/look_test/variant_a/look_a.gd"
## Variant C, variant A's lighting with a fake depth, all in 2D (look-test; no 3D stage, no gameplay change):
## sprites draw smaller toward the top of the map (visual scale only: bodies, collisions and the mouse are
## untouched), a distance haze by world height, a tilt-shift that is
## stronger at the bottom, a parallax backdrop beyond the top wall, and a gentler bloom. The post pass lives in the
## world canvas between the sprites and the damage numbers / health bars, which therefore stay sharp.

const POST_C: Shader = preload("res://experiments/look_test/variant_c/post_c.gdshader")
const DepthArt: GDScript = preload("res://experiments/look_test/variant_c/depth_art.gd")
const DEPTH_TOP: float = 0.87
const POST_Z: int = 150
const BARS_Z: int = 199
const LABELS_Z: int = 200
## How far above the top wall the camera may look (px), where the backdrop shows.
const BACKDROP_HEIGHT: float = 170.0
const POST_MARGIN: float = 24.0
## Backdrop layers: kind, colour, art height, how much of the camera's movement it follows (0: still, 1: the world).
const LAYERS: Array = [
	["hills", Color(0.2, 0.27, 0.4), 96, 0.18],
	["ruins", Color(0.12, 0.16, 0.26), 88, 0.38],
	["trees", Color(0.07, 0.09, 0.15), 50, 0.62],
]

var _floor_top: float = -500.0
var _floor_bottom: float = 400.0
var _wall_top: float = -532.0
var _depth_sprites: Array[Dictionary] = []
var _backdrop_layers: Array[Dictionary] = []


func attach(level: Level) -> void:
	light_boost = 1.3
	halo_alpha = 0.3
	halo_scale = 0.6
	var floor_rect: Control = level.get_node("%Floor")
	_floor_top = floor_rect.global_position.y
	_floor_bottom = floor_rect.global_position.y + floor_rect.size.y
	_wall_top = (level.get_node("%Ground") as TiledGround).global_position.y
	super.attach(level)
	_camera.limit_top = int(_wall_top - BACKDROP_HEIGHT)
	_build_backdrop()


func _process(delta: float) -> void:
	super._process(delta)
	if _level == null or not is_instance_valid(_camera):
		return
	var center: Vector2 = _camera.get_screen_center_position()
	var view: Vector2 = get_viewport().get_visible_rect().size
	_post.size = view + Vector2.ONE * POST_MARGIN * 2.0
	_post.global_position = center - _post.size * 0.5
	_update_depth_sprites()
	for layer: Dictionary in _backdrop_layers:
		var sprite: Sprite2D = layer["sprite"]
		var width: float = view.x + 64.0
		sprite.region_rect = Rect2(center.x * float(layer["follow"]) / 2.0 - width * 0.25, 0, width / 2.0, sprite.texture.get_height())
		sprite.global_position = Vector2(center.x - width * 0.5, _wall_top + 6.0 - sprite.texture.get_height() * 2.0)


func _inspect(node: Node) -> void:
	super(node)
	if not is_instance_valid(node) or node.has_meta(&"look_c"):
		return
	if node is EnemyHealthBar:
		node.set_meta(&"look_c", true)
		_raise(node as CanvasItem, BARS_Z)
	elif node is Label and (node as Label).get_canvas_layer_node() == null:
		node.set_meta(&"look_c", true)
		_raise(node as CanvasItem, LABELS_Z)
	elif node is AnimatedSprite2D and node.name == &"Sprite" and (node.get_parent() is Enemy or node.get_parent() is Hero or node.get_parent() is Tower):
		node.set_meta(&"look_c", true)
		_depth_sprites.append(_depth_entry(node as Node2D))
	elif node is Sprite2D and node.get_parent() != null and node.get_parent().get_parent() != null and node.get_parent().get_parent().name == "Props":
		node.set_meta(&"look_c", true)
		_depth_sprites.append(_depth_entry(node as Node2D))


## The post pass is a rectangle in the world canvas (z between the sprites and the numbers), moved over the view each frame.
func _add_post_layer() -> void:
	_post = ColorRect.new()
	if _off.has("post"):
		_post.visible = false
	_post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_post.light_mask = 0
	_post.z_as_relative = false
	_post.z_index = POST_Z
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = POST_C
	material.set_shader_parameter("haze_top_y", _floor_top)
	material.set_shader_parameter("haze_bottom_y", _floor_bottom)
	_post.material = material
	_level.add_child(_post)


func _raise(item: CanvasItem, z: int) -> void:
	item.z_as_relative = false
	item.z_index = z


# ----------------------------------------------------------------------------- depth scale

func _depth_entry(sprite: Node2D) -> Dictionary:
	return {"sprite": sprite, "base_position": sprite.position, "base_scale": sprite.scale,
		"applied_position": sprite.position, "applied_scale": sprite.scale}


## 0.87 at the top of the floor to 1 at the bottom, by the entity's own position.
func depth_factor(world_y: float) -> float:
	return lerpf(DEPTH_TOP, 1.0, clampf((world_y - _floor_top) / maxf(_floor_bottom - _floor_top, 1.0), 0.0, 1.0))


func _update_depth_sprites() -> void:
	for entry: Dictionary in _depth_sprites:
		var sprite: Node2D = entry["sprite"] as Node2D if is_instance_valid(entry["sprite"]) else null
		if sprite == null:
			continue
		# Something else moved or scaled it since last frame (the game's own animation): that is the new base.
		if sprite.position != entry["applied_position"]:
			entry["base_position"] = sprite.position
		if sprite.scale != entry["applied_scale"]:
			entry["base_scale"] = sprite.scale
		var base_scale: Vector2 = entry["base_scale"]
		var factor: float = depth_factor(sprite.get_parent().global_position.y)
		var feet: float = _feet_below_origin(sprite)
		sprite.scale = base_scale * factor
		sprite.position = (entry["base_position"] as Vector2) + Vector2(0.0, feet * base_scale.y * (1.0 - factor))
		entry["applied_scale"] = sprite.scale
		entry["applied_position"] = sprite.position


## How far below the sprite's origin its bottom edge is, in its own unscaled pixels (so scaling keeps the feet put).
func _feet_below_origin(sprite: Node2D) -> float:
	var size: Vector2 = Vector2.ZERO
	var offset: Vector2 = Vector2.ZERO
	var centered: bool = true
	if sprite is AnimatedSprite2D:
		var animated: AnimatedSprite2D = sprite as AnimatedSprite2D
		if animated.sprite_frames != null and animated.sprite_frames.has_animation(animated.animation) and animated.sprite_frames.get_frame_count(animated.animation) > 0:
			var texture: Texture2D = animated.sprite_frames.get_frame_texture(animated.animation, animated.frame)
			size = texture.get_size() if texture != null else Vector2.ZERO
		offset = animated.offset
		centered = animated.centered
	else:
		var plain: Sprite2D = sprite as Sprite2D
		if plain.texture != null:
			size = plain.region_rect.size if plain.region_enabled else plain.texture.get_size()
			size = Vector2(size.x / maxi(plain.hframes, 1), size.y / maxi(plain.vframes, 1))
		offset = plain.offset
		centered = plain.centered
	return offset.y + (size.y * 0.5 if centered else size.y)


# ----------------------------------------------------------------------------- backdrop and foreground

func _build_backdrop() -> void:
	var holder: Node2D = Node2D.new()
	holder.name = "Backdrop"
	holder.z_index = -3  # the level's own dark Backdrop rectangle is at -3: this comes after it (tree order, larger y)
	_level.add_child(holder)
	_build_sky(holder)
	for spec: Array in LAYERS:
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = DepthArt.strip(spec[0], spec[1], spec[2])
		sprite.centered = false
		sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		sprite.region_enabled = true
		sprite.scale = Vector2(2, 2)
		holder.add_child(sprite)
		_backdrop_layers.append({"sprite": sprite, "follow": spec[3]})


const SKY_BANDS: Array[Color] = [Color("0a0d1c"), Color("0d1226"), Color("121a33"), Color("19243f"), Color("22304c"),
	Color("2d3d59"), Color("3a4a64"), Color("495a72")]
const SKY_HEIGHT: float = 420.0
const SKY_HALF_WIDTH: float = 3200.0


## The sky beyond the top wall: banded dusk colours, stars and a moon, as plain rectangles in whole pixels.
func _build_sky(holder: Node2D) -> void:
	var band: float = SKY_HEIGHT / SKY_BANDS.size()
	for i: int in SKY_BANDS.size():
		_rect(holder, Rect2(-SKY_HALF_WIDTH, _wall_top - SKY_HEIGHT + i * band, SKY_HALF_WIDTH * 2.0, band + 1.0), SKY_BANDS[i])
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 77
	for _i: int in 90:
		var at: Vector2 = Vector2(rng.randf_range(-SKY_HALF_WIDTH, SKY_HALF_WIDTH), _wall_top - rng.randf_range(160.0, SKY_HEIGHT))
		_rect(holder, Rect2(at.round(), Vector2(2, 2)), Color(0.8, 0.85, 1.0, rng.randf_range(0.25, 0.8)))
	var moon: Vector2 = Vector2(-60.0, _wall_top - 190.0)
	for ring: Array in [[46.0, Color(0.7, 0.78, 1.0, 0.07)], [30.0, Color(0.75, 0.82, 1.0, 0.12)], [20.0, Color(0.88, 0.9, 0.97, 1.0)]]:
		_rect(holder, Rect2(moon - Vector2.ONE * ring[0], Vector2.ONE * ring[0] * 2.0), ring[1])


func _rect(parent: Node, area: Rect2, color: Color) -> void:
	var rect: ColorRect = ColorRect.new()
	rect.position = area.position
	rect.size = area.size
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
