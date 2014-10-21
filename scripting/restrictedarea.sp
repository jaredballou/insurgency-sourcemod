# (C) 2014 Jared Ballou <sourcemod@jballou.com>
# Released under GPLv3

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "0.0.1"

public Plugin:myinfo = {
name= "Insurgency Restricted Area Removal",
author  = "Jared Ballou (jballou)",
description = "Plugin for removing Restricted Areas",
version = PLUGIN_VERSION,
url = "http://jballou.com/"
};

public OnPluginStart()
{
	HookEvent("server_spawn", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_init", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_start", Event_GameStart, EventHookMode_Pre);
	HookEvent("game_newmap", Event_GameStart, EventHookMode_Pre);
	remove_restrictedarea();
}
public Event_GameStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	remove_restrictedarea();
}
public remove_restrictedarea()
{
	new String:name[32];
	for(new i=0;i<= GetMaxEntities() ;i++){
		if(!IsValidEntity(i))
			continue;
		if(GetEdictClassname(i, name, sizeof(name))){
			if(StrEqual("ins_blockzone", name,false)){
				decl String:entity_name[128];
				GetEntPropString(i, Prop_Data, "m_iName", entity_name, sizeof(entity_name));
				PrintToServer("Found blockzone named %s",entity_name);
				RemoveEdict(i);
				PrintToServer("Deleted blockzone named %s",entity_name);
			}
		}
	}
}
