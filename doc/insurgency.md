<a name="insurgency">
### [INS] Insurgency Support Library 1.3.7

Provides functions to support Insurgency. Includes logging, round statistics, weapon names, player class names, and more.
 * [Source - scripting/insurgency.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/insurgency.sp?raw=true)
 * [Source - scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)
 * [Plugin - plugins/insurgency.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/insurgency.smx?raw=true)

#### Dependencies

 * [Source - scripting/include/loghelper.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/loghelper.inc?raw=true)
 * [Plugin - translations/insurgency.phrases.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/translations/insurgency.phrases.txt?raw=true)
 * [Plugin - gamedata/insurgency.games.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/gamedata/insurgency.games.txt?raw=true)

#### CVAR List

 * "sm_insurgency_class_strip_words" "template training coop security insurgent survival" // Strings to strip out of player class (squad slot) names
 * "sm_insurgency_checkpoint_capture_player_ratio" "0.5" // Fraction of living players required to capture in Checkpoint
 * "sm_insurgency_infinite_magazine" "0" // Infinite magazine
 * "sm_insurgency_enabled" "PLUGIN_WORKING" // sets whether log fixing is enabled
 * "sm_insurgency_disable_sliding" "0" // 0: do nothing
 * "sm_insurgency_log_level" "error" // Logging level
 * "sm_insurgency_infinite_ammo" "0" // Infinite ammo
 * "sm_insurgency_checkpoint_counterattack_capture" "0" // Enable counterattack by bots to capture points in Checkpoint

