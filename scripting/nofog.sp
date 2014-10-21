# (C) 2014 Jared Ballou <sourcemod@jballou.com>
# Released under GPLv3

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "0.0.1"

public Plugin:myinfo = {
name= "No Fog",
author  = "Jared Ballou (jballou)",
description = "Removes fog",
version = PLUGIN_VERSION,
url = "http://jballou.com/"
};

public OnPluginStart()
{
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
