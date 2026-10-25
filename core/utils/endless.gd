class_name Endless
## Endless mode's rules (M12), "Descend": after the last chapter's boss the run may go on through more
## tier-3 biomes, each a short map and tougher than the one before. Rules only: RunState keeps the depth,
## MapFlow applies the health scale, Main runs the flow.

## Rows of a descended chapter, boss row included.
const ROWS: int = 6
## Enemy health, x this per depth.
const HEALTH_PER_DEPTH: float = 1.3
## Shards paid for reaching depth d: SHARDS_PER_DEPTH * d (summed over the depths reached).
const SHARDS_PER_DEPTH: int = 10


## The enemies' extra health at `depth` (1 at depth 0).
static func health_scale(depth: int) -> float:
	return pow(HEALTH_PER_DEPTH, depth)


## Shards for reaching `depth`: 10 for depth 1, 10 + 20 for depth 2, ...
static func shards(depth: int) -> int:
	return SHARDS_PER_DEPTH * ((depth * (depth + 1)) >> 1)  # 1 + 2 + ... + depth


## A short copy of `base` for the descent to `depth`: 6 rows (battles, an elite, a merchant, the boss).
static func short_chapter(base: ChapterData, depth: int) -> ChapterData:
	var chapter: ChapterData = base.duplicate()
	chapter.rows = ROWS
	chapter.row_sizes = [2, 3, 3, 2, 2]
	chapter.battle_rows = [1]
	chapter.merchant_row = ROWS - 1
	chapter.first_elite_row = 3  # the elites are authored for rows 3-6
	chapter.min_mixed_combat = 1
	chapter.display_name = "Depth %d: %s" % [depth, base.display_name]
	return chapter


## True if `chapter` is already a descended copy.
static func is_short(chapter: ChapterData) -> bool:
	return chapter != null and chapter.rows == ROWS
