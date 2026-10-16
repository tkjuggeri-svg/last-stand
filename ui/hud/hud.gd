extends CanvasLayer
## In-game overlay showing fortress and hero HP. Assign fortress and hero in the level scene.
## A bar whose target is not assigned is hidden, so the HUD also runs on its own.

@export var fortress: Fortress
@export var hero: Hero

@onready var _fortress_bar: HealthBar = %FortressBar
@onready var _hero_bar: HealthBar = %HeroBar


func _ready() -> void:
	_fortress_bar.visible = fortress != null
	_hero_bar.visible = hero != null
	# The HUD may be ready before them (tree order); their `health` is only set in their _ready().
	if fortress != null:
		if not fortress.is_node_ready():
			await fortress.ready
		_fortress_bar.track(fortress.health)
	if hero != null:
		if not hero.is_node_ready():
			await hero.ready
		_hero_bar.track(hero.health)
