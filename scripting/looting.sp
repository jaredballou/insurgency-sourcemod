//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#include <updater>

#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_DESCRIPTION "Adds ability to loot items from dead bodies"
#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-looting.txt"

new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?

public Plugin:myinfo = {
	name= "[INS] Looting",
	author  = "Jared Ballou (jballou)",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com/"
};

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_looting_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_looting_enabled", "1", "sets whether ammo check is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);
	RegConsoleCmd("loot", Loot_Body);
	HookEvent("weapon_pickup", Event_WeaponPickup);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	PrintToServer("[LOOTING] Started!");
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
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
//	new victimId = GetEventInt(event, "victim");
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	return Plugin_Continue;
}
public Action:Event_WeaponPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
/*
	PrintToServer("[LOOTING] Event_WeaponPickup started");
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new weaponid = GetEventInt(event, "weaponid");
	if(!IsClientInGame(client))
		return Plugin_Handled;
	new ActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (ActiveWeapon < 0)
		return Plugin_Handled;
	if (weaponid)
	{
		decl String:sWeapon[32];
		GetEdictClassname(ActiveWeapon, sWeapon, sizeof(sWeapon));
		PrintToServer("[LOOTING] Client %N ActiveWeapon %d sWeapon %s weaponid %d",client,ActiveWeapon,sWeapon,weaponid);
	}
*/
	return Plugin_Continue;
}

public Action:Loot_Body(client, args)
{
	PrintToServer("[LOOTING] Loot_Body called");
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Handled;
	}
	//new m_iPrimaryAmmoType = GetEntProp(i, Prop_Send, "m_iPrimaryAmmoType");
/*
	new ActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (ActiveWeapon < 0)
	{
		return Plugin_Handled;
	}
	decl String:sWeapon[32];
	new maxammo;
	GetEdictClassname(ActiveWeapon, sWeapon, sizeof(sWeapon));
	new ammo = GetEntProp(ActiveWeapon, Prop_Send, "m_iClip1", 1);
	new m_bChamberedRound = GetEntData(ActiveWeapon, FindSendPropInfo("CINSWeaponBallistic", "m_bChamberedRound"),1);
	if (m_bChamberedRound)
		ammo++;
*/
	return Plugin_Handled;
}
/*
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponEquip, Weapon_Equip);
}

public Action:Weapon_Equip(client, weapon)
{
	//PrintToServer("[LOOTING] Weapon_Equip!");
	Check_Ammo(client, GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon"));
//	return Plugin_Handled;
}
*/
