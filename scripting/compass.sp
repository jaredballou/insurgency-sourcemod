#pragma semicolon 1
#pragma unused cvarVersion

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_DESCRIPTION "Puts a compass in the game"

public Plugin:myinfo = {
	name= "[INS] Compass",
	author  = "Jared Ballou (jballou)",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com/"
};
new Handle:cvarVersion; // version cvar!
new Handle:cvarEnabled; // are we enabled?
public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_compass_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_compass_enabled", "1", "sets whether bot naming is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);

	RegConsoleCmd("check_compass", Check_Compass);
}

public Action:Check_Compass(client, args)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return true;
	}
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
