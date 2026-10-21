class_name GameOverScreen
extends CanvasLayer
## Shown when the run is lost. It only reports the player's choice; Main decides what restarting means.

signal restart_requested

@onready var _restart_button: Button = %RestartButton
@onready var _subtitle: Label = %Subtitle
@onready var _seed_label: Label = %SeedLabel


func _ready() -> void:
	_restart_button.pressed.connect(_on_restart_button_pressed)


## Shows the screen with why the run was lost and the run's seed (-1: none shown), and focuses Restart
## (Enter/Space work as well as the mouse).
func open(subtitle: String, run_seed: int = -1) -> void:
	_subtitle.text = subtitle
	_seed_label.text = "Seed %d" % run_seed if run_seed >= 0 else ""
	show()
	_restart_button.grab_focus()


## The button's text (Main: "Continue" when the run summary follows).
func set_button_text(text: String) -> void:
	_restart_button.text = text


func _on_restart_button_pressed() -> void:
	restart_requested.emit()
