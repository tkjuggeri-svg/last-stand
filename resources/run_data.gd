class_name RunData
extends Resource
## A whole run: its chapters (biomes) by tier: a run crosses one biome per tier (M10). Beating the last chapter's boss wins the run. The chapter
## count is data: a new chapter (M10's maps) is one more ChapterData here. `heroes` are the heroes a
## run can be played with (M9), the first being the default.

@export var chapters: Array[ChapterData] = []
@export var heroes: Array[HeroData] = []
## The Pressure modifiers the player may turn on before a run (M12).
@export var pressure_options: Array[PressureData] = []


## The Pressure modifier with `id` (null if unknown).
func find_pressure(id: StringName) -> PressureData:
	for data: PressureData in pressure_options:
		if data.id == id:
			return data
	return null


## The modifiers for the saved `ids` (unknown ones dropped).
func pressure_for(ids: Array) -> Array[PressureData]:
	var list: Array[PressureData] = []
	for id: Variant in ids:
		var data: PressureData = find_pressure(StringName(str(id)))
		if data != null and not list.has(data):
			list.append(data)
	return list


## The hero with `id`; the default (first) hero for an unknown id. Null if there are no heroes.
func get_hero(id: String) -> HeroData:
	for hero: HeroData in heroes:
		if String(hero.id) == id:
			return hero
	return heroes[0] if not heroes.is_empty() else null


## The tier of `chapter`: its own, or (tier 0) its place in the list.
func tier_of(chapter: ChapterData) -> int:
	return chapter.tier if chapter.tier > 0 else chapters.find(chapter) + 1


## How many chapters a run has: the highest tier.
func tier_count() -> int:
	var count: int = 0
	for chapter: ChapterData in chapters:
		count = maxi(count, tier_of(chapter))
	return count


## The biomes of `tier`, in list order.
func biomes_of_tier(tier: int) -> Array[ChapterData]:
	return chapters.filter(func(c: ChapterData) -> bool: return tier_of(c) == tier)


## The chapter with `id` (null if there is none).
func find_chapter(id: StringName) -> ChapterData:
	for chapter: ChapterData in chapters:
		if chapter.id == id:
			return chapter
	return null
