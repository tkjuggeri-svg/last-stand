class_name RunSummaryScreen
extends CanvasLayer
## The end of a run (M8), after Game Over or Victory: how it ended and where, the seed, the path, the
## kills, waves and time, the cards and relics taken, and the Soul Shards it paid, line by line. Then
## to the War Room or straight into a new run. Display and intents only (the summary is RunSummary's
## dictionary with Main's shard lines).

signal hub_requested
signal new_run_requested

const RESULT_TITLES: Dictionary = {"won": "Victory", "lost": "The fortress has fallen", "abandoned": "Run abandoned"}
const CARD_ICONS: String = "res://assets/sprites/ui/upgrades/%s.png"
const RELIC_ICONS: String = "res://assets/sprites/ui/relics/%s.png"

@onready var _frame: ScreenFrame = %Frame
@onready var _where: Label = %Where
@onready var _stats: Label = %Stats
@onready var _icons: HFlowContainer = %Icons
@onready var _lines: VBoxContainer = %Lines
@onready var _total: Label = %Total
@onready var _hub_button: Button = %HubButton
@onready var _new_run_button: Button = %NewRunButton


func _ready() -> void:
	hide()
	_hub_button.pressed.connect(func() -> void: hub_requested.emit())
	_new_run_button.pressed.connect(func() -> void: new_run_requested.emit())


func open(summary: Dictionary) -> void:
	_frame.title = RESULT_TITLES.get(String(summary.get("result", "lost")), "The run is over")
	_where.text = "Chapter %d, row %d   -   seed %d" % [int(summary.get("chapter", 1)), int(summary.get("row", 0)), int(summary.get("seed", 0))]
	var path: Array = summary.get("path", [])
	_stats.text = "Hero: %s\nPath: %s\nKills: %d   Waves: %d   Time: %.1f min" % [
		String(summary.get("hero", "knight")).capitalize(),
		" > ".join(path.map(func(kind: Variant) -> String: return String(kind).capitalize())) if not path.is_empty() else "-",
		int(summary.get("kills", 0)), int(summary.get("waves", 0)), float(summary.get("minutes", 0.0))]
	for child: Node in _icons.get_children():
		child.queue_free()
	for id: Variant in summary.get("cards", []):
		_add_icon(CARD_ICONS % id, String(id))
	for id: Variant in summary.get("relics", []):
		_add_icon(RELIC_ICONS % id, "Relic: %s" % id)
	for child: Node in _lines.get_children():
		child.queue_free()
	for line: Variant in summary.get("shard_lines", []):
		var row: Label = Label.new()
		row.text = "%s   +%d" % [(line as Array)[0], int((line as Array)[1])]
		_lines.add_child(row)
	if (summary.get("shard_lines", []) as Array).is_empty():
		var none: Label = Label.new()
		none.theme_type_variation = &"DimLabel"
		none.text = "Nothing this time. Win a battle to earn Soul Shards."
		_lines.add_child(none)
	_total.text = "Soul Shards earned: %d" % int(summary.get("shards", 0))
	show()
	_hub_button.grab_focus.call_deferred()


func get_hub_button() -> Button:
	return _hub_button


func get_total_text() -> String:
	return _total.text


func _add_icon(path: String, tip: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var icon: TextureRect = TextureRect.new()
	icon.texture = load(path)
	icon.custom_minimum_size = Vector2(32, 32)
	icon.tooltip_text = tip
	_icons.add_child(icon)
