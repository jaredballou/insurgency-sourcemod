//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3
#pragma unused cvarVersion

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <updater>
#include <insurgency>


//Define CVARS
#define PLUGIN_DESCRIPTION "Shows Bots Left Alive"
#define PLUGIN_NAME "Bot Counter"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_WORKING "1"
#define PLUGIN_LOG_PREFIX "BOTCOUNT"
#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_URL "http://jballou.com/insurgency"

public Plugin:myinfo = {
        name            = PLUGIN_NAME,
        author          = PLUGIN_AUTHOR,
        description     = PLUGIN_DESCRIPTION,
        version         = PLUGIN_VERSION,
        url             = PLUGIN_URL
};

new Handle:PanelTimers[MAXPLAYERS+1];
new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
new Handle:cvarTimer = INVALID_HANDLE; // Frequency

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_botcount_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_botcount_enabled", "0", "sets whether bot naming is enabled", FCVAR_NOTIFY);
	cvarTimer = CreateConVar("sm_botcount_timer", "60", "Frequency to show count", FCVAR_NOTIFY);
	HookUpdater();
}

public OnLibraryAdded(const String:name[]) {
	HookUpdater();
}

public OnClientPutInServer(client)
{
	PanelTimers[client] = CreateTimer(GetConVarFloat(cvarTimer), RefreshPanel, client, TIMER_REPEAT);
}
 
public OnClientDisconnect(client)
{
	if (PanelTimers[client] != INVALID_HANDLE)
	{
		KillTimer(PanelTimers[client]);
		PanelTimers[client] = INVALID_HANDLE;
	}
}
 
public Action:RefreshPanel(Handle:timer, any:client)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	if (IsValidPlayer(client))
	{
		new myteam = GetClientTeam(client);
		new otherteam = view_as<int>(myteam == view_as<int>(TEAM_SECURITY) ? TEAM_INSURGENTS : TEAM_SECURITY);
		decl String:hint[40];
		new num_ins = 0, total_ins;
		new maxplayers = GetMaxClients();

		for (new i = 1; i <= maxplayers; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i))
			{
				if (GetClientTeam(i) == otherteam)
				{
					num_ins++;
				}
			}
		}
		total_ins = GetTeamClientCount(otherteam);
		Format(hint, 255,"Enemies Remaining: %i of %i", num_ins, total_ins);

		PrintHintText(client, "%s", hint);
	}
	return Plugin_Continue;
}

//Is Valid Player
public IsValidPlayer(client)
{
	if (client == 0)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	if (IsFakeClient(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	return true;
}


