class_name VectorSkin
extends Node
## Puts the vector test look on a level (branch vector-test, never merge): the graveyard ground, the Knight,
## every Ghoul and every Archer tower get a vector node; the pixel sprites they replace stay in place and keep
## animating, only invisible (self_modulate alpha 0), so the vector nodes read their state and nothing in the
## game changes. Everything else (props, other enemies, shots, effects, the HUD) stays pixel art.
## Add it as a child of a level (VectorSkin.apply(level)) before or after the level is ready.

const GHOUL: String = "ghoul.tres"
## Sizes matched to today's sprites (the shapes are drawn at a base size; scaling vectors costs nothing).
const KNIGHT_SCALE: float = 1.2
const GHOUL_SCALE: float = 1.3
const ARCHER: StringName = &"archer"

## Which parts get the vector look (the comparison tool's --parts, to measure each one's cost).
static var parts: Array[String] = ["ground", "knight", "ghoul", "archer"]
## Bake the vector ground into one texture when the level starts (the tool's --live-ground draws it live:
## thousands of cached shapes are still submitted every frame, about 5 ms at 1280x720).
static var bake_ground: bool = true

var level: Node2D


static func apply(target: Node2D) -> VectorSkin:
	var skin: VectorSkin = VectorSkin.new()
	skin.name = "VectorSkin"
	skin.level = target
	target.add_child(skin)
	return skin


func _ready() -> void:
	if parts.has("ground"):
		_ground()
	_skin_tree(level)
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if level.is_ancestor_of(node):
		# Wait until the new node's own children are ready (its sprite, its data).
		_skin.call_deferred(node)


func _skin_tree(node: Node) -> void:
	_skin(node)
	for child: Node in node.get_children():
		_skin_tree(child)


func _skin(node: Node) -> void:
	if not is_instance_valid(node) or node.has_node("Vector"):
		return
	if node is Hero and parts.has("knight"):
		var hero: Hero = node
		var knight: VectorKnight = VectorKnight.new()
		knight.sprite = hero.get_node("%Sprite")
		knight.pivot = hero.get_node("%AttackPivot")
		_hide(knight.sprite)
		_hide(hero.get_node("%AttackVisual"))
		var rig: Node = hero.get_node_or_null("%VectorRig")
		if rig != null:
			rig.set("enabled", false)  # the earlier cutout-rig experiment on this branch
		knight.scale = Vector2(KNIGHT_SCALE, KNIGHT_SCALE)
		_attach(hero, knight)
	elif node is Enemy and parts.has("ghoul"):
		var enemy: Enemy = node
		if enemy.data == null or enemy.data.resource_path.get_file() != GHOUL:
			return
		var ghoul: VectorGhoul = VectorGhoul.new()
		ghoul.sprite = enemy.get_node("%Sprite")
		_hide(ghoul.sprite)
		ghoul.scale = Vector2(GHOUL_SCALE, GHOUL_SCALE)
		_attach(enemy, ghoul)
	elif node is Tower and parts.has("archer"):
		var tower: Tower = node
		if tower.data == null or tower.data.id != ARCHER:
			return
		var archer: VectorArcher = VectorArcher.new()
		archer.tower = tower
		archer.sprite = tower.get_node("Sprite")
		_hide(archer.sprite)
		_attach(tower, archer)


func _attach(owner_node: Node2D, art: Node2D) -> void:
	art.name = "Vector"
	# Vectors and their gradient glows want smooth filtering; the project's nearest filter (right for pixel
	# art) shows the glows' texels as steps.
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	owner_node.add_child(art)


func _hide(item: CanvasItem) -> void:
	item.self_modulate.a = 0.0


func _ground() -> void:
	var pixel_ground: Node2D = level.get_node("%Ground")
	var floor_rect: Control = level.get_node("%Floor")
	var ground: VectorGround = VectorGround.new()
	ground.name = "VectorGround"
	ground.z_index = pixel_ground.z_index
	ground.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ground.light_mask = 0  # like the Floor and the baked ground: 2D lights would redraw the whole ground and wash it out
	ground.floor_rect = Rect2(floor_rect.position, floor_rect.size)
	ground.fortress = (level.get_node("Fortress") as Node2D).position
	var crypt: Node2D = level.get_node_or_null("Crypt")
	ground.crypt = crypt.position if crypt != null else ground.floor_rect.position
	for child: Node in level.get_children():
		if child is Path2D and String(child.name).begins_with("Lane"):
			var path: Path2D = child
			var points: PackedVector2Array = PackedVector2Array()
			for p: Vector2 in path.curve.get_baked_points():
				points.append(level.to_local(path.to_global(p)))
			ground.lanes.append(points)
	var slots: Node = level.get_node_or_null("BuildSlots")
	if slots != null:
		for slot: Node in slots.get_children():
			ground.avoid.append(level.to_local((slot as Node2D).global_position))
	if not bake_ground:
		level.add_child(ground)
		# Right above the pixel ground: the fog and everything else still draw over it.
		level.move_child(ground, pixel_ground.get_index() + 1)
		return
	var view: SubViewport = SubViewport.new()
	view.size = Vector2i(ground.floor_rect.size)
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	ground.position = -ground.floor_rect.position
	view.add_child(ground)
	level.add_child(view)
	await get_tree().process_frame
	await get_tree().process_frame
	var baked: Sprite2D = Sprite2D.new()
	baked.name = "VectorGround"
	baked.texture = ImageTexture.create_from_image(view.get_texture().get_image())
	baked.centered = false
	baked.position = ground.floor_rect.position
	baked.z_index = pixel_ground.z_index
	baked.light_mask = 0
	view.queue_free()
	level.add_child(baked)
	level.move_child(baked, pixel_ground.get_index() + 1)
