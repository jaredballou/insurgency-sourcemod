#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.0.1"

public Plugin:myinfo = {
name= "Compass",
author  = "Jared Ballou (jballou)",
description = "Puts a compass in the game",
version = PLUGIN_VERSION,
url = "http://jballou.com/"
};

public OnPluginStart()
{
	RegConsoleCmd("check_compass", Check_Compass);
}

public Action:Check_Compass(client, args)
{
//	new Handle:hHudText = CreateHudSynchronizer();
//	SetHudTextParams(-1.0, 0.2, 5.0, 255, 0, 0, 255);
	decl Float:angle[3];
	new String:sDisplay[512];
	GetClientEyeAngles(client, angle);
	if ((angle[1] < -158)  || (angle[1] > 158)) {
		sDisplay[0] = 'W';
	} else if (angle[1] < -113) {
		sDisplay[0] = 'S';
		sDisplay[1] = 'W';
	} else if (angle[1] < -68) {
		sDisplay[0] = 'S';
	} else if (angle[1] < -22) {
		sDisplay[0] = 'S';
		sDisplay[1] = 'E';
	} else if (angle[1] < 22) {
		sDisplay[0] = 'E';
	} else if (angle[1] < 67) {
		sDisplay[0] = 'N';
		sDisplay[1] = 'E';
	} else if (angle[1] < 112) {
		sDisplay[0] = 'N';
	} else {
		sDisplay[0] = 'N';
		sDisplay[1] = 'W';
	}
	PrintHintText(client, "%s",sDisplay);
//	ShowSyncHudText(client, hHudText, "%s",sDisplay);
//	CloseHandle(hHudText);
	return Plugin_Handled;
}  
