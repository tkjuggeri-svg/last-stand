class_name SaveProfile
extends RefCounted
## The player's profile (M8): Soul Shards, the unlocks bought, records, one-off rewards already paid,
## tutorial hints seen, and the run in progress (resumable from the map). Plain data with a versioned
## dictionary form (to_dict / from_dict); SaveManager reads and writes it. migrate() brings an older
## save up to CURRENT_VERSION step by step (a test loads tests/fixtures/save_v1.json).

const CURRENT_VERSION: int = 2
## Version 1 (the M8 proposal) had permanent bonuses, dropped in version 2 (the user's rule: no
## permanent power). Their price per level, refunded when an old save is loaded.
const V1_BONUS_PRICES: Dictionary = {"stores": [40, 80, 120], "mortar": [50, 100, 150]}
## How many finished runs the records keep.
const HISTORY_SIZE: int = 10

var shards: int = 0
## Ids of the UnlockData bought.
var unlocks: Array[String] = []
## Everything counts as unlocked (tests and tools; never saved).
var unlock_everything: bool = false
var runs: int = 0
var wins: int = 0
## The furthest a run got: chapter and row.
var best_chapter: int = 0
var best_row: int = 0
## Every boss ever beaten (display names), and all shards ever earned.
var bosses: Array[String] = []
var shards_total: int = 0
## The last finished runs' summaries (newest last), and one-off rewards already paid ("boss:<name>").
var history: Array[Dictionary] = []
var firsts: Array[String] = []
var hints_seen: Array[String] = []
var hints_off: bool = false
## The run in progress (RunResume's dictionary), empty when there is none.
var run: Dictionary = {}


func has_unlock(id: String) -> bool:
	return unlock_everything or unlocks.has(id)


func get_last_run() -> Dictionary:
	return history.back() if not history.is_empty() else {}


func to_dict() -> Dictionary:
	return {"version": CURRENT_VERSION, "shards": shards, "unlocks": unlocks,
		"records": {"runs": runs, "wins": wins, "best": {"chapter": best_chapter, "row": best_row},
			"bosses": bosses, "shards_total": shards_total, "history": history},
		"firsts": firsts, "hints_seen": hints_seen, "hints_off": hints_off, "run": run}


## A profile from a saved dictionary of any known version (migrated first).
static func from_dict(data: Dictionary) -> SaveProfile:
	var d: Dictionary = migrate(data)
	var profile: SaveProfile = SaveProfile.new()
	profile.shards = int(d.get("shards", 0))
	profile.unlocks = _strings(d.get("unlocks", []))
	var records: Dictionary = d.get("records", {})
	profile.runs = int(records.get("runs", 0))
	profile.wins = int(records.get("wins", 0))
	var best: Dictionary = records.get("best", {})
	profile.best_chapter = int(best.get("chapter", 0))
	profile.best_row = int(best.get("row", 0))
	profile.bosses = _strings(records.get("bosses", []))
	profile.shards_total = int(records.get("shards_total", 0))
	for entry: Variant in records.get("history", []):
		if entry is Dictionary:
			profile.history.append(entry)
	profile.firsts = _strings(d.get("firsts", []))
	profile.hints_seen = _strings(d.get("hints_seen", []))
	profile.hints_off = bool(d.get("hints_off", false))
	var saved_run: Variant = d.get("run", {})
	profile.run = saved_run if saved_run is Dictionary else {}
	return profile


## `data` brought up to CURRENT_VERSION (a copy; data without a version is version 1).
static func migrate(data: Dictionary) -> Dictionary:
	var d: Dictionary = data.duplicate(true)
	var version: int = int(d.get("version", 1))
	if version < 2:
		d = _v1_to_v2(d)
	d["version"] = CURRENT_VERSION
	return d


## Version 2 drops the permanent bonuses: Stores and Mortar levels are refunded as shards; Drill (one
## free reroll) became an unlock of the same name.
static func _v1_to_v2(d: Dictionary) -> Dictionary:
	var bonuses: Dictionary = d.get("bonuses", {})
	var refund: int = 0
	for bonus: String in V1_BONUS_PRICES:
		var prices: Array = V1_BONUS_PRICES[bonus]
		for level: int in mini(int(bonuses.get(bonus, 0)), prices.size()):
			refund += int(prices[level])
	d["shards"] = int(d.get("shards", 0)) + refund
	if int(bonuses.get("drill", 0)) > 0:
		var unlocked: Array = d.get("unlocks", [])
		if not unlocked.has("drill"):
			unlocked.append("drill")
		d["unlocks"] = unlocked
	d.erase("bonuses")
	return d


static func _strings(values: Variant) -> Array[String]:
	var out: Array[String] = []
	if values is Array:
		for value: Variant in values:
			out.append(str(value))
	return out
