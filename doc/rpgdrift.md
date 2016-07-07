<a name="rpgdrift">
### [INS] RPG Adjustments 0.0.3

Adjusts behavior of RPG rounds
 * [Source - scripting/rpgdrift.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/rpgdrift.sp?raw=true)
 * [Plugin - plugins/rpgdrift.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/rpgdrift.smx?raw=true)

#### Dependencies

 * [Source - scripting/include/smlib/entities.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/smlib/entities.inc?raw=true)

#### CVAR List

 * "sm_rpgdrift_enabled" "1" // Sets whether RPG drifting is enabled
 * "sm_rpgdrift_always_bots" "1" // Always affect bot-fired rockets
 * "sm_rpgdrift_chance" "0.25" // Chance as a fraction of 1 that a player-fired rocket will be affected
 * "sm_rpgdrift_amount" "2.0" // Sets RPG drift max change per tick

