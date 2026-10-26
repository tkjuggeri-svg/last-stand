class_name MapLook
extends Resource
## How a chapter's run map looks (M13 playtest: "the run map is super boring"): the biome's ground tile,
## the colour of its roads, the cold tint of the far end (the boss, where the dead are) against the warm
## firelight of the fortress at the start, and the weather drifting over it. Display only: MapView draws it.

enum Weather { MOTES, EMBERS, SNOW, SPORES, MIST, GLINTS }

## A seamless tile, drawn repeated (assets/sprites/ui/map/ground_<biome>.png).
@export var ground: Texture2D
## The roads between nodes.
@export var road: Color = Color(0.36, 0.28, 0.2)
## Tints the top of the map, away from the fortress.
@export var cold: Color = Color(0.2, 0.28, 0.45)
@export var weather: Weather = Weather.MOTES
@export var weather_color: Color = Color(0.8, 0.78, 0.7)
