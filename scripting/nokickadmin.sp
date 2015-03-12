//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <updater>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_DESCRIPTION "Don't kick admins"
#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-nokickadmin.txt"

public Plugin:myinfo = {
	name= "[INS] Don't kick admins!",
	author  = "Jared Ballou (jballou)",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com/"
};

public OnPluginStart()
{
	RegServerCmd("kickid", Command_KickId);
}
 
public Action:Command_KickId(args)
{
	new String:name[32], target = -1;
	GetCmdArg(1, name, sizeof(name));
	for (new i=1; i<=MaxClients; i++)
	{
		if (!IsClientConnected(i))
		{
			continue;
		}
		decl String:other[32];
		GetClientName(i, other, sizeof(other));
		if (StrEqual(name, other))
		{
			target = i;
		}
	}
	if (target > -1)
	{
		new AdminId:admin = GetUserAdmin(target);
		if (admin)
		{
			if (GetAdminFlag(admin, Admin_Reservation))
			{
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}
