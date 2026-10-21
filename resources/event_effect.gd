class_name EventEffect
extends Resource
## One consequence of an event's or a shrine's choice. EventResolver applies it to the chapter's level.

enum Type {
	GOLD,  ## gain `amount` gold (negative: lose it)
	GOLD_MULTIPLY,  ## multiply the gold by `factor`
	FORTRESS_DAMAGE,  ## the fortress takes `amount` damage (never below 1 HP)
	GRANT_UPGRADE,  ## take `upgrade` (a boon or a curse; shown with the run's upgrades)
	UPGRADE_CHOICE,  ## an upgrade choice of `amount` cards (`rare_only`)
	LOSE_LIFE,  ## the hero loses a life (never the last)
	LOSE_LAST_UPGRADE,  ## the most recent upgrade taken is lost
	FREE_TOWER_LEVEL,  ## the cheapest tower that can be upgraded goes up a level for free
	DESTROY_BEST_TOWER,  ## the highest-level tower crumbles (no refund)
	FREE_EVOLUTION,  ## the next evolution costs nothing
	NEXT_FIGHTS_AFFIX,  ## `affix` applies to the next `amount` fights (99: the rest of the chapter)
	MERCHANT_PRICES,  ## the next merchant's prices x `factor`
	EXTRA_FIGHT,  ## fight one wave of the next row's tier now; its reward: a choice of `amount` cards (`rare_only`)
	RELIC_CHOICE,  ## a relic choice of `amount` relics (M7.5)
}

@export var type: Type = Type.GOLD
@export var amount: int = 0
@export var factor: float = 1.0
@export var rare_only: bool = false
@export var upgrade: UpgradeData
@export var affix: AffixData
