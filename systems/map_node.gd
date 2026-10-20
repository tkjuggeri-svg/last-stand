class_name MapNode
extends RefCounted
## One node of a RunMap: its place (row, column, x from 0 to 1 across the row), what it is (RunMap.Kind),
## its fight (battles, elites, the boss: an EncounterData; elites also an affix) or scene (events and
## shrines: an EventData), and the indices of the nodes it leads to in the next row.

var index: int = 0
var row: int = 1
var column: int = 0
var x: float = 0.5
var kind: RunMap.Kind = RunMap.Kind.BATTLE
var links: Array[int] = []
var encounter: EncounterData
var affix: AffixData
## An event's or a shrine's scene.
var event: EventData


func is_combat() -> bool:
	return kind == RunMap.Kind.BATTLE or kind == RunMap.Kind.ELITE or kind == RunMap.Kind.BOSS
