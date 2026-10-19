class_name RespawnPoint
extends Marker2D
## Where the fallen hero comes back. Shows the countdown above the spot while a respawn is pending.
## Display only: HeroLives owns the timer and tells it what to show.

@onready var _countdown: Label = %Countdown


func _ready() -> void:
	hide_countdown()


## Shows the seconds left, rounded up ("Hero returns in 4").
func show_countdown(seconds_left: float) -> void:
	_countdown.text = "Hero returns in %d" % ceili(seconds_left)
	_countdown.show()


func hide_countdown() -> void:
	_countdown.hide()
