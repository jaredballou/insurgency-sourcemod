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

#define PLUGIN_VERSION "0.0.7"
#define PLUGIN_DESCRIPTION "Adds a check_ammo command for clients to get approximate ammo left in magazine, and display the same message when loading a new magazine"
#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-ammocheck.txt"

new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
new Handle:h_AmmoTimers[MAXPLAYERS+1];
new i_TimerWeapon[MAXPLAYERS+1];

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
	RegConsoleCmd("check_ammo", Command_Check_Ammo);
	HookEvent("weapon_reload", Event_WeaponReload,  EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	PrintToServer("[AMMOCHECK] Started!");
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
	new victimId = GetEventInt(event, "victim");
	if (victimId > 0)
	{
		new victim = GetClientOfUserId(victimId);
		KillAmmoTimer(victim);
	}
	return Plugin_Continue;
}
public OnMapStart()
{
}
public OnClientDisconnect(client)
{
	KillAmmoTimer(client);
}
public KillAmmoTimer(client)
{
	if (h_AmmoTimers[client] != INVALID_HANDLE)
	{
		KillTimer(h_AmmoTimers[client]);
		h_AmmoTimers[client] = INVALID_HANDLE;
		i_TimerWeapon[client] = -1;
	}
}

public CreateAmmoTimer(client,ActiveWeapon)
{
	KillAmmoTimer(client);
	i_TimerWeapon[client] = ActiveWeapon;
	new Float:timedone = GetEntPropFloat(ActiveWeapon,Prop_Data,"m_flNextPrimaryAttack");
	//PrintToServer("[AMMOCHECK] Reload Timer Started with %f time is %f timer is %f!",timedone,GetGameTime(),(timedone-GetGameTime()));
	h_AmmoTimers[client] = CreateTimer((timedone-GetGameTime())+0.5, Timer_Check_Ammo, client);
}
public Action:Event_WeaponReload(Handle:event, const String:name[], bool:dontBroadcast)
{
	//PrintToServer("[AMMOCHECK] Event_WeaponReload! name %s",name);
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsClientInGame(client))
		return Plugin_Continue;
	new ActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (ActiveWeapon < 0)
		return Plugin_Continue;
	CreateAmmoTimer(client,ActiveWeapon);
	return Plugin_Continue;
}

public Action:Timer_Check_Ammo(Handle:event, any:client)
{
	//PrintToServer("[AMMOCHECK] Reload timer finished!");
	Check_Ammo(client);
	return Plugin_Stop;
}

public Action:Command_Check_Ammo(client, args)
{
	return Check_Ammo(client);
}
public Action:Check_Ammo(client)
{
	//PrintToServer("[AMMOCHECK] Check_Ammo!");
	if (!GetConVarBool(cvarEnabled))
	{
		KillAmmoTimer(client);
		return Plugin_Handled;
	}
	new ActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (ActiveWeapon < 0)
	{
		KillAmmoTimer(client);
		return Plugin_Handled;
	}
	if ((i_TimerWeapon[client]) && (i_TimerWeapon[client] != ActiveWeapon))
	{
		KillAmmoTimer(client);
		return Plugin_Handled;
	}
	new maxammo = Ins_GetWeaponGetMaxClip1(ActiveWeapon);
	new ammo = GetEntProp(ActiveWeapon, Prop_Send, "m_iClip1", 1);
	if (maxammo <= 2) //Don't do it if we have a small magazine, usually means single shot weapon
	{
		KillAmmoTimer(client);
		return Plugin_Handled;
	}
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
	KillAmmoTimer(client);
	return Plugin_Handled;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponEquip, Weapon_Equip);
}

public Action:Weapon_Equip(client, weapon)
{
	//PrintToServer("[AMMOCHECK] Weapon_Equip!");
	Check_Ammo(client);
	return Plugin_Continue;
}
