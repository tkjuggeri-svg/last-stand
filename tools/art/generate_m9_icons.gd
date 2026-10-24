extends SceneTree
## Dev tool: draws the M9 card and relic icons (m9_icons_art.gd) into assets/sprites/ui/.
##   godot --headless --path . --script res://tools/art/generate_m9_icons.gd

const IconsArt: GDScript = preload("res://tools/art/m9_icons_art.gd")


func _initialize() -> void:
	var art: RefCounted = IconsArt.new()
	for id: String in IconsArt.ICONS:
		var path: String = IconsArt.ICONS[id]
		var image: Image = art.icon(id)
		image.save_png(ProjectSettings.globalize_path(path))
		print("saved ", path)
	quit(0)
