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

