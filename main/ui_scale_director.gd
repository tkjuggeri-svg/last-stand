class_name UiScaleDirector
extends Node
## Applies the player's interface size (GameSettings.get_ui_scale) to every CanvasLayer in the
## `ui_scaled` group: its controls move into a UiScaleFrame (made when first needed, so the default
## size never touches the layers). Main owns one; it watches the setting like Display watches smooth
## scaling, and meets layers created later (a chapter's HUD) as they enter the tree.

var _applied: float = 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # the setting is changed from the pause menu
	_applied = GameSettings.get_ui_scale()
	get_tree().node_added.connect(_on_node_added)
	apply_all()


func _process(_delta: float) -> void:
	if not is_equal_approx(GameSettings.get_ui_scale(), _applied):
		_applied = GameSettings.get_ui_scale()
		apply_all()


func apply_all() -> void:
	for node: Node in get_tree().get_nodes_in_group(Groups.UI_SCALED):
		_apply(node as CanvasLayer)


## The frame of `layer`, or null while it has none.
static func frame_of(layer: CanvasLayer) -> UiScaleFrame:
	for child: Node in layer.get_children():
		if child is UiScaleFrame:
			return child as UiScaleFrame
	return null


func _on_node_added(node: Node) -> void:
	if node is CanvasLayer and node.is_in_group(Groups.UI_SCALED) and not is_equal_approx(_applied, 1.0):
		_apply.call_deferred(node)  # the tree is still adding children


func _apply(layer: CanvasLayer) -> void:
	if layer == null or not layer.is_inside_tree():
		return
	var frame: UiScaleFrame = frame_of(layer)
	if frame == null:
		if is_equal_approx(_applied, 1.0):
			return
		frame = UiScaleFrame.new()
		layer.add_child(frame)
		layer.move_child(frame, 0)
		for child: Node in layer.get_children():
			if child is Control and child != frame:
				child.reparent(frame, false)
	frame.set_factor(_applied)
