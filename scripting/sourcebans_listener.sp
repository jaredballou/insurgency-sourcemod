#pragma semicolon 1
#include <sourcemod>
#include <sourcebans>

#undef REQUIRE_PLUGIN
#include <adminmenu>

new g_bSBAvailable = false;

public Plugin:myinfo =
{
	name = "SourceBans Listener",
	author = "Jared Ballou",
	description = "Listens for player bans and converts them to SourceBans",
	version = "0.0.1",
	url = "http://github.com/jaredballou/insurgency-sourcemod"
};

public OnAllPluginsLoaded()
{
	if (LibraryExists("sourcebans"))
	{
		g_bSBAvailable = true;
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "sourcebans"))
	{
		g_bSBAvailable = true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "sourcebans"))
	{
		g_bSBAvailable = false;
	}
}

public Action:OnBanClient(client, time, flags, const String:reason[], const String:kick_message[], const String:command[], any:source) {
/*
	if(StrEqual(command, "banid")) {
		return Plugin_Continue;
	}
*/
	if(source < 0 || source > MaxClients) {
		return Plugin_Continue;
	}
	if(source > 0 && (!IsClientInGame(source) || GetUserAdmin(source) == INVALID_ADMIN_ID)) {
		return Plugin_Continue;
	}
	if (g_bSBAvailable)
	{
		SBBanPlayer(source, client, time, reason);
	}
	else
	{
//		BanClient(client, time, BANFLAG_AUTO, &reason);
	}
	return Plugin_Handled;
}  
