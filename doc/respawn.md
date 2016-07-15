<a name="respawn">
### [INS] Player Respawn 1.8.1

Respawn players
 * [Source - scripting/respawn.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/respawn.sp?raw=true)
 * [Plugin - plugins/respawn.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/respawn.smx?raw=true)

#### Dependencies

 * [Source - scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)
 * [Plugin - translations/common.phrases.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/translations/common.phrases.txt?raw=true)
 * [Plugin - translations/respawn.phrases.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/translations/respawn.phrases.txt?raw=true)
 * [Plugin - gamedata/plugin.respawn.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/gamedata/plugin.respawn.txt?raw=true)

#### CVAR List

 * "sm_respawn_enabled" "PLUGIN_WORKING" // Enable respawn plugin
 * "sm_respawn_reset_each_round" "1" // Reset player respawn counts each round
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

