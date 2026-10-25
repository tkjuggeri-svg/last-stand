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
## The biome of each chapter chosen so far (M10): the first from the seed, the next ones by the player's
## choice of road (RunState.road_options / choose_road).
var biomes: Array[ChapterData] = []
## What the next chapter's level starts with (null in chapter 1).
var carry: ChapterCarry
## What this run may use (M8 unlocks; null = everything).
var unlocks: RunUnlocks
## The hero this run is played with (M9).
var hero: HeroData
## How many chapters deeper than the last tier the run has descended (Endless, M12; 0 = the normal run).
var depth: int = 0
## The Pressure modifiers this run is played with (M12).
var pressure: Array[PressureData] = []
## What the run did, for its summary: the fights won ({chapter, row, kind, boss}), kills, waves
## fought, and when it started (msec).
var cleared: Array[Dictionary] = []
var kills: int = 0
var waves: int = 0
var started_msec: int = 0


## A fresh run: chapter 1 and its map.
func start_run(data: RunData, run_seed: int, run_unlocks: RunUnlocks = null, run_hero: HeroData = null, run_pressure: Array[PressureData] = []) -> void:
	pressure = run_pressure.duplicate()
	run_data = data
	seed_value = run_seed
	unlocks = run_unlocks
	hero = run_hero if run_hero != null else (data.get_hero("") if data != null else null)
	chapter_index = 0
	depth = 0
	carry = null
	biomes.clear()
	biomes.append(_draw_biome(1, 0))
	cleared.clear()
	kills = 0
	waves = 0
	started_msec = Time.get_ticks_msec()
	_make_map()


func get_chapter() -> ChapterData:
	return biomes[chapter_index] if chapter_index >= 0 and chapter_index < biomes.size() else null


func get_chapter_count() -> int:
	return run_data.tier_count() if run_data != null else 0


## True in the normal run's last chapter (a descended run has no last one: it ends when it is lost).
func is_last_chapter() -> bool:
	return depth == 0 and chapter_index >= get_chapter_count() - 1


## The roads the player may take after this chapter: up to two unlocked biomes of the next tier, drawn
## from the seed (the same two every time it is asked). Fewer than two: no choice to make.
func road_options() -> Array[ChapterData]:
	var options: Array[ChapterData] = _candidates(chapter_index + 2)
	if options.size() <= 2:
		return options
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = chapter_seed() * 31 + 7
	var first: int = rng.randi_range(0, options.size() - 1)
	var second: int = (first + rng.randi_range(1, options.size() - 1)) % options.size()
	return [options[mini(first, second)], options[maxi(first, second)]]


## Takes `chapter` as the next chapter's biome (one of road_options()).
func choose_road(chapter: ChapterData) -> void:
	biomes.resize(chapter_index + 1)
	biomes.append(chapter)


## Moves on to the next chapter and its map (its biome: the road chosen, else the seed's pick).
func next_chapter() -> void:
	if biomes.size() <= chapter_index + 1:
		biomes.append(_draw_biome(chapter_index + 2, chapter_index + 1))
	chapter_index += 1
	if chapter_index >= get_chapter_count():
		depth = chapter_index - get_chapter_count() + 1
		biomes[chapter_index] = Endless.short_chapter(biomes[chapter_index], depth)
	_make_map()


## Puts a saved descent back: the depth, the chapter and its map (the biomes were set already).
func resume_descent(saved_depth: int, index: int) -> void:
	depth = saved_depth
	chapter_index = index
	for i: int in range(get_chapter_count(), biomes.size()):
		if not Endless.is_short(biomes[i]):
			biomes[i] = Endless.short_chapter(biomes[i], i - get_chapter_count() + 1)
	_make_map()


## Goes to chapter `index` (0-based) with a fresh map and nothing carried (the dev menu's jump).
func set_chapter(index: int) -> void:
	chapter_index = clampi(index, 0, get_chapter_count() - 1)
	for i: int in range(biomes.size(), chapter_index + 1):
		biomes.append(_draw_biome(i + 1, i))
	carry = null
	_make_map()


## The seed for chapter-dependent randomness (maps, offers), different per chapter.
func chapter_seed() -> int:
	return seed_value * 101 + chapter_index


## The unlocked biomes of `tier` (all of them if none is unlocked: a run never lacks a chapter).
func _candidates(tier: int) -> Array[ChapterData]:
	tier = mini(tier, get_chapter_count())  # a descent keeps drawing from the last tier
	var all: Array[ChapterData] = run_data.biomes_of_tier(tier) if run_data != null else []
	var open: Array[ChapterData] = all.filter(func(c: ChapterData) -> bool: return unlocks == null or not unlocks.locked_biomes.has(c))
	return open if not open.is_empty() else all


## One biome of `tier` drawn from the seed (for the chapter at `index`).
func _draw_biome(tier: int, index: int) -> ChapterData:
	var options: Array[ChapterData] = _candidates(tier)
	if options.is_empty():
		return null
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = (seed_value * 101 + index) * 17 + 3
	return options[rng.randi_range(0, options.size() - 1)]


func _make_map() -> void:
	var chapter: ChapterData = get_chapter()
	var locked: Array[EventData] = []
	if unlocks != null:
		locked = unlocks.locked_events
	map = RunMap.generate(chapter, chapter_seed(), locked) if chapter != null else null
