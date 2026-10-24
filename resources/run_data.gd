class_name RunData
extends Resource
## A whole run: its chapters in order. Beating the last chapter's boss wins the run. The chapter
## count is data: a new chapter (M10's maps) is one more ChapterData here. `heroes` are the heroes a
## run can be played with (M9), the first being the default.

@export var chapters: Array[ChapterData] = []
@export var heroes: Array[HeroData] = []


## The hero with `id`; the default (first) hero for an unknown id. Null if there are no heroes.
func get_hero(id: String) -> HeroData:
	for hero: HeroData in heroes:
		if String(hero.id) == id:
			return hero
	return heroes[0] if not heroes.is_empty() else null
