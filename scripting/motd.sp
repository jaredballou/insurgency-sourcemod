#include <sourcemod>

#define Plugin_Version "2.0"

new Handle:g_CvarEnabled;

public Plugin:myinfo = {
	name = "Message Of The Day",
	author = "Insurgency ANZ",
	description = "Launch MOTD on Player Join",
	version = Plugin_Version,
	url = "http://www.insurgencyanz.com"
};

public OnPluginStart()
{
	g_CvarEnabled = CreateConVar("sm_motd_enabled","1","Enables(1) or disables(0) the plugin.",FCVAR_NOTIFY);
	AutoExecConfig(true,"plugin.motd");
}

public OnClientPutInServer(client)
{
	if (client < 1 || IsFakeClient(client) || !GetConVarBool(g_CvarEnabled)) return;
	
	FakeClientCommand (client, "say /motd");
}