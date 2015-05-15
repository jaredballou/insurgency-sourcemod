---
### Suicide Bombers (version 0.0.4)
Adds suicide bomb for bots

 * [Plugin - suicide_bomb.smx](plugins/suicide_bomb.smx?raw=true)
 * [Source - suicide_bomb.sp](https://raw.githubusercontent.com/jaredballou/insurgency-sourcemod/master/scripting/suicide_bomb.sp)

Adds a suicide bomb effect that creates an IED at the player's origin and immediately detonates. Release 1 has all 'bomber' class players detonate on death, which is very annoying in game but is a proof of concept.

#### CVAR List
 * "sm_suicidebomb_enabled" "0" //sets whether suicide bombs are enabled
 * "sm_suicidebomb_explode_armed" "0" //Explode when killed if C4 or IED is in hand
 * "sm_suicidebomb_death_chance" "0.1" //Chance as a fraction of 1 that a bomber will explode when killed

#### Todo
 * [ ] Add bot targeting and behavior to make them seek players
 * [ ] Add functionality to have bots blow themselves up when they run into a group of players
 * [X] Create CVAR to enable random suicide bomb detonation based on role
 * [X] Create CVAR to enable suicide bomb when IED phone is out
 * [ ] Create CVAR to allow dropping of TIMED bomb. Some sort of warning, or maybe a disarm feature?
 * [ ] Sound effect before detonation, obvious choice is Aloha Snackbar.
 * [ ] Add logic to not detonate when in a group, unless killed by headshot? Figure out the best way to balance gameplay.
 * [ ] Work on PVP mode and figuring out how to balance when a player is using the suicide bomb rather than a bot.


