#pragma semicolon 1
#define PLUGIN_VERSION "1.0"
#define PLUGIN_DESCRIPTION "Mikee Join Sound ._."

public Plugin:myinfo =
{
	name = "＃Lua Mikee Join Sound",
	author = "D.Freddo",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://steam.lua.kr"
}

new bool:g_bLateLoad = false;
new Handle:g_hCvarEnabled;
new WelcomeToTheCompany[MAXPLAYERS + 1] = {0, ...};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sm_ins_mikee_join_sound", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_hCvarEnabled = CreateConVar("sm_ins_mikee_join_sound_enabled", "1", "Mikee Join Sound Enable [0/1] ._.", FCVAR_NOTIFY | FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	HookEvent("player_pick_squad", Event_PlayerPickSquad);
}

public OnMapStart()
{
	if (g_bLateLoad){
		g_bLateLoad = false;
		for (new i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i)) WelcomeToTheCompany[i] = 2;
	}
}

public OnClientPutInServer(client)
{
	WelcomeToTheCompany[client] = 0;
}

public Event_PlayerPickSquad(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if ((GetConVarInt(g_hCvarEnabled) < 1) || (!IsFakeClient(client)) || (WelcomeToTheCompany[client] < 2))
	{
		return;
	}
	//Use same timer to simplify and make new scripts workable
	//TODO: Support external script config files including timings, so we can support multiple languages
	CreateTimer(0.1, WelcomeToTheCompany_timer, client, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(2.9, WelcomeToTheCompany_timer, client, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(4.9, WelcomeToTheCompany_timer, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:WelcomeToTheCompany_timer(Handle:timer, any:client)
{
	if ((GetConVarInt(g_hCvarEnabled) < 1) || (!IsClientInGame(client)) || (!WelcomeToTheCompany[client]))
	{
		//Not sure if Stop is the right action for the individual timers
		return Plugin_Stop;
	}
	switch(WelcomeToTheCompany[client]) {
		case 2:
			ClientCommand(client, "playgamesound Training.Warehouse.Vip.1.1");
		case 1:
			ClientCommand(client, "playgamesound Training.Warehouse.Vip.1.2");
		case 0:
			ClientCommand(client, "playgamesound Training.Warehouse.Vip.41.3");
	}
	WelcomeToTheCompany[client]--;
	return Plugin_Stop;
}
