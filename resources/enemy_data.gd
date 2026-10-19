class_name EnemyData
extends Resource
## Stats and look of one enemy type. Make one .tres per enemy in data/enemies/ and tune it there.
## All enemies share entities/enemies/enemy.tscn; this data decides what it is.

@export var display_name: String = ""
@export var max_health: int = 30
## Pixels per second along the lane.
@export var move_speed: float = 60.0
## Gold paid when the enemy is killed (by the hero or a tower). Nothing is paid if it reaches the fortress.
@export var gold_reward: int = 10
## Damage dealt to the fortress when the enemy reaches it.
@export var fortress_damage: int = 10
## Melee attack on the hero: damage per hit.
@export var hero_damage: int = 10
## The enemy stops to attack when the hero's body comes within this many pixels of its own collision shape.
@export var attack_range: float = 24.0
## Telegraphed wind-up before the strike lands, in seconds (gives the player time to dodge).
@export var attack_windup: float = 0.35
## Seconds between the starts of two attacks.
@export var attack_cooldown: float = 1.2
## Visual played where the enemy is killed (a one-shot scene). Optional.
@export var death_effect: PackedScene

@export_group("Body and look")
## Radius of the body in world px: its hurtbox, fortress contact and attack reach grow with it.
@export var body_radius: float = 12.0
## The enemy's animations ("idle_<facing>", "walk_<facing>", "attack_<facing>", "death").
@export var sprite_frames: SpriteFrames
## Where the sprite sits relative to the body's centre (the feet should touch the body's bottom).
@export var sprite_offset: Vector2 = Vector2(0, -10)
## Height of the health bar (shown once damaged) relative to the body's centre: just above the head.
@export var health_bar_y: float = -36.0
## A coloured light around the enemy (a caster's glow); none while alpha is 0.
@export var glow_color: Color = Color(0, 0, 0, 0)

@export_group("Ranged attack")
## Speed of its shots in px/s. 0 = a melee enemy (it strikes at arm's length). A ranged enemy shoots
## the hero once the hero is within attack_range (dealing hero_damage) instead of striking.
@export var bolt_speed: float = 0.0
## A ranged enemy stops this many px before the end of its lane (at the fortress) and shoots the
## fortress from there. 0 = it walks all the way like the others.
@export var siege_distance: float = 0.0
## Damage of a shot that hits the fortress.
@export var siege_damage: int = 0


func is_ranged() -> bool:
	return bolt_speed > 0.0
