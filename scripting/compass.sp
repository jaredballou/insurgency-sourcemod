#pragma semicolon 1
#pragma unused cvarVersion
#pragma unused cvarTimer

#include <sourcemod>
#include <clientprefs>
#include <smlib>
//#include <sdktools>
//#include <smlib>
#include <insurgency>
#undef REQUIRE_PLUGIN
#include <updater>

#define PLUGIN_VERSION "0.0.6"
#define PLUGIN_DESCRIPTION "Puts a compass in the game"
#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-compass.txt"

public Plugin:myinfo = {
	name= "[INS] Compass",
	author  = "Jared Ballou (jballou)",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com/"
};
#define TIMER_MIN 0
#define TIMER_MAX 360
#define TIMER_STEP 15

new Float:g_lastChecked[MAXPLAYERS+1];
new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
new Handle:cvarDirection = INVALID_HANDLE;
new Handle:cvarBearing = INVALID_HANDLE;
new Handle:cvarTimer = INVALID_HANDLE;
new Handle:cvDefaultEnabled	= INVALID_HANDLE;
new Handle:cvDefaultTimer	= INVALID_HANDLE;
new Handle:cvDefaultDisplay	= INVALID_HANDLE;
new Handle:cvDefaultDirection	= INVALID_HANDLE;
new Handle:cvDefaultBearing	= INVALID_HANDLE;
//	enabledForClient[client] = GetConVarBool(cvDefaultPref);

new
	Handle:ckEnabled = INVALID_HANDLE,
	clientEnabled[MAXPLAYERS + 1],
	Handle:ckTimer = INVALID_HANDLE,
	clientTimer[MAXPLAYERS + 1],
	Handle:ckDisplay = INVALID_HANDLE,
	clientDisplay[MAXPLAYERS + 1],
	Handle:ckDirection = INVALID_HANDLE,
	clientDirection[MAXPLAYERS + 1],
	Handle:ckBearing = INVALID_HANDLE,
	clientBearing[MAXPLAYERS + 1],
	bool:cookiesEnabled = false;

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_compass_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_compass_enabled", "1", "Enables compass", FCVAR_NOTIFY);
	cvarDirection = CreateConVar("sm_compass_direction", "1", "Display direction in ordinal directions", FCVAR_NOTIFY);
	cvarBearing = CreateConVar("sm_compass_bearing", "1", "Display bearing in degrees", FCVAR_NOTIFY);
	cvarTimer = CreateConVar("sm_compass_timer", "0", "If greater than 0, display compass to players every X seconds.", FCVAR_NOTIFY);

	cvDefaultEnabled	= CreateConVar("sm_compass_default_enabled",		"1",		"Default compass",);
	cvDefaultTimer		= CreateConVar("sm_compass_default_timer",		"60",		"Default compass",);
	cvDefaultDisplay	= CreateConVar("sm_compass_default_display",		"1",		"Default compass",);
	cvDefaultDirection	= CreateConVar("sm_compass_default_direction",		"1",		"Default compass",);
	cvDefaultBearing	= CreateConVar("sm_compass_default_bearing",		"1",		"Default compass",);

	RegConsoleCmd("check_compass", Check_Compass);
	CreateTimer(1.0, TimerCompass, _, TIMER_REPEAT);
	LoadTranslations("compass.phrases");
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	cookiesEnabled = (GetExtensionFileStatus("clientprefs.ext") == 1);

	if (cookiesEnabled) {
		// prepare title for clientPref menu
		decl String:menutitle[64];
		Format(menutitle, sizeof(menutitle), "%T", "name", LANG_SERVER);
		SetCookieMenuItem(CompassSettingsMenu, 0, menutitle);

//		SetCookieMenuItem(PrefMenu, 0, menutitle);

		ckEnabled = RegClientCookie("compass_enabled", "", CookieAccess_Public);
		ckTimer = RegClientCookie("compass_timer", "Display compass on timer", CookieAccess_Public);
		ckDisplay = RegClientCookie("compass_display", "Display in chatbox (0), top center (1), lower center (2), or side menu (3)", CookieAccess_Public);
		ckBearing = RegClientCookie("compass_bearing", "Display compass bearing in degrees", CookieAccess_Public);
		ckDirection = RegClientCookie("compass_direction", "Display compass direction", CookieAccess_Public);

		LOOP_CLIENTS(client, CLIENTFILTER_INGAME | CLIENTFILTER_NOBOTS) {

			if (!AreClientCookiesCached(client)) {
				continue;
			}

			LoadCookies(client);
		}
	}
}
public OnClientCookiesCached(client)
{
	if (IsClientInGame(client)) {
		LoadCookies(client);
	}
}

public OnClientPutInServer(client)
{
	if (cookiesEnabled && AreClientCookiesCached(client)) {
		LoadCookies(client);
	}
}

public OnClientConnected(client)
{
	LoadCookies(client);
}
public SaveCookies(client)
{
	decl String:sCookieValue[11];
	IntToString(clientEnabled[client], sCookieValue, sizeof(sCookieValue));
	SetClientCookie(client, ckEnabled, sCookieValue);
	IntToString(clientTimer[client], sCookieValue, sizeof(sCookieValue));
	SetClientCookie(client, ckTimer, sCookieValue);
	IntToString(clientDisplay[client], sCookieValue, sizeof(sCookieValue));
	SetClientCookie(client, ckDisplay, sCookieValue);
	IntToString(clientDirection[client], sCookieValue, sizeof(sCookieValue));
	SetClientCookie(client, ckDirection, sCookieValue);
	IntToString(clientBearing[client], sCookieValue, sizeof(sCookieValue));
	SetClientCookie(client, ckBearing, sCookieValue);
}

public LoadCookies(client)
{
	decl String:preference[8];

	GetClientCookie(client, ckEnabled, preference, sizeof(preference));
	if (StrEqual(preference, "")) {
		clientEnabled[client] = GetConVarInt(cvDefaultEnabled);
	}
	else {
		clientEnabled[client] = StringToInt(preference);
	}
	GetClientCookie(client, ckDisplay, preference, sizeof(preference));
	if (StrEqual(preference, "")) {
		clientDisplay[client] = GetConVarInt(cvDefaultDisplay);
	}
	else {
		clientDisplay[client] = StringToInt(preference);
	}
	GetClientCookie(client, ckTimer, preference, sizeof(preference));
	if (StrEqual(preference, "")) {
		clientTimer[client] = GetConVarInt(cvDefaultTimer);
	}
	else {
		clientTimer[client] = StringToInt(preference);
	}
	GetClientCookie(client, ckBearing, preference, sizeof(preference));
	if (StrEqual(preference, "")) {
		clientBearing[client] = GetConVarInt(cvDefaultBearing);
	}
	else {
		clientBearing[client] = StringToInt(preference);
	}
	GetClientCookie(client, ckDirection, preference, sizeof(preference));
	if (StrEqual(preference, "")) {
		clientDirection[client] = GetConVarInt(cvDefaultDirection);
	}
	else {
		clientDirection[client] = StringToInt(preference);
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public Action:TimerCompass(Handle:timer)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return;
	}
	for (new client=1;client <= MaxClients; client++)
	{
		if (Client_IsValid(client,true))
		{
			if ((clientEnabled[client]) && (GetGameTime() >= (g_lastChecked[client] + clientTimer[client])))
			{
				Display_Compass(client);
			}
		}
	}
}
public Action:Check_Compass(client, args)
{
/*
	new Float:distance,Float:vecOrigin[3],Float:vecTarget[3];
	GetClientAbsOrigin(client,vecOrigin);
	for (new iTarget = 1; iTarget < MaxClients; iTarget++)
	{
		if (IsValidClient(iTarget))
		{
			GetClientAbsOrigin(iTarget,vecTarget);
			distance = GetVectorDistance(vecTarget,vecOrigin);
			PrintToServer("[BOTSPAWNS] Distance from %N to %N is %f",client,iTarget,distance);
		}
	}
*/	
	if (GetConVarBool(cvarEnabled))
	{
		Display_Compass(client);
	}
	return Plugin_Handled;
}
public Display_Compass(client)
{
	if (!Client_IsValid(client,true))
	{
		return;
	}
	new target = client;
	if(Client_IsIngame(client) && IsClientObserver(client) && GetClientHealth(client) == 0)
	{
		new ObsTarget = Client_GetObserverTarget(client);
		if(Client_IsValid(ObsTarget,true) && Client_IsIngame(ObsTarget))
		{
			target = ObsTarget;
		}	
	}
	else if(!Client_IsIngame(client))
	{
		return;
	}
	g_lastChecked[client] = GetGameTime();

	decl Float:angle[3],Float:bearing;
	new String:sDisplay[512];
	GetClientEyeAngles(target, angle);
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
	if (clientDirection[client] && GetConVarBool(cvarDirection))
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
		if (clientBearing[client] && GetConVarBool(cvarBearing))
		{
			if (clientDisplay[client] == 1)
			{
				Format(sDisplay,sizeof(sDisplay),"%s - ",sDisplay);
			}
			else
			{
				Format(sDisplay,sizeof(sDisplay),"%s\n",sDisplay);
			}
		}
	}
	if (clientBearing[client] && GetConVarBool(cvarBearing))
	{
		if (clientDisplay[client] != 1)
		{
			Format(sDisplay,sizeof(sDisplay),"%s%T: ",sDisplay,"bearing",LANG_SERVER);
		}
		Format(sDisplay,sizeof(sDisplay),"%s%0.1f\xc2\xb0",sDisplay,bearing);
	}
	switch (clientDisplay[client])
	{
		case 0: //Chat box
			PrintHintText(client, "%s",sDisplay);
		case 1: //Top center
			PrintCenterText(client, "%s",sDisplay);
		case 2: //Bottom center
			PrintHintText(client, "%s",sDisplay);

		case 3: //Side menu
		{
			new Handle:CompassPanel = CreatePanel(INVALID_HANDLE);
			DrawPanelText(CompassPanel, sDisplay);
			SendPanelToClient(CompassPanel, client, NullMenuHandler, 1);
			CloseHandle(CompassPanel);
		}
	}
	return;
}
public NullMenuHandler(Handle:menu, MenuAction:action, param1, param2) 
{
}
























public CompassSettingsMenu(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_SelectOption)
	{
		DisplayCompassMenuMain(client);
	}
}

//AAAAAAAAAAAAAAAAAAAAAAAAAA
public DisplayCompassMenuMain(client)
{
	new Handle:MenuHandle = CreateMenu(CompassMainCommandHandler, MenuAction_Select|MenuAction_Cancel);
	decl String:menutitle[64];
	Format(menutitle, sizeof(menutitle), "%T", "name", LANG_SERVER);
	Format(menutitle, sizeof(menutitle), "%s - %T", menutitle, "name", LANG_SERVER);
	SetMenuTitle(MenuHandle, menutitle);
	if (clientEnabled[client])
	{
		Format(menutitle, sizeof(menutitle), "%T", "enabled", LANG_SERVER);
	}
	else
	{
		Format(menutitle, sizeof(menutitle), "%T", "disabled", LANG_SERVER);
	}
	AddMenuItem(MenuHandle, "", menutitle);

	if (clientDirection[client])
	{
		Format(menutitle, sizeof(menutitle), "%T [X]", "direction", LANG_SERVER);
	}
	else
	{
		Format(menutitle, sizeof(menutitle), "%T [ ]", "direction", LANG_SERVER);
	}
	AddMenuItem(MenuHandle, "", menutitle);

	if (clientBearing[client])
	{
		Format(menutitle, sizeof(menutitle), "%T [X]", "bearing", LANG_SERVER);
	}
	else
	{
		Format(menutitle, sizeof(menutitle), "%T [ ]", "bearing", LANG_SERVER);
	}
	AddMenuItem(MenuHandle, "", menutitle);


	Format(menutitle, sizeof(menutitle), "%T", "timer", LANG_SERVER);
	Format(menutitle, sizeof(menutitle), "%s: %d", menutitle, clientTimer[client]);
	AddMenuItem(MenuHandle, "", menutitle);
	Format(menutitle, sizeof(menutitle), "display%d", clientDisplay[client]);
	Format(menutitle, sizeof(menutitle), "%T", menutitle, LANG_SERVER);
	Format(menutitle, sizeof(menutitle), "%T: %s", "display", LANG_SERVER, menutitle);
	AddMenuItem(MenuHandle, "", menutitle);
	SetMenuPagination(MenuHandle, 8);
	SetMenuExitBackButton(MenuHandle,true);
	DisplayMenu(MenuHandle, client, MENU_TIME_FOREVER);
}
public CompassMainCommandHandler(Handle:hMenu, MenuAction:action, client, selection)
{
	if (action == MenuAction_Select)
	{
		if (IsClientInGame(client))
		{
			switch (selection)
			{
				case 0 :
				{
					clientEnabled[client] = (!clientEnabled[client]);
					SaveCookies(client);
					DisplayCompassMenuMain(client);
				}
				case 1 :
				{
					clientDirection[client] = (!clientDirection[client]);
					SaveCookies(client);
					DisplayCompassMenuMain(client);
				}
				case 2 :
				{
					clientBearing[client] = (!clientBearing[client]);
					SaveCookies(client);
					DisplayCompassMenuMain(client);
				}
				case 3 :
					DisplayCompassMenuTimer(client);
				case 4 :
					DisplayCompassMenuDisplay(client);
			}
		}
	}
	else if (action == MenuAction_End) {
		CloseHandle(hMenu);
	}
}


public DisplayCompassMenuTimer(client)
{
	new Handle:MenuHandle = CreateMenu(CompassTimerCommandHandler, MenuAction_Select|MenuAction_Cancel);

	decl String:menutitle[64];
	Format(menutitle, sizeof(menutitle), "%T", "name", LANG_SERVER);
	Format(menutitle, sizeof(menutitle), "%s - %T", menutitle, "timer", LANG_SERVER);
	Format(menutitle, sizeof(menutitle), "%s (%d %T)", menutitle, clientTimer[client], "seconds", LANG_SERVER);
	SetMenuTitle(MenuHandle, menutitle);
	Format(menutitle, sizeof(menutitle), "+%d %T", TIMER_STEP, "seconds", LANG_SERVER);
	AddMenuItem(MenuHandle, "", menutitle);
	Format(menutitle, sizeof(menutitle), "-%d %T", TIMER_STEP, "seconds", LANG_SERVER);
	AddMenuItem(MenuHandle, "", menutitle);
	SetMenuPagination(MenuHandle, 8);
	SetMenuExitBackButton(MenuHandle,true);
	DisplayMenu(MenuHandle, client, MENU_TIME_FOREVER);
}

public CompassTimerCommandHandler(Handle:hMenu, MenuAction:action, client, selection)
{
	if (action == MenuAction_Select)
	{
		if (IsClientInGame(client))
		{
			switch (selection)
			{
				case 0 : 
					if ((clientTimer[client] + TIMER_STEP) <= TIMER_MAX)
					{
						clientTimer[client] += TIMER_STEP;
					}
					else
					{
						clientTimer[client] = TIMER_MAX;
					}
				case 1 : 
					if ((clientTimer[client] - TIMER_STEP) >= TIMER_MIN)
					{
						clientTimer[client] -= TIMER_STEP;
					}
					else
					{
						clientTimer[client] = TIMER_MIN;
					}
			}
			SaveCookies(client);
			DisplayCompassMenuTimer(client);
		}
	}
	else if (action == MenuAction_End) {
		CloseHandle(hMenu);
	}
}

public DisplayCompassMenuDisplay(client)
{
	new Handle:MenuHandle = CreateMenu(CompassDisplayCommandHandler, MenuAction_Select|MenuAction_Cancel);
	decl String:menutitle[64];
	Format(menutitle, sizeof(menutitle), "display%d", clientDisplay[client]);
	Format(menutitle, sizeof(menutitle), "%T", menutitle, LANG_SERVER);
	Format(menutitle, sizeof(menutitle), "%T - %s", "display", LANG_SERVER, menutitle);
	SetMenuTitle(MenuHandle, menutitle);
	for (new i=0;i<4;i++)
	{
		Format(menutitle, sizeof(menutitle), "display%d", i);
		Format(menutitle, sizeof(menutitle), "%T", menutitle, LANG_SERVER);
		if (i == clientDisplay[client])
		{
			Format(menutitle, sizeof(menutitle), "%s [X]", menutitle);
		}
		else
		{
			Format(menutitle, sizeof(menutitle), "%s [ ]", menutitle);
		}
		AddMenuItem(MenuHandle, "", menutitle);
	}
	SetMenuPagination(MenuHandle, 8);
	SetMenuExitBackButton(MenuHandle,true);
	DisplayMenu(MenuHandle, client, MENU_TIME_FOREVER);
}

public CompassDisplayCommandHandler(Handle:hMenu, MenuAction:action, client, selection)
{
	if (action == MenuAction_Select)
	{
		if (IsClientInGame(client))
		{
			if ((selection >= 0) && (selection < 4))
			{
				clientDisplay[client] = selection;
				SaveCookies(client);
			}
		}
		DisplayCompassMenuDisplay(client);
	}
	else if (action == MenuAction_End) {
		CloseHandle(hMenu);
	}
}
