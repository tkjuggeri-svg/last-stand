class_name SpriteMirror
extends RefCounted
## Variant B's mapping of the 2D world onto the 3D stage (look-test). Every world sprite, label, lamp and
## health bar of the running level gets a counterpart here that is moved to follow it each frame; the 2D
## nodes keep doing all the work (they are only hidden from the 2D view). One 2D px is 1/UNIT units on the
## ground plane (x -> x, y -> z). Upright sprites stand on the ground at the bottom centre of their 2D rectangle
## and face the camera (so the art keeps its proportions); ground-layer art (negative z_index, rings, pads,
## rotated shots) lies flat on the ground.

enum Kind { SPRITE, LABEL, BAR, LIGHT }

const UNIT: float = 32.0
const FLAT_NAMES: Array[String] = ["Pad", "Ripple", "Rubble", "Shadow", "Scorch", "Decal", "Ring", "Patch"]
const EFFECT_PRIORITY: int = 10

## Camera elevation above the ground, degrees (set by the presenter): billboards lean back to face it.
var elevation: float = 42.0
## The level's CanvasModulate (the night tint) as a multiplier for lit sprites, so they match the 2D look.
var world_tint: Color = Color.WHITE
## Omni lights are scaled by this (Forward+ attenuates differently from Compatibility).
var light_gain: float = 1.0
var omni_shadows: bool = true
var omni_lights: bool = true

var _entries: Dictionary = {}
var _root: Node3D


func _init(root: Node3D) -> void:
	_root = root


func count() -> int:
	return _entries.size()


func has(node: Node) -> bool:
	return _entries.has(node.get_instance_id())


## Makes the counterpart of `node` if it is something the 3D stage shows. Returns true when it did.
func add(node: Node) -> bool:
	if has(node) or not (node is CanvasItem or node is PointLight2D):
		return false
	var item: CanvasItem = node as CanvasItem
	if item.get_canvas_layer_node() != null or _under_ground(node):
		return false
	var entry: Dictionary = {}
	if node is AnimatedSprite2D or node is Sprite2D:
		entry = _make_sprite(node)
	elif node is Label:
		entry = _make_label(node as Label)
	elif node is EnemyHealthBar:
		entry = _make_bar(node as EnemyHealthBar)
	elif node is PointLight2D:
		entry = _make_light(node as PointLight2D)
	if entry.is_empty():
		return false
	entry["src"] = node
	_entries[node.get_instance_id()] = entry
	_root.add_child(entry["dst"])
	return true


func update() -> void:
	for id: int in _entries.keys():
		var entry: Dictionary = _entries[id]
		var source: Variant = entry["src"]  # may be freed: not cast before the check
		if not is_instance_valid(source):
			(entry["dst"] as Node).queue_free()
			_entries.erase(id)
			continue
		var src: Node = source as Node
		var dst: Node3D = entry["dst"]
		var visible: bool = (src as CanvasItem).is_visible_in_tree()
		dst.visible = visible
		if not visible:
			continue
		match entry["kind"]:
			Kind.SPRITE:
				_sync_sprite(entry)
			Kind.LABEL:
				_sync_label(entry)
			Kind.BAR:
				_sync_bar(entry)
			Kind.LIGHT:
				_sync_light(entry)


## The ground point (px) a 2D rectangle's bottom centre is at, and its size.
static func ground_point(center: Vector2, size: Vector2) -> Vector2:
	return Vector2(center.x, center.y + size.y * 0.5)


func _under_ground(node: Node) -> bool:
	var parent: Node = node.get_parent()
	while parent != null:
		if parent is TiledGround:
			return true
		parent = parent.get_parent()
	return false


func _is_flat(src: CanvasItem) -> bool:
	if src.z_index < 0 or absf(src.global_rotation) > 0.01:
		return true
	return FLAT_NAMES.has(String(src.name)) or FLAT_NAMES.has(String(src.get_parent().name))


func _is_effect(src: Node) -> bool:
	var parent: Node = src
	while parent != null:
		if String(parent.name) == "Effects":
			return true
		parent = parent.get_parent()
	return (src as CanvasItem).z_index > 0


# ----------------------------------------------------------------------------- sprites

func _make_sprite(src: Node) -> Dictionary:
	var dst: Sprite3D = Sprite3D.new()
	dst.pixel_size = 1.0 / UNIT
	dst.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	dst.double_sided = true
	var flat: bool = _is_flat(src as CanvasItem)
	var effect: bool = _is_effect(src)
	if flat:
		dst.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		dst.rotation_degrees = Vector3(-90, 0, 0)
		dst.shaded = false
		dst.transparent = true
		dst.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
		dst.render_priority = -1
		dst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	else:
		dst.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		dst.shaded = not effect
		dst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if effect else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		dst.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED if effect else SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
		if effect:
			dst.transparent = true
			dst.no_depth_test = true
			dst.render_priority = EFFECT_PRIORITY
	return {"kind": Kind.SPRITE, "dst": dst, "flat": flat, "effect": effect}


func _sync_sprite(entry: Dictionary) -> void:
	var src: Node2D = entry["src"]
	var dst: Sprite3D = entry["dst"]
	var texture: Texture2D
	var size: Vector2
	var offset: Vector2 = Vector2.ZERO
	var centered: bool = true
	if src is AnimatedSprite2D:
		var animated: AnimatedSprite2D = src as AnimatedSprite2D
		if animated.sprite_frames == null or not animated.sprite_frames.has_animation(animated.animation) \
				or animated.sprite_frames.get_frame_count(animated.animation) == 0:
			dst.visible = false
			return
		texture = animated.sprite_frames.get_frame_texture(animated.animation, animated.frame)
		dst.flip_h = animated.flip_h
		dst.flip_v = animated.flip_v
		offset = animated.offset
		centered = animated.centered
		size = texture.get_size() if texture != null else Vector2.ZERO
	else:
		var plain: Sprite2D = src as Sprite2D
		texture = plain.texture
		dst.flip_h = plain.flip_h
		dst.flip_v = plain.flip_v
		offset = plain.offset
		centered = plain.centered
		dst.region_enabled = plain.region_enabled
		dst.region_rect = plain.region_rect
		dst.hframes = plain.hframes
		dst.vframes = plain.vframes
		dst.frame = plain.frame
		size = plain.region_rect.size if plain.region_enabled else (texture.get_size() if texture != null else Vector2.ZERO)
		size = Vector2(size.x / maxi(plain.hframes, 1), size.y / maxi(plain.vframes, 1))
	if texture == null or size == Vector2.ZERO:
		dst.visible = false
		return
	dst.texture = texture
	var tint: Color = (src as CanvasItem).modulate * (src as CanvasItem).self_modulate
	if dst.shaded:
		tint *= world_tint
	dst.modulate = tint
	var scale2d: Vector2 = src.global_scale
	dst.flip_h = dst.flip_h != (scale2d.x < 0.0)
	var center: Vector2 = src.global_position + (offset + (Vector2.ZERO if centered else size * 0.5)) * scale2d
	var drawn: Vector2 = size * scale2d.abs()
	dst.scale = Vector3(absf(scale2d.x), absf(scale2d.y), 1.0)
	if entry["flat"]:
		dst.position = Vector3(center.x / UNIT, 0.03, center.y / UNIT)
	else:
		dst.position = _stand(center, drawn)


## Centre of an upright, camera-facing quad of `drawn` px whose bottom edge sits at the rectangle's bottom centre.
func _stand(center: Vector2, drawn: Vector2) -> Vector3:
	var foot: Vector2 = ground_point(center, drawn)
	var half: float = drawn.y * 0.5 / UNIT
	var e: float = deg_to_rad(elevation)
	return Vector3(foot.x / UNIT, half * cos(e), foot.y / UNIT - half * sin(e))


# ----------------------------------------------------------------------------- labels

func _make_label(src: Label) -> Dictionary:
	var dst: Label3D = Label3D.new()
	dst.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	dst.no_depth_test = true
	dst.render_priority = EFFECT_PRIORITY + 1
	dst.shaded = false
	dst.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	dst.font = src.get_theme_font("font")
	dst.font_size = src.get_theme_font_size("font_size")
	dst.outline_size = 6
	dst.pixel_size = 1.0 / UNIT
	return {"kind": Kind.LABEL, "dst": dst}


func _sync_label(entry: Dictionary) -> void:
	var src: Label = entry["src"]
	var dst: Label3D = entry["dst"]
	dst.text = src.text
	dst.modulate = src.modulate * src.self_modulate * src.get_theme_color("font_color")
	var rect: Rect2 = src.get_global_rect()
	dst.position = _stand(rect.get_center(), rect.size)


# ----------------------------------------------------------------------------- health bars

func _make_bar(_src: EnemyHealthBar) -> Dictionary:
	var dst: Sprite3D = Sprite3D.new()
	dst.pixel_size = 1.0 / UNIT
	dst.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	dst.shaded = false
	dst.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	dst.no_depth_test = true
	dst.render_priority = EFFECT_PRIORITY
	return {"kind": Kind.BAR, "dst": dst, "ratio": -1.0}


func _sync_bar(entry: Dictionary) -> void:
	var src: EnemyHealthBar = entry["src"]
	var dst: Sprite3D = entry["dst"]
	var width: int = int(src.get("_width")) + 4
	var ratio: float = src.get_fill_ratio()
	if not is_equal_approx(ratio, entry["ratio"]):
		entry["ratio"] = ratio
		var image: Image = Image.create_empty(width, 8, false, Image.FORMAT_RGBA8)
		image.fill(Color("1a141f"))
		image.fill_rect(Rect2i(2, 2, width - 4, 4), Color("3a1218"))
		image.fill_rect(Rect2i(2, 2, int(ceil((width - 4) * ratio)), 4), src.get("_fill_light") as Color)
		dst.texture = ImageTexture.create_from_image(image)
	var size: Vector2 = Vector2(width, 8)
	dst.position = _stand(src.global_position + size * 0.5, size)


# ----------------------------------------------------------------------------- lights

func _make_light(src: PointLight2D) -> Dictionary:
	if not omni_lights or src.get_parent() is CharacterBody2D:
		return {}  # every enemy carries a small glow: a 3D light each would be hundreds of lights
	var dst: OmniLight3D = OmniLight3D.new()
	dst.shadow_enabled = omni_shadows
	dst.light_color = src.color
	var radius_px: float = (src.texture.get_width() * 0.5 if src.texture != null else 64.0) * src.texture_scale
	dst.omni_range = clampf(radius_px / UNIT * 1.3, 2.5, 14.0)
	dst.omni_attenuation = 1.0
	return {"kind": Kind.LIGHT, "dst": dst}


func _sync_light(entry: Dictionary) -> void:
	var src: PointLight2D = entry["src"]
	var dst: OmniLight3D = entry["dst"]
	dst.light_energy = src.energy * 3.5 * light_gain
	dst.position = Vector3(src.global_position.x / UNIT, 1.5, src.global_position.y / UNIT)
