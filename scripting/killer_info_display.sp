#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#include <smlib>

#define PLUGIN_VERSION "1.4.1"


/****************************************************************
			P L U G I N   I N F O
*****************************************************************/

public Plugin:myinfo = {
	name		= "Killer Info Display",
	author		= "Berni, gH0sTy, Smurfy1982, Snake60",
	description	= "Displays the health, the armor and the weapon of the player who has killed you",
	version		= PLUGIN_VERSION,
	url			= "http://forums.alliedmods.net/showthread.php?p=670361"
}


/****************************************************************
			G L O B A L   V A R S
*****************************************************************/

// ConVar Handles
new
	Handle:cvVersion			= INVALID_HANDLE,
	Handle:cvPrinttochat		= INVALID_HANDLE,
	Handle:cvPrinttopanel		= INVALID_HANDLE,
	Handle:cvShowweapon			= INVALID_HANDLE,
	Handle:cvShowarmorleft		= INVALID_HANDLE,
	Handle:cvShowdistance		= INVALID_HANDLE,
	Handle:cvDistancetype		= INVALID_HANDLE,
	Handle:cvAnnouncetime		= INVALID_HANDLE,
	Handle:cvDefaultPref		= INVALID_HANDLE;

// Misc Vars
new
	bool:enabledForClient[MAXPLAYERS + 1],
	Handle:cookie = INVALID_HANDLE,
	bool:cookiesEnabled = false;

/****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) 
{ 
    MarkNativeAsOptional("GetUserMessageType"); 
    return APLRes_Success; 
}

public OnPluginStart()
{	
	// ConVars
	cvVersion = CreateConVar("kid_version", PLUGIN_VERSION, "Killer info display plugin version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	// Set it to the correct version, in case the plugin gets updated...
	SetConVarString(cvVersion, PLUGIN_VERSION);

	cvPrinttochat		= CreateConVar("kid_printtochat",		"1",		"Prints the killer info to the victims chat",);
	cvPrinttopanel		= CreateConVar("kid_printtopanel",		"1",		"Displays the killer info to the victim as a panel",);
	cvShowweapon		= CreateConVar("kid_showweapon",		"1",		"Set to 1 to show the weapon the player got killed with, 0 to disable.",);
	cvShowarmorleft		= CreateConVar("kid_showarmorleft",		"1",		"Set to 0 to disable, 1 to show the armor, 2 to show the suitpower the killer has left.",);
	cvShowdistance		= CreateConVar("kid_showdistance",		"1",		"Set to 1 to show the distance to the killer, 0 to disable.",);
	cvDistancetype		= CreateConVar("kid_distancetype",		"meters",	"Set to \"meters\" to show the distance in \"meters\" or \"feet\" for feet.",);
	cvAnnouncetime		= CreateConVar("kid_announcetime",		"5",		"Time in seconds after an announce about turning killer infos on/off is printed to chat, set to -1 to disable.",);
	cvDefaultPref		= CreateConVar("kid_defaultpref",		"1",		"Default client preference (0 - killer info display off, 1 - killer info display on)",);

	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);

	// create or load cfg
	AutoExecConfig(true);

	// add translations support
	LoadTranslations("killer_info_display.phrases");
	
	cookiesEnabled = (GetExtensionFileStatus("clientprefs.ext") == 1);

	if (cookiesEnabled) {
		// prepare title for clientPref menu
		decl String:menutitle[64];
		Format(menutitle, sizeof(menutitle), "%T", "name", LANG_SERVER);
		SetCookieMenuItem(PrefMenu, 0, menutitle);
		cookie = RegClientCookie("killerinfo", "Enable (\"on\") / Disable (\"off\") Display of Killer Info", CookieAccess_Public);

		LOOP_CLIENTS(client, CLIENTFILTER_INGAME | CLIENTFILTER_NOBOTS) {

			if (!AreClientCookiesCached(client)) {
				continue;
			}

			ClientIngameAndCookiesCached(client);
		}
	}

	RegConsoleCmd("sm_killerinfo", Command_KillerInfo, "On/Off Killer info display");
}

public OnClientCookiesCached(client)
{
	if (IsClientInGame(client)) {
		ClientIngameAndCookiesCached(client);
	}
}

public OnClientPutInServer(client)
{
	if (cookiesEnabled && AreClientCookiesCached(client)) {
		ClientIngameAndCookiesCached(client);
	}
}

public OnClientConnected(client)
{
	enabledForClient[client] = true;
}

/***************************************************************
			C A L L B A C K   F U N C T I O N S
****************************************************************/

public PrefMenu(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_SelectOption) {
		DisplaySettingsMenu(client);
	}
}

public PrefMenuHandler(Handle:prefmenu, MenuAction:action, client, item)
{
	if (action == MenuAction_Select) {
		decl String:preference[8];

		GetMenuItem(prefmenu, item, preference, sizeof(preference));

		enabledForClient[client] = bool:StringToInt(preference);

		if (enabledForClient[client]) {
			SetClientCookie(client, cookie, "on");
		}
		else {
			SetClientCookie(client, cookie, "off");
		}

		DisplaySettingsMenu(client);
	}
	else if (action == MenuAction_End) {
		CloseHandle(prefmenu);
	}
}

public Action:Command_KillerInfo(client, args)
{
	if (client == 0) {
		ReplyToCommand(client, "[Killer Info] This command can only be run by players.");
		return Plugin_Handled;
	}

	if (enabledForClient[client]) {
		enabledForClient[client] = false;

		Color_ChatSetSubject(client);
		Client_Reply(client, "{G}[Killer Info] {N}%t", "kid_disabled");

		if (cookiesEnabled) {
			SetClientCookie(client, cookie, "off");
		}
	}
	else {
		enabledForClient[client] = true;

		Color_ChatSetSubject(client);
		Client_Reply(client, "{G}[Killer Info] {N}%t", "kid_enabled");

		if (cookiesEnabled) {
			SetClientCookie(client, cookie, "on");
		}
	}

	return Plugin_Handled;
}

public Action:Timer_Announce(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);

	// Check for invalid client serial
	if (client == 0) {
		return Plugin_Stop;
	}

	Color_ChatSetSubject(client);
	Client_PrintToChat(client, false, "{G}[Killer Info] {N}%t", "announcement");

	return Plugin_Stop;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client		= GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker	= GetClientOfUserId(GetEventInt(event, "attacker"));
	new dominated	= GetEventBool(event, "dominated");
	new revenge		= GetEventBool(event, "revenge");

	if (client == 0 || attacker == 0 || client == attacker) {
		return Plugin_Continue;
	}
	
	if (!enabledForClient[client]) {
		return Plugin_Continue;
	}

	decl
		String:weapon[32],
		String:unitType[8],
		String:distanceType[5];

	new
		Float:distance,
		armor;

	new healthLeft = GetClientHealth(attacker);
	new showArmorLeft = GetConVarInt(cvShowarmorleft);
	new bool:showDistance = GetConVarBool(cvShowdistance);
	new bool:showWeapon = GetConVarBool(cvShowweapon);

	GetEventString(event, "weapon", weapon, sizeof(weapon));		
	GetConVarString(cvDistancetype, distanceType, sizeof(distanceType));

	if (showArmorLeft > 0) {

		if (showArmorLeft == 1) {
			armor = Client_GetArmor(attacker);
		}
		else {
			armor = RoundFloat(Client_GetSuitPower(client));
		}
	}

	if (showDistance) {
		
		distance = Entity_GetDistance(client, attacker);
		
		if (StrEqual(distanceType, "feet", false)) {
			distance = Math_UnitsToFeet(distance);
			Format(unitType, sizeof(unitType), "%t", "feet");
		}
		else {
			distance = Math_UnitsToMeters(distance);
			Format(unitType, sizeof(unitType), "%t", "meters");
		}
	}

	// Print To Chat ?
	if ((GetConVarBool(cvPrinttochat))) {
		
		decl
			String:chat_weapon[64]		= "",
			String:chat_distance[64]	= "",
			String:chat_armor[64]		= "";
			
		if (showWeapon) {
			Format(chat_weapon, sizeof(chat_weapon), " %t", "chat_weapon", weapon);
		}
		
		if (showDistance) {
			Format(chat_distance, sizeof(chat_distance), " %t", "chat_distance", distance, unitType);
		}

		if (GetConVarBool(cvShowarmorleft) && armor > 0) {
			Format(chat_armor, sizeof(chat_armor), " %t", "chat_armor", armor, showArmorLeft == 1 ? "armor" : "suitpower");
		}

		Color_ChatSetSubject(attacker);
		Client_PrintToChat(
			client,
			false,
			"{G}[Killer Info] {N}%t",
			"chat_basic",
			attacker,
			chat_weapon,
			chat_distance,
			healthLeft,
			chat_armor
		);

		if (dominated) {
			Color_ChatSetSubject(attacker);
			Client_PrintToChat(
				client,
				false,
				"{G}[Killer Info] {N}%t",
				"dominated", attacker
			);
		}

		if (revenge) {
			Color_ChatSetSubject(attacker);
			Client_PrintToChat(
				client,
				false,
				"{G}[Killer Info] {N}%t",
				"revenge", attacker
			);
		}
	}

	// Print To Panel ?
	if ((GetConVarBool(cvPrinttopanel))) {

		new Handle:panel= CreatePanel();
		decl String:buffer[128];

		Format(buffer, sizeof(buffer), "%t", "panel_killer", attacker);
		SetPanelTitle(panel, buffer);

		DrawPanelItem(panel, "", ITEMDRAW_SPACER);
		
		if (showWeapon) {
			Format(buffer, sizeof(buffer), "%t", "panel_weapon", weapon);
			DrawPanelItem(panel, buffer, ITEMDRAW_DEFAULT);
		}

		Format(buffer, sizeof(buffer), "%t", "panel_health", healthLeft);
		DrawPanelItem(panel, buffer, ITEMDRAW_DEFAULT);

		if (showArmorLeft > 0 && armor > 0) {
			Format(buffer, sizeof(buffer), "%t", "panel_armor", showArmorLeft == 1 ? "armor" : "suitpower", armor);
			DrawPanelItem(panel, buffer, ITEMDRAW_DEFAULT);
		}

		if (showDistance) {
			Format(buffer, sizeof(buffer), "%t", "panel_distance", distance, unitType);
			DrawPanelItem(panel, buffer, ITEMDRAW_DEFAULT);
		}
		
		DrawPanelItem(panel, "", ITEMDRAW_SPACER);

		if (dominated) {
			decl String:strippedText[64];
			Format(buffer, sizeof(buffer), "%t", "dominated", attacker);

			// We remove all colors, by parsing them first
			// and then stripping the control codes, ugly - but it works.
			Color_ParseChatText(buffer, strippedText, sizeof(strippedText));
			Color_StripFromChatText(strippedText, strippedText, sizeof(strippedText));

			DrawPanelItem(panel, strippedText, ITEMDRAW_DEFAULT);
		}

		if (revenge) {
			decl String:strippedText[64];
			Format(buffer, sizeof(buffer), "%t", "revenge", attacker);

			// We remove all colors, by parsing them first
			// and then stripping the control codes, ugly - but it works.
			Color_ParseChatText(buffer, strippedText, sizeof(strippedText));
			Color_StripFromChatText(strippedText, strippedText, sizeof(strippedText));

			DrawPanelItem(panel, strippedText, ITEMDRAW_DEFAULT);
		}

		SetPanelCurrentKey(panel, 10);
		SendPanelToClient(panel, client, Handler_DoNothing, 20);
		CloseHandle(panel);
	}

	return Plugin_Continue;
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2) {}

/***************************************************************
			P L U G I N    F U N C T I O N S
****************************************************************/

ClientIngameAndCookiesCached(client)
{
	decl String:preference[8];
	GetClientCookie(client, cookie, preference, sizeof(preference));

	if (StrEqual(preference, "")) {
		enabledForClient[client] = GetConVarBool(cvDefaultPref);
	}
	else {
		enabledForClient[client] = !StrEqual(preference, "off", false);
	}

	new Float:announceTime = GetConVarFloat(cvAnnouncetime);

	if (announceTime > 0.0) {
		CreateTimer(announceTime, Timer_Announce, GetClientSerial(client));
	}
}

DisplaySettingsMenu(client)
{
	decl String:MenuItem[128];
	new Handle:prefmenu = CreateMenu(PrefMenuHandler);

	Format(MenuItem, sizeof(MenuItem), "%t", "name");
	SetMenuTitle(prefmenu, MenuItem);

	new String:checked[] = String:0x9A88E2;
	
	Format(MenuItem, sizeof(MenuItem), "%t [%s]", "enabled", enabledForClient[client] ? checked : "   ");
	AddMenuItem(prefmenu, "1", MenuItem);

	Format(MenuItem, sizeof(MenuItem), "%t [%s]", "disabled", enabledForClient[client] ? "   " : checked);
	AddMenuItem(prefmenu, "0", MenuItem);

	DisplayMenu(prefmenu, client, MENU_TIME_FOREVER);
}
