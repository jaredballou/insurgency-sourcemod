# SourceMod for Insurgency
This repository has a complete installation of SourceMod, including all my plugins and source files. It's updated regularly, kept in sync with upstream, and includes a ton of stuff. It's still very much a development branch, so be aware that almost all the plugins I am working on are still pretty new and could be buggy.
##Plugin list
These plugins are all provided as-is, I do my best to document and describe them but they are all potentially broken, so be aware. Please send me feedback and bug reports to help keep these working.
### Ammo Check (version 0.0.6)
Adds a check_ammo command for clients to get approximate ammo left in magazine, and display the same message when loading a new magazine

[Plugin](plugins/ammocheck.smx?raw=true) - [Source](scripting/ammocheck.sp)

Adds check_ammo command that client runs and gets RO2-style "Mag feels mostly full" estimation of remaining ammo. Reloading will also pop this up to alert player if they have inserted a magazine that is less than full. Future features I'd like to do are to show a reload animation partially to animate the check, and have the check command delay the next weapon attack to simulate removing and checking the magazine. Due to the way the theater system works, it's not practical to hard-code weapon data like magazine capacity in the plugin as similar CS and TF2 plugins do, so I have a hacky method that checks the 'm_iClip' variable and uses that to perform the math. There are other workarounds and todos in the source code as well. Release candidate, no obvious bugs, but still needs a lot of polish.

#### CVAR List
 * sm_ammocheck_enabled: sets whether ammo check is enabled (default: 1)

### Backblast (version 0.0.2)
Adds backblast to rocket based weapons

[Plugin](plugins/backblast.smx?raw=true) - [Source](scripting/backblast.sp)

Adds backblast to AT4 and RPG. Still in progress, this is not yet fully functional.

#### CVAR List
 * sm_backblast_enabled: sets whether bot naming is enabled (default: 1)
 * sm_backblast_damage: Max damage from backblast (default: 80)
 * sm_backblast_damage_range: Distance in meters from firing to hurt players in backblast (default: 15)
 * sm_backblast_max_range: Max range for backblast to affect players visually (default: 25)
 * sm_backblast_cone_angle: Angle behind firing to include in backblast effect (default: 90)
 * sm_backblast_wall_distance: Distance in meters to wall where player firing will hurt himself (default: 5)

#### Todo
 * [X] Add CVARs to control cone angle, kill range, and total effect range
 * [X] Use flashbang effect as standin for non-lethal backblast
 * [X] Add CVAR for wall proximity, hurt or kill player if too close to a wall behind them
 * [X] On weapon fire for AT4/RPG, get all clients in a radius, determine angle, and apply damage or effect accordingly

### Bot Counter (version 0.0.1)
Shows Bots Left Alive

[Plugin](plugins/botcount.smx?raw=true) - [Source](scripting/botcount.sp)

Displays a popup to players every 60 seconds by default identifying remaining enemy players alive. Beginning of a "UAV" feature, my goal is to create an entity on the map that can be used to get this information rather than just spamming it. Release ready, no known bugs.

#### CVAR List
 * sm_botcount_enabled: sets whether bot naming is enabled (default: 0)
 * sm_botcount_timer: Frequency to show count (default: 60)

### Bot Names (version 1.0)
Gives automatic names to bots on creation.

[Plugin](plugins/botnames.smx?raw=true) - [Source](scripting/botnames.sp)

Changes bot names to selectable lists of names. Included are Arabic, Pashtun, and English name lists.

#### CVAR List
 * sm_botnames_enabled: sets whether bot naming is enabled (default: 1)
 * sm_botnames_prefix: sets a prefix for bot names  (default: )
 * sm_botnames_random: sets whether to randomize names used (default: 1)
 * sm_botnames_announce: sets whether to announce bots when added (default: 0)
 * sm_botnames_suppress: sets whether to supress join/team change/name change bot messages (default: 1)
 * sm_botnames_list: Set list to use for bots (default: default)

#### Todo
 * [ ] Add per-team CVARs to use different lists

### Bot spawns (version 0.2.0)
Adds a number of options and ways to handle bot spawns

[Plugin](plugins/botspawns.smx?raw=true) - [Source](scripting/botspawns.sp)

Adjust bot spawning and rules to increase game control. In early beta, only navmesh spawning and multiple lives supported right now.

#### Dependencies
 * [gamedata/insurgency.games.txt](gamedata/insurgency.games.txt&raw=true)

#### CVAR List
 * sm_botspawns_enabled: Enable enhanced bot spawning features (default: 0)
 * sm_botspawns_spawn_mode: Spawn in hiding spots  (default: 0)
 * sm_botspawns_respawn_mode: Do not respawn  (default: 0)
 * sm_botspawns_counterattack_mode: Use standard spawning for final counterattack waves  (default: 1)
 * sm_botspawns_counterattack_frac: Multiplier to total bots for spawning in counterattack wave (default: 0.5)
 * sm_botspawns_min_spawn_delay: Min delay in seconds for spawning. Set to 0 for instant. (default: 1)
 * sm_botspawns_max_spawn_delay: Max delay in seconds for spawning. Set to 0 for instant. (default: 15)
 * sm_botspawns_spawn_sides: Spawn bots to the sides of the players when facing the next objective? (default: 1)
 * sm_botspawns_spawn_rear: Spawn bots to the rear of pthe players when facing the next objective? (default: 1)
 * sm_botspawns_min_player_distance: Min distance from players to spawn (default: 1200)
 * sm_botspawns_max_player_distance: Max distance from players to spawn (default: 16000)
 * sm_botspawns_min_objective_distance: Min distance from next objective to spawn (default: 1)
 * sm_botspawns_min_counterattack_distance: Min distance from counterattack objective to spawn (default: 3600)
 * sm_botspawns_max_objective_distance: Max distance from next objective to spawn (default: 12000)
 * sm_botspawns_min_frac_in_game: Min multiplier of bot quota to have alive at any time. Set to 1 to emulate standard spawning. (default: 0.75)
 * sm_botspawns_max_frac_in_game: Max multiplier of bot quota to have alive at any time. Set to 1 to emulate standard spawning. (default: 1)
 * sm_botspawns_total_spawn_frac: Total number of bots to spawn as multiple of number of bots in game to simulate larger numbers. 1 is standard, values less than 1 are not supported. (default: 1.75)
 * sm_botspawns_min_fireteam_size: Min number of bots to spawn per fireteam. Default 3 (default: 3)
 * sm_botspawns_max_fireteam_size: Max number of bots to spawn per fireteam. Default 5 (default: 5)
 * sm_botspawns_stop_spawning_at_objective: Stop spawning new bots when near next objective  (default: 1)
 * sm_botspawns_remove_unseen_when_capping: Silently kill off all unseen bots when capping next point  (default: 1)
 * sm_botspawns_spawn_snipers_alone: Spawn snipers alone, can be 50% further from the objective than normal bots if this is enabled? (default: 1)

#### Todo
 * [X] Instead of spawning all bots in one spot, spawn them at hiding spots in the navmesh
 * [X] Find path between current and next point, add bots around that axis
 * [X] Add option for minimum spawn distance to keep bots from spawning on top of players
 * [X] Create variables for how far off the path to spawn
 * [X] Create option to either spawn and keep X number of bots in game, or simply spawn on random timer (also an option)
 * [X] Create functionality to respawn bots to simulate more bots than game can support


### Compass (version 0.0.5)
Puts a compass in the game

[Plugin](plugins/compass.smx?raw=true) - [Source](scripting/compass.sp)

Adds a check_compass command that clients can use and get their ordinal direction where they are looking in relation to where they stand. Like a compass. Release ready, no known bugs.

#### Dependencies
 * [translations/compass.phrases.txt](translations/compass.phrases.txt&raw=true)

#### CVAR List
 * sm_compass_enabled: Enables compass (default: 1)
 * sm_compass_direction: Display direction in ordinal directions (default: 1)
 * sm_compass_bearing: Display bearing in degrees (default: 1)
 * sm_compass_timer: If greater than 0, display compass to players every X seconds. (default: 0)
 * sm_compass_default_enabled:		Default compass (default:		1)
 * sm_compass_default_timer:		Default compass (default:		60)
 * sm_compass_default_display:		Default compass (default:		1)
 * sm_compass_default_direction:		Default compass (default:		1)
 * sm_compass_default_bearing:		Default compass (default:		1)

### Coop Lobby Override (version 0.0.1)
Plugin for overriding Insurgency Coop to 16 players

[Plugin](plugins/cooplobby.smx?raw=true) - [Source](scripting/cooplobby.sp)

Increases max for mp_cooplobbysize from 8 to 16. Requires custom theaters to allow all 16 players to select a class. Release ready, no known bugs.

### Damage Modifier (version 0.0.1)
Modifies all damage applied

[Plugin](plugins/damagemod.smx?raw=true) - [Source](scripting/damagemod.sp)

Enable world-wide modification of damage values (i.e. for doing training missions where damage is set to 0). Still in the wireframe phase, not fucntional at all.

#### CVAR List
 * sm_damagemod_enabled: sets whether log fixing is enabled (default: 0)

### HLstatsX CE Ingame Plugin (version )
Provides ingame functionality for interaction from an HLstatsX CE installation

[Plugin](plugins/hlstatsx.smx?raw=true) - [Source](scripting/hlstatsx.sp)

Adds in-game support for HLStatsX servers to connect and send messages and other tasks. Adds color support, and a number of other features absent from the HLStatsX upstream version. Release ready, no known bugs.

#### CVAR List
 * hlxce_webpage: http://www.hlxcommunity.com (default: http://www.hlxcommunity.com)
 * hlx_block_commands: If activated HLstatsX commands are blocked from the chat area (default: 1)
 * hlx_message_prefix: Define the prefix displayed on every HLstatsX ingame message (default: )
 * hlx_protect_address: Address to be protected for logging/forwarding (default: )
 * hlx_server_tag: If enabled, adds \HLstatsX:CE\ to server tags on supported games. 1 = Enabled  (default: 1)

### Insurgency Support Library (version 1.0.2)
Provides functions to support Insurgency and fixes logging

[Plugin](plugins/insurgency.smx?raw=true) - [Source](scripting/insurgency.sp)

Creates hooks and events for Insurgency-specific stat logging, entities, and events. Fixes a lot of issues with missing log entries for HLStatsX, this plugin is tightly bound with my HLStatsX fork I created to handle more Insurgency-specific data and events. This is based off of Brutus' Insurgency logger, but adds support for nearly every event supported by the game, enhances support for new weapons by removing the old config file method of adding weapons, and generally kicks ass if you're looking to create stats from Insurgency. It also includes a number of natives for checking game rules and objective status. This is generally stable, I look at it as a beta release candidate right now.

#### Dependencies
 * [gamedata/insurgency.games.txt](gamedata/insurgency.games.txt&raw=true)
 * [translations/insurgency.phrases.txt.txt](translations/insurgency.phrases.txt.txt&raw=true)

#### CVAR List
 * sm_inslogger_enabled: sets whether log fixing is enabled (default: 1)
 * sm_insurgency_checkpoint_capture_player_ratio: Fraction of living players required to capture in Checkpoint (default: 0.5)
 * sm_insurgency_checkpoint_counterattack_capture: Enable counterattack by bots to capture points in Checkpoint (default: 0)

#### Todo
 * [ ] Weapon lookup by index/name
 * [ ] Role (template/class) lookup by index/name/player
 * [ ] Game rules lookup (control points, status, waves, etc)
 * [ ] Precache models based upon manifests.
 * [ ] Investigate adding feature to read mp_theater_override variable, parse that theater, and add any materials/models/sounds to the list?
 * [ ] Complete theater parser in SM to get around engine theater lookup limitations?


### Looting (version 0.0.1)
Adds ability to loot items from dead bodies

[Plugin](plugins/looting.smx?raw=true) - [Source](scripting/looting.sp)

Allows looting bodies for ammo. Not yet functional.

#### CVAR List
 * sm_looting_enabled: sets whether looting is enabled (default: 1)
 * sm_looting_mode: sets looting mode - 0: Loot per mag, 1: Loot all ammo (default: 1)

### Navmesh Chat (version 0.0.1)
Puts navmesh area into chat

[Plugin](plugins/navmesh-chat.smx?raw=true) - [Source](scripting/navmesh-chat.sp)

Adds prefix to all chat messages (selectable team or all) that includes grid coordinates, area name (if named in navmesh). For radio commands, it adds those and also a distance and direction related to the player. This plugin is currently complex in that it relies on parsing the map overview data from the Data repository existing in the Insurgency game root directory, cloned to insurgency-data. This has a lot of work to do, especially in getting the overview data from the engine directly rather than hacking around it. This is still very much under active development and could blow up your server, but I'd appreciate testing and feedback.

#### Dependencies
 * [translations/insurgency.phrases.txt](translations/insurgency.phrases.txt&raw=true)

#### CVAR List
 * sm_navmesh_chat_enabled: sets whether this plugin is enabled (default: 1)
 * sm_navmesh_chat_teamonly: sets whether to prepend to all messages or just team messages (default: 1)
 * sm_navmesh_chat_grid: Include grid coordinates (default: 1)
 * sm_navmesh_chat_place: Include place name from navmesh (default: 1)
 * sm_navmesh_chat_distance: Include distance to speaker (default: 1)
 * sm_navmesh_chat_direction: Include direction to speaker (default: 1)

#### Todo
 * [ ] Get grid/overlay data from engine directly
 * [X] Create CVARs to decide if prefix is attached to all chat, team only, or just admins
 * [X] Put grid in front of all chat messages
 * [ ] Put grid, distance, and direction with radio voice commands
 * [ ] Add in-game markers for wider array of tasks
 * [ ] Add support for commands that target location other than player's current position (i.e. "grenade over there")
 * [ ] Replace spotting box with callout of distance/direction, add map marker


### Navmesh Export (version 0.0.3)
Exports navmesh data in JSON format

[Plugin](plugins/navmesh-export.smx?raw=true) - [Source](scripting/navmesh-export.sp)

Exports Navmesh data as JSON for parsing by the Insurgency Tools. Nobody should need this, but it's released for completeness.

#### CVAR List
 * sm_navmesh_export_enabled: sets whether this plugin is enabled (default: 0)

### SourcePawn Navigation Mesh Parser (version 1.0.3)
A plugin that can read Valve's Navigation Mesh.

[Plugin](plugins/navmesh.smx?raw=true) - [Source](scripting/navmesh.sp)

Navmesh parser, created by KitRifty and modified by me to support Hiding Spots and other natives that were missing.

### SP-Readable Navigation Mesh Test (version 1.0.1)
Testing plugin of the SP-Readable Navigation Mesh plugin.

[Plugin](plugins/navmesh-test.smx?raw=true) - [Source](scripting/navmesh-test.sp)


### No Fog (version 0.0.1)
Removes fog

[Plugin](plugins/nofog.smx?raw=true) - [Source](scripting/nofog.sp)

Removes all fog on the map. Release ready, no known bugs.

#### CVAR List
 * sm_nofog_enabled: sets whether bot naming is enabled (default: 1)

### No Objectives (version 0.0.1)
Removes all objectives

[Plugin](plugins/noobj.smx?raw=true) - [Source](scripting/noobj.sp)

Removes objectives, not yet functional.

#### CVAR List
 * sm_noobj_enabled: sets whether objective removal is enabled (default: 0)
 * sm_noobj_cache_destroy: Can caches be destroyed? (default: 1)
 * sm_noobj_capture: Can points be captured? (default: 1)
 * sm_noobj_remove: Remove all points? (default: 0)

### Pistols Only (version 0.0.3)
Adds a game modifier that only allows pistols

[Plugin](plugins/pistolsonly.smx?raw=true) - [Source](scripting/pistolsonly.sp)

Disables all primary weapons, enables only pistols. Not yet functional.

#### CVAR List
 * sm_pistolsonly_enabled: sets whether ammo check is enabled (default: 0)

### Prop Removal (version 0.0.1)
Plugin for removing Restricted Areas

[Plugin](plugins/prop_dynamic.smx?raw=true) - [Source](scripting/prop_dynamic.sp)

Removes all prop_dynamic entities.

#### CVAR List
 * sm_prop_dynamic_enabled: sets whether bot naming is enabled (default: 1)

### Player Respawn (version 1.7.0)
Respawn dead players via admincommand or by queues

[Plugin](plugins/respawn.smx?raw=true) - [Source](scripting/respawn.sp)

Allows respawning of players or bots. Support for some customization of per round counting, total respawns, delays, and team-specific rules. Also has an admin menu hook.

#### Dependencies
 * [gamedata/plugin.respawn.txt](gamedata/plugin.respawn.txt&raw=true)
 * [translations/common.phrases.txt](translations/common.phrases.txt&raw=true)
 * [translations/respawn.phrases.txt](translations/respawn.phrases.txt&raw=true)

#### CVAR List
 * sm_respawn_enabled: Automatically respawn players when they die; 0 - disabled, 1 - enabled); (default: 0)
 * sm_respawn_delay: How many seconds to delay the respawn); (default: 1.0)
 * sm_respawn_counterattack: Respawn during counterattack?  (default: 0)
 * sm_respawn_final_counterattack: Respawn during final counterattack?  (default: 0)
 * sm_respawn_count: Respawn all players this many times); (default: 0)
 * sm_respawn_count_team2: Respawn all Team 2 players this many times); (default: -1)
 * sm_respawn_count_team3: Respawn all Team 3 players this many times); (default: -1)
 * sm_respawn_reset_each_round: Reset player respawn counts each round); (default: 1)
 * sm_respawn_reset_each_objective: Reset player respawn counts each objective); (default: 1)

### Restricted Area Removal (version 0.0.1)
Plugin for removing Restricted Areas

[Plugin](plugins/restrictedarea.smx?raw=true) - [Source](scripting/restrictedarea.sp)

Removes all restricted areas on the map. Release ready, no known bugs.

#### CVAR List
 * sm_restrictedarea_enabled: sets whether bot naming is enabled (default: 1)

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


### Suicide Bombers (version 0.0.4)
Adds suicide bomb for bots

[Plugin](plugins/suicide_bomb.smx?raw=true) - [Source](scripting/suicide_bomb.sp)

Adds a suicide bomb effect that creates an IED at the player's origin and immediately detonates. Release 1 has all 'bomber' class players detonate on death, which is very annoying in game but is a proof of concept.

#### CVAR List
 * sm_suicidebomb_enabled: sets whether suicide bombs are enabled (default: 0)
 * sm_suicidebomb_explode_armed: Explode when killed if C4 or IED is in hand (default: 0)
 * sm_suicidebomb_death_chance: Chance as a fraction of 1 that a bomber will explode when killed (default: 0.1)

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
