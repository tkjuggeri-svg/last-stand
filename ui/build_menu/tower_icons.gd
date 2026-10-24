class_name TowerIcons
## Menu icons cut from the towers' idle art: the upper part of an animation's first frame (the top
## 40 of its 48 rows in the original 32x48 frame, skipping the empty sky above the tallest tower),
## shown at 64x80 px whatever the sheet's resolution (the hand-drawn sheet is already 64x96 frames).

const TOWER_FRAMES: SpriteFrames = preload("res://entities/towers/tower_frames.tres")
## In units of the original 32 px wide frame (scaled to the sheet's frame width).
const ICON_TOP: float = 4.0
const ICON_SIZE: Vector2 = Vector2(32, 40)
const ORIGINAL_WIDTH: float = 32.0
## The icon's size on screen (UI textures are drawn pixel for pixel).
const SHOWN_SIZE: Vector2i = Vector2i(64, 80)


## The icon of tower `data` at `level` (falls back to level 1 art).
static func for_level(data: TowerData, level: int = 1) -> Texture2D:
	var frames: SpriteFrames = _frames_of(data)
	var anim: StringName = StringName("%s_idle" % data.id if level <= 1 else "%s_idle_%d" % [data.id, level])
	return for_animation(anim if frames.has_animation(anim) else StringName("%s_idle" % data.id), frames)


## The icon of an evolved tower (its own idle art; the base tower's top level if it has none).
static func for_evolution(data: TowerData, evolution: TowerEvolution) -> Texture2D:
	var frames: SpriteFrames = _frames_of(data)
	var anim: StringName = StringName("%s_idle" % evolution.id)
	return for_animation(anim, frames) if frames.has_animation(anim) else for_level(data, data.max_level())


static func for_animation(anim: StringName, frames: SpriteFrames = TOWER_FRAMES) -> Texture2D:
	if not frames.has_animation(anim):
		return null
	var frame: AtlasTexture = frames.get_frame_texture(anim, 0) as AtlasTexture
	if frame == null:
		return null
	var k: float = frame.region.size.x / ORIGINAL_WIDTH
	var image: Image = frame.atlas.get_image().get_region(Rect2i(Rect2(frame.region.position + Vector2(0, ICON_TOP * k), ICON_SIZE * k)))
	image.resize(SHOWN_SIZE.x, SHOWN_SIZE.y, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(image)


## The sheet `data`'s animations are in (its own, or the shared one).
static func _frames_of(data: TowerData) -> SpriteFrames:
	return data.frames if data.frames != null else TOWER_FRAMES
