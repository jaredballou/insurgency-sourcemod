//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_DESCRIPTION "Removes fog"
new Handle:cvarVersion; // version cvar!
new Handle:cvarEnabled; // are we enabled?

public Plugin:myinfo = {
	name= "[INS] No Fog",
	author  = "Jared Ballou (jballou)",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com/"
};

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_nofog_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_nofog_enabled", "1", "sets whether bot naming is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);

	HookEvent("server_spawn", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_init", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_start", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_newmap", Event_GameStart, EventHookMode_Pre);
	remove_fog();
}
public Event_GameStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	remove_fog();
}
public remove_fog()
{
	if (!GetConVarBool(cvarEnabled))
	{
		return true;
	}
	new String:name[32];
	for(new i=0;i<= GetMaxEntities() ;i++){
		if(!IsValidEntity(i))
			continue;
		if(GetEdictClassname(i, name, sizeof(name))){
			if (StrEqual("env_fog_controller", name,false)) {
				RemoveEdict(i);
			}
		}
	}
}
