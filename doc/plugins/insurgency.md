---
### Insurgency Support Library (version 1.0.3)
Provides functions to support Insurgency and fixes logging

 * [Plugin - insurgency.smx](plugins/insurgency.smx?raw=true)
 * [Source - insurgency.sp](scripting/insurgency.sp)

Creates hooks and events for Insurgency-specific stat logging, entities, and events. Fixes a lot of issues with missing log entries for HLStatsX, this plugin is tightly bound with my HLStatsX fork I created to handle more Insurgency-specific data and events. This is based off of Brutus' Insurgency logger, but adds support for nearly every event supported by the game, enhances support for new weapons by removing the old config file method of adding weapons, and generally kicks ass if you're looking to create stats from Insurgency. It also includes a number of natives for checking game rules and objective status. This is generally stable, I look at it as a beta release candidate right now.

#### Dependencies
 * [gamedata/insurgency.games.txt](gamedata/insurgency.games.txt)
 * [translations/insurgency.phrases.txt](translations/insurgency.phrases.txt)

#### CVAR List
 * "sm_inslogger_enabled" "1" //sets whether log fixing is enabled
 * "sm_insurgency_checkpoint_capture_player_ratio" "0.5" //Fraction of living players required to capture in Checkpoint
 * "sm_insurgency_checkpoint_counterattack_capture" "0" //Enable counterattack by bots to capture points in Checkpoint
 * "sm_insurgency_infinite_ammo" "0" //Infinite ammo, still uses magazines and needs to reload
 * "sm_insurgency_infinite_magazine" "0" //Infinite magazine, will never need reloading.

#### Todo
 * [ ] Weapon lookup by index/name
 * [ ] Role (template/class) lookup by index/name/player
 * [ ] Game rules lookup (control points, status, waves, etc)
 * [ ] Precache models based upon manifests.
 * [ ] Investigate adding feature to read mp_theater_override variable, parse that theater, and add any materials/models/sounds to the list?
 * [ ] Complete theater parser in SM to get around engine theater lookup limitations?


