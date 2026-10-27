class_name SheetSprite
extends AnimatedSprite2D
## An AnimatedSprite2D that fits its sheet (M15): vector sheets are drawn at twice the world resolution and their
## SpriteFrames carry that factor as metadata (SHEET_SCALE, set by tools/art/build_sprite_frames.gd). The sprite is
## then drawn at 1 / that scale with linear filtering; a pixel sheet (no metadata) keeps scale 1 and the project's
## nearest filtering. Re-applied whenever the frames change (a hero's data, an enemy's look). Display only.

const SHEET_SCALE: StringName = &"sheet_scale"


func _ready() -> void:
	sprite_frames_changed.connect(fit_sheet)
	fit_sheet()


func fit_sheet() -> void:
	var factor: float = float(sprite_frames.get_meta(SHEET_SCALE, 1.0)) if sprite_frames != null else 1.0
	scale = Vector2.ONE / factor
	texture_filter = TEXTURE_FILTER_LINEAR if factor > 1.0 else TEXTURE_FILTER_PARENT_NODE
