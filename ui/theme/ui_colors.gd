class_name UiColors
## The UI's colours in one place (M8.5 consistency pass), the same as the theme's label variations:
## code that must colour something by hand (a disabled button's text, a feed line, a banner) uses
## these; labels use the variations (HeaderLabel, DimLabel, GoodLabel, WarnLabel, RelicLabel).

## Headers, gold, rare cards (HeaderLabel).
const GOLD: Color = Color(0.94, 0.82, 0.48, 1)
## Body text (Label).
const TEXT: Color = Color(0.93, 0.9, 0.84, 1)
## Secondary text (DimLabel).
const DIM: Color = Color(0.72, 0.7, 0.78, 1)
## Good news, things gained (GoodLabel).
const GOOD: Color = Color(0.6, 0.9, 0.5, 1)
## Errors, what can't be done or afforded (WarnLabel).
const WARN: Color = Color(1.0, 0.47, 0.4, 1)
## Relics (RelicLabel).
const RELIC: Color = Color(0.82, 0.66, 1.0, 1)


## The label variation for a card's name: a relic's, a rare card's, or the plain one.
static func card_title(data: UpgradeData) -> StringName:
	if data is RelicData:
		return &"RelicLabel"
	return &"HeaderLabel" if data.rarity == UpgradeData.Rarity.RARE else &""
