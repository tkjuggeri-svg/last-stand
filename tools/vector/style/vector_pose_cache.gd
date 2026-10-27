class_name VectorPoseCache
extends Node
## Bakes vector poses into textures on demand (branch vector-test, never merge): the recommended path for detailed
## vector art, because painting the shapes every frame costs about 0.15 ms a character. A pose is a key plus a
## painter; the first request renders it once in a SubViewport at SCALE and keeps the texture, later requests just
## return it. Until a pose is ready the caller paints it live. Textures come out premultiplied (a transparent
## viewport), so they are drawn with premult_material().

## Render scale: the camera's 2x zoom times the characters' ~1.25 scale, so baked poses stay sharp.
const SCALE: float = 2.5
## New poses rendered per frame at most (the rest wait a frame and are painted live meanwhile).
const PER_FRAME: int = 16

static var _premult: CanvasItemMaterial

var _textures: Dictionary = {}
var _pending: Dictionary = {}  # key -> [SubViewport, frames waited]
var _started_this_frame: int = 0


static func premult_material() -> CanvasItemMaterial:
	if _premult == null:
		_premult = CanvasItemMaterial.new()
		_premult.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	return _premult


## The baked texture for `key` (or null while it renders): `box` is the pose's bounds in pose units, `painter`
## a Callable(ci: CanvasItem) that paints it.
func get_pose(key: String, box: Rect2, painter: Callable) -> Texture2D:
	if _textures.has(key):
		return _textures[key]
	if not _pending.has(key) and _started_this_frame < PER_FRAME:
		_started_this_frame += 1
		var view: SubViewport = SubViewport.new()
		view.size = Vector2i((box.size * SCALE).ceil())
		view.transparent_bg = true
		view.render_target_update_mode = SubViewport.UPDATE_ONCE
		view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
		var canvas: Node2D = Node2D.new()
		canvas.position = -box.position * SCALE
		canvas.scale = Vector2(SCALE, SCALE)
		canvas.draw.connect(func() -> void: painter.call(canvas))
		view.add_child(canvas)
		add_child(view)
		_pending[key] = [view, 0]
	return null


## How many poses are baked (the report).
func count() -> int:
	return _textures.size()


func _process(_delta: float) -> void:
	_started_this_frame = 0
	for key: String in _pending.keys():
		var entry: Array = _pending[key]
		entry[1] = int(entry[1]) + 1
		if int(entry[1]) < 2:
			continue
		var view: SubViewport = entry[0]
		_textures[key] = ImageTexture.create_from_image(view.get_texture().get_image())
		view.queue_free()
		_pending.erase(key)


## Draws pose texture `texture` (baked from `box`) on `ci` at its pose origin.
static func draw_pose(ci: CanvasItem, texture: Texture2D, box: Rect2) -> void:
	ci.draw_texture_rect(texture, box, false)
