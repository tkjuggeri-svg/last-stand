class_name FightReward
extends RefCounted
## What winning a run map fight gives (Level.start_encounter): an upgrade choice of `cards` cards
## (only rare ones if `rare_only`; 0 = none), bonus gold, and a repair of the fortress (a share of its
## max HP).

var cards: int = 0
var rare_only: bool = false
var gold: int = 0
var repair: float = 0.0


static func make(card_count: int, rare: bool = false, bonus_gold: int = 0, repair_share: float = 0.0) -> FightReward:
	var reward: FightReward = FightReward.new()
	reward.cards = card_count
	reward.rare_only = rare
	reward.gold = bonus_gold
	reward.repair = repair_share
	return reward
