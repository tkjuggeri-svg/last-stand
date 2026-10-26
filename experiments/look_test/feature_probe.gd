extends SceneTree
## Which rendering features really change the picture in the running renderer (look-test): each is toggled on a
## small 3D (or 2D) scene and the viewport image is compared with and without it; a difference above a threshold
## means it works. godot --path . --resolution 960x540 --script res://experiments/look_test/feature_probe.gd -- --tag=compat
## (add --rendering-method forward_plus --rendering-driver vulkan before --script to probe Forward+).

## A feature counts as working when it changes the picture by more than this many times the noise between two
## identical frames (and by at least FLOOR).
const NOISE_FACTOR: float = 4.0
const FLOOR: float = 0.0002

var _tag: String = "compat"
var _lines: PackedStringArray = PackedStringArray()
var _env: Environment
var _attrs: CameraAttributesPractical
var _sun: DirectionalLight3D
var _omni: OmniLight3D


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=")
	_run.call_deferred()


func _run() -> void:
	_lines.append("renderer: %s on %s" % [RenderingServer.get_current_rendering_method(), RenderingServer.get_video_adapter_name()])
	_build_3d()
	await _frames(8)
	await _probe("3D glow (HDR emissive)", func(on: bool) -> void: _env.glow_enabled = on)
	await _probe("3D depth fog", func(on: bool) -> void: _env.fog_enabled = on)
	await _probe("volumetric fog", func(on: bool) -> void: _env.volumetric_fog_enabled = on, 6)
	await _probe("SSAO", func(on: bool) -> void: _env.ssao_enabled = on)
	await _probe("SSIL", func(on: bool) -> void: _env.ssil_enabled = on)
	await _probe("SSR", func(on: bool) -> void: _env.ssr_enabled = on)
	await _probe("SDFGI", func(on: bool) -> void: _env.sdfgi_enabled = on, 20)
	await _probe("depth of field (far blur)", func(on: bool) -> void: _attrs.dof_blur_far_enabled = on)
	await _probe("directional shadows", func(on: bool) -> void: _sun.shadow_enabled = on)
	await _probe("omni shadows", func(on: bool) -> void: _omni.shadow_enabled = on)
	await _build_2d()
	await _probe("2D glow (Environment on the canvas, HDR 2D)", func(on: bool) -> void: _env.glow_enabled = on, 6)
	var file: FileAccess = FileAccess.open(ProjectSettings.globalize_path("exports/look-test/renderer_support_%s.txt" % _tag), FileAccess.WRITE)
	file.store_string("\n".join(_lines) + "\n")
	file.close()
	print("\n".join(_lines))
	quit()


func _build_3d() -> void:
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color(0.05, 0.05, 0.1)
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.4, 0.4, 0.5)
	_env.glow_hdr_threshold = 0.8
	_env.glow_intensity = 1.5
	_env.fog_light_color = Color(0.3, 0.35, 0.5)
	_env.fog_density = 0.05
	_env.volumetric_fog_density = 0.05
	_env.sdfgi_use_occlusion = true
	_attrs = CameraAttributesPractical.new()
	_attrs.dof_blur_far_distance = 6.0
	_attrs.dof_blur_far_transition = 4.0
	_attrs.dof_blur_amount = 0.2
	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.environment = _env
	world_env.camera_attributes = _attrs
	root.add_child(world_env)
	var camera: Camera3D = Camera3D.new()
	camera.position = Vector3(0, 5, 9)
	camera.rotation_degrees = Vector3(-30, 0, 0)
	camera.current = true
	root.add_child(camera)
	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-50, -40, 0)
	root.add_child(_sun)
	_omni = OmniLight3D.new()
	_omni.position = Vector3(3.5, 3.0, 2.5)
	_omni.omni_range = 8.0
	_omni.light_energy = 2.0
	root.add_child(_omni)
	var floor_mesh: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(60, 60)
	floor_mesh.mesh = plane
	var checker: Image = Image.create_empty(64, 64, false, Image.FORMAT_RGB8)
	for y: int in 64:
		for x: int in 64:
			checker.set_pixel(x, y, Color(0.7, 0.7, 0.7) if (floori(x / 8.0) + floori(y / 8.0)) % 2 == 0 else Color(0.2, 0.25, 0.2))
	var floor_material: StandardMaterial3D = StandardMaterial3D.new()
	floor_material.albedo_texture = ImageTexture.create_from_image(checker)
	floor_material.uv1_scale = Vector3(20, 20, 1)
	floor_mesh.material_override = floor_material
	root.add_child(floor_mesh)
	for i: int in 7:
		var box: MeshInstance3D = MeshInstance3D.new()
		var cube: BoxMesh = BoxMesh.new()
		cube.size = Vector3(1.6, 1.6, 1.6)
		box.mesh = cube
		box.position = Vector3(-6 + i * 2.0, 0.8, -i * 3.0 + 1.0)
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.9, 0.5, 0.3)
		box.material_override = material
		root.add_child(box)
	var lamp: MeshInstance3D = MeshInstance3D.new()
	lamp.mesh = SphereMesh.new()
	lamp.position = Vector3(1, 2.5, 0)
	var glow: StandardMaterial3D = StandardMaterial3D.new()
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.8, 0.4)
	glow.emission_energy_multiplier = 6.0
	lamp.material_override = glow
	root.add_child(lamp)


## Removes the 3D scene and sets up a 2D one: a bright sprite on a dark field under the environment's canvas glow.
func _build_2d() -> void:
	for child: Node in root.get_children():
		if child is Node3D or child is WorldEnvironment:
			child.queue_free()
	await _frames(3)
	root.use_hdr_2d = true
	_env = Environment.new()
	_env.background_mode = Environment.BG_CANVAS
	_env.glow_enabled = false
	_env.glow_hdr_threshold = 0.6
	_env.glow_intensity = 1.5
	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.environment = _env
	root.add_child(world_env)
	var back: ColorRect = ColorRect.new()
	back.color = Color(0.04, 0.04, 0.06)
	back.size = Vector2(1280, 720)
	root.add_child(back)
	var spot: ColorRect = ColorRect.new()
	spot.color = Color(2.0, 1.6, 0.9)
	spot.size = Vector2(60, 60)
	spot.position = Vector2(300, 200)
	root.add_child(spot)
	await _frames(6)


func _probe(label: String, apply: Callable, wait: int = 4) -> void:
	apply.call(false)
	await _frames(wait + 8)
	var off: Image = root.get_viewport().get_texture().get_image()
	await _frames(4)
	var noise: float = _difference(off, root.get_viewport().get_texture().get_image())
	apply.call(true)
	await _frames(wait + 8)
	var on: Image = root.get_viewport().get_texture().get_image()
	apply.call(false)
	var difference: float = _difference(off, on)
	var works: bool = difference > maxf(noise * NOISE_FACTOR, FLOOR)
	_lines.append("%-46s %s (difference %.4f, noise %.4f)" % [label, "WORKS" if works else "no visible effect", difference, noise])


func _difference(a: Image, b: Image) -> float:
	a.resize(120, 68)
	b.resize(120, 68)
	var total: float = 0.0
	for y: int in 68:
		for x: int in 120:
			var ca: Color = a.get_pixel(x, y)
			var cb: Color = b.get_pixel(x, y)
			total += absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)
	return total / (120.0 * 68.0 * 3.0)


func _frames(count: int) -> void:
	for _i: int in count:
		await process_frame
