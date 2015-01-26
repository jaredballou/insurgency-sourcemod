# SourceMod for Insurgency
This repository has a complete installation of SourceMod, including all my plugins and source files. It's updated regularly, kept in sync with upstream, and includes a ton of stuff. It's still very much a development branch, so be aware that almost all the plugins I am working on are still pretty new and could be buggy.

### Plugins Ready to Use
These plugins are generally stable and functional. Unless noted, they can simply be downloaded and installed without dependencies.
* [Insurgency Logger](plugins/ins_logger.smx?raw=true): Creates hooks and events for Insurgency-specific stat logging. Fixes a lot of issues with missing log entries for HLStatsX, this plugin is tightly bound with my HLStatsX fork I created to handle more Insurgency-specific data and events. This is based off of Brutus' Insurgency logger, but adds support for nearly every event supported by the game, enhances support for new weapons by removing the old config file method of adding weapons, and generally kicks ass if you're looking to create stats from Insurgency. This is generally stable, I look at it as a beta release candidate right now.
* [HLStatsX](plugins/hlstatsx.smx?raw=true): Adds in-game support for HLStatsX servers to connect and send messages and other tasks. Adds color support, and a number of other features absent from the HLStatsX upstream version. Release ready, no known bugs.
* [Coop Lobby Size](plugins/cooplobby.smx?raw=true): Increases max for mp_cooplobbysize from 8 to 16. Requires custom theaters to allow all 16 players to select a class. Release ready, no known bugs.
* [Compass](plugins/compass.smx?raw=true): Adds a check_compass command that clients can use and get their ordinal direction where they are looking in relation to where they stand. Like a compass. Release ready, no known bugs.
* [Bot Count](plugins/botcount.smx?raw=true): Displays a popup to players every 60 seconds by default identifying remaining enemy players alive. Beginning of a "UAV" feature, my goal is to create an entity on the map that can be used to get this information rather than just spamming it. Release ready, no known bugs.
* [Restricted Area Removal](plugins/restrictedarea.smx?raw=true): Removes all restricted areas on the map. Release ready, no known bugs.
* [Fog remover](plugins/nofog.smx?raw=true): Removes all fog on the map. Release ready, no known bugs.
* [Ammo check](plugins/ammocheck.smx?raw=true): Adds check_ammo command that client runs and gets RO2-style "Mag feels mostly full" estimation of remaining ammo. Reloading will also pop this up to alert player if they have inserted a magazine that is less than full. Future features I'd like to do are to show a reload animation partially to animate the check, and have the check command delay the next weapon attack to simulate removing and checking the magazine. Due to the way the theater system works, it's not practical to hard-code weapon data like magazine capacity in the plugin as similar CS and TF2 plugins do, so I have a hacky method that checks the 'm_iClip' variable and uses that to perform the math. There are other workarounds and todos in the source code as well. Release candidate, no obvious bugs, but still needs a lot of polish.

### Plugins In Progress
These are plugins that still are not ready for general use, these will be very buggy.
* [RPG rockets drift off course](scripting/rpgdrift.sp). Add slight nudges to in-flight rockets to reduce punishment of laser beam RPGs.
  * [X] Nudge rocket in flight
  * [ ] Randomized chance of happening, default 10% for players?
  * [ ] CVAR Variables to set amount of drift, chance, and option to always force drift for bots.
* [Suicide Bombs](scripting/suicide_bomb.sp): Adds a suicide bomb effect that creates an IED at the player's origin and immediately detonates. Release 1 has all 'bomber' class players detonate on death, which is very annoying in game but is a proof of concept.
  * [ ] Add bot targeting and behavior to make them seek players
  * [ ] Add functionality to have bots blow themselves up when they run into a group of players
  * [ ] Create CVAR to enable random suicide bomb detonation based on role
  * [ ] Create CVAR to enable suicide bomb when IED phone is out
* [Chat improvements](scripting/navmesh-chat.sp): Adds prefix to all chat messages (selectable team or all) that includes grid coordinates, area name (if named in navmesh). For radio commands, it adds those and also a distance and direction related to the player. This plugin is currently complex in that it relies on parsing the map overview data from the Data repository existing in the Insurgency game root directory, cloned to insurgency-data. This has a lot of work to do, especially in getting the overview data from the engine directly rather than hacking around it. This is still very much under active development and could blow up your server, but I'd appreciate testing and feedback.
  * [ ] Get grid/overlay data from engine directly
  * [X] Create CVARs to decide if prefix is attached to all chat, team only, or just admins
  * [X] Put grid in front of all chat messages
  * [ ] Put grid, distance, and direction with radio voice commands
  * [ ] Add in-game markers for wider array of tasks
  * [ ] Add support for commands that target location other than player's current position (i.e. "grenade over there")
  * [ ] Replace spotting box with callout of distance/direction, add map marker
* [Insurgency Library](scripting/insurgency.sp): This is a new project where I am trying to build data structures and natives to support other Insurgency functionality in SourceMod.
  * [ ] Weapon lookup by index/name
  * [ ] Role (template/class) lookup by index/name/player
  * [ ] Game rules lookup (control points, status, waves, etc)
* [Bot Spawns](scripting/botspawns.sp): Adjust bot spawning and rules to increase game control.
  * [ ] Instead of spawning all bots in one spot, spawn them at hiding spots in the navmesh
  * [ ] Find path between current and next point, add bots around that axis
  * [ ] Create variables for how far off the path to spawn
  * [ ] Create timers to allow spawning small numbers of bots at different times to keep up the action
  * [ ] Create functionality to respawn bots a set number of times per round to simulate more bots than game can support
* [Backblast](scripting/backblast.sp): Adds backblast to AT4 and RPG. Still in progress.
  * [X] Add CVARs to control cone angle, kill range, and total effect range
  * [ ] Use flashbang effect as standin for non-lethal backblast
  * [X] Add CVAR for wall proximity, hurt or kill player if too close to a wall behind them
  * [X] On weapon fire for AT4/RPG, get all clients in a radius, determine angle, and apply damage or effect accordingly

### Ideas to develop
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
