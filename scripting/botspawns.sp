//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3
#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <insurgency>
#undef REQUIRE_PLUGIN
#include <navmesh>
#include <updater>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_DESCRIPTION "Adds a number of options and ways to handle bot spawns"
#define PLUGIN_NAME "[INS] Bot Spawns"
#define PLUGIN_URL "http://jballou.com/"
#define PLUGIN_VERSION "0.4.0"
#define PLUGIN_WORKING "0"

public Plugin:myinfo = {
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url		= PLUGIN_URL
};


#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-botspawns.txt"

new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?

new Handle:cvarSpawnMode = INVALID_HANDLE; //Spawn in hiding spots (1), any spawnpoints that meets criteria (2), or only at normal spawnpoints at next objective (0, standard spawning, default setting)
new Handle:cvarCounterattackMode = INVALID_HANDLE; //Use standard spawning for counterattack waves? Same values and default as above.
new Handle:cvarCounterattackFinaleInfinite = INVALID_HANDLE; //Infinite finale?
new Handle:cvarCounterattackFrac = INVALID_HANDLE; //Multiplier to total bots to take part in counterattack
new Handle:cvarMinCounterattackDistance = INVALID_HANDLE; //Min distance from counterattack objective to spawn
new Handle:cvarSpawnAttackDelay = INVALID_HANDLE; //Attack delay for spawning bots
new Handle:cvarMinSpawnDelay = INVALID_HANDLE; //Min delay for spawning. Set to 0 for instant.
new Handle:cvarMaxSpawnDelay = INVALID_HANDLE; //Max delay for spawning. Set to 0 for instant.
new Handle:cvarMinPlayerDistance = INVALID_HANDLE; //Min/max distance from players to spawn
new Handle:cvarMaxPlayerDistance = INVALID_HANDLE; //Min/max distance from players to spawn
new Handle:cvarMinObjectiveDistance = INVALID_HANDLE; //Min/max distance from next objective to spawn
new Handle:cvarMaxObjectiveDistance = INVALID_HANDLE; //Min/max distance from next objective to spawn
new Handle:cvarMinFracInGame = INVALID_HANDLE; //Min multiplier of bot quota to have alive at any time. Set to 1 to emulate standard spawning.
new Handle:cvarMaxFracInGame = INVALID_HANDLE; //Max multiplier of bot quota to have alive at any time. Set to 1 to emulate standard spawning.
new Handle:cvarTotalSpawnFrac = INVALID_HANDLE; //Total number of bots to spawn as multiple of number of bots in game to simulate larger numbers. 1 is standard, values less than 1 are not supported.
new Handle:cvarMinFireteamSize = INVALID_HANDLE; //Min count of bots to spawn per fireteam. Default 3
new Handle:cvarMaxFireteamSize = INVALID_HANDLE; //Max count of bots to spawn per fireteam. Default 5
new Handle:cvarStopSpawningAtObjective = INVALID_HANDLE; //Stop spawning new bots when near next objective (1, default)
new Handle:cvarRemoveUnseenWhenCapping = INVALID_HANDLE; //Silently kill off all unseen bots when capping next point (1, default)
new Handle:cvarSpawnSnipersAlone = INVALID_HANDLE; //Spawn snipers alone, maybe further out (1)?
new bool:g_bEnabled, g_iSpawnMode, g_iCounterattackMode, g_iCounterattackFinaleInfinite, Float:g_flCounterattackFrac, Float:g_flMinSpawnDelay, Float:g_flMaxSpawnDelay, Float:g_flMinPlayerDistance, Float:g_flMaxPlayerDistance, Float:g_flMinObjectiveDistance, Float:g_flMaxObjectiveDistance, Float:g_flMinFracInGame, Float:g_flMaxFracInGame, Float:g_flTotalSpawnFrac, g_iMinFireteamSize, g_iMaxFireteamSize, bool:g_bStopSpawningAtObjective, bool:g_bRemoveUnseenWhenCapping, bool:g_bSpawnSnipersAlone, Float:g_flMinCounterattackDistance;
//Until I add functionality


new Handle:g_hHidingSpots = INVALID_HANDLE;
#define MAX_OBJECTIVES 13
#define MAX_HIDING_SPOTS 2048
// Minimum space between players, so we don't telefrag
#define MIN_PLAYER_DISTANCE 128.0
new g_iCPHidingSpots[MAX_OBJECTIVES][MAX_HIDING_SPOTS];
new g_iCPHidingSpotCount[MAX_OBJECTIVES];
new g_iCPLastHidingSpot[MAX_OBJECTIVES];
new Float:m_vCPPositions[MAX_OBJECTIVES][3],m_iNumControlPoints;

new Handle:g_hForceRespawn;
new Handle:g_hGameConfig;
new Handle:g_hSpawnTimer[MAXPLAYERS+1];
new g_iHidingSpotCount;
new g_iBotsToSpawn, g_iSpawnTokens[MAXPLAYERS+1], g_iNumReady, g_iBotsAlive,g_iBotsTotal,g_iInQueue[MAXPLAYERS+1],g_iNeedSpawn[MAXPLAYERS+1],Float:g_vecOrigin[MAXPLAYERS+1][3];
new bot_team = 3;

#pragma unused g_bRemoveUnseenWhenCapping
#pragma unused g_bSpawnSnipersAlone
#pragma unused g_bStopSpawningAtObjective
#pragma unused g_flCounterattackFrac
#pragma unused g_flMaxObjectiveDistance
#pragma unused g_flMinFracInGame
#pragma unused g_flMinObjectiveDistance
#pragma unused g_iCounterattackMode
#pragma unused g_iCounterattackFinaleInfinite
#pragma unused g_iMaxFireteamSize
#pragma unused g_iMinFireteamSize

enum SpawnModes {
SpawnMode_Normal = 0,
	SpawnMode_HidingSpots,
	SpawnMode_SpawnPoints,
};

new m_hMyWeapons, m_flNextPrimaryAttack, m_flNextSecondaryAttack;

public OnPluginStart()
{
	InsLog(DEBUG, "Starting up");
	cvarVersion = CreateConVar("sm_botspawns_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_botspawns_enabled", PLUGIN_WORKING, "Enable enhanced bot spawning features", FCVAR_NOTIFY | FCVAR_PLUGIN);

	cvarSpawnMode = CreateConVar("sm_botspawns_spawn_mode", "0", "Only normal spawnpoints at the objective, the old way (0), spawn in hiding spots following rules (1), spawnpoints that meet rules (2)", FCVAR_NOTIFY | FCVAR_PLUGIN);

	cvarCounterattackMode = CreateConVar("sm_botspawns_counterattack_mode", "0", "Do not alter default game spawning during counterattacks (0), Respawn using new rules during counterattack by following sm_botspawns_respawn_mode (1)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarCounterattackFinaleInfinite = CreateConVar("sm_botspawns_counterattack_finale_infinite", "0", "Obey sm_botspawns_counterattack_respawn_mode (0), use rules and do infinite respawns (1)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarCounterattackFrac = CreateConVar("sm_botspawns_counterattack_frac", "0.5", "Multiplier to total bots for spawning in counterattack wave", FCVAR_NOTIFY | FCVAR_PLUGIN);

	cvarMinCounterattackDistance = CreateConVar("sm_botspawns_min_counterattack_distance", "3600", "Min distance from counterattack objective to spawn", FCVAR_NOTIFY | FCVAR_PLUGIN);

	cvarSpawnAttackDelay = CreateConVar("sm_botspawns_spawn_attack_delay", "10", "Delay in seconds for spawning bots to wait before firing.", FCVAR_NOTIFY | FCVAR_PLUGIN);

	cvarMinSpawnDelay = CreateConVar("sm_botspawns_min_spawn_delay", "1", "Min delay in seconds for spawning. Set to 0 for instant.", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarMaxSpawnDelay = CreateConVar("sm_botspawns_max_spawn_delay", "30", "Max delay in seconds for spawning. Set to 0 for instant.", FCVAR_NOTIFY | FCVAR_PLUGIN);

	cvarMinPlayerDistance = CreateConVar("sm_botspawns_min_player_distance", "1200", "Min distance from players to spawn", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarMaxPlayerDistance = CreateConVar("sm_botspawns_max_player_distance", "16000", "Max distance from players to spawn", FCVAR_NOTIFY | FCVAR_PLUGIN);

	cvarMinObjectiveDistance = CreateConVar("sm_botspawns_min_objective_distance", "1", "Min distance from next objective to spawn", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarMaxObjectiveDistance = CreateConVar("sm_botspawns_max_objective_distance", "12000", "Max distance from next objective to spawn", FCVAR_NOTIFY | FCVAR_PLUGIN);

	cvarMinFracInGame = CreateConVar("sm_botspawns_min_frac_in_game", "0.75", "Min multiplier of bot quota to have alive at any time. Set to 1 to emulate standard spawning.", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarMaxFracInGame = CreateConVar("sm_botspawns_max_frac_in_game", "1", "Max multiplier of bot quota to have alive at any time. Set to 1 to emulate standard spawning.", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarTotalSpawnFrac = CreateConVar("sm_botspawns_total_spawn_frac", "1.75", "Total number of bots to spawn as multiple of number of bots in game to simulate larger numbers. 1 is standard, values less than 1 are not supported.", FCVAR_NOTIFY | FCVAR_PLUGIN);

	cvarMinFireteamSize = CreateConVar("sm_botspawns_min_fireteam_size", "3", "Min number of bots to spawn per fireteam. Default 3", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarMaxFireteamSize = CreateConVar("sm_botspawns_max_fireteam_size", "5", "Max number of bots to spawn per fireteam. Default 5", FCVAR_NOTIFY | FCVAR_PLUGIN);

	cvarStopSpawningAtObjective = CreateConVar("sm_botspawns_stop_spawning_at_objective", "1", "Stop spawning new bots when near next objective (1, default)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarRemoveUnseenWhenCapping = CreateConVar("sm_botspawns_remove_unseen_when_capping", "1", "Silently kill off all unseen bots when capping next point (1, default)", FCVAR_NOTIFY | FCVAR_PLUGIN);

	cvarSpawnSnipersAlone = CreateConVar("sm_botspawns_spawn_snipers_alone", "1", "Spawn snipers alone, can be 50% further from the objective than normal bots if this is enabled?", FCVAR_NOTIFY | FCVAR_PLUGIN);

	HookConVarChange(cvarVersion,CvarChange);
	HookConVarChange(cvarEnabled,CvarChange);
	HookConVarChange(cvarSpawnMode,CvarChange);
	HookConVarChange(cvarCounterattackFinaleInfinite,CvarChange);
	HookConVarChange(cvarCounterattackMode,CvarChange);
	HookConVarChange(cvarCounterattackFrac,CvarChange);
	HookConVarChange(cvarMinSpawnDelay,CvarChange);
	HookConVarChange(cvarMaxSpawnDelay,CvarChange);
	HookConVarChange(cvarMinPlayerDistance,CvarChange);
	HookConVarChange(cvarMaxPlayerDistance,CvarChange);
	HookConVarChange(cvarMinObjectiveDistance,CvarChange);
	HookConVarChange(cvarMaxObjectiveDistance,CvarChange);
	HookConVarChange(cvarMinFracInGame,CvarChange);
	HookConVarChange(cvarMaxFracInGame,CvarChange);
	HookConVarChange(cvarTotalSpawnFrac,CvarChange);
	HookConVarChange(cvarMinFireteamSize,CvarChange);
	HookConVarChange(cvarMaxFireteamSize,CvarChange);
	HookConVarChange(cvarStopSpawningAtObjective,CvarChange);
	HookConVarChange(cvarRemoveUnseenWhenCapping,CvarChange);
	HookConVarChange(cvarSpawnSnipersAlone,CvarChange);
	UpdateCvars();

	g_hGameConfig = LoadGameConfigFile("insurgency.games");
	if (g_hGameConfig == INVALID_HANDLE)
	{
		SetFailState("Fatal Error: Missing File \"insurgency.games\"!");
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Signature, "ForceRespawn");
	g_hForceRespawn = EndPrepSDKCall();
	if (g_hForceRespawn == INVALID_HANDLE)
	{
		SetFailState("Fatal Error: Unable to find signature for \"Respawn\"!");
	}
	if ((m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons")) == -1) {
		SetFailState("Fatal Error: Unable to find property offset \"CBasePlayer::m_hMyWeapons\" !");
	}

	if ((m_flNextPrimaryAttack = FindSendPropOffs("CBaseCombatWeapon", "m_flNextPrimaryAttack")) == -1) {
		SetFailState("Fatal Error: Unable to find property offset \"CBaseCombatWeapon::m_flNextPrimaryAttack\" !");
	}

	if ((m_flNextSecondaryAttack = FindSendPropOffs("CBaseCombatWeapon", "m_flNextSecondaryAttack")) == -1) {
		SetFailState("Fatal Error: Unable to find property offset \"CBaseCombatWeapon::m_flNextSecondaryAttack\" !");
	}

	//HookEvent("player_spawn", Event_SpawnPre, EventHookMode_Pre);
	HookEvent("player_spawn", Event_Spawn);
	HookEvent("player_spawn", Event_SpawnPost, EventHookMode_Post);
	//HookEvent("round_begin", Event_RoundBeginPre, EventHookMode_Pre);
	HookEvent("round_begin", Event_RoundBegin);
	//HookEvent("round_begin", Event_RoundBeginPost, EventHookMode_Post);
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("controlpoint_captured", Event_ControlPointCaptured);
	HookEvent("controlpoint_starttouch", Event_ControlPointStartTouch);
	CreateTimer(1.0, Timer_ProcessQueue, _, TIMER_REPEAT);
}

public CvarChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	UpdateCvars();
}
public UpdateCvars()
{
	g_iSpawnMode = GetConVarInt(cvarSpawnMode);
	g_iCounterattackFinaleInfinite = GetConVarInt(cvarCounterattackFinaleInfinite);
	g_iCounterattackMode = GetConVarInt(cvarCounterattackMode);
	g_iMinFireteamSize = GetConVarInt(cvarMinFireteamSize);
	g_iMaxFireteamSize = GetConVarInt(cvarMaxFireteamSize);

	g_flCounterattackFrac = GetConVarFloat(cvarCounterattackFrac);
	g_flMinCounterattackDistance = GetConVarFloat(cvarMinCounterattackDistance);
	g_flMinSpawnDelay = GetConVarFloat(cvarMinSpawnDelay);
	g_flMaxSpawnDelay = GetConVarFloat(cvarMaxSpawnDelay);
	g_flMinPlayerDistance = GetConVarFloat(cvarMinPlayerDistance);
	g_flMaxPlayerDistance = GetConVarFloat(cvarMaxPlayerDistance);
	g_flMinObjectiveDistance = GetConVarFloat(cvarMinObjectiveDistance);
	g_flMaxObjectiveDistance = GetConVarFloat(cvarMaxObjectiveDistance);
	g_flMinFracInGame = GetConVarFloat(cvarMinFracInGame);
	g_flMaxFracInGame = GetConVarFloat(cvarMaxFracInGame);
	g_flTotalSpawnFrac = GetConVarFloat(cvarTotalSpawnFrac);

	g_bEnabled = GetConVarBool(cvarEnabled);
	g_bStopSpawningAtObjective = GetConVarBool(cvarStopSpawningAtObjective);
	g_bRemoveUnseenWhenCapping = GetConVarBool(cvarRemoveUnseenWhenCapping);
	g_bSpawnSnipersAlone = GetConVarBool(cvarSpawnSnipersAlone);
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}
public OnMapStart()
{
	UpdateCvars();
/*
	new String:sGameMode[32],String:sLogicEnt[64];
	GetConVarString(FindConVar("mp_gamemode"), sGameMode, sizeof(sGameMode));
	Format (sLogicEnt,sizeof(sLogicEnt),"logic_%s",sGameMode);
	InsLog(DEBUG, "gamemode %s logicent %s",sGameMode,sLogicEnt);
	if (!StrEqual(sGameMode,"checkpoint")) return;
*/
	RestartBotQueue();
	return;
}

public GetHidingSpots() {
	if (!NavMesh_Exists()) return;
	if (g_hHidingSpots == INVALID_HANDLE) g_hHidingSpots = NavMesh_GetHidingSpots();
	g_iHidingSpotCount = GetArraySize(g_hHidingSpots);
	new Float:flHidingSpot[3];//, iHidingSpotFlags;
	new Float:dist,Float:closest = -1.0,pointidx=-1;

	m_iNumControlPoints = Ins_ObjectiveResource_GetProp("m_iNumControlPoints");
	InsLog(DEBUG, "m_iNumControlPoints %d",m_iNumControlPoints);
	for (new i = 0; i < m_iNumControlPoints; i++) {
		Ins_ObjectiveResource_GetPropVector("m_vCPPositions",m_vCPPositions[i],i);
		InsLog(DEBUG, "i %d (%f,%f,%f)",i,m_vCPPositions[i][0],m_vCPPositions[i][1],m_vCPPositions[i][2]);
	}
	for (new iCP = 0; iCP < m_iNumControlPoints; iCP++) {
		g_iCPLastHidingSpot[iCP] = 0;
	}
	if (g_iHidingSpotCount) {
		for (new iIndex = 0, iSize = g_iHidingSpotCount; iIndex < iSize; iIndex++) {
			flHidingSpot[0] = GetArrayCell(g_hHidingSpots, iIndex, NavMeshHidingSpot_X);
			flHidingSpot[1] = GetArrayCell(g_hHidingSpots, iIndex, NavMeshHidingSpot_Y);
			flHidingSpot[2] = GetArrayCell(g_hHidingSpots, iIndex, NavMeshHidingSpot_Z);
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
		InsLog(DEBUG, "Found hiding count: a %d b %d c %d d %d e %d f %d g %d h %d i %d j %d k %d l %d m %d",g_iCPHidingSpotCount[0],g_iCPHidingSpotCount[1],g_iCPHidingSpotCount[2],g_iCPHidingSpotCount[3],g_iCPHidingSpotCount[4],g_iCPHidingSpotCount[5],g_iCPHidingSpotCount[6],g_iCPHidingSpotCount[7],g_iCPHidingSpotCount[8],g_iCPHidingSpotCount[9],g_iCPHidingSpotCount[10],g_iCPHidingSpotCount[11],g_iCPHidingSpotCount[12]);
	}
}
Float:GetHidingSpotVector(iSpot) {
	new Float:flHidingSpot[3];
	flHidingSpot[0] = GetArrayCell(g_hHidingSpots, iSpot, NavMeshHidingSpot_X);
	flHidingSpot[1] = GetArrayCell(g_hHidingSpots, iSpot, NavMeshHidingSpot_Y);
	flHidingSpot[2] = GetArrayCell(g_hHidingSpots, iSpot, NavMeshHidingSpot_Z);
	return flHidingSpot;
}

CheckSpawnPoint(Float:vecSpawn[3],client) {
//Ins_InCounterAttack
	new m_iTeam = GetClientTeam(client);
	new Float:distance,Float:furthest,Float:closest=-1.0;
	new Float:vecOrigin[3];

	GetClientAbsOrigin(client,vecOrigin);
	for (new iTarget = 1; iTarget < MaxClients; iTarget++) {
		if (!IsValidClient(iTarget))
			continue;
		if (!IsClientInGame(iTarget))
			continue;
		//InsLog(DEBUG, "Distance from %N to iSpot %d is %f",iTarget,iSpot,distance);
		distance = GetVectorDistance(vecSpawn,g_vecOrigin[iTarget]);
		if (distance > furthest)
			furthest = distance;
		if ((distance < closest) || (closest < 0))
			closest = distance;
		// If any player is close enough to telefrag
		if (distance < MIN_PLAYER_DISTANCE) {
			return 0;
		}
		if (GetClientTeam(iTarget) != m_iTeam) {
			// If we are too close
			if (distance < g_flMinPlayerDistance) {
				return 0;
			}
			// If the player can see the spawn point
			if ((IsVectorInSightRange(iTarget, vecSpawn, 120.0)) && (ClientCanSeeVector(iTarget, vecSpawn, g_flMaxPlayerDistance))) {
				return 0;
			}
		}
	}
	// If any player is too far
	if (closest > g_flMaxPlayerDistance) {
		return 0;
	}
	// Check distance to point in counterattack
	if (Ins_InCounterAttack()) {
		new m_nActivePushPointIndex = Ins_ObjectiveResource_GetProp("m_nActivePushPointIndex");
		distance = GetVectorDistance(vecSpawn,m_vCPPositions[m_nActivePushPointIndex]);
		if (distance < g_flMinCounterattackDistance) {
			return 0;
		}
	}
	return 1;
}

float GetSpawnPoint_HidingSpot(client,iteration=0) {
	float vecSpawn[3];
	float vecOrigin[3];
	GetClientAbsOrigin(client,vecOrigin);

	UpdatePlayerOrigins();
	new m_nActivePushPointIndex = Ins_ObjectiveResource_GetProp("m_nActivePushPointIndex");

	new minidx = (iteration) ? 0 : g_iCPLastHidingSpot[m_nActivePushPointIndex];
	new maxidx = (iteration) ? g_iCPLastHidingSpot[m_nActivePushPointIndex] : g_iCPHidingSpotCount[m_nActivePushPointIndex];
	new iSpot;
	for (new iCPHIndex = minidx; iCPHIndex < maxidx; iCPHIndex++) {
		iSpot = g_iCPHidingSpots[m_nActivePushPointIndex][iCPHIndex];
		vecSpawn = GetHidingSpotVector(iSpot);

		if (CheckSpawnPoint(vecSpawn,client)) {
			g_iCPLastHidingSpot[m_nActivePushPointIndex] = iCPHIndex;
			InsLog(DEBUG,"FOUND! %N (%d) hiding spot %d at (%f, %f, %f)", client, client, iSpot, vecSpawn[0], vecSpawn[1], vecSpawn[2]);
			return vecSpawn;
		}
	}
	if (iteration) {
		InsLog(DEBUG,"Unable to find hiding spot for %N (%d)", client, client);
		return vecOrigin;
	}
	InsLog(DEBUG,"Running second iteration for hiding spot %N (%d)", client, client);
	return GetSpawnPoint_HidingSpot(client,1);
}

float GetSpawnPoint_SpawnPoint(client) {
	int m_iTeam = GetClientTeam(client);
	int m_iTeamNum;
	float vecSpawn[3];
	float vecOrigin[3];
	GetClientAbsOrigin(client,vecOrigin);
	new point = FindEntityByClassname(-1, "ins_spawnpoint");
	while (point != -1) {
		// Check to make sure it is the same team
		m_iTeamNum = GetEntProp(point, Prop_Send, "m_iTeamNum");
		if (m_iTeamNum == m_iTeam) {
			GetEntPropVector(point, Prop_Send, "m_vecOrigin", vecSpawn);
			if (CheckSpawnPoint(vecSpawn,client)) {
				InsLog(DEBUG,"FOUND! %N (%d) spawnpoint %d at (%f, %f, %f)", client, client, point, vecSpawn[0], vecSpawn[1], vecSpawn[2]);
				return vecSpawn;
			}
		}
		point = FindEntityByClassname(point, "ins_spawnpoint");
	}
	InsLog(DEBUG,"Could not find acceptable ins_spawnzone for %N (%d)", client, client);
	return vecOrigin;
}

public UpdatePlayerOrigins() {
	for (new i = 1; i < MaxClients; i++) {
		if (IsValidClient(i)) {
			GetClientAbsOrigin(i,g_vecOrigin[i]);
		}
	}
}

//This should be executed every time a point is taken, round starts, or any time a wave would be spawned.
RestartBotQueue() {
	//TODO: Kill all bots at this time?
	g_iBotsToSpawn = RoundToFloor(Float:Team_CountPlayers(bot_team) * g_flTotalSpawnFrac);
	InsLog(DEBUG,"Calling RestartBotQueue, TCP is %d TSF is %0.2f g_iBotsToSpawn is %d",Team_CountPlayers(bot_team),g_flTotalSpawnFrac,g_iBotsToSpawn);
}

//Move a bot to the queue. This will silently kill them and remove ragdoll.
public JoinQueue(client,bool:spawning)
{
	if (!g_bEnabled)
	{
		return;
	}
	if ((g_iInQueue[client]) || (g_iNeedSpawn[client]))
		return;
	InsLog(DEBUG, "called JoinQueue for %N (%d) g_iBotsToSpawn %d spawning %b",client,client,g_iBotsToSpawn,spawning);
	g_iInQueue[client] = 1;
	if (!spawning)
	{
		if (IsPlayerAlive(client))
		{
			ForcePlayerSuicide(client);
		}
	}
}

// Run this to begin the process of spawning a client
BeginSpawnClient(client,tokens=0,instant=0) {
	if (!g_bEnabled) {
		return;
	}
	g_iSpawnTokens[client]+=tokens;
	g_iNumReady++;
	g_iNeedSpawn[client] = 1;
	g_iInQueue[client] = 0;

	if (g_iBotsToSpawn) {
		g_iBotsToSpawn--;
	}
	new Float:flSpawnDelay = (instant) ? 0.1 : GetRandomFloat(g_flMinSpawnDelay,g_flMaxSpawnDelay);
	if (flSpawnDelay < 0.1) {
		flSpawnDelay = 0.1;
	}
	InsLog(DEBUG, "called BeginSpawnClient for %d flSpawnDelay %0.2f g_iBotsToSpawn %d g_iSpawnTokens %d",client,flSpawnDelay,g_iBotsToSpawn,g_iSpawnTokens[client]);
	if (!IsPlayerAlive(client))
		g_hSpawnTimer[client] = CreateTimer(flSpawnDelay, Timer_Spawn, client, TIMER_FLAG_NO_MAPCHANGE);
	else
		g_hSpawnTimer[client] = CreateTimer(flSpawnDelay, Timer_PostSpawn, client, TIMER_FLAG_NO_MAPCHANGE);
}

public UpdateBotCounters() {
	g_iBotsAlive = Team_CountAlivePlayers(bot_team);
	g_iBotsTotal = Team_CountPlayers(bot_team);
}

public SpawnAvailable() {
	//new iBotCountMin = RoundToFloor(Float:g_iBotsTotal * g_flMinFracInGame);
	new iBotCountMax = RoundToFloor(Float:g_iBotsTotal * g_flMaxFracInGame);
	return (
		((iBotCountMax > (g_iBotsAlive + g_iNumReady)) && 
		((g_iBotsAlive + g_iNumReady) < g_iBotsTotal)) && 
		((g_iBotsToSpawn) || (g_iBotsToSpawn < 0))
	);
}
public CanSpawnClient(client) {
	return ((IsValidClient(client)) && (GetClientTeam(client) == bot_team) && (IsFakeClient(client)) && (!IsPlayerAlive(client)) && (g_iInQueue[client]) && (!g_iNeedSpawn[client]));
}
//Loop every second, this keeps track of the bots and adds/removes them as needed.
public Action:Timer_ProcessQueue(Handle:timer) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}
	UpdateBotCounters();

//	new iStart = RoundToFloor(GetRandomFloat(0.0,1.0) * 64);
	for (new i = 1; i <= MaxClients; i++) {
		if (!SpawnAvailable()) {
			return Plugin_Continue;
		}
		if (CanSpawnClient(i)) {
			BeginSpawnClient(i,1);
		}
	}
	return Plugin_Continue;
}

//This timer actually spawns the bot
public Action:Timer_Spawn(Handle:timer, any:client)
{
	InsLog(DEBUG, "called Timer_Spawn for client %N (%d)",client,client);
	g_iSpawnTokens[client]--; //Remove one token
	SDKCall(g_hForceRespawn, client); //Perform respawn
	g_hSpawnTimer[client] = CreateTimer(0.1, Timer_PostSpawn, client, TIMER_FLAG_NO_MAPCHANGE); //Do the post-spawn stuff like moving to final "spawnpoint" selected
}

//Handle any work that needs to happen after the client is in the game
public Action:Timer_PostSpawn(Handle:timer, any:client)
{
	InsLog(DEBUG, "called Timer_PostSpawn for client %N (%d)",client,client);
	TeleportClient(client);
}
public TeleportClient(client) {
	g_iNeedSpawn[client] = 0;
	new Float:vecSpawn[3];
	vecSpawn = GetSpawnPoint(client);
	TeleportEntity(client, vecSpawn, NULL_VECTOR, NULL_VECTOR);
	g_hSpawnTimer[client] = INVALID_HANDLE;
}

float GetSpawnPoint(client) {
	new Float:vecSpawn[3];
	if ((g_iHidingSpotCount) && (g_iSpawnMode == _:SpawnMode_HidingSpots)) {
		vecSpawn = GetSpawnPoint_HidingSpot(client);
	} else {
		vecSpawn = GetSpawnPoint_SpawnPoint(client);
	}
	InsLog(DEBUG, "Could not find spawn point for %N (%d)", client, client);
	return vecSpawn;
}
public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!g_bEnabled) {
		return Plugin_Continue;
	}
	if (!IsFakeClient(client)) {
		return Plugin_Continue;
	}
	new Float:vecOrigin[3];
	GetClientAbsOrigin(client,vecOrigin);
	int iCanSpawn = CheckSpawnPoint(vecOrigin,client);
	InsLog(DEBUG, "Event_Spawn iCanSpawn %d", iCanSpawn);
	if (!iCanSpawn) {
		InsLog(DEBUG, "Teleporting %N (%d)", client, client);
		TeleportClient(client);
	}
	if (g_iSpawnMode) {
		if (!g_iInQueue[client])
			BeginSpawnClient(client,1,1);
		if (g_iSpawnTokens[client]) {
			TeleportClient(client);
		} else {
			JoinQueue(client,true);
		}
	}
	return Plugin_Continue;
}

public Action:Event_SpawnPost(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//InsLog(DEBUG, "Event_Spawn called");
	if (!g_bEnabled) {
		return Plugin_Continue;
	}
	if (!IsFakeClient(client)) {
		return Plugin_Continue;
	}
	SetNextAttack(client);
	return Plugin_Continue;
}

SetNextAttack(client) {
	float flTime = GetGameTime();
	float flDelay = GetConVarFloat(cvarSpawnAttackDelay);
//	InsLog(DEBUG, "SetNextAttack %f for %N (%d)",flDelay,client,client);
/*
	new weapons = GetEntDataEnt2(activator, m_hMyWeapons + (1 * 4));
	SetEntDataFloat(weapons, m_flNextPrimaryAttack,   time + flDelay);
	SetEntDataFloat(weapons, m_flNextSecondaryAttack, time + flDelay);
	new m_hMyWeapons = FindSendPropOffs("CINSPlayer", "m_hMyWeapons");
*/

// Loop through entries in m_hMyWeapons.
	for(new offset = 0; offset < 128; offset += 4) {
		new weapon = GetEntDataEnt2(client, m_hMyWeapons + offset);
		if (weapon < 0) {
			continue;
		}
//		InsLog(DEBUG, "SetNextAttack weapon %d", weapon);
		SetEntDataFloat(weapon, m_flNextPrimaryAttack, flTime + flDelay);
		SetEntDataFloat(weapon, m_flNextSecondaryAttack, flTime + flDelay);
	}
}

public Action:Event_RoundBegin(Handle:event, const String:name[], bool:dontBroadcast)
{
//	InsLog(DEBUG, "Calling Event_RoundBegin");
	RestartBotQueue();
	return Plugin_Continue;
}
public Action:Event_ControlPointCaptured(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled)
	{
		return Plugin_Continue;
	}
	RestartBotQueue();
	return Plugin_Continue;
}
public Action:Event_ControlPointStartTouch(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled)
	{
		return Plugin_Continue;
	}
	//TODO: Silently kill all bots that are not seen by a player

	//new area = GetEventInt(event, "area");
	//new object = GetEventInt(event, "object");
	//new player = GetEventInt(event, "player");
	//new team = GetEventInt(event, "team");
	//new owner = GetEventInt(event, "owner");
	//new type = GetEventInt(event, "type");
	//InsLog(DEBUG, "Event_ControlPointStartTouch: player %N area %d object %d player %d team %d owner %d type %d",player,area,object,player,team,owner,type);
	return Plugin_Continue;
}
public Action:Timer_RemoveRagdoll(Handle:timer, any:_iEntity)
{
	if (_iEntity < 0) {
		return Plugin_Continue;
	}
	if (!IsValidEntity(_iEntity)) {
		return Plugin_Continue;
	}
	AcceptEntityInput(_iEntity, "Kill");
	return Plugin_Continue;
}
public Action:Event_PlayerDeathPre(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled)
	{
		return Plugin_Continue;
	}
	//InsLog(DEBUG, "Calling Event_PlayerDeathPre");
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//If this client is in the queue (being killed so that they can wait for a 'proper' spawn), remove ragdoll and do not print death message.
	if (g_iInQueue[client]) {
		new _iEntity = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if(_iEntity > 0 && IsValidEdict(_iEntity))
		{
			//CreateTimer(0.1, Timer_RemoveRagdoll, _iEntity, TIMER_FLAG_NO_MAPCHANGE);
			RemoveEdict(_iEntity);
		}
		return Plugin_Continue;
	}
	//Join queue
	if (IsFakeClient(client))
	{
		JoinQueue(client,false);
	}
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled)
	{
		return Plugin_Continue;
	}
	//InsLog(DEBUG, "Calling Event_PlayerDeath");
	//"deathflags" "short"
	//"attacker" "short"
	//"customkill" "short"
	//"lives" "short"
	//"attackerteam" "short"
	//"damagebits" "short"
	//"weapon" "string"
	//"weaponid" "short"
	//"userid" "short"
	//"priority" "short"
	//"team" "short"
	//"y" "float"
	//"x" "float"
	//"z" "float"
	//"assister" "short"
	return Plugin_Continue;
}
