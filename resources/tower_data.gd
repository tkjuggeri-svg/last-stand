class_name TowerData
extends Resource
## Stats and look of one tower type. Make one .tres per tower in data/towers/ and tune it there.

## Selects the tower's animations ("<id>_idle", "<id>_fire").
@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var cost: int = 50
## The tower scene to build (all towers share one scene; the data decides how it looks and fights).
@export var scene: PackedScene

@export_group("Attack")
## Enemies whose body comes within this many pixels are targeted.
@export var attack_range: float = 160.0
@export var damage: int = 10
## Seconds between two shots.
@export var fire_interval: float = 1.0
@export var projectile_speed: float = 400.0
## Projectile animation. "arrow" picks one of the 8 directional arrow_N animations.
@export var projectile_look: StringName = &"arrow"
## Above 0: the projectile explodes on impact and damages every enemy within this radius.
@export var splash_radius: float = 0.0
## Where shots leave the tower, relative to its base (the top of the bow, barrel or crystal).
@export var muzzle_offset: Vector2 = Vector2(0, -48)
## Colour of the light the tower gives off at its muzzle (e.g. the frost crystal). Alpha 0 = no light.
@export var glow_color: Color = Color(0, 0, 0, 0)

@export_group("Slow")
## Speed multiplier applied to a hit enemy (1 = no slow).
@export_range(0.1, 1.0) var slow_factor: float = 1.0
## How long the slow lasts, in seconds.
@export var slow_duration: float = 0.0
