class_name ChapterScreen
extends CanvasLayer
## Between two chapters: the chapter cleared, what carries over (gold with the towers packed up for
## part of what they cost, the fortress's repair, the lives left, the upgrades) and the next chapter's
## name, with a Continue button. Display only: Main moves the run on.

signal continued
## One of the roads offered was taken (its index in the `roads` given to open()).
signal road_chosen(index: int)

const LINES: String = "Your towers are packed up for %d%% of what they cost: +%d gold (%d in all).\nThe fortress is repaired by %d%%: %d / %d HP.\nLives left: %d.   Upgrades kept: %d.\n\nNext: %s"

@onready var _title: Label = %Title
@onready var _text: Label = %Text
@onready var _continue_button: Button = %ContinueButton
## The road cards (built when two roads are offered).
var _roads: VBoxContainer


func _ready() -> void:
	hide()
	_continue_button.pressed.connect(func() -> void:
		hide()
		continued.emit())


## Shows chapter `cleared` done and what `carry` takes into `next` (the fortress at `health` / `max_health`
## after its `repair` share). With two `roads` (biomes of the next tier) the player picks one instead of
## pressing Continue.
func open(cleared: String, next: String, carry: ChapterCarry, refund_ratio: float, repair: float, health: int, max_health: int,
		roads: Array[ChapterData] = []) -> void:
	_title.text = "%s cleared!" % cleared
	Sfx.play(self, &"chapter_clear")
	var choosing: bool = roads.size() > 1
	_text.text = LINES % [roundi(refund_ratio * 100.0), carry.refund, carry.gold, roundi(repair * 100.0), health, max_health, carry.lives_left, carry.upgrades.size(),
		"choose your road" if choosing else next]
	_show_roads(roads)
	_continue_button.visible = not choosing
	show()
	_focus_first.call_deferred()


## Keyboard focus on the first road (or Continue), if the screen is still up when this runs.
func _focus_first() -> void:
	if not visible:
		return
	if _roads != null and _roads.visible and _roads.get_child_count() > 0:
		_roads.get_child(0).grab_focus()
	else:
		_continue_button.grab_focus()


## The button of road `index` (tests).
func get_road_button(index: int) -> Button:
	return _roads.get_child(index) as Button if _roads != null and index < _roads.get_child_count() else null


func _show_roads(roads: Array[ChapterData]) -> void:
	if _roads == null:
		_roads = VBoxContainer.new()
		_roads.add_theme_constant_override("separation", 10)
		_continue_button.get_parent().add_child(_roads)
		_continue_button.get_parent().move_child(_roads, _continue_button.get_index())
	for child: Node in _roads.get_children():
		_roads.remove_child(child)
		child.queue_free()
	_roads.visible = roads.size() > 1
	if roads.size() < 2:
		return
	for i: int in roads.size():
		var button: Button = Button.new()
		button.name = String(roads[i].id)
		button.text = "%s\n%s\nMechanic: %s\n%s" % [roads[i].display_name, roads[i].blurb, roads[i].mechanic_text, roads[i].difficulty_note]
		button.custom_minimum_size = Vector2(0, 150)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func() -> void:
			hide()
			road_chosen.emit(i))
		_roads.add_child(button)


func get_continue_button() -> Button:
	return _continue_button
