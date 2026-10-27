class_name HeroVectorRig
extends Node2D
## The hero drawn as a vector cutout rig (vector-test branch): a Skeleton2D with the knight's SVG parts, animated by an
## AnimationPlayer (idle, walk, attack, dash, death). Display only: the hero's DirectionalSprite keeps running (hidden) and
## decides what the hero is doing; this node reads its animation name (state and facing), its flip, its tint and its hit flash
## and plays the matching rig animation, so movement, collision and attack timing are untouched. There is no side or back art
## in the SVG: every facing shows the front, mirrored when the sprite faces left.

const FLASH_SHADER: Shader = preload("res://assets/shaders/hit_flash.gdshader")

## The hero's pixel sprite this rig follows.
@export var sprite: DirectionalSprite
## False: the rig is hidden and the pixel sprite shows (a second hero for side-by-side comparisons).
@export var enabled: bool = true:
	set(value):
		enabled = value
		if is_node_ready():
			_apply_enabled()

var _state: StringName = &""
var _last_frame: int = 0
var _flash: ShaderMaterial = ShaderMaterial.new()

@onready var _player: AnimationPlayer = %Anim
@onready var _skeleton: Skeleton2D = %Skeleton2D


func _ready() -> void:
	_flash.shader = FLASH_SHADER
	for child: Node in get_children():
		var part: Polygon2D = child as Polygon2D
		if part != null and part.name != &"Shadow":
			part.material = _flash
	_apply_enabled()


func _process(_delta: float) -> void:
	if not enabled or sprite == null:
		return
	var state: StringName = StringName(String(sprite.animation).get_slice("_", 0))
	# A new swing restarts the sprite's attack animation from frame 0: the rig swings again with it.
	var restarted: bool = state == &"attack" and (_state != &"attack" or sprite.frame < _last_frame)
	if state != _state or restarted:
		_switch_to(state)
	_last_frame = sprite.frame
	scale.x = -1.0 if sprite.flip_h else 1.0
	modulate = sprite.modulate
	var sprite_flash: ShaderMaterial = sprite.material as ShaderMaterial
	if sprite_flash != null:
		_flash.set_shader_parameter("flash", sprite_flash.get_shader_parameter("flash"))


func _apply_enabled() -> void:
	visible = enabled
	if sprite != null:
		sprite.visible = not enabled
	set_process(enabled)


func _switch_to(state: StringName) -> void:
	_state = state
	# Back to the bind pose first: a track an animation doesn't touch must not keep the last one's pose.
	for bone: Node in _skeleton.find_children("*", "Bone2D", true, false):
		(bone as Bone2D).apply_rest()
	rotation = 0.0
	var anim: StringName = state if _player.has_animation(state) else &"idle"
	_player.play(anim)
