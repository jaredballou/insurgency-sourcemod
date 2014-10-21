//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1

#include <sourcemod>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "0.0.1"

public Plugin:myinfo = {
        name        = "Insurgency Coop Lobby Override",
        author      = "Jared Ballou (jballou)",
        description = "Plugin for overriding Insurgency Coop to 16 players",
        version     = PLUGIN_VERSION,
        url         = "http://jballou.com/"
};

public OnPluginStart()
{
       	decl String:folder[64];
       	GetGameFolderName(folder, sizeof(folder));
       	if (strcmp(folder, "insurgency") == 0)
        {
                HookEvent("server_spawn", Event_GameStart, EventHookMode_Pre);
                HookEvent("game_init", Event_GameStart, EventHookMode_Pre);
                HookEvent("game_start", Event_GameStart, EventHookMode_Pre);
                HookEvent("game_newmap", Event_GameStart, EventHookMode_Pre);
		set_lobbysize();
       	}
}
public Event_GameStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	set_lobbysize();
}

public set_lobbysize()
{
    new Handle:cvar;
    cvar = FindConVar("mp_coop_lobbysize");
    SetConVarBounds(cvar,ConVarBound_Upper, true, 16.0);
//  SetConVarInt(cvar, 16);
}
