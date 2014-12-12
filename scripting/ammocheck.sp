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
new Handle:hReloadTimer[MAXPLAYERS+1];

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
	HookEvent("weapon_reload", Event_WeaponEventMagUpdate,  EventHookMode_Post);
	HookEvent("weapon_fire", Event_WeaponEventMagUpdate,  EventHookMode_Pre);
	WeaponsTrie = CreateTrie();
	PrintToServer("[AMMOCHECK] Started!");
}

public OnMapStart()
{
	ClearTrie(WeaponsTrie);
}
public Action:Event_WeaponEventMagUpdate(Handle:event, const String:name[], bool:dontBroadcast)
{
	//PrintToServer("[AMMOCHECK] Event_WeaponMagUpdate! name %s",name);
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsClientInGame(client))
		return Plugin_Handled;
	new ActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	Update_Magazine(client,ActiveWeapon);
	if(StrEqual(name, "weapon_reload"))
	{
		new Float:timedone = GetEntPropFloat(ActiveWeapon,Prop_Data,"m_flNextPrimaryAttack");
		//PrintToServer("[AMMOCHECK] Reload Timer Started with %f time is %f timer is %f!",timedone,GetGameTime(),(timedone-GetGameTime()));
		hReloadTimer[client] = CreateTimer((timedone-GetGameTime())+0.5, Timer_Check_Ammo, client, TIMER_REPEAT);
	}
	return Plugin_Continue;
}

public Action:Timer_Check_Ammo(Handle:event, any:client)
{
	//PrintToServer("[AMMOCHECK] Reload timer finished!");
	Check_Ammo(client,0);
	return Plugin_Stop;
}

public OnClientDisconnect(client)
{
	if (hReloadTimer[client] != INVALID_HANDLE)
	{
		KillTimer(hReloadTimer[client]);
		hReloadTimer[client] = INVALID_HANDLE;
	}
}

public Action:Check_Ammo(client, args)
{
	//PrintToServer("[AMMOCHECK] Check_Ammo!");
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Handled;
	}
	new ActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (ActiveWeapon < 0)
	{
		return Plugin_Handled;
	}
	Update_Magazine(client,ActiveWeapon);
	decl String:sWeapon[32];
	new maxammo;
	GetEdictClassname(ActiveWeapon, sWeapon, sizeof(sWeapon));
	GetTrieValue(WeaponsTrie, sWeapon, maxammo);
	new ammo = GetEntProp(ActiveWeapon, Prop_Send, "m_iClip1", 1);
	//PrintHintText(client, "sWeapon %s ActiveWeapon %d ammo %d maxammo %d",sWeapon,ActiveWeapon,ammo,maxammo);
	//PrintToServer("[AMMOCHECK] sWeapon %s ActiveWeapon %d ammo %d maxammo %d",sWeapon,ActiveWeapon,ammo,maxammo);
	if (ammo >= maxammo) {
		PrintHintText(client, "Mag is full");
	} else if (ammo > (maxammo * 0.85)) {
		PrintHintText(client, "Mag feels full");
	} else if (ammo > (maxammo * 0.62)) {
		PrintHintText(client, "Mag feels mostly full");
	} else if (ammo > (maxammo * 0.35)) {
		PrintHintText(client, "Mag feels half full");
	} else if (ammo > (maxammo * 0.2)) {
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
	//PrintToServer("[AMMOCHECK] Weapon_Equip!");
	Check_Ammo(client,0);
//	return Plugin_Handled;
}
public Update_Magazine(client,weapon)
{
	//PrintToServer("[AMMOCHECK] Update_Magazine!");
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
