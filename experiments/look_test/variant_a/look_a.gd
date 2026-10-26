extends Node
## Variant A, "fake HD-2D" in the current 2D setup (look-test, Compatibility renderer): a post pass with
## tilt-shift blur, bloom and drifting fog; glow halos and soft shadows on the level's lights (props, towers
## and units get small occluders); a moonlit directional light and generated normal maps for the knight,
## the Ghoul and the archer tower; light motes drifting over the view. Nothing in the game's code changes:
## this node only reads the running level and adds nodes.

const POST_SHADER: Shader = preload("res://experiments/look_test/variant_a/post_fx.gdshader")
const NormalMaps: GDScript = preload("res://experiments/look_test/variant_a/normal_maps.gd")
## Which sprites get normal maps: hero ids, enemy ids, tower ids.
const NORMAL_HEROES: Array[StringName] = [&"knight"]
const NORMAL_ENEMIES: Array[StringName] = [&"ghoul"]
const NORMAL_TOWERS: Array[StringName] = [&"archer"]
const LIGHT_BOOST: float = 1.5
const HALO_SIZE: int = 96
## Light layer of the sprites with normal maps: the directional moon lights only these. On the tiled ground it
## showed the tiles as bright squares (the Compatibility renderer lights each tile item on its own).
const SUN_LAYER: int = 2

## Debug: LOOK_A_OFF=sun,shadows,halo,post,motes,normals switches parts off for comparison shots.
var _off: PackedStringArray = OS.get_environment("LOOK_A_OFF").split(",")
var _level: Level
var _camera: Camera2D
var _post: ColorRect
var _normals: RefCounted = NormalMaps.new()
var _tracked: Array[AnimatedSprite2D] = []
var _lights: Array[PointLight2D] = []
var _base_energy: Dictionary = {}
var _halo_texture: Texture2D
var _time: float = 0.0


func attach(level: Level) -> void:
	_level = level
	_camera = level.get_node("Hero/Camera2D")
	_halo_texture = _radial(HALO_SIZE)
	if not _off.has("post"):
		_add_post_layer()
	if not _off.has("sun"):
		_add_sun()
	if not _off.has("motes"):
		_add_motes()
	for node: Node in level.find_children("*", "", true, false):
		_inspect(node)
	get_tree().node_added.connect(func(node: Node) -> void: _inspect.call_deferred(node))


func _process(delta: float) -> void:
	_time += delta
	if _post == null or not is_instance_valid(_camera):
		return
	var material: ShaderMaterial = _post.material as ShaderMaterial
	material.set_shader_parameter("camera_pos", _camera.get_screen_center_position())
	material.set_shader_parameter("view_size", get_viewport().get_visible_rect().size)
	for light: PointLight2D in _lights:
		if is_instance_valid(light):
			var flicker: float = 1.0 + 0.08 * sin(_time * 7.0 + light.get_instance_id() * 0.37) + 0.05 * sin(_time * 13.0 + light.get_instance_id())
			light.energy = _base_energy[light] * flicker
	if Engine.get_process_frames() % 30 == 0:
		for sprite: AnimatedSprite2D in _tracked:
			if is_instance_valid(sprite) and sprite.sprite_frames != _normals.call("convert", sprite.sprite_frames):
				sprite.sprite_frames = _normals.call("convert", sprite.sprite_frames)


func _inspect(node: Node) -> void:
	if not is_instance_valid(node) or node.has_meta(&"look_a"):
		return
	if node is PointLight2D:
		node.set_meta(&"look_a", true)
		_light_up(node as PointLight2D)
	elif node is Hero and NORMAL_HEROES.has((node as Hero).data.id):
		node.set_meta(&"look_a", true)
		_track(node.get_node("Sprite") as AnimatedSprite2D)
		_occlude(node as Node2D, Vector2(9, 4), Vector2(0, 6))
	elif node is Hero:
		node.set_meta(&"look_a", true)
		_occlude(node as Node2D, Vector2(9, 4), Vector2(0, 6))
	elif node is Enemy:
		node.set_meta(&"look_a", true)
		if NORMAL_ENEMIES.has(StringName((node as Enemy).data.resource_path.get_file().get_basename())):
			_track(node.get_node("Sprite") as AnimatedSprite2D)
		_occlude(node as Node2D, Vector2(8, 3.5), Vector2(0, 6))
	elif node is Tower:
		node.set_meta(&"look_a", true)
		if NORMAL_TOWERS.has((node as Tower).data.id):
			_track(node.get_node("Sprite") as AnimatedSprite2D)
		_occlude(node as Node2D, Vector2(14, 6), Vector2(0, 8))
	elif node is Sprite2D and node.get_parent() != null and node.get_parent().get_parent() != null and node.get_parent().get_parent().name == "Props":
		node.set_meta(&"look_a", true)
		var sprite: Sprite2D = node as Sprite2D
		var size: Vector2 = sprite.texture.get_size() if sprite.texture != null else Vector2(24, 24)
		_occlude(node.get_parent() as Node2D, Vector2(size.x * 0.35, minf(size.y * 0.2, 7.0)), sprite.position + Vector2(0, size.y * 0.3))


func _track(sprite: AnimatedSprite2D) -> void:
	if _off.has("normals") or sprite == null or sprite.sprite_frames == null:
		return
	sprite.sprite_frames = _normals.call("convert", sprite.sprite_frames)
	sprite.light_mask = SUN_LAYER | 1  # the moon lights these sprites only (see _add_sun)
	_tracked.append(sprite)


## The level's lamps cast soft shadows, glow, and flicker.
func _light_up(light: PointLight2D) -> void:
	_base_energy[light] = light.energy * LIGHT_BOOST
	light.energy = _base_energy[light]
	light.shadow_enabled = not _off.has("shadows")
	light.shadow_filter = Light2D.SHADOW_FILTER_PCF13
	light.shadow_filter_smooth = 3.0
	light.shadow_color = Color(0.0, 0.0, 0.02, 0.6)
	_lights.append(light)
	if _off.has("halo"):
		return
	var halo: Sprite2D = Sprite2D.new()
	halo.texture = _halo_texture
	halo.light_mask = 0
	halo.z_index = 6
	halo.scale = Vector2.ONE * clampf(light.texture_scale * 0.7, 0.8, 3.0)
	halo.modulate = Color(light.color, 0.55)
	var add: CanvasItemMaterial = CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	halo.material = add
	light.add_child(halo)


func _occlude(parent: Node2D, radius: Vector2, offset: Vector2) -> void:
	var polygon: PackedVector2Array = PackedVector2Array()
	for i: int in 10:
		polygon.append(Vector2.from_angle(TAU * i / 10.0) * radius)
	var shape: OccluderPolygon2D = OccluderPolygon2D.new()
	shape.polygon = polygon
	var occluder: LightOccluder2D = LightOccluder2D.new()
	occluder.occluder = shape
	occluder.position = offset
	parent.add_child(occluder)


func _add_post_layer() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 1
	_post = ColorRect.new()
	_post.set_anchors_preset(Control.PRESET_FULL_RECT)
	_post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = POST_SHADER
	_post.material = material
	layer.add_child(_post)
	add_child(layer)


## A cool moon from the top left: what the normal maps are shaded by. A big PointLight2D riding with the camera,
## because in the Compatibility renderer a DirectionalLight2D ignores the item cull mask and lit the whole
## ground (and showed its tiles as bright squares); a point light respects it, so only the sprites on SUN_LAYER get it.
func _add_sun() -> void:
	var moon: PointLight2D = PointLight2D.new()
	moon.set_meta(&"look_a", true)
	moon.texture = _radial(256)
	moon.texture_scale = 9.0
	moon.color = Color(0.62, 0.72, 1.0)
	moon.energy = 0.9
	moon.height = 150.0
	moon.range_item_cull_mask = SUN_LAYER
	moon.position = Vector2(-320, -280)
	_camera.add_child(moon)


func _add_motes() -> void:
	var motes: CPUParticles2D = CPUParticles2D.new()
	motes.amount = 80
	motes.lifetime = 8.0
	motes.preprocess = 8.0
	motes.local_coords = false
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(700, 400)
	motes.direction = Vector2(0.3, -1.0)
	motes.spread = 90.0
	motes.gravity = Vector2.ZERO
	motes.initial_velocity_min = 4.0
	motes.initial_velocity_max = 14.0
	motes.scale_amount_min = 0.5
	motes.scale_amount_max = 1.1
	motes.texture = _radial(12)
	var ramp: Gradient = Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	ramp.colors = PackedColorArray([Color(1, 0.9, 0.55, 0), Color(1, 0.92, 0.6, 0.9), Color(0.8, 1, 0.7, 0.7), Color(0.8, 1, 0.7, 0)])
	motes.color_ramp = ramp
	var add: CanvasItemMaterial = CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	motes.material = add
	motes.light_mask = 0
	motes.z_index = 20
	_camera.add_child(motes)


## A soft round dot / halo: white in the middle fading to nothing.
func _radial(size: int) -> Texture2D:
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = size
	texture.height = size
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture
