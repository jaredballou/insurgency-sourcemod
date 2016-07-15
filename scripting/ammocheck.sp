//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#define PLUGIN_DESCRIPTION "Adds a check_ammo command for clients to get approximate ammo left in magazine, and display the same message when loading a new magazine"
#define PLUGIN_NAME "Ammo Check"
#define PLUGIN_VERSION "1.0.2"
#define PLUGIN_WORKING "1"
#define PLUGIN_LOG_PREFIX "AMMOCHECK"
#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_URL "http://jballou.com/insurgency"
#define UPDATE_URL "http://ins.jballou.com/sourcemod/update-ammocheck.txt"

public Plugin:myinfo = {
        name            = PLUGIN_NAME,
        author          = PLUGIN_AUTHOR,
        description     = PLUGIN_DESCRIPTION,
        version         = PLUGIN_VERSION,
        url             = PLUGIN_URL
};

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <insurgency>
#undef REQUIRE_PLUGIN
#include <updater>

new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
new Handle:h_AmmoTimers[MAXPLAYERS+1];
new i_TimerWeapon[MAXPLAYERS+1];


new Handle:cvarAttackDelay = INVALID_HANDLE; //Attack delay for spawning bots
new m_flNextPrimaryAttack, m_flNextSecondaryAttack;

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_ammocheck_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_ammocheck_enabled", "1", "sets whether ammo check is enabled", FCVAR_NOTIFY);

	cvarAttackDelay = CreateConVar("sm_ammocheck_attack_delay", "1", "Delay in seconds until next attack when checking ammo", FCVAR_NOTIFY);

	RegConsoleCmd("check_ammo", Command_Check_Ammo, "Check ammo of the current weapon");
	HookEvent("weapon_reload", Event_WeaponReload,  EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	if ((m_flNextPrimaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextPrimaryAttack")) == -1) {
		SetFailState("Fatal Error: Unable to find property offset \"CBaseCombatWeapon::m_flNextPrimaryAttack\" !");
	}

	if ((m_flNextSecondaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextSecondaryAttack")) == -1) {
		SetFailState("Fatal Error: Unable to find property offset \"CBaseCombatWeapon::m_flNextSecondaryAttack\" !");
	}

	if (LibraryExists("updater")) {
		Updater_AddPlugin(UPDATE_URL_FORMAT(PLUGIN_FILE));
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater")) {
		Updater_AddPlugin(UPDATE_URL_FORMAT(PLUGIN_FILE));
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
	float flNextPrimaryAttack = GetEntPropFloat(ActiveWeapon,Prop_Data,"m_flNextPrimaryAttack");
	h_AmmoTimers[client] = CreateTimer((flNextPrimaryAttack-GetGameTime())+0.5, Timer_Check_Ammo, client);
}
public Action:Event_WeaponReload(Handle:event, const String:name[], bool:dontBroadcast)
{
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
	Check_Ammo(client);
	return Plugin_Stop;
}

public Action:Command_Check_Ammo(client, args)
{
	if (CheckAndSetAttackDelay(client)) {
		return Check_Ammo(client);
	}
	return Plugin_Continue;
}
float CheckAndSetAttackDelay(client) {
	new ActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (ActiveWeapon < 0) {
		return 0.0;
	}
	// Don't allow checking if next attack time is in the future
	float flNextPrimaryAttack = GetEntPropFloat(ActiveWeapon,Prop_Data,"m_flNextPrimaryAttack");
	float flNextSecondaryAttack = GetEntPropFloat(ActiveWeapon,Prop_Data,"m_flNextSecondaryAttack");
	if (flNextPrimaryAttack > GetGameTime() || flNextSecondaryAttack > GetGameTime()){
		return 0.0;
	}
	float flDelay = GetGameTime() + GetConVarFloat(cvarAttackDelay);
	SetEntDataFloat(ActiveWeapon, m_flNextPrimaryAttack, flDelay);
	SetEntDataFloat(ActiveWeapon, m_flNextSecondaryAttack, flDelay);
	return flDelay;
}
public Action:Check_Ammo(client) {
	if (!GetConVarBool(cvarEnabled)) {
		KillAmmoTimer(client);
		return Plugin_Handled;
	}
	// Don't run if no active weapon
	new ActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (ActiveWeapon < 0) {
		KillAmmoTimer(client);
		return Plugin_Handled;
	}

	// Don't run if the active weapon doesn't match the timer
	if ((i_TimerWeapon[client]) && (i_TimerWeapon[client] != ActiveWeapon)) {
		KillAmmoTimer(client);
		return Plugin_Handled;
	}

	new maxammo = Ins_GetWeaponGetMaxClip1(ActiveWeapon);
	new ammo = GetEntProp(ActiveWeapon, Prop_Send, "m_iClip1", 1);
	//Don't do it if we have a small magazine, usually means single shot weapon
	if (maxammo <= 2) {
		KillAmmoTimer(client);
		return Plugin_Handled;
	}
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

public OnClientPutInServer(client) {
	SDKHook(client, SDKHook_WeaponEquip, Weapon_Equip);
}

public Action:Weapon_Equip(client, weapon) {
	Check_Ammo(client);
	return Plugin_Continue;
}
