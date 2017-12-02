# SourceMod for Insurgency
This repository has a complete installation of SourceMod, including all my plugins and source files. It's updated regularly, kept in sync with upstream, and includes a ton of stuff. It's still very much a development branch, so be aware that almost all the plugins I am working on are still pretty new and could be buggy.
##Plugin list
These plugins are all provided as-is, I do my best to document and describe them but they are all potentially broken, so be aware. Please send me feedback and bug reports to help keep these working.

 * <a href='#botnames'>Bot Names 1.0.5</a>
 * <a href='#cooplobby'>Coop Lobby Override 1.0.0</a>
 * <a href='#hlstatsx'>HLStatsX CE Ingame Plugin 1.6.19</a>
 * <a href='#insurgency'>Insurgency Support Library 1.5.1</a>
 * <a href='#nofog'>No Fog 1.0.1</a>
 * <a href='#restrictedarea'>Restricted Area Removal 1.0.0</a>
 * <a href='#updater'>Updater 1.3.0</a>

<a name="botnames">
### Bot Names 1.0.5

Gives automatic names to bots on creation.
#### Plugin
[plugins/botnames.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/botnames.smx?raw=true)<br>
#### Source
[scripting/botnames.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/botnames.sp?raw=true)<br>
[scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)<br>

#### CVAR List
```
"sm_botnames_list" "default" // Set list to use for bots
"sm_botnames_enabled" "1" // sets whether bot naming is enabled
"sm_botnames_suppress" "1" // sets whether to supress join/team change/name change bot messages
"sm_botnames_random" "1" // sets whether to randomize names used
"sm_botnames_prefix" "" // sets a prefix for bot names (include a trailing space, if needed!)
"sm_botnames_announce" "0" // sets whether to announce bots when added
```

#### Command List
```
"sm_botnames_reload"
"sm_botnames_rename_all"
```


<a name="cooplobby">
### Coop Lobby Override 1.0.0

Plugin for overriding Insurgency Coop to 32 players
#### Plugin
[plugins/cooplobby.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/cooplobby.smx?raw=true)<br>
#### Source
[scripting/cooplobby.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/cooplobby.sp?raw=true)<br>
[scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)<br>
[scripting/include/updater.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/updater.inc?raw=true)<br>


<a name="hlstatsx">
### HLStatsX CE Ingame Plugin 1.6.19

Provides ingame functionality for interaction from an HLstatsX CE installation
#### Plugin
[plugins/hlstatsx.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/hlstatsx.smx?raw=true)<br>
#### Source
[scripting/hlstatsx.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/hlstatsx.sp?raw=true)<br>
[scripting/include/loghelper.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/loghelper.inc?raw=true)<br>
[scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)<br>

#### CVAR List
```
"hlx_block_commands" "1" // If activated HLstatsX commands are blocked from the chat area
"hlx_protect_address" "" // Address to be protected for logging/forwarding
"hlxce_webpage" "http://www.hlxcommunity.com" // http://www.hlxcommunity.com
"hlx_server_tag" "1" // If enabled, adds "HLstatsX:CE" to server tags on supported games. 1 = Enabled (default), 0 = Disabled
"hlx_message_prefix" "" // Define the prefix displayed on every HLstatsX ingame message
```

#### Command List
```
"hlx_sm_bulkpsay"
"hlx_sm_team_action"
"hlx_sm_world_action"
"log"
"hlx_sm_psay"
"hlx_sm_swap"
"hlx_sm_browse"
"hlx_sm_hint"
"hlx_sm_redirect"
"hlx_sm_csay"
"hlx_sm_msay"
"hlx_sm_tsay"
"logaddress_del"
"hlx_sm_psay2"
"hlx_message_prefix_clear"
"logaddress_delall"
"hlx_sm_player_action"
```


<a name="insurgency">
### Insurgency Support Library 1.5.1

Provides functions to support Insurgency. Includes logging, round statistics, weapon names, player class names, and more.
#### Plugin
[translations/insurgency.phrases.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/translations/insurgency.phrases.txt?raw=true)<br>
[gamedata/insurgency.games.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/gamedata/insurgency.games.txt?raw=true)<br>
[plugins/insurgency.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/insurgency.smx?raw=true)<br>
#### Source
[scripting/insurgency.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/insurgency.sp?raw=true)<br>
[scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)<br>
[scripting/include/loghelper.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/loghelper.inc?raw=true)<br>
[scripting/include/updater.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/updater.inc?raw=true)<br>

#### CVAR List
```
"sm_insurgency_class_strip_words" "template training coop security insurgent survival" // Strings to strip out of player class (squad slot) names
"sm_insurgency_enabled" "1" // sets whether log fixing is enabled
"sm_insurgency_infinite_magazine" "0" // Infinite magazine, will never need reloading.
"sm_insurgency_disable_sliding" "0" // 0: do nothing, 1: disable for everyone, 2: disable for Security, 3: disable for Insurgents
"sm_insurgency_log_level" "error" // Logging level, values can be: all, trace, debug, info, warn, error
"sm_insurgency_infinite_ammo" "0" // Infinite ammo, still uses magazines and needs to reload
```


<a name="nofog">
### No Fog 1.0.1

Removes fog
#### Plugin
[plugins/nofog.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/nofog.smx?raw=true)<br>
#### Source
[scripting/nofog.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/nofog.sp?raw=true)<br>
[scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)<br>
[scripting/include/updater.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/updater.inc?raw=true)<br>

#### CVAR List
```
"sm_nofog_enabled" "1" // sets whether fog is enabled
```


<a name="restrictedarea">
### Restricted Area Removal 1.0.0

Plugin for removing Restricted Areas
#### Plugin
[plugins/restrictedarea.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/restrictedarea.smx?raw=true)<br>
#### Dependencies
<a href='#insurgency'>insurgency</a><br>
#### Source
[scripting/restrictedarea.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/restrictedarea.sp?raw=true)<br>
[scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)<br>
[scripting/include/updater.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/updater.inc?raw=true)<br>

#### CVAR List
```
"sm_restrictedarea_enabled" "1" // sets whether bot naming is enabled
```


<a name="updater">
### Updater 1.3.0

Automatically updates SourceMod plugins and files
#### Plugin
[translations/common.phrases.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/translations/common.phrases.txt?raw=true)<br>
[plugins/updater.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/updater.smx?raw=true)<br>
#### Source
[scripting/updater.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/updater.sp?raw=true)<br>
[scripting/include/cURL.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/cURL.inc?raw=true)<br>
[scripting/include/socket.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/socket.inc?raw=true)<br>
[scripting/include/steamtools.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/steamtools.inc?raw=true)<br>

#### CVAR List
```
"sm_updater" "2" // Determines update functionality. (1 = Notify, 2 = Download, 3 = Include source code),0
```

#### Command List
```
"sm_updater_status" // View the status of Updater.
"sm_updater_check" // Forces Updater to check for updates.
```




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

