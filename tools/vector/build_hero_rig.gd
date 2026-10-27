extends SceneTree
## Dev tool (not shipped, vector-test): builds entities/hero/vector/hero_vector_rig.tscn, the vector knight as a Godot 2D
## skeleton: a Skeleton2D with Bone2Ds (hip, legs, torso, head, sword arm and sword, shield arm and shield) and one textured
## Polygon2D per part (assets/sprites/hero_vector/*.svg, see split_knight_svg.py) weighted to its bone, in the source's drawing
## order. The AnimationPlayer holds idle, walk, attack, dash and death. Rerun after changing a pose:
##   godot --headless --path . --script res://tools/vector/build_hero_rig.gd

const PARTS_DIR: String = "res://assets/sprites/hero_vector/"
const OUT: String = "res://entities/hero/vector/hero_vector_rig.tscn"
const RIG_SCRIPT: GDScript = preload("res://entities/hero/vector/hero_vector_rig.gd")
## World pixels per SVG unit, and the raster scale the SVGs are imported at (the polygons draw them at SCALE / IMPORT_SCALE).
const SCALE: float = 0.38
const IMPORT_SCALE: float = 0.76
## Where the feet are in the SVG (the rig's origin).
const FEET: Vector2 = Vector2(128, 230)
## bone -> [parent, its joint in SVG units]
const BONES: Dictionary = {
	"Hip": ["", Vector2(128, 186)],
	"LegL": ["Hip", Vector2(112, 186)],
	"LegR": ["Hip", Vector2(146, 186)],
	"Torso": ["Hip", Vector2(128, 184)],
	"Head": ["Torso", Vector2(129, 122)],
	"ArmSword": ["Torso", Vector2(96, 138)],
	"Sword": ["ArmSword", Vector2(92, 178)],
	"ArmShield": ["Torso", Vector2(156, 136)],
	"Shield": ["ArmShield", Vector2(172, 170)],
}
## The parts in the source's drawing order (back to front) and the bone each follows ("" = none: it stays on the ground).
const PARTS: Array = [
	["shadow", ""], ["leg_l", "LegL"], ["leg_r", "LegR"], ["torso", "Torso"], ["arm_sword", "ArmSword"], ["sword", "Sword"],
	["pauldron_l", "ArmSword"], ["gorget", "Torso"], ["pauldron_r", "ArmShield"], ["shield", "Shield"], ["helm", "Head"],
]

var _root: Node2D
var _skeleton: Skeleton2D
var _bones: Dictionary = {}


func _initialize() -> void:
	_root = Node2D.new()
	_root.name = "HeroVectorRig"
	_root.set_script(RIG_SCRIPT)
	_skeleton = Skeleton2D.new()
	_skeleton.name = "Skeleton2D"
	_skeleton.unique_name_in_owner = true
	_root.add_child(_skeleton)
	for bone_name: String in BONES:
		_add_bone(bone_name)
	for part: Array in PARTS:
		_add_part(part[0], part[1])
	var player: AnimationPlayer = AnimationPlayer.new()
	player.name = "Anim"
	player.unique_name_in_owner = true
	_root.add_child(player)
	var library: AnimationLibrary = AnimationLibrary.new()
	library.add_animation(&"idle", _idle())
	library.add_animation(&"walk", _walk())
	library.add_animation(&"attack", _attack())
	library.add_animation(&"dash", _dash())
	library.add_animation(&"death", _death())
	player.add_animation_library(&"", library)
	_own(_root, _root)
	var scene: PackedScene = PackedScene.new()
	scene.pack(_root)
	print("saved ", OUT, " ", ResourceSaver.save(scene, OUT))
	quit()


func _own(node: Node, owner_node: Node) -> void:
	for child: Node in node.get_children():
		child.owner = owner_node
		_own(child, owner_node)


func _add_bone(bone_name: String) -> void:
	var bone: Bone2D = Bone2D.new()
	bone.name = bone_name
	# Skinned polygons need no bone length; with it on, every leaf bone warns that it has no child bone.
	bone.auto_calculate_length_and_angle = false
	var parent_name: String = BONES[bone_name][0]
	var joint: Vector2 = BONES[bone_name][1]
	var parent: Node = _skeleton if parent_name.is_empty() else _bones[parent_name]
	var parent_joint: Vector2 = FEET if parent_name.is_empty() else BONES[parent_name][1]
	parent.add_child(bone)
	bone.position = (joint - parent_joint) * SCALE
	bone.rest = Transform2D(0.0, bone.position)
	_bones[bone_name] = bone


## One polygon (a quad over the part's texture) skinned to its bone. Polygon2D draws in tree order, so the SVG's layering is kept.
func _add_part(part: String, bone_name: String) -> void:
	var texture: Texture2D = load(PARTS_DIR + part + ".svg")
	var size: Vector2 = texture.get_size()
	var poly: Polygon2D = Polygon2D.new()
	poly.name = part.to_pascal_case()
	poly.texture = texture
	var drawn: Vector2 = size * (SCALE / IMPORT_SCALE)
	poly.polygon = PackedVector2Array([Vector2.ZERO, Vector2(drawn.x, 0), drawn, Vector2(0, drawn.y)])
	poly.uv = PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
	poly.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	# The SVG's origin sits at (-FEET * SCALE) from the rig's origin (the feet).
	poly.position = -FEET * SCALE
	_root.add_child(poly)
	if not bone_name.is_empty():
		poly.skeleton = NodePath("../Skeleton2D")
		poly.add_bone(NodePath(_bone_path(bone_name)), PackedFloat32Array([1.0, 1.0, 1.0, 1.0]))


func _bone_path(bone_name: String) -> String:
	var path: String = bone_name
	var parent: String = BONES[bone_name][0]
	while not parent.is_empty():
		path = parent + "/" + path
		parent = BONES[parent][0]
	return path


# ------------------------------------------------------------------------------------------------ animations

func _full_path(bone_name: String) -> String:
	return "Skeleton2D/" + _bone_path(bone_name)


func _rest(bone_name: String) -> Vector2:
	return (_bones[bone_name] as Bone2D).position


## A track on `bone_name`'s `property` with `values` at `times` (position values are offsets from the bone's rest position).
func _track(anim: Animation, bone_name: String, property: String, times: Array, values: Array) -> void:
	var index: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(index, NodePath("%s:%s" % [_full_path(bone_name), property]))
	anim.track_set_interpolation_type(index, Animation.INTERPOLATION_CUBIC if anim.loop_mode == Animation.LOOP_LINEAR else Animation.INTERPOLATION_LINEAR)
	for i: int in times.size():
		var value: Variant = values[i]
		if property == "position":
			value = _rest(bone_name) + (value as Vector2)
		anim.track_insert_key(index, times[i], value)


func _make(length: float, looped: bool) -> Animation:
	var anim: Animation = Animation.new()
	anim.length = length
	anim.loop_mode = Animation.LOOP_LINEAR if looped else Animation.LOOP_NONE
	return anim


## Breathing, 0.8 s like the pixel idle (4 frames at 5 fps).
func _idle() -> Animation:
	var a: Animation = _make(0.8, true)
	var t: Array = [0.0, 0.4, 0.8]
	_track(a, "Torso", "position", t, [Vector2.ZERO, Vector2(0, -0.9), Vector2.ZERO])
	_track(a, "Head", "position", t, [Vector2.ZERO, Vector2(0, -0.6), Vector2.ZERO])
	_track(a, "Head", "rotation", t, [0.0, 0.025, 0.0])
	_track(a, "ArmSword", "rotation", t, [0.0, 0.04, 0.0])
	_track(a, "Sword", "rotation", t, [0.0, 0.03, 0.0])
	_track(a, "ArmShield", "rotation", t, [0.0, -0.035, 0.0])
	return a


## A front-on step, 6 frames at 11 fps: the body bobs twice, each leg lifts in turn, the arms and head counter-swing.
func _walk() -> Animation:
	var a: Animation = _make(6.0 / 11.0, true)
	var t: Array = [0.0, 0.136, 0.273, 0.409, 0.545]
	_track(a, "Hip", "position", t, [Vector2.ZERO, Vector2(0, -1.6), Vector2.ZERO, Vector2(0, -1.6), Vector2.ZERO])
	_track(a, "LegL", "position", t, [Vector2.ZERO, Vector2(0, -3.2), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	_track(a, "LegR", "position", t, [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2(0, -3.2), Vector2.ZERO])
	_track(a, "LegL", "rotation", t, [0.0, 0.1, 0.0, -0.04, 0.0])
	_track(a, "LegR", "rotation", t, [0.0, -0.04, 0.0, 0.1, 0.0])
	_track(a, "Torso", "rotation", t, [0.0, 0.035, 0.0, -0.035, 0.0])
	_track(a, "Head", "rotation", t, [0.0, -0.04, 0.0, 0.04, 0.0])
	_track(a, "ArmSword", "rotation", t, [0.0, 0.2, 0.0, -0.2, 0.0])
	_track(a, "Sword", "rotation", t, [0.0, 0.06, 0.0, -0.06, 0.0])
	_track(a, "ArmShield", "rotation", t, [0.0, -0.12, 0.0, 0.12, 0.0])
	return a


## The swing, 0.2 s like the pixel attack (4 frames at 20 fps): the sword arm winds up overhead, chops down and recovers; the
## body twists into it and the shield arm guards.
func _attack() -> Animation:
	var a: Animation = _make(0.2, false)
	var t: Array = [0.0, 0.06, 0.12, 0.2]
	_track(a, "ArmSword", "rotation", t, [0.0, 2.5, -0.35, 0.0])
	_track(a, "Sword", "rotation", t, [0.0, 0.35, -0.6, 0.0])
	_track(a, "Torso", "rotation", t, [0.0, -0.1, 0.15, 0.0])
	_track(a, "Hip", "position", t, [Vector2.ZERO, Vector2(0, 0.6), Vector2(0, 2.2), Vector2.ZERO])
	_track(a, "Head", "rotation", t, [0.0, -0.06, 0.1, 0.0])
	_track(a, "ArmShield", "rotation", t, [0.0, 0.35, -0.25, 0.0])
	return a


## The dash: a crouched lunge with the arms swept back (held while the dash lasts).
func _dash() -> Animation:
	var a: Animation = _make(0.16, true)
	var t: Array = [0.0, 0.16]
	_track(a, "Hip", "position", t, [Vector2(0, 3.0), Vector2(0, 3.0)])
	_track(a, "Torso", "rotation", t, [0.14, 0.14])
	_track(a, "Head", "rotation", t, [-0.1, -0.1])
	_track(a, "ArmSword", "rotation", t, [0.7, 0.7])
	_track(a, "ArmShield", "rotation", t, [-0.7, -0.7])
	_track(a, "LegL", "rotation", t, [0.25, 0.25])
	_track(a, "LegR", "rotation", t, [-0.25, -0.25])
	return a


## Falls over backwards and stays down.
func _death() -> Animation:
	var a: Animation = _make(0.5, false)
	var index: int = a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(index, NodePath(".:rotation"))
	a.track_insert_key(index, 0.0, 0.0)
	a.track_insert_key(index, 0.45, 1.45)
	_track(a, "ArmSword", "rotation", [0.0, 0.3], [0.0, -0.8])
	_track(a, "ArmShield", "rotation", [0.0, 0.3], [0.0, 0.8])
	return a
