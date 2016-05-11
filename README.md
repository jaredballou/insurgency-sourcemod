# SourceMod for Insurgency
This repository has a complete installation of SourceMod, including all my plugins and source files. It's updated regularly, kept in sync with upstream, and includes a ton of stuff. It's still very much a development branch, so be aware that almost all the plugins I am working on are still pretty new and could be buggy.
##Plugin list
These plugins are all provided as-is, I do my best to document and describe them but they are all potentially broken, so be aware. Please send me feedback and bug reports to help keep these working.
<a name='ammocheck'>
---
### Ammo Check 0.0.7</a>
Adds a check_ammo command for clients to get approximate ammo left in magazine, and display the same message when loading a new magazine

 * [Plugin - ammocheck.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/ammocheck.smx?raw=true)
 * [Source - ammocheck.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/ammocheck.sp?raw=true)


#### Dependencies
 * [Source Include - insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)

#### CVAR List
 * "sm_ammocheck_enabled" "1" //sets whether ammo check is enabled

#### Command List
 * "check_ammo" // Command_Check_Ammo

<a name='botcount'>
---
### Bot Counter 0.0.2</a>
Shows Bots Left Alive

 * [Plugin - botcount.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/botcount.smx?raw=true)
 * [Source - botcount.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/botcount.sp?raw=true)


#### Dependencies
 * [Source Include - insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)

#### CVAR List
 * "sm_botcount_enabled" "0" //sets whether bot naming is enabled
 * "sm_botcount_timer" "60" //Frequency to show count

<a name='botnames'>
---
### Bot Names 1.0.2</a>
Gives automatic names to bots on creation.

 * [Plugin - botnames.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/botnames.smx?raw=true)
 * [Source - botnames.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/botnames.sp?raw=true)


#### CVAR List
 * "sm_botnames_enabled" "1" //sets whether bot naming is enabled
 * "sm_botnames_prefix" "" //sets a prefix for bot names
 * "sm_botnames_random" "1" //sets whether to randomize names used
 * "sm_botnames_announce" "0" //sets whether to announce bots when added
 * "sm_botnames_suppress" "1" //sets whether to supress join/team change/name change bot messages
 * "sm_botnames_list" "default" //Set list to use for bots

<a name='botspawns'>
---
### Bot Spawns 0.3.0</a>
Adds a number of options and ways to handle bot spawns

 * [Plugin - botspawns.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/botspawns.smx?raw=true)
 * [Source - botspawns.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/botspawns.sp?raw=true)


#### Dependencies
 * [Source Include - navmesh.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/navmesh.inc?raw=true)
 * [Source Include - insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)
 * [gamedata/insurgency.games.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/gamedata/insurgency.games.txt?raw=true)

#### CVAR List
 * "sm_botspawns_enabled" "0" //Enable enhanced bot spawning features
 * "sm_botspawns_spawn_mode" "0" //Only normal spawnpoints at the objective, the old way
 * "sm_botspawns_counterattack_mode" "0" //Do not alter default game spawning during counterattacks
 * "sm_botspawns_counterattack_finale_infinite" "0" //Obey sm_botspawns_counterattack_respawn_mode
 * "sm_botspawns_counterattack_frac" "0.5" //Multiplier to total bots for spawning in counterattack wave
 * "sm_botspawns_min_counterattack_distance" "3600" //Min distance from counterattack objective to spawn
 * "sm_botspawns_min_spawn_delay" "1" //Min delay in seconds for spawning. Set to 0 for instant.
 * "sm_botspawns_max_spawn_delay" "30" //Max delay in seconds for spawning. Set to 0 for instant.
 * "sm_botspawns_min_player_distance" "1200" //Min distance from players to spawn
 * "sm_botspawns_max_player_distance" "16000" //Max distance from players to spawn
 * "sm_botspawns_min_objective_distance" "1" //Min distance from next objective to spawn
 * "sm_botspawns_max_objective_distance" "12000" //Max distance from next objective to spawn
 * "sm_botspawns_min_frac_in_game" "0.75" //Min multiplier of bot quota to have alive at any time. Set to 1 to emulate standard spawning.
 * "sm_botspawns_max_frac_in_game" "1" //Max multiplier of bot quota to have alive at any time. Set to 1 to emulate standard spawning.
 * "sm_botspawns_total_spawn_frac" "1.75" //Total number of bots to spawn as multiple of number of bots in game to simulate larger numbers. 1 is standard, values less than 1 are not supported.
 * "sm_botspawns_min_fireteam_size" "3" //Min number of bots to spawn per fireteam. Default 3
 * "sm_botspawns_max_fireteam_size" "5" //Max number of bots to spawn per fireteam. Default 5
 * "sm_botspawns_stop_spawning_at_objective" "1" //Stop spawning new bots when near next objective
 * "sm_botspawns_remove_unseen_when_capping" "1" //Silently kill off all unseen bots when capping next point
 * "sm_botspawns_spawn_snipers_alone" "1" //Spawn snipers alone, can be 50% further from the objective than normal bots if this is enabled?

<a name='cooplobby'>
---
### Coop Lobby Override 0.0.1</a>
Plugin for overriding Insurgency Coop to 16 players

 * [Plugin - cooplobby.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/cooplobby.smx?raw=true)
 * [Source - cooplobby.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/cooplobby.sp?raw=true)


<a name='cvarlist'>
---
### CVAR List 0.0.1</a>
Upholder of the [BFG], modified by Jared Ballou (jballou)

 * [Plugin - cvarlist.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/cvarlist.smx?raw=true)
 * [Source - cvarlist.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/cvarlist.sp?raw=true)


<a name='damagemod'>
---
### Damage Modifier 0.0.2</a>
Modifies damage before applying to players

 * [Plugin - damagemod.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/damagemod.smx?raw=true)
 * [Source - damagemod.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/damagemod.sp?raw=true)


#### Dependencies
 * [Source Include - insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)

#### CVAR List
 * "sm_damagemod_enabled" "PLUGIN_WORKING" //Enable Damage Mod plugin
 * "sm_damagemod_ff_min_distance" "120" //Minimum distance between players for Friendly Fire to register

<a name='dropweapon'>
---
### Drop Weapon 0.0.2</a>
Adds a drop command

 * [Plugin - dropweapon.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/dropweapon.smx?raw=true)
 * [Source - dropweapon.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/dropweapon.sp?raw=true)


#### Dependencies
 * [Source Include - insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)

#### CVAR List
 * "sm_dropweapon_enabled" "PLUGIN_WORKING" //sets whether weapon dropping is enabled

#### Command List
 * "drop_weapon" // Command_Drop_Weapon

<a name='hlstatsx'>
---
### HLStatsX CE Ingame Plugin 1.6.19</a>
Provides ingame functionality for interaction from an HLstatsX CE installation

 * [Plugin - hlstatsx.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/hlstatsx.smx?raw=true)
 * [Source - hlstatsx.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/hlstatsx.sp?raw=true)


#### Dependencies
 * [Third-Party Plugin: clientprefs](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/clientprefs.smx?raw=true)

#### CVAR List
 * "hlxce_webpage" "http://www.hlxcommunity.com" //http://www.hlxcommunity.com
 * "hlx_block_commands" "1" //If activated HLstatsX commands are blocked from the chat area
 * "hlx_message_prefix" "" //Define the prefix displayed on every HLstatsX ingame message
 * "hlx_protect_address" "" //Address to be protected for logging/forwarding
 * "hlx_server_tag" "1" //If enabled, adds \HLstatsX:CE\ to server tags on supported games. 1 = Enabled

<a name='insmaps'>
---
### Map List 1.4.1</a>
Lists all maps and modes available

 * [Plugin - insmaps.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/disabled/insmaps.smx?raw=true)
 * [Source - insmaps.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/insmaps.sp?raw=true)


#### Dependencies
 * [Source Include - insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)

<a name='insurgency'>
---
### Insurgency Support Library 1.3.3</a>
Provides functions to support Insurgency and fixes logging

 * [Plugin - insurgency.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/insurgency.smx?raw=true)
 * [Source - insurgency.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/insurgency.sp?raw=true)


#### Dependencies
 * [Source Include - insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)
 * [gamedata/insurgency.games.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/gamedata/insurgency.games.txt?raw=true)
 * [translations/insurgency.phrases.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/translations/insurgency.phrases.txt?raw=true)

#### CVAR List
 * "sm_insurgency_enabled" "1" //sets whether log fixing is enabled
 * "sm_insurgency_checkpoint_capture_player_ratio" "0.5" //Fraction of living players required to capture in Checkpoint
 * "sm_insurgency_checkpoint_counterattack_capture" "0" //Enable counterattack by bots to capture points in Checkpoint
 * "sm_insurgency_infinite_ammo" "0" //Infinite ammo, still uses magazines and needs to reload
 * "sm_insurgency_infinite_magazine" "0" //Infinite magazine, will never need reloading.
 * "sm_insurgency_disable_sliding" "0" //0: do nothing, 1: disable for everyone, 2: disable for Security, 3: disable for Insurgents
 * "sm_insurgency_log_level" "error" //Logging level, values can be: all, trace, debug, info, warn, error

<a name='magnifier'>
---
### Magnifier 0.0.1</a>
Adds FOV switch to emulate flip to side magnifiers

 * [Plugin - magnifier.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/disabled/magnifier.smx?raw=true)
 * [Source - magnifier.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/magnifier.sp?raw=true)


#### Dependencies
 * [translations/common.phrases.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/translations/common.phrases.txt?raw=true)

#### CVAR List
 * "sm_magnifier_zoom" "60" //zoom level for magnifier
 * "sm_magnifier_shots" "0" //Allow or disallow shots while using magnifier. 1 = allow. 0 = disallow.);
 * "sm_magnifier_adminflag" "0" //Admin flag required to use magnifier. 0 = No flag needed. Can use a b c ....);

#### Command List
 * "sm_magnifier" // ToggleMagnifier

<a name='navmesh-export'>
---
### Navmesh JSON Export 0.0.4</a>
Exports navmesh data in JSON format

 * [Plugin - navmesh-export.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/disabled/navmesh-export.smx?raw=true)
 * [Source - navmesh-export.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/navmesh-export.sp?raw=true)


#### Dependencies
 * [Source Include - navmesh.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/navmesh.inc?raw=true)

#### CVAR List
 * "sm_navmesh_export_enabled" "0" //sets whether this plugin is enabled

<a name='navmesh'>
---
### Navmesh Parser 1.0.4</a>
Read navigation mesh

 * [Plugin - navmesh.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/navmesh.smx?raw=true)
 * [Source - navmesh.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/navmesh.sp?raw=true)


#### Dependencies
 * [Source Include - navmesh.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/navmesh.inc?raw=true)

<a name='newspawn'>
---
### New Spawn 0.0.1</a>
New spawning plugin

 * [Plugin - newspawn.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/disabled/newspawn.smx?raw=true)
 * [Source - newspawn.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/newspawn.sp?raw=true)


#### CVAR List
 * "sm_sprinklers_enabled" "0" //Set to 1 to remove sprinklers. 0 leaves them alone.

<a name='nofog'>
---
### No Fog 0.0.1</a>
Removes fog

 * [Plugin - nofog.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/nofog.smx?raw=true)
 * [Source - nofog.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/nofog.sp?raw=true)


#### CVAR List
 * "sm_nofog_enabled" "1" //sets whether bot naming is enabled

<a name='respawn'>
---
### Player Respawn 1.8.0</a>
Respawn players

 * [Plugin - respawn.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/respawn.smx?raw=true)
 * [Source - respawn.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/respawn.sp?raw=true)


#### Dependencies
 * [Source Include - insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)
 * [gamedata/plugin.respawn.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/gamedata/plugin.respawn.txt?raw=true)
 * [translations/common.phrases.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/translations/common.phrases.txt?raw=true)
 * [translations/respawn.phrases.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/translations/respawn.phrases.txt?raw=true)
 * [Third-Party Plugin: adminmenu](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/adminmenu.smx?raw=true)

#### CVAR List
 * "sm_respawn_enabled" "0" //Automatically respawn players when they die; 0 - disabled, 1 - enabled);
 * "sm_respawn_delay" "1.0" //How many seconds to delay the respawn);
 * "sm_respawn_counterattack" "0" //Respawn during counterattack?
 * "sm_respawn_final_counterattack" "0" //Respawn during final counterattack?
 * "sm_respawn_count" "0" //Respawn all players this many times);
 * "sm_respawn_count_team2" "-1" //Respawn all Team 2 players this many times);
 * "sm_respawn_count_team3" "-1" //Respawn all Team 3 players this many times);
 * "sm_respawn_reset_each_round" "1" //Reset player respawn counts each round);
 * "sm_respawn_reset_each_objective" "1" //Reset player respawn counts each objective);

<a name='restrictedarea'>
---
### Restricted Area Removal 0.0.1</a>
Plugin for removing Restricted Areas

 * [Plugin - restrictedarea.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/restrictedarea.smx?raw=true)
 * [Source - restrictedarea.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/restrictedarea.sp?raw=true)


#### CVAR List
 * "sm_restrictedarea_enabled" "1" //sets whether bot naming is enabled

<a name='rpgdrift'>
---
### RPG Adjustments 0.0.3</a>
Adjusts behavior of RPG rounds

 * [Plugin - rpgdrift.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/rpgdrift.smx?raw=true)
 * [Source - rpgdrift.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/rpgdrift.sp?raw=true)


#### CVAR List
 * "sm_rpgdrift_enabled" "1" //Sets whether RPG drifting is enabled
 * "sm_rpgdrift_amount" "2.0" //Sets RPG drift max change per tick
 * "sm_rpgdrift_chance" "0.25" //Chance as a fraction of 1 that a player-fired rocket will be affected
 * "sm_rpgdrift_always_bots" "1" //Always affect bot-fired rockets

<a name='score'>
---
### Score Modifiers 0.0.1</a>
Adds a number of new ways to get score, or remove score for players

 * [Plugin - score.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/disabled/score.smx?raw=true)
 * [Source - score.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/score.sp?raw=true)


#### Dependencies
 * [Source Include - insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)
 * [translations/common.phrases.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/translations/common.phrases.txt?raw=true)
 * [translations/score.phrases.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/translations/score.phrases.txt?raw=true)

#### CVAR List
 * "sm_score_enabled" "1" //sets whether score modifier is enabled

#### Command List
 * "check_score" // Command_check_score

<a name='sprinklers'>
---
### Sprinkler Removal 0.0.2</a>
Plugin for removing Sprinkers

 * [Plugin - sprinklers.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/sprinklers.smx?raw=true)
 * [Source - sprinklers.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/sprinklers.sp?raw=true)


#### CVAR List
 * "sm_sprinklers_enabled" "0" //Set to 1 to remove sprinklers. 0 leaves them alone.

<a name='suicide_bomb'>
---
### Suicide Bombers 0.0.7</a>
Adds suicide bomb for bots

 * [Plugin - suicide_bomb.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/suicide_bomb.smx?raw=true)
 * [Source - suicide_bomb.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/suicide_bomb.sp?raw=true)


#### Dependencies
 * [Source Include - insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)

#### CVAR List
 * "sm_suicidebomb_" "" //
 * "sm_suicidebomb_enabled" "0" //sets whether suicide bombs are enabled
 * "sm_suicidebomb_spawn_delay" "30" //Do not detonate if player has been alive less than this many seconds
 * "sm_suicidebomb_explode_armed" "0" //Explode when killed if C4 or IED is in hand
 * "sm_suicidebomb_death_chance" "0.1" //Chance as a fraction of 1 that a bomber will explode when killed
 * "sm_suicidebomb_bots_only" "1" //Only apply suicide bomber code to bots
 * "sm_suicidebomb_auto_detonate_range" "0" //Range at which to automatically set off the bomb
 * "sm_suicidebomb_auto_detonate_count" "2" //Do not detonate until this many enemies are in range
 * "sm_suicidebomb_strip_weapons" "1" //Remove all weapons from suicide bombers except the bomb
 * "sm_suicidebomb_player_classes" "sapper" //bomber suicide Player classes to apply suicide bomber changes to

<a name='theaterpicker'>
---
### Theater Picker 0.0.4</a>
Allows admins to set theater, and clients to vote

 * [Plugin - theaterpicker.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/theaterpicker.smx?raw=true)
 * [Source - theaterpicker.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/theaterpicker.sp?raw=true)


#### Dependencies
 * [Source Include - insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)

#### CVAR List
 * "sm_theaterpicker_file" "PLUGIN_VERSION" //Custom theater file name
 * "sm_theaterpicker_config" "PLUGIN_VERSION" //Custom theater file name

<a name='theater_reconnect'>
---
### Theater Reconnect 0.0.1</a>
If a player connects with their mp_theater_override set to something other than what the server uses, set the cvar and retonnect them.

 * [Plugin - theater_reconnect.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/theater_reconnect.smx?raw=true)
 * [Source - theater_reconnect.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/theater_reconnect.sp?raw=true)


#### CVAR List
 * "sm_theater_reconnect_enabled" "1" //sets whether theater reconnect is enabled


 * <a href='#user-content-ammocheck'>Ammo Check 0.0.7</a>
 * <a href='#user-content-botcount'>Bot Counter 0.0.2</a>
 * <a href='#user-content-botnames'>Bot Names 1.0.2</a>
 * <a href='#user-content-botspawns'>Bot Spawns 0.3.0</a>
 * <a href='#user-content-cooplobby'>Coop Lobby Override 0.0.1</a>
 * <a href='#user-content-cvarlist'>CVAR List 0.0.1</a>
 * <a href='#user-content-damagemod'>Damage Modifier 0.0.2</a>
 * <a href='#user-content-dropweapon'>Drop Weapon 0.0.2</a>
 * <a href='#user-content-hlstatsx'>HLStatsX CE Ingame Plugin 1.6.19</a>
 * <a href='#user-content-insmaps'>Map List 1.4.1</a>
 * <a href='#user-content-insurgency'>Insurgency Support Library 1.3.3</a>
 * <a href='#user-content-magnifier'>Magnifier 0.0.1</a>
 * <a href='#user-content-navmesh-export'>Navmesh JSON Export 0.0.4</a>
 * <a href='#user-content-navmesh'>Navmesh Parser 1.0.4</a>
 * <a href='#user-content-newspawn'>New Spawn 0.0.1</a>
 * <a href='#user-content-nofog'>No Fog 0.0.1</a>
 * <a href='#user-content-respawn'>Player Respawn 1.8.0</a>
 * <a href='#user-content-restrictedarea'>Restricted Area Removal 0.0.1</a>
 * <a href='#user-content-rpgdrift'>RPG Adjustments 0.0.3</a>
 * <a href='#user-content-score'>Score Modifiers 0.0.1</a>
 * <a href='#user-content-sprinklers'>Sprinkler Removal 0.0.2</a>
 * <a href='#user-content-suicide_bomb'>Suicide Bombers 0.0.7</a>
 * <a href='#user-content-theater_reconnect'>Theater Reconnect 0.0.1</a>
 * <a href='#user-content-theaterpicker'>Theater Picker 0.0.4</a>
 * <a href='#user-content-weapon_pickup'>Weapon Pickup 0.0.2</a>

<a name='weapon_pickup'>
---
### Weapon Pickup 0.0.2</a>
Weapon Pickup logic for manipulating player inventory

 * [Plugin - weapon_pickup.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/weapon_pickup.smx?raw=true)
 * [Source - weapon_pickup.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/weapon_pickup.sp?raw=true)


#### Dependencies
 * [Source Include - insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)

#### CVAR List
 * "sm_weapon_pickup_enabled" "1" //sets whether weapon pickup manipulation is enabled

#### Command List
 * "wp_weaponslots" // Command_ListWeaponSlots weapon slots. Usage: wp_weaponslots [target]
 * "wp_weaponlist" // Command_ListWeapons all weapons. Usage: wp_weaponlist [target]
 * "wp_knife" // Command_Knife a knife. Usage: wp_knife [target]
 * "wp_removeweapons" // Command_RemoveWeapons all weapons. Usage: wp_removeweapons [target]

## Ideas to develop
This is a sort of scratchpad and todo list for things that I think of or people ask for me to work on.
* [X] Remove counterattack capture ability in checkpoint coop mode via a cvar. Having to capture a building and then stand inside it while it gets assaulted instead of choosing good firing positions outside makes the game switch from tight, careful action to Call of Duty twitch shooter.
* [X] Review bot CVARs and changes from last two patches to see if there are any new options to try or setting changes that can help get the bots to behave like mildly well trained, scared teenagers instead of a guy on a sunday stroll who can hipshoot you at a hundred meters.
* [ ] IR strobe on the back of US helmets for IFF. Possible to do with a particle effect or alpha/color mask, Source engine precompiled lighting makes actual strobes unlikely.
* [ ] IR laser? Is there a variable I can check to see if a player has NV enabled, and then how to control visibility of the beam per-client.
* [ ] Artillery, mortar, or air support SM plugin to give delayed but devastating damage on an area? How to balance and offset the massive power for the Insurgent side?
* [ ] Wounded/disabled players, can talk for very short time but no ability to move or shoot? Implement contact shots?
* [ ] Look at ability to modify game rules via tricky Sourcemod magic, like passing off spawning additional waves, spawning in staggered groups, and other fun things we need to do.
* [ ] Ability to loot ammo from dead bodies and have them added to the player's inventory properly. Needs to be sorted out how player inventory is handled, with the array method where each magazine's capacity is tracked and retained, and make sure we only pick up the right ammo for the primary weapon. The system needs to inform player "picked up one full AK74 magazine" or "picked up one nearly empty M16 magazine". Should loot from most full to least full, loot one mag per run of the command, and say how many mags still available to be looted. Add cvar-controlled timer to delay next loot/shoot/reload/switch for half a second or so to balance it. Add support for shared magazines, namely AKS74U/AK74 and M16/M4A1/MK18.
* [ ] Decouple flashbang visual impairment and audio impairment. The goal is to slightly increase flashed vision loss time, but greatly increase efefct and duration of audio impairment.
* [X] Add controls to disable bot shooting while sliding or jumping.
* [X] Add controls to disable firing for slight delay after jumping or falling.
* [ ] Add slot for "ear protection", can be Peltors, plugs, or nothing. Costs points, affects shots/frags/flashes impact on hearing
* [ ] Add slot for radio, allow Prox, Squad, or Team as options to select how widely they want to communicate. maybe some team-level abilities via radio?
* [ ] Add tripwires, timers, and daisy chains to IEDs for Insurgents, give them multiple IEDs and have a defuse mission
* [X] Add fragmentation effect to grenades, slightly reduce damage blast radius but shoots 60+ fragments (bullets) out in a random pattern to really clear a room
* [ ] Create config-driven rules-based tutorial mod to tell players about their chosen kits and loadout. Have events hooked to firing, killing, getting killed, etc. to use in tips.
* [ ] Add ability to place explosives (grenades with mechanical switches) as booby traps
* [ ] Add 100 round magazine for SAR that adds weight/recoil to promote bipod use in intermediate machinegun role
* [ ] Add deployable supply point to Squad Leader. Destructible cache point that can be deployed and packed. One per round so it needs to be protected.

