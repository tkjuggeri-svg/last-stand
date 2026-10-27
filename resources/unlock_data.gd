class_name UnlockData
extends Resource
## One unlock on the War Room's board (M8): bought once with Soul Shards, it adds content to every run
## from then on (towers, a tower's evolutions, cards, relics, events) or a perk (a starting choice or a
## small convenience, or a hero; never permanent power). data/meta/unlocks/*.tres, listed in order by the board.

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var cost: int = 50
## The War Room character who sells it (a StoryCharacter id, M14): their Council card lists it. Empty, or a
## character the story doesn't have, puts it in the plain list under the cards.
@export var seller: StringName = &""
## Unlocks to buy first (ids).
@export var requires: Array[StringName] = []
## A one-off the profile must have earned first (SaveProfile.firsts, e.g. "boss:The Lich Warden").
@export var requires_first: String = ""
@export_group("Adds")
@export var towers: Array[TowerData] = []
## Towers whose two evolution branches this opens.
@export var evolutions: Array[TowerData] = []
@export var cards: Array[UpgradeData] = []
@export var relics: Array[RelicData] = []
@export var events: Array[EventData] = []
@export var heroes: Array[HeroData] = []
## Biomes this opens for the road choice (M10).
@export var biomes: Array[ChapterData] = []
## A perk: "muster" (choose 1 of 2 common cards before the first fight) or "drill" (one free card
## reroll in each chapter).
@export var perk: StringName = &""


## Something to show for it: its first card's or relic's icon (towers draw their own, see the hub).
func get_icon() -> Texture2D:
	if not cards.is_empty():
		return cards[0].icon
	if not relics.is_empty():
		return relics[0].icon
	return null
