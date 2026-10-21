extends RefCounted
## Gold bookkeeping for the balance tool (not shipped): where every coin of a run came from and where
## it went, per wave. A wave's row runs from its start to the next wave's start, so it holds the wave's
## kills and end-of-wave payouts and the build phase after it; row 0 is the build phase before wave 1.
## Income: kill gold per enemy type (before upgrades), the extra each kill-gold upgrade adds, the
## perfect-defense bonus, interest and sell refunds. Spending is reported by the tool (spend()), by
## category. "bank" is the unspent gold when the next wave starts.

const ENEMY_COLUMNS: Array[String] = ["ghoul", "hound", "brute", "cultist", "boss"]
const SPEND_COLUMNS: Array[String] = ["towers", "upgrades", "evolutions", "repairs", "lives"]

var _economy: Economy
var _rewards: WaveRewards
var _mods: RunModifiers
var _rows: Array[Dictionary] = [{}]


func _init(level: Level) -> void:
	_economy = level.get_node("%Economy")
	_rewards = level.get_node("%WaveRewards")
	_mods = level.get_node("%RunModifiers")
	var spawner: WaveSpawner = level.get_node("WaveSpawner")
	spawner.wave_started.connect(func(_n: int) -> void:
		_row()["bank"] = _economy.get_gold()
		_rows.append({}))
	spawner.enemy_killed.connect(_on_enemy_killed)
	_economy.gold_earned.connect(_on_gold_earned)


## The tool spent `amount` on `category` (one of SPEND_COLUMNS).
func spend(category: String, amount: int) -> void:
	_add("spent:" + category, amount)


## Gold a discount saved (counted apart from income).
func saved(source: String, amount: int) -> void:
	_add("saved:" + source, amount)


func total(prefix: String) -> int:
	var sum: int = 0
	for row: Dictionary in _rows:
		sum += _sum(row, prefix)
	return sum


## The per-wave table plus totals, as printable lines.
func report(title: String) -> Array[String]:
	_row()["bank"] = _economy.get_gold()
	var lines: Array[String] = ["", "gold: " + title]
	var head: String = "  %4s" % "wave"
	for column: String in ENEMY_COLUMNS:
		head += " %7s" % column
	head += " %7s %7s %7s %7s %6s |" % ["upgrades", "perfect", "interest", "refund", "IN"]
	for column: String in SPEND_COLUMNS:
		head += " %8s" % column
	head += " %6s | %5s  %s" % ["OUT", "bank", "upgrade gold, discounts"]
	lines.append(head)
	for i: int in _rows.size():
		lines.append(_line("%4s" % ("pre" if i == 0 else str(i)), _rows[i], int(_rows[i].get("bank", 0))))
	var all: Dictionary = {}
	for row: Dictionary in _rows:
		for key: String in row:
			if key != "bank":
				all[key] = int(all.get(key, 0)) + int(row[key])
	lines.append(_line("all", all, _economy.get_gold()))
	return lines


func _line(label: String, row: Dictionary, bank: int) -> String:
	var line: String = "  " + label
	for column: String in ENEMY_COLUMNS:
		line += " %7d" % int(row.get("kill:" + column, 0))
	line += " %8d %7d %7d %7d %6d |" % [_sum(row, "upg:"), int(row.get("perfect", 0)), int(row.get("interest", 0)),
		int(row.get("refund", 0)), _income(row)]
	for column: String in SPEND_COLUMNS:
		line += " %8d" % int(row.get("spent:" + column, 0))
	line += " %6d | %5d  %s" % [_sum(row, "spent:"), bank, _details(row)]
	return line


func _details(row: Dictionary) -> String:
	var parts: Array[String] = []
	for key: String in row:
		if key.begins_with("upg:") or key.begins_with("saved:"):
			parts.append("%s %d" % [key, int(row[key])])
	return ", ".join(parts)


func _income(row: Dictionary) -> int:
	return _sum(row, "kill:") + _sum(row, "upg:") + int(row.get("perfect", 0)) + int(row.get("interest", 0)) \
		+ int(row.get("refund", 0))


func _sum(row: Dictionary, prefix: String) -> int:
	var sum: int = 0
	for key: String in row:
		if key.begins_with(prefix):
			sum += int(row[key])
	return sum


func _row() -> Dictionary:
	return _rows.back()


func _add(key: String, amount: int) -> void:
	_row()[key] = int(_row().get(key, 0)) + amount


func _on_enemy_killed(enemy: Enemy) -> void:
	if not is_instance_valid(enemy):
		return
	var base: int = _rewards.base_kill_reward(enemy)
	var id: String = "boss" if enemy.data.is_boss else enemy.data.resource_path.get_file().get_basename()
	_add("kill:" + id, base)
	var extra: int = _rewards.kill_reward(enemy) - base
	if extra == 0:
		return
	# Split the extra between the kill-gold upgrades by their share of the bonus.
	var shares: Dictionary = {}
	var share_total: float = 0.0
	for data: UpgradeData in _mods.get_taken():
		for modifier: StatModifier in data.modifiers:
			if modifier.stat == RunModifiers.KILL_GOLD and modifier.percent != 0.0:
				shares[String(data.id)] = float(shares.get(String(data.id), 0.0)) + modifier.percent
				share_total += modifier.percent
	if share_total == 0.0:
		_add("upg:other", extra)
		return
	for id_key: String in shares:
		_add("upg:" + id_key, roundi(extra * float(shares[id_key]) / share_total))


func _on_gold_earned(amount: int, source: Economy.Source) -> void:
	match source:
		Economy.Source.PERFECT_DEFENSE:
			_add("perfect", amount)
		Economy.Source.EARLY_CALL:
			_add("early", amount)
		Economy.Source.INTEREST:
			_add("interest", amount)
		Economy.Source.REFUND:
			_add("refund", amount)
