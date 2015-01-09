//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_DESCRIPTION "Removes all objectives"
new Handle:cvarVersion; // version cvar!
new Handle:cvarEnabled; // are we enabled?

public Plugin:myinfo = {
	name= "[INS] No Objectives",
	author  = "Jared Ballou (jballou)",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com/"
};

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_noobj_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_noobj_enabled", "0", "sets whether objective removal is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);

	HookEvent("server_spawn", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_init", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_start", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_newmap", Event_GameStart, EventHookMode_Pre);
	remove_obj();
}
public Event_GameStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	remove_obj();
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
