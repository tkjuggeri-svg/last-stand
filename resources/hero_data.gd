class_name HeroData
extends Resource
## One playable hero (M9): who they are and the stats the Hero scene reads at startup. data/heroes/*.tres.
## The attack itself stays in the Hero scene; heroes with another attack add theirs in their own stage.

@export var id: StringName = &""
@export var display_name: String = ""
## Two short lines for the War Room: how the hero fights and what they are weak at.
@export_multiline var description: String = ""
@export var max_health: int = 100
@export var move_speed: float = 200.0
## Damage of one hit, before the run's upgrades.
@export var attack_damage: int = 10
## Seconds between the start of two attacks, and how long the attack's hitbox stays active.
@export var attack_cooldown: float = 0.4
@export var attack_duration: float = 0.12
## How far (px) a hit pushes an enemy back along its lane.
@export var knockback: float = 12.0
