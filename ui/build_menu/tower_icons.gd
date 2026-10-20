class_name TowerIcons
## Menu icons cut from the towers' idle art: the upper part of an animation's first frame (32x40 art
## px, skipping the empty sky above the tallest tower), shown at the 2x art scale.

const TOWER_FRAMES: SpriteFrames = preload("res://entities/towers/tower_frames.tres")
const ICON_TOP: float = 4.0
const ICON_SIZE: Vector2 = Vector2(32, 40)


## The icon of tower `data` at `level` (falls back to level 1 art).
static func for_level(data: TowerData, level: int = 1) -> Texture2D:
	var anim: StringName = StringName("%s_idle" % data.id if level <= 1 else "%s_idle_%d" % [data.id, level])
	return for_animation(anim if TOWER_FRAMES.has_animation(anim) else StringName("%s_idle" % data.id))


## The icon of an evolved tower (its own idle art; the base tower's top level if it has none).
static func for_evolution(data: TowerData, evolution: TowerEvolution) -> Texture2D:
	var anim: StringName = StringName("%s_idle" % evolution.id)
	return for_animation(anim) if TOWER_FRAMES.has_animation(anim) else for_level(data, data.max_level())


static func for_animation(anim: StringName) -> Texture2D:
	if not TOWER_FRAMES.has_animation(anim):
		return null
	var frame: AtlasTexture = TOWER_FRAMES.get_frame_texture(anim, 0) as AtlasTexture
	if frame == null:
		return null
	var image: Image = frame.atlas.get_image().get_region(Rect2i(Rect2(frame.region.position + Vector2(0, ICON_TOP), ICON_SIZE)))
	image.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(image)
