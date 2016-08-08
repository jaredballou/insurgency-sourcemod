//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <insurgency>
#include <updater>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_DESCRIPTION "Removes fog"
#define PLUGIN_NAME "[INS] No Fog"
#define PLUGIN_URL "http://jballou.com/insurgency"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_WORKING 1

public Plugin:myinfo = {
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url		= PLUGIN_URL
};


new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_nofog_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_nofog_enabled", "1", "sets whether bot naming is enabled", FCVAR_NOTIFY);

	HookEvent("server_spawn", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_init", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_start", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_newmap", Event_GameStart, EventHookMode_Pre);
	remove_fog();
	HookUpdater();
}

public OnLibraryAdded(const String:name[]) {
	HookUpdater();
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
	return true;
}
