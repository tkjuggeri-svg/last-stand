class_name MapScreen
extends CanvasLayer
## The run map between fights: the chapter's title, the run's status (gold, fortress HP, lives), the
## node map (MapView) with an icon per node. The nodes the player may go to next pulse and can be
## picked with the mouse or the keyboard; the others are dimmed, the path taken is marked. Hovering a
## node says what it is (an elite also its twist). Display and intents only: Main plays the node.

signal node_chosen(node: MapNode)

const ICONS: Dictionary = {
	RunMap.Kind.BATTLE: preload("res://assets/sprites/ui/map/node_battle.png"),
	RunMap.Kind.ELITE: preload("res://assets/sprites/ui/map/node_elite.png"),
	RunMap.Kind.EVENT: preload("res://assets/sprites/ui/map/node_event.png"),
	RunMap.Kind.SHRINE: preload("res://assets/sprites/ui/map/node_shrine.png"),
	RunMap.Kind.MERCHANT: preload("res://assets/sprites/ui/map/node_merchant.png"),
	RunMap.Kind.BOSS: preload("res://assets/sprites/ui/map/node_boss.png"),
}
const NAMES: Dictionary = {
	RunMap.Kind.BATTLE: "Battle",
	RunMap.Kind.ELITE: "Elite",
	RunMap.Kind.EVENT: "Event",
	RunMap.Kind.SHRINE: "Shrine",
	RunMap.Kind.MERCHANT: "Merchant",
	RunMap.Kind.BOSS: "Boss",
}
const DIM: Color = Color(0.68, 0.64, 0.74, 0.9)
const VISITED: Color = Color(0.7, 0.66, 0.6, 1)
const PULSE_SPEED: float = 4.0

var _map: RunMap
var _buttons: Dictionary = {}
var _time: float = 0.0

@onready var _view: MapView = %MapView
@onready var _title: Label = %Title
@onready var _status: Label = %Status
@onready var _info: Label = %Info


func _ready() -> void:
	hide()
	_view.resized.connect(_place_buttons)


func _process(delta: float) -> void:
	if not visible or _map == null:
		return
	_time += delta
	_view.time = _time
	_view.pulse = 0.5 + 0.5 * sin(_time * PULSE_SPEED)


## Shows `map` with the run's status line and lets the player pick the next node.
func open(map: RunMap, title: String, status: String) -> void:
	_map = map
	_title.text = title
	_status.text = status
	_view.map = map
	_view.look = map.chapter.map_look
	for child: Node in _view.get_children():
		child.queue_free()
	_buttons.clear()
	var choices: Array[MapNode] = map.get_choices()
	for node: MapNode in map.nodes:
		var button: TextureButton = TextureButton.new()
		button.texture_normal = ICONS[node.kind]
		button.disabled = not choices.has(node)
		button.focus_mode = Control.FOCUS_ALL if choices.has(node) else Control.FOCUS_NONE
		button.modulate = VISITED if map.path.has(node) else (Color.WHITE if choices.has(node) else DIM)
		button.tooltip_text = describe(node)
		button.pressed.connect(func() -> void: _choose(node))
		button.mouse_entered.connect(func() -> void: _info.text = describe(node))
		button.focus_entered.connect(func() -> void: _info.text = describe(node))
		_view.add_child(button)
		_buttons[node.index] = button
	_info.text = "Choose where to go next."
	show()
	_place_buttons()
	_view.queue_redraw()
	if not choices.is_empty():
		(_buttons[choices[0].index] as Control).grab_focus.call_deferred()


func close() -> void:
	hide()


## The button of a node (for tests).
func get_node_button(node: MapNode) -> TextureButton:
	return _buttons.get(node.index)


## What a node is, for its tooltip and the info line.
static func describe(node: MapNode) -> String:
	var text: String = NAMES[node.kind]
	if node.kind == RunMap.Kind.ELITE:
		if node.encounter != null and node.encounter.leader != null:
			text += ": %s leads it" % node.encounter.leader.display_name
		if node.affix != null:
			text += ". %s: %s" % [node.affix.display_name, node.affix.description]
	elif node.kind == RunMap.Kind.BOSS and node.encounter != null:
		text += ": the chapter's last fight"
	elif node.kind == RunMap.Kind.MERCHANT:
		text += ": buy upgrades, a repair"
	return text


func _choose(node: MapNode) -> void:
	if _map != null and _map.get_choices().has(node):
		Sfx.play(self, &"map_select")
		node_chosen.emit(node)


func _place_buttons() -> void:
	if _map == null:
		return
	for node: MapNode in _map.nodes:
		var button: TextureButton = _buttons.get(node.index)
		if button != null:
			button.position = _view.node_position(node) - button.texture_normal.get_size() * 0.5
	_view.queue_redraw()
