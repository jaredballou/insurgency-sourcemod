//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1

#include <sourcemod>
#include <insurgency>
#undef REQUIRE_PLUGIN
#include <updater>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_DESCRIPTION "Plugin for overriding Insurgency Coop to 16 players"
#define PLUGIN_NAME "Coop Lobby Override"
#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_WORKING "1"
#define PLUGIN_LOG_PREFIX "COOPLOBBY"
#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_URL "http://jballou.com/insurgency"

public Plugin:myinfo = {
        name            = PLUGIN_NAME,
        author          = PLUGIN_AUTHOR,
        description     = PLUGIN_DESCRIPTION,
        version         = PLUGIN_VERSION,
        url             = PLUGIN_URL
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
	HookUpdater();
}

public OnLibraryAdded(const String:name[]) {
	HookUpdater();
}

public Event_GameStart(Handle:event, const String:name[], bool:dontBroadcast) {
	set_lobbysize();
}

public set_lobbysize()
{
    new Handle:cvar;
    cvar = FindConVar("mp_coop_lobbysize");
    SetConVarBounds(cvar,ConVarBound_Upper, true, 16.0);
//  SetConVarInt(cvar, 16);
}
