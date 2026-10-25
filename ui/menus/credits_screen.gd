class_name CreditsScreen
extends CanvasLayer
## The credits (M13), from the title: who made the game, how, and what it stands on. A modal that scrolls
## slowly by itself (the mouse wheel and the keys take over); Esc or Close ends it. Display and intents only.

signal closed

## Seconds the text takes to scroll from top to bottom if left alone.
@export var scroll_seconds: float = 60.0

const TITLE: String = "LAST STAND"
## One block per paragraph; a line starting with "# " is a heading.
const BLOCKS: Array[String] = [
	"# A game by Tony",
	"Designed, drawn, composed and built in 2026, with Claude as the programming partner.",
	"# Made with",
	"Godot 4.7 and GDScript. No add-ons, no plug-ins, no outside assets: every sprite, every sound and every note of music was drawn or synthesized in code (tools/art, tools/audio in the project).",
	"# Heroes",
	"Ser Aldric, the Knight. Wren, the Huntress. Maren, the Necromancer.",
	"# The people of Last Light",
	"Quartermaster Dunmore. Sister Ilse. Orm the smith.",
	"# The dead of Vael",
	"Thirty-three kinds of the Waking, nine places they hold, and the bells that never stopped ringing.",
	"# Thanks",
	"To everyone who played a build and wrote down what felt wrong.",
	"# Licence",
	"This game uses the Godot Engine, available under the MIT licence: Copyright (c) 2014-present Godot Engine contributors; Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.",
]

var _elapsed: float = 0.0

@onready var _scroll: ScrollContainer = %Scroll
@onready var _text: VBoxContainer = %Text
@onready var _close: Button = %CloseButton


func _ready() -> void:
	hide()
	_close.pressed.connect(close)
	_build()


func _process(delta: float) -> void:
	if not visible:
		return
	_elapsed += delta
	var bar: ScrollBar = _scroll.get_v_scroll_bar()
	_scroll.scroll_vertical = roundi(bar.max_value * clampf(_elapsed / scroll_seconds, 0.0, 1.0))


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func open() -> void:
	_elapsed = 0.0
	_scroll.scroll_vertical = 0
	Music.play(self, &"credits")
	show()
	_close.grab_focus.call_deferred()


func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


## The blocks shown (tests).
func get_block_count() -> int:
	return _text.get_child_count()


func _build() -> void:
	for block: String in BLOCKS:
		var label: Label = Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if block.begins_with("# "):
			label.text = block.trim_prefix("# ")
			label.theme_type_variation = &"HeaderLabel"
		else:
			label.text = block
			label.theme_type_variation = &"DimLabel"
		_text.add_child(label)
