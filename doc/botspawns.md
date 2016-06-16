### botspawns
'''[INS] Bot Spawns 0.4.0'''

Adds a number of options and ways to handle bot spawns

 * [Source - scripting/botspawns.sp](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/botspawns.sp?raw=true)
 * [Plugin - plugins/botspawns.smx](https://github.com/jaredballou/insurgency-sourcemod/blob/master/plugins/botspawns.smx?raw=true)

#### Dependencies
 * [Source - scripting/include/smlib.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/smlib.inc?raw=true)
 * [Source - scripting/include/insurgency.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/insurgency.inc?raw=true)
 * [Source - scripting/include/navmesh.inc](https://github.com/jaredballou/insurgency-sourcemod/blob/master/scripting/include/navmesh.inc?raw=true)
 * [Plugin - gamedata/insurgency.games.txt](https://github.com/jaredballou/insurgency-sourcemod/blob/master/gamedata/insurgency.games.txt?raw=true)
#### CVAR List
 * "sm_botspawns_enabled" "PLUGIN_WORKING" // $data['description']
 * "sm_botspawns_min_spawn_delay" "1" // $data['description']
 * "sm_botspawns_min_fireteam_size" "3" // $data['description']
 * "sm_botspawns_spawn_mode" "0" // $data['description']
 * "sm_botspawns_counterattack_finale_infinite" "0" // $data['description']
 * "sm_botspawns_counterattack_mode" "0" // $data['description']
 * "sm_botspawns_max_fireteam_size" "5" // $data['description']
 * "sm_botspawns_total_spawn_frac" "1.75" // $data['description']
 * "sm_botspawns_spawn_attack_delay" "10" // $data['description']
 * "sm_botspawns_spawn_snipers_alone" "1" // $data['description']
 * "sm_botspawns_max_objective_distance" "12000" // $data['description']
 * "sm_botspawns_max_player_distance" "16000" // $data['description']
 * "sm_botspawns_max_spawn_delay" "30" // $data['description']
 * "sm_botspawns_min_counterattack_distance" "3600" // $data['description']
 * "sm_botspawns_min_player_distance" "1200" // $data['description']
 * "sm_botspawns_stop_spawning_at_objective" "1" // $data['description']
 * "sm_botspawns_remove_unseen_when_capping" "1" // $data['description']
 * "sm_botspawns_min_objective_distance" "1" // $data['description']
 * "sm_botspawns_counterattack_frac" "0.5" // $data['description']
 * "sm_botspawns_version" "PLUGIN_VERSION" // $data['description']
 * "sm_botspawns_max_frac_in_game" "1" // $data['description']
 * "sm_botspawns_min_frac_in_game" "0.75" // $data['description']
