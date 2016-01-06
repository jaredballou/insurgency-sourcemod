<a name='rpgdrift'>
---
### RPG Adjustments 0.0.3</a>
Adjusts behavior of RPG rounds

 * [Plugin - rpgdrift.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/rpgdrift.smx?raw=true)
 * [Source - rpgdrift.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/rpgdrift.sp?raw=true)

Add slight nudges to in-flight rockets to reduce punishment of laser beam RPGs. This currently works, but affects all RPGs all the time.

#### CVAR List
 * "sm_rpgdrift_enabled" "1" //Sets whether RPG drifting is enabled
 * "sm_rpgdrift_amount" "2.0" //Sets RPG drift max change per tick
 * "sm_rpgdrift_chance" "0.25" //Chance as a fraction of 1 that a player-fired rocket will be affected
 * "sm_rpgdrift_always_bots" "1" //Always affect bot-fired rockets

#### Todo
 * [X] Nudge rocket in flight
 * [X] Randomized chance of happening, default 10% for players?
 * [X] CVAR Variables to set amount of drift, chance, and option to always force drift for bots.


