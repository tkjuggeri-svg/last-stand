class_name ServicesPanel
extends PanelContainer
## The HUD's between-waves shop (the Quartermaster's offers): repair the fortress, buy back a lost
## life. Shown in the build phase while one of them applies (the walls are damaged, a life is lost and
## not yet bought back); a button is disabled while its price can't be paid. Only displays and asks:
## the Quartermaster owns the prices and the rules.

const REPAIR_TEXT: String = "Repair walls +%d  (%d g)"
const LIFE_TEXT: String = "Buy back a life  (%d g)"

var _quartermaster: Quartermaster

@onready var _repair_button: Button = %RepairButton
@onready var _life_button: Button = %LifeButton


func _ready() -> void:
	_repair_button.pressed.connect(func() -> void: _quartermaster.repair())
	_life_button.pressed.connect(func() -> void: _quartermaster.buy_life())
	_refresh()


## Shows this Quartermaster's offers (null hides the panel).
func setup(quartermaster: Quartermaster) -> void:
	_quartermaster = quartermaster
	if quartermaster != null:
		quartermaster.changed.connect(_refresh)
	if is_node_ready():
		_refresh()


func get_repair_button() -> Button:
	return _repair_button


func get_life_button() -> Button:
	return _life_button


func _refresh() -> void:
	if _quartermaster == null:
		visible = false
		return
	var repair_blocker: String = _quartermaster.repair_blocker()
	_repair_button.visible = repair_blocker.is_empty() or repair_blocker == Quartermaster.NOT_ENOUGH_GOLD
	_repair_button.disabled = not repair_blocker.is_empty()
	_repair_button.text = REPAIR_TEXT % [_quartermaster.repair_amount(), _quartermaster.repair_cost()]
	var life_blocker: String = _quartermaster.life_blocker()
	_life_button.visible = life_blocker.is_empty() or life_blocker == Quartermaster.NOT_ENOUGH_GOLD
	_life_button.disabled = not life_blocker.is_empty()
	_life_button.text = LIFE_TEXT % _quartermaster.life_cost()
	visible = _repair_button.visible or _life_button.visible
