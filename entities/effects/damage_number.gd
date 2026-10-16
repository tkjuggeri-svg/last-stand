class_name DamageNumber
extends Node2D
## A short floating number ("-10" damage, "+10" gold) that rises, fades and removes itself. Display only.

const RISE: float = 22.0
const DURATION: float = 0.8

func _ready() -> void:
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y - RISE, DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, DURATION * 0.5).set_delay(DURATION * 0.5)
	tween.chain().tween_callback(queue_free)


## Damage taken. Call before adding it to the tree.
func set_amount(amount: int) -> void:
	%Label.text = "-%d" % amount


## Any short text in a colour (e.g. "+10" in gold). Call before adding it to the tree.
func set_text(text: String, color: Color) -> void:
	%Label.text = text
	(%Label as Label).add_theme_color_override("font_color", color)
