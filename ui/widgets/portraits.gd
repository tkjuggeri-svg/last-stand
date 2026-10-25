class_name Portraits
## The portraits sheet (M11): six busts side by side, 96x96 each (tools/art/portrait_art.gd). A person's
## index is StoryCharacter.portrait or HeroData.portrait_index.

const SHEET: Texture2D = preload("res://assets/sprites/ui/portraits.png")
const FRAME: int = 96


static func texture(index: int) -> AtlasTexture:
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = SHEET
	atlas.region = Rect2(index * FRAME, 0, FRAME, FRAME)
	return atlas
