//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#include <updater>

#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_DESCRIPTION "Adds ability to loot items from dead bodies"
#define PLUGIN_NAME "[INS] Looting"
#define PLUGIN_URL "http://jballou.com/insurgency"
#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_WORKING 0

public Plugin:myinfo = {
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url		= PLUGIN_URL
};

#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-looting.txt"
new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
new Handle:cvarMode = INVALID_HANDLE;

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_looting_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_looting_enabled", "1", "sets whether looting is enabled", FCVAR_NOTIFY);
	cvarMode = CreateConVar("sm_looting_mode", "1", "sets looting mode - 0: Loot per mag, 1: Loot all ammo", FCVAR_NOTIFY);
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
	PrintToServer("[LOOTING] Event_PlayerDeath starting");
	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	//new victim = GetEventInt(event, "victim");
	//new ammo = GetEntProp(victim, Prop_Send, "m_iAmmo");
	new ragdoll = GetEntDataEnt2(victim, FindSendPropInfo("CINSPlayer", "m_hRagdoll"));
	PrintToServer("[LOOTING] victim %N (%d) ragdoll %d",victim,victim,ragdoll);
	//new m_iAmmo = FindSendPropInfo("CINSPlayer", "m_iAmmo");
	new ammo = -1;
	new max = GetEntPropArraySize(victim, Prop_Send, "m_iAmmo");
	for (new i = 0; i < max; i++)
	{
		if ((ammo = GetEntProp(victim, Prop_Send, "m_iAmmo", _, i)) > 0)
			PrintToServer("[LOOTING]Slot %d, Ammo %d", i, ammo);
	}

/*
	new ammo[256];
	for (new i=0;i<256;i++)
	{
		ammo[i] = GetEntProp(victim, Prop_Send, "m_iAmmo", _, i); // Player ammunition for this weapon ammo type
		if (ammo[i])
		{
			PrintToServer("[LOOTING] victim ammo index %d is %d",i,ammo[i]);
		}
	}
	//new weapon = GetEntDataEnt2(victim, FindSendPropInfo("CINSPlayer", "m_hActiveWeapon"));
	//new m_iPrimaryAmmoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType"); // Ammo type
	//new m_iSecondaryAmmoType = GetEntProp(weapon, Prop_Send, "m_iSecondaryAmmoType");

	if(m_iPrimaryAmmoType != -1)
	{
		m_iClip1 = GetEntProp(weapon, Prop_Send, "m_iClip1"); // weapon clip amount bullets
		m_iAmmo_prim = GetEntProp(client, Prop_Send, "m_iAmmo", _, m_iPrimaryAmmoType); // Player ammunition for this weapon ammo type
	}
	if(m_iSecondaryAmmoType != -1)
	{
		m_iClip2 = GetEntProp(weapon, Prop_Send, "m_iClip2");
		m_iAmmo_sec = GetEntProp(client, Prop_Send, "m_iAmmo", _, m_iSecondaryAmmoType);
	}
*/
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
	if (!GetConVarInt(cvarMode))
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
