class_name BuildSlot
extends Node2D
## A fixed place where exactly one tower can stand. Shows a stone pad, glows while the hero is close
## (with an "E" prompt) and draws range rings: the ones the build menu asks for (one, or two side by
## side for an evolution choice, each with its own colour and dead zone), or its tower's range while
## the mouse is over the slot. Building and selling rules live in TowerBuilder.

signal hero_entered(slot: BuildSlot)
signal hero_exited(slot: BuildSlot)

const RANGE_COLOR: Color = Color(0.95, 0.85, 0.5, 0.55)
## Pair-bonus links (TowerSynergy) in the build menu.
const LINK_COLOR: Color = Color(0.55, 0.9, 1.0, 0.9)
const DUST_SCENE: PackedScene = preload("res://entities/effects/dust_puff.tscn")
const DISMANTLE_SCENE: PackedScene = preload("res://entities/towers/tower_dismantle.tscn")
## The mouse-over area (slot-local px): the pad and the tower standing on it.
const HOVER_RECT: Rect2 = Rect2(-30, -96, 60, 116)

## The tower standing here, or null.
var tower: Tower = null

## Rings requested by the build menu: [outer radius, inner radius (dead zone, 0 = none), colour].
var _menu_rings: Array = []
## Pair-bonus links to draw while the build menu is open here (global positions of partner towers).
var _links: Array[Vector2] = []
var _hovered: bool = false

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


## Draws a range ring (0 hides it) while the build menu is open here.
func show_range(radius: float) -> void:
	show_rings([[radius, 0.0, RANGE_COLOR]] if radius > 0.0 else [])


## Draws several rings at once ([outer, inner, colour] each; empty hides them).
func show_rings(rings: Array) -> void:
	_menu_rings = rings
	queue_redraw()


## Draws a dashed link to each of `points` (partner towers' global positions; empty hides them).
func show_links(points: Array[Vector2]) -> void:
	_links = points
	queue_redraw()


func get_links() -> Array[Vector2]:
	return _links


## Mouse-over: the ring of the tower standing here (called every frame with the mouse position).
func update_hover(mouse_world: Vector2) -> void:
	var hovered: bool = HOVER_RECT.has_point(to_local(mouse_world))
	if hovered != _hovered:
		_hovered = hovered
		queue_redraw()


func is_hovered() -> bool:
	return _hovered


## The radius of the (first) ring being drawn (0 = none).
func get_shown_range() -> float:
	if not _menu_rings.is_empty():
		return _menu_rings[0][0]
	return tower.get_attack_range() if _hovered and tower != null else 0.0


## Every ring being drawn: the menu's, else the hovered tower's (with its dead zone).
func get_shown_rings() -> Array:
	if not _menu_rings.is_empty():
		return _menu_rings
	if _hovered and tower != null:
		return [[tower.get_attack_range(), tower.get_min_range(), RANGE_COLOR]]
	return []


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
	if tower_data.frames != null:
		sprite.sprite_frames = tower_data.frames
	if not sprite.sprite_frames.has_animation(anim):
		effect.free()
		return
	sprite.animation = anim
	add_child(effect)


func _process(_delta: float) -> void:
	update_hover(get_global_mouse_position())


func _update_prompt() -> void:
	if _prompt != null:
		_prompt.text = "E  Build" if is_empty() else "E  " + tower.data.display_name


func _draw() -> void:
	for point: Vector2 in _links:
		_draw_link(to_local(point))
	for ring: Array in get_shown_rings():
		_draw_ring(ring[0], ring[2])
		if ring[1] > 0.0:
			_draw_ring(ring[1], Color(ring[2], ring[2].a * 0.6))


## A dashed ring, drawn in 2 px segments so it matches the pixel art (more dashes for big rings).
func _draw_ring(radius: float, color: Color) -> void:
	if radius <= 0.0:
		return
	var segments: int = maxi(64, roundi(radius / 6.0) * 2)
	for i: int in range(0, segments, 2):
		var a: float = TAU * i / segments
		var b: float = TAU * (i + 1) / segments
		draw_line(Vector2.from_angle(a) * radius, Vector2.from_angle(b) * radius, color, 2.0)


## A dashed line from the pad to `to` (a partner tower), in 2 px dashes like the rings.
func _draw_link(to: Vector2) -> void:
	var steps: int = maxi(2, roundi(to.length() / 8.0))
	for i: int in range(0, steps, 2):
		draw_line(to * (float(i) / steps), to * (float(i + 1) / steps), LINK_COLOR, 2.0)
