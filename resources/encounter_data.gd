class_name EncounterData
extends Resource
## One fight on the run map: a few waves (each its own wave with a build phase before it), optionally
## led by a mini-boss (an elite's Gravelord or Colossus, added at the head of the first wave) and with
## the wave files' own bosses left out (the run's 15 waves still lead waves 5 and 10 with them).

## The map row it is drawn for (battles and elites); 0 for the boss.
@export var row: int = 0
@export var waves: Array[WaveData] = []
## Leads the first wave (null = none).
@export var leader: EnemyData
## Seconds after the first wave starts that the leader arrives, and on which lane.
@export var leader_delay: float = 6.0
@export var leader_lane: int = 0
## Leave out the waves' own boss groups (true for battles and elites; the boss fight keeps its own).
@export var strip_bosses: bool = true


## The waves to play: copies with the bosses stripped, the leader added and every one of `affixes`
## applied (an elite's twist, an event's lasting curse). The data itself is never changed.
func build_waves(affixes: Array[AffixData] = []) -> Array[WaveData]:
	var built: Array[WaveData] = []
	for i: int in waves.size():
		var wave: WaveData = waves[i].duplicate()
		wave.groups = []
		for group: SpawnGroup in waves[i].groups:
			if not (strip_bosses and group.enemy != null and group.enemy.is_boss):
				wave.groups.append(group.duplicate())
		if i == 0 and leader != null:
			var lead: SpawnGroup = SpawnGroup.new()
			lead.enemy = leader
			lead.count = 1
			lead.lane = leader_lane
			lead.delay = leader_delay
			wave.groups.append(lead)
		for affix: AffixData in affixes:
			wave = affix.apply(wave)
		built.append(wave)
	return built
