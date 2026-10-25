class_name ChapterData
extends Resource
## One chapter of a run: the battlefield it is played on, the shape and odds of its node map
## (RunMap.generate) and what its fights are. Rows are 1-based: rows 1..rows-1 hold choices, the last
## row is the boss. Tune it in data/run/*.tres.

@export var id: StringName = &""
@export var display_name: String = ""
## Which tier it belongs to (1 easy, 2 medium, 3 hard; M10). 0: its place in RunData.chapters (a run of
## one biome per tier, as before).
@export var tier: int = 0
## For the road choice between two biomes: what the place is, its mechanic, and how it differs in difficulty.
@export_multiline var blurb: String = ""
@export_multiline var mechanic_text: String = ""
@export var difficulty_note: String = ""
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
## The regulars' HP in this chapter's fights is multiplied by this (on top of each wave's own): the run
## map gives fewer upgrades than a straight 15-wave run (one choice per battle, not per wave), so its
## fights are tuned to keep the chapter's difficulty (balance: tests/tools/map_balance.gd).
@export var fight_health_scale: float = 1.0
## When the chapter is cleared its towers are packed up for this share of what they cost (the rest is
## lost): the next chapter starts on a fresh field with less than the last one had built.
@export_range(0.0, 1.0) var leave_refund: float = 0.4
@export_group("Events")
## Events and shrines drawn for the map's event and shrine nodes (each at most once per map, while
## the pool lasts).
@export var events: Array[EventData] = []
@export var shrines: Array[EventData] = []
@export_group("Rewards")
## Upgrade choice after a battle: cards offered (1 of n).
@export var battle_cards: int = 3
## After an elite: a choice of this many relics (M7.5; before: 2 rare cards and 100 gold).
@export var elite_relics: int = 3
## An elite fight's regulars are this much tougher than the chapter's battles (on top of
## fight_health_scale): the risk that pays for the relic.
@export var elite_health_scale: float = 1.25
## After the boss (not the run's last): a choice of this many relics, and the share of the fortress's
## max HP repaired.
@export var boss_relics: int = 3
@export_range(0.0, 1.0) var boss_repair: float = 0.4


## The encounters available on `row` from `pool` (battles or elites).
func encounters_for(pool: Array[EncounterData], row: int) -> Array[EncounterData]:
	return pool.filter(func(e: EncounterData) -> bool: return e.row == row)


## What winning a fight of `kind` gives (`last_chapter`: the run's last, whose boss gives no relic).
func reward_for(kind: RunMap.Kind, last_chapter: bool) -> FightReward:
	match kind:
		RunMap.Kind.ELITE:
			return FightReward.relic_choice(elite_relics)
		RunMap.Kind.BOSS:
			return FightReward.relic_choice(boss_relics if not last_chapter else 0, boss_repair)
	return FightReward.make(battle_cards)


## An event's extra fight: the first wave of the battle on `row` (or the nearest row before it).
func extra_fight(row: int) -> EncounterData:
	var pool: Array[EncounterData] = encounters_for(battles, row)
	while pool.is_empty() and row > 1:
		row -= 1
		pool = encounters_for(battles, row)
	var fight: EncounterData = pool[0].duplicate()
	fight.waves = pool[0].waves.slice(0, 1)
	return fight
