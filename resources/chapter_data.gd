class_name ChapterData
extends Resource
## One chapter of a run: the battlefield it is played on, the shape and odds of its node map
## (RunMap.generate) and what its fights are. Rows are 1-based: rows 1..rows-1 hold choices, the last
## row is the boss. Tune it in data/run/*.tres.

@export var id: StringName = &""
@export var display_name: String = ""
## The level every fight of the chapter is played on (it stays, with its towers, for the chapter).
@export var level_scene: PackedScene
@export_group("Map")
## Rows including the boss row.
@export var rows: int = 8
## Nodes per row (index 0 = row 1); the boss row always has one.
@export var row_sizes: Array[int] = [2, 3, 3, 4, 4, 3, 3]
## Rows that are all battles (the gentle opening).
@export var battle_rows: Array[int] = [1, 2]
## The row that is all merchants (the last stop before the boss); 0 = none.
@export var merchant_row: int = 7
## Relative odds of each node type in the other rows (the map's mixed rows).
@export var battle_weight: float = 45.0
@export var elite_weight: float = 15.0
@export var event_weight: float = 20.0
@export var shrine_weight: float = 12.0
@export var merchant_weight: float = 8.0
## No elite before this row.
@export var first_elite_row: int = 3
## Every path holds at least this many battles or elites in the mixed rows.
@export var min_mixed_combat: int = 2
@export_group("Fights")
## Battles: one or more encounters per combat row (a node picks one of its row's, seeded).
@export var battles: Array[EncounterData] = []
## Elite fights, by row like the battles.
@export var elites: Array[EncounterData] = []
## Affixes an elite can get (one each).
@export var affixes: Array[AffixData] = []
@export var boss: EncounterData
@export_group("Events")
## Events and shrines drawn for the map's event and shrine nodes (each at most once per map, while
## the pool lasts).
@export var events: Array[EventData] = []
@export var shrines: Array[EventData] = []
@export_group("Rewards")
## Upgrade choice after a battle: cards offered (1 of n).
@export var battle_cards: int = 3
## After an elite: rare cards offered, and bonus gold.
@export var elite_cards: int = 2
@export var elite_gold: int = 100
## After the boss: rare cards offered, and the share of the fortress's max HP repaired.
@export var boss_cards: int = 3
@export_range(0.0, 1.0) var boss_repair: float = 0.4


## The encounters available on `row` from `pool` (battles or elites).
func encounters_for(pool: Array[EncounterData], row: int) -> Array[EncounterData]:
	return pool.filter(func(e: EncounterData) -> bool: return e.row == row)
