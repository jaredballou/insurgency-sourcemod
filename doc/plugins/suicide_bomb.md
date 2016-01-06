<a name='suicide_bomb'>
---
### Suicide Bombers 0.0.5</a>
Adds suicide bomb for bots

 * [Plugin - suicide_bomb.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/suicide_bomb.smx?raw=true)
 * [Source - suicide_bomb.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/suicide_bomb.sp?raw=true)

Adds a suicide bomb effect that creates an IED at the player's origin and immediately detonates. Release 1 has all 'bomber' class players detonate on death, which is very annoying in game but is a proof of concept.

#### Dependencies
 * [Source Include - insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)

#### CVAR List
 * "sm_suicidebomb_" "" //
 * "sm_suicidebomb_enabled" "0" //sets whether suicide bombs are enabled
 * "sm_suicidebomb_explode_armed" "0" //Explode when killed if C4 or IED is in hand
 * "sm_suicidebomb_death_chance" "0.1" //Chance as a fraction of 1 that a bomber will explode when killed
 * "sm_suicidebomb_bots_only" "1" //Only apply suicide bomber code to bots
 * "sm_suicidebomb_auto_detonate_range" "0" //Range at which to automatically set off the bomb
 * "sm_suicidebomb_auto_detonate_count" "2" //Do not detonate until this many enemies are in range
 * "sm_suicidebomb_strip_weapons" "1" //Remove all weapons from suicide bombers except the bomb
 * "sm_suicidebomb_player_classes" "sapper" //bomber suicide Player classes to apply suicide bomber changes to

#### Todo
 * [ ] Add bot targeting and behavior to make them seek players
 * [ ] Add functionality to have bots blow themselves up when they run into a group of players
 * [X] Create CVAR to enable random suicide bomb detonation based on role
 * [X] Create CVAR to enable suicide bomb when IED phone is out
 * [ ] Create CVAR to allow dropping of TIMED bomb. Some sort of warning, or maybe a disarm feature?
 * [ ] Sound effect before detonation, obvious choice is Aloha Snackbar.
 * [ ] Add logic to not detonate when in a group, unless killed by headshot? Figure out the best way to balance gameplay.
 * [ ] Work on PVP mode and figuring out how to balance when a player is using the suicide bomb rather than a bot.


