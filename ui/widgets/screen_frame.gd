class_name ScreenFrame
extends Control
## The shared full-screen frame of the front-end screens (M8's UI style): a dark backdrop, a centred
## panel with the screen's title, its content (%Content) and a row of buttons at the bottom (%Footer).
## Screens put their own controls in Content and Footer; the look comes from the project theme's type
## variations (TitleLabel, HeaderLabel, DimLabel, ButtonPrimary, CardPanel).

@export var title: String = "":
	set(value):
		title = value
		if is_node_ready():
			_title.text = value

@onready var _title: Label = %Title


func _ready() -> void:
	_title.text = title


func get_content() -> VBoxContainer:
	return %Content


func get_footer() -> HBoxContainer:
	return %Footer
