class_name MapFixtures
## Test helpers for the run map: Main starts every run on the map, so tests that need a fight pick
## a node the way the player does (the map screen's node_chosen).


## Picks the first node offered on the map (row 1: always a battle) and returns the level, now
## running that fight's build phase. Await it after adding Main to the tree.
static func enter_first_battle(main: Node) -> Level:
	if not main.is_node_ready():
		await main.ready
	var screen: MapScreen = main.get_node("%MapScreen")
	screen.node_chosen.emit((main.call("get_map") as RunMap).get_choices()[0])
	return main.call("get_level")


## A one-chapter run: one battle (row 1) then the boss, with the given fights (for short tests); with
## no battle, the boss is the only node.
static func tiny_run(battle: EncounterData, boss: EncounterData, level_scene: PackedScene) -> RunData:
	var chapter: ChapterData = ChapterData.new()
	chapter.display_name = "Test chapter"
	chapter.level_scene = level_scene
	chapter.rows = 2 if battle != null else 1
	chapter.row_sizes = [1]
	chapter.battle_rows.clear()
	chapter.merchant_row = 0
	if battle != null:
		chapter.battle_rows.append(1)
		battle.row = 1
		chapter.battles = [battle]
	chapter.boss = boss
	var run: RunData = RunData.new()
	run.chapters = [chapter]
	return run


## A fight of `waves` simple waves of `count` Ghouls each.
static func encounter(waves: int, count: int) -> EncounterData:
	var data: EncounterData = EncounterData.new()
	for _i: int in waves:
		data.waves.append(WaveFixtures.make_wave(count, 0.5))
	return data
