//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_DESCRIPTION "Adds a check_ammo command for clients to get approximate ammo left in magazine, and display the same message when loading a new magazine"

new Handle:cvarVersion; // version cvar!
new Handle:cvarEnabled; // are we enabled?
new i_fullmag[MAXPLAYERS+1];
new Handle:WeaponsTrie;
new ammoOffset;

public Plugin:myinfo = {
	name= "[INS] Ammo Check",
	author  = "Jared Ballou (jballou)",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com/"
};

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_ammocheck_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_ammocheck_enabled", "1", "sets whether ammo check is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);
	RegConsoleCmd("check_ammo", Check_Ammo);
	HookEvent("weapon_reload", Event_Weapon_Reload,  EventHookMode_Pre);
	WeaponsTrie = CreateTrie();
	ammoOffset = FindSendPropInfo("CINSPlayer", "m_iAmmo");
//	new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo");
}
public OnMapStart()
{
	ClearTrie(WeaponsTrie);
}

public Action:Event_Weapon_Reload(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:classname[256];
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsClientInGame(client))
		return Plugin_Handled;
	//new ActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	new ActiveWeapon = GetPlayerWeaponSlot(client, 0);
	new String:sWeaponName[64];
	GetClientWeapon(client, sWeaponName, sizeof(sWeaponName));
	GetEntityClassname(ActiveWeapon, classname, sizeof(classname));
	Update_Magazine(client,ActiveWeapon);

	return Plugin_Continue;
}

public Action:Check_Ammo(client, args)
{
	if (!GetConVarBool(cvarEnabled)) {
		return Plugin_Handled;
	}
	new ammo = GetEntData(client, ammoOffset+4);
	new pct = (ammo / i_fullmag[client]);
	if (pct > 0.85) {
		PrintHintText(client, "Mag feels full");
	} else if (pct > 0.62) {
		PrintHintText(client, "Mag feels mostly full");
	} else if (pct > 0.35) {
		PrintHintText(client, "Mag feels half full");
	} else if (pct > 0.2) {
		PrintHintText(client, "Mag feels nearly empty");
	} else {
		PrintHintText(client, "Mag feels empty");
	}
	return Plugin_Handled;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponEquip, Weapon_Equip);
}

public Action:Weapon_Equip(client, weapon)
{
	Update_Magazine(client,weapon);
	Check_Ammo(client,0);
//	return Plugin_Handled;
}
public Update_Magazine(client,weapon)
{
	if(IsClientInGame(client) && IsValidEntity(weapon))
	{
		decl String:sWeapon[32]; 
		GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
		new ammo = GetEntProp(weapon, Prop_Data, "m_iClip1");
		new maxammo;
		GetTrieValue(WeaponsTrie, sWeapon, maxammo);
		if (maxammo < ammo)
		{
			PrintToServer("[AMMOCHECK] Updated Trie! Changed max ammo for %s from %d to %d",sWeapon,maxammo,ammo);
			maxammo = ammo;
			SetTrieValue(WeaponsTrie, sWeapon, ammo);
		}
		i_fullmag[client] = maxammo;
	}
}
