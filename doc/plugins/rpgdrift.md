### RPG Adjustments (version 0.0.3)
Adjusts behavior of RPG rounds

[Plugin](plugins/rpgdrift.smx?raw=true) - [Source](scripting/rpgdrift.sp)

Add slight nudges to in-flight rockets to reduce punishment of laser beam RPGs. This currently works, but affects all RPGs all the time.

#### CVAR List
 * sm_rpgdrift_enabled: Sets whether RPG drifting is enabled (default: 1)
 * sm_rpgdrift_amount: Sets RPG drift max change per tick (default: 2.0)
 * sm_rpgdrift_chance: Chance as a fraction of 1 that a player-fired rocket will be affected (default: 0.25)
 * sm_rpgdrift_always_bots: Always affect bot-fired rockets (default: 1)

#### Todo
 * [X] Nudge rocket in flight
 * [X] Randomized chance of happening, default 10% for players?
 * [X] CVAR Variables to set amount of drift, chance, and option to always force drift for bots.


