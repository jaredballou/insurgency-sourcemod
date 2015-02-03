#pragma semicolon 1
#pragma unused cvarVersion
#pragma unused cvarTimer

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <updater>

#define PLUGIN_VERSION "0.0.3"
#define PLUGIN_DESCRIPTION "Puts a compass in the game"
#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-compass.txt"

public Plugin:myinfo = {
	name= "[INS] Compass",
	author  = "Jared Ballou (jballou)",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com/"
};
new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
new Handle:cvarDirection = INVALID_HANDLE;
new Handle:cvarBearing = INVALID_HANDLE;
new Handle:cvarTimer = INVALID_HANDLE;

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_compass_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_compass_enabled", "1", "Enables compass", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarDirection = CreateConVar("sm_compass_direction", "1", "Display direction in ordinal directions", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarBearing = CreateConVar("sm_compass_bearing", "1", "Display bearing in degrees", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarTimer = CreateConVar("sm_compass_timer", "0", "If greater than 0, display compass to players every X seconds.", FCVAR_NOTIFY | FCVAR_PLUGIN);

	RegConsoleCmd("check_compass", Check_Compass);
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public Action:Check_Compass(client, args)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Handled;
	}
	decl Float:angle[3],Float:bearing;
	new String:sDisplay[512];
	GetClientEyeAngles(client, angle);
//E -1 to 0
//N 90
//W -180 to 180
//S -90
	if (angle[1] >= 90.0) { // W to N
		bearing = 270.0 + (180.0 - angle[1]);
	} else if (angle[1]) { //W to N
		bearing = 90.0 - angle[1];
	} else if (angle[1] >= -90) {
		bearing = 90.0 + (0.0 - angle[1]);
	} else {
		bearing = 180.0 - (angle[1] + 90.0);
	}
	if (GetConVarBool(cvarDirection))
	{
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
		//If also adding bearing, add a line break
		if (GetConVarBool(cvarBearing))
		{
			Format(sDisplay,sizeof(sDisplay),"%s\n",sDisplay);
		}
	}
	if (GetConVarBool(cvarBearing))
	{
		Format(sDisplay,sizeof(sDisplay),"%sBearing: %0.1f\xc2\xb0",sDisplay,bearing);
	}
	PrintHintText(client, "%s",sDisplay);
	return Plugin_Handled;
}
