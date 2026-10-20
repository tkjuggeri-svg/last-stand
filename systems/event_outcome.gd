class_name EventOutcome
extends RefCounted
## What an event's or a shrine's answer leaves to play (EventResolver.apply): its result text, upgrade
## choices to make one after another, and an extra fight (with its reward) to play now (null = none).

var text: String = ""
var choices: Array[FightReward] = []
var extra_fight: FightReward
