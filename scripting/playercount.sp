#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_DESCRIPTION "Displays counter of players left"

public Plugin:myinfo =
{
	name = "Player Count",
	author = "jballou",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	RegServerCmd("sm_player_count", Command_Player_Count);
}

public Action:Command_Player_Count(args)
{

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
// && IsPlayerAlive(i))
		{
			decl String:clientname[64];
			decl String:team[64];
			GetClientName(i, clientname, sizeof(clientname));
			GetTeamName(GetClientTeam(i), team, sizeof(team));
			PrintToServer("[player on team] %s is on team %s id %d", clientname,team,GetClientTeam(i));
		}
	}
}
