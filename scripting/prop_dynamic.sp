//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <updater>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_DESCRIPTION "Plugin for removing Restricted Areas"
#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-prop_dynamic.txt"

new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
public Plugin:myinfo = {
	name= "[INS] Prop Removal",
	author  = "Jared Ballou (jballou)",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com/"
};

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_prop_dynamic_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_prop_dynamic_enabled", "1", "sets whether bot naming is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);
	HookEvent("server_spawn", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_init", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_start", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_newmap", Event_GameStart, EventHookMode_Pre);
	remove_prop_dynamic();
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
	remove_prop_dynamic();
}
public remove_prop_dynamic()
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
			if(StrEqual("prop_dynamic", name,false)){
				decl String:entity_name[128];
				GetEntPropString(i, Prop_Data, "m_iName", entity_name, sizeof(entity_name));
				PrintToServer("Found prop named %s",entity_name);
				RemoveEdict(i);
				PrintToServer("Deleted prop named %s",entity_name);
			}
		}
	}
	return true;
}
