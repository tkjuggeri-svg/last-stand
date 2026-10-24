class_name RunStateNode
extends Node
## The run being played (autoload "RunState": it outlives the levels a run passes through). Scripts
## reach it as `get_node("/root/RunState") as RunStateNode` where the autoload's name isn't known at
## compile time (the script check, tests and tools run with --script). It holds what must cross from
## one level to the next: the run's data and seed, the chapter and its node map (with where the player
## stands), and what the next chapter starts with (carry: gold with the towers packed up, the run's
## upgrades, the hero's lives, the fortress's HP). State only: Main runs the flow, RunMap the map's rules.

var run_data: RunData
var seed_value: int = 0
## 0-based index into run_data.chapters.
var chapter_index: int = 0
var map: RunMap
## What the next chapter's level starts with (null in chapter 1).
var carry: ChapterCarry
## What this run may use (M8 unlocks; null = everything).
var unlocks: RunUnlocks
## The hero this run is played with (M9).
var hero: HeroData
## What the run did, for its summary: the fights won ({chapter, row, kind, boss}), kills, waves
## fought, and when it started (msec).
var cleared: Array[Dictionary] = []
var kills: int = 0
var waves: int = 0
var started_msec: int = 0


## A fresh run: chapter 1 and its map.
func start_run(data: RunData, run_seed: int, run_unlocks: RunUnlocks = null, run_hero: HeroData = null) -> void:
	run_data = data
	seed_value = run_seed
	unlocks = run_unlocks
	hero = run_hero if run_hero != null else (data.get_hero("") if data != null else null)
	chapter_index = 0
	carry = null
	cleared.clear()
	kills = 0
	waves = 0
	started_msec = Time.get_ticks_msec()
	_make_map()


func get_chapter() -> ChapterData:
	return run_data.chapters[chapter_index] if run_data != null and chapter_index < run_data.chapters.size() else null


func get_chapter_count() -> int:
	return run_data.chapters.size() if run_data != null else 0


func is_last_chapter() -> bool:
	return chapter_index >= get_chapter_count() - 1


## Moves on to the next chapter and its map.
func next_chapter() -> void:
	chapter_index += 1
	_make_map()


## Goes to chapter `index` (0-based) with a fresh map and nothing carried (the dev menu's jump).
func set_chapter(index: int) -> void:
	chapter_index = clampi(index, 0, get_chapter_count() - 1)
	carry = null
	_make_map()


## The seed for chapter-dependent randomness (maps, offers), different per chapter.
func chapter_seed() -> int:
	return seed_value * 101 + chapter_index


func _make_map() -> void:
	var chapter: ChapterData = get_chapter()
	var locked: Array[EventData] = []
	if unlocks != null:
		locked = unlocks.locked_events
	map = RunMap.generate(chapter, chapter_seed(), locked) if chapter != null else null
