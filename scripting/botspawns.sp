//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>
#include <navmesh>
#undef REQUIRE_PLUGIN
#include <updater>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "0.1.0"
#define PLUGIN_DESCRIPTION "Adds a number of options and ways to handle bot spawns"
#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-botspawns.txt"

new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?

new Handle:cvarSpawnMode = INVALID_HANDLE; //Spawn in hiding spots (1), any spawnpoints that meets criteria (2), or only at normal spawnpoints at next objective (0, standard spawning, default setting)
new Handle:cvarCounterattackMode = INVALID_HANDLE; //Use standard spawning for counterattack waves? Same values and default as above.
new Handle:cvarCounterattackFrac = INVALID_HANDLE; //Multiplier to total bots to take part in counterattack
new Handle:cvarMinSpawnDelay = INVALID_HANDLE; //Min delay for spawning. Set to 0 for instant.
new Handle:cvarMaxSpawnDelay = INVALID_HANDLE; //Max delay for spawning. Set to 0 for instant.
new Handle:cvarSpawnSides = INVALID_HANDLE; //Spawn bots to the sides of the players when facing the next objective?
new Handle:cvarSpawnRear = INVALID_HANDLE; //Spawn bots to the rear of pthe players when facing the next objective?
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

//Until I add functionality
#pragma unused cvarCounterattackFrac
#pragma unused cvarCounterattackMode
#pragma unused cvarMaxFireteamSize
#pragma unused cvarMaxObjectiveDistance
#pragma unused cvarMaxPlayerDistance
#pragma unused cvarMinFireteamSize
#pragma unused cvarMinFracInGame
#pragma unused cvarMinObjectiveDistance
#pragma unused cvarMinPlayerDistance
#pragma unused cvarRemoveUnseenWhenCapping
#pragma unused cvarRespawnMode
#pragma unused cvarSpawnRear
#pragma unused cvarSpawnSides
#pragma unused cvarSpawnSnipersAlone
#pragma unused cvarStopSpawningAtObjective

new Handle:g_hHidingSpots = INVALID_HANDLE;
new Handle:g_hPlayerRespawn;
new Handle:g_hGameConfig;
new Handle:g_hRespawnTimer[MAXPLAYERS];
new g_iHidingSpotCount;
new g_iBotsToSpawn, g_iSpawnTokens[MAXPLAYERS], g_iNumReady, g_iBotsAlive,g_iBotsTotal,g_iInQueue[MAXPLAYERS];
new bot_team = 3;

public Plugin:myinfo = {
	name= "[INS] Bot spawns",
	author  = "Jared Ballou (jballou)",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com/"
};

public OnPluginStart()
{
	PrintToServer("[BOTSPAWNS] Starting up");
	cvarVersion = CreateConVar("sm_botspawns_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_botspawns_enabled", "0", "Enable enhanced bot spawning features", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarSpawnMode = CreateConVar("sm_botspawns_spawn_mode", "1", "Spawn in hiding spots (1), any spawnpoints that meets criteria (2), or only at normal spawnpoints at next objective (0, standard spawning, default setting)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarCounterattackMode = CreateConVar("sm_botspawns_counterattack_mode", "1", "Use standard spawning for final counterattack waves (0), hiding spots (1) or any spawnpoint (2)?", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarCounterattackFrac = CreateConVar("sm_botspawns_counterattack_frac", "0.5", "Multiplier to total bots for spawning in counterattack wave", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarMinSpawnDelay = CreateConVar("sm_botspawns_min_spawn_delay", "1", "Min delay in seconds for spawning. Set to 0 for instant.", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarMaxSpawnDelay = CreateConVar("sm_botspawns_max_spawn_delay", "15", "Max delay in seconds for spawning. Set to 0 for instant.", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarSpawnSides = CreateConVar("sm_botspawns_spawn_sides", "1", "Spawn bots to the sides of the players when facing the next objective?", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarSpawnRear = CreateConVar("sm_botspawns_spawn_rear", "1", "Spawn bots to the rear of pthe players when facing the next objective?", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarMinPlayerDistance = CreateConVar("sm_botspawns_min_player_distance", "360", "Min distance from players to spawn", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarMaxPlayerDistance = CreateConVar("sm_botspawns_max_player_distance", "16000", "Max distance from players to spawn", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarMinObjectiveDistance = CreateConVar("sm_botspawns_min_objective_distance", "1", "Min distance from next objective to spawn", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarMaxObjectiveDistance = CreateConVar("sm_botspawns_max_objective_distance", "12000", "Max distance from next objective to spawn", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarMinFracInGame = CreateConVar("sm_botspawns_min_frac_in_game", "0.75", "Min multiplier of bot quota to have alive at any time. Set to 1 to emulate standard spawning.", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarMaxFracInGame = CreateConVar("sm_botspawns_max_frac_in_game", "1", "Max multiplier of bot quota to have alive at any time. Set to 1 to emulate standard spawning.", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarTotalSpawnFrac = CreateConVar("sm_botspawns_total_spawn_frac", "1.75", "Total number of bots to spawn as multiple of number of bots in game to simulate larger numbers. 1 is standard, values less than 1 are not supported.", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarMinFireteamSize = CreateConVar("sm_botspawns_min_fireteam_size", "3", "Min number of bots to spawn per fireteam. Default 3", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarMaxFireteamSize = CreateConVar("sm_botspawns_max_fireteam_size", "5", "Max number of bots to spawn per fireteam. Default 5", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarRespawnMode = CreateConVar("sm_botspawns_respawn_mode", "1", "Respawn killed bots only when all bots die (0) or respawn fireteams once the number drops enough to spawn a team (1)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarStopSpawningAtObjective = CreateConVar("sm_botspawns_stop_spawning_at_objective", "1", "Stop spawning new bots when near next objective (1, default)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarRemoveUnseenWhenCapping = CreateConVar("sm_botspawns_remove_unseen_when_capping", "1", "Silently kill off all unseen bots when capping next point (1, default)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarSpawnSnipersAlone = CreateConVar("sm_botspawns_spawn_snipers_alone", "1", "Spawn snipers alone, can be 50% further from the objective than normal bots if this is enabled?", FCVAR_NOTIFY | FCVAR_PLUGIN);

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
	OnMapStart();
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

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}
public OnMapStart()
{
	new String:sGameMode[32],String:sLogicEnt[64];
	GetConVarString(FindConVar("mp_gamemode"), sGameMode, sizeof(sGameMode));
	Format (sLogicEnt,sizeof(sLogicEnt),"logic_%s",sGameMode);
	PrintToServer("[BOTSPAWNS] gamemode %s logicent %s",sGameMode,sLogicEnt);
	if (!StrEqual(sGameMode,"checkpoint")) return;
	if (!NavMesh_Exists()) return;
	if (g_hHidingSpots == INVALID_HANDLE) g_hHidingSpots = NavMesh_GetHidingSpots();
	g_iHidingSpotCount = GetArraySize(g_hHidingSpots);
	return;
}

//This should be executed every time a point is taken, round starts, or any time a wave would be spawned.
RestartBotQueue()
{
	//TODO: Kill all bots at this time?
	g_iBotsToSpawn = RoundToFloor(Team_CountPlayers(bot_team) * GetConVarFloat(cvarTotalSpawnFrac));
	PrintToServer("[BOTSPAWNS] Calling RestartBotQueue, TCP is %d TSF is %0.2f g_iBotsToSpawn is %d",Team_CountPlayers(bot_team),GetConVarFloat(cvarTotalSpawnFrac),g_iBotsToSpawn);
}

//Move a bot to the queue. This will silently kill them and remove ragdoll.
public JoinQueue(client)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return;
	}
	PrintToServer("[BOTSPAWNS] called JoinQueue for %d",client);
	g_iInQueue[client] = 1;
	if (IsPlayerAlive(client))
	{
		ForcePlayerSuicide(client);
	}
}
//Run this to mark a bot as ready to spawn. Add tokens if you want them to be able to spawn.
PreSpawn(client,tokens=0)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return;
	}
	PrintToServer("[BOTSPAWNS] called PreSpawn for %d",client);
	g_iSpawnTokens[client]+=tokens;
	g_iNumReady++;
	if (g_iBotsToSpawn)
	{
		g_iBotsToSpawn--;
	}
	new Float:fSpawnDelay = GetRandomFloat(GetConVarFloat(cvarMinSpawnDelay),GetConVarFloat(cvarMaxSpawnDelay));
	if (fSpawnDelay < 0.1)
	{
		fSpawnDelay = 0.1;
	}
	g_hRespawnTimer[client] = CreateTimer(fSpawnDelay, Timer_Spawn, client);
}

//Loop every second, this keeps track of the bots and adds/removes them as needed.
public Action:Timer_ProcessQueue(Handle:timer)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return;
	}
	g_iBotsAlive = Team_CountAlivePlayers(bot_team);
	g_iBotsTotal = Team_CountPlayers(bot_team);
//	new iStart = RoundToFloor(GetRandomFloat(0.0,1.0) * 64);
//	new iBotCountMin = RoundToFloor(Float:g_iBotsTotal * GetConVarFloat(cvarMinFracInGame));
	new iBotCountMax = RoundToFloor(Float:g_iBotsTotal * GetConVarFloat(cvarMaxFracInGame));
	//If we need to spawn bots, hand out tokens
	if (((iBotCountMax > (g_iBotsAlive + g_iNumReady)) && ((g_iBotsAlive + g_iNumReady) < g_iBotsTotal)) && ((g_iBotsToSpawn) || (g_iBotsToSpawn < 0)))
	{
		for (new i = 1; i <= MaxClients; i++) {
			if (((iBotCountMax > (g_iBotsAlive + g_iNumReady)) && ((g_iBotsAlive + g_iNumReady) < g_iBotsTotal)) && ((g_iBotsToSpawn) || (g_iBotsToSpawn < 0)))
			{
				if ((IsValidClient(i)) && (GetClientTeam(i) == bot_team) && (IsFakeClient(i)) && (!IsPlayerAlive(i)))
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
	g_iSpawnTokens[client]--; //Remove one token
	SDKCall(g_hPlayerRespawn, client); //Perform respawn
	g_hRespawnTimer[client] = CreateTimer(0.1, Timer_PostSpawn, client); //Do the post-spawn stuff like moving to final "spawnpoint" selected
	g_iInQueue[client] = 0; //No longer queued
}

//Handle any work that needs to happen after the client is in the game
public Action:Timer_PostSpawn(Handle:timer, any:client)
{
	if (g_hHidingSpots == INVALID_HANDLE) return;
	if (g_iHidingSpotCount)
	{
/*
		for (new iIndex = 0, iSize = g_iHidingSpotCount; iIndex < iSize; iIndex++)
		{
			new Float:flHidingSpot[3];//, iHidingSpotFlags;
			flHidingSpot[0] = GetArrayCell(g_hHidingSpots, iIndex, NavMeshHidingSpot_X);
			flHidingSpot[1] = GetArrayCell(g_hHidingSpots, iIndex, NavMeshHidingSpot_Y);
			flHidingSpot[2] = GetArrayCell(g_hHidingSpots, iIndex, NavMeshHidingSpot_Z);
			iHidingSpotFlags = GetArrayCell(g_hHidingSpots, iIndex, NavMeshHidingSpot_Flags);
			PrintToServer("[BOTSPAWNS] Found hiding spot %d at %f,%f,%f flags %d",iIndex,flHidingSpot[0],flHidingSpotY,flHidingSpotZ,iHidingSpotFlags);
		}
*/
	}
//	TeleportEntity(client, flHidingSpot, NULL_VECTOR, NULL_VECTOR);
	g_hRespawnTimer[client] = INVALID_HANDLE;
}

/* Returns True if the client is an ingame player, False otherwise.
 * Checks are performed in the order least likely to spew an error.
 *
 * @return                  If the client is a valid client.
 */
stock bool:IsValidClient(client) {

  return (client > 0 && client <= MaxClients &&
    IsClientConnected(client) && IsClientInGame(client) &&
    !IsClientReplay(client) && !IsClientSourceTV(client));

}

/**
 * Counts the players in a team, alive or dead.
 *
 * @param team             Team index.
 * @return                 Number of players.
 */
stock Team_CountPlayers(team) {

  new count = 0;
  for (new i = 1; i <= MaxClients; i++) {
    if (IsValidClient(i) && GetClientTeam(i) == team) {
      count++;
    }
  }
  return count;

}

/**
 * Counts the number of living players in a team.
 *
 * @param team             Team index.
 * @return                 Number of living players.
 */
stock Team_CountAlivePlayers(team) {

   new count = 0;
   for (new i = 1; i <= MaxClients; i++) {
     if (IsValidClient(i) && GetClientTeam(i) == team && IsPlayerAlive(i)) {
       count++;
     }
   }
   return count;

 }
public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_iInQueue[client] = 0;
	//PrintToServer("[BOTSPAWNS] Event_Spawn called");
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	if (GetConVarFloat(cvarSpawnMode))
	{
		if (IsFakeClient(client))
		{
			if (g_iSpawnTokens[client])
			{
				PreSpawn(client);
			}
			else
			{
				JoinQueue(client);
			}
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
	if (!GetConVarBool(cvarEnabled))
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
	if (!GetConVarBool(cvarEnabled))
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
	if (!GetConVarBool(cvarEnabled))
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
			//CreateTimer(0.1, Timer_RemoveRagdoll, _iEntity);
			RemoveEdict(_iEntity);
		}
		return Plugin_Stop;
	}
	//Join queue
	if (IsFakeClient(client))
	{
		JoinQueue(client);
	}
	return Plugin_Continue;
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return true;
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
	return true;
}
public Action:Event_ObjectDestroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
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

public Event_PlayerPickSquad(Handle:event, const String:name[], bool:dontBroadcast)
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
		return;
	if(!StrEqual(g_client_last_classstring[client],class_template)) {
		LogRoleChange( client, class_template );
		g_client_last_classstring[client] = class_template;
	}
*/
	return true;
}
