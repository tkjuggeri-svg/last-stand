class_name Blizzard
extends LevelHazard
## The Frostbound Pass's mechanic: now and then the wind rises (the snow thickens for `data.warning` s), then
## for `data.effect_time` s a gale blows: towers lose a share of their range (`range_loss`) and every enemy
## walks `data.amount` faster. It ends with the gale's time, or with the wave. Display: a snow
## particle field over the level while it blows.

@export var builder: TowerBuilder
@export_range(0.0, 1.0) var range_loss: float = 0.2

var _gale_left: float = 0.0
var _warning_left: float = 0.0
var _snow: CPUParticles2D


func _ready() -> void:
	super()
	_snow = CPUParticles2D.new()
	_snow.emitting = false
	_snow.amount = 220
	_snow.lifetime = 2.2
	_snow.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_snow.emission_rect_extents = Vector2(700, 420)
	_snow.direction = Vector2(-1, 0.35)
	_snow.spread = 12.0
	_snow.gravity = Vector2.ZERO
	_snow.initial_velocity_min = 300.0
	_snow.initial_velocity_max = 420.0
	_snow.scale_amount_min = 2.0
	_snow.scale_amount_max = 2.0
	_snow.color = Color(0.92, 0.96, 1.0, 0.85)
	_snow.z_index = 3
	_snow.top_level = true
	add_child(_snow)


func _physics_process(delta: float) -> void:
	if _warning_left > 0.0:
		_warning_left -= delta
		if _warning_left <= 0.0 and is_active():
			_begin_gale()
	if _gale_left > 0.0:
		_gale_left -= delta
		_apply()
		if _gale_left <= 0.0 or not is_active():
			_end_gale()
		return
	super(delta)


func is_blowing() -> bool:
	return _gale_left > 0.0


func _strike() -> void:
	_warning_left = data.warning  # the snow thickens


func _begin_gale() -> void:
	_gale_left = data.effect_time
	_snow.emitting = true
	if hero != null:
		_snow.global_position = hero.global_position
	Sfx.play(self, &"gale")


func _end_gale() -> void:
	_gale_left = 0.0
	_snow.emitting = false
	_apply()


## Towers and the enemies alive take the gale's changes now (or lose them again when it is over).
func _apply() -> void:
	var blowing: bool = _gale_left > 0.0
	if builder != null:
		for tower: Tower in builder.get_towers():
			tower.set_weather_range(-range_loss if blowing else 0.0)
	for child: Node in spawner.get_children():
		var walker: Enemy = child as Enemy
		if walker != null:
			walker.weather_speed = 1.0 + data.amount if blowing else 1.0
	if blowing and hero != null:
		_snow.global_position = hero.global_position


func _on_wave_cleared(wave_number: int) -> void:
	super(wave_number)
	if _gale_left > 0.0:
		_end_gale()
	_warning_left = 0.0
