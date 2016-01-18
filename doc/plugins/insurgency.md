<a name='insurgency'>
---
### Insurgency Support Library 1.3.1</a>
Provides functions to support Insurgency and fixes logging

 * [Plugin - insurgency.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/insurgency.smx?raw=true)
 * [Source - insurgency.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/insurgency.sp?raw=true)

Creates hooks and events for Insurgency-specific stat logging, entities, and events. Fixes a lot of issues with missing log entries for HLStatsX, this plugin is tightly bound with my HLStatsX fork I created to handle more Insurgency-specific data and events. This is based off of Brutus' Insurgency logger, but adds support for nearly every event supported by the game, enhances support for new weapons by removing the old config file method of adding weapons, and generally kicks ass if you're looking to create stats from Insurgency. It also includes a number of natives for checking game rules and objective status. This is generally stable, I look at it as a beta release candidate right now.

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
 * "sm_insurgency_disable_sliding" "0" //
 * "sm_insurgency_log_level" "error" //Logging level, values can be: all, trace, debug, info, warn, error

#### Todo
 * [ ] Weapon lookup by index/name
 * [ ] Role (template/class) lookup by index/name/player
 * [ ] Game rules lookup (control points, status, waves, etc)
 * [ ] Precache models based upon manifests.
 * [ ] Investigate adding feature to read mp_theater_override variable, parse that theater, and add any materials/models/sounds to the list?
 * [ ] Complete theater parser in SM to get around engine theater lookup limitations?


