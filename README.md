# SourceMod for Insurgency
This repository has a complete installation of SourceMod, including all my plugins and source files. It's updated regularly, kept in sync with upstream, and includes a ton of stuff. It's still very much a development branch, so be aware that almost all the plugins I am working on are still pretty new and could be buggy.
##Plugin list
These plugins are all provided as-is, I do my best to document and describe them but they are all potentially broken, so be aware. Please send me feedback and bug reports to help keep these working.

 * <a href='#ammocheck'>Ammo Check 1.0.0</a>
 * <a href='#botcount'>[INS] Bot Counter 0.0.2</a>
 * <a href='#botnames'>Bot Names 1.0.3</a>
 * <a href='#botspawns'>Bot Spawns 0.4.0</a>
 * <a href='#cooplobby'>Coop Lobby Override 0.0.1</a>
 * <a href='#cvarlist'>CVAR List 0.0.1</a>
 * <a href='#damagemod'>[INS] Damage Modifier 0.0.2</a>
 * <a href='#dropweapon'>[INS] Drop Weapon 0.0.2</a>
 * <a href='#events'>Event Logger 0.0.1</a>
 * <a href='#hlstatsx'>[INS] HLStatsX CE Ingame Plugin 1.6.19</a>
 * <a href='#insmaps'>[INS] Map List 1.4.1</a>
 * <a href='#insurgency'>[INS] Insurgency Support Library 1.3.5</a>
 * <a href='#magnifier'>[INS] Magnifier 0.0.1</a>
 * <a href='#nofog'>[INS] No Fog 0.0.1</a>
 * <a href='#respawn'>[INS] Player Respawn 1.8.1</a>
 * <a href='#restrictedarea'>[INS] Restricted Area Removal 0.0.1</a>
 * <a href='#rpgdrift'>[INS] RPG Adjustments 0.0.3</a>
 * <a href='#score'>[INS] Score Modifiers 0.0.1</a>
 * <a href='#sprinklers'>[INS] Sprinkler Removal 0.0.3</a>
 * <a href='#suicide_bomb'>[INS] Suicide Bombers 0.0.7</a>
 * <a href='#theater_reconnect'>[INS] Theater Reconnect 0.0.1</a>
 * <a href='#theaterpicker'>[INS] Theater Picker 0.0.4</a>
 * <a href='#votelog'>Vote Logging 0.0.2</a>
 * <a href='#weapon_pickup'>[INS] Weapon Pickup 0.1.0</a>

<a name="ammocheck">
### Ammo Check 1.0.0
Adds a check_ammo command for clients to get approximate ammo left in magazine, and display the same message when loading a new magazine
 * [Source - scripting/ammocheck.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/ammocheck.sp?raw=true)
 * [Plugin - plugins/ammocheck.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/ammocheck.smx?raw=true)
#### Dependencies
 * [Source - scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)
 * [Source - scripting/include/myinfo.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/myinfo.inc?raw=true)
#### CVAR List
 * "sm_ammocheck_version" "PLUGIN_VERSION" // PLUGIN_DESCRIPTION
 * "sm_ammocheck_attack_delay" "1" // Delay in seconds until next attack when checking ammo
 * "sm_ammocheck_enabled" "1" // sets whether ammo check is enabled
#### Command List
 * "check_ammo" // Check ammo of the current weapon
<a name="botcount">
### [INS] Bot Counter 0.0.2
Shows Bots Left Alive
 * [Source - scripting/botcount.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/botcount.sp?raw=true)
 * [Plugin - plugins/botcount.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/botcount.smx?raw=true)
#### Dependencies
 * [Source - scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)
 * [Source - scripting/include/myinfo.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/myinfo.inc?raw=true)
#### CVAR List
 * "sm_botcount_timer" "60" // Frequency to show count
 * "sm_botcount_version" "PLUGIN_VERSION" // PLUGIN_DESCRIPTION
 * "sm_botcount_enabled" "0" // sets whether bot naming is enabled
<a name="botnames">
### Bot Names 1.0.3
Gives automatic names to bots on creation.
 * [Source - scripting/botnames.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/botnames.sp?raw=true)
 * [Plugin - plugins/botnames.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/botnames.smx?raw=true)
#### Dependencies
 * [Source - scripting/include/myinfo.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/myinfo.inc?raw=true)
#### CVAR List
 * "sm_botnames_list" "default" // Set list to use for bots
 * "sm_botnames_enabled" "1" // sets whether bot naming is enabled
 * "sm_botnames_suppress" "1" // sets whether to supress join/team change/name change bot messages
 * "sm_botnames_version" "PLUGIN_VERSION" // PLUGIN_DESCRIPTION
 * "sm_botnames_random" "1" // sets whether to randomize names used
 * "sm_botnames_prefix" "" // sets a prefix for bot names (include a trailing space
 * "sm_botnames_announce" "0" // sets whether to announce bots when added
#### Command List
 * "sm_botnames_reload"
 * "sm_botnames_rename_all"
<a name="botspawns">
### Bot Spawns 0.4.0
Adds a number of options and ways to handle bot spawns
 * [Source - scripting/botspawns.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/botspawns.sp?raw=true)
 * [Plugin - plugins/botspawns.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/botspawns.smx?raw=true)
#### Dependencies
 * [Source - scripting/include/smlib.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/smlib.inc?raw=true)
 * [Source - scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)
 * [Source - scripting/include/navmesh.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/navmesh.inc?raw=true)
 * [Source - scripting/include/myinfo.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/myinfo.inc?raw=true)
 * [Plugin - gamedata/insurgency.games.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/gamedata/insurgency.games.txt?raw=true)
#### CVAR List
 * "sm_botspawns_enabled" "PLUGIN_WORKING" // Enable enhanced bot spawning features
 * "sm_botspawns_min_spawn_delay" "1" // Min delay in seconds for spawning. Set to 0 for instant.
 * "sm_botspawns_min_fireteam_size" "3" // Min number of bots to spawn per fireteam. Default 3
 * "sm_botspawns_spawn_mode" "0" // Only normal spawnpoints at the objective
 * "sm_botspawns_counterattack_finale_infinite" "0" // Obey sm_botspawns_counterattack_respawn_mode (0)
 * "sm_botspawns_counterattack_mode" "0" // Do not alter default game spawning during counterattacks (0)
 * "sm_botspawns_max_fireteam_size" "5" // Max number of bots to spawn per fireteam. Default 5
 * "sm_botspawns_total_spawn_frac" "1.75" // Total number of bots to spawn as multiple of number of bots in game to simulate larger numbers. 1 is standard
 * "sm_botspawns_spawn_attack_delay" "10" // Delay in seconds for spawning bots to wait before firing.
 * "sm_botspawns_spawn_snipers_alone" "1" // Spawn snipers alone
 * "sm_botspawns_max_objective_distance" "12000" // Max distance from next objective to spawn
 * "sm_botspawns_max_player_distance" "16000" // Max distance from players to spawn
 * "sm_botspawns_max_spawn_delay" "30" // Max delay in seconds for spawning. Set to 0 for instant.
 * "sm_botspawns_min_counterattack_distance" "3600" // Min distance from counterattack objective to spawn
 * "sm_botspawns_min_player_distance" "1200" // Min distance from players to spawn
 * "sm_botspawns_stop_spawning_at_objective" "1" // Stop spawning new bots when near next objective (1
 * "sm_botspawns_remove_unseen_when_capping" "1" // Silently kill off all unseen bots when capping next point (1
 * "sm_botspawns_min_objective_distance" "1" // Min distance from next objective to spawn
 * "sm_botspawns_counterattack_frac" "0.5" // Multiplier to total bots for spawning in counterattack wave
 * "sm_botspawns_version" "PLUGIN_VERSION" // PLUGIN_DESCRIPTION
 * "sm_botspawns_max_frac_in_game" "1" // Max multiplier of bot quota to have alive at any time. Set to 1 to emulate standard spawning.
 * "sm_botspawns_min_frac_in_game" "0.75" // Min multiplier of bot quota to have alive at any time. Set to 1 to emulate standard spawning.
<a name="cooplobby">
### Coop Lobby Override 0.0.1
Plugin for overriding Insurgency Coop to 16 players
 * [Source - scripting/cooplobby.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/cooplobby.sp?raw=true)
 * [Plugin - plugins/cooplobby.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/cooplobby.smx?raw=true)
#### Dependencies
 * [Source - scripting/include/myinfo.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/myinfo.inc?raw=true)
<a name="cvarlist">
### CVAR List 0.0.1
CVAR and command list dumper
 * [Source - scripting/cvarlist.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/cvarlist.sp?raw=true)
 * [Plugin - plugins/cvarlist.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/cvarlist.smx?raw=true)
#### Dependencies
 * [Source - scripting/include/myinfo.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/myinfo.inc?raw=true)
#### Command List
 * "sm_cvarlist"
 * "sm_cmdlist"
<a name="damagemod">
### [INS] Damage Modifier 0.0.2
Modifies damage before applying to players
 * [Source - scripting/damagemod.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/damagemod.sp?raw=true)
 * [Plugin - plugins/damagemod.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/damagemod.smx?raw=true)
#### Dependencies
 * [Source - scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)
#### CVAR List
 * "sm_damagemod_version" "PLUGIN_VERSION" // PLUGIN_DESCRIPTION
 * "sm_damagemod_ff_min_distance" "120" // Minimum distance between players for Friendly Fire to register
 * "sm_damagemod_enabled" "PLUGIN_WORKING" // Enable Damage Mod plugin
<a name="dropweapon">
### [INS] Drop Weapon 0.0.2
Adds a drop command
 * [Source - scripting/dropweapon.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/dropweapon.sp?raw=true)
 * [Plugin - plugins/dropweapon.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/dropweapon.smx?raw=true)
#### Dependencies
 * [Source - scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)
#### CVAR List
 * "sm_dropweapon_enabled" "PLUGIN_WORKING" // sets whether weapon dropping is enabled
 * "sm_dropweapon_version" "PLUGIN_VERSION" // PLUGIN_DESCRIPTION
#### Command List
 * "drop_weapon"
<a name="events">
### Event Logger 0.0.1
Log events to client or server
 * [Source - scripting/events.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/events.sp?raw=true)
 * [Plugin - plugins/events.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/events.smx?raw=true)
#### Dependencies
 * [Source - scripting/include/myinfo.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/myinfo.inc?raw=true)
#### CVAR List
 * "sm_events_prefix" "sPrefix" // What to prefix on event messages
 * "sm_events_version" "PLUGIN_VERSION" // Version of Event Info on this server
#### Command List
 * "sm_events_keylistentoall" // Start listening to all event keys
 * "sm_events_stoplisten" // Stop listening to all events and keys
 * "sm_events_listkeys" // List all keys for an event
 * "sm_events_listevents" // List all hooked events
 * "sm_events_searchevents" // Search for events
 * "sm_events_keylisten" // Start or stop listening to an event's keys
 * "sm_events_listentoall" // Start listening to all events
 * "sm_events_listen" // Start or stop listening to an event
<a name="hlstatsx">
### [INS] HLStatsX CE Ingame Plugin 1.6.19
Provides ingame functionality for interaction from an HLstatsX CE installation
 * [Source - scripting/hlstatsx.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/hlstatsx.sp?raw=true)
 * [Plugin - plugins/hlstatsx.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/hlstatsx.smx?raw=true)
#### Dependencies
 * [Source - scripting/include/loghelper.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/loghelper.inc?raw=true)
 * [Source - scripting/include/cstrike.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/cstrike.inc?raw=true)
 * [Source - scripting/include/clientprefs.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/clientprefs.inc?raw=true)
#### CVAR List
 * "hlxce_version" "" // HLstatsX:CE
 * "hlxce_plugin_version" "PLUGIN_VERSION" // HLstatsX:CE Ingame Plugin
 * "hlx_block_commands" "1" // If activated HLstatsX commands are blocked from the chat area
 * "hlx_protect_address" "" // Address to be protected for logging/forwarding
 * "hlx_message_prefix" "" // Define the prefix displayed on every HLstatsX ingame message
 * "hlxce_webpage" "http://www.hlxcommunity.com" // http://www.hlxcommunity.com
#### Command List
 * "hlx_sm_bulkpsay"
 * "hlx_sm_team_action"
 * "hlx_sm_world_action"
 * "log"
 * "hlx_sm_psay"
 * "hlx_sm_swap"
 * "hlx_sm_browse"
 * "hlx_sm_hint"
 * "hlx_sm_redirect"
 * "hlx_sm_csay"
 * "hlx_sm_msay"
 * "hlx_sm_tsay"
 * "logaddress_del"
 * "hlx_sm_psay2"
 * "hlx_message_prefix_clear"
 * "logaddress_delall"
 * "hlx_sm_player_action"
<a name="insmaps">
### [INS] Map List 1.4.1
Lists all maps and modes available
 * [Source - scripting/insmaps.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/insmaps.sp?raw=true)
 * [Plugin - plugins/insmaps.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/insmaps.smx?raw=true)
#### Dependencies
 * [Source - scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)
#### CVAR List
 * "sm_insmaps_version" "PLUGIN_VERSION" // SM Ins Maps Version
<a name="insurgency">
### [INS] Insurgency Support Library 1.3.5
Provides functions to support Insurgency. Includes logging, round statistics, weapon names, player class names, and more.
 * [Source - scripting/insurgency.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/insurgency.sp?raw=true)
 * [Source - scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)
 * [Plugin - plugins/insurgency.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/insurgency.smx?raw=true)
#### Dependencies
 * [Source - scripting/include/loghelper.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/loghelper.inc?raw=true)
 * [Source - scripting/include/myinfo.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/myinfo.inc?raw=true)
 * [Plugin - translations/insurgency.phrases.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/translations/insurgency.phrases.txt?raw=true)
 * [Plugin - gamedata/insurgency.games.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/gamedata/insurgency.games.txt?raw=true)
#### CVAR List
 * "sm_insurgency_class_strip_words" "template training coop security insurgent survival" // Strings to strip out of player class (squad slot) names
 * "sm_insurgency_checkpoint_capture_player_ratio" "0.5" // Fraction of living players required to capture in Checkpoint
 * "sm_insurgency_version" "PLUGIN_VERSION" // PLUGIN_DESCRIPTION
 * "sm_insurgency_infinite_magazine" "0" // Infinite magazine
 * "sm_insurgency_enabled" "PLUGIN_WORKING" // sets whether log fixing is enabled
 * "sm_insurgency_disable_sliding" "0" // 0: do nothing
 * "sm_insurgency_log_level" "error" // Logging level
 * "sm_insurgency_infinite_ammo" "0" // Infinite ammo
 * "sm_insurgency_checkpoint_counterattack_capture" "0" // Enable counterattack by bots to capture points in Checkpoint
<a name="magnifier">
### [INS] Magnifier 0.0.1
Adds FOV switch to emulate flip to side magnifiers
 * [Source - scripting/magnifier.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/magnifier.sp?raw=true)
 * [Plugin - plugins/magnifier.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/magnifier.smx?raw=true)
#### Dependencies
 * [Plugin - translations/common.phrases.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/translations/common.phrases.txt?raw=true)
#### CVAR List
 * "sm_magnifier_version" "PLUGIN_VERSION" // version
 * "sm_magnifier_zoom" "60" // zoom level for magnifier
 * "sm_magnifier_shots" "0" // Allow or disallow shots while using magnifier. 1 = allow. 0 = disallow.
 * "sm_magnifier_adminflag" "0" // Admin flag required to use magnifier. 0 = No flag needed. Can use a b c ....
#### Command List
 * "sm_magnifier"
<a name="nofog">
### [INS] No Fog 0.0.1
Removes fog
 * [Source - scripting/nofog.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/nofog.sp?raw=true)
 * [Plugin - plugins/nofog.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/nofog.smx?raw=true)
#### Dependencies
#### CVAR List
 * "sm_nofog_enabled" "1" // sets whether bot naming is enabled
 * "sm_nofog_version" "PLUGIN_VERSION" // PLUGIN_DESCRIPTION
<a name="respawn">
### [INS] Player Respawn 1.8.1
Respawn players
 * [Source - scripting/respawn.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/respawn.sp?raw=true)
 * [Plugin - plugins/respawn.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/respawn.smx?raw=true)
#### Dependencies
 * [Source - scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)
 * [Source - scripting/include/cstrike.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/cstrike.inc?raw=true)
 * [Source - scripting/include/tf2.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/tf2.inc?raw=true)
 * [Source - scripting/include/tf2_stocks.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/tf2_stocks.inc?raw=true)
 * [Plugin - translations/common.phrases.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/translations/common.phrases.txt?raw=true)
 * [Plugin - translations/respawn.phrases.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/translations/respawn.phrases.txt?raw=true)
 * [Plugin - gamedata/plugin.respawn.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/gamedata/plugin.respawn.txt?raw=true)
#### CVAR List
 * "sm_respawn_enabled" "PLUGIN_WORKING" // Enable respawn plugin
 * "sm_respawn_reset_each_round" "1" // Reset player respawn counts each round
 * "sm_respawn_version" "PLUGIN_VERSION" // PLUGIN_DESCRIPTION
 * "sm_respawn_final_counterattack" "0" // Respawn during final counterattack? (0: no
 * "sm_respawn_auto" "0" // Automatically respawn players when they die; 0 - disabled
 * "sm_respawn_delay" "1.0" // How many seconds to delay the respawn
 * "sm_respawn_counterattack" "0" // Respawn during counterattack? (0: no
 * "sm_respawn_count_team2" "-1" // Respawn all Team 2 players this many times
 * "sm_respawn_count_team3" "-1" // Respawn all Team 3 players this many times
 * "sm_respawn_count" "0" // Respawn all players this many times
 * "sm_respawn_reset_each_objective" "1" // Reset player respawn counts each objective
#### Command List
 * "sm_respawn" // sm_respawn <#userid|name>
<a name="restrictedarea">
### [INS] Restricted Area Removal 0.0.1
Plugin for removing Restricted Areas
 * [Source - scripting/restrictedarea.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/restrictedarea.sp?raw=true)
 * [Plugin - plugins/restrictedarea.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/restrictedarea.smx?raw=true)
#### Dependencies
#### CVAR List
 * "sm_restrictedarea_version" "PLUGIN_VERSION" // PLUGIN_DESCRIPTION
 * "sm_restrictedarea_enabled" "1" // sets whether bot naming is enabled
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
 * "sm_rpgdrift_version" "PLUGIN_VERSION" // PLUGIN_DESCRIPTION
<a name="score">
### [INS] Score Modifiers 0.0.1
Adds a number of new ways to get score, or remove score for players
 * [Source - scripting/score.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/score.sp?raw=true)
 * [Plugin - plugins/score.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/score.smx?raw=true)
#### Dependencies
 * [Source - scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)
 * [Plugin - translations/common.phrases.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/translations/common.phrases.txt?raw=true)
 * [Plugin - translations/score.phrases.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/translations/score.phrases.txt?raw=true)
#### CVAR List
 * "sm_score_version" "PLUGIN_VERSION" // PLUGIN_DESCRIPTION
 * "sm_score_enabled" "1" // sets whether score modifier is enabled
#### Command List
 * "check_score"
<a name="sprinklers">
### [INS] Sprinkler Removal 0.0.3
Plugin for removing Sprinkers
 * [Source - scripting/sprinklers.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/sprinklers.sp?raw=true)
 * [Plugin - plugins/sprinklers.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/sprinklers.smx?raw=true)
#### Dependencies
#### CVAR List
 * "sm_sprinklers_enabled" "PLUGIN_WORKING" // Set to 1 to remove sprinklers. 0 leaves them alone.
 * "sm_sprinklers_version" "PLUGIN_VERSION" // PLUGIN_DESCRIPTION
<a name="suicide_bomb">
### [INS] Suicide Bombers 0.0.7
Adds suicide bomb for bots
 * [Source - scripting/suicide_bomb.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/suicide_bomb.sp?raw=true)
 * [Plugin - plugins/suicide_bomb.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/suicide_bomb.smx?raw=true)
#### Dependencies
 * [Source - scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)
#### CVAR List
 * "sm_suicidebomb_auto_detonate_range" "0" // Range at which to automatically set off the bomb (0 is disabled)
 * "sm_suicidebomb_" "" // 
 * "sm_suicidebomb_player_classes" "sapper bomber suicide" // Player classes to apply suicide bomber changes to
 * "sm_suicidebomb_version" "PLUGIN_VERSION" // PLUGIN_DESCRIPTION
 * "sm_suicidebomb_enabled" "0" // sets whether suicide bombs are enabled
 * "sm_suicidebomb_spawn_delay" "30" // Do not detonate if player has been alive less than this many seconds
 * "sm_suicidebomb_auto_detonate_count" "2" // Do not detonate until this many enemies are in range
 * "sm_suicidebomb_explode_armed" "0" // Explode when killed if C4 or IED is in hand
 * "sm_suicidebomb_strip_weapons" "1" // Remove all weapons from suicide bombers except the bomb
 * "sm_suicidebomb_death_chance" "0.1" // Chance as a fraction of 1 that a bomber will explode when killed
 * "sm_suicidebomb_bots_only" "1" // Only apply suicide bomber code to bots
<a name="theater_reconnect">
### [INS] Theater Reconnect 0.0.1
If a player connects with their mp_theater_override set to something other than what the server uses, set the cvar and retonnect them.
 * [Source - scripting/theater_reconnect.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/theater_reconnect.sp?raw=true)
 * [Plugin - plugins/theater_reconnect.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/theater_reconnect.smx?raw=true)
#### Dependencies
#### CVAR List
 * "sm_theater_reconnect_version" "PLUGIN_VERSION" // PLUGIN_DESCRIPTION
 * "sm_theater_reconnect_enabled" "1" // sets whether theater reconnect is enabled
<a name="theaterpicker">
### [INS] Theater Picker 0.0.4
Allows admins to set theater, and clients to vote
 * [Source - scripting/theaterpicker.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/theaterpicker.sp?raw=true)
 * [Plugin - plugins/theaterpicker.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/theaterpicker.smx?raw=true)
#### Dependencies
 * [Source - scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)
 * [Source - scripting/include/smjansson.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/smjansson.inc?raw=true)
#### CVAR List
 * "sm_theaterpicker_file" "PLUGIN_VERSION" // Custom theater file name
 * "sm_theaterpicker_version" "PLUGIN_VERSION" // Theater picker version
 * "sm_theaterpicker_config" "PLUGIN_VERSION" // Custom theater file name
<a name="votelog">
### Vote Logging 0.0.2
Logs voting events
 * [Source - scripting/votelog.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/votelog.sp?raw=true)
 * [Plugin - plugins/votelog.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/votelog.smx?raw=true)
#### Dependencies
 * [Source - scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)
 * [Source - scripting/include/loghelper.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/loghelper.inc?raw=true)
 * [Source - scripting/include/myinfo.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/myinfo.inc?raw=true)
#### CVAR List
 * "sm_votelog_enabled" "PLUGIN_WORKING" // Enable vote logging
 * "sm_votelog_version" "PLUGIN_VERSION" // PLUGIN_DESCRIPTION
<a name="weapon_pickup">
### [INS] Weapon Pickup 0.1.0
Weapon Pickup logic for manipulating player inventory
 * [Source - scripting/weapon_pickup.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/weapon_pickup.sp?raw=true)
 * [Plugin - plugins/weapon_pickup.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/weapon_pickup.smx?raw=true)
#### Dependencies
 * [Source - scripting/include/smlib.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/smlib.inc?raw=true)
 * [Source - scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)
 * [Plugin - gamedata/insurgency.games.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/gamedata/insurgency.games.txt?raw=true)
 * [Plugin - gamedata/sdkhooks.games/engine.insurgency.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/gamedata/sdkhooks.games/engine.insurgency.txt?raw=true)
#### CVAR List
 * "sm_weapon_pickup_max_magazine" "12" // Maximum number of magazines that can be carried
 * "sm_weapon_pickup_ammo" "1" // sets whether picking up a weapon the player already has will add to the player's ammo count
 * "sm_weapon_pickup_version" "PLUGIN_VERSION" // PLUGIN_DESCRIPTION
 * "sm_weapon_pickup_enabled" "PLUGIN_WORKING" // sets whether weapon pickup manipulation is enabled
 * "sm_weapon_pickup_max_explosive" "3" // Maximum number of ammo that can be carried for explosives
#### Command List
 * "wp_weaponlist" // Lists all weapons. Usage: wp_weaponlist [target]
 * "wp_weaponslots" // Lists weapon slots. Usage: wp_weaponslots [target]
 * "wp_removeweapons" // Removes all weapons. Usage: wp_removeweapons [target]


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

