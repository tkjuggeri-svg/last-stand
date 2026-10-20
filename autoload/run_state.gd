class_name RunStateNode
extends Node
## The run being played (autoload "RunState": it outlives the levels a run passes through). Scripts
## reach it as `get_node("/root/RunState") as RunStateNode` where the autoload's name isn't known at
## compile time (the script check, tests and tools run with --script). It holds what must cross from
## one level to the next: the run's data and seed, the chapter and its node map (with where the player
## stands). State only: Main runs the flow, RunMap the map's rules.

var run_data: RunData
var seed_value: int = 0
## 0-based index into run_data.chapters.
var chapter_index: int = 0
var map: RunMap


## A fresh run: chapter 1 and its map.
func start_run(data: RunData, run_seed: int) -> void:
	run_data = data
	seed_value = run_seed
	chapter_index = 0
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


## The seed for chapter-dependent randomness (maps, offers), different per chapter.
func chapter_seed() -> int:
	return seed_value * 101 + chapter_index


func _make_map() -> void:
	var chapter: ChapterData = get_chapter()
	map = RunMap.generate(chapter, chapter_seed()) if chapter != null else null
