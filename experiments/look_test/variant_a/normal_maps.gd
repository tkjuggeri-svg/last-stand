class_name LookNormalMaps
extends RefCounted
## Makes normal maps for sprite sheets from the art itself (look-test variant A): the height is a soft dome
## of the sprite's silhouette plus its brightness, the normal its slope. Then wraps SpriteFrames so every
## frame is an AtlasTexture over a CanvasTexture (diffuse + normal), which 2D lights shade with relief.

const DOME_SHRINK: int = 4
const DOME_WEIGHT: float = 0.6
const SLOPE: float = 2.6

var _canvases: Dictionary = {}
var _converted: Dictionary = {}


## A copy of `frames` whose textures carry normal maps.
func convert(frames: SpriteFrames) -> SpriteFrames:
	if _converted.has(frames):
		return _converted[frames]
	var out: SpriteFrames = frames.duplicate(true) as SpriteFrames
	for animation: StringName in out.get_animation_names():
		for i: int in out.get_frame_count(animation):
			out.set_frame(animation, i, _wrap(out.get_frame_texture(animation, i)), out.get_frame_duration(animation, i))
	_converted[frames] = out
	_converted[out] = out
	return out


func _wrap(texture: Texture2D) -> Texture2D:
	var atlas: AtlasTexture = texture as AtlasTexture
	if atlas == null:
		return _canvas(texture)
	var wrapped: AtlasTexture = AtlasTexture.new()
	wrapped.atlas = _canvas(atlas.atlas)
	wrapped.region = atlas.region
	wrapped.margin = atlas.margin
	wrapped.filter_clip = atlas.filter_clip
	return wrapped


func _canvas(sheet: Texture2D) -> CanvasTexture:
	if _canvases.has(sheet):
		return _canvases[sheet]
	var canvas: CanvasTexture = CanvasTexture.new()
	canvas.diffuse_texture = sheet
	canvas.normal_texture = ImageTexture.create_from_image(_normal_image(sheet.get_image()))
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_canvases[sheet] = canvas
	return canvas


func _normal_image(source: Image) -> Image:
	var image: Image = source.duplicate() as Image
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	var width: int = image.get_width()
	var height: int = image.get_height()
	var dome: Image = image.duplicate() as Image
	dome.resize(maxi(int(width / float(DOME_SHRINK)), 1), maxi(int(height / float(DOME_SHRINK)), 1), Image.INTERPOLATE_BILINEAR)
	dome.resize(width, height, Image.INTERPOLATE_BILINEAR)
	var data: PackedByteArray = image.get_data()
	var dome_data: PackedByteArray = dome.get_data()
	var heights: PackedFloat32Array = PackedFloat32Array()
	heights.resize(width * height)
	for i: int in width * height:
		var alpha: float = data[i * 4 + 3] / 255.0
		var luma: float = (data[i * 4] * 0.299 + data[i * 4 + 1] * 0.587 + data[i * 4 + 2] * 0.114) / 255.0
		heights[i] = DOME_WEIGHT * (dome_data[i * 4 + 3] / 255.0) + (1.0 - DOME_WEIGHT) * luma * alpha
	var out: PackedByteArray = PackedByteArray()
	out.resize(width * height * 4)
	for y: int in height:
		for x: int in width:
			var i: int = y * width + x
			var left: float = heights[i - 1] if x > 0 else heights[i]
			var right: float = heights[i + 1] if x < width - 1 else heights[i]
			var up: float = heights[i - width] if y > 0 else heights[i]
			var down: float = heights[i + width] if y < height - 1 else heights[i]
			var normal: Vector3 = Vector3((left - right) * SLOPE, (up - down) * SLOPE, 1.0).normalized()
			out[i * 4] = int((normal.x * 0.5 + 0.5) * 255.0)
			out[i * 4 + 1] = int((normal.y * 0.5 + 0.5) * 255.0)
			out[i * 4 + 2] = int((normal.z * 0.5 + 0.5) * 255.0)
			out[i * 4 + 3] = data[i * 4 + 3]
	return Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, out)
