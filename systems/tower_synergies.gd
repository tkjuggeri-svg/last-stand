class_name TowerSynergies
## The rule of the tower pair bonuses (TowerSynergy): a tower's synergy is active while a tower of its
## partner type (not itself) stands within the synergy's reach. TowerBuilder keeps every tower's active
## synergies up to date; the build menu asks who the partners are, to draw the links.


## The synergies of `tower` that `towers` (the level's towers) make active now.
static func active_for(tower: Tower, towers: Array[Tower]) -> Array[TowerSynergy]:
	var active: Array[TowerSynergy] = []
	for synergy: TowerSynergy in tower.data.synergies:
		if not partners(synergy, tower.global_position, towers, tower).is_empty():
			active.append(synergy)
	return active


## The towers that would make `synergy` active for a tower at `at` (`except`: the tower itself, or
## null for one not built yet).
static func partners(synergy: TowerSynergy, at: Vector2, towers: Array[Tower], except: Tower = null) -> Array[Tower]:
	return towers.filter(func(other: Tower) -> bool:
		return other != except and other.data.id == synergy.partner_id and other.global_position.distance_to(at) <= synergy.reach)


## Every partner tower of any of `data`'s synergies, for a tower of `data` at `at`.
static func all_partners(data: TowerData, at: Vector2, towers: Array[Tower], except: Tower = null) -> Array[Tower]:
	var found: Array[Tower] = []
	for synergy: TowerSynergy in data.synergies:
		for other: Tower in partners(synergy, at, towers, except):
			if not found.has(other):
				found.append(other)
	return found


## The tower menu's lines about `data`'s pair bonuses: which are on (`active`), and what each needs,
## naming the partner from `catalog` (its id if it isn't built or unlocked in this run).
static func describe(data: TowerData, active: Array[TowerSynergy], catalog: Array[TowerData]) -> String:
	var lines: Array[String] = []
	for synergy: TowerSynergy in data.synergies:
		var partner: String = String(synergy.partner_id).capitalize()
		for other: TowerData in catalog:
			if other.id == synergy.partner_id:
				partner = other.display_name
		lines.append("%s %s: %s %s" % ["Active:" if active.has(synergy) else "Pair bonus", synergy.display_name, synergy.describe_bonus(),
			"(%s nearby)" % partner if active.has(synergy) else "with a %s nearby" % partner])
	return "\n".join(lines)
