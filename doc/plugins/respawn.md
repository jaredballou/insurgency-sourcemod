<a name='respawn'>
---
### Player Respawn 1.7.1</a>
Respawn dead players via admincommand or by queues

 * [Plugin - respawn.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/respawn.smx?raw=true)
 * [Source - respawn.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/respawn.sp?raw=true)

Allows respawning of players or bots. Support for some customization of per round counting, total respawns, delays, and team-specific rules. Also has an admin menu hook.

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

