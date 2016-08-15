#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tentdev>

#define VERSION 		"0.0.2"


public Plugin:myinfo =
{
	name 		= "tEntDev - Commands",
	author 		= "Thrawn",
	description = "Provides chat commands to debug entity netprops",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_tentdev_cmds_version", VERSION, "",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	RegAdminCmd("sm_ted_selectself", Command_SelectSelf, ADMFLAG_ROOT);
	RegAdminCmd("sm_ted_set", Command_SetNetprop, ADMFLAG_ROOT);
	RegAdminCmd("sm_ted_show", Command_ShowNetprops, ADMFLAG_ROOT);
	RegAdminCmd("sm_ted_ignore", Command_IgnoreNetprop, ADMFLAG_ROOT);
	RegAdminCmd("sm_ted_unignore", Command_UnIgnoreNetprop, ADMFLAG_ROOT);
	RegAdminCmd("sm_ted_watch", Command_WatchNetprops, ADMFLAG_ROOT);
	RegAdminCmd("sm_ted_stopwatch", Command_StopWatchNetprops, ADMFLAG_ROOT);
	RegAdminCmd("sm_ted_save", Command_SaveNetprops, ADMFLAG_ROOT);
	RegAdminCmd("sm_ted_compare", Command_CompareNetprops, ADMFLAG_ROOT);
}

public Action:Command_SetNetprop(client,args) {
	if(args == 2) {
		new String:sNetProp[32];
		GetCmdArg(1, sNetProp, sizeof(sNetProp));

		new String:sValue[8];
		GetCmdArg(2, sValue, sizeof(sValue));

		TED_SetNetprop(client, sNetProp, sValue);
		return Plugin_Handled;
	} else {
		ReplyToCommand(client, "Usage: sm_ted_set <netprop> <value>");
		return Plugin_Handled;
	}
}

public Action:Command_SelectSelf(client,args) {
	TED_SelectEntity(client, client);
	return Plugin_Handled;
}


public Action:Command_ShowNetprops(client,args) {
	TED_ShowNetprops(client);
	return Plugin_Handled;
}

public Action:Command_WatchNetprops(client,args) {
	TED_WatchNetprops(client);
	return Plugin_Handled;
}

public Action:Command_StopWatchNetprops(client,args) {
	TED_StopWatchNetprops(client);
	return Plugin_Handled;
}

public Action:Command_SaveNetprops(client,args) {
	TED_SaveNetprops(client);
	return Plugin_Handled;
}

public Action:Command_CompareNetprops(client,args) {
	TED_CompareNetprops(client);
	return Plugin_Handled;
}

public Action:Command_IgnoreNetprop(client,args) {
	if(args == 1) {
		new String:sNetProp[32];
		GetCmdArg(1, sNetProp, sizeof(sNetProp));

		TED_IgnoreNetprop(client, sNetProp);
	} else {
		ReplyToCommand(client, "Usage: sm_ted_ignore <netprop>");
	}

	return Plugin_Handled;
}

public Action:Command_UnIgnoreNetprop(client,args) {
	if(args == 1) {
		new String:sNetProp[32];
		GetCmdArg(1, sNetProp, sizeof(sNetProp));

		TED_UnignoreNetprop(client, sNetProp);
	} else {
		ReplyToCommand(client, "Usage: sm_ted_unignore <netprop>");
	}

	return Plugin_Handled;
}
