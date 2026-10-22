class_name UiSounds
extends Node
## Gives every button in the game its sounds (M8.5), wherever it is and whenever it is made: a click
## when pressed (the screen's main action, a ButtonPrimary, a brighter confirm) and a quiet tick when
## the mouse comes onto one that can be pressed. Main has one; screens need nothing for it.


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	for node: Node in get_tree().root.find_children("*", "BaseButton", true, false):
		_on_node_added(node)


func _on_node_added(node: Node) -> void:
	var button: BaseButton = node as BaseButton
	if button == null:
		return
	button.pressed.connect(func() -> void:
		Sfx.play(self, &"ui_confirm" if button.theme_type_variation == &"ButtonPrimary" else &"ui_click"))
	button.mouse_entered.connect(func() -> void:
		if not button.disabled:
			Sfx.play(self, &"ui_hover"))
