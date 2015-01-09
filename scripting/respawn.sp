#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#include <tf2>
#include <tf2_stocks>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <adminmenu>

new Handle:hAdminMenu = INVALID_HANDLE;
new Handle:g_hPlayerRespawn;
new Handle:g_hGameConfig;

// This will be used for checking which team the player is on before repsawning them
#define SPECTATOR_TEAM 0
#define TEAM_SPEC 	1
#define TEAM_1			2
#define TEAM_2			3

new bool:TF2 = false;

new Handle:sm_auto_respawn = INVALID_HANDLE;
new Handle:sm_auto_respawn_time = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Player Respawn",
	author = "Rogue",
	description = "Respawn dead players",
	version = "1.6",
	url = "http://forums.alliedmods.net/showthread.php?p=984087"
}

public OnPluginStart()
{
	decl String:gamemod[40];
	GetGameFolderName(gamemod, sizeof(gamemod));
	
	if(StrEqual(gamemod, "tf"))
	{
		TF2 = true;
	}

	CreateConVar("sm_respawn_version", "1.6", "Player Respawn Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	sm_auto_respawn = CreateConVar("sm_auto_respawn", "0", "Automatically respawn players when they die; 0 - disabled, 1 - enabled");
	sm_auto_respawn_time = CreateConVar("sm_auto_respawn_time", "0.0", "How many seconds to delay the respawn");
	RegAdminCmd("sm_respawn", Command_Respawn, ADMFLAG_SLAY, "sm_respawn <#userid|name>");

	HookEvent("player_death", Event_PlayerDeath);
	HookConVarChange(sm_auto_respawn, EnableChanged);
	HookConVarChange(FindConVar("sv_tags"), TagsChanged);

	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}

	decl String:game[40];
	GetGameFolderName(game, sizeof(game));
	if (StrEqual(game, "dod"))
	{
		// Next 14 lines of text are taken from Andersso's DoDs respawn plugin. Thanks :)
		g_hGameConfig = LoadGameConfigFile("plugin.respawn");

		if (g_hGameConfig == INVALID_HANDLE)
		{
			SetFailState("Fatal Error: Missing File \"plugin.respawn\"!");
		}

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Signature, "DODRespawn");
		g_hPlayerRespawn = EndPrepSDKCall();

		if (g_hPlayerRespawn == INVALID_HANDLE)
		{
			SetFailState("Fatal Error: Unable to find signature for \"CDODPlayer::DODRespawn(void)\"!");
		}
	}

	LoadTranslations("common.phrases");
	LoadTranslations("respawn.phrases");
	AutoExecConfig(true, "respawn");
}

public OnMapStart()
{
	TF2_IsArenaMap(true);
}

public OnConfigsExecuted()
{
	if (GetConVarBool(sm_auto_respawn))
		TagsCheck("respawntimes");
	else
		TagsCheck("respawntimes", true);
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

		if(team >= 2)
		{
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

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);

	if (GetConVarInt(sm_auto_respawn) == 1)
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
			CreateTimer(GetConVarFloat(sm_auto_respawn_time), RespawnPlayer2, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public RespawnPlayer(client, target)
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
	else if (StrEqual(game, "dod"))
	{
		SDKCall(g_hPlayerRespawn, target);
	}
}

public Action:RespawnPlayer2(Handle:Timer, any:client)
{
	decl String:game[40];
	GetGameFolderName(game, sizeof(game));

	if (StrEqual(game, "cstrike") || StrEqual(game, "csgo"))
	{
		CS_RespawnPlayer(client);
	}
	else if (StrEqual(game, "tf"))
	{
		TF2_RespawnPlayer(client);
	}
	else if (StrEqual(game, "dod"))
	{
		SDKCall(g_hPlayerRespawn, client);
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

public TagsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(sm_auto_respawn))
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