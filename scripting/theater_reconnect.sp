#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma unused cvarVersion

#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_DESCRIPTION "If a player connects with their mp_theater_override set to something other than what the server uses, set the cvar and retonnect them."
#define PLUGIN_NAME "[INS] Theater Reconnect"
#define PLUGIN_URL "http://jballou.com/"
#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_WORKING "1"

public Plugin:myinfo = {
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url		= PLUGIN_URL
};

#define UPDATE_URL "http://ins.jballou.com/sourcemod/update-theater_reconnect.txt"

new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?

// called when the plugin loads
public OnPluginStart()
{
	// cvars!
	cvarVersion = CreateConVar("sm_theater_reconnect_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_theater_reconnect_enabled", "1", "sets whether theater reconnect is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);

	// hook team change, connect to supress messages
	//HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Post);

	AutoExecConfig();
}

//public OnClientConnected(client) {
public OnClientAuthorized(client, const String:auth[]) {
	PrintToServer("[TR] OnClientAuthorized client %d %N",client,client);
	QueryClientConVar(client, "mp_theater_override", ConVarQueryFinished:CheckClientTheater, client);
}
public CheckClientTheater(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[]) {
	new String:sTheaterOverride[32];
        GetConVarString(FindConVar("mp_theater_override"),sTheaterOverride, sizeof(sTheaterOverride));
	PrintToServer("[TR] Server theater is \"%s\" client is \"%s\"",sTheaterOverride,cvarValue);
//ClientCommand(client, "retry");
}
/*
// handle player connect, to supress bot messages
public Action:Event_PlayerConnect(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!(GetConVarBool(cvarEnabled))) {
		return Plugin_Continue;
	}
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	PrintToServer("[TR] Event_PlayerConnect userid %d client %d %N",userid,client,client);
	QueryClientConVar(client, "mp_theater_override", ConVarQueryFinished:ClientConVar, client);
	return Plugin_Continue;
}
*/
