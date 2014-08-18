#include <sourcemod>
#pragma semicolon 1
#define VERSION "0.1.1"

public Plugin:myinfo = {
	name = "No Fog",
	author = "jballou",
	description = "Removes fog",
	version = VERSION,
	url = "N/A"
}

new Handle:cvar_fog_override=INVALID_HANDLE;
new Handle:cvar_fog_end=INVALID_HANDLE;
new Handle:cvar_fog_enable=INVALID_HANDLE;
new Handle:cvar_fog_endskybox=INVALID_HANDLE;

public OnPluginStart()
{
	//cvars needed to abuse for listining servers
	cvar_fog_override = FindConVar("fog_override");
	if(cvar_fog_override!=INVALID_HANDLE)
	{
		SetConVarInt(cvar_fog_override, 1, true);
	}
	cvar_fog_end = FindConVar("fog_end");
	if(cvar_fog_end!=INVALID_HANDLE)
	{
		SetConVarInt(cvar_fog_end, 1000000, true);
	}
	cvar_fog_endskybox = FindConVar("fog_endskybox");
	if(cvar_fog_endskybox!=INVALID_HANDLE)
	{
		SetConVarInt(cvar_fog_endskybox, 1000000, true);
	}	
	cvar_fog_enable = FindConVar("fog_enable");
	if(cvar_fog_enable!=INVALID_HANDLE)
	{
		SetConVarInt(cvar_fog_enable, 0, true);
	}
	HookEvent("player_spawn",SpawnEvent);
}
public Action:SpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client_id = GetEventInt(event, "userid");
	new client = GetClientOfUserId(client_id);
	removeFog(client);
}

public OnClientPutInServer(client) {
	removeFog(client);
}

removeFog(client)
{
	if(!IsFakeClient(client))
	{
		decl String:ipaddr[24];
		GetClientIP(client, ipaddr, sizeof(ipaddr));
	
		if (!StrEqual(ipaddr,"loopback",false))
		{
			//I learned to do this by lookig at grandwazir's blindluck plugin, http://forums.alliedmods.net/showthread.php?t=84926
			SendConVarValue(client, FindConVar("sv_cheats"), "1");
			ClientCommand(client, "fog_override 1");
			ClientCommand(client, "fog_enable 0");
		}
	}
}
