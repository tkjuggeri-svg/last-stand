class_name ChapterScreen
extends CanvasLayer
## Between two chapters: the chapter cleared, what carries over (gold with the towers packed up for
## part of what they cost, the fortress's repair, the lives left, the upgrades) and the next chapter's
## name, with a Continue button. Display only: Main moves the run on.

signal continued

const LINES: String = "Your towers are packed up for %d%% of what they cost: +%d gold (%d in all).\nThe fortress is repaired by %d%%: %d / %d HP.\nLives left: %d.   Upgrades kept: %d.\n\nNext: %s"

@onready var _title: Label = %Title
@onready var _text: Label = %Text
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	hide()
	_continue_button.pressed.connect(func() -> void:
		hide()
		continued.emit())


## Shows chapter `cleared` done and what `carry` takes into `next` (the fortress at `health` / `max_health`
## after its `repair` share).
func open(cleared: String, next: String, carry: ChapterCarry, refund_ratio: float, repair: float, health: int, max_health: int) -> void:
	_title.text = "%s cleared!" % cleared
	Sfx.play(self, &"chapter_clear")
	_text.text = LINES % [roundi(refund_ratio * 100.0), carry.refund, carry.gold, roundi(repair * 100.0), health, max_health, carry.lives_left, carry.upgrades.size(), next]
	show()
	_continue_button.grab_focus.call_deferred()


func get_continue_button() -> Button:
	return _continue_button
