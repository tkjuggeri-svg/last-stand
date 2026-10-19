class_name TowerData
extends Resource
## Stats and look of one tower type. Make one .tres per tower in data/towers/ and tune it there.
## The fields below are level 1; `tiers` holds the upgrades (levels 2, 3, ...), each with its price and
## full stats. Gameplay reads a level's stats through stats_for().

## Selects the tower's animations ("<id>_idle", "<id>_fire", "<id>_build"; upgraded levels add
## "_2" / "_3": "<id>_idle_2").
@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var cost: int = 50
## Seconds of construction after placing: the tower can't target or fire until it is finished.
## Its "<id>_build" animation is stretched to this length.
@export var build_time: float = 0.6
## The tower scene to build (all towers share one scene; the data decides how it looks and fights).
@export var scene: PackedScene

@export_group("Attack")
## Enemies whose centre is within this many pixels of the tower's base are targeted.
@export var attack_range: float = 160.0
@export var damage: int = 10
## Seconds between two shots.
@export var fire_interval: float = 1.0
@export var projectile_speed: float = 400.0
## Projectile animation. "arrow" picks one of the 8 directional arrow_N animations.
@export var projectile_look: StringName = &"arrow"
## Above 0: the projectile explodes on impact and damages every enemy within this radius.
@export var splash_radius: float = 0.0
## True: the shot follows its target (arrows, frost bolts). False: a shell fired at the ground point
## where the target should be when it lands (simple lead) that explodes there; it can miss.
@export var homing: bool = true
## Where shots leave the tower, relative to its base (the top of the bow, barrel or crystal).
@export var muzzle_offset: Vector2 = Vector2(0, -48)
## Colour of the light the tower gives off at its muzzle (e.g. the frost crystal). Alpha 0 = no light.
@export var glow_color: Color = Color(0, 0, 0, 0)

@export_group("Slow")
## Speed multiplier applied to a hit enemy (1 = no slow).
@export_range(0.1, 1.0) var slow_factor: float = 1.0
## How long the slow lasts, in seconds.
@export var slow_duration: float = 0.0

@export_group("Upgrades")
## Level 2, 3, ... in order.
@export var tiers: Array[TowerTier] = []

var _level_one: TowerTier


func max_level() -> int:
	return 1 + tiers.size()


## Every stat at `level` (1 = the fields above).
func stats_for(level: int) -> TowerTier:
	if level >= 2 and level - 2 < tiers.size():
		return tiers[level - 2]
	if _level_one == null:
		_level_one = TowerTier.new()
		_level_one.cost = 0
		_level_one.damage = damage
		_level_one.fire_interval = fire_interval
		_level_one.attack_range = attack_range
		_level_one.splash_radius = splash_radius
		_level_one.slow_factor = slow_factor
		_level_one.slow_duration = slow_duration
		_level_one.projectile_look = projectile_look
	return _level_one


## Gold to go from `level` - 1 to `level` (the build price for level 1).
func upgrade_cost(level: int) -> int:
	return cost if level <= 1 else stats_for(level).cost
