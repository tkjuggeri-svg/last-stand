extends Node
## Variant B, a tilted perspective camera over the unchanged 2D game (look-test). The level keeps running in
## 2D (physics, AI, towers, the HUD) but its world is hidden from the 2D view (its items move to canvas layer
## 2 and the viewport's cull mask leaves that out); a 3D stage shows it instead: the baked ground as a
## textured plane, a perspective camera that follows the 2D camera, every sprite as an upright camera-facing
## quad standing at its 2D position (SpriteMirror), the 2D lamps as omni lights, a moon with shadows,
## fog, glow and depth of field. The mouse is projected from the camera back onto the 2D plane
## (WorldPointer.provider), so aiming and building keep working. The HUD stays 2D, on top.
## Renderer: Compatibility has 3D, shadows, fog and glow but no built-in depth of field, SSAO or volumetric
## fog; those switch on automatically under Forward+ (godot --rendering-method forward_plus).

const POST_SHADER: Shader = preload("res://experiments/look_test/variant_a/post_fx.gdshader")
const UNIT: float = SpriteMirror.UNIT
const WORLD_LAYER: int = 2
## The night tint is multiplied by this, since the 3D lights add up to less than the 2D unlit look.
const TINT_GAIN: float = 1.35

var elevation: float = float(OS.get_environment("LOOK_B_ELEV")) if OS.get_environment("LOOK_B_ELEV") != "" else 42.0
var distance: float = float(OS.get_environment("LOOK_B_DIST")) if OS.get_environment("LOOK_B_DIST") != "" else 36.0
var fov: float = 30.0
var forward_plus: bool = false

var _world: Node3D
var _camera: Camera3D
var _mirror: SpriteMirror
var _level: Level
var _cam2d: Camera2D
var _post: ColorRect
var _modulate: Color = Color.WHITE
var _environment: Environment
## Debug switches for the cost breakdown: LOOK_B_OFF=moon_shadows,omni_shadows,omni,glow,post
var _off: PackedStringArray = OS.get_environment("LOOK_B_OFF").split(",")
var _sync_usec: int = 0
var _sync_frames: int = 0


func _ready() -> void:
	forward_plus = RenderingServer.get_current_rendering_method() != "gl_compatibility"
	_world = Node3D.new()
	_world.name = "Stage3D"
	add_child(_world)
	_mirror = SpriteMirror.new(_world)
	_mirror.elevation = elevation
	get_viewport().canvas_cull_mask = 0xFFFFFFFF & ~WORLD_LAYER
	_build_environment()
	_build_camera()
	_build_moon()
	_build_post()


func attach(level: Level) -> void:
	_level = level
	_cam2d = level.get_node("Hero/Camera2D")
	var modulate_node: CanvasModulate = level.get_node_or_null("CanvasModulate") as CanvasModulate
	_modulate = modulate_node.color if modulate_node != null else Color.WHITE
	_mirror.world_tint = _modulate * TINT_GAIN
	_mirror.light_gain = 2.2 if forward_plus else 1.0
	_mirror.omni_shadows = not _off.has("omni_shadows")
	_mirror.omni_lights = not _off.has("omni")
	_build_ground(level.get_node("%Ground") as TiledGround)
	for node: Node in level.find_children("*", "", true, false):
		_adopt(node, false)
	get_tree().node_added.connect(func(node: Node) -> void: _adopt(node, true))
	WorldPointer.provider = _mouse_on_ground
	print("variant B: %d mirrored nodes, renderer %s" % [_mirror.count(), RenderingServer.get_current_rendering_method()])


func _exit_tree() -> void:
	WorldPointer.provider = Callable()
	if _sync_frames > 0:
		print("variant B: mirror sync %.2f ms a frame on average, %d mirrored nodes at the end" % [_sync_usec / 1000.0 / _sync_frames, _mirror.count()])


func _process(_delta: float) -> void:
	if _level == null:
		return
	var started: int = Time.get_ticks_usec()
	_mirror.update()
	_sync_usec += Time.get_ticks_usec() - started
	_sync_frames += 1
	var target: Vector2 = _cam2d.get_screen_center_position() / UNIT
	var focus: Vector3 = Vector3(target.x, 0.0, target.y)
	var e: float = deg_to_rad(elevation)
	_camera.global_position = focus + Vector3(0.0, distance * sin(e), distance * cos(e))
	_camera.look_at(focus, Vector3.UP)
	if _post != null:
		(_post.material as ShaderMaterial).set_shader_parameter("view_size", get_viewport().get_visible_rect().size)


## The 2D world position under the mouse: the camera's ray meets the ground plane.
func _mouse_on_ground() -> Vector2:
	return ground_at(get_viewport().get_mouse_position())


func ground_at(screen: Vector2) -> Vector2:
	var from: Vector3 = _camera.project_ray_origin(screen)
	var direction: Vector3 = _camera.project_ray_normal(screen)
	if absf(direction.y) < 0.0001:
		return Vector2.ZERO
	var hit: Vector3 = from + direction * (-from.y / direction.y)
	return Vector2(hit.x, hit.z) * UNIT


func screen_of(world_2d: Vector2) -> Vector2:
	return _camera.unproject_position(Vector3(world_2d.x / UNIT, 0.0, world_2d.y / UNIT))


## World items leave the 2D view; the 3D stage gets their counterpart.
func _adopt(node: Node, deferred: bool) -> void:
	if node is CanvasItem and (node as CanvasItem).get_canvas_layer_node() == null:
		(node as CanvasItem).visibility_layer = WORLD_LAYER
	if deferred:
		_mirror_later.call_deferred(node)
	else:
		_mirror.add(node)


func _mirror_later(node: Node) -> void:
	if is_instance_valid(node) and node.is_inside_tree():
		_mirror.add(node)


func _build_ground(ground: TiledGround) -> void:
	var size: Vector2 = ground.texture.get_size()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = size / UNIT
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_texture = ground.texture
	material.albedo_color = _modulate * TINT_GAIN
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.roughness = 1.0
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.mesh = plane
	mesh.material_override = material
	mesh.position = Vector3((ground.position.x + size.x * 0.5) / UNIT, 0.0, (ground.position.y + size.y * 0.5) / UNIT)
	_world.add_child(mesh)


func _build_environment() -> void:
	_environment = Environment.new()
	_environment.background_mode = Environment.BG_COLOR
	_environment.background_color = Color(0.02, 0.02, 0.04)
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.ambient_light_color = Color(0.55, 0.58, 0.65)
	_environment.ambient_light_energy = 0.5
	_environment.glow_enabled = not _off.has("glow")
	_environment.glow_intensity = 0.9
	_environment.glow_bloom = 0.15
	_environment.glow_hdr_threshold = 0.85
	_environment.fog_enabled = true
	_environment.fog_light_color = Color(0.08, 0.1, 0.16)
	_environment.fog_density = 0.008
	var attributes: CameraAttributesPractical = CameraAttributesPractical.new()
	if forward_plus:
		_environment.ssao_enabled = true
		_environment.ssao_radius = 1.0
		_environment.ssao_intensity = 1.0
		_environment.volumetric_fog_enabled = true
		_environment.volumetric_fog_density = 0.004
		_environment.volumetric_fog_albedo = Color(0.45, 0.55, 0.75)
		attributes.dof_blur_far_enabled = true
		attributes.dof_blur_far_distance = distance * 1.15
		attributes.dof_blur_far_transition = distance * 0.35
		attributes.dof_blur_near_enabled = true
		attributes.dof_blur_near_distance = distance * 0.82
		attributes.dof_blur_near_transition = distance * 0.3
		attributes.dof_blur_amount = 0.12
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.environment = _environment
	world_environment.camera_attributes = attributes
	_world.add_child(world_environment)


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.fov = fov
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.near = 1.0
	_camera.far = 200.0
	_camera.current = true
	_world.add_child(_camera)


## A cool moon from the top left with shadows (the billboards cast cut-out shadows onto the ground).
func _build_moon() -> void:
	var moon: DirectionalLight3D = DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-48, -135, 0)
	moon.light_color = Color(0.9, 0.93, 1.0)
	moon.light_energy = 0.6
	moon.shadow_enabled = not _off.has("moon_shadows")
	moon.shadow_blur = 1.6
	moon.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL  # one split: the view is a small, even patch of ground
	moon.directional_shadow_max_distance = 48.0
	moon.shadow_bias = 0.04
	_world.add_child(moon)


## Tilt-shift and bloom for the Compatibility renderer, which has no built-in depth of field (and whose glow is
## weaker); under Forward+ the camera's own depth of field and glow do this.
func _build_post() -> void:
	if forward_plus or _off.has("post"):
		return
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 1
	_post = ColorRect.new()
	_post.set_anchors_preset(Control.PRESET_FULL_RECT)
	_post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = POST_SHADER
	material.set_shader_parameter("fog_strength", 0.0)
	material.set_shader_parameter("blur_max", 4.5)
	material.set_shader_parameter("focus_band", 0.2)
	material.set_shader_parameter("bloom_strength", 0.35)
	_post.material = material
	layer.add_child(_post)
	add_child(layer)
