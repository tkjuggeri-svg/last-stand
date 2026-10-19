class_name BuildSlot
extends Node2D
## A fixed place where exactly one tower can stand. Shows a stone pad, glows while the hero is close
## (with an "E" prompt) and can draw the tower's range. Building and selling rules live in TowerBuilder.

signal hero_entered(slot: BuildSlot)
signal hero_exited(slot: BuildSlot)

const RANGE_COLOR: Color = Color(0.95, 0.85, 0.5, 0.55)
const DUST_SCENE: PackedScene = preload("res://entities/effects/dust_puff.tscn")
const DISMANTLE_SCENE: PackedScene = preload("res://entities/towers/tower_dismantle.tscn")

## The tower standing here, or null.
var tower: Tower = null

var _range_radius: float = 0.0

@onready var _pad: Sprite2D = %Pad
@onready var _prompt: Label = %Prompt
@onready var _interact_area: Area2D = %InteractArea


func _ready() -> void:
	_interact_area.body_entered.connect(func(_body: Node2D) -> void: hero_entered.emit(self))
	_interact_area.body_exited.connect(func(_body: Node2D) -> void: hero_exited.emit(self))
	set_highlighted(false)


func is_empty() -> bool:
	return tower == null


func place(new_tower: Tower) -> void:
	assert(is_empty(), "BuildSlot already has a tower: %s" % name)
	tower = new_tower
	add_child(new_tower)
	_update_prompt()
	_puff()


## Takes the tower off the slot and returns it (the caller frees it). Returns null if empty, so a
## second call can never hand out the same tower twice.
func remove_tower() -> Tower:
	var removed: Tower = tower
	tower = null
	if removed != null:
		removed.deactivate()
		remove_child(removed)
		_dismantle(removed.data)
		_puff()
	_update_prompt()
	return removed


## Glow and show the "E" prompt while the hero is close.
func set_highlighted(highlighted: bool) -> void:
	_pad.frame = 1 if highlighted else 0
	_prompt.visible = highlighted
	_update_prompt()


## Draws a range ring (0 hides it).
func show_range(radius: float) -> void:
	_range_radius = radius
	queue_redraw()


## A dust cloud when a tower goes up or comes down (display only).
func _puff() -> void:
	var dust: Node2D = DUST_SCENE.instantiate()
	dust.position = Vector2(0, 4)
	add_child(dust)


## The sold tower is gone at once; this effect shows it being taken down into rubble (display only).
func _dismantle(tower_data: TowerData) -> void:
	if tower_data == null:
		return
	var effect: Node2D = DISMANTLE_SCENE.instantiate()
	var sprite: AnimatedSprite2D = effect.get_node("%Sprite")
	var anim: StringName = StringName("%s_sell" % tower_data.id)
	if not sprite.sprite_frames.has_animation(anim):
		effect.free()
		return
	sprite.animation = anim
	add_child(effect)


func _update_prompt() -> void:
	if _prompt != null:
		_prompt.text = "E  Build" if is_empty() else "E  " + tower.data.display_name


func _draw() -> void:
	if _range_radius <= 0.0:
		return
	# A dashed ring, drawn in 2 px segments so it matches the pixel art.
	var segments: int = 64
	for i: int in segments:
		if i % 2 == 1:
			continue
		var a: float = TAU * i / segments
		var b: float = TAU * (i + 1) / segments
		draw_line(Vector2.from_angle(a) * _range_radius, Vector2.from_angle(b) * _range_radius, RANGE_COLOR, 2.0)
