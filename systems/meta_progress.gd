class_name MetaProgress
extends RefCounted
## The meta-progression rules (M8; docs/M8_META.md): the Soul Shards a finished run pays (every run,
## lost ones too: progress, not kills), the records it updates, and buying unlocks (price, what must be
## bought first). Works on a SaveProfile; SaveManager saves it, the hub and the run summary show it.

## Shards per thing done in a run (docs/M8_META.md 1.1).
const BATTLE: int = 3
const ELITE: int = 8
## A chapter's boss, by chapter (1-based; the last value for later chapters).
const BOSS: Array[int] = [15, 25]
const CHAPTER_CLEARED: int = 5
const RUN_WON: int = 30
## One-off: the first time each boss is beaten and each chapter is reached.
const FIRST_TIME: int = 10

const NEEDS_SHARDS: String = "Not enough Soul Shards"
const OWNED: String = "Bought"


## The shards a finished run pays, line by line ([label, shards]), one-off rewards included.
## `summary` is RunSummary's dictionary.
static func shard_lines(summary: Dictionary, profile: SaveProfile) -> Array[Array]:
	var lines: Array[Array] = []
	var battles: int = int(summary.get("battles", 0))
	if battles > 0:
		lines.append(["%d battle%s won" % [battles, "s" if battles > 1 else ""], battles * BATTLE])
	var elites: int = int(summary.get("elites", 0))
	if elites > 0:
		lines.append(["%d elite%s beaten" % [elites, "s" if elites > 1 else ""], elites * ELITE])
	var bosses: Array = summary.get("bosses", [])
	for i: int in bosses.size():
		lines.append(["%s beaten" % bosses[i], BOSS[mini(i, BOSS.size() - 1)]])
	var chapters: int = int(summary.get("chapters_cleared", 0))
	if chapters > 0:
		lines.append(["%d chapter%s cleared" % [chapters, "s" if chapters > 1 else ""], chapters * CHAPTER_CLEARED])
	if summary.get("result", "") == "won":
		lines.append(["The run won", RUN_WON])
	for first: String in firsts_of(summary):
		if not profile.firsts.has(first):
			lines.append(["First time: %s" % first.get_slice(":", 1), FIRST_TIME])
	var pressure: int = int(summary.get("pressure", 0))
	if pressure > 0:
		var base: int = 0
		for line: Array in lines:
			base += int(line[1])
		lines.append(["Pressure %d (+%d%%)" % [pressure, roundi(PressureRules.SHARD_BONUS_PER_POINT * pressure * 100.0)],
			roundi(base * PressureRules.SHARD_BONUS_PER_POINT * pressure)])
	return lines


static func shards_for(summary: Dictionary, profile: SaveProfile) -> int:
	var total: int = 0
	for line: Array in shard_lines(summary, profile):
		total += int(line[1])
	return total


## The one-off rewards a run earned: "boss:<name>" per boss beaten, "chapter <n>" per chapter reached.
static func firsts_of(summary: Dictionary) -> Array[String]:
	var firsts: Array[String] = []
	for boss: Variant in summary.get("bosses", []):
		firsts.append("boss:%s" % boss)
	for chapter: int in range(2, int(summary.get("chapter", 1)) + 1):
		firsts.append("chapter:Chapter %d reached" % chapter)
	return firsts


## Pays the run's shards and updates the records (call once, when the run ends). Returns the shards.
static func finish_run(profile: SaveProfile, summary: Dictionary) -> int:
	var shards: int = shards_for(summary, profile)
	profile.shards += shards
	profile.shards_total += shards
	profile.runs += 1
	if summary.get("result", "") == "won":
		profile.wins += 1
	var pressure: int = int(summary.get("pressure", 0))
	profile.pressure_best = maxi(profile.pressure_best, pressure)
	if summary.get("result", "") == "won":
		var hero_id: String = str(summary.get("hero", SaveProfile.DEFAULT_HERO))
		profile.pressure_wins[hero_id] = maxi(int(profile.pressure_wins.get(hero_id, 0)), pressure)
	var chapter: int = int(summary.get("chapter", 1))
	var row: int = int(summary.get("row", 0))
	if chapter > profile.best_chapter or (chapter == profile.best_chapter and row > profile.best_row):
		profile.best_chapter = chapter
		profile.best_row = row
	for boss: Variant in summary.get("bosses", []):
		if not profile.bosses.has(str(boss)):
			profile.bosses.append(str(boss))
	for first: String in firsts_of(summary):
		if not profile.firsts.has(first):
			profile.firsts.append(first)
	var entry: Dictionary = summary.duplicate()
	entry["shards"] = shards
	profile.history.append(entry)
	while profile.history.size() > SaveProfile.HISTORY_SIZE:
		profile.history.pop_front()
	profile.run = {}
	return shards


## Why `unlock` can't be bought now ("" = it can).
static func blocker(profile: SaveProfile, board: UnlockBoard, unlock: UnlockData) -> String:
	if profile.unlocks.has(String(unlock.id)):
		return OWNED
	for need: StringName in unlock.requires:
		if not profile.unlocks.has(String(need)):
			var first: UnlockData = board.find(need)
			return "Needs %s" % (first.display_name if first != null else String(need))
	if unlock.requires_first != "" and not profile.firsts.has(unlock.requires_first):
		var what: String = unlock.requires_first.get_slice(":", 1)
		return "Beat %s" % what if unlock.requires_first.begins_with("boss:") else "Needs: %s" % what
	if profile.shards < unlock.cost:
		return NEEDS_SHARDS
	return ""


static func buy(profile: SaveProfile, board: UnlockBoard, unlock: UnlockData) -> bool:
	if not blocker(profile, board, unlock).is_empty():
		return false
	profile.shards -= unlock.cost
	profile.unlocks.append(String(unlock.id))
	return true
