class_name EvolutionChoice
extends HBoxContainer
## The build menu's evolution choice for a level-3 tower: its two branches side by side, each with
## the evolved tower's icon, name, description, key numbers, price and an Evolve button, and both
## branches' range rings on the slot in the cards' colours (the hovered or focused one brighter).
## Permanent, so the card says so. Display and intents only: TowerBuilder decides.

## Ring and name colours of the two branches.
const COLORS: Array[Color] = [Color(0.95, 0.75, 0.4, 1), Color(0.55, 0.85, 1.0, 1)]
const DIM_ALPHA: float = 0.3
const BRIGHT_ALPHA: float = 0.7
const ERROR_COLOR: Color = UiColors.WARN
const GOLD_COLOR: Color = UiColors.GOLD

var _builder: TowerBuilder
var _slot: BuildSlot
var _options: Array[TowerEvolution] = []
var _buttons: Array[Button] = []
var _focused: int = -1


## Shows the slot's branches (hides itself when there are none). Returns true if shown.
func show_for(builder: TowerBuilder, slot: BuildSlot) -> bool:
	_builder = builder
	_slot = slot
	for child: Node in get_children():
		child.queue_free()
	_buttons.clear()
	_options = builder.evolution_options(slot) if builder != null else []
	visible = not _options.is_empty()
	for i: int in _options.size():
		add_child(_make_card(i))
	_focused = -1
	_show_rings()
	return visible


## Re-colours prices and enables the Evolve buttons for `gold`.
func refresh_gold(gold: int) -> void:
	for i: int in _buttons.size():
		var cost: int = _builder.evolution_cost(_options[i])
		_buttons[i].disabled = gold < cost
		_buttons[i].add_theme_color_override("font_disabled_color", ERROR_COLOR)


func get_evolve_button(index: int) -> Button:
	return _buttons[index]


func get_option_count() -> int:
	return _options.size()


func _make_card(index: int) -> Control:
	var evolution: TowerEvolution = _options[index]
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = &"CardPanel"
	card.custom_minimum_size = Vector2(360, 0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var icon: TextureRect = TextureRect.new()
	icon.texture = TowerIcons.for_evolution(_slot.tower.data, evolution)
	icon.custom_minimum_size = Vector2(64, 80)
	icon.stretch_mode = TextureRect.STRETCH_KEEP
	row.add_child(icon)
	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 4)
	row.add_child(column)
	var title: Label = Label.new()
	title.text = evolution.display_name
	title.add_theme_color_override("font_color", COLORS[index % COLORS.size()])
	column.add_child(title)
	for text: String in [evolution.description, evolution.key_numbers()]:
		var label: Label = Label.new()
		label.text = text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(260, 0)
		column.add_child(label)
	var button: Button = Button.new()
	button.text = "Evolve (for good)   -%d gold" % _builder.evolution_cost(evolution)
	button.pressed.connect(func() -> void: _builder.evolve(_slot, index))
	button.focus_entered.connect(func() -> void: _focus(index))
	button.mouse_entered.connect(func() -> void: _focus(index))
	card.mouse_entered.connect(func() -> void: _focus(index))
	column.add_child(button)
	_buttons.append(button)
	return card


func _focus(index: int) -> void:
	_focused = index
	_show_rings()


## Both branches' rings (with the Mortar's dead zone), the focused one brighter.
func _show_rings() -> void:
	if _slot == null or not is_instance_valid(_slot):
		return
	var rings: Array = []
	for i: int in _options.size():
		var color: Color = COLORS[i % COLORS.size()]
		color.a = BRIGHT_ALPHA if i == _focused or _focused < 0 else DIM_ALPHA
		var stats: TowerTier = _options[i]
		rings.append([_slot.tower.modifiers.apply(stats.attack_range, RunModifiers.tower_stats(RunModifiers.TOWER_RANGE, _slot.tower.data.id)) if _slot.tower.modifiers != null else stats.attack_range,
			_options[i].min_range, color])
	if not rings.is_empty():
		_slot.show_rings(rings)
