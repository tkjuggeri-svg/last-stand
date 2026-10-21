extends Node
## Sandbox (F6): the front-end screens on their own (title, War Room, run summary), on a throwaway save
## (user://sandbox_save.json) with 300 Soul Shards to spend. Starting a run shows a made-up summary.

const SAVE_PATH: String = "user://sandbox_save.json"

@onready var _front_end: FrontEnd = %FrontEnd


func _ready() -> void:
	var save: SaveManagerNode = get_node("/root/SaveManager")
	save.use_file(SAVE_PATH)
	save.profile.shards = maxi(save.profile.shards, 300)
	_front_end.run_requested.connect(_show_made_up_summary)
	_front_end.continue_requested.connect(_show_made_up_summary)
	_front_end.quit_requested.connect(func() -> void: get_tree().quit())
	_front_end.show_title()


func _show_made_up_summary() -> void:
	_front_end.show_summary({"result": "lost", "chapter": 1, "row": 6, "seed": 1234, "path": ["battle", "battle", "elite", "merchant"],
		"kills": 212, "waves": 9, "minutes": 7.5, "cards": ["berserker", "battle_rhythm"], "relics": ["hourglass"],
		"shard_lines": [["4 battles won", 8], ["1 elite beaten", 6]], "shards": 14})
