//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#pragma unused cvarEnabled
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#include <smlib>
#include <updater>

#define PLUGIN_VERSION "0.0.3"
#define PLUGIN_DESCRIPTION "Adds a game modifier that only allows pistols"
#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-pistolsonly.txt"

new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?

public Plugin:myinfo = {
	name= "[INS] Pistols Only",
	author  = "Jared Ballou (jballou)",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com/"
};

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_pistolsonly_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_pistolsonly_enabled", "0", "sets whether ammo check is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);
	//RegConsoleCmd("check_ammo", Check_Ammo);
	HookEvent("weapon_pickup", Event_WeaponPickup);
	HookEvent("weapon_deploy", Event_WeaponDeploy);
	HookEvent("player_first_spawn", Event_PlayerSpawn);
	HookEvent("player_spawn", Event_PlayerSpawn);
	PrintToServer("[PISTOLSONLY] Started!");
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
public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userId = GetEventInt(event, "userid");
	if (userId > 0)
	{
		new user = GetClientOfUserId(userId);
		if (user)
		{
			PrintToServer("[PISTOLSONLY] loop through weapons for client %d named %N <%d>",user,user,userId);
			new primary = GetPlayerWeaponSlot(user, 0);
			if (IsValidEntity(primary))
			{
				PrintToServer("[PISTOLSONLY] Removing primary %d",primary);
				RemovePlayerItem(user,primary);
				AcceptEntityInput(primary, "kill");
			}
		}
	}
	return Plugin_Continue;
}
public OnMapStart()
{
}
public OnClientDisconnect(client)
{
}
public Action:Event_WeaponDeploy(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userId = GetEventInt(event, "userid");
	if (userId > 0)
	{
		new user = GetClientOfUserId(userId);
		if (user)
		{
			return CheckWeapon(user);
		}
	}
	return Plugin_Continue;
}
public Action:Event_WeaponPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userId = GetEventInt(event, "userid");
	if (userId > 0)
	{
		new user = GetClientOfUserId(userId);
		if (user)
		{
			return CheckWeapon(user);
		}
	}
	return Plugin_Continue;	
}
stock Action:CheckWeapon(client)
{
	if(!IsClientInGame(client))
		return Plugin_Continue;
	new ActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (ActiveWeapon < 0)
		return Plugin_Continue;
	decl String:sWeapon[32];
	GetEdictClassname(ActiveWeapon, sWeapon, sizeof(sWeapon));
	PrintToServer("[PISTOLSONLY] CheckWeapon for client %d named %N ActiveWeapon %d sWeapon %s",client,client,ActiveWeapon,sWeapon);
	if (!GetConVarBool(cvarEnabled))
		return Plugin_Continue;	

	if (
		((StrContains(sWeapon, "weapon_ak74") > -1))
		|| ((StrContains(sWeapon, "weapon_akm") > -1))
		|| ((StrContains(sWeapon, "weapon_aks74u") > -1))
		|| ((StrContains(sWeapon, "weapon_fal") > -1))
		|| ((StrContains(sWeapon, "weapon_l1a1") > -1))
		|| ((StrContains(sWeapon, "weapon_m14") > -1))
		|| ((StrContains(sWeapon, "weapon_m16a4") > -1))
		|| ((StrContains(sWeapon, "weapon_m1a1") > -1))
		|| ((StrContains(sWeapon, "weapon_m249") > -1))
		|| ((StrContains(sWeapon, "weapon_m40a1") > -1))
		|| ((StrContains(sWeapon, "weapon_m4a1") > -1))
		|| ((StrContains(sWeapon, "weapon_m590") > -1))
		|| ((StrContains(sWeapon, "weapon_mini14") > -1))
		|| ((StrContains(sWeapon, "weapon_mk18") > -1))
		|| ((StrContains(sWeapon, "weapon_mk48") > -1))
		|| ((StrContains(sWeapon, "weapon_mosin") > -1))
		|| ((StrContains(sWeapon, "weapon_mp40") > -1))
		|| ((StrContains(sWeapon, "weapon_mp5") > -1))
		|| ((StrContains(sWeapon, "weapon_rpk") > -1))
		|| ((StrContains(sWeapon, "weapon_sks") > -1))
		|| ((StrContains(sWeapon, "weapon_toz") > -1))
		|| ((StrContains(sWeapon, "weapon_ump45") > -1))
	)
	{
		PrintToServer("[PISTOLSONLY] Denying ActiveWeapon %d sWeapon %s",ActiveWeapon,sWeapon);
		RemovePlayerItem(client,ActiveWeapon);
		AcceptEntityInput(ActiveWeapon, "kill");
		new secondary = GetPlayerWeaponSlot(client, 1); 
		if (IsValidEntity(secondary))
			Client_SetActiveWeapon(client, secondary);
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

/*
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponEquip, Weapon_Equip);
}

public Action:Weapon_Equip(client, weapon)
{
	Check_Ammo(client, GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon"));
}
*/
