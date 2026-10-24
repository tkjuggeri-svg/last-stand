class_name RunIconsRow
extends HFlowContainer
## A row of the run's upgrade icons in the HUD: the cards taken (a stacked one shows "xN"), or, with
## `relics`, the relics (on their own row). Hover an icon: its name and what it does. Display only.

## Show the relics instead of the cards.
@export var relics: bool = false

var _modifiers: RunModifiers
## The card row's first entry: the archetype the run leans on ("Fire build"), hidden below two of a tag.
var _build: Label


## Follows `modifiers` from now on (and shows what it already has).
func setup(modifiers: RunModifiers) -> void:
	_modifiers = modifiers
	visible = modifiers != null
	if modifiers == null:
		return
	if not relics:
		_build = Label.new()
		_build.name = "Build"
		_build.theme_type_variation = &"DimLabel"
		add_child(_build)
	modifiers.upgrade_added.connect(_on_added)
	modifiers.upgrade_removed.connect(_on_removed)
	for data: UpgradeData in modifiers.get_taken():
		_on_added(data, modifiers.get_stacks(data.id))
	_update_build()


## The archetype label follows the run's cards and relics (the card row shows it, the relic row's count too).
func _update_build() -> void:
	if _build == null:
		return
	var tag: StringName = Archetypes.leading(_modifiers)
	_build.visible = tag != &""
	_build.text = Archetypes.label(tag) if tag != &"" else ""


func _shows(data: UpgradeData) -> bool:
	return (data is RelicData) == relics


func _on_added(data: UpgradeData, stacks: int) -> void:
	_update_build()
	if not _shows(data):
		return
	var existing: Node = get_node_or_null(NodePath(String(data.id)))
	if existing != null:
		(existing.get_node("Count") as Label).text = "x%d" % stacks
		return
	var icon: TextureRect = TextureRect.new()
	icon.name = String(data.id)
	icon.texture = data.icon
	icon.custom_minimum_size = Vector2(32, 32)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.tooltip_text = "%s%s\n%s" % ["Relic: " if relics else "", data.display_name, data.description]
	var count: Label = Label.new()
	count.name = "Count"
	count.position = Vector2(14, 10)
	icon.add_child(count)
	add_child(icon)


func _on_removed(data: UpgradeData, stacks: int) -> void:
	_update_build()
	if not _shows(data):
		return
	var existing: Node = get_node_or_null(NodePath(String(data.id)))
	if existing != null:
		if stacks <= 0:
			existing.queue_free()
		else:
			(existing.get_node("Count") as Label).text = "x%d" % stacks if stacks > 1 else ""
