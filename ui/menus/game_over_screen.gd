class_name GameOverScreen
extends CanvasLayer
## Shown when the run is lost. It only reports the player's choice; Main decides what restarting means.

signal restart_requested

@onready var _restart_button: Button = %RestartButton


func _ready() -> void:
	_restart_button.pressed.connect(_on_restart_button_pressed)


## Shows the screen and focuses Restart, so Enter/Space work as well as the mouse.
func open() -> void:
	show()
	_restart_button.grab_focus()


func _on_restart_button_pressed() -> void:
	restart_requested.emit()
