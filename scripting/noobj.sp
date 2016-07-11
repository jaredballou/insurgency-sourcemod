//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#pragma unused cvarRemove
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <updater>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_DESCRIPTION "Removes all objectives"
#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-noobj.txt"

new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
new Handle:cvarCacheDestroy = INVALID_HANDLE;
new Handle:cvarCapture = INVALID_HANDLE;
new Handle:cvarRemove = INVALID_HANDLE;

public Plugin:myinfo = {
	name= "[INS] No Objectives",
	author  = "Jared Ballou (jballou)",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com/"
};

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_noobj_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_noobj_enabled", "0", "sets whether objective removal is enabled", FCVAR_NOTIFY);
	cvarCacheDestroy = CreateConVar("sm_noobj_cache_destroy", "1", "Can caches be destroyed?", FCVAR_NOTIFY);
	cvarCapture = CreateConVar("sm_noobj_capture", "1", "Can points be captured?", FCVAR_NOTIFY);
	cvarRemove = CreateConVar("sm_noobj_remove", "0", "Remove all points?", FCVAR_NOTIFY);

	HookEvent("server_spawn", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_init", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_start", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_newmap", Event_GameStart, EventHookMode_Pre);

	HookEvent("object_destroyed", Event_ObjectDestroyed);
	HookEvent("controlpoint_captured", Event_ControlPointCaptured);
	HookEvent("controlpoint_neutralized", Event_ControlPointNeutralized);
	HookEvent("controlpoint_starttouch", Event_ControlPointStartTouch);
	HookEvent("controlpoint_endtouch", Event_ControlPointEndTouch);

	remove_obj();
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}
public Event_GameStart(Handle:event, const String:name[], bool:dontBroadcast)
{
}
public remove_obj()
{
	if (!GetConVarBool(cvarEnabled))
	{
		return true;
	}
	new String:name[32],String:entity_name[128];
	for(new i=0;i<= GetMaxEntities() ;i++){
		if(!IsValidEntity(i))
			continue;
		if(GetEdictClassname(i, name, sizeof(name))){
			if (
				(StrEqual("point_controlpoint", name,false)) || 
				(StrEqual("obj_weapon_cache", name,false)) || 
				(StrEqual("trigger_capture_zone", name,false))
			) {
				GetEntPropString(i, Prop_Data, "m_iName", entity_name, sizeof(entity_name));
				PrintToServer("[NOOBJ] Found entity %s named %s - removing",name,entity_name);
				RemoveEdict(i);
			}
		}
	}
	return true;
}
public Action:Event_ControlPointCaptured(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
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
public Action:Event_ControlPointNeutralized(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	//"priority" "short"
	//"cp" "byte"
	//"cappers" "string"
	//"cpname" "string"
	//"team" "byte"
/*
	decl String:cappers[256],String:cpname[64];
	//new priority = GetEventInt(event, "priority");
	//new cp = GetEventInt(event, "cp");
	GetEventString(event, "cappers", cappers, sizeof(cappers));
	GetEventString(event, "cpname", cpname, sizeof(cpname));
	//new team = GetEventInt(event, "team");

	//new capperlen = GetCharBytes(cappers);
	//PrintToServer("[LOGGER] Event_ControlPointNeutralized priority %d cp %d capperlen %d cpname %s team %d", priority,cp,capperlen,cpname,team);

	//"cp" "byte" - for naming, currently not needed
	GetEventString(event, "cappers", cappers, sizeof(cappers));
	for (new i = 0 ; i < strlen(cappers); i++)
	{
		new client = cappers[i];
		if(client > 0 && client <= MaxClients && IsClientInGame(client))
		{
			decl String:player_authid[64];
			if (!GetClientAuthString(client, player_authid, sizeof(player_authid)))
			{
				strcopy(player_authid, sizeof(player_authid), "UNKNOWN");
			}
			new player_userid = GetClientUserId(client);
			new player_team_index = GetClientTeam(client);

			LogToGame("\"%N<%d><%s><%s>\" triggered \"ins_cp_neutralized\"", client, player_userid, player_authid, g_team_list[player_team_index]);
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
	if (!GetConVarBool(cvarCapture))
	{
		return Plugin_Stop;
	}
	//new area = GetEventInt(event, "area");
	//new object = GetEventInt(event, "object");
	//new player = GetEventInt(event, "player");
	//new team = GetEventInt(event, "team");
	//new owner = GetEventInt(event, "owner");
	//new type = GetEventInt(event, "type");
	//PrintToServer("[LOGGER] Event_ControlPointStartTouch: player %N area %d object %d player %d team %d owner %d type %d",player,area,object,player,team,owner,type);
	return Plugin_Continue;
}
public Action:Event_ControlPointEndTouch(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	//"owner" "short"
	//"player" "short"
	//"team" "short"
	//"area" "byte"
	//new owner = GetEventInt(event, "owner");
	//new player = GetEventInt(event, "player");
	//new team = GetEventInt(event, "team");
	//new area = GetEventInt(event, "area");

	//PrintToServer("[LOGGER] Event_ControlPointEndTouch: player %N area %d player %d team %d owner %d",player,area,player,team,owner);
	return Plugin_Continue;
}

public Action:Event_ObjectDestroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	if (!GetConVarBool(cvarCacheDestroy))
	{
		return Plugin_Stop;
	}
	//decl String:attacker_authid[64],String:assister_authid[64],String:classname[64];
	//"team" "byte"
	//"attacker" "byte"
	//"cp" "short"
	//"index" "short"
	//"type" "byte"
	//"weapon" "string"
	//"weaponid" "short"
	//"assister" "byte"
	//"attackerteam" "byte"
	return Plugin_Continue;
}
