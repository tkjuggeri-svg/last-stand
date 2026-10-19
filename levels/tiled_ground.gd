class_name TiledGround
extends Node2D
## The baked arena ground, drawn as a grid of tiles instead of one huge sprite. Looks identical, but in
## the Compatibility renderer every 2D light redraws each item it touches: with one big sprite every
## lantern re-shaded the whole arena, with tiles only the few under it (about 5 ms per frame saved).

@export var texture: Texture2D
## Tile size in texture pixels (art px).
@export var tile_size: Vector2i = Vector2i(64, 64)


func _ready() -> void:
	if texture == null:
		return
	var size: Vector2i = Vector2i(texture.get_size())
	for y: int in range(0, size.y, tile_size.y):
		for x: int in range(0, size.x, tile_size.x):
			var tile: Sprite2D = Sprite2D.new()
			tile.texture = texture
			tile.centered = false
			tile.region_enabled = true
			tile.region_rect = Rect2(x, y, mini(tile_size.x, size.x - x), mini(tile_size.y, size.y - y))
			tile.position = Vector2(x, y)
			add_child(tile)


## The ground's extent in the level (what the arena checks compare with).
func get_rect_in_parent() -> Rect2:
	return Rect2(position, texture.get_size() * scale)
