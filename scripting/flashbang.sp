#pragma semicolon 1
#include <sdkhooks>

#define IS_CLIENT(%1)	(1 <= %1 <= MaxClients)

#define CS_TEAM_SPECTATOR 1
#define PLUGIN_VERSION "0.0.4"

// PropOffsets
new g_iFlashDuration = -1;
new g_iFlashAlpha = -1;

new bool:g_bLateLoad;

// Flash variables
new Handle:g_hFlashThrowers = INVALID_HANDLE;

new g_iFlashVictim[MAXPLAYERS + 1];
new g_iVictimCount = -1;
new bool:g_bFlashedEnemy;

new Float:g_fFlashAlpha[MAXPLAYERS + 1];
new Float:g_fFlashDuration[MAXPLAYERS + 1];
new Float:g_fFlashLeft[MAXPLAYERS + 1];

new g_iTeam[MAXPLAYERS + 1];
new bool:g_bAlive[MAXPLAYERS + 1];

new Float:g_fFlashedUntil[MAXPLAYERS+1];
new bool:g_bFlashHooked = false; 


public Plugin:myinfo = 
{
	name = "[INS] Flash Protection",
	author = "TheAvengers2, thetwistedpanda, GoD-Tony, Bacardi",
	description = "Anti-TeamFlash, NoDeafen, Anti-NoFlash, Flash Duration Bug Fix",
	version = PLUGIN_VERSION,
	url = "http://sourcemod.com/"
}

// thetwistedpanda - Anti Team Flash (http://forums.alliedmods.net/showthread.php?t=139505)
// GoD-Tony - SMAC Anti-NoFlash (http://hg.nicholashastings.com/smac/)
// Bacardi - Flash Duration Bug Fix (http://forums.alliedmods.net/showthread.php?t=173450)
// Bacardi - No Deafening (http://forums.alliedmods.net/showpost.php?p=1493651&postcount=13)

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	if ((g_iFlashDuration = FindSendPropOffs("CINSPlayer", "m_flFlashDuration")) == -1)
		SetFailState("Failed to find \"m_flFlashDuration\".");
	if ((g_iFlashAlpha = FindSendPropOffs("CINSPlayer", "m_flFlashMaxAlpha")) == -1)
		SetFailState("Failed to find \"m_flFlashMaxAlpha\".");

	HookEvent("player_blind", Event_PreFlashPlayer, EventHookMode_Pre);
	HookEvent("player_blind", Event_OnFlashPlayer, EventHookMode_Post);
//	HookEvent("grenade_detonate", Event_OnFlashExplode, EventHookMode_Post);
	HookEvent("player_team", Event_OnPlayerTeam);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
	g_hFlashThrowers = CreateArray(2);
}

public OnPluginEnd()
{
	ClearArray(g_hFlashThrowers);
}

public OnConfigsExecuted()
{
	if (g_bLateLoad)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				g_iTeam[i] = GetClientTeam(i);
				g_bAlive[i] = IsPlayerAlive(i) ? true : false;
			}
			else
			{
				g_iTeam[i] = 0;
				g_bAlive[i] = false;
			}
		}
		
		g_bLateLoad = false;
	}
}

public OnMapEnd()
{
	ClearArray(g_hFlashThrowers);
	g_iVictimCount = -1;
	g_bFlashedEnemy = false;
}

public OnClientPutInServer(client)
{
	if (g_bFlashHooked)
	{
		SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	}
}

public OnClientDisconnect(client)
{
	g_fFlashedUntil[client] = 0.0;
	g_iTeam[client] = 0;
	g_bAlive[client] = false;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "grenade_m84"))
	{
		CreateTimer(0.1, Timer_Create, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Event_OnFlashExplode(Handle:event, const String:name[], bool:dontBroadcast)
{
	new entityid = GetEventInt(event, "entityid");
	new id = GetEventInt(event, "id");
	PrintToServer("[FLASHBANG] entityid %d id %d",entityid,id);
	new String:classname[32];
	if(!GetEdictClassname(entityid, classname, sizeof(classname)))
	{
		PrintToServer("[FLASHBANG] No classname for entityid %d",entityid);
		return;
	}
	if (!StrEqual(classname, "grenade_m84"))
	{
		PrintToServer("[FLASHBANG] classname %s for entityid %d does not match",classname,entityid);
		return;
	}

	if (GetArraySize(g_hFlashThrowers))
	{
		if (g_iVictimCount != -1)
		{
			for (new i = 0; i <= g_iVictimCount; ++i)
			{
				if (!IsClientInGame(g_iFlashVictim[i]))
					continue;
					
				if (g_bFlashedEnemy)
				{
					new _iFlashThrower = GetArrayCell(g_hFlashThrowers, 0);
				
					if (IsClientInGame(_iFlashThrower))
					{
						decl String:sOwnerName[32], String:sOwnerAuth[30];
						GetClientName(_iFlashThrower, sOwnerName, sizeof(sOwnerName));
						GetClientAuthString(_iFlashThrower, sOwnerAuth, sizeof(sOwnerAuth));
						PrintToChat(g_iFlashVictim[i], "\x04[TFD] \x01%s \x04(\x01%s\x04) has team flashed you.", sOwnerName, sOwnerAuth);
					}
				}
				else
				{
					if (g_fFlashLeft[(g_iFlashVictim[i])])
					{
						SetEntDataFloat(g_iFlashVictim[i], g_iFlashAlpha, g_fFlashAlpha[(g_iFlashVictim[i])]);
						SetEntDataFloat(g_iFlashVictim[i], g_iFlashDuration, g_fFlashLeft[(g_iFlashVictim[i])]);
						//FadeClientVolume(g_iFlashVictim[i], 100.0, 3.0, duration - 3.0, 0.0);
						SetupAntiFlash(g_iFlashVictim[i]);
					}
					else
					{
						SetEntDataFloat(g_iFlashVictim[i], g_iFlashAlpha, 0.5);
						SetEntDataFloat(g_iFlashVictim[i], g_iFlashDuration, 0.0);
						ClientCommand(g_iFlashVictim[i], "dsp_player 0");
						g_fFlashedUntil[(g_iFlashVictim[i])] = 0.0;
					}
				}
			}
		}
		RemoveFromArray(g_hFlashThrowers, 0);
	}
	
	g_iVictimCount = -1;
	g_bFlashedEnemy = false;
}

public Event_PreFlashPlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid")), Float:fGameTime = GetGameTime();
	
	g_fFlashAlpha[client] = GetEntDataFloat(client, g_iFlashAlpha);
	g_fFlashDuration[client] = GetEntDataFloat(client, g_iFlashDuration);
	g_fFlashLeft[client] = (g_fFlashedUntil[client] && g_fFlashedUntil[client] > fGameTime) ? (g_fFlashedUntil[client] - fGameTime) + 2.5 : 0.0;
}

public Event_OnFlashPlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IS_CLIENT(client) && IsClientInGame(client))
	{
		if (GetArraySize(g_hFlashThrowers))
		{
			if (g_bAlive[client] && g_iTeam[client] > CS_TEAM_SPECTATOR)
			{
				decl _iData[2];
				GetArrayArray(g_hFlashThrowers, 0, _iData);
			
				if (g_iTeam[client] == _iData[1])
				{
					if (client != _iData[0])
						g_iFlashVictim[(++g_iVictimCount)] = client;
				}
				else
				{
					g_bFlashedEnemy = true;
				}
			}
		}
		
		SetupAntiFlash(client);
	}
}

SetupAntiFlash(client)
{
	// Bacardi - Flash Bug Fix
	new Float:duration = GetEntDataFloat(client, g_iFlashDuration);
	if (duration == g_fFlashDuration[client])
	{
		duration = GetRandomFloat(duration + 0.01, duration + 0.1);
		SetEntDataFloat(client, g_iFlashDuration, duration);
	}
	
	// GoD-Tony - SMAC Anti-NoFlash
	new Float:alpha = GetEntDataFloat(client, g_iFlashAlpha);
	if (alpha < 255.0)
		return;

	g_fFlashedUntil[client] = (duration > 2.9) ? (GetGameTime() + duration - 2.9) : (GetGameTime() + duration * 0.1);
	
	if (!g_bFlashHooked)
	{
		AntiFlash_HookAll();
	}
	
	CreateTimer(duration, Timer_FlashEnded);
}

public Action:Timer_FlashEnded(Handle:timer)
{
	/* Check if there are any other flashes being processed. Otherwise, we can unhook. */
	new Float:fGameTime = GetGameTime();
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_fFlashedUntil[i] > fGameTime)
			return Plugin_Stop;
	}
	
	if (g_bFlashHooked)
	{
		AntiFlash_UnhookAll();
	}
	
	return Plugin_Stop;
}

public Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IS_CLIENT(client) && IsClientInGame(client))
	{
		g_iTeam[client] = GetEventInt(event, "team");
		if (g_iTeam[client] <= CS_TEAM_SPECTATOR)
		{
			g_bAlive[client] = false;
		}
	}
}

public Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IS_CLIENT(client) && IsClientInGame(client) && g_iTeam[client] > CS_TEAM_SPECTATOR)
	{
		g_bAlive[client] = true;
	}
}

public Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IS_CLIENT(client) && IsClientInGame(client))
	{
		g_bAlive[client] = false;
	}
}

public Action:Timer_Create(Handle:timer, any:ref)
{
	new entity = EntRefToEntIndex(ref);
	if (entity != INVALID_ENT_REFERENCE)
	{
		decl _iData[2];
		_iData[0] = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
		_iData[1] = (_iData[0] > 0) ? g_iTeam[_iData[0]] : 0;

		PushArrayArray(g_hFlashThrowers, _iData);
	}
}

public Action:Hook_SetTransmit(entity, client)
{
	if (!IS_CLIENT(client) || entity == client)
		return Plugin_Continue;
	
	if (g_fFlashedUntil[client] && g_fFlashedUntil[client] > GetGameTime())
		return Plugin_Handled;
	
	g_fFlashedUntil[client] = 0.0;
	
	return Plugin_Continue;
}

AntiFlash_HookAll()
{
	g_bFlashHooked = true;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SDKHook(i, SDKHook_SetTransmit, Hook_SetTransmit);
		}
	}
}

AntiFlash_UnhookAll()
{
	g_bFlashHooked = false;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SDKUnhook(i, SDKHook_SetTransmit, Hook_SetTransmit);
		}
	}
}

