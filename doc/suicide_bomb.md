<a name="suicide_bomb">
### [INS] Suicide Bombers 0.0.7

Adds suicide bomb for bots
 * [Source - scripting/suicide_bomb.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/suicide_bomb.sp?raw=true)
 * [Plugin - plugins/suicide_bomb.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/suicide_bomb.smx?raw=true)

#### Dependencies

 * [Source - scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)

#### CVAR List

 * "sm_suicidebomb_auto_detonate_range" "0" // Range at which to automatically set off the bomb (0 is disabled)
 * "sm_suicidebomb_player_classes" "sapper bomber suicide" // Player classes to apply suicide bomber changes to
 * "sm_suicidebomb_enabled" "0" // sets whether suicide bombs are enabled
 * "sm_suicidebomb_spawn_delay" "30" // Do not detonate if player has been alive less than this many seconds
 * "sm_suicidebomb_auto_detonate_count" "2" // Do not detonate until this many enemies are in range
 * "sm_suicidebomb_explode_armed" "0" // Explode when killed if C4 or IED is in hand
 * "sm_suicidebomb_strip_weapons" "1" // Remove all weapons from suicide bombers except the bomb
 * "sm_suicidebomb_death_chance" "0.1" // Chance as a fraction of 1 that a bomber will explode when killed
 * "sm_suicidebomb_bots_only" "1" // Only apply suicide bomber code to bots

