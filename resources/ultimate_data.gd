class_name UltimateData
extends Resource
## A hero's ultimate (M14, docs/M14_ULTIMATES.md): a big move on its own key that charges from what the hero and its
## minions do, not from a timer. One .tres per hero in data/heroes/, referenced by HeroData.ultimate.

enum Kind { LAST_STAND, VOLLEY, RISE }

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var kind: Kind = Kind.LAST_STAND
@export_group("Charge")
## Points for a full bar, per kill by the hero or its minions (a boss pays more), per 100 damage they deal, and per second
## a wave is running. A new chapter starts the bar at `chapter_start`.
@export var charge_needed: float = 100.0
@export var per_kill: float = 2.0
@export var per_boss_kill: float = 25.0
@export var per_100_damage: float = 1.0
@export var per_second: float = 0.5
@export var chapter_start: float = 50.0
@export_group("Effect")
## Radius (px) of a ring / of each impact, and the damage as a multiple of the hero's blow. A boss takes `boss_multiplier`
## times the blow instead, never more than `boss_health_cap` of its max health.
@export var radius: float = 160.0
@export var damage_multiplier: float = 6.0
@export var boss_multiplier: float = 3.0
@export_range(0.0, 1.0) var boss_health_cap: float = 0.1
## Last Stand: enemies in the ring are held this long; the hero takes this share less damage and swings this much wider
## (as a share) for `buff_seconds`.
@export var stun_time: float = 1.2
@export_range(0.0, 0.9) var damage_reduction: float = 0.5
@export var reach_bonus: float = 0.3
@export var buff_seconds: float = 6.0
## Volley of Ruin: this many impacts along a line this long (px) over `volley_seconds`; each Marks what it hits.
@export var bolts: int = 12
@export var line_length: float = 340.0
@export var volley_seconds: float = 2.5
@export var mark_bonus: float = 0.15
@export var mark_time: float = 8.0
## Rise of the Dead: this many skeletons, over the hero's cap, that last `skeleton_seconds`.
@export var skeletons: int = 5
@export var skeleton_seconds: float = 12.0
@export_group("Sound")
@export var sound: StringName = &"ultimate_knight"
