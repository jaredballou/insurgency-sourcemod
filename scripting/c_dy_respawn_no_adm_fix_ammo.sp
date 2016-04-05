#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <insurgencydy>
#undef REQUIRE_EXTENSIONS
#include <cstrike>
#include <tf2>
#include <tf2_stocks>
#define REQUIRE_EXTENSIONS
#include <navmesh>
#include <insurgency>

#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_DESCRIPTION "Respawn dead players via admincommand or by queues"
#define PLUGIN_NAME "[INS] Player Respawns"
#define PLUGIN_URL "http://jballou.com/"
#define PLUGIN_VERSION "1.7.0"
#define PLUGIN_WORKING 1

public Plugin:myinfo = {
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url		= PLUGIN_URL
};

#define Gren_M67 68
#define Gren_Incen 73
#define Gren_Molot 74
#define Gren_M18 70
#define Gren_Flash 71
#define Gren_F1 69
#define Gren_IED 72
#define Gren_C4 72
#define Gren_AT4 67
#define Gren_RPG7 61

//Player binds
#define MAX_BUTTONS 25
new g_LastButtons[MAXPLAYERS+1];

#undef REQUIRE_PLUGIN

new Handle:g_hPlayerRespawn;
new Handle:g_hGameConfig;
new Handle:h_ragdollRemoveTimer[MAXPLAYERS+1];
new Handle:h_RespawnTimers[MAXPLAYERS+1];
new Handle:h_ReviveTimer[MAXPLAYERS+1];
new Handle:h_RespawnCounterTimer[MAXPLAYERS+1];
new Handle:h_PreReviveTimer;
new Handle:h_RagdollTimer[MAXPLAYERS+1];


//Ammo Amounts
new Handle:playerClip[MAXPLAYERS + 1][2]; // Track primary and secondary ammo
new Handle:playerAmmo[MAXPLAYERS + 1][4]; // track player ammo based on weapon slot 0 - 4
new Handle:playerGrenadeType[MAXPLAYERS + 1][10]; //track player grenade types
new Handle:playerRole[MAXPLAYERS + 1]; // tracks player role so if it changes while wounded, he dies
new Handle:playerPrimary[MAXPLAYERS + 1];
new Handle:playerSecondary[MAXPLAYERS + 1];
new bool:playerRevived[MAXPLAYERS + 1];
new bool:playerFirstJoin[MAXPLAYERS + 1];
new bool:playerFirstDeath[MAXPLAYERS + 1];
new Handle:playerPickSquad[MAXPLAYERS + 1];
//Navmesh Init
new Handle:g_hHidingSpots = INVALID_HANDLE;
#define MAX_OBJECTIVES 13
#define MAX_HIDING_SPOTS 2048
#define MIN_PLAYER_DISTANCE 128.0
new g_iCPHidingSpots[MAX_OBJECTIVES][MAX_HIDING_SPOTS];
new g_iCPHidingSpotCount[MAX_OBJECTIVES];
new g_iCPLastHidingSpot[MAX_OBJECTIVES];
new Float:m_vCPPositions[MAX_OBJECTIVES][3],m_iNumControlPoints;
new g_iHidingSpotCount;


new g_reviveCounter[MAXPLAYERS+1];
new Handle:g_hRespawnTimer[MAXPLAYERS+1];
new g_RoundStatus = 0; //0 is over, 1 is active
new g_EnableRevive = 0;
new g_clientDamageDone[MAXPLAYERS+1];
//Player Distance Plugin //Credits to author = "Popoklopsi", url = "http://popoklopsi.de"
//These are the items that show, distance, name, arrow
new bool:playerItems[MAXPLAYERS + 1][3];
// unit to use 1 = feet, 0 = meters
new unit = 1;

// This will be used for checking which team the player is on before repsawning them
#define SPECTATOR_TEAM	0
#define TEAM_SPEC 	1
#define TEAM_1		2
#define TEAM_2		3

new bool:TF2 = false;

new Handle:sm_respawn_enabled = INVALID_HANDLE;
new Handle:sm_respawn_delay = INVALID_HANDLE;
new Handle:sm_respawn_count = INVALID_HANDLE;
new Handle:sm_respawn_counterattack = INVALID_HANDLE;
new Handle:sm_always_finale_counterattack = INVALID_HANDLE;
new Handle:sm_respawn_final_counterattack = INVALID_HANDLE;
new Handle:sm_respawn_count_team2 = INVALID_HANDLE;
new Handle:sm_respawn_count_team3 = INVALID_HANDLE;
new Handle:sm_respawn_lives_modifier = INVALID_HANDLE;
new Handle:sm_respawn_type = INVALID_HANDLE;
new Handle:sm_respawn_reset_each_round = INVALID_HANDLE;
new Handle:sm_respawn_reset_each_objective = INVALID_HANDLE;
new Handle:sm_fatal_limb_dmg = INVALID_HANDLE;
new Handle:sm_fatal_head_dmg = INVALID_HANDLE;
new Handle:sm_fatal_burn_dmg = INVALID_HANDLE;
new Handle:sm_fatal_explosive_dmg = INVALID_HANDLE;
new Handle:sm_fatal_chest_stomach = INVALID_HANDLE;
new Handle:sm_fatal_chance = INVALID_HANDLE;
new Handle:sm_fatal_head_chance = INVALID_HANDLE;
new Handle:sm_nav_mesh_spawning = INVALID_HANDLE;
new Handle:sm_spawn_security_on_counter = INVALID_HANDLE;
new Handle:sm_enable_track_ammo = INVALID_HANDLE;
new Handle:sm_min_counter_dur_sec = INVALID_HANDLE;
new Handle:sm_max_counter_dur_sec = INVALID_HANDLE;
new Handle:sm_counter_chance = INVALID_HANDLE;
new Handle:sm_reinforce_multiplier = INVALID_HANDLE;
new Handle:sm_reinforce_time = INVALID_HANDLE;
new Handle:sm_reinforce_time_subsequent = INVALID_HANDLE;
new Handle:sm_check_static_enemy = INVALID_HANDLE;
//new Handle:sm_temp_map_fix = INVALID_HANDLE;



//Medic specific
new Handle:sm_revive_seconds = INVALID_HANDLE;
new Handle:sm_revive_health = INVALID_HANDLE;
new Handle:sm_heal_amount = INVALID_HANDLE;
new String:g_client_last_classstring[MAXPLAYERS+1][64];


//NAV MESH SPECIFIC CVARS
new Handle:cvarSpawnMode = INVALID_HANDLE; //Spawn in hiding spots (1), any spawnpoints that meets criteria (2), or only at normal spawnpoints at next objective (0, standard spawning, default setting)
new Handle:cvarMinCounterattackDistance = INVALID_HANDLE; //Min distance from counterattack objective to spawn
new Handle:cvarMinPlayerDistance = INVALID_HANDLE; //Min/max distance from players to spawn
new Handle:cvarMaxPlayerDistance = INVALID_HANDLE; //Min/max distance from players to spawn
//new Float:g_vecOrigin[MAXPLAYERS+1][3];

new g_checkStaticAmt, g_isConquer, g_isCheckpoint, g_isHunt, g_always_counter, g_reinforceTime, g_iSpawnMode, g_team_lives_2, g_team_lives_3, g_team_lives_3_total, g_team_lives_2_total, g_teams_spawned_bool, g_respawn_lives_modifier, g_respawn_type, g_respawn_count_team2, g_respawn_count_team3, g_revive_seconds, g_revive_health, g_heal_amount, Float:g_flMinPlayerDistance, Float:g_flMaxPlayerDistance, Float:g_flMinCounterattackDistance;
new Float:g_vecOrigin[MAXPLAYERS+1][3];
new Float:g_fInterval  = 5.0;
enum SpawnModes {
        SpawnMode_Normal = 0,
	SpawnMode_HidingSpots,
	SpawnMode_SpawnPoints,
};
//Kill Stray Enemy Bots Globals
new Float:g_enemyTimerPos[MAXPLAYERS+1][3];
new Float:g_enemyPos[MAXPLAYERS+1][3];

new g_iSpawnTokens[MAXPLAYERS+1];
new g_hurtFatal[MAXPLAYERS+1];
new Float:g_iDeadVectors[MAXPLAYERS+1][3];
new Float:g_iDeadRagdollVectors[MAXPLAYERS+1][3];
new g_ClientRagdolls[MAXPLAYERS+1];
new g_iRespawnCount[4];
new Float:g_SecurityCounterSpawn[3];

public OnPluginStart()
{
	decl String:gamemod[40];
	GetGameFolderName(gamemod, sizeof(gamemod));
	
	if(StrEqual(gamemod, "tf"))
	{
		TF2 = true;
	}
	//Nav Mesh Botspawn specific START
	cvarSpawnMode = CreateConVar("sm_botspawns_spawn_mode", "1", "Only normal spawnpoints at the objective, the old way (0), spawn in hiding spots following rules (1), spawnpoints that meet rules (2)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarMinCounterattackDistance = CreateConVar("sm_botspawns_min_counterattack_distance", "800.0", "Min distance from counterattack objective to spawn", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarMinPlayerDistance = CreateConVar("sm_botspawns_min_player_distance", "800.0", "Min distance from players to spawn", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarMaxPlayerDistance = CreateConVar("sm_botspawns_max_player_distance", "1000.0", "Max distance from players to spawn", FCVAR_NOTIFY | FCVAR_PLUGIN);

	//Nav Mesh Botspawn specific END

	CreateConVar("sm_respawn_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	sm_respawn_enabled = CreateConVar("sm_respawn_enabled", "1", "Automatically respawn players when they die; 0 - disabled, 1 - enabled");
	sm_respawn_delay = CreateConVar("sm_respawn_delay", "1.0", "How many seconds to delay the respawn");
	sm_respawn_counterattack = CreateConVar("sm_respawn_counterattack", "2", "Respawn during counterattack? (0: no, 1: yes, 2: infinite)");
	sm_respawn_final_counterattack = CreateConVar("sm_respawn_final_counterattack", "2", "Respawn during final counterattack? (0: no, 1: yes, 2: infinite)");
	sm_respawn_count = CreateConVar("sm_respawn_count", "0", "Respawn all players this many times");
	sm_respawn_count_team2 = CreateConVar("sm_respawn_count_team2", "-1", "Respawn all Team 2 players this many times");
	sm_respawn_count_team3 = CreateConVar("sm_respawn_count_team3", "-1", "Respawn all Team 3 players this many times");
	sm_respawn_reset_each_round = CreateConVar("sm_respawn_reset_each_round", "1", "Reset player respawn counts each round");
	sm_respawn_reset_each_objective = CreateConVar("sm_respawn_reset_each_objective", "1", "Reset player respawn counts each objective");
	sm_respawn_type = CreateConVar("sm_respawn_type", "2", "1 - individual lives, 2 - each team gets a pool of lives used by everyone, respawn_count_team2/3 must be > 0");
	sm_respawn_lives_modifier = CreateConVar("sm_respawn_lives_modifier", "3", "sm_respawn_type must be 2:  Depending on how many enemies alive times the modifier. 10 Bots = 10 * 2 = 20 team pool lives");
	sm_fatal_limb_dmg = CreateConVar("sm_fatal_limb_dmg", "80", "Amount of damage to fatally kill player in limb");
	sm_fatal_head_dmg = CreateConVar("sm_fatal_head_dmg", "100", "Amount of damage to fatally kill player in head");
	sm_fatal_burn_dmg = CreateConVar("sm_fatal_burn_dmg", "50", "Amount of damage to fatally kill player in burn");
	sm_fatal_explosive_dmg = CreateConVar("sm_fatal_explosive_dmg", "200", "Amount of damage to fatally kill player in explosive");
	sm_fatal_chest_stomach = CreateConVar("sm_fatal_chest_stomach", "100", "Amount of damage to fatally kill player in chest/stomach");
	sm_nav_mesh_spawning = CreateConVar("sm_nav_mesh_spawning", "1", "Attempt to spawn on nav_mesh if player in range of original spawn");
	sm_fatal_chance = CreateConVar("sm_fatal_chance", "0.6", "Chance for a kill to be fatal, 0.6 default = 60% chance to be fatal");
	sm_fatal_head_chance = CreateConVar("sm_fatal_head_chance", "0.7", "Chance for a headshot kill to be fatal, 0.6 default = 60% chance to be fatal");
	sm_spawn_security_on_counter = CreateConVar("sm_spawn_security_on_counter", "1", "0/1 When a counter attack starts, spawn all dead players and teleport them to point to defend");
	sm_enable_track_ammo = CreateConVar("sm_enable_track_ammo", "1", "0/1 Track ammo on death to revive (may be buggy if using a different theatre that modifies ammo)");
	sm_min_counter_dur_sec = CreateConVar("sm_min_counter_dur_sec", "66", "Minimum randomized counter attack duration");
	sm_max_counter_dur_sec = CreateConVar("sm_max_counter_dur_sec", "126", "Maximum randomized counter attack duration");
	sm_counter_chance = CreateConVar("sm_counter_chance", "0.5", "Percent chance that a counter attack will happen def: 50%");
	sm_reinforce_multiplier = CreateConVar("sm_reinforce_multiplier", "4", "Division multiplier to determine when to start reinforce timer for bots based on team pool lives left over");
	sm_reinforce_time = CreateConVar("sm_reinforce_time", "200", "When enemy forces are low on lives, how much time til they get reinforcements?");
	sm_reinforce_time_subsequent = CreateConVar("sm_reinforce_time_subsequent", "140", "When enemy forces are low on lives and already reinforced, how much time til they get reinforcements on subsequent reinforcement?");
	sm_check_static_enemy = CreateConVar("sm_check_static_enemy", "120.0", "Seconds amount to check if an AI has moved probably stuck");
	
	//sm_temp_map_fix = CreateConVar("sm_temp_map_fix", "embassy_coop", "Current starting map to fix model bug");
	

	//Daimyo Medic Revive
	sm_revive_seconds = CreateConVar("sm_revive_seconds", "5", "Time in seconds medic needs to stand over body to revive");
	sm_revive_health = CreateConVar("sm_revive_health", "50", "Health restored when revived");
	sm_heal_amount = CreateConVar("sm_heal_amount", "25", "Heal amount per X seconds");
	

	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);

	HookEvent("player_pick_squad", Event_PlayerPickSquad);
	HookEvent("player_spawn", Event_PlayerSpawn);
	//HookEvent("controlpoint_neutralized", Event_ControlPointNeutralized);
	HookEvent("object_destroyed", Event_ObjectDestroyed);
	HookEvent("controlpoint_captured", Event_ControlPointCaptured_Pre, EventHookMode_Pre);
	HookEvent("controlpoint_captured", Event_ControlPointCaptured);
	HookEvent("controlpoint_captured", Event_ControlPointCaptured_Post, EventHookMode_Post);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_connect", Event_PlayerConnect);
	///NavMesh Botspawn Specific Start
	HookConVarChange(cvarSpawnMode,CvarChange);
	HookConVarChange(cvarMinPlayerDistance,CvarChange);
	HookConVarChange(cvarMaxPlayerDistance,CvarChange);
	//NavMesh Botspawn Specific End
	HookConVarChange(sm_revive_seconds, UpdateRespawnCountConVar);
	HookConVarChange(sm_revive_health, UpdateRespawnCountConVar);
	HookConVarChange(sm_heal_amount, UpdateRespawnCountConVar);

	HookConVarChange(sm_respawn_enabled, EnableChanged);
	HookConVarChange(sm_respawn_count, UpdateRespawnCountConVar);
	HookConVarChange(sm_respawn_count_team2, UpdateRespawnCountConVar);
	HookConVarChange(sm_respawn_count_team3, UpdateRespawnCountConVar);
	HookConVarChange(sm_respawn_reset_each_round, UpdateRespawnCountConVar);
	HookConVarChange(sm_respawn_reset_each_objective, UpdateRespawnCountConVar);
	HookConVarChange(sm_respawn_type, UpdateRespawnCountConVar);
	HookConVarChange(sm_respawn_lives_modifier, UpdateRespawnCountConVar);
	
	HookConVarChange(FindConVar("sv_tags"), TagsChanged);
	UpdateCvars();


	decl String:game[40];
	GetGameFolderName(game, sizeof(game));
	if ((StrEqual(game, "dod")) || StrEqual(game, "insurgency"))
	{
		// Next 14 lines of text are taken from Andersso's DoDs respawn plugin. Thanks :)
		g_hGameConfig = LoadGameConfigFile("insurgency.games");

		if (g_hGameConfig == INVALID_HANDLE)
		{
			SetFailState("Fatal Error: Missing File \"insurgency.games\"!");
		}

		StartPrepSDKCall(SDKCall_Player);
		if (StrEqual(game, "dod"))
		{
			PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Signature, "DODRespawn");
		}
		if (StrEqual(game, "insurgency"))
		{
			PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Signature, "ForceRespawn");
		}
		g_hPlayerRespawn = EndPrepSDKCall();

		if (g_hPlayerRespawn == INVALID_HANDLE)
		{
			SetFailState("Fatal Error: Unable to find signature for \"Respawn\"!");
		}
	}

	LoadTranslations("common.phrases");
	LoadTranslations("respawn.phrases");
	LoadTranslations("nearest_player.phrases.txt");
	AutoExecConfig(true, "respawn");

	//decl String:temp_map[256];
	//GetConVarString(sm_temp_map_fix, temp_map, sizeof(temp_map));
	//ForceChangeLevel(temp_map, "Fix Workshop By Changing Map");
	//CreateTimer(1.0, Timer_ReviveLoop, _, TIMER_REPEAT);
	
	//CreateTimer(2.0, Timer_MedicMonitor,_ , TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public CvarChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	UpdateCvars();
}

public UpdateCvars()
{
	g_revive_seconds = GetConVarInt(sm_revive_seconds);
	g_revive_health = GetConVarInt(sm_revive_health);
	g_heal_amount = GetConVarInt(sm_heal_amount);
	
	g_iSpawnMode = GetConVarInt(cvarSpawnMode);
	g_flMinCounterattackDistance = GetConVarFloat(cvarMinCounterattackDistance);
	g_flMinPlayerDistance = GetConVarFloat(cvarMinPlayerDistance);
	g_flMaxPlayerDistance = GetConVarFloat(cvarMaxPlayerDistance);
	

}

public OnMapStart()
{	
	g_isConquer = 0;
	decl String:sGameMode[32];
	GetConVarString(FindConVar("mp_gamemode"), sGameMode, sizeof(sGameMode));
	if (StrEqual(sGameMode,"conquer")) // if Hunt?
	{
		g_isConquer = 1;
		new fatalChance = FindConVar("sm_fatal_chance");
		new headFatalChance = FindConVar("sm_fatal_head_chance");
	   	SetConVarInt(fatalChance, 0.3, true, true);
	   	SetConVarInt(headFatalChance, 0.4, true, true);
	}
	if (StrEqual(sGameMode,"checkpoint")) // if Hunt?
	{
		//g_isConquer = 1;
	}
	new reinforce_time = GetConVarInt(sm_reinforce_time);
	g_reinforceTime = reinforce_time;
	UpdateRespawnCount();

	g_EnableRevive = 0;
	//BotSpawn Nav Mesh initialize #################### END
	SetPlayerSpawns();

	CreateTimer(0.2, checkPlayers, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE); //Needs more than 2 people to test
	
	if (GetConVarInt(sm_enable_track_ammo) == 1)
		CreateTimer(1.0, Timer_GearMonitor,_ , TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	if (g_isConquer != 1) 
		CreateTimer(1.0, Timer_EnemyReinforce,_ , TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	if (g_isConquer != 1) 
		CreateTimer(30.0, Enemies_Remaining,_ , TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	CreateTimer(1.0, Timer_PlayerStatus,_ , TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	//CreateTimer(5.0, Timer_CheckEnemyStacks,_ , TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	g_checkStaticAmt = GetConVarFloat(sm_check_static_enemy);
	CreateTimer(g_checkStaticAmt, Timer_CheckEnemyStatic,_ , TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	//CreateTimer(1.0, Timer_PlayerTimeout,_ , TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	//########### NOTHING BELOW THIS, IF THIS CODE CRASHES, NOTHING UNDER RUNS #######
	if (g_hHidingSpots == INVALID_HANDLE) 
		g_hHidingSpots = NavMesh_GetHidingSpots();//try NavMesh_GetAreas(); or //NavMesh_GetPlaces(); // or NavMesh_GetEncounterPaths();
		g_iHidingSpotCount = GetArraySize(g_hHidingSpots);

	m_iNumControlPoints = Ins_ObjectiveResource_GetProp("m_iNumControlPoints");
	//PrintToServer("[BOTSPAWNS] m_iNumControlPoints %d",m_iNumControlPoints);
	for (new i = 0; i < m_iNumControlPoints; i++)
	{
		Ins_ObjectiveResource_GetPropVector("m_vCPPositions",m_vCPPositions[i],i);
		//PrintToServer("[BOTSPAWNS] i %d (%f,%f,%f)",i,m_vCPPositions[i][0],m_vCPPositions[i][1],m_vCPPositions[i][2]);
	}
	for (new iCP = 0; iCP < m_iNumControlPoints; iCP++)
	{
		g_iCPLastHidingSpot[iCP] = 0;
	}
	if (g_iHidingSpotCount)
	{
		for (new iIndex = 0, iSize = g_iHidingSpotCount; iIndex < iSize; iIndex++)
		{
			new Float:flHidingSpot[3];//, iHidingSpotFlags;
			flHidingSpot[0] = GetArrayCell(g_hHidingSpots, iIndex, NavMeshHidingSpot_X);
			flHidingSpot[1] = GetArrayCell(g_hHidingSpots, iIndex, NavMeshHidingSpot_Y);
			flHidingSpot[2] = GetArrayCell(g_hHidingSpots, iIndex, NavMeshHidingSpot_Z);
			new Float:dist,Float:closest = -1.0,pointidx=-1;
			for (new i = 0; i < m_iNumControlPoints; i++)
			{
				dist = GetVectorDistance(flHidingSpot,m_vCPPositions[i]);
				if ((dist < closest) || (closest == -1.0))
				{
					closest = dist;
					pointidx = i;
				}
			}
			if (pointidx > -1)
			{
				g_iCPHidingSpots[pointidx][g_iCPHidingSpotCount[pointidx]] = iIndex;
				g_iCPHidingSpotCount[pointidx]++;
			}
		}
		//PrintToServer("[BOTSPAWNS] Found hiding count: a %d b %d c %d d %d e %d f %d g %d h %d i %d j %d k %d l %d m %d",g_iCPHidingSpotCount[0],g_iCPHidingSpotCount[1],g_iCPHidingSpotCount[2],g_iCPHidingSpotCount[3],g_iCPHidingSpotCount[4],g_iCPHidingSpotCount[5],g_iCPHidingSpotCount[6],g_iCPHidingSpotCount[7],g_iCPHidingSpotCount[8],g_iCPHidingSpotCount[9],g_iCPHidingSpotCount[10],g_iCPHidingSpotCount[11],g_iCPHidingSpotCount[12]);
	}
	//PrintToServer("[REVIVE_DEBUG] MAP STARTED");	
	//##########NOTHING BELOW THIS POINT##########
}
public OnMapEnd()
{
	//PrintToServer("[REVIVE_DEBUG] MAP ENDED");	
	SetPlayerSpawns();
}

/*
public OnGameFrame()
{
	static Float:player_time[MAXPLAYERS+1];
	static i;
	for (i = 1; i < MaxClients; i++)
	{
	    if (i > 0 && IsClientInGame(i) && !IsFakeClient(i))
	    {
	        if (IsClientTimingOut(i))
	        {
	            if (player_time[i])
	            {
	                // timed out
	                if ((GetGameTime() - player_time[i]) >= g_fInterval)
	                {
	                    KickClient(i, "%N crashed from server!", i);
	                    player_time[i] = 0.0;
	                    //PrintToServer("Kicking timed out player: %N ", i);
	                    LogToGame("Kicking timed out player: %N ", i);
	                }
	            }
	            else
	            {
	                player_time[i] = GetGameTime();
	            }
	        }
	        else if (player_time[i])
	        {
	            player_time[i] = 0.0;
	        }
	    }
	}
}  
*/

public Action:Timer_PlayerStatus(Handle:Timer)
{

    for (new client = 1; client <= MaxClients; client++)
    {
    	if (client > 0 && IsClientInGame(client) && IsValidClient(client) && !IsFakeClient(client) && playerPickSquad[client] == 1)
    	{
    		new team = GetClientTeam(client);
	        if (!IsPlayerAlive(client) && !IsClientTimingOut(client) && IsClientObserver(client) && team == TEAM_1 && g_EnableRevive == 1 && g_RoundStatus == 1 && playerFirstJoin[client] == false) //
	        {
	        	
	            if (g_hurtFatal[client] == -1)
	            {
	            		PrintCenterText(client, "You changed your role in the squad. You can no longer be revived and must wait til next respawn!");
	            }
	            else if (g_hurtFatal[client] == 1)
	            {       
	            		decl String:fatal_hint[64];
	            		Format(fatal_hint, 255,"You were fatally killed for %i damage", g_clientDamageDone[client]);
						PrintCenterText(client, "%s", fatal_hint);
	            }
	            else if (g_hurtFatal[client] == 0 && !Ins_InCounterAttack())
	            {
	            		//decl String:wounded_hint[64];
	            		//Format(wounded_hint, 255,"You were wounded for %i damage", g_clientDamageDone[client]);
						PrintCenterText(client, "[You are WOUNDED]..wait patiently for a medic..do NOT mic/chat spam!");
	            }
	            else if (g_hurtFatal[client] == 0 && Ins_InCounterAttack())
	            {
	            	//decl String:wounded_hint[64];
	        		//Format(wounded_hint, 255,"You were wounded for %i damage", g_clientDamageDone[client]);
					PrintCenterText(client, "You are WOUNDED during a Counter-Attack..if its close to ending..dont bother asking for a medic!");
	            }
	        }
    	}
    }
}
public Action:Enemies_Remaining(Handle:Timer)
{
		new alive_insurgents;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && IsFakeClient(i))
			{
				alive_insurgents++;
			}
		}
		decl String:textToPrintChat[64];
		decl String:textToPrint[64];
		Format(textToPrintChat, sizeof(textToPrintChat), "Enemies alive: %d | Enemy reinforcements remaining: %d", alive_insurgents, g_team_lives_3);
		Format(textToPrint, sizeof(textToPrint), "Enemies alive: %d | Enemy reinforcements remaining: %d", alive_insurgents ,g_team_lives_3);
		PrintHintTextToAll(textToPrint);
		PrintToChatAll(textToPrintChat);
}
//this timer reinforces bot team if you do not capture point
public Action:Timer_EnemyReinforce(Handle:Timer)
{
	
	new reinforce_multiplier = GetConVarInt(sm_reinforce_multiplier);
	new reinforce_time = GetConVarInt(sm_reinforce_time);
	new reinforce_time_subsequent = GetConVarInt(sm_reinforce_time_subsequent);

	if (g_team_lives_3 <= (g_team_lives_3_total / reinforce_multiplier))
	{
		g_reinforceTime = g_reinforceTime - 1;
		if (g_reinforceTime % 10 == 0 && g_reinforceTime > 10)
		{
			decl String:textToPrintChat[64];
			decl String:textToPrint[64];
			Format(textToPrintChat, sizeof(textToPrintChat), "Friendlies spawn on Counter-Attacks, Capture the Point!");
			Format(textToPrint, sizeof(textToPrint), "Enemies reinforce in %d seconds | Capture the point soon!", g_reinforceTime);
			PrintHintTextToAll(textToPrint);
			PrintToChatAll(textToPrintChat);
		}
		if (g_reinforceTime <= 10)
		{
			decl String:textToPrintChat[64];
			decl String:textToPrint[64];
			Format(textToPrintChat, sizeof(textToPrintChat), "Friendlies spawn on Counter-Attacks, Capture the Point!");
			Format(textToPrint, sizeof(textToPrint), "Enemies reinforce in %d seconds | Capture the point soon!", g_reinforceTime);
			PrintHintTextToAll(textToPrint);
			PrintToChatAll(textToPrintChat);
		}
		if (g_reinforceTime <= 0)
		{
			if (g_team_lives_3 > 0)
			{
				g_team_lives_3 = (g_team_lives_3_total / reinforce_multiplier);
				decl String:textToPrint[64];
	        	Format(textToPrint, sizeof(textToPrint), "Enemy Reinforcements Added to Existing Reinforcements!");
				PrintHintTextToAll(textToPrint);
				g_reinforceTime = reinforce_time_subsequent;
			}
			else
			{
				for (new client = 1; client <= MaxClients; client++)
			    {
			    	if (client > 0 && IsClientInGame(client))
			    	{
			    		new m_iTeam = GetClientTeam(client);
				    	//new botTeamCount = Team_CountAlivePlayers(m_iTeam);
				        if (IsFakeClient(client) && !IsPlayerAlive(client) && m_iTeam == TEAM_2)
				        {
				        	g_reinforceTime = reinforce_time_subsequent;
				            CreateRespawnTimer(client);

				        }
			    	}
				}
		    	decl String:textToPrint[64];
        		Format(textToPrint, sizeof(textToPrint), "Enemy Reinforcements Have Arrived!");
				PrintHintTextToAll(textToPrint);
		    }
		    
		    
		}
	    
	}
    
}
public Action:Timer_CheckEnemyStacks(Handle:Timer)
{
	for (new enemyBot = 1; enemyBot <= MaxClients; enemyBot++)
	{	

		new m_iTeam = GetClientTeam(enemyBot);
		//new botTeamCount = Team_CountAlivePlayers(m_iTeam);
		if (IsFakeClient(enemyBot) && IsPlayerAlive(enemyBot) && m_iTeam == TEAM_2)
		{
			// decl Float:enemyPos[3];
			// GetClientAbsOrigin(enemyBot, Float:enemyPos);
			// g_enemyPos[enemyBot] = enemyPos;
			new bool:isBotStuck = false;
			isBotStuck = CheckIfPlayerIsStuck(enemyBot);
			if (isBotStuck == true)
			{
				PrintToServer("ENEMY STUCK - KILLING");
				ForcePlayerSuicide(enemyBot);
			}
		}
	}
}

// Check if a player(or bot) is stuck (credits to VEN) 
stock bool:CheckIfPlayerIsStuck(iClient)
{
	decl Float:vecMin[3], Float:vecMax[3], Float:vecOrigin[3];
	
	GetClientMins(iClient, vecMin);
	GetClientMaxs(iClient, vecMax);
	GetClientAbsOrigin(iClient, vecOrigin);
	
	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_SOLID, TraceEntityFilterSolid);
	return TR_DidHit();	// head in wall ?
}


public bool:TraceEntityFilterSolid(entity, contentsMask) 
{
	return entity > 1;
}

public Action:Timer_CheckEnemyStatic(Handle:Timer)
{
	for (new enemyBot = 1; enemyBot <= MaxClients; enemyBot++)
	{	
		if (IsClientInGame(enemyBot) && IsFakeClient(enemyBot))
		{
			new m_iTeam = GetClientTeam(enemyBot);
			//new botTeamCount = Team_CountAlivePlayers(m_iTeam);
			if (IsPlayerAlive(enemyBot) && m_iTeam == TEAM_2)
			{
				decl Float:enemyPos[3];
				GetClientAbsOrigin(enemyBot, Float:enemyPos);
				new Float:tDistance;
				tDistance = GetVectorDistance(enemyPos,g_enemyTimerPos[enemyBot]);
				if (tDistance <= 1) 
				{
					PrintToServer("ENEMY STATIC - KILLING");
					ForcePlayerSuicide(enemyBot);
				}
				else
				{
					g_enemyTimerPos[enemyBot] = enemyPos;
				}
				
			}
		}
	}
}
public Action:Timer_GearMonitor(Handle:Timer)
{

    for (new client = 1; client <= MaxClients; client++)
    {
        if (client > 0 && IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client) && !IsClientObserver(client))
        {

            if (g_EnableRevive == 1 && g_RoundStatus == 1 && GetConVarInt(sm_enable_track_ammo) == 1)
            {       
            	GetPlayerAmmo(client);
            }
        }
    }
}
public Action:Timer_MedicMonitor(Handle:Timer)
{
	//PrintToServer("[MEDIC_DEBUG] MONITORING MEDIC");	
    for (new medic = 1; medic <= MaxClients; medic++)
	{
		if (IsClientInGame(medic) && !IsFakeClient(medic))
		{
			
		}
	}
}

SetPlayerAmmo(client)
{
	if (IsClientInGame(client) && IsValidClient(client) && !IsFakeClient(client))
	{


		//PrintToServer("SETWEAPON ########");
			new primaryWeapon = GetPlayerWeaponSlot(client, 0);
			new secondaryWeapon = GetPlayerWeaponSlot(client, 1);
			new playerGrenades = GetPlayerWeaponSlot(client, 3);
			//Lets get weapon classname, we need this to create weapon entity if primary does not fit secondary
			//Make sure IsValidEntity is not only for entities
			//decl String:weaponClassname[32];
			// if (secondaryWeapon != playerSecondary[client] && playerSecondary[client] != -1 && IsValidEntity(playerSecondary[client]))
			// {
			// 	GetEdictClassname(playerSecondary[client], weaponClassname, sizeof(weaponClassname));
			// 	RemovePlayerItem(client,secondaryWeapon);
			// 	AcceptEntityInput(secondaryWeapon, "kill");
			// 	GivePlayerItem(client, weaponClassname);
			// 	secondaryWeapon = playerSecondary[client];
			// }
			// if (primaryWeapon != playerPrimary[client] && playerPrimary[client] != -1 && IsValidEntity(playerPrimary[client]))
			// {
			// 	GetEdictClassname(playerPrimary[client], weaponClassname, sizeof(weaponClassname));
			// 	RemovePlayerItem(client,primaryWeapon);
			// 	AcceptEntityInput(primaryWeapon, "kill");
			// 	GivePlayerItem(client, weaponClassname);
			// 	EquipPlayerWeapon(client, playerPrimary[client]); 
			// 	primaryWeapon = playerPrimary[client];
			// }
			if (primaryWeapon != -1 && IsValidEntity(primaryWeapon))
			{
				//PrintToServer("PlayerClip %i, playerAmmo %i, PrimaryWeapon %d",playerClip[client][0],playerAmmo[client][0], primaryWeapon); 
				SetPrimaryAmmo(client, primaryWeapon, playerClip[client][0], 0); //primary clip
				//SetWeaponAmmo(client, primaryWeapon, playerAmmo[client][0], 0); //primary
				//PrintToServer("SETWEAPON 1");
			}
			if (secondaryWeapon != -1 && IsValidEntity(secondaryWeapon))
		    {
		    	//PrintToServer("PlayerClip %i, playerAmmo %i, PrimaryWeapon %d",playerClip[client][1],playerAmmo[client][1], primaryWeapon); 
		    	SetPrimaryAmmo(client, secondaryWeapon, playerClip[client][1], 1); //secondary clip
		    	//SetWeaponAmmo(client, secondaryWeapon, playerAmmo[client][1], 1); //secondary
		    	//PrintToServer("SETWEAPON 2");
		    }	 
			if (playerGrenades != -1 && IsValidEntity(playerGrenades)) // We need to figure out what slots are defined#define Slot_HEgrenade 11, #define Slot_Flashbang 12, #define Slot_Smokegrenade 13
			{
				while (playerGrenades != -1 && IsValidEntity(playerGrenades)) // since we only have 3 slots in current theater
				{
					playerGrenades = GetPlayerWeaponSlot(client, 3);
					if (playerGrenades != -1 && IsValidEntity(playerGrenades)) // We need to figure out what slots are defined#define Slot_HEgrenade 11, #define Slot_Flashbang 12, #define Slot_Smokegrenade 13
					{
						// Remove grenades but not pistols
						decl String:weapon[32];
						GetEntityClassname(playerGrenades, weapon, sizeof(weapon));
						if (!(StrEqual(weapon, "weapon_m93r", false) && 
							StrEqual(weapon, "weapon_m9", false) && 
							StrEqual(weapon, "weapon_m45", false) && 
							StrEqual(weapon, "weapon_makarov", false) && 
							StrEqual(weapon, "weapon_m1911", false)))
						{
							RemovePlayerItem(client,playerGrenades);
							AcceptEntityInput(playerGrenades, "kill");
						}
					}
				}
				
				/*
				If we need to track grenades (since they drop them on death, its a no)
				SetGrenadeAmmo(client, Gren_M67, playerGrenadeType[client][0]);
				SetGrenadeAmmo(client, Gren_Incen, playerGrenadeType[client][1]);
				SetGrenadeAmmo(client, Gren_Molot, playerGrenadeType[client][2]);
				SetGrenadeAmmo(client, Gren_M18, playerGrenadeType[client][3]);
				SetGrenadeAmmo(client, Gren_Flash, playerGrenadeType[client][4]);
				SetGrenadeAmmo(client, Gren_F1, playerGrenadeType[client][5]);
				SetGrenadeAmmo(client, Gren_IED, playerGrenadeType[client][6]);
				SetGrenadeAmmo(client, Gren_C4, playerGrenadeType[client][7]);
				SetGrenadeAmmo(client, Gren_AT4, playerGrenadeType[client][8]);
				SetGrenadeAmmo(client, Gren_RPG7, playerGrenadeType[client][9]);
				*/
				 //PrintToServer("SETWEAPON 3");
			}
			if (!IsFakeClient(client))
				playerRevived[client] = false;
	}
}
GetPlayerAmmo(client)
{
	if (IsClientInGame(client) && IsValidClient(client) && !IsFakeClient(client))
	{
		
		//CONSIDER IF PLAYER CHOOSES DIFFERENT CLASS
		new primaryWeapon = GetPlayerWeaponSlot(client, 0);
		new secondaryWeapon = GetPlayerWeaponSlot(client, 1);
		new playerGrenades = GetPlayerWeaponSlot(client, 3);

		playerPrimary[client] = primaryWeapon;
		playerSecondary[client] = secondaryWeapon;
		//Get ammo left in clips for primary and secondary
		playerClip[client][0] = GetPrimaryAmmo(client, primaryWeapon, 0);
		playerClip[client][1] = GetPrimaryAmmo(client, secondaryWeapon, 1); // m_iClip2 for secondary if this doesnt work? would need GetSecondaryAmmo
		//Get Magazines left on player
		if (primaryWeapon != -1 && IsValidEntity(primaryWeapon))
		    playerAmmo[client][0] = GetWeaponAmmo(client, primaryWeapon, 0); //primary
		if (secondaryWeapon != -1 && IsValidEntity(secondaryWeapon))
		    playerAmmo[client][1] = GetWeaponAmmo(client, secondaryWeapon, 1); //secondary    
		/*
		if (playerGrenades != -1 && IsValidEntity(playerGrenades))
		{
			 //PrintToServer("[GEAR] CLIENT HAS VALID GRENADES");
			 playerGrenadeType[client][0] = GetGrenadeAmmo(client, Gren_M67);
			 playerGrenadeType[client][1] = GetGrenadeAmmo(client, Gren_Incen);
			 playerGrenadeType[client][2] = GetGrenadeAmmo(client, Gren_Molot);
			 playerGrenadeType[client][3] = GetGrenadeAmmo(client, Gren_M18);
			 playerGrenadeType[client][4] = GetGrenadeAmmo(client, Gren_Flash);
			 playerGrenadeType[client][5] = GetGrenadeAmmo(client, Gren_F1);
			 playerGrenadeType[client][6] = GetGrenadeAmmo(client, Gren_IED);
			 playerGrenadeType[client][7] = GetGrenadeAmmo(client, Gren_C4);
			 playerGrenadeType[client][8] = GetGrenadeAmmo(client, Gren_AT4);
			 playerGrenadeType[client][9] = GetGrenadeAmmo(client, Gren_RPG7);
		}
		*/
		////PrintToServer("G: %i, G: %i, G: %i, G: %i, G: %i, G: %i, G: %i, G: %i, G: %i, G: %i",playerGrenadeType[client][0], playerGrenadeType[client][1], playerGrenadeType[client][2],playerGrenadeType[client][3],playerGrenadeType[client][4],playerGrenadeType[client][5],playerGrenadeType[client][6],playerGrenadeType[client][7],playerGrenadeType[client][8],playerGrenadeType[client][9]); 
	}
}

public Action:Timer_RevivePeriod(Handle:Timer, Handle:revivePack)
{
	new client;
	new clientRagdoll;
	new Float:ragPos[3];
	ResetPack(revivePack);
	client = ReadPackCell(revivePack);
	clientRagdoll = ReadPackCell(revivePack);
    //client is our victim and we are running through all medics to see whos nearby

    if (client > 0 && IsClientConnected(client) && IsClientInGame(client))
    {
	    for (new medic = 1; medic <= MaxClients; medic++)
		{
			if (medic > 0 && IsClientInGame(medic) && !IsFakeClient(medic))
			{
				new m_iTeam = GetClientTeam(client);
				if ((medic != client) && (StrContains(g_client_last_classstring[medic], "medic") > -1) && IsPlayerAlive(medic) && !IsPlayerAlive(client) && m_iTeam == TEAM_1)
				{
					//PrintToServer("[REVIVE_DEBUG] MEDIC %N FOUND",medic);	
					new Float:fReviveDistance = 65.0;
					new Float:vecPos[3];
					new Float:tDistance;
					GetClientAbsOrigin(medic, Float:vecPos);
					clientRagdoll = EntRefToEntIndex(g_ClientRagdolls[client]);
					if(clientRagdoll > 0 && clientRagdoll != INVALID_ENT_REFERENCE && IsValidEdict(clientRagdoll) && IsValidEntity(clientRagdoll))
					{
						
						GetEntPropVector(clientRagdoll, Prop_Send, "m_vecOrigin", ragPos);
						g_iDeadRagdollVectors[client] = ragPos;
						tDistance = GetVectorDistance(ragPos,vecPos);
					}
					else
						return Plugin_Stop;
					
					
					//new Float:tDistance = (GetEntitiesDistance(medic, client)); // get current distance
					//PrintToServer("[REVIVE_DEBUG] Distance from %N to %N is %f",client,medic,tDistance);	
					//new Float:fMedicViewThreshold = 0.75; // if negative, bombers back is turned
					//new Bool:tCanMedicSeeTarget = (ClientViews(medic, g_ClientRagdolls[client], fReviveDistance, fMedicViewThreshold));

					//Jareds pistols only code to verify medic is carrying knife
					new ActiveWeapon = GetEntPropEnt(medic, Prop_Data, "m_hActiveWeapon");
					if (ActiveWeapon < 0)
						continue;
					decl String:sWeapon[32];
					GetEdictClassname(ActiveWeapon, sWeapon, sizeof(sWeapon));
					//PrintToServer("[KNIFE ONLY] CheckWeapon for medic %d named %N ActiveWeapon %d sWeapon %s",medic,medic,ActiveWeapon,sWeapon);
					
					//new nearest = IsMedicClosest(medic); //Closest medic gets the revive. There can only be one
					//(nearest != 0 && nearest == medic) 
					if (tDistance < fReviveDistance && (ClientCanSeeVector(medic, ragPos, fReviveDistance)) && ((StrContains(sWeapon, "weapon_defib") > -1) || (StrContains(sWeapon, "weapon_knife") > -1)))
					{
						g_reviveCounter[client] = g_reviveCounter[client] + 1;
						decl String:hint[40];
						decl String:hint_medic[40];
						decl String:revive_to_all[40];
						new tSecondsRemaining = g_revive_seconds - g_reviveCounter[client];
						//PrintToServer("[REVIVE_DEBUG] Distance from %N to %N is %f Seconds %d COUNTER %d",client,medic,tDistance, tSecondsRemaining, g_reviveCounter[client]);		
						
						if (tSecondsRemaining > -1)
						{
							if ((StrContains(g_client_last_classstring[medic], "medic") > -1) && IsPlayerAlive(medic))
							{
								Format(hint_medic, 255,"Reviving %N in: %i seconds", client, tSecondsRemaining);
								PrintHintText(medic, "%s", hint_medic);
							}
							
							Format(hint, 255,"Medic %N is reviving you in: %i seconds", medic, tSecondsRemaining);
							PrintHintText(client, "%s", hint);
							
						}
						
						
						if (g_reviveCounter[client] > g_revive_seconds)
						{	
							Format(revive_to_all, 255,"Medic %N revived %N", medic, client);
							PrintToChatAll("%s", revive_to_all);
							Format(hint_medic, 255,"You revived %N", client);
							PrintHintText(medic, "%s", hint_medic);
							Format(hint, 255,"Medic %N revived you", medic);
							PrintHintText(client, "%s", hint);
							g_iDeadRagdollVectors[client] = ragPos;
							g_reviveCounter[client] = 0;
							playerRevived[client] = true;
							//PrintToServer("##########PLAYER REVIVED %s ############", playerRevived[client]);
							CreateReviveTimer(client);
								return Plugin_Stop;
						}
					}
					//Needs a check for all medics not present
					//else // If no medics are nearby, increase revive time
					//{
					//	if (g_reviveCounter[client] > 0)
					//	{
					//		g_reviveCounter[client] = g_reviveCounter[client] - 1;
					//	}
					//	else if (g_reviveCounter[client] < 0) 
					//	{
					//		g_reviveCounter[client] = 0;
					//	}
					//}  
				}
				else if ((medic != client) && !(StrContains(g_client_last_classstring[medic], "medic") > -1) && IsPlayerAlive(medic) && !IsPlayerAlive(client) && m_iTeam == TEAM_1)
				{
					new Float:fReviveDistance = 65.0;
					decl Float:vecPos[3];
					new Float:tDistance;
					GetClientAbsOrigin(medic, Float:vecPos);
					clientRagdoll = EntRefToEntIndex(g_ClientRagdolls[client]);
					if(clientRagdoll != INVALID_ENT_REFERENCE && clientRagdoll > 0 && IsValidEdict(clientRagdoll) && IsValidEntity(clientRagdoll))
					{
						
						GetEntPropVector(clientRagdoll, Prop_Send, "m_vecOrigin", ragPos);
						tDistance = GetVectorDistance(ragPos,vecPos);
					}
					else
						continue;

					if (tDistance < fReviveDistance && (ClientCanSeeVector(medic, ragPos, fReviveDistance)))
					{
						decl String:hint_medic[40];
						Format(hint_medic, 255,"Viewing wounded soldier %N", client);
						PrintHintText(medic, "%s", hint_medic);
					}

				}
			}
		}
	}
	
}
public Action:Timer_Remove(Handle:timer, any:ref) 
{
	new entity = EntRefToEntIndex(ref);
	if(entity != INVALID_ENT_REFERENCE && IsValidEntity(entity))
		AcceptEntityInput(entity, "Kill");

}


RemoveRagdoll(client)
{

	//new ref = EntIndexToEntRef(g_ClientRagdolls[client]);
	new entity = EntRefToEntIndex(g_ClientRagdolls[client]);
	if(entity != INVALID_ENT_REFERENCE && IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
		g_ClientRagdolls[client] = INVALID_ENT_REFERENCE;
	}	
}

/*
	Ammo related stuff:
	CINSPlayer

*/
stock Float:GetEntitiesDistance(ent1, ent2)
{
	new Float:orig1[3];
	GetEntPropVector(ent1, Prop_Send, "m_vecOrigin", orig1);
	
	new Float:orig2[3];
	GetEntPropVector(ent2, Prop_Send, "m_vecOrigin", orig2);

	return GetVectorDistance(orig1, orig2);
} 
/*
#####################################################################
# NAV MESH BOT SPAWNS FUNCTIONS START ###############################
# NAV MESH BOT SPAWNS FUNCTIONS START ###############################
#####################################################################
*/
CheckHidingSpotRules(m_nActivePushPointIndex,iCPHIndex,iSpot,client)
{
	new m_iTeam = GetClientTeam(client);
	new Float:distance,Float:furthest,Float:closest=-1.0,Float:flHidingSpot[3];
	new Float:vecOrigin[3];
	new needSpawn = 0;
	for (new iTarget = 1; iTarget < MaxClients; iTarget++)
	{
		new Float:distance;
		if (!IsValidClient(iTarget))
			continue;
		if (!IsClientInGame(iTarget))
			continue;
		distance = GetVectorDistance(g_vecOrigin[client],g_vecOrigin[iTarget]);
		if (GetClientTeam(iTarget) != m_iTeam && IsPlayerAlive(iTarget))
		{
			if ((distance < g_flMinPlayerDistance))// || ((IsVectorInSightRange(iTarget, flHidingSpot, 120.0, g_flMinPlayerDistance)) && (ClientCanSeeVector(iTarget, flHidingSpot, g_flMinPlayerDistance))))
			{
				PrintToServer("[BOTSPAWNS] ###PRE-SPAWN-CHECK###, Cannot Spawn due to player in DISTANCE/SIGHT");
				needSpawn = 1;
				break;
			}
		}
	}
	if (needSpawn == 1)
	{
		GetClientAbsOrigin(client,vecOrigin);
		flHidingSpot[0] = GetArrayCell(g_hHidingSpots, iSpot, NavMeshHidingSpot_X);
		flHidingSpot[1] = GetArrayCell(g_hHidingSpots, iSpot, NavMeshHidingSpot_Y);
		flHidingSpot[2] = GetArrayCell(g_hHidingSpots, iSpot, NavMeshHidingSpot_Z);
		for (new iTarget = 1; iTarget < MaxClients; iTarget++)
		{
			if (!IsValidClient(iTarget))
				continue;
			if (!IsClientInGame(iTarget))
				continue;
			distance = GetVectorDistance(flHidingSpot,g_vecOrigin[iTarget]);
			//PrintToServer("[BOTSPAWNS] Distance from %N to iSpot %d is %f",iTarget,iSpot,distance);
			if (GetClientTeam(iTarget) != m_iTeam)
			{
				if (distance > furthest)
					furthest = distance;
				if ((distance < closest) || (closest < 0))
					closest = distance;
				if ((distance < g_flMinPlayerDistance))// || ((IsVectorInSightRange(iTarget, flHidingSpot, 120.0, g_flMinPlayerDistance)) && (ClientCanSeeVector(iTarget, flHidingSpot, g_flMinPlayerDistance))))
				{
					PrintToServer("[BOTSPAWNS] Cannot spawn %N at iSpot %d since it is in sight of %N",client,iSpot,iTarget);
					return 0;
				}
			}
			// if (distance < MIN_PLAYER_DISTANCE)
			// {
			// 	PrintToServer("[BOTSPAWNS] Distance too small from %N to iSpot %d distance %f",iTarget,iSpot,distance);
			// 	return 0;
			// }
		}
		if (closest > g_flMaxPlayerDistance)
		{
			PrintToServer("[BOTSPAWNS] iSpot %d is too far from nearest player distance %f",iSpot,closest);
			return 0;
		}
		if (Ins_InCounterAttack())
		{
			distance = GetVectorDistance(flHidingSpot,m_vCPPositions[m_nActivePushPointIndex]);
			if (distance < g_flMinCounterattackDistance)
			{
				PrintToServer("[BOTSPAWNS] iSpot %d is too close counterattack point distance %f",iSpot,distance);
				return 0;
			}
		}
		distance = GetVectorDistance(flHidingSpot,vecOrigin);
		PrintToServer("[BOTSPAWNS] Selected spot for %N, iCPHIndex %d iSpot %d distance %f",client,iCPHIndex,iSpot,distance);
		return 1;
	}
	else
	{
		return 0;
	}
}
GetBestHidingSpot(client,iteration=0)
{
	UpdatePlayerOrigins();
	new m_nActivePushPointIndex = Ins_ObjectiveResource_GetProp("m_nActivePushPointIndex");
//	if (Ins_InCounterAttack())
//		m_nActivePushPointIndex--;

	new minidx = (iteration) ? 0 : g_iCPLastHidingSpot[m_nActivePushPointIndex];
	new maxidx = (iteration) ? g_iCPLastHidingSpot[m_nActivePushPointIndex] : g_iCPHidingSpotCount[m_nActivePushPointIndex];
	for (new iCPHIndex = minidx; iCPHIndex < maxidx; iCPHIndex++)
	{
		new iSpot = g_iCPHidingSpots[m_nActivePushPointIndex][iCPHIndex];
		if (CheckHidingSpotRules(m_nActivePushPointIndex,iCPHIndex,iSpot,client))
		{
			g_iCPLastHidingSpot[m_nActivePushPointIndex] = iCPHIndex;
			return iSpot;
		}
	}
	if (iteration)
		return -1;
	return GetBestHidingSpot(client,1);
}
public UpdatePlayerOrigins()
{
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			GetClientAbsOrigin(i,g_vecOrigin[i]);
		}
	}
}
public Action:Timer_PostCounterSpawn(Handle:timer, any:client)
{
	g_hRespawnTimer[client] = INVALID_HANDLE;
	if (GetConVarInt(sm_enable_track_ammo) == 1)
	{
		SetPlayerAmmo(client);
	}
	//PrintToServer("[REVIVE_DEBUG] called Timer_PostCounterSpawn for client %N (%d)",client,client);
	TeleportEntity(client, g_SecurityCounterSpawn, NULL_VECTOR, NULL_VECTOR);
	
	g_iDeadRagdollVectors[client][0] = INVALID_HANDLE;
	g_iDeadRagdollVectors[client][1] = INVALID_HANDLE;
	g_iDeadRagdollVectors[client][2] = INVALID_HANDLE;
}

public Action:Timer_PostRevive(Handle:timer, any:client)
{
	g_hRespawnTimer[client] = INVALID_HANDLE;
	//PrintToServer("[REVIVE_DEBUG] called Timer_PostRevive for client %N (%d)",client,client);
	TeleportEntity(client, g_iDeadRagdollVectors[client], NULL_VECTOR, NULL_VECTOR);

	g_iDeadRagdollVectors[client][0] = INVALID_HANDLE;
	g_iDeadRagdollVectors[client][1] = INVALID_HANDLE;
	g_iDeadRagdollVectors[client][2] = INVALID_HANDLE;
}

//Handle any work that needs to happen after the client is in the game
public Action:Timer_PostSpawn(Handle:timer, any:client)
{
	g_hRespawnTimer[client] = INVALID_HANDLE;
	//PrintToServer("[BOTSPAWNS] called Timer_PostSpawn for client %N (%d)",client,client);
	//g_iSpawning[client] = 0;
	if ((g_iHidingSpotCount) && !Ins_InCounterAttack() && (g_isConquer != 1) )
	{	
		//PrintToServer("[BOTSPAWNS] HAS g_iHidingSpotCount COUNT");
			
		new Float:flHidingSpot[3],Float:vecOrigin[3];
		new iSpot = GetBestHidingSpot(client);
		PrintToServer("[BOTSPAWNS] FOUND Hiding spot %d",iSpot);
			
		if (iSpot > -1)
		{
			flHidingSpot[0] = GetArrayCell(g_hHidingSpots, iSpot, NavMeshHidingSpot_X);
			flHidingSpot[1] = GetArrayCell(g_hHidingSpots, iSpot, NavMeshHidingSpot_Y);
			flHidingSpot[2] = GetArrayCell(g_hHidingSpots, iSpot, NavMeshHidingSpot_Z);
			GetClientAbsOrigin(client,vecOrigin);
			new Float:distance = GetVectorDistance(flHidingSpot,vecOrigin);

			PrintToServer("[BOTSPAWNS] Teleporting %N to hiding spot %d at %f,%f,%f distance %f",client,iSpot,flHidingSpot[0],flHidingSpot[1],flHidingSpot[2],distance);
			TeleportEntity(client, flHidingSpot, NULL_VECTOR, NULL_VECTOR);
		}
	}

}

/*
#####################################################################
# NAV MESH BOT SPAWNS FUNCTIONS END ###############################
# NAV MESH BOT SPAWNS FUNCTIONS END ###############################
#####################################################################
*/
public OnConfigsExecuted()
{
	if (GetConVarBool(sm_respawn_enabled))
		TagsCheck("respawntimes");
	else
		TagsCheck("respawntimes", true);
}
public OnClientPutInServer(client)
{
	playerFirstJoin[client] = true;
	playerFirstDeath[client] = false;
	playerPickSquad[client] = 0;
	g_hurtFatal[client] = -1;
}
public Action:Event_PlayerConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	playerFirstJoin[client] = true;
	playerFirstDeath[client] = false;
	playerPickSquad[client] = 0;
	g_hurtFatal[client] = -1;
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0 && IsClientInGame(client))
	{


		//Set flags to 0
		playerItems[client][0] = false;
		playerItems[client][1] = false;
		// playerItems[client][2] = false;	
		new playerRag = EntRefToEntIndex(g_ClientRagdolls[client]);
		//remove network ragdoll associated with player
		if(playerRag > 0 && IsValidEdict(playerRag) && IsValidEntity(playerRag))
			RemoveRagdoll(client);


	}
	return Plugin_Continue;
}


public Action:Event_PlayerSpawn( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );

	if(client > 0 && IsClientInGame(client))
	{
		playerFirstJoin[client] = false;
		playerItems[client][0] = true;
		playerItems[client][1] = true;
		// playerItems[client][2] = true;
		new playerRag = EntRefToEntIndex(g_ClientRagdolls[client]);
		if(playerRag > 0 && IsValidEdict(playerRag) && IsValidEntity(playerRag))
			RemoveRagdoll(client);

		
		g_hurtFatal[client] = 0;
	}
	return Plugin_Continue;
}


public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(sm_respawn_reset_each_round))
	{
		SetPlayerSpawns();
	}
	new reinforce_time = GetConVarInt(sm_reinforce_time);
	g_reinforceTime = reinforce_time;
	decl String:sGameMode[32];
	GetConVarString(FindConVar("mp_gamemode"), sGameMode, sizeof(sGameMode));
	if (!StrEqual(sGameMode,"checkpoint")) // if Hunt?
	{
		//PrintToServer("*******NOT CHECKPOINT | SETTING sm_respawn_count_team3 TO 3*******");
		//PrintToServer("*******NOT CHECKPOINT | SETTING sm_respawn_count_team3 TO 3*******");
		//PrintToServer("*******NOT CHECKPOINT | SETTING sm_respawn_count_team3 TO 3*******");
		// SetConVarInt(sm_respawn_count_team3, 6);
		// SetConVarInt(sm_respawn_count_team2, 1);
		// SetConVarFloat(sm_fatal_chance, 0.5);
		// SetConVarFloat(cvarMinCounterattackDistance, 600.0);
		// SetConVarFloat(cvarMinPlayerDistance, 1000.0);
		// SetConVarFloat(cvarMaxPlayerDistance, 1600.0);
	}
	//PrintToServer("[REVIVE_DEBUG] ROUND STARTED");	
	g_EnableRevive = 0;
	h_PreReviveTimer = CreateTimer(15.0, PreReviveTimer);

	
	return Plugin_Continue;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	//PrintToServer("[REVIVE_DEBUG] ROUND ENDED");	
	g_EnableRevive = 0;
	g_RoundStatus = 0;
	
	if (GetConVarInt(sm_respawn_reset_each_round))
	{
		SetPlayerSpawns();
	}
}

public Action:Event_ControlPointCaptured_Pre(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_isConquer != 1) {
		decl String:sGameMode[32];
		GetConVarString(FindConVar("mp_gamemode"), sGameMode, sizeof(sGameMode));

		new ncp = Ins_ObjectiveResource_GetProp("m_iNumControlPoints");
		new acp = Ins_ObjectiveResource_GetProp("m_nActivePushPointIndex");
		new Handle:cvar;
		new Float:fRandom = GetRandomFloat(0.0, 1.0);
		new min_ca_dur = GetConVarInt(sm_min_counter_dur_sec);
		new max_ca_dur = GetConVarInt(sm_max_counter_dur_sec);

		new fRandomInt = GetRandomInt(min_ca_dur, max_ca_dur);
		new Float:ins_ca_chance = GetConVarFloat(sm_counter_chance);
			new Handle:cvar_ca_dur;
			cvar_ca_dur = FindConVar("mp_checkpoint_counterattack_duration");
			SetConVarInt(cvar_ca_dur, fRandomInt, true, true);
			
		if (fRandom < ins_ca_chance && StrEqual(sGameMode,"checkpoint") && ((acp+1) != ncp))
		{
			PrintToServer("COUNTER YES");
			new Handle:cvar;
			cvar = FindConVar("mp_checkpoint_counterattack_disable");
	   		//SetConVarBounds(cvar,ConVarBound_Upper, true, 18.0);
	   		SetConVarInt(cvar, 0, true, true);
		}
		else
		{
			PrintToServer("COUNTER NO");
			new Handle:cvar;
			cvar = FindConVar("mp_checkpoint_counterattack_disable");
	   		//SetConVarBounds(cvar,ConVarBound_Upper, true, 18.0);
	   		SetConVarInt(cvar, 1, true, true);
		}
		
		if (StrEqual(sGameMode,"checkpoint") && ((acp+1) == ncp))
		{
			new Handle:cvar;
			cvar = FindConVar("mp_checkpoint_counterattack_disable");
	   		//SetConVarBounds(cvar,ConVarBound_Upper, true, 18.0);
	   		SetConVarInt(cvar, 0, true, true);
		}
	}

	return Plugin_Continue;
}
public Action:Event_ControlPointCaptured(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_isConquer != 1)  {
		new reinforce_time = GetConVarInt(sm_reinforce_time);
		g_reinforceTime = reinforce_time;
		if (GetConVarInt(sm_respawn_reset_each_round))
		{
			SetPlayerSpawns();
		}
		//PrintToServer("CONTROL POINT CAPTURED");
	}
	return Plugin_Continue;
}
public Action:Event_ControlPointCaptured_Post(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_isConquer != 1) {
		new ncp = Ins_ObjectiveResource_GetProp("m_iNumControlPoints");
		new acp = Ins_ObjectiveResource_GetProp("m_nActivePushPointIndex");
		
		//PrintToServer("CONTROL POINT CAPTURED POST");
		// if (((acp+1) != ncp)) //GetConVarInt(FindConVar("mp_checkpoint_counterattack_disable")) == 1 && 
		// {
			decl String:cappers[256],String:cpname[64];
			GetEventString(event, "cappers", cappers, sizeof(cappers));
			new spawnCount = 0;
			//PrintToServer("CONTROL POINT CAPTURED POST 1");
			new cappersLength = strlen(cappers);
			for (new i = 0 ; i < cappersLength; i++)
			{
				//i = i + spawnCount;
				new clientCapper = cappers[i];
				// if (!IsValidClient(clientCapper) || i >= cappersLength)
				// {
				// 	//PrintToServer("CONTROL POINT CAPTURED POST 2");
				// 	spawnCount = 0;
				// 	break;
				// }
				if(clientCapper > 0 && IsClientInGame(clientCapper) && IsValidClient(clientCapper) && IsPlayerAlive(clientCapper) && !IsFakeClient(clientCapper))
				{
					//PrintToServer("CONTROL POINT CAPTURED POST 3");
					new Float:capperPos[3];
					GetClientAbsOrigin(clientCapper, Float:capperPos);

					g_SecurityCounterSpawn = capperPos;
					
					//spawnCount++;
					break;
				}
			}		
			if (GetConVarInt(sm_spawn_security_on_counter) == 1)
			{
				//PrintToServer("CONTROL POINT CAPTURED POST 0 ");
				for (new client = 1; client <= MaxClients; client++)
				{	
					if (client > 0 && IsClientConnected(client) && !IsFakeClient(client) && IsValidClient(client))
					{
						new team = GetClientTeam(client);
						if(IsClientInGame(client) && !IsClientTimingOut(client) && playerFirstDeath[client] == true && playerPickSquad[client] == 1 && playerFirstJoin[client] == false && !IsPlayerAlive(client) && team == TEAM_1)
						{
							CreateCounterRespawnTimer(client);
						}
					}
					
				}
			}
		// }
		}
		return Plugin_Continue;

}
public Action:Event_ObjectDestroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_isConquer != 1)  {
		new reinforce_time = GetConVarInt(sm_reinforce_time);
		g_reinforceTime = reinforce_time;
		if (GetConVarInt(sm_respawn_reset_each_objective))
		{
			SetPlayerSpawns();
		}
	}
	if (g_isConquer == 1) {
		for (new client = 1; client <= MaxClients; client++)
		{	
			if (client > 0 && IsClientConnected(client) && !IsFakeClient(client) && IsValidClient(client))
			{
				new team = GetClientTeam(client);
				if(IsClientInGame(client) && !IsClientTimingOut(client) && playerFirstDeath[client] == true && playerPickSquad[client] == 1 && playerFirstJoin[client] == false && !IsPlayerAlive(client) && team == TEAM_1)
				{
					CreateRespawnTimer(client);
				}
			}
			
		}
	}
	return Plugin_Continue;
}

//Run this to mark a bot as ready to spawn. Add tokens if you want them to be able to spawn.
SetPlayerSpawns(client=-1)
{
	if (g_isConquer != 1) {
		new mc = MaxClients;
		new iTeam;
		if (!GetConVarBool(sm_respawn_enabled))
		{
			return;
		}
		if (client == -1)
		{
			client = 1;
		}
		else
		{
			mc = client;
		}
		new t_team_lives_2 = 0; // temp count for players/bots
		new t_team_lives_3 = 0;
		//PrintToServer("[RESPAWNS] Called SetPlayerSpawns with client %d mc %d",client,mc);
		for (; client<=mc; client++)
		{
			if(client > 0 && client <= MaxClients && IsClientInGame(client))
			{
				iTeam = GetClientTeam(client);
				if (g_respawn_type == 1)
				{
					g_iSpawnTokens[client] = g_iRespawnCount[iTeam];

				}
				else if (g_respawn_type == 2)
				{
					if(!IsFakeClient(client))
					{
						t_team_lives_2++;
					}
					else if (IsFakeClient(client))
					{
						t_team_lives_3++;
					}
				}
					
			}

		}

		if (g_respawn_type == 2)
		{
			if (g_respawn_count_team2 > 0)
			{
				g_team_lives_2 = (t_team_lives_2 * g_respawn_lives_modifier); // If 10 bots alive, * 2 = 20 lives, so 10 initial lives + 20 = 30 total
				g_team_lives_2_total = (t_team_lives_2 * g_respawn_lives_modifier);
			}
			if (g_respawn_count_team3 > 0)
			{
				g_team_lives_3 = (t_team_lives_3 * g_respawn_lives_modifier);
				g_team_lives_3_total = (t_team_lives_3 * g_respawn_lives_modifier);
			}
		}
	}
}

public Action:Event_PlayerPickSquad( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"squad_slot" "byte"
	//"squad" "byte"
	//"userid" "short"
	//"class_template" "string"
	//PrintToServer("##########PLAYER IS PICKING SQUAD!############");
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	playerPickSquad[client] = 1;
	decl String:class_template[64];
	GetEventString(event, "class_template",class_template,sizeof(class_template));
	new team = GetClientTeam(client);
	if(IsClientInGame(client) && !IsFakeClient(client) && IsClientObserver(client) && !IsPlayerAlive(client) && g_hurtFatal[client] == 0 && team == TEAM_1)
	{
		playerItems[client][0] = true;
		playerItems[client][1] = true;
		// playerItems[client][2] = true;
		new playerRag = EntRefToEntIndex(g_ClientRagdolls[client]);
		if(playerRag > 0 && IsValidEdict(playerRag) && IsValidEntity(playerRag))
			RemoveRagdoll(client);

		g_hurtFatal[client] = -1;
	}
	
	if( client) {
		g_client_last_classstring[client] = class_template;
	}
	if( client == 0 || !IsClientInGame(client) )
		return;	
	//SetPlayerSpawns( client );
}
public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attackerId = GetEventInt(event, "attacker");
	new attacker = GetClientOfUserId(attackerId);
	new victimId = GetEventInt(event, "userid");
	new victim = GetClientOfUserId(victimId);
	new Int:dmg_taken = GetEventInt(event, "dmg_health");
	new hitgroup = GetEventInt(event, "hitgroup");
	decl String:weapon[32];
	new Int:victimHealth = GetEventInt(event, "health");
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	//PrintToServer("[DAMAGE TAKEN] Weapon used: %s, Damage done: %i",weapon, dmg_taken);
	g_clientDamageDone[victim] = dmg_taken;

	new teamAttack;
	if (attacker > 0 && IsClientInGame(attacker) && IsValidClient(attacker))
		teamAttack = GetClientTeam(attacker);

	new Float:fFatalChance = GetConVarFloat(sm_fatal_chance);
	new Float:fFatalHeadChance = GetConVarFloat(sm_fatal_head_chance);
	new Float:fRandom = GetRandomFloat(0.0, 1.0);
	if (IsClientInGame(victim))
	{
		if (hitgroup == 0)
		{
		//explosive list
			//incens
			//grenade_molotov, grenade_anm14
			//PrintToServer("[HITGROUP HURT BURN]");
			//grenade_m67, grenade_f1, grenade_ied, grenade_c4, rocket_rpg7, rocket_at4, grenade_gp25_he, grenade_m203_he
			if (StrEqual(weapon, "grenade_anm14", false) || StrEqual(weapon, "grenade_molotov", false))
			{
				//PrintToServer("[SUICIDE] incen/molotov DETECTED!");
				if (dmg_taken >= GetConVarInt(sm_fatal_burn_dmg) && (fRandom <= fFatalChance))
				{
					g_hurtFatal[victim] = 1;
					//PrintToServer("[PLAYER HURT BURN]");
				}
			}
			else if (StrEqual(weapon, "grenade_m67", false) || 
				StrEqual(weapon, "grenade_f1", false) || 
				StrEqual(weapon, "grenade_ied", false) || 
				StrEqual(weapon, "grenade_c4", false) || 
				StrEqual(weapon, "rocket_rpg7", false) || 
				StrEqual(weapon, "rocket_at4", false) || 
				StrEqual(weapon, "grenade_gp25_he", false) || 
				StrEqual(weapon, "grenade_m203_he", false))
			{
				//PrintToServer("[HITGROUP HURT EXPLOSIVE]");
				if (dmg_taken >= GetConVarInt(sm_fatal_explosive_dmg) && (fRandom <= fFatalChance))
				{
					g_hurtFatal[victim] = 1;
					//PrintToServer("[PLAYER HURT EXPLOSIVE]");
				}
			}
			//PrintToServer("[SUICIDE] HITRGOUP 0 [GENERIC]");
		}
		else if (hitgroup == 1)
		{
			
			//PrintToServer("[PLAYER HURT HEAD]");
			if (dmg_taken >= GetConVarInt(sm_fatal_head_dmg) && (fRandom <= fFatalHeadChance) && teamAttack != TEAM_1)
			{
				g_hurtFatal[victim] = 1;
				//PrintToServer("[BOTSPAWNS] BOOM HEADSHOT");
			}
			
		}
		else if (hitgroup == 2 || hitgroup == 3)
		{
			//PrintToServer("[HITGROUP HURT CHEST]");
			if (dmg_taken >= GetConVarInt(sm_fatal_chest_stomach) && (fRandom <= fFatalChance))
			{
				g_hurtFatal[victim] = 1;
				//PrintToServer("[PLAYER HURT CHEST]");
			}
		}
		else if (hitgroup == 4 || hitgroup == 5  || hitgroup == 6 || hitgroup == 7)
		{
			//PrintToServer("[HITGROUP HURT LIMBS]");
			if (dmg_taken >= GetConVarInt(sm_fatal_limb_dmg) && (fRandom <= fFatalChance))
			{
				g_hurtFatal[victim] = 1;
				//PrintToServer("[PLAYER HURT LIMBS]");
			}
		}
	}
	if (g_EnableRevive == 1 && g_RoundStatus == 1 && GetConVarInt(sm_enable_track_ammo) == 1)
    {		
    	//PrintToServer("### GET PLAYER WEAPONS ###");
    	//CONSIDER IF PLAYER CHOOSES DIFFERENT CLASS
    		new primaryWeapon = GetPlayerWeaponSlot(victim, 0);
			new secondaryWeapon = GetPlayerWeaponSlot(victim, 1);
			new playerGrenades = GetPlayerWeaponSlot(victim, 3);

			playerPrimary[victim] = primaryWeapon;
			playerSecondary[victim] = secondaryWeapon;
			//Get ammo left in clips for primary and secondary
    		playerClip[victim][0] = GetPrimaryAmmo(victim, primaryWeapon, 0);
    		playerClip[victim][1] = GetPrimaryAmmo(victim, secondaryWeapon, 1); // m_iClip2 for secondary if this doesnt work? would need GetSecondaryAmmo
    		//Get Magazines left on player
    		if (primaryWeapon != -1 && IsValidEntity(primaryWeapon))
    			playerAmmo[victim][0] = GetWeaponAmmo(victim, primaryWeapon, 0); //primary
    		if (secondaryWeapon != -1 && IsValidEntity(secondaryWeapon))
    			playerAmmo[victim][1] = GetWeaponAmmo(victim, secondaryWeapon, 1); //secondary	  

    		//PrintToServer("PlayerClip_1 %i, PlayerClip_2 %i, playerAmmo_1 %i, playerAmmo_2 %i, playerGrenades %i",playerClip[victim][0], playerClip[victim][1], playerAmmo[victim][0], playerAmmo[victim][1], playerAmmo[victim][2]); 
    		// if (playerGrenades != -1 && IsValidEntity(playerGrenades))
    		// {
    		// 	 playerGrenadeType[victim][0] = GetGrenadeAmmo(victim, Gren_M67);
    		// 	 playerGrenadeType[victim][1] = GetGrenadeAmmo(victim, Gren_Incen);
    		// 	 playerGrenadeType[victim][2] = GetGrenadeAmmo(victim, Gren_Molot);
    		// 	 playerGrenadeType[victim][3] = GetGrenadeAmmo(victim, Gren_M18);
    		// 	 playerGrenadeType[victim][4] = GetGrenadeAmmo(victim, Gren_Flash);
    		// 	 playerGrenadeType[victim][5] = GetGrenadeAmmo(victim, Gren_F1);
    		// 	 playerGrenadeType[victim][6] = GetGrenadeAmmo(victim, Gren_IED);
    		// 	 playerGrenadeType[victim][7] = GetGrenadeAmmo(victim, Gren_C4);
    		// 	 playerGrenadeType[victim][8] = GetGrenadeAmmo(victim, Gren_AT4);
    		// 	 playerGrenadeType[victim][9] = GetGrenadeAmmo(victim, Gren_RPG7);
    		// }
    			
    }
}
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	playerFirstDeath[client] = true;
	//new Int:dmg_taken = GetEventInt(event, "damagebits");
	//Console check
	if (g_clientDamageDone[client] == 0 && !IsFakeClient(client))
	{
		//g_hurtFatal[client] = 1;
	}
	if (!IsFakeClient(client) && IsClientInGame(client))
	{
		decl Float:vecPos[3];
		GetClientAbsOrigin(client, Float:vecPos);
		g_iDeadVectors[client] = vecPos;

	    if (g_EnableRevive == 1 && g_RoundStatus == 1)
	    {		
			h_RagdollTimer[client] = CreateTimer(5.0, ConvertDeleteRagdoll, client);
	    }
				

	}
	new team = GetClientTeam(client);
	//PrintToServer("[PLAYERDEATH] Client %N has %d lives remaining", client, g_iSpawnTokens[client]);
	decl String:sGameMode[32];
	GetConVarString(FindConVar("mp_gamemode"), sGameMode, sizeof(sGameMode));

	 if (GetConVarInt(sm_respawn_enabled) == 1)
	 {
		if (IsClientInGame(client) && (team == TEAM_1 || team == TEAM_2))
		{
			new ncp = Ins_ObjectiveResource_GetProp("m_iNumControlPoints");
			new acp = Ins_ObjectiveResource_GetProp("m_nActivePushPointIndex");
			//if (Ins_InCounterAttack() && ((acp+1) == ncp) && (GetConVarInt(sm_respawn_final_counterattack)))
			
			if (StrEqual(sGameMode,"checkpoint") && Ins_InCounterAttack() && ((acp+1) == ncp) && (GetConVarInt(sm_respawn_final_counterattack) == 2))
			{
				//PrintToServer("##########FINAL COUNTER#########");

				if (g_respawn_type == 1)
				{
					if ((g_iSpawnTokens[client] < g_iRespawnCount[team]))
					{
						//PrintToServer("[RESPAWN] Respawning %N with extra token due to FINAL counterattack infinity!",client);
						g_iSpawnTokens[client] = (g_iRespawnCount[team] + 1);
					}
				}
				else if (g_respawn_type == 2)
				{
					if (g_respawn_count_team2 > 0)
						g_team_lives_2 = g_team_lives_2 + 1;

					if (g_respawn_count_team3 > 0)
						g_team_lives_3 = g_team_lives_3 + 1;
				}
				
			}
			else if (StrEqual(sGameMode,"checkpoint") && Ins_InCounterAttack() && (GetConVarInt(sm_respawn_counterattack) == 2) && !((acp+1) == ncp) && (IsFakeClient(client)))
			{
				//PrintToServer("##########NORMAL COUNTER#########");

				if (g_respawn_type == 1)
				{
					if ((g_iSpawnTokens[client] < g_iRespawnCount[team]))
					{
						//PrintToServer("[RESPAWN] Respawning %N with extra token due to FINAL counterattack infinity!",client);
						g_iSpawnTokens[client] = (g_iRespawnCount[team] + 1);
					}
				}
				else if (g_respawn_type == 2)
				{
					if (g_respawn_count_team2 > 0)
						g_team_lives_2 = g_team_lives_2 + 1;

					if (g_respawn_count_team3 > 0)
						g_team_lives_3 = g_team_lives_3 + 1;
				}
			}


			if (g_respawn_type == 1)
			{
				//PrintToServer("###SPAWN 1####");
				//If have lives, spawn
				if (g_iSpawnTokens[client] > 0)
				{
					if (IsFakeClient(client))
					{
						CreateRespawnTimer(client);
					}
					else
					{
						if (g_hurtFatal[client] == 1)
							CreateRespawnTimer(client);
					}
				}
			}
			else if (g_respawn_type == 2)
			{
				//PrintToServer("###SPAWN 2####");
				//If have lives, spawn
				if  (team == TEAM_1 && g_team_lives_2 > 0)
				{
						if (g_hurtFatal[client] == 1)
							CreateRespawnTimer(client);
				}
				else if (team == TEAM_2 && g_team_lives_3 > 0)
				{
					if (IsFakeClient(client))
					{
						
						CreateRespawnTimer(client);
					}
					else
					{
						if (g_hurtFatal[client] == 1)
							CreateRespawnTimer(client);
					}
				}
			}
			
		}
	}
	decl String:wound_hint[64];
	decl String:fatal_hint[64];

	if (g_hurtFatal[client] == 1 && !IsFakeClient(client))
	{
		Format(fatal_hint, 255,"You were fatally killed for %i damage", g_clientDamageDone[client]);
		PrintHintText(client, "%s", fatal_hint);
		PrintToChat(client, "%s", fatal_hint);
	}
	else
	{
			Format(wound_hint, 255,"You were wounded for %i damage, call a medic for revive!", g_clientDamageDone[client]);
			PrintHintText(client, "%s", wound_hint);
			PrintToChat(client, "%s", wound_hint);
	}
}


//This handles revives by medics
public CreateReviveTimer(client)
{
	h_ReviveTimer[client] = CreateTimer(0.0, RespawnPlayerRevive, client);
}
//Handles spawns when counter attack starts
public CreateCounterRespawnTimer(client)
{
	h_RespawnCounterTimer[client] = CreateTimer(0.0, RespawnPlayerCounter, client);
}
public CreateRespawnTimer(client)
{
	h_RespawnTimers[client] = CreateTimer(GetConVarFloat(sm_respawn_delay), RespawnPlayer2, client);
}

public Action:RespawnPlayer(client, target)
{
	decl String:game[40];
	GetGameFolderName(game, sizeof(game));
	LogAction(client, target, "\"%L\" respawned \"%L\"", client, target);
	if (StrEqual(game, "cstrike") || StrEqual(game, "csgo"))
	{
		CS_RespawnPlayer(target);
	}
	else if (StrEqual(game, "tf"))
	{
		TF2_RespawnPlayer(target);
	}
	else if ((StrEqual(game, "dod")) || StrEqual(game, "insurgency"))
	{
		SDKCall(g_hPlayerRespawn, target);
	}
}

public Action:RespawnPlayer2(Handle:Timer, any:client)
{
	h_RespawnTimers[client] = INVALID_HANDLE;
	decl String:game[40];
	GetGameFolderName(game, sizeof(game));
	new iTeam = GetClientTeam(client);
	if (g_respawn_type == 1 && g_iSpawnTokens[client] > 0)
	{
		g_iSpawnTokens[client]--;
	}
	else if (g_respawn_type == 2)
	{
		//If have lives, spawn
		if  (iTeam == TEAM_1 && g_team_lives_2 > 0)
		{
			g_team_lives_2--;
			if (g_team_lives_2 <= 0)
				g_team_lives_2 = 0;
		}
		else if (iTeam == TEAM_2 && g_team_lives_3 > 0)
		{
			g_team_lives_3--;
			if (g_team_lives_3 <= 0)
				g_team_lives_3 = 0;
			//PrintToServer("######################TEAM 2 LIVES REMAINING %i", g_team_lives_3);
		}
	}
	//PrintToServer("######################TEAM 2 LIVES REMAINING %i", g_team_lives_3);
	//PrintToServer("######################TEAM 2 LIVES REMAINING %i", g_team_lives_3);
	//PrintToServer("[RESPAWN] Respawning client %N who has %d lives remaining", client, g_iSpawnTokens[client]);
	if (StrEqual(game, "cstrike") || StrEqual(game, "csgo"))
	{
		CS_RespawnPlayer(client);
	}
	else if (StrEqual(game, "tf"))
	{
		TF2_RespawnPlayer(client);
	}
	else if ((StrEqual(game, "dod")) || StrEqual(game, "insurgency"))
	{
		SDKCall(g_hPlayerRespawn, client);
	}

	
	

	if (IsFakeClient(client))
		g_hRespawnTimer[client] = CreateTimer(0.0, Timer_PostSpawn, client); //Do the post-spawn stuff like moving to final "spawnpoint" selected
}


public Action:PreReviveTimer(Handle:Timer)
{
	h_PreReviveTimer = INVALID_HANDLE;
	//PrintToServer("ROUND STATUS AND REVIVE ENABLED********************");
	g_RoundStatus = 1;
	g_EnableRevive = 1;
}
public Action:ConvertDeleteRagdoll(Handle:Timer, any:client)
{	
	h_RagdollTimer[client] = INVALID_HANDLE;
	if (IsClientInGame(client) && g_RoundStatus == 1 && !IsPlayerAlive(client)) 
	{
		//PrintToServer("CONVERT RAGDOLL********************");
		//new clientRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		//TeleportEntity(clientRagdoll, g_iDeadVectors[client], NULL_VECTOR, NULL_VECTOR);

		new clientRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	    //This timer safely removes client-side ragdoll
	    if(clientRagdoll > 0 && IsValidEdict(clientRagdoll) && IsValidEntity(clientRagdoll) && g_EnableRevive == 1)
    	{
	    	new ref = EntIndexToEntRef(clientRagdoll);
			new entity = EntRefToEntIndex(ref);
			if(entity != INVALID_ENT_REFERENCE && IsValidEntity(entity))
			{
				AcceptEntityInput(entity, "Kill");
				clientRagdoll = INVALID_ENT_REFERENCE;
			}
    	}
	
	    
	    if (g_hurtFatal[client] != 1)
		{

		    new tempRag = CreateEntityByName("prop_ragdoll");
		    g_ClientRagdolls[client]  = EntIndexToEntRef(tempRag);
		    g_iDeadVectors[client][2] = g_iDeadVectors[client][2] + 50;
		    if(tempRag != -1)
		    {
		        decl String:name[64];
		        GetClientModel(client, name, sizeof(name));
		        SetEntityModel(tempRag, name);
		        DispatchSpawn(tempRag);
		        SetEntProp(tempRag, Prop_Send, "m_CollisionGroup", 17);
		        TeleportEntity(tempRag, g_iDeadVectors[client], NULL_VECTOR, NULL_VECTOR);
		        
		        GetEntPropVector(tempRag, Prop_Send, "m_vecOrigin", g_iDeadRagdollVectors[client]);
		        new Handle:revivePack;
		        CreateDataTimer(1.0 , Timer_RevivePeriod, revivePack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);	
		        WritePackCell(revivePack, client);
		        WritePackCell(revivePack, tempRag);
		       
		    }
		    else
		    {
		    	if(tempRag > 0 && IsValidEdict(tempRag) && IsValidEntity(tempRag))
					RemoveRagdoll(client);
			}
		}
	}
}

public Action:RespawnPlayerCounter(Handle:Timer, any:client)
{
	h_RespawnCounterTimer[client] = INVALID_HANDLE;
	decl String:game[40];
	GetGameFolderName(game, sizeof(game));
	//PrintToServer("[Counter Respawn] Respawning client %N who has %d lives remaining", client, g_iSpawnTokens[client]);
	if (StrEqual(game, "cstrike") || StrEqual(game, "csgo"))
	{
		CS_RespawnPlayer(client);
	}
	else if (StrEqual(game, "tf"))
	{
		TF2_RespawnPlayer(client);
	}
	else if ((StrEqual(game, "dod")) || StrEqual(game, "insurgency"))
	{
		SDKCall(g_hPlayerRespawn, client);
	}

	new playerRag = EntRefToEntIndex(g_ClientRagdolls[client]);
	//Remove network ragdoll
	if(playerRag > 0 && IsValidEdict(playerRag) && IsValidEntity(playerRag))
		RemoveRagdoll(client);
		
	g_hRespawnTimer[client] = CreateTimer(0.0, Timer_PostCounterSpawn, client); //Do the post-spawn stuff like moving to final "spawnpoint" selected
}

public Action:RespawnPlayerRevive(Handle:Timer, any:client)
{
	h_ReviveTimer[client] = INVALID_HANDLE;
	decl String:game[40];
	GetGameFolderName(game, sizeof(game));
	//PrintToServer("[REVIVE_RESPAWN] REVIVING client %N who has %d lives remaining", client, g_iSpawnTokens[client]);
	if (StrEqual(game, "cstrike") || StrEqual(game, "csgo"))
	{
		CS_RespawnPlayer(client);
	}
	else if (StrEqual(game, "tf"))
	{
		TF2_RespawnPlayer(client);
	}
	else if ((StrEqual(game, "dod")) || StrEqual(game, "insurgency"))
	{
		SDKCall(g_hPlayerRespawn, client);
	}

	if (playerRevived[client] == true && GetConVarInt(sm_enable_track_ammo) == 1)
	{
		SetPlayerAmmo(client);
	}
	new playerRag = EntRefToEntIndex(g_ClientRagdolls[client]);
	//Remove network ragdoll
	if(playerRag > 0 && IsValidEdict(playerRag) && IsValidEntity(playerRag))
		RemoveRagdoll(client);

	TeleportEntity(client, g_iDeadRagdollVectors[client], NULL_VECTOR, NULL_VECTOR);
	g_hRespawnTimer[client] = CreateTimer(0.0, Timer_PostRevive, client); //Do the post-spawn stuff like moving to final "spawnpoint" selected
}





public EnableChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new intNewValue = StringToInt(newValue);
	new intOldValue = StringToInt(oldValue);

	if(intNewValue == 1 && intOldValue == 0)
	{
		TagsCheck("respawntimes");
		//HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	}
	else if(intNewValue == 0 && intOldValue == 1)
	{
		TagsCheck("respawntimes", true);
		//UnhookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	}
}
public UpdateRespawnCountConVar(Handle:convar, const String:oldValue[], const String:newValue[])
{
	UpdateRespawnCount();
}
public UpdateRespawnCount()
{
	if (g_isConquer != 1) {
		new ism_respawn_count = GetConVarInt(sm_respawn_count);
			g_respawn_count_team2 = GetConVarInt(sm_respawn_count_team2);
			g_respawn_count_team3 = GetConVarInt(sm_respawn_count_team3);
			g_respawn_type = GetConVarInt(sm_respawn_type);
			g_respawn_lives_modifier = GetConVarInt(sm_respawn_lives_modifier);
		//new ism_respawn_reset_each_round = GetConVarInt(sm_respawn_reset_each_round);
		if (g_respawn_type == 1)
		{
			if (g_respawn_count_team2 > -1)
			{
				g_iRespawnCount[2] = g_respawn_count_team2;
			}
			else
			{
				g_iRespawnCount[2] = ism_respawn_count;
			}
			if (g_respawn_count_team3 > -1)
			{
				g_iRespawnCount[3] = g_respawn_count_team3;
			}
			else
			{
				g_iRespawnCount[3] = ism_respawn_count;
			}
		}
	}
		//Revive counts
		new ism_revive_seconds = GetConVarInt(sm_revive_seconds);
		new ism_revive_health = GetConVarInt(sm_revive_health);
		new ism_heal_amount = GetConVarInt(sm_heal_amount);
		
		g_revive_seconds = ism_revive_seconds;
		g_revive_health = ism_revive_health;
		g_heal_amount = ism_heal_amount;
}

public TagsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(sm_respawn_enabled))
		TagsCheck("respawntimes");
	else
		TagsCheck("respawntimes", true);
}


// Check for nearest player
public Action:checkPlayers(Handle:timer, any:data)
{
	// Variables to store
	new Float:clientOrigin[3];
	new Float:searchOrigin[3];
	new Float:near;
	new Float:distance;

	new Float:dist;
	new Float:vecPoints[3];
	new Float:vecAngles[3];
	new Float:clientAngles[3];

	decl String:directionString[64];
	decl String:unitString[32];

	decl String:textToPrint[64];

	// nearest client
	new nearest;

	// Client loop
	for (new client = 1; client <= MaxClients; client++)
	{

		// Valid client?
		if (client > 0 && IsClientInGame(client) && (StrContains(g_client_last_classstring[client], "medic") > -1) && (playerItems[client][0] || playerItems[client][1]) && IsPlayerAlive(client) && IsValidClient(client))
		{
			// Reset variables
			nearest = 0;
			near = 0.0;


			// Get origin
			GetClientAbsOrigin(client, clientOrigin);

			//PrintToServer("MEDIC DETECTED ********************");
			// Next client loop
			for (new search = 1; search <= MaxClients; search++)
			{

				
				// Check if valid
				if (search > 0 && IsClientInGame(search) && !IsPlayerAlive(search) && (g_hurtFatal[search] == 0 && search != client && (GetClientTeam(client) == GetClientTeam(search))))
				{
					//PrintToServer("MEDIC DETECTED ******************** 1");
					new clientRagdoll = EntRefToEntIndex(g_ClientRagdolls[search]);
					if (clientRagdoll > 0 && IsValidEdict(clientRagdoll) && IsValidEntity(clientRagdoll) && clientRagdoll != INVALID_ENT_REFERENCE)
					{

						//PrintToServer("MEDIC DETECTED ******************** 2");
						// Get distance to first client
						//GetClientAbsOrigin(search, searchOrigin);
						//GetEntPropVector(g_ClientRagdolls[search], Prop_Send, "m_vecOrigin", searchOrigin);
	    				searchOrigin = g_iDeadRagdollVectors[search];
	    				//searchOrigin = g_iDeadVectors[client];
						distance = GetVectorDistance(clientOrigin, searchOrigin);

						// Is he more near to the player as the player before?
						if (near == 0.0)
						{
							near = distance;
							nearest = search;
						}
						if (distance < near)
						{
							// Set new distance and new nearest player
							near = distance;
							nearest = search;
						}
					}
				}
			}


			// Found a player?
			if (nearest != 0)
			{
				/*
				// Client get Direction?
				if (playerItems[client][2])
				{
					// Get the origin of the nearest player
					GetClientAbsOrigin(nearest, searchOrigin);

					// and the Angles
					GetClientAbsAngles(client, clientAngles);

					// Angles from origin
					MakeVectorFromPoints(clientOrigin, searchOrigin, vecPoints);
					GetVectorAngles(vecPoints, vecAngles);


					// Differenz
					new Float:diff = clientAngles[1] - vecAngles[1];


					// Correct it
					if (diff < -180)
					{
						diff = 360 + diff;
					}

					if (diff > 180)
					{
						diff = 360 - diff;
					}


					// Now geht the direction
					// Up
					if (diff >= -22.5 && diff < 22.5)
					{
						Format(directionString, sizeof(directionString), "FWD");//"\xe2\x86\x91");
					}
					// right up
					else if (diff >= 22.5 && diff < 67.5)
					{
						Format(directionString, sizeof(directionString), "FWD-RIGHT");//"\xe2\x86\x97");
					}
					// right
					else if (diff >= 67.5 && diff < 112.5)
					{
						Format(directionString, sizeof(directionString), "RIGHT");//"\xe2\x86\x92");
					}

					// right down
					else if (diff >= 112.5 && diff < 157.5)
					{
						Format(directionString, sizeof(directionString), "BACK-RIGHT");//"\xe2\x86\x98");
					}
					// down
					else if (diff >= 157.5 || diff < -157.5)
					{
						Format(directionString, sizeof(directionString), "BACK");//"\xe2\x86\x93");
					}

									// down left
					else if (diff >= -157.5 && diff < -112.5)
					{
						Format(directionString, sizeof(directionString), "BACK-LEFT");//"\xe2\x86\x99");
					}

					// left
					else if (diff >= -112.5 && diff < -67.5)
					{
						Format(directionString, sizeof(directionString), "LEFT");//"\xe2\x86\x90");
					}
					// left up
					else if (diff >= -67.5 && diff < -22.5)
					{
						Format(directionString, sizeof(directionString), "FWD-LEFT");//"\xe2\x86\x96");
					}


					// Add to text
					if (playerItems[client][1] || playerItems[client][0])
					{
						Format(textToPrint, sizeof(textToPrint), "%s", directionString);
					}
					else
					{
						Format(textToPrint, sizeof(textToPrint), directionString);
					}
				}
*/


				// Client get Distance?
				if (playerItems[client][1])
				{
					// Distance to meters
					dist = near * 0.01905;

					// Distance to feet?
					if (unit == 1)
					{
						dist = dist * 3.2808399;

						// Feet
						Format(unitString, sizeof(unitString), "%T", "feet", client);
					}
					else
					{
						// Meter
						Format(unitString, sizeof(unitString), "%T", "meter", client);
					}


					// Add to text
					if (playerItems[client][0])
					{
						Format(textToPrint, sizeof(textToPrint), "(%.0f %s)", dist, unitString);
					}
					else
					{
						Format(textToPrint, sizeof(textToPrint), "(%.0f %s)", dist, unitString);
					}
				}


				// Add name
				if (playerItems[client][0])
				{
					Format(textToPrint, sizeof(textToPrint), "Nearest dead: %N %s", nearest, textToPrint);
				}

				// Print text
				//PrintHintText(client, textToPrint);
				//PrintToChat(client, textToPrint);
				PrintCenterText(client, textToPrint);
			}
		}
	}

	return Plugin_Continue;
}



stock TagsCheck(const String:tag[], bool:remove = false)
{
	new Handle:hTags = FindConVar("sv_tags");
	decl String:tags[255];
	GetConVarString(hTags, tags, sizeof(tags));

	if (StrContains(tags, tag, false) == -1 && !remove)
	{
		decl String:newTags[255];
		Format(newTags, sizeof(newTags), "%s,%s", tags, tag);
		ReplaceString(newTags, sizeof(newTags), ",,", ",", false);
		SetConVarString(hTags, newTags);
		GetConVarString(hTags, tags, sizeof(tags));
	}
	else if (StrContains(tags, tag, false) > -1 && remove)
	{
		ReplaceString(tags, sizeof(tags), tag, "", false);
		ReplaceString(tags, sizeof(tags), ",,", ",", false);
		SetConVarString(hTags, tags);
	}
}

// Stock to check if client is valid
stock bool:isClientValid(client)
{
	if (client > 0 && client <= MaxClients)
	{
		if (IsClientInGame(client))
		{
			if (!IsFakeClient(client) && !IsClientSourceTV(client))
			{
				// Yeah, the client is valid
				return true;
			}
		}
	}

	// No he isn't valid
	return false;
}
