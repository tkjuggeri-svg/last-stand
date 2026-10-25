class_name HazardData
extends Resource
## The numbers of a biome's environmental mechanic (M10): how often it strikes, how long it warns, how
## big and how hard it is. data/hazards/*.tres, one per mechanic; balance never means editing code.

## Seconds from a wave's start to the first strike, then between two strikes (random in the range).
@export var first_delay: float = 12.0
@export var interval_min: float = 20.0
@export var interval_max: float = 28.0
## Seconds the ground warns before it strikes (a ring that fills up).
@export var warning: float = 3.0
## Radius of the strike (px), damage to enemies and to the hero and minions caught in it.
@export var radius: float = 70.0
@export var damage_to_enemies: int = 40
@export var damage_to_hero: int = 15
## How many things a strike makes (enemies that rise, rocks that fall).
@export var count: int = 1
## What lasts after the strike (seconds): a silence on the nearest tower, a blocked road, a gale.
@export var effect_time: float = 8.0
## A second number for a mechanic that needs one (a share, a distance).
@export var amount: float = 0.0
