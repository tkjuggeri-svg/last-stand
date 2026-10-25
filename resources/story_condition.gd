class_name StoryCondition
extends Resource
## When a story line or beat may be told (M11): every field that is set must hold for the profile (the
## empty condition always holds). Data, with one fixed rule per field; StoryCondition.holds() is the whole
## logic. The `last_*` fields look at the last finished run (RunSummary's dictionary).

@export var min_runs: int = 0
@export var min_wins: int = 0
## A boss beaten at least once (its display name, as the profile records it).
@export var boss: String = ""
## The furthest chapter reached, at least this (1-based).
@export var chapter: int = 0
## A biome entered at least once (its chapter id).
@export var place: StringName = &""
## An unlock bought (its id: a hero, a biome).
@export var unlock: StringName = &""
## An ending seen (EndingData id).
@export var ending: StringName = &""
## A beat already heard (its id).
@export var beat: StringName = &""
@export_group("The last run")
## "won", "lost" or "abandoned"; empty: any.
@export var last_result: String = ""
@export var last_chapter_min: int = 0
## It ended at this row or earlier (0: any).
@export var last_row_max: int = 0
@export var last_beat_a_boss: bool = false
@export var last_found_a_relic: bool = false
## The last run's hero (a HeroData id); empty: any.
@export var last_hero: StringName = &""


func holds(profile: SaveProfile) -> bool:
	if profile.runs < min_runs or profile.wins < min_wins or profile.best_chapter < chapter:
		return false
	if boss != "" and not profile.bosses.has(boss):
		return false
	if place != &"" and not profile.places_seen.has(String(place)):
		return false
	if unlock != &"" and not profile.has_unlock(String(unlock)):
		return false
	if ending != &"" and not profile.endings.has(String(ending)):
		return false
	if beat != &"" and not profile.beats_seen.has(String(beat)):
		return false
	return _last_run_holds(profile.get_last_run())


func _last_run_holds(last: Dictionary) -> bool:
	var wants_last: bool = last_result != "" or last_chapter_min > 0 or last_row_max > 0 or last_beat_a_boss or last_found_a_relic or last_hero != &""
	if not wants_last:
		return true
	if last.is_empty():
		return false
	if last_result != "" and String(last.get("result", "")) != last_result:
		return false
	if int(last.get("chapter", 1)) < last_chapter_min:
		return false
	if last_row_max > 0 and int(last.get("row", 0)) > last_row_max:
		return false
	if last_beat_a_boss and (last.get("bosses", []) as Array).is_empty():
		return false
	if last_found_a_relic and (last.get("relics", []) as Array).is_empty():
		return false
	return last_hero == &"" or String(last.get("hero", "knight")) == String(last_hero)
