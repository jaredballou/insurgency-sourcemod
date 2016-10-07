//Depends: insurgency
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <insurgency>

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#include <tf2>
#include <tf2_stocks>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_DESCRIPTION "Respawn players"
#define PLUGIN_NAME "[INS] Player Respawn"
#define PLUGIN_URL "http://jballou.com/insurgency"
#define PLUGIN_VERSION "1.9.0"
#define PLUGIN_WORKING "1"

public Plugin:myinfo = {
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url		= PLUGIN_URL
};

new Handle:hAdminMenu = INVALID_HANDLE;
new Handle:g_hPlayerRespawn;
new Handle:g_hGameConfig;
new Handle:g_hRespawnTimer[MAXPLAYERS+1] = INVALID_HANDLE;
new g_bHasClass[MAXPLAYERS+1];


// This will be used for checking which team the player is on before repsawning them
#define SPECTATOR_TEAM	0
#define TEAM_SPEC 	1
#define TEAM_1		2
#define TEAM_2		3

new bool:TF2 = false;

new Handle:sm_respawn_enabled = INVALID_HANDLE;
new Handle:sm_respawn_auto = INVALID_HANDLE;
new Handle:sm_respawn_delay = INVALID_HANDLE;
new Handle:sm_respawn_count = INVALID_HANDLE;
new Handle:sm_respawn_counterattack = INVALID_HANDLE;
new Handle:sm_respawn_final_counterattack = INVALID_HANDLE;
new Handle:sm_respawn_count_team2 = INVALID_HANDLE;
new Handle:sm_respawn_count_team3 = INVALID_HANDLE;
new Handle:sm_respawn_reset_each_round = INVALID_HANDLE;
new Handle:sm_respawn_reset_each_objective = INVALID_HANDLE;

new g_iSpawnTokens[MAXPLAYERS];
new g_iRespawnCount[4];


public OnPluginStart()
{
	decl String:gamemod[40];
	GetGameFolderName(gamemod, sizeof(gamemod));
	
	if(StrEqual(gamemod, "tf"))
	{
		TF2 = true;
	}

	CreateConVar("sm_respawn_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	sm_respawn_enabled = CreateConVar("sm_respawn_enabled", PLUGIN_WORKING, "Enable respawn plugin");
	sm_respawn_auto = CreateConVar("sm_respawn_auto", "0", "Automatically respawn players when they die; 0 - disabled, 1 - enabled");
	sm_respawn_delay = CreateConVar("sm_respawn_delay", "1.0", "How many seconds to delay the respawn");
	sm_respawn_counterattack = CreateConVar("sm_respawn_counterattack", "0", "Respawn during counterattack? (0: no, 1: yes, 2: infinite)");
	sm_respawn_final_counterattack = CreateConVar("sm_respawn_final_counterattack", "0", "Respawn during final counterattack? (0: no, 1: yes, 2: infinite)");
	sm_respawn_count = CreateConVar("sm_respawn_count", "0", "Respawn all players this many times");
	sm_respawn_count_team2 = CreateConVar("sm_respawn_count_team2", "-1", "Respawn all Team 2 players this many times");
	sm_respawn_count_team3 = CreateConVar("sm_respawn_count_team3", "-1", "Respawn all Team 3 players this many times");
	sm_respawn_reset_each_round = CreateConVar("sm_respawn_reset_each_round", "1", "Reset player respawn counts each round");
	sm_respawn_reset_each_objective = CreateConVar("sm_respawn_reset_each_objective", "1", "Reset player respawn counts each objective");
	RegAdminCmd("sm_respawn", Command_Respawn, ADMFLAG_SLAY, "sm_respawn <#userid|name>");

	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_start", Event_RoundStart);

	HookEvent("player_pick_squad", Event_PlayerPickSquad);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);

	HookEvent("object_destroyed", Event_ObjectDestroyed);
	HookEvent("controlpoint_captured", Event_ControlPointCaptured);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Pre);

	HookConVarChange(sm_respawn_enabled, EnableChanged);
	//HookConVarChange(sm_respawn_auto, EnableChanged);
	HookConVarChange(sm_respawn_count, UpdateRespawnCountConVar);
	HookConVarChange(sm_respawn_count_team2, UpdateRespawnCountConVar);
	HookConVarChange(sm_respawn_count_team3, UpdateRespawnCountConVar);
	HookConVarChange(sm_respawn_reset_each_round, UpdateRespawnCountConVar);
	HookConVarChange(sm_respawn_reset_each_objective, UpdateRespawnCountConVar);
	HookConVarChange(FindConVar("sv_tags"), TagsChanged);

	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}

	decl String:game[40];
	GetGameFolderName(game, sizeof(game));
	if (StrEqual(game, "dod") || StrEqual(game, "insurgency") || StrEqual(game, "doi")) {
		PrintToServer("[RESPAWN] Starting OnPluginLoad stuff");
		// Next 14 lines of text are taken from Andersso's DoDs respawn plugin. Thanks :)
		g_hGameConfig = LoadGameConfigFile("plugin.respawn");

		if (g_hGameConfig == INVALID_HANDLE) {
			SetFailState("Fatal Error: Missing File \"plugin.respawn\"!");
		}

		StartPrepSDKCall(SDKCall_Player);
		if (StrEqual(game, "dod")) {
			PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Signature, "DODRespawn");
		}
		if (StrEqual(game, "insurgency")) {
			PrintToServer("[RESPAWN] ForceRespawn for Insurgency");
			PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Signature, "ForceRespawn");
		}
		if (StrEqual(game, "doi")) {
			PrintToServer("[RESPAWN] ForceRespawn for DoI");
			PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Virtual, "ForceRespawn");
		}
		g_hPlayerRespawn = EndPrepSDKCall();

		if (g_hPlayerRespawn == INVALID_HANDLE)
		{
			SetFailState("Fatal Error: Unable to find signature for \"Respawn\"!");
		}
	}

	LoadTranslations("common.phrases");
	LoadTranslations("respawn.phrases");
	AutoExecConfig(true, "respawn");
	HookUpdater();
}

public OnMapStart()
{
	UpdateRespawnCount();
	TF2_IsArenaMap(true);
	SetPlayerSpawns();
}

public OnConfigsExecuted()
{
	if (GetConVarBool(sm_respawn_enabled))
		TagsCheck("respawntimes");
	else
		TagsCheck("respawntimes", true);
}
public Action:Event_PlayerConnect(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0 && IsClientInGame(client)) {
		KillRespawnTimer(client);
	}
	g_bHasClass[client] = 0;
	return Plugin_Continue;
}
public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0 && IsClientInGame(client)) {
		KillRespawnTimer(client);
	}
	g_bHasClass[client] = 0;
	return Plugin_Continue;
}

public Action:Event_PlayerSpawn( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	KillRespawnTimer(client);
	return Plugin_Continue;
}

public Action:Event_PlayerFirstSpawn( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	g_bHasClass[client] = 1;
	return Plugin_Continue;
}

public Action:Command_Respawn(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_respawn <#userid|name>");
		return Plugin_Handled;
	}

	new String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients], target_count, bool:tn_is_ml;

	target_count = ProcessTargetString(
					arg,
					client,
					target_list,
					MaxClients,
					COMMAND_FILTER_DEAD,
					target_name,
					sizeof(target_name),
					tn_is_ml);


	if(target_count <= COMMAND_TARGET_NONE) 	// If we don't have dead players
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	// Team filter dead players, re-order target_list array with new_target_count
	new target, team, new_target_count;

	for (new i = 0; i < target_count; i++)
	{
		target = target_list[i];
		team = GetClientTeam(target);

		if(team >= 2) {
			target_list[new_target_count] = target; // re-order
			new_target_count++;
		}
	}

	if(new_target_count == COMMAND_TARGET_NONE) // No dead players from  team 2 and 3
	{
		ReplyToTargetError(client, new_target_count);
		return Plugin_Handled;
	}

	target_count = new_target_count; // re-set new value.

	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t", "Toggled respawn on target", target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%t", "Toggled respawn on target", "_s", target_name);
	}

	for (new i = 0; i < target_count; i++)
	{
		RespawnPlayer(client, target_list[i]);
	}

	return Plugin_Handled;
}
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(sm_respawn_reset_each_round))
	{
		SetPlayerSpawns();
	}
	return Plugin_Continue;
}
public Action:Event_ControlPointCaptured(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(sm_respawn_reset_each_objective))
	{
		SetPlayerSpawns();
	}
	return Plugin_Continue;
}
public Action:Event_ObjectDestroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(sm_respawn_reset_each_objective))
	{
		SetPlayerSpawns();
	}
	return Plugin_Continue;
}

//Run this to mark a bot as ready to spawn. Add tokens if you want them to be able to spawn.
SetPlayerSpawns(client=-1)
{
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
	//PrintToServer("[RESPAWNS] Called SetPlayerSpawns with client %d mc %d",client,mc);
	for (; client<=mc; client++)
	{
		if(client > 0 && client <= MaxClients && IsClientInGame(client))
		{
			iTeam = GetClientTeam(client);
			//PrintToServer("[RESPAWNS] Setting client %N on team %d g_iSpawnTokens to %d",client,iTeam,g_iRespawnCount[iTeam]);
			g_iSpawnTokens[client] = g_iRespawnCount[iTeam];
		}
	}
}

public Event_PlayerPickSquad( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"squad_slot" "byte"
	//"squad" "byte"
	//"userid" "short"
	//"class_template" "string"
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	if( client == 0 || !IsClientInGame(client) )
		return;	
	g_bHasClass[client] = 1;
	SetPlayerSpawns( client );
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);

	if (GetConVarInt(sm_respawn_auto) == 1)
	{
		if (IsClientInGame(client) && (team == TEAM_1 || team == TEAM_2))
		{
			if (TF2)
			{
				if ((GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER) == TF_DEATHFLAG_DEADRINGER)
					return;
				new RoundState:iRoundState = GameRules_GetRoundState();
				new bool:NoRespawn = (TF2_IsSuddenDeath() || TF2_IsArenaMap() || iRoundState == RoundState_GameOver || iRoundState == RoundState_TeamWin);
				if(NoRespawn)
				{
					return;
				}
			}
			new ncp = Ins_ObjectiveResource_GetProp("m_iNumControlPoints");
			new acp = Ins_ObjectiveResource_GetProp("m_nActivePushPointIndex");
			if (Ins_InCounterAttack() && ((acp+1) == ncp) && (GetConVarInt(sm_respawn_final_counterattack)))
			{
				if ((g_iSpawnTokens[client] < 1) && (GetConVarInt(sm_respawn_final_counterattack)) && (IsFakeClient(client)))
				{
					//PrintToServer("[RESPAWN] Respawning %N with extra token due to FINAL counterattack infinity! ncp %d acp %d",client,ncp,acp);
					g_iSpawnTokens[client] = 1;
				}
			}
			else if (Ins_InCounterAttack() && (!GetConVarInt(sm_respawn_counterattack)) && (IsFakeClient(client)))
			{
				//PrintToServer("[RESPAWN] Not respawning %N due to counterattack ncp %d acp %d",client,ncp,acp);
				return;
			}
			if (g_iSpawnTokens[client] > 0) {
				CreateRespawnTimer(client);
			}
		}
	}
}
public KillRespawnTimer(client) {
	if (g_hRespawnTimer[client] != INVALID_HANDLE) {
		KillTimer(g_hRespawnTimer[client]);
		g_hRespawnTimer[client] = INVALID_HANDLE;
	}
}

public CreateRespawnTimer(client)
{
	KillRespawnTimer(client);
	g_hRespawnTimer[client] = CreateTimer(GetConVarFloat(sm_respawn_delay), RespawnPlayer2, client, TIMER_FLAG_NO_MAPCHANGE);
}

public RespawnPlayer(client, target)
{
	PrintToServer("[RESPAWN] Starting RespawnPlayer");

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
	else if ((StrEqual(game, "dod")) || StrEqual(game, "insurgency") || StrEqual(game, "doi"))
	{
		if (g_bHasClass[target])  {
			SDKCall(g_hPlayerRespawn, target);
		}
	}
}

public Action:RespawnPlayer2(Handle:Timer, any:client)
{
	decl String:game[40];
	GetGameFolderName(game, sizeof(game));
	g_iSpawnTokens[client]--;
	//PrintToServer("[RESPAWN] Respawning client %N who has %d lives remaining", client, g_iSpawnTokens[client]);
	if (StrEqual(game, "cstrike") || StrEqual(game, "csgo"))
	{
		CS_RespawnPlayer(client);
	}
	else if (StrEqual(game, "tf"))
	{
		TF2_RespawnPlayer(client);
	}
	else if ((StrEqual(game, "dod")) || StrEqual(game, "insurgency") || StrEqual(game, "doi")) {
		if (g_bHasClass[client]) {
			SDKCall(g_hPlayerRespawn, client);
		}
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu")) 
	{
		hAdminMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hAdminMenu)
	{
		return;
	}
	
	hAdminMenu = topmenu;

	new TopMenuObject:player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS);

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hAdminMenu,
		"sm_respawn",
		TopMenuObject_Item,
		AdminMenu_Respawn,
		player_commands,
		"sm_respawn",
		ADMFLAG_SLAY);
	}
}

public AdminMenu_Respawn( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Respawn Player");
	}
	else if( action == TopMenuAction_SelectOption)
	{
		DisplayPlayerMenu(param);
	}
}

DisplayPlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Players);

	decl String:title[100];
	Format(title, sizeof(title), "Choose Player to Respawn:");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);

	// AddTargetsToMenu(menu, client, true, false);
	// Lets only add dead players to the menu... we don't want to respawn alive players do we?
	AddTargetsToMenu2(menu, client, COMMAND_FILTER_DEAD);

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Players(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hAdminMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hAdminMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;

		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %t", "Unable to target");
		}
		else
		{
			new String:name[32];
			GetClientName(target, name, sizeof(name));

			RespawnPlayer(param1, target);
			ShowActivity2(param1, "[SM] ", "%t", "Toggled respawn on target", "_s", name);
		}

		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayPlayerMenu(param1);
		}
	}
}

public EnableChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new intNewValue = StringToInt(newValue);
	new intOldValue = StringToInt(oldValue);

	if(intNewValue == 1 && intOldValue == 0)
	{
		TagsCheck("respawntimes");
		HookEvent("player_death", Event_PlayerDeath);
	}
	else if(intNewValue == 0 && intOldValue == 1)
	{
		TagsCheck("respawntimes", true);
		UnhookEvent("player_death", Event_PlayerDeath);
	}
}
public UpdateRespawnCountConVar(Handle:convar, const String:oldValue[], const String:newValue[])
{
	UpdateRespawnCount();
}
public UpdateRespawnCount()
{
	
	new ism_respawn_count = GetConVarInt(sm_respawn_count);
	new ism_respawn_count_team2 = GetConVarInt(sm_respawn_count_team2);
	new ism_respawn_count_team3 = GetConVarInt(sm_respawn_count_team3);
	//new ism_respawn_reset_each_round = GetConVarInt(sm_respawn_reset_each_round);
	if (ism_respawn_count_team2 > -1)
	{
		g_iRespawnCount[2] = ism_respawn_count_team2;
	}
	else
	{
		g_iRespawnCount[2] = ism_respawn_count;
	}
	if (ism_respawn_count_team3 > -1)
	{
		g_iRespawnCount[3] = ism_respawn_count_team3;
	}
	else
	{
		g_iRespawnCount[3] = ism_respawn_count;
	}
}

public TagsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(sm_respawn_enabled))
		TagsCheck("respawntimes");
	else
		TagsCheck("respawntimes", true);
}

// Thanks Leonardo
stock bool:TF2_IsSuddenDeath()
{
	if (!GetConVarBool(FindConVar("mp_stalemate_enable")))
		return false;
	if (TF2_IsArenaMap())
		return false;
	if (GameRules_GetRoundState() == RoundState_Stalemate)
		return true;
	return false;
}

stock TF2_IsArenaMap(bool:bRecalc = false)
{
	static bool:bChecked = false;
	static bool:bArena = false;
	if(bRecalc || !bChecked)
	{
		new iEnt = FindEntityByClassname(-1, "tf_logic_arena");
		bArena = (iEnt > MaxClients && IsValidEntity(iEnt));
		bChecked = true;
	}
	return bArena;
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
