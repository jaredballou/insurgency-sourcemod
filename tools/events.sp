#define PLUGIN_AUTHOR "Jared Ballou"
#define PLUGIN_DESCRIPTION "Log events to client or server"
#define PLUGIN_NAME "Event Logger"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_WORKING "1"
#define PLUGIN_LOG_PREFIX "EVENTS"
#define PLUGIN_URL "http://jballou.com/insurgency"

public Plugin:myinfo = {
        name            = PLUGIN_NAME,
        author          = PLUGIN_AUTHOR,
        description     = PLUGIN_DESCRIPTION,
        version         = PLUGIN_VERSION,
        url             = PLUGIN_URL
};
#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <updater>

#pragma semicolon 1

public OnPluginStart() {
	HookEvent("player_hurt", Event_Player_Hurt);
	HookEvent("player_footstep", Event_Player_Footstep);
	HookEvent("player_jump", Event_Player_Jump);
	HookEvent("player_blind", Event_Player_Blind);
	HookEvent("player_falldamage", Event_Player_Falldamage);
	HookEvent("player_stats_updated", Event_Player_Stats_Updated);
	HookEvent("player_avenged_teammate", Event_Player_Avenged_Teammate);
	HookEvent("player_decal", Event_Player_Decal);
	HookEvent("player_death", Event_Player_Death);
	HookEvent("player_drop", Event_Player_Drop);
	HookEvent("player_receive_supply", Event_Player_Receive_Supply);
	HookEvent("player_first_spawn", Event_Player_First_Spawn);
	HookEvent("player_pick_squad", Event_Player_Pick_Squad);
	HookEvent("player_suppressed", Event_Player_Suppressed);
	HookEvent("weapon_fire", Event_Weapon_Fire);
	HookEvent("weapon_fire_on_empty", Event_Weapon_Fire_On_Empty);
	HookEvent("weapon_outofammo", Event_Weapon_Outofammo);
	HookEvent("weapon_reload", Event_Weapon_Reload);
	HookEvent("weapon_pickup", Event_Weapon_Pickup);
	HookEvent("weapon_deploy", Event_Weapon_Deploy);
	HookEvent("weapon_holster", Event_Weapon_Holster);
	HookEvent("weapon_ironsight", Event_Weapon_Ironsight);
	HookEvent("weapon_lower_sight", Event_Weapon_Lower_Sight);
	HookEvent("weapon_focus_enter", Event_Weapon_Focus_Enter);
	HookEvent("weapon_focus_exit", Event_Weapon_Focus_Exit);
	HookEvent("weapon_firemode", Event_Weapon_Firemode);
	HookEvent("grenade_thrown", Event_Grenade_Thrown);
	HookEvent("grenade_detonate", Event_Grenade_Detonate);
	HookEvent("game_start", Event_Game_Start);
	HookEvent("game_teams_switched", Event_Game_Teams_Switched);
	HookEvent("game_newmap", Event_Game_Newmap);
	HookEvent("game_end", Event_Game_End);
	HookEvent("round_start", Event_Round_Start);
	HookEvent("round_end", Event_Round_End);
	HookEvent("round_freeze_end", Event_Round_Freeze_End);
	HookEvent("round_restart", Event_Round_Restart);
	HookEvent("round_begin", Event_Round_Begin);
	HookEvent("round_timer_changed", Event_Round_Timer_Changed);
	HookEvent("round_level_advanced", Event_Round_Level_Advanced);
	HookEvent("controlpoint_initialized", Event_Controlpoint_Initialized);
	HookEvent("controlpoint_captured", Event_Controlpoint_Captured);
	HookEvent("controlpoint_neutralized", Event_Controlpoint_Neutralized);
	HookEvent("controlpoint_endtouch", Event_Controlpoint_Endtouch);
	HookEvent("controlpoint_starttouch", Event_Controlpoint_Starttouch);
	HookEvent("door_moving", Event_Door_Moving);
	HookEvent("nav_blocked", Event_Nav_Blocked);
	HookEvent("nav_generate", Event_Nav_Generate);
	HookEvent("achievement_info_loaded", Event_Achievement_Info_Loaded);
	HookEvent("rank_mgr_ranks_calculated", Event_Rank_Mgr_Ranks_Calculated);
	HookEvent("spec_target_updated", Event_Spec_Target_Updated);
	HookEvent("spec_mode_updated", Event_Spec_Mode_Updated);
	HookEvent("hltv_changed_mode", Event_Hltv_Changed_Mode);
	HookEvent("show_freezepanel", Event_Show_Freezepanel);
	HookEvent("hide_freezepanel", Event_Hide_Freezepanel);
	HookEvent("freezecam_started", Event_Freezecam_Started);
	HookEvent("achievement_earned", Event_Achievement_Earned);
	HookEvent("client_disconnect", Event_Client_Disconnect);
	HookEvent("inventory_open", Event_Inventory_Open);
	HookEvent("inventory_close", Event_Inventory_Close);
	HookEvent("enter_spawnzone", Event_Enter_Spawnzone);
	HookEvent("exit_spawnzone", Event_Exit_Spawnzone);
	HookEvent("missile_launched", Event_Missile_Launched);
	HookEvent("missile_detonate", Event_Missile_Detonate);
	HookEvent("smoke_grenade_expire", Event_Smoke_Grenade_Expire);
	HookEvent("flag_pickup", Event_Flag_Pickup);
	HookEvent("flag_drop", Event_Flag_Drop);
	HookEvent("flag_captured", Event_Flag_Captured);
	HookEvent("flag_returned", Event_Flag_Returned);
	HookEvent("flag_reset", Event_Flag_Reset);
	HookEvent("object_destroyed", Event_Object_Destroyed);
	HookEvent("time_class", Event_Time_Class);
	HookEvent("time_weapon", Event_Time_Weapon);
	HookEvent("training_timer", Event_Training_Timer);
	HookEvent("instructor_ai_difficulty", Event_Instructor_Ai_Difficulty);
	HookEvent("stat_summary_updated", Event_Stat_Summary_Updated);
	HookEvent("stat_local_load_start", Event_Stat_Local_Load_Start);
	HookEvent("stat_local_load_finish", Event_Stat_Local_Load_Finish);
	HookEvent("stat_leaderboard_updated", Event_Stat_Leaderboard_Updated);
	HookEvent("radio_requested", Event_Radio_Requested);
	HookEvent("artillery_requested", Event_Artillery_Requested);
	HookEvent("artillery_failed", Event_Artillery_Failed);
	HookEvent("artillery_called", Event_Artillery_Called);
	HookUpdater();
}

public void RecordEvent(const char[] name, const char[] fields) {
        LogToGame("\"event\": {\"%s\": { %s }}", name, fields);
}
public void Event_Player_Hurt(Event event, const char[] name, bool dontBroadcast) {
	int m_Priority = event.GetInt("priority");
	int m_Attacker = event.GetInt("attacker");
	int m_Dmg_Health = event.GetInt("dmg_health");
	int m_Health = event.GetInt("health");
	int m_Damagebits = event.GetInt("damagebits");
	int m_Hitgroup = event.GetInt("hitgroup");
	char m_Weapon[256];
	event.GetString("weapon", m_Weapon, sizeof(m_Weapon));
	int m_Weaponid = event.GetInt("weaponid");
	int m_Userid = event.GetInt("userid");
	RecordEvent(name, "\"priority\": \"%d\",\"attacker\": \"%d\",\"dmg_health\": \"%d\",\"health\": \"%d\",\"damagebits\": \"%d\",\"hitgroup\": \"%d\",\"weapon\": \"%s\",\"weaponid\": \"%d\",\"userid\": \"%d\",} } ", priority, attacker, dmg_health, health, damagebits, hitgroup, weapon, weaponid, userid);
}
public void Event_Player_Footstep(Event event, const char[] name, bool dontBroadcast) {
	int m_Userid = event.GetInt("userid");
	RecordEvent(name, "\"userid\": \"%d\",} } ", userid);
}
public void Event_Player_Jump(Event event, const char[] name, bool dontBroadcast) {
	int m_Userid = event.GetInt("userid");
	RecordEvent(name, "\"userid\": \"%d\",} } ", userid);
}
public void Event_Player_Blind(Event event, const char[] name, bool dontBroadcast) {
	int m_Userid = event.GetInt("userid");
	RecordEvent(name, "\"userid\": \"%d\",} } ", userid);
}
public void Event_Player_Falldamage(Event event, const char[] name, bool dontBroadcast) {
	int m_Userid = event.GetInt("userid");
	float m_Damage = event.GetFloat("damage");
	RecordEvent(name, "\"userid\": \"%d\",\"damage\": \"%f\",} } ", userid, damage);
}
public void Event_Player_Stats_Updated(Event event, const char[] name, bool dontBroadcast) {
	RecordEvent(name, "} } ", );
}
public void Event_Player_Avenged_Teammate(Event event, const char[] name, bool dontBroadcast) {
	int m_Avenger_Id = event.GetInt("avenger_id");
	int m_Avenged_Player_Id = event.GetInt("avenged_player_id");
	RecordEvent(name, "\"avenger_id\": \"%d\",\"avenged_player_id\": \"%d\",} } ", avenger_id, avenged_player_id);
}
public void Event_Player_Decal(Event event, const char[] name, bool dontBroadcast) {
	int m_Userid = event.GetInt("userid");
	RecordEvent(name, "\"userid\": \"%d\",} } ", userid);
}
public void Event_Player_Death(Event event, const char[] name, bool dontBroadcast) {
	int m_Deathflags = event.GetInt("deathflags");
	int m_Attacker = event.GetInt("attacker");
	int m_Customkill = event.GetInt("customkill");
	int m_Lives = event.GetInt("lives");
	int m_Attackerteam = event.GetInt("attackerteam");
	int m_Damagebits = event.GetInt("damagebits");
	char m_Weapon[256];
	event.GetString("weapon", m_Weapon, sizeof(m_Weapon));
	int m_Weaponid = event.GetInt("weaponid");
	int m_Userid = event.GetInt("userid");
	int m_Priority = event.GetInt("priority");
	int m_Team = event.GetInt("team");
	float m_Y = event.GetFloat("y");
	float m_X = event.GetFloat("x");
	float m_Z = event.GetFloat("z");
	int m_Assister = event.GetInt("assister");
	RecordEvent(name, "\"deathflags\": \"%d\",\"attacker\": \"%d\",\"customkill\": \"%d\",\"lives\": \"%d\",\"attackerteam\": \"%d\",\"damagebits\": \"%d\",\"weapon\": \"%s\",\"weaponid\": \"%d\",\"userid\": \"%d\",\"priority\": \"%d\",\"team\": \"%d\",\"y\": \"%f\",\"x\": \"%f\",\"z\": \"%f\",\"assister\": \"%d\",} } ", deathflags, attacker, customkill, lives, attackerteam, damagebits, weapon, weaponid, userid, priority, team, y, x, z, assister);
}
public void Event_Player_Drop(Event event, const char[] name, bool dontBroadcast) {
	int m_Userid = event.GetInt("userid");
	int m_Entity = event.GetInt("entity");
	RecordEvent(name, "\"userid\": \"%d\",\"entity\": \"%d\",} } ", userid, entity);
}
public void Event_Player_Receive_Supply(Event event, const char[] name, bool dontBroadcast) {
	int m_Userid = event.GetInt("userid");
	int m_Ammount = event.GetInt("ammount");
	RecordEvent(name, "\"userid\": \"%d\",\"ammount\": \"%d\",} } ", userid, ammount);
}
public void Event_Player_First_Spawn(Event event, const char[] name, bool dontBroadcast) {
	int m_Userid = event.GetInt("userid");
	RecordEvent(name, "\"userid\": \"%d\",} } ", userid);
}
public void Event_Player_Pick_Squad(Event event, const char[] name, bool dontBroadcast) {
	int m_Squad_Slot = event.GetInt("squad_slot");
	int m_Squad = event.GetInt("squad");
	int m_Userid = event.GetInt("userid");
	char m_Class_Template[256];
	event.GetString("class_template", m_Class_Template, sizeof(m_Class_Template));
	RecordEvent(name, "\"squad_slot\": \"%d\",\"squad\": \"%d\",\"userid\": \"%d\",\"class_template\": \"%s\",} } ", squad_slot, squad, userid, class_template);
}
public void Event_Player_Suppressed(Event event, const char[] name, bool dontBroadcast) {
	int m_Attacker = event.GetInt("attacker");
	int m_Victim = event.GetInt("victim");
	RecordEvent(name, "\"attacker\": \"%d\",\"victim\": \"%d\",} } ", attacker, victim);
}
public void Event_Weapon_Fire(Event event, const char[] name, bool dontBroadcast) {
	int m_Weaponid = event.GetInt("weaponid");
	int m_Userid = event.GetInt("userid");
	int m_Shots = event.GetInt("shots");
	RecordEvent(name, "\"weaponid\": \"%d\",\"userid\": \"%d\",\"shots\": \"%d\",} } ", weaponid, userid, shots);
}
public void Event_Weapon_Fire_On_Empty(Event event, const char[] name, bool dontBroadcast) {
	char m_Weapon[256];
	event.GetString("weapon", m_Weapon, sizeof(m_Weapon));
	int m_Userid = event.GetInt("userid");
	RecordEvent(name, "\"weapon\": \"%s\",\"userid\": \"%d\",} } ", weapon, userid);
}
public void Event_Weapon_Outofammo(Event event, const char[] name, bool dontBroadcast) {
	int m_Userid = event.GetInt("userid");
	RecordEvent(name, "\"userid\": \"%d\",} } ", userid);
}
public void Event_Weapon_Reload(Event event, const char[] name, bool dontBroadcast) {
	int m_Userid = event.GetInt("userid");
	RecordEvent(name, "\"userid\": \"%d\",} } ", userid);
}
public void Event_Weapon_Pickup(Event event, const char[] name, bool dontBroadcast) {
	int m_Weaponid = event.GetInt("weaponid");
	int m_Userid = event.GetInt("userid");
	RecordEvent(name, "\"weaponid\": \"%d\",\"userid\": \"%d\",} } ", weaponid, userid);
}
public void Event_Weapon_Deploy(Event event, const char[] name, bool dontBroadcast) {
	int m_Weaponid = event.GetInt("weaponid");
	int m_Userid = event.GetInt("userid");
	RecordEvent(name, "\"weaponid\": \"%d\",\"userid\": \"%d\",} } ", weaponid, userid);
}
public void Event_Weapon_Holster(Event event, const char[] name, bool dontBroadcast) {
	int m_Weaponid = event.GetInt("weaponid");
	int m_Userid = event.GetInt("userid");
	RecordEvent(name, "\"weaponid\": \"%d\",\"userid\": \"%d\",} } ", weaponid, userid);
}
public void Event_Weapon_Ironsight(Event event, const char[] name, bool dontBroadcast) {
	int m_Weaponid = event.GetInt("weaponid");
	int m_Userid = event.GetInt("userid");
	RecordEvent(name, "\"weaponid\": \"%d\",\"userid\": \"%d\",} } ", weaponid, userid);
}
public void Event_Weapon_Lower_Sight(Event event, const char[] name, bool dontBroadcast) {
	int m_Weaponid = event.GetInt("weaponid");
	int m_Userid = event.GetInt("userid");
	RecordEvent(name, "\"weaponid\": \"%d\",\"userid\": \"%d\",} } ", weaponid, userid);
}
public void Event_Weapon_Focus_Enter(Event event, const char[] name, bool dontBroadcast) {
	int m_Weaponid = event.GetInt("weaponid");
	int m_Userid = event.GetInt("userid");
	RecordEvent(name, "\"weaponid\": \"%d\",\"userid\": \"%d\",} } ", weaponid, userid);
}
public void Event_Weapon_Focus_Exit(Event event, const char[] name, bool dontBroadcast) {
	int m_Weaponid = event.GetInt("weaponid");
	int m_Userid = event.GetInt("userid");
	RecordEvent(name, "\"weaponid\": \"%d\",\"userid\": \"%d\",} } ", weaponid, userid);
}
public void Event_Weapon_Firemode(Event event, const char[] name, bool dontBroadcast) {
	int m_Weaponid = event.GetInt("weaponid");
	int m_Userid = event.GetInt("userid");
	int m_Firemode = event.GetInt("firemode");
	RecordEvent(name, "\"weaponid\": \"%d\",\"userid\": \"%d\",\"firemode\": \"%d\",} } ", weaponid, userid, firemode);
}
public void Event_Grenade_Thrown(Event event, const char[] name, bool dontBroadcast) {
	int m_Entityid = event.GetInt("entityid");
	int m_Userid = event.GetInt("userid");
	int m_Id = event.GetInt("id");
	RecordEvent(name, "\"entityid\": \"%d\",\"userid\": \"%d\",\"id\": \"%d\",} } ", entityid, userid, id);
}
public void Event_Grenade_Detonate(Event event, const char[] name, bool dontBroadcast) {
	int m_Userid = event.GetInt("userid");
	int m_Effectedenemies = event.GetInt("effectedEnemies");
	float m_Y = event.GetFloat("y");
	float m_X = event.GetFloat("x");
	int m_Entityid = event.GetInt("entityid");
	float m_Z = event.GetFloat("z");
	int m_Id = event.GetInt("id");
	RecordEvent(name, "\"userid\": \"%d\",\"effectedEnemies\": \"%d\",\"y\": \"%f\",\"x\": \"%f\",\"entityid\": \"%d\",\"z\": \"%f\",\"id\": \"%d\",} } ", userid, effectedEnemies, y, x, entityid, z, id);
}
public void Event_Game_Start(Event event, const char[] name, bool dontBroadcast) {
	int m_Priority = event.GetInt("priority");
	RecordEvent(name, "\"priority\": \"%d\",} } ", priority);
}
public void Event_Game_Teams_Switched(Event event, const char[] name, bool dontBroadcast) {
	RecordEvent(name, "} } ", );
}
public void Event_Game_Newmap(Event event, const char[] name, bool dontBroadcast) {
	char m_Mapname[256];
	event.GetString("mapname", m_Mapname, sizeof(m_Mapname));
	RecordEvent(name, "\"mapname\": \"%s\",} } ", mapname);
}
public void Event_Game_End(Event event, const char[] name, bool dontBroadcast) {
	int m_Team2_Score = event.GetInt("team2_score");
	int m_Winner = event.GetInt("winner");
	int m_Team1_Score = event.GetInt("team1_score");
	RecordEvent(name, "\"team2_score\": \"%d\",\"winner\": \"%d\",\"team1_score\": \"%d\",} } ", team2_score, winner, team1_score);
}
public void Event_Round_Start(Event event, const char[] name, bool dontBroadcast) {
	int m_Priority = event.GetInt("priority");
	int m_Timelimit = event.GetInt("timelimit");
	int m_Lives = event.GetInt("lives");
	int m_Gametype = event.GetInt("gametype");
	RecordEvent(name, "\"priority\": \"%d\",\"timelimit\": \"%d\",\"lives\": \"%d\",\"gametype\": \"%d\",} } ", priority, timelimit, lives, gametype);
}
public void Event_Round_End(Event event, const char[] name, bool dontBroadcast) {
	int m_Reason = event.GetInt("reason");
	int m_Winner = event.GetInt("winner");
	char m_Message[256];
	event.GetString("message", m_Message, sizeof(m_Message));
	char m_Message_String[256];
	event.GetString("message_string", m_Message_String, sizeof(m_Message_String));
	RecordEvent(name, "\"reason\": \"%d\",\"winner\": \"%d\",\"message\": \"%s\",\"message_string\": \"%s\",} } ", reason, winner, message, message_string);
}
public void Event_Round_Freeze_End(Event event, const char[] name, bool dontBroadcast) {
	RecordEvent(name, "} } ", );
}
public void Event_Round_Restart(Event event, const char[] name, bool dontBroadcast) {
	RecordEvent(name, "} } ", );
}
public void Event_Round_Begin(Event event, const char[] name, bool dontBroadcast) {
	RecordEvent(name, "} } ", );
}
public void Event_Round_Timer_Changed(Event event, const char[] name, bool dontBroadcast) {
	float m_Delta = event.GetFloat("delta");
	RecordEvent(name, "\"delta\": \"%f\",} } ", delta);
}
public void Event_Round_Level_Advanced(Event event, const char[] name, bool dontBroadcast) {
	int m_Level = event.GetInt("level");
	RecordEvent(name, "\"level\": \"%d\",} } ", level);
}
public void Event_Controlpoint_Initialized(Event event, const char[] name, bool dontBroadcast) {
	RecordEvent(name, "} } ", );
}
public void Event_Controlpoint_Captured(Event event, const char[] name, bool dontBroadcast) {
	int m_Priority = event.GetInt("priority");
	int m_Cp = event.GetInt("cp");
	char m_Cappers[256];
	event.GetString("cappers", m_Cappers, sizeof(m_Cappers));
	char m_Cpname[256];
	event.GetString("cpname", m_Cpname, sizeof(m_Cpname));
	int m_Team = event.GetInt("team");
	int m_Oldteam = event.GetInt("oldteam");
	RecordEvent(name, "\"priority\": \"%d\",\"cp\": \"%d\",\"cappers\": \"%s\",\"cpname\": \"%s\",\"team\": \"%d\",\"oldteam\": \"%d\",} } ", priority, cp, cappers, cpname, team, oldteam);
}
public void Event_Controlpoint_Neutralized(Event event, const char[] name, bool dontBroadcast) {
	int m_Priority = event.GetInt("priority");
	int m_Cp = event.GetInt("cp");
	char m_Cappers[256];
	event.GetString("cappers", m_Cappers, sizeof(m_Cappers));
	char m_Cpname[256];
	event.GetString("cpname", m_Cpname, sizeof(m_Cpname));
	int m_Team = event.GetInt("team");
	int m_Oldteam = event.GetInt("oldteam");
	RecordEvent(name, "\"priority\": \"%d\",\"cp\": \"%d\",\"cappers\": \"%s\",\"cpname\": \"%s\",\"team\": \"%d\",\"oldteam\": \"%d\",} } ", priority, cp, cappers, cpname, team, oldteam);
}
public void Event_Controlpoint_Endtouch(Event event, const char[] name, bool dontBroadcast) {
	int m_Owner = event.GetInt("owner");
	int m_Player = event.GetInt("player");
	int m_Team = event.GetInt("team");
	int m_Area = event.GetInt("area");
	RecordEvent(name, "\"owner\": \"%d\",\"player\": \"%d\",\"team\": \"%d\",\"area\": \"%d\",} } ", owner, player, team, area);
}
public void Event_Controlpoint_Starttouch(Event event, const char[] name, bool dontBroadcast) {
	int m_Area = event.GetInt("area");
	int m_Object = event.GetInt("object");
	int m_Player = event.GetInt("player");
	int m_Team = event.GetInt("team");
	int m_Owner = event.GetInt("owner");
	int m_Type = event.GetInt("type");
	RecordEvent(name, "\"area\": \"%d\",\"object\": \"%d\",\"player\": \"%d\",\"team\": \"%d\",\"owner\": \"%d\",\"type\": \"%d\",} } ", area, object, player, team, owner, type);
}
public void Event_Door_Moving(Event event, const char[] name, bool dontBroadcast) {
	int m_Entindex = event.GetInt("entindex");
	int m_Userid = event.GetInt("userid");
	RecordEvent(name, "\"entindex\": \"%d\",\"userid\": \"%d\",} } ", entindex, userid);
}
public void Event_Nav_Blocked(Event event, const char[] name, bool dontBroadcast) {
	int m_Area = event.GetInt("area");
	bool m_Blocked = event.GetBool("blocked");
	RecordEvent(name, "\"area\": \"%d\",\"blocked\": \"%d\",} } ", area, blocked);
}
public void Event_Nav_Generate(Event event, const char[] name, bool dontBroadcast) {
	RecordEvent(name, "} } ", );
}
public void Event_Achievement_Info_Loaded(Event event, const char[] name, bool dontBroadcast) {
	RecordEvent(name, "} } ", );
}
public void Event_Rank_Mgr_Ranks_Calculated(Event event, const char[] name, bool dontBroadcast) {
	RecordEvent(name, "} } ", );
}
public void Event_Spec_Target_Updated(Event event, const char[] name, bool dontBroadcast) {
	RecordEvent(name, "} } ", );
}
public void Event_Spec_Mode_Updated(Event event, const char[] name, bool dontBroadcast) {
	RecordEvent(name, "} } ", );
}
public void Event_Hltv_Changed_Mode(Event event, const char[] name, bool dontBroadcast) {
	int m_Newmode = event.GetInt("newmode");
	int m_Oldmode = event.GetInt("oldmode");
	int m_Obs_Target = event.GetInt("obs_target");
	RecordEvent(name, "\"newmode\": \"%d\",\"oldmode\": \"%d\",\"obs_target\": \"%d\",} } ", newmode, oldmode, obs_target);
}
public void Event_Show_Freezepanel(Event event, const char[] name, bool dontBroadcast) {
	int m_Hits_Taken = event.GetInt("hits_taken");
	int m_Damage_Given = event.GetInt("damage_given");
	int m_Hits_Given = event.GetInt("hits_given");
	int m_Killer = event.GetInt("killer");
	int m_Damage_Taken = event.GetInt("damage_taken");
	int m_Victim = event.GetInt("victim");
	RecordEvent(name, "\"hits_taken\": \"%d\",\"damage_given\": \"%d\",\"hits_given\": \"%d\",\"killer\": \"%d\",\"damage_taken\": \"%d\",\"victim\": \"%d\",} } ", hits_taken, damage_given, hits_given, killer, damage_taken, victim);
}
public void Event_Hide_Freezepanel(Event event, const char[] name, bool dontBroadcast) {
	RecordEvent(name, "} } ", );
}
public void Event_Freezecam_Started(Event event, const char[] name, bool dontBroadcast) {
	RecordEvent(name, "} } ", );
}
public void Event_Achievement_Earned(Event event, const char[] name, bool dontBroadcast) {
	int m_Player = event.GetInt("player");
	int m_Achievement = event.GetInt("achievement");
	RecordEvent(name, "\"player\": \"%d\",\"achievement\": \"%d\",} } ", player, achievement);
}
public void Event_Client_Disconnect(Event event, const char[] name, bool dontBroadcast) {
	RecordEvent(name, "} } ", );
}
public void Event_Inventory_Open(Event event, const char[] name, bool dontBroadcast) {
	RecordEvent(name, "} } ", );
}
public void Event_Inventory_Close(Event event, const char[] name, bool dontBroadcast) {
	RecordEvent(name, "} } ", );
}
public void Event_Enter_Spawnzone(Event event, const char[] name, bool dontBroadcast) {
	int m_Userid = event.GetInt("userid");
	RecordEvent(name, "\"userid\": \"%d\",} } ", userid);
}
public void Event_Exit_Spawnzone(Event event, const char[] name, bool dontBroadcast) {
	int m_Userid = event.GetInt("userid");
	RecordEvent(name, "\"userid\": \"%d\",} } ", userid);
}
public void Event_Missile_Launched(Event event, const char[] name, bool dontBroadcast) {
	int m_Entityid = event.GetInt("entityid");
	int m_Userid = event.GetInt("userid");
	int m_Id = event.GetInt("id");
	RecordEvent(name, "\"entityid\": \"%d\",\"userid\": \"%d\",\"id\": \"%d\",} } ", entityid, userid, id);
}
public void Event_Missile_Detonate(Event event, const char[] name, bool dontBroadcast) {
	int m_Userid = event.GetInt("userid");
	float m_Y = event.GetFloat("y");
	float m_X = event.GetFloat("x");
	int m_Entityid = event.GetInt("entityid");
	float m_Z = event.GetFloat("z");
	int m_Id = event.GetInt("id");
	RecordEvent(name, "\"userid\": \"%d\",\"y\": \"%f\",\"x\": \"%f\",\"entityid\": \"%d\",\"z\": \"%f\",\"id\": \"%d\",} } ", userid, y, x, entityid, z, id);
}
public void Event_Smoke_Grenade_Expire(Event event, const char[] name, bool dontBroadcast) {
	int m_Userid = event.GetInt("userid");
	float m_Y = event.GetFloat("y");
	float m_X = event.GetFloat("x");
	int m_Entityid = event.GetInt("entityid");
	float m_Z = event.GetFloat("z");
	int m_Id = event.GetInt("id");
	RecordEvent(name, "\"userid\": \"%d\",\"y\": \"%f\",\"x\": \"%f\",\"entityid\": \"%d\",\"z\": \"%f\",\"id\": \"%d\",} } ", userid, y, x, entityid, z, id);
}
public void Event_Flag_Pickup(Event event, const char[] name, bool dontBroadcast) {
	int m_Priority = event.GetInt("priority");
	int m_Userid = event.GetInt("userid");
	RecordEvent(name, "\"priority\": \"%d\",\"userid\": \"%d\",} } ", priority, userid);
}
public void Event_Flag_Drop(Event event, const char[] name, bool dontBroadcast) {
	int m_Priority = event.GetInt("priority");
	int m_Userid = event.GetInt("userid");
	RecordEvent(name, "\"priority\": \"%d\",\"userid\": \"%d\",} } ", priority, userid);
}
public void Event_Flag_Captured(Event event, const char[] name, bool dontBroadcast) {
	int m_Priority = event.GetInt("priority");
	int m_Cp = event.GetInt("cp");
	int m_Userid = event.GetInt("userid");
	RecordEvent(name, "\"priority\": \"%d\",\"cp\": \"%d\",\"userid\": \"%d\",} } ", priority, cp, userid);
}
public void Event_Flag_Returned(Event event, const char[] name, bool dontBroadcast) {
	int m_Priority = event.GetInt("priority");
	int m_Userid = event.GetInt("userid");
	RecordEvent(name, "\"priority\": \"%d\",\"userid\": \"%d\",} } ", priority, userid);
}
public void Event_Flag_Reset(Event event, const char[] name, bool dontBroadcast) {
	int m_Priority = event.GetInt("priority");
	int m_Team = event.GetInt("team");
	RecordEvent(name, "\"priority\": \"%d\",\"team\": \"%d\",} } ", priority, team);
}
public void Event_Object_Destroyed(Event event, const char[] name, bool dontBroadcast) {
	int m_Team = event.GetInt("team");
	int m_Attacker = event.GetInt("attacker");
	int m_Cp = event.GetInt("cp");
	int m_Index = event.GetInt("index");
	int m_Type = event.GetInt("type");
	char m_Weapon[256];
	event.GetString("weapon", m_Weapon, sizeof(m_Weapon));
	int m_Weaponid = event.GetInt("weaponid");
	int m_Assister = event.GetInt("assister");
	int m_Attackerteam = event.GetInt("attackerteam");
	RecordEvent(name, "\"team\": \"%d\",\"attacker\": \"%d\",\"cp\": \"%d\",\"index\": \"%d\",\"type\": \"%d\",\"weapon\": \"%s\",\"weaponid\": \"%d\",\"assister\": \"%d\",\"attackerteam\": \"%d\",} } ", team, attacker, cp, index, type, weapon, weaponid, assister, attackerteam);
}
public void Event_Time_Class(Event event, const char[] name, bool dontBroadcast) {
	float m_Seconds = event.GetFloat("seconds");
	int m_Userid = event.GetInt("userid");
	int m_Class = event.GetInt("class");
	RecordEvent(name, "\"seconds\": \"%f\",\"userid\": \"%d\",\"class\": \"%d\",} } ", seconds, userid, class);
}
public void Event_Time_Weapon(Event event, const char[] name, bool dontBroadcast) {
	float m_Seconds = event.GetFloat("seconds");
	int m_Weapon = event.GetInt("weapon");
	int m_Userid = event.GetInt("userid");
	RecordEvent(name, "\"seconds\": \"%f\",\"weapon\": \"%d\",\"userid\": \"%d\",} } ", seconds, weapon, userid);
}
public void Event_Training_Timer(Event event, const char[] name, bool dontBroadcast) {
	float m_Duration = event.GetFloat("duration");
	RecordEvent(name, "\"duration\": \"%f\",} } ", duration);
}
public void Event_Instructor_Ai_Difficulty(Event event, const char[] name, bool dontBroadcast) {
	int m_Rounds_Failed = event.GetInt("rounds_failed");
	bool m_Ai_Win = event.GetBool("ai_win");
	RecordEvent(name, "\"rounds_failed\": \"%d\",\"ai_win\": \"%d\",} } ", rounds_failed, ai_win);
}
public void Event_Stat_Summary_Updated(Event event, const char[] name, bool dontBroadcast) {
	bool m_Localplayer = event.GetBool("localplayer");
	RecordEvent(name, "\"localplayer\": \"%d\",} } ", localplayer);
}
public void Event_Stat_Local_Load_Start(Event event, const char[] name, bool dontBroadcast) {
	RecordEvent(name, "} } ", );
}
public void Event_Stat_Local_Load_Finish(Event event, const char[] name, bool dontBroadcast) {
	RecordEvent(name, "} } ", );
}
public void Event_Stat_Leaderboard_Updated(Event event, const char[] name, bool dontBroadcast) {
	RecordEvent(name, "} } ", );
}
public void Event_Radio_Requested(Event event, const char[] name, bool dontBroadcast) {
	int m_Requesting_Player = event.GetInt("requesting_player");
	int m_Team = event.GetInt("team");
	RecordEvent(name, "\"requesting_player\": \"%d\",\"team\": \"%d\",} } ", requesting_player, team);
}
public void Event_Artillery_Requested(Event event, const char[] name, bool dontBroadcast) {
	int m_Requesting_Player = event.GetInt("requesting_player");
	int m_Radio_Player = event.GetInt("radio_player");
	int m_Team = event.GetInt("team");
	char m_Type[256];
	event.GetString("type", m_Type, sizeof(m_Type));
	bool m_Lethal = event.GetBool("lethal");
	float m_Target_X = event.GetFloat("target_x");
	float m_Target_Y = event.GetFloat("target_y");
	float m_Target_Z = event.GetFloat("target_z");
	RecordEvent(name, "\"requesting_player\": \"%d\",\"radio_player\": \"%d\",\"team\": \"%d\",\"type\": \"%s\",\"lethal\": \"%d\",\"target_x\": \"%f\",\"target_y\": \"%f\",\"target_z\": \"%f\",} } ", requesting_player, radio_player, team, type, lethal, target_x, target_y, target_z);
}
public void Event_Artillery_Failed(Event event, const char[] name, bool dontBroadcast) {
	int m_Requesting_Player = event.GetInt("requesting_player");
	int m_Radio_Player = event.GetInt("radio_player");
	int m_Team = event.GetInt("team");
	char m_Type[256];
	event.GetString("type", m_Type, sizeof(m_Type));
	bool m_Lethal = event.GetBool("lethal");
	char m_Reason[256];
	event.GetString("reason", m_Reason, sizeof(m_Reason));
	RecordEvent(name, "\"requesting_player\": \"%d\",\"radio_player\": \"%d\",\"team\": \"%d\",\"type\": \"%s\",\"lethal\": \"%d\",\"reason\": \"%s\",} } ", requesting_player, radio_player, team, type, lethal, reason);
}
public void Event_Artillery_Called(Event event, const char[] name, bool dontBroadcast) {
	int m_Requesting_Player = event.GetInt("requesting_player");
	int m_Radio_Player = event.GetInt("radio_player");
	int m_Team = event.GetInt("team");
	char m_Type[256];
	event.GetString("type", m_Type, sizeof(m_Type));
	bool m_Lethal = event.GetBool("lethal");
	float m_Target_X = event.GetFloat("target_x");
	float m_Target_Y = event.GetFloat("target_y");
	float m_Target_Z = event.GetFloat("target_z");
	RecordEvent(name, "\"requesting_player\": \"%d\",\"radio_player\": \"%d\",\"team\": \"%d\",\"type\": \"%s\",\"lethal\": \"%d\",\"target_x\": \"%f\",\"target_y\": \"%f\",\"target_z\": \"%f\",} } ", requesting_player, radio_player, team, type, lethal, target_x, target_y, target_z);
}
	