#pragma semicolon 1
#include <sourcemod>
#include <tentdev>
#include <sdkhooks>

#define VERSION 		"0.0.2"

new String:g_sHookClass[MAXPLAYERS+1][127];
new bool:g_bStartWatching[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name 		= "tEntDev - Spawnhook",
	author 		= "Thrawn",
	description = "Immediately selects an entity by classname when it is created",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_tentdev_aim_version", VERSION, "",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	RegAdminCmd("sm_ted_spawnhook", Command_SpawnHookEntity, ADMFLAG_ROOT);
}

public OnPlayerDisconnect(client) {
	strcopy(g_sHookClass[client], 127, "");
}

public Action:Command_SpawnHookEntity(client,args) {
	if(args > 0) {
		new String:sClassName[32];
		GetCmdArg(1, sClassName, sizeof(sClassName));

		strcopy(g_sHookClass[client], 127, sClassName);

		if(args == 2) {
			g_bStartWatching[client] = false;
		} else {
			g_bStartWatching[client] = true;
		}
	} else {
		ReplyToCommand(client, "Usage: sm_spawnhook <classname> [startwatching]");
	}

	return Plugin_Handled;
}

public OnEntityCreated(entity, const String:classname[]) {
	for(new client = 1; client <= MaxClients; client++) {
		if(IsClientInGame(client) && strlen(g_sHookClass[client]) > 0) {
			if(StrEqual(classname, g_sHookClass[client])) {
				TED_SelectEntity(client, entity);

				if(g_bStartWatching[client]) {
					TED_ShowNetprops(client);
					TED_WatchNetprops(client);
				}
			}
		}
	}
}
