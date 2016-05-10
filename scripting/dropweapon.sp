//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <insurgency>
#undef REQUIRE_PLUGIN
#include <updater>

#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-dropweapon.txt"

#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_DESCRIPTION "Adds a drop command"
#define PLUGIN_NAME "[INS] Drop Weapon"
#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_URL "http://jballou.com/"
#define PLUGIN_WORKING "1"

public Plugin:myinfo = {
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url		= PLUGIN_URL
};

new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_dropweapon_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_dropweapon_enabled", PLUGIN_WORKING, "sets whether weapon dropping is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);
	RegConsoleCmd("drop", Command_Drop);
	//HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	PrintToServer("[DROPWEAPON] Started!");
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnLibraryAdded(const String:name[]) {
	if (StrEqual(name, "updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}
}

public Action:Command_Drop(client, args) {
	return Drop(client);
}
public Action:Drop(client) {
	//PrintToServer("[DROPWEAPON] Check_Ammo!");
	// If disabled, return
	if (!GetConVarBool(cvarEnabled)) {
		return Plugin_Handled;
	}
	// If no active weapon, return
	new m_hActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (m_hActiveWeapon < 0) {
		return Plugin_Handled;
	}
	// Do not drop knives
	decl String:strBuf[32];
	Ins_GetWeaponName(m_hActiveWeapon, strBuf, sizeof(strBuf));
	if(StrEqual("weapon_knife", strBuf) || StrEqual("weapon_kabar", strBuf) || StrEqual("weapon_gurkha", strBuf) || StrEqual("weapon_kukri", strBuf)) {
		return Plugin_Handled;
	}
	// Drop weapon
	SDKHooks_DropWeapon(client,m_hActiveWeapon);
	return Plugin_Handled;
}
