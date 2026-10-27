class_name VectorGhoul
extends Node2D
## The Ghoul in the vector test style (branch vector-test, never merge), detailed (GhoulPainter). Poses are baked by
## the shared VectorPoseCache (facing x walk 12 / idle 8 / attack 6 phases); the eyes' glow, the cold mist and the
## hit flash are live. Death is a transform of the baked idle pose. Reads the real enemy's hidden sprite.

const WALK_HZ: float = 1.4
const IDLE_HZ: float = 0.5
const WALK_PHASES: int = 12
const IDLE_PHASES: int = 8
const LUNGE_STEPS: int = 6
const MIST: int = 4

var sprite: AnimatedSprite2D
var cache: VectorPoseCache
var _time: float = 0.0
var _offset: float = 0.0
var _pose: Dictionary = {}
var _texture: Texture2D
var _body: Node2D
var _glow: Node2D
var _eyes: Array[Vector2] = []


func _ready() -> void:
	_offset = fmod(absf(global_position.x * 0.37 + global_position.y * 0.11), 1.0)
	_body = Node2D.new()
	_body.name = "Body"
	_body.material = VectorPoseCache.premult_material()
	_body.draw.connect(_draw_body)
	add_child(_body)
	_glow = VectorStyle.make_glow_layer(self, _draw_glow)


func _process(delta: float) -> void:
	_time += delta
	var s: Dictionary = VectorStyle.sprite_state(sprite)
	var flash: float = 0.0
	var shader: ShaderMaterial = sprite.material as ShaderMaterial
	if shader != null:
		flash = float(shader.get_shader_parameter(&"flash"))
	var walking: bool = s.state == "walk"
	var lunge_step: int = 0
	if s.state == "attack":
		lunge_step = int(sin(clampf(float(s.progress), 0.0, 1.0) * PI) * (LUNGE_STEPS - 1) + 0.5)
	var phases: int = WALK_PHASES if walking else IDLE_PHASES
	var index: int = int(fmod(_time * (WALK_HZ if walking else IDLE_HZ) + _offset, 1.0) * phases)
	var facing: String = s.facing
	var lunge: float = float(lunge_step) / (LUNGE_STEPS - 1)
	_pose = {"facing": facing, "walk": walking, "phase": float(index) / phases, "lunge": lunge}
	var key: String = "ghoul_%s_%s_%d_%d" % [facing, "w" if walking else "i", index, lunge_step]
	_texture = cache.get_pose(key, GhoulPainter.BOX, func(ci: CanvasItem) -> void:
		GhoulPainter.paint(ci, {"facing": facing, "walk": walking, "phase": float(index) / phases, "lunge": lunge})) if cache != null else null
	var mirror: float = -1.0 if s.flip and facing == "side" else 1.0
	var alpha: float = sprite.modulate.a
	var bob: float = -absf(sin(_time * WALK_HZ * TAU)) * 1.2 if walking else 0.0
	_body.position = Vector2(0, bob)
	_body.rotation = 0.0
	_body.scale = Vector2(mirror, 1.0)
	if s.state == "death":
		var p: float = clampf(float(s.progress), 0.0, 1.0)
		_body.position = Vector2(0, p * 7.0)
		_body.rotation = p * 1.1 * mirror
		_body.scale = Vector2(mirror, 1.0 - p * 0.35)
		alpha *= 1.0 - p * 0.75
	modulate = Color(1.0 + flash * 2.5, 1.0 + flash * 2.5, 1.0 + flash * 2.5, alpha)
	# Where the sockets are, for the live glow.
	match facing:
		"up":
			_eyes = []
		"side":
			_eyes = [Vector2((13.2 + lunge * 4.0) * mirror, -19.5 + lunge + bob)]
		_:
			_eyes = [Vector2(-2.3, -27.0 + lunge * 2.0 + bob), Vector2(2.3, -27.0 + lunge * 2.0 + bob)]
	queue_redraw()
	_body.queue_redraw()
	_glow.queue_redraw()


func _draw() -> void:
	VectorStyle.shadow(self, Vector2(0, 2), 12, 4.8)
	if _texture == null and not _pose.is_empty():
		draw_set_transform(_body.position, _body.rotation, _body.scale)
		GhoulPainter.paint(self, _pose)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_body() -> void:
	if _texture != null:
		VectorPoseCache.draw_pose(_body, _texture, GhoulPainter.BOX)


func _draw_glow(layer: Node2D) -> void:
	if String(VectorStyle.sprite_state(sprite).state) == "death":
		return
	VectorStyle.draw_glow(layer, VectorStyle.COLD_GLOW, Vector2(0, -14), 24.0, 0.1 + 0.03 * sin(_time * 3.0))
	for eye: Vector2 in _eyes:
		VectorStyle.draw_glow(layer, VectorStyle.EYE_RED, eye, 3.6, 0.95)
		VectorStyle.draw_glow(layer, Color("ffd0c0"), eye, 1.0, 0.8)
	# Cold mist rising off the body.
	for i: int in MIST:
		var t: float = fmod(_time * 0.35 + i / float(MIST) + _offset, 1.0)
		var at: Vector2 = Vector2(sin(i * 2.3 + _time * 0.8) * 7.0, -6.0 - t * 22.0)
		VectorStyle.draw_glow(layer, VectorStyle.COLD_GLOW, at, 5.0 + t * 6.0, 0.18 * (1.0 - t))
