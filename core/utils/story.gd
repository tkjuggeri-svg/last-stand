class_name Story
## The story's rules (M11), on a StoryBook and a SaveProfile: what a character says now, which beat they
## want to tell, which lore is unlocked, which ending a finale boss gives. Rules only: the screens show it.


## The line `character` says now: the highest priority of those whose condition holds ("" if none).
static func line_for(book: StoryBook, profile: SaveProfile, character: StringName) -> String:
	var best: HubLine = null
	for line: HubLine in book.lines:
		if line.character == character and (line.condition == null or line.condition.holds(profile)):
			if best == null or line.priority > best.priority:
				best = line
	return best.text if best != null else ""


## The next beat `character` has to tell: the first by order that is not heard and whose condition holds.
static func next_beat(book: StoryBook, profile: SaveProfile, character: StringName) -> StoryBeat:
	var best: StoryBeat = null
	for beat: StoryBeat in book.beats:
		if beat.character != character or profile.beats_seen.has(String(beat.id)):
			continue
		if beat.condition != null and not beat.condition.holds(profile):
			continue
		if best == null or beat.order < best.order:
			best = beat
	return best


## The heard beats of `character`, in order.
static func heard_beats(book: StoryBook, profile: SaveProfile, character: StringName) -> Array[StoryBeat]:
	var heard: Array[StoryBeat] = []
	for beat: StoryBeat in book.beats:
		if beat.character == character and profile.beats_seen.has(String(beat.id)):
			heard.append(beat)
	heard.sort_custom(func(a: StoryBeat, b: StoryBeat) -> bool: return a.order < b.order)
	return heard


## True if the Chronicle entry `entry` is unlocked.
static func is_unlocked(entry: LoreEntry, profile: SaveProfile) -> bool:
	if entry.kind == LoreEntry.Kind.FOE:
		return profile.foes_seen.has(String(entry.key))
	return profile.places_seen.has(String(entry.key))


## The ending after finale boss `boss` (an enemy file name). Once all the normal endings have been seen, a
## win gives the secret one instead (once). Null if none is defined.
static func ending_for(book: StoryBook, profile: SaveProfile, boss: StringName) -> EndingData:
	var own: EndingData = null
	var secret: EndingData = null
	var all_seen: bool = true
	for ending: EndingData in book.endings:
		if ending.secret:
			secret = ending
			continue
		if ending.boss == boss:
			own = ending
		all_seen = all_seen and profile.endings.has(String(ending.id))
	if secret != null and all_seen and not profile.endings.has(String(secret.id)):
		return secret
	return own
