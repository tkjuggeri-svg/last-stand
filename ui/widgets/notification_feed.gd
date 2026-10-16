class_name NotificationFeed
extends VBoxContainer
## A short list of messages that fade out on their own. Newest at the bottom; display only.

@export var message_duration: float = 2.0
@export var fade_duration: float = 0.5
@export var max_messages: int = 4


func push(text: String, color: Color = Color.WHITE) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_color_override("font_color", color)
	add_child(label)
	while get_child_count() > max_messages:
		var oldest: Node = get_child(0)
		remove_child(oldest)
		oldest.queue_free()
	# The tween belongs to the label, so it stops if the label is removed early.
	var tween: Tween = label.create_tween()
	tween.tween_interval(message_duration)
	tween.tween_property(label, "modulate:a", 0.0, fade_duration)
	tween.tween_callback(label.queue_free)
