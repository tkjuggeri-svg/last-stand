class_name ChapterCarry
extends RefCounted
## What a cleared chapter's level hands to the next chapter's (Level.carry_out / carry_in): gold with
## every tower packed up for all it cost (`refund`: that part), the run's upgrades, the hero's lives,
## and the fortress's HP before its repair between chapters.

var gold: int = 0
var refund: int = 0
var upgrades: Array[UpgradeData] = []
var lives_left: int = 0
var fortress_health: int = 0
