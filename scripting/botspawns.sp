//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>
#include <navmesh>
#undef REQUIRE_PLUGIN
#include <updater>
#include <insurgency>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "0.2.6"
#define PLUGIN_DESCRIPTION "Adds a number of options and ways to handle bot spawns"
#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-botspawns.txt"

new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?

new Handle:cvarSpawnMode = INVALID_HANDLE; //Spawn in hiding spots (1), any spawnpoints that meets criteria (2), or only at normal spawnpoints at next objective (0, standard spawning, default setting)
new Handle:cvarCounterattackMode = INVALID_HANDLE; //Use standard spawning for counterattack waves? Same values and default as above.
new Handle:cvarCounterattackFinaleInfinite = INVALID_HANDLE; //Infinite finale?
new Handle:cvarCounterattackFrac = INVALID_HANDLE; //Multiplier to total bots to take part in counterattack
new Handle:cvarMinCounterattackDistance = INVALID_HANDLE; //Min distance from counterattack objective to spawn
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
new Handle:cvarRespawnMode = INVALID_HANDLE; //Respawn killed bots only when all bots die (0, default) or respawn fireteams once the number drops enough to spawn a team (1)
new Handle:cvarStopSpawningAtObjective = INVALID_HANDLE; //Stop spawning new bots when near next objective (1, default)
new Handle:cvarRemoveUnseenWhenCapping = INVALID_HANDLE; //Silently kill off all unseen bots when capping next point (1, default)
new Handle:cvarSpawnSnipersAlone = INVALID_HANDLE; //Spawn snipers alone, maybe further out (1)?
new bool:g_bEnabled, g_iSpawnMode, g_iRespawnMode, g_iCounterattackMode, g_iCounterattackFinaleInfinite, Float:g_flCounterattackFrac, Float:g_flMinSpawnDelay, Float:g_flMaxSpawnDelay, Float:g_flMinPlayerDistance, Float:g_flMaxPlayerDistance, Float:g_flMinObjectiveDistance, Float:g_flMaxObjectiveDistance, Float:g_flMinFracInGame, Float:g_flMaxFracInGame, Float:g_flTotalSpawnFrac, g_iMinFireteamSize, g_iMaxFireteamSize, bool:g_bStopSpawningAtObjective, bool:g_bRemoveUnseenWhenCapping, bool:g_bSpawnSnipersAlone, Float:g_flMinCounterattackDistance;
//Until I add functionality


new Handle:g_hHidingSpots = INVALID_HANDLE;
#define MAX_OBJECTIVES 13
#define MAX_HIDING_SPOTS 2048
#define MIN_PLAYER_DISTANCE 128.0
new g_iCPHidingSpots[MAX_OBJECTIVES][MAX_HIDING_SPOTS];
new g_iCPHidingSpotCount[MAX_OBJECTIVES];
new g_iCPLastHidingSpot[MAX_OBJECTIVES];
new Float:m_vCPPositions[MAX_OBJECTIVES][3],m_iNumControlPoints;

new Handle:g_hPlayerRespawn;
new Handle:g_hGameConfig;
new Handle:g_hRespawnTimer[MAXPLAYERS+1];
new g_iHidingSpotCount;
new g_iBotsToSpawn, g_iSpawnTokens[MAXPLAYERS+1], g_iNumReady, g_iBotsAlive,g_iBotsTotal,g_iInQueue[MAXPLAYERS+1],g_iSpawning[MAXPLAYERS+1],Float:g_vecOrigin[MAXPLAYERS+1][3];
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
#pragma unused g_iRespawnMode

enum SpawnModes {
        SpawnMode_Normal = 0,
	SpawnMode_HidingSpots,
	SpawnMode_SpawnPoints,
};
enum RepawnModes {
        RepawnMode_None = 0,
        RepawnMode_Immediate,
        RepawnMode_Waves,
        RepawnMode_Fireteams,
};
public Plugin:myinfo = {
	name		= "[INS] Bot spawns",
	author  	= "Jared Ballou (jballou)",
	description 	= PLUGIN_DESCRIPTION,
	version 	= PLUGIN_VERSION,
	url 		= "http://jballou.com/"
};

public OnPluginStart()
{
	PrintToServer("[BOTSPAWNS] Starting up");
	cvarVersion = CreateConVar("sm_botspawns_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_botspawns_enabled", "0", "Enable enhanced bot spawning features", FCVAR_NOTIFY | FCVAR_PLUGIN);

	cvarSpawnMode = CreateConVar("sm_botspawns_spawn_mode", "0", "Only normal spawnpoints at the objective, the old way (0), spawn in hiding spots following rules (1), spawnpoints that meet rules (2)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarRespawnMode = CreateConVar("sm_botspawns_respawn_mode", "0", "Do not respawn (0), Respawn immediately as killed (1), Respawn killed bots as waves only when all bots are dead (2), Respawn fireteams once the number drops enough to spawn a team (3)", FCVAR_NOTIFY | FCVAR_PLUGIN);

	cvarCounterattackMode = CreateConVar("sm_botspawns_counterattack_mode", "0", "Do not alter default game spawning during counterattacks (0), Respawn using new rules during counterattack by following sm_botspawns_respawn_mode (1)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarCounterattackFinaleInfinite = CreateConVar("sm_botspawns_counterattack_finale_infinite", "0", "Obey sm_botspawns_counterattack_respawn_mode (0), use rules and do infinite respawns (1)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarCounterattackFrac = CreateConVar("sm_botspawns_counterattack_frac", "0.5", "Multiplier to total bots for spawning in counterattack wave", FCVAR_NOTIFY | FCVAR_PLUGIN);

	cvarMinCounterattackDistance = CreateConVar("sm_botspawns_min_counterattack_distance", "3600", "Min distance from counterattack objective to spawn", FCVAR_NOTIFY | FCVAR_PLUGIN);

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
	HookConVarChange(cvarRespawnMode,CvarChange);
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
	g_hPlayerRespawn = EndPrepSDKCall();
	if (g_hPlayerRespawn == INVALID_HANDLE)
	{
		SetFailState("Fatal Error: Unable to find signature for \"Respawn\"!");
	}
	HookEvent("player_spawn", Event_Spawn);
	HookEvent("round_begin", Event_RoundBegin);
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_pick_squad", Event_PlayerPickSquad);
	HookEvent("object_destroyed", Event_ObjectDestroyed);
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
	g_iRespawnMode = GetConVarInt(cvarRespawnMode);
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
	new String:sGameMode[32],String:sLogicEnt[64];
	GetConVarString(FindConVar("mp_gamemode"), sGameMode, sizeof(sGameMode));
	Format (sLogicEnt,sizeof(sLogicEnt),"logic_%s",sGameMode);
	PrintToServer("[BOTSPAWNS] gamemode %s logicent %s",sGameMode,sLogicEnt);
	if (!StrEqual(sGameMode,"checkpoint")) return;
	if (!NavMesh_Exists()) return;
	if (g_hHidingSpots == INVALID_HANDLE) g_hHidingSpots = NavMesh_GetHidingSpots();
	g_iHidingSpotCount = GetArraySize(g_hHidingSpots);

	m_iNumControlPoints = Ins_ObjectiveResource_GetProp("m_iNumControlPoints");
	PrintToServer("[BOTSPAWNS] m_iNumControlPoints %d",m_iNumControlPoints);
	for (new i = 0; i < m_iNumControlPoints; i++)
	{
		Ins_ObjectiveResource_GetPropVector("m_vCPPositions",m_vCPPositions[i],i);
		PrintToServer("[BOTSPAWNS] i %d (%f,%f,%f)",i,m_vCPPositions[i][0],m_vCPPositions[i][1],m_vCPPositions[i][2]);
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
		PrintToServer("[BOTSPAWNS] Found hiding count: a %d b %d c %d d %d e %d f %d g %d h %d i %d j %d k %d l %d m %d",g_iCPHidingSpotCount[0],g_iCPHidingSpotCount[1],g_iCPHidingSpotCount[2],g_iCPHidingSpotCount[3],g_iCPHidingSpotCount[4],g_iCPHidingSpotCount[5],g_iCPHidingSpotCount[6],g_iCPHidingSpotCount[7],g_iCPHidingSpotCount[8],g_iCPHidingSpotCount[9],g_iCPHidingSpotCount[10],g_iCPHidingSpotCount[11],g_iCPHidingSpotCount[12]);
	}
	RestartBotQueue();
	return;
}
CheckHidingSpotRules(m_nActivePushPointIndex,iCPHIndex,iSpot,client)
{
	new m_iTeam = GetClientTeam(client);
	new Float:distance,Float:furthest,Float:closest=-1.0,Float:flHidingSpot[3];
	new Float:vecOrigin[3];

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
			if ((distance < g_flMinPlayerDistance) || ((IsVectorInSightRange(iTarget, flHidingSpot, 120.0)) && (ClientCanSeeVector(iTarget, flHidingSpot, g_flMaxPlayerDistance))))
			{
				PrintToServer("[BOTSPAWNS] Cannot spawn %N at iSpot %d since it is in sight of %N",client,iSpot,iTarget);
				return 0;
			}
		}
		if (distance < MIN_PLAYER_DISTANCE)
		{
			PrintToServer("[BOTSPAWNS] Distance too small from %N to iSpot %d distance %f",iTarget,iSpot,distance);
			return 0;
		}
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
//This should be executed every time a point is taken, round starts, or any time a wave would be spawned.
RestartBotQueue()
{
	//TODO: Kill all bots at this time?
	g_iBotsToSpawn = RoundToFloor(Float:Team_CountPlayers(bot_team) * g_flTotalSpawnFrac);
	PrintToServer("[BOTSPAWNS] Calling RestartBotQueue, TCP is %d TSF is %0.2f g_iBotsToSpawn is %d",Team_CountPlayers(bot_team),g_flTotalSpawnFrac,g_iBotsToSpawn);
}

//Move a bot to the queue. This will silently kill them and remove ragdoll.
public JoinQueue(client,bool:spawning)
{
	if (!g_bEnabled)
	{
		return;
	}
	if ((g_iInQueue[client]) || (g_iSpawning[client]))
		return;
	PrintToServer("[BOTSPAWNS] called JoinQueue for %N (%d) g_iBotsToSpawn %d spawning %b",client,client,g_iBotsToSpawn,spawning);
	g_iInQueue[client] = 1;
	if (!spawning)
	{
		if (IsPlayerAlive(client))
		{
			ForcePlayerSuicide(client);
		}
	}
}
//Run this to mark a bot as ready to spawn. Add tokens if you want them to be able to spawn.
PreSpawn(client,tokens=0,instant=0)
{
	if (!g_bEnabled)
	{
		return;
	}
	g_iSpawnTokens[client]+=tokens;
	g_iNumReady++;
	g_iSpawning[client] = 1;
	g_iInQueue[client] = 0;

	if (g_iBotsToSpawn)
	{
		g_iBotsToSpawn--;
	}
	new Float:fSpawnDelay = (instant) ? 0.1 : GetRandomFloat(g_flMinSpawnDelay,g_flMaxSpawnDelay);
	if (fSpawnDelay < 0.1)
	{
		fSpawnDelay = 0.1;
	}
	PrintToServer("[BOTSPAWNS] called PreSpawn for %d fSpawnDelay %0.2f g_iBotsToSpawn %d g_iSpawnTokens %d",client,fSpawnDelay,g_iBotsToSpawn,g_iSpawnTokens[client]);
	if (!IsPlayerAlive(client))
		g_hRespawnTimer[client] = CreateTimer(fSpawnDelay, Timer_Spawn, client, TIMER_FLAG_NO_MAPCHANGE);
	else
		g_hRespawnTimer[client] = CreateTimer(fSpawnDelay, Timer_PostSpawn, client, TIMER_FLAG_NO_MAPCHANGE);
}

//Loop every second, this keeps track of the bots and adds/removes them as needed.
public Action:Timer_ProcessQueue(Handle:timer)
{
	if (!g_bEnabled)
	{
		return;
	}
	g_iBotsAlive = Team_CountAlivePlayers(bot_team);
	g_iBotsTotal = Team_CountPlayers(bot_team);

//	new iStart = RoundToFloor(GetRandomFloat(0.0,1.0) * 64);
//	new iBotCountMin = RoundToFloor(Float:g_iBotsTotal * g_flMinFracInGame);
	new iBotCountMax = RoundToFloor(Float:g_iBotsTotal * g_flMaxFracInGame);
	//If we need to spawn bots, hand out tokens
	//new g_iBotsToSpawn
	if (
		((iBotCountMax > (g_iBotsAlive + g_iNumReady)) && 
		((g_iBotsAlive + g_iNumReady) < g_iBotsTotal)) && 
		((g_iBotsToSpawn) || (g_iBotsToSpawn < 0))
	)
	{
		for (new i = 1; i <= MaxClients; i++) {
			if (((iBotCountMax > (g_iBotsAlive + g_iNumReady)) && ((g_iBotsAlive + g_iNumReady) < g_iBotsTotal)) && ((g_iBotsToSpawn) || (g_iBotsToSpawn < 0)))
			{
				if ((IsValidClient(i)) && (GetClientTeam(i) == bot_team) && (IsFakeClient(i)) && (!IsPlayerAlive(i)) && (g_iInQueue[i]) && (!g_iSpawning[i]))
				{
					PreSpawn(i,1);
				}
			}
		}
	}
	
}

//This timer actually spawns the bot
public Action:Timer_Spawn(Handle:timer, any:client)
{
	PrintToServer("[BOTSPAWNS] called Timer_Spawn for client %N (%d)",client,client);
	g_iSpawnTokens[client]--; //Remove one token
	SDKCall(g_hPlayerRespawn, client); //Perform respawn
	g_hRespawnTimer[client] = CreateTimer(0.1, Timer_PostSpawn, client, TIMER_FLAG_NO_MAPCHANGE); //Do the post-spawn stuff like moving to final "spawnpoint" selected
}

//Handle any work that needs to happen after the client is in the game
public Action:Timer_PostSpawn(Handle:timer, any:client)
{
	PrintToServer("[BOTSPAWNS] called Timer_PostSpawn for client %N (%d)",client,client);
	g_iSpawning[client] = 0;
	if ((g_iHidingSpotCount) && (g_iSpawnMode == _:SpawnMode_HidingSpots))
	{
		new Float:flHidingSpot[3],Float:vecOrigin[3];
		new iSpot = GetBestHidingSpot(client);
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
	g_hRespawnTimer[client] = INVALID_HANDLE;
}

public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//PrintToServer("[BOTSPAWNS] Event_Spawn called");
	if (!g_bEnabled)
	{
		return Plugin_Continue;
	}
	if (g_iSpawnMode)
	{
		if (IsFakeClient(client))
		{
			if (!g_iInQueue[client])
				PreSpawn(client,1,1);
/*
			if (g_iSpawnTokens[client])
			{
				PreSpawn(client);
			}
			else
			{
				JoinQueue(client,1);
			}
*/
		}
	}
	return Plugin_Continue;
}

public Action:Event_RoundBegin(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToServer("[BOTSPAWNS] Calling Event_RoundBegin");
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
/*
	//"priority" "short"
	//"cp" "byte"
	//"cappers" "string"
	//"cpname" "string"
	//"team" "byte"
	decl String:cappers[256],String:cpname[64];
	//new priority = GetEventInt(event, "priority");
	new cp = GetEventInt(event, "cp");
	GetEventString(event, "cappers", cappers, sizeof(cappers));
	GetEventString(event, "cpname", cpname, sizeof(cpname));
	new team = GetEventInt(event, "team");
	new capperlen = GetCharBytes(cappers);
	PrintToServer("[LOGGER] Event_ControlPointCaptured cp %d capperlen %d cpname %s team %d", cp,capperlen,cpname,team);

	//"cp" "byte" - for naming, currently not needed
	for (new i = 0; i < strlen(cappers); i++)
	{
		new client = cappers[i];
		PrintToServer("[LOGGER] Event_ControlPointCaptured parsing capper id %d client %d",i,client);
		if(client > 0 && client <= MaxClients && IsClientInGame(client))
		{
			decl String:player_authid[64];
			if (!GetClientAuthString(client, player_authid, sizeof(player_authid)))
			{
				strcopy(player_authid, sizeof(player_authid), "UNKNOWN");
			}
			new player_userid = GetClientUserId(client);
			new player_team_index = GetClientTeam(client);
			LogToGame("\"%N<%d><%s><%s>\" triggered \"ins_cp_captured\"", client, player_userid, player_authid, g_team_list[player_team_index]);
		}
	}
*/
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
	//PrintToServer("[LOGGER] Event_ControlPointStartTouch: player %N area %d object %d player %d team %d owner %d type %d",player,area,object,player,team,owner,type);
	return Plugin_Continue;
}
public Action:Timer_RemoveRagdoll(Handle:timer, any:_iEntity)
{
	AcceptEntityInput(_iEntity, "Kill");
}
public Action:Event_PlayerDeathPre(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled)
	{
		return Plugin_Continue;
	}
	//PrintToServer("[BOTSPAWNS] Calling Event_PlayerDeathPre");
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//If this client is in the queue (being killed so that they can wait for a 'proper' spawn), remove ragdoll and do not print death message.
	if (g_iInQueue[client])
	{
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
	//PrintToServer("[BOTSPAWNS] Calling Event_PlayerDeath");
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
public Action:Event_ObjectDestroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled)
	{
		return Plugin_Continue;
	}
	PrintToServer("[BOTSPAWNS] Calling Event_ObjectDestroyed");
	RestartBotQueue();
/*
	decl String:attacker_authid[64],String:assister_authid[64],String:classname[64];
	//"team" "byte"
	//"attacker" "byte"
	//"cp" "short"
	//"index" "short"
	//"type" "byte"
	//"weapon" "string"
	//"weaponid" "short"
	//"assister" "byte"
	//"attackerteam" "byte"
	new team = GetEventInt(event, "team");
	new attacker = GetEventInt(event, "attacker");
	new attackerteam = GetEventInt(event, "attackerteam");
	new cp = GetEventInt(event, "cp");
	new index = GetEventInt(event, "index");
	new type = GetEventInt(event, "type");
	new weaponid = GetEventInt(event, "weaponid");
	new assister = GetEventInt(event, "assister");
	new assister_userid = -1;
	new attacker_userid = -1;
	new assisterteam = -1;
	if (index)
	{
		GetEdictClassname(index, classname, sizeof(classname));
	}
	if ((assister) && (assister != attacker))
	{
		assister_userid = GetClientUserId(assister);
		if (assister_userid)
		{
			assisterteam = GetClientTeam(assister);
			if (!GetClientAuthString(assister, assister_authid, sizeof(assister_authid)))
			{
				strcopy(assister_authid, sizeof(assister_authid), "UNKNOWN");
			}
			LogToGame("\"%N<%d><%s><%s>\" triggered \"ins_cp_destroyed\"", assister, assister_userid, assister_authid, g_team_list[assisterteam]);
		}
	}

	if (attacker)
	{
		attacker_userid = GetClientUserId(attacker);
		if (!GetClientAuthString(attacker, attacker_authid, sizeof(attacker_authid)))
		{
			strcopy(attacker_authid, sizeof(attacker_authid), "UNKNOWN");
		}
		LogToGame("\"%N<%d><%s><%s>\" triggered \"ins_cp_destroyed\"", attacker, attacker_userid, attacker_authid, g_team_list[attackerteam]);
	}
	PrintToServer("[LOGGER] Event_ObjectDestroyed: team %d attacker %d attacker_userid %d cp %d classname %s index %d type %d weaponid %d assister %d assister_userid %d attackerteam %d",team,attacker,attacker_userid,cp,classname,index,type,weaponid,assister,assister_userid,attackerteam);
*/
	return Plugin_Continue;
}

public Action:Event_PlayerPickSquad(Handle:event, const String:name[], bool:dontBroadcast)
{
/*
	//"squad_slot" "byte"
	//"squad" "byte"
	//"userid" "short"
	//"class_template" "string"
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	//new squad = GetEventInt( event, "squad" );
	//new squad_slot = GetEventInt( event, "squad_slot" );
	decl String:class_template[64];
	GetEventString(event, "class_template",class_template,sizeof(class_template));
	ReplaceString(class_template,sizeof(class_template),"template_","",false);
	ReplaceString(class_template,sizeof(class_template),"_training","",false);
	ReplaceString(class_template,sizeof(class_template),"_coop","",false);
	ReplaceString(class_template,sizeof(class_template),"coop_","",false);
	ReplaceString(class_template,sizeof(class_template),"_security","",false);
	ReplaceString(class_template,sizeof(class_template),"_insurgent","",false);
	ReplaceString(class_template,sizeof(class_template),"_survival","",false);


	//PrintToServer("[LOGGER] squad: %d squad_slot: %d class_template: %s",squad,squad_slot,class_template);

	if( client == 0)
		return Plugin_Continue;
	if(!StrEqual(g_client_last_classstring[client],class_template)) {
		LogRoleChange( client, class_template );
		g_client_last_classstring[client] = class_template;
	}
*/
	return Plugin_Continue;
}
