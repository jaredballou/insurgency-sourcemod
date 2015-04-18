# SourceMod for Insurgency
This repository has a complete installation of SourceMod, including all my plugins and source files. It's updated regularly, kept in sync with upstream, and includes a ton of stuff. It's still very much a development branch, so be aware that almost all the plugins I am working on are still pretty new and could be buggy.
##Plugin list
These plugins are all provided as-is, I do my best to document and describe them but they are all potentially broken, so be aware. Please send me feedback and bug reports to help keep these working.

 * <a href='#Ammo Check'>Ammo Check (version 0.0.6)</a>
 * <a href='#Backblast'>Backblast (version 0.0.2)</a>
 * <a href='#Bot Counter'>Bot Counter (version 0.0.1)</a>
 * <a href='#Bot Names'>Bot Names (version 1.0)</a>
 * <a href='#Bot spawns'>Bot spawns (version 0.2.6)</a>
 * <a href='#Compass'>Compass (version 0.0.5)</a>
 * <a href='#Coop Lobby Override'>Coop Lobby Override (version 0.0.1)</a>
 * <a href='#Damage Modifier'>Damage Modifier (version 0.0.1)</a>
 * <a href='#HLstatsX CE Ingame Plugin'>HLstatsX CE Ingame Plugin (version 1.6.19)</a>
 * <a href='#Insurgency Support Library'>Insurgency Support Library (version 1.0.2)</a>
 * <a href='#SourcePawn Navigation Mesh Parser'>SourcePawn Navigation Mesh Parser (version 1.0.3)</a>
 * <a href='#SP-Readable Navigation Mesh Test'>SP-Readable Navigation Mesh Test (version 1.0.1)</a>
 * <a href='#Navmesh Chat'>Navmesh Chat (version 0.0.1)</a>
 * <a href='#Navmesh Export'>Navmesh Export (version 0.0.3)</a>
 * <a href='#Looting'>Looting (version 0.0.1)</a>
 * <a href='#No Fog'>No Fog (version 0.0.1)</a>
 * <a href='#No Objectives'>No Objectives (version 0.0.1)</a>
 * <a href='#Pistols Only'>Pistols Only (version 0.0.3)</a>
 * <a href='#Prop Removal'>Prop Removal (version 0.0.1)</a>
 * <a href='#Player Respawn'>Player Respawn (version 1.7.0)</a>
 * <a href='#Restricted Area Removal'>Restricted Area Removal (version 0.0.1)</a>
 * <a href='#RPG Adjustments'>RPG Adjustments (version 0.0.3)</a>
 * <a href='#Suicide Bombers'>Suicide Bombers (version 0.0.4)</a>
---
### <a name='Ammo Check'>Ammo Check (version 0.0.6)</a>
Adds a check_ammo command for clients to get approximate ammo left in magazine, and display the same message when loading a new magazine

 * [Plugin - ammocheck.smx](plugins/ammocheck.smx?raw=true)
 * [Source - ammocheck.sp](scripting/ammocheck.sp)

Adds check_ammo command that client runs and gets RO2-style "Mag feels mostly full" estimation of remaining ammo. Reloading will also pop this up to alert player if they have inserted a magazine that is less than full. Future features I'd like to do are to show a reload animation partially to animate the check, and have the check command delay the next weapon attack to simulate removing and checking the magazine. Due to the way the theater system works, it's not practical to hard-code weapon data like magazine capacity in the plugin as similar CS and TF2 plugins do, so I have a hacky method that checks the 'm_iClip' variable and uses that to perform the math. There are other workarounds and todos in the source code as well. Release candidate, no obvious bugs, but still needs a lot of polish.

#### CVAR List
 * "sm_ammocheck_enabled" "1" //sets whether ammo check is enabled

#### Todo
 * [ ] Add client-side config on enable, display location, and to show after mag change

---
### <a name='Backblast'>Backblast (version 0.0.2)</a>
Adds backblast to rocket based weapons

 * [Plugin - backblast.smx](plugins/backblast.smx?raw=true)
 * [Source - backblast.sp](scripting/backblast.sp)

Adds backblast to AT4 and RPG. Still in progress, this is not yet fully functional.

#### CVAR List
 * "sm_backblast_enabled" "1" //sets whether bot naming is enabled
 * "sm_backblast_damage" "80" //Max damage from backblast
 * "sm_backblast_damage_range" "15" //Distance in meters from firing to hurt players in backblast
 * "sm_backblast_max_range" "25" //Max range for backblast to affect players visually
 * "sm_backblast_cone_angle" "90" //Angle behind firing to include in backblast effect
 * "sm_backblast_wall_distance" "5" //Distance in meters to wall where player firing will hurt himself

#### Todo
 * [X] Add CVARs to control cone angle, kill range, and total effect range
 * [X] Use flashbang effect as standin for non-lethal backblast
 * [X] Add CVAR for wall proximity, hurt or kill player if too close to a wall behind them
 * [X] On weapon fire for AT4/RPG, get all clients in a radius, determine angle, and apply damage or effect accordingly

---
### <a name='Bot Counter'>Bot Counter (version 0.0.1)</a>
Shows Bots Left Alive

 * [Plugin - botcount.smx](plugins/botcount.smx?raw=true)
 * [Source - botcount.sp](scripting/botcount.sp)

Displays a popup to players every 60 seconds by default identifying remaining enemy players alive. Beginning of a "UAV" feature, my goal is to create an entity on the map that can be used to get this information rather than just spamming it. Release ready, no known bugs.

#### CVAR List
 * "sm_botcount_enabled" "0" //sets whether bot naming is enabled
 * "sm_botcount_timer" "60" //Frequency to show count

---
### <a name='Bot Names'>Bot Names (version 1.0)</a>
Gives automatic names to bots on creation.

 * [Plugin - botnames.smx](plugins/botnames.smx?raw=true)
 * [Source - botnames.sp](scripting/botnames.sp)

Changes bot names to selectable lists of names. Included are Arabic, Pashtun, and English name lists.

#### CVAR List
 * "sm_botnames_enabled" "1" //sets whether bot naming is enabled
 * "sm_botnames_prefix" "" //sets a prefix for bot names
 * "sm_botnames_random" "1" //sets whether to randomize names used
 * "sm_botnames_announce" "0" //sets whether to announce bots when added
 * "sm_botnames_suppress" "1" //sets whether to supress join/team change/name change bot messages
 * "sm_botnames_list" "default" //Set list to use for bots

#### Todo
 * [ ] Add per-team CVARs to use different lists

---
### <a name='Bot spawns'>Bot spawns (version 0.2.6)</a>
Adds a number of options and ways to handle bot spawns

 * [Plugin - botspawns.smx](plugins/botspawns.smx?raw=true)
 * [Source - botspawns.sp](scripting/botspawns.sp)

Adjust bot spawning and rules to increase game control. In early beta, only navmesh spawning and multiple lives supported right now.

#### Dependencies
 * [gamedata/insurgency.games.txt](gamedata/insurgency.games.txt)

#### CVAR List
 * "sm_botspawns_enabled" "0" //Enable enhanced bot spawning features
 * "sm_botspawns_spawn_mode" "0" //Only normal spawnpoints at the objective, the old way
 * "sm_botspawns_respawn_mode" "0" //Do not respawn
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

#### Todo
 * [X] Instead of spawning all bots in one spot, spawn them at hiding spots in the navmesh
 * [X] Find path between current and next point, add bots around that axis
 * [X] Add option for minimum spawn distance to keep bots from spawning on top of players
 * [X] Create variables for how far off the path to spawn
 * [X] Create option to either spawn and keep X number of bots in game, or simply spawn on random timer (also an option)
 * [X] Create functionality to respawn bots to simulate more bots than game can support


---
### <a name='Compass'>Compass (version 0.0.5)</a>
Puts a compass in the game

 * [Plugin - compass.smx](plugins/compass.smx?raw=true)
 * [Source - compass.sp](scripting/compass.sp)

Adds a check_compass command that clients can use and get their ordinal direction where they are looking in relation to where they stand. Like a compass. Release ready, no known bugs.

#### Dependencies
 * [translations/compass.phrases.txt](translations/compass.phrases.txt)

#### CVAR List
 * "sm_compass_enabled" "1" //Enables compass
 * "sm_compass_direction" "1" //Display direction in ordinal directions
 * "sm_compass_bearing" "1" //Display bearing in degrees
 * "sm_compass_timer" "0" //If greater than 0, display compass to players every X seconds.
 * "sm_compass_default_enabled" "1" //Default compass
 * "sm_compass_default_timer" "60" //Default compass
 * "sm_compass_default_display" "1" //Default compass
 * "sm_compass_default_direction" "1" //Default compass
 * "sm_compass_default_bearing" "1" //Default compass

---
### <a name='Coop Lobby Override'>Coop Lobby Override (version 0.0.1)</a>
Plugin for overriding Insurgency Coop to 16 players

 * [Plugin - cooplobby.smx](plugins/cooplobby.smx?raw=true)
 * [Source - cooplobby.sp](scripting/cooplobby.sp)

Increases max for mp_cooplobbysize from 8 to 16. Requires custom theaters to allow all 16 players to select a class. Release ready, no known bugs.

---
### <a name='Damage Modifier'>Damage Modifier (version 0.0.1)</a>
Modifies all damage applied

 * [Plugin - damagemod.smx](plugins/damagemod.smx?raw=true)
 * [Source - damagemod.sp](scripting/damagemod.sp)

Enable world-wide modification of damage values (i.e. for doing training missions where damage is set to 0). Still in the wireframe phase, not fucntional at all.

#### CVAR List
 * "sm_damagemod_enabled" "0" //sets whether log fixing is enabled

---
### <a name='HLstatsX CE Ingame Plugin'>HLstatsX CE Ingame Plugin (version 1.6.19)</a>
Provides ingame functionality for interaction from an HLstatsX CE installation

 * [Plugin - hlstatsx.smx](plugins/hlstatsx.smx?raw=true)
 * [Source - hlstatsx.sp](scripting/hlstatsx.sp)

Adds in-game support for HLStatsX servers to connect and send messages and other tasks. Adds color support, and a number of other features absent from the HLStatsX upstream version. Release ready, no known bugs.

#### CVAR List
 * "hlxce_webpage" "http://www.hlxcommunity.com" //http://www.hlxcommunity.com
 * "hlx_block_commands" "1" //If activated HLstatsX commands are blocked from the chat area
 * "hlx_message_prefix" "" //Define the prefix displayed on every HLstatsX ingame message
 * "hlx_protect_address" "" //Address to be protected for logging/forwarding
 * "hlx_server_tag" "1" //If enabled, adds \HLstatsX:CE\ to server tags on supported games. 1 = Enabled

---
### <a name='Insurgency Support Library'>Insurgency Support Library (version 1.0.2)</a>
Provides functions to support Insurgency and fixes logging

 * [Plugin - insurgency.smx](plugins/insurgency.smx?raw=true)
 * [Source - insurgency.sp](scripting/insurgency.sp)

Creates hooks and events for Insurgency-specific stat logging, entities, and events. Fixes a lot of issues with missing log entries for HLStatsX, this plugin is tightly bound with my HLStatsX fork I created to handle more Insurgency-specific data and events. This is based off of Brutus' Insurgency logger, but adds support for nearly every event supported by the game, enhances support for new weapons by removing the old config file method of adding weapons, and generally kicks ass if you're looking to create stats from Insurgency. It also includes a number of natives for checking game rules and objective status. This is generally stable, I look at it as a beta release candidate right now.

#### Dependencies
 * [gamedata/insurgency.games.txt](gamedata/insurgency.games.txt)
 * [translations/insurgency.phrases.txt.txt](translations/insurgency.phrases.txt.txt)

#### CVAR List
 * "sm_inslogger_enabled" "1" //sets whether log fixing is enabled
 * "sm_insurgency_checkpoint_capture_player_ratio" "0.5" //Fraction of living players required to capture in Checkpoint
 * "sm_insurgency_checkpoint_counterattack_capture" "0" //Enable counterattack by bots to capture points in Checkpoint

#### Todo
 * [ ] Weapon lookup by index/name
 * [ ] Role (template/class) lookup by index/name/player
 * [ ] Game rules lookup (control points, status, waves, etc)
 * [ ] Precache models based upon manifests.
 * [ ] Investigate adding feature to read mp_theater_override variable, parse that theater, and add any materials/models/sounds to the list?
 * [ ] Complete theater parser in SM to get around engine theater lookup limitations?


---
### <a name='Looting'>Looting (version 0.0.1)</a>
Adds ability to loot items from dead bodies

 * [Plugin - looting.smx](plugins/looting.smx?raw=true)
 * [Source - looting.sp](scripting/looting.sp)

Allows looting bodies for ammo. Not yet functional.

#### CVAR List
 * "sm_looting_enabled" "1" //sets whether looting is enabled
 * "sm_looting_mode" "1" //sets looting mode - 0: Loot per mag, 1: Loot all ammo

---
### <a name='Navmesh Chat'>Navmesh Chat (version 0.0.1)</a>
Puts navmesh area into chat

 * [Plugin - navmesh-chat.smx](plugins/navmesh-chat.smx?raw=true)
 * [Source - navmesh-chat.sp](scripting/navmesh-chat.sp)

Adds prefix to all chat messages (selectable team or all) that includes grid coordinates, area name (if named in navmesh). For radio commands, it adds those and also a distance and direction related to the player. This plugin is currently complex in that it relies on parsing the map overview data from the Data repository existing in the Insurgency game root directory, cloned to insurgency-data. This has a lot of work to do, especially in getting the overview data from the engine directly rather than hacking around it. This is still very much under active development and could blow up your server, but I'd appreciate testing and feedback.

#### Dependencies
 * [translations/insurgency.phrases.txt](translations/insurgency.phrases.txt)

#### CVAR List
 * "sm_navmesh_chat_enabled" "1" //sets whether this plugin is enabled
 * "sm_navmesh_chat_teamonly" "1" //sets whether to prepend to all messages or just team messages
 * "sm_navmesh_chat_grid" "1" //Include grid coordinates
 * "sm_navmesh_chat_place" "1" //Include place name from navmesh
 * "sm_navmesh_chat_distance" "1" //Include distance to speaker
 * "sm_navmesh_chat_direction" "1" //Include direction to speaker

#### Todo
 * [ ] Get grid/overlay data from engine directly
 * [X] Create CVARs to decide if prefix is attached to all chat, team only, or just admins
 * [X] Put grid in front of all chat messages
 * [ ] Put grid, distance, and direction with radio voice commands
 * [ ] Add in-game markers for wider array of tasks
 * [ ] Add support for commands that target location other than player's current position (i.e. "grenade over there")
 * [ ] Replace spotting box with callout of distance/direction, add map marker


---
### <a name='Navmesh Export'>Navmesh Export (version 0.0.3)</a>
Exports navmesh data in JSON format

 * [Plugin - navmesh-export.smx](plugins/navmesh-export.smx?raw=true)
 * [Source - navmesh-export.sp](scripting/navmesh-export.sp)

Exports Navmesh data as JSON for parsing by the Insurgency Tools. Nobody should need this, but it's released for completeness.

#### CVAR List
 * "sm_navmesh_export_enabled" "0" //sets whether this plugin is enabled

---
### <a name='SourcePawn Navigation Mesh Parser'>SourcePawn Navigation Mesh Parser (version 1.0.3)</a>
A plugin that can read Valve's Navigation Mesh.

 * [Plugin - navmesh.smx](plugins/navmesh.smx?raw=true)
 * [Source - navmesh.sp](scripting/navmesh.sp)

Navmesh parser, created by KitRifty and modified by me to support Hiding Spots and other natives that were missing.

---
### <a name='SP-Readable Navigation Mesh Test'>SP-Readable Navigation Mesh Test (version 1.0.1)</a>
Testing plugin of the SP-Readable Navigation Mesh plugin.

 * [Plugin - navmesh-test.smx](plugins/navmesh-test.smx?raw=true)
 * [Source - navmesh-test.sp](scripting/navmesh-test.sp)


---
### <a name='No Fog'>No Fog (version 0.0.1)</a>
Removes fog

 * [Plugin - nofog.smx](plugins/nofog.smx?raw=true)
 * [Source - nofog.sp](scripting/nofog.sp)

Removes all fog on the map. Release ready, no known bugs.

#### CVAR List
 * "sm_nofog_enabled" "1" //sets whether bot naming is enabled

---
### <a name='No Objectives'>No Objectives (version 0.0.1)</a>
Removes all objectives

 * [Plugin - noobj.smx](plugins/noobj.smx?raw=true)
 * [Source - noobj.sp](scripting/noobj.sp)

Removes objectives, not yet functional.

#### CVAR List
 * "sm_noobj_enabled" "0" //sets whether objective removal is enabled
 * "sm_noobj_cache_destroy" "1" //Can caches be destroyed?
 * "sm_noobj_capture" "1" //Can points be captured?
 * "sm_noobj_remove" "0" //Remove all points?

---
### <a name='Pistols Only'>Pistols Only (version 0.0.3)</a>
Adds a game modifier that only allows pistols

 * [Plugin - pistolsonly.smx](plugins/pistolsonly.smx?raw=true)
 * [Source - pistolsonly.sp](scripting/pistolsonly.sp)

Disables all primary weapons, enables only pistols. Not yet functional.

#### CVAR List
 * "sm_pistolsonly_enabled" "0" //sets whether ammo check is enabled

---
### <a name='Prop Removal'>Prop Removal (version 0.0.1)</a>
Plugin for removing Restricted Areas

 * [Plugin - prop_dynamic.smx](plugins/prop_dynamic.smx?raw=true)
 * [Source - prop_dynamic.sp](scripting/prop_dynamic.sp)

Removes all prop_dynamic entities.

#### CVAR List
 * "sm_prop_dynamic_enabled" "1" //sets whether bot naming is enabled

---
### <a name='Player Respawn'>Player Respawn (version 1.7.0)</a>
Respawn dead players via admincommand or by queues

 * [Plugin - respawn.smx](plugins/respawn.smx?raw=true)
 * [Source - respawn.sp](scripting/respawn.sp)

Allows respawning of players or bots. Support for some customization of per round counting, total respawns, delays, and team-specific rules. Also has an admin menu hook.

#### Dependencies
 * [gamedata/plugin.respawn.txt](gamedata/plugin.respawn.txt)
 * [translations/common.phrases.txt](translations/common.phrases.txt)
 * [translations/respawn.phrases.txt](translations/respawn.phrases.txt)

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

---
### <a name='Restricted Area Removal'>Restricted Area Removal (version 0.0.1)</a>
Plugin for removing Restricted Areas

 * [Plugin - restrictedarea.smx](plugins/restrictedarea.smx?raw=true)
 * [Source - restrictedarea.sp](scripting/restrictedarea.sp)

Removes all restricted areas on the map. Release ready, no known bugs.

#### CVAR List
 * "sm_restrictedarea_enabled" "1" //sets whether bot naming is enabled

---
### <a name='RPG Adjustments'>RPG Adjustments (version 0.0.3)</a>
Adjusts behavior of RPG rounds

 * [Plugin - rpgdrift.smx](plugins/rpgdrift.smx?raw=true)
 * [Source - rpgdrift.sp](scripting/rpgdrift.sp)

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


---
### <a name='Suicide Bombers'>Suicide Bombers (version 0.0.4)</a>
Adds suicide bomb for bots

 * [Plugin - suicide_bomb.smx](plugins/suicide_bomb.smx?raw=true)
 * [Source - suicide_bomb.sp](scripting/suicide_bomb.sp)

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


## Ideas to develop
This is a sort of scratchpad and todo list for things that I think of or people ask for me to work on.
* [ ] Remove counterattack capture ability in checkpoint coop mode via a cvar. Having to capture a building and then stand inside it while it gets assaulted instead of choosing good firing positions outside makes the game switch from tight, careful action to Call of Duty twitch shooter.
* [ ] Review bot CVARs and changes from last two patches to see if there are any new options to try or setting changes that can help get the bots to behave like mildly well trained, scared teenagers instead of a guy on a sunday stroll who can hipshoot you at a hundred meters.
* [ ] IR strobe on the back of US helmets for IFF. Possible to do with a particle effect or alpha/color mask, Source engine precompiled lighting makes actual strobes unlikely.
* [ ] IR laser? Is there a variable I can check to see if a player has NV enabled, and then how to control visibility of the beam per-client.
* [ ] Artillery, mortar, or air support SM plugin to give delayed but devastating damage on an area? How to balance and offset the massive power for the Insurgent side?
* [ ] Wounded/disabled players, can talk for very short time but no ability to move or shoot? Implement contact shots?
* [ ] Look at ability to modify game rules via tricky Sourcemod magic, like passing off spawning additional waves, spawning in staggered groups, and other fun things we need to do.
* [ ] Ability to loot ammo from dead bodies and have them added to the player's inventory properly. Needs to be sorted out how player inventory is handled, with the array method where each magazine's capacity is tracked and retained, and make sure we only pick up the right ammo for the primary weapon. The system needs to inform player "picked up one full AK74 magazine" or "picked up one nearly empty M16 magazine". Should loot from most full to least full, loot one mag per run of the command, and say how many mags still available to be looted. Add cvar-controlled timer to delay next loot/shoot/reload/switch for half a second or so to balance it. Add support for shared magazines, namely AKS74U/AK74 and M16/M4A1/MK18.
* [ ] Decouple flashbang visual impairment and audio impairment. The goal is to slightly increase flashed vision loss time, but greatly increase efefct and duration of audio impairment.
* [ ] Add controls to disable bot shooting while sliding.
* [ ] Add controls to disable firing for slight delay after jumping or falling.
