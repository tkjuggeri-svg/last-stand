class_name HubLines
## What the Quartermaster says in the War Room about the last run (M8: the hub's character reacting to
## how the run went; M11 grows this into real characters). Text only, chosen from the last summary.

const SPEAKER: String = "The Quartermaster"


static func line_for(profile: SaveProfile) -> String:
	var last: Dictionary = profile.get_last_run()
	if last.is_empty():
		return "First night on the walls? The dead leave Soul Shards behind. Spend them here."
	var chapter: int = int(last.get("chapter", 1))
	var row: int = int(last.get("row", 0))
	var bosses: Array = last.get("bosses", [])
	var relics: Array = last.get("relics", [])
	match String(last.get("result", "")):
		"won":
			return "You held! Every chapter. The bells will ring for a week." if profile.wins <= 1 \
				else "Another dawn won. They'll write songs, if anyone is left to sing."
		"abandoned":
			return "Walking away is sometimes wisdom. The walls will wait for you."
	if not bosses.is_empty():
		return "%s fell to you, and still the night came on. Rest, then go again." % bosses.back()
	if chapter >= 2:
		return "The marsh took you at row %d. The water there remembers everything." % row
	if row <= 2:
		return "A short night. Shake it off, knight: the first rows are the easiest to learn."
	if not relics.is_empty():
		return "That relic you found... I've seen ones like it. Keep your eyes open out there."
	return "The fortress fell at row %d. We rebuild. We always rebuild." % row
