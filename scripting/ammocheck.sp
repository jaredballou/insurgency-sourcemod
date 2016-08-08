//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#define PLUGIN_DESCRIPTION "Adds a check_ammo command for clients to get approximate ammo left in magazine, and display the same message when loading a new magazine"
#define PLUGIN_NAME "Ammo Check"
#define PLUGIN_VERSION "1.0.4"
#define PLUGIN_WORKING "1"
#define PLUGIN_LOG_PREFIX "AMMOCHECK"
#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_URL "http://jballou.com/insurgency"

public Plugin:myinfo = {
        name            = PLUGIN_NAME,
        author          = PLUGIN_AUTHOR,
        description     = PLUGIN_DESCRIPTION,
        version         = PLUGIN_VERSION,
        url             = PLUGIN_URL
};

//#pragma newdecls required
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

new Handle:g_hReloadTimers[MAXPLAYERS+1];
int g_iReloadTimer[MAXPLAYERS+1];
float g_flAttackDelay[MAXPLAYERS+1];


new Handle:cvarAttackDelay = INVALID_HANDLE; //Attack delay for spawning bots
new g_flNextPrimaryAttack, g_flNextSecondaryAttack;

public OnPluginStart() {
	cvarVersion = CreateConVar("sm_ammocheck_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_ammocheck_enabled", "1", "Allow clients to use check_ammo and post-reload ammo checks", FCVAR_NOTIFY);

	cvarAttackDelay = CreateConVar("sm_ammocheck_attack_delay", "1", "Delay in seconds until next attack when checking ammo", FCVAR_NOTIFY);

	RegConsoleCmd("check_ammo", Command_Check_Ammo, "Check ammo of the current weapon");
	HookEvent("weapon_reload", Event_WeaponReload,  EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);

	g_flNextPrimaryAttack = GetSendProp("CBaseCombatWeapon", "m_flNextPrimaryAttack");
	g_flNextSecondaryAttack = GetSendProp("CBaseCombatWeapon", "m_flNextSecondaryAttack");

	HookUpdater();
}

public OnLibraryAdded(const String:name[]) {
	HookUpdater();
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	new victimId = GetEventInt(event, "victim");
	if (victimId > 0) {
		new victim = GetClientOfUserId(victimId);
		KillReloadTimer(victim);
	}
	return Plugin_Continue;
}
public OnClientDisconnect(client) {
	KillReloadTimer(client);
}
/**
 * Kill the ammo check timer for a client
 *
 * @param client	Client number
 */
public KillReloadTimer(client) {
	if (g_hReloadTimers[client] != INVALID_HANDLE) {
		KillTimer(g_hReloadTimers[client]);
		g_hReloadTimers[client] = INVALID_HANDLE;
	}
	g_iReloadTimer[client] = -1;
	g_flAttackDelay[client] = 0.0;
}

/**
 * Create the ammo check timer for a client
 *
 * @param client	Client number
 * @param ActiveWeapon	Weapon entity ID, so that we only run the check for this weapon.
 */
public CreateReloadTimer(client,ActiveWeapon) {
	KillReloadTimer(client);
	g_iReloadTimer[client] = ActiveWeapon;
	float flNextPrimaryAttack = GetEntPropFloat(ActiveWeapon,Prop_Data,"m_flNextPrimaryAttack");
	g_hReloadTimers[client] = CreateTimer((flNextPrimaryAttack-GetGameTime())+0.5, Timer_Check_Ammo, client);
}

public Action:Event_WeaponReload(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsClientInGame(client))
		return Plugin_Continue;
	new ActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (ActiveWeapon < 0)
		return Plugin_Continue;
	CreateReloadTimer(client,ActiveWeapon);
	return Plugin_Continue;
}

/**
 * Called by timer after reload to check ammo
 *
 * @param event		Event handle
 * @param client	Client number
 */
public Action:Timer_Check_Ammo(Handle:event, any:client) {
	Check_Ammo(client);
	return Plugin_Stop;
}

/**
 * Run each time the command is called by a client
 *
 * @param client	Client number
 */
public Action:Command_Check_Ammo(client, args) {
	if (CheckAndSetAttackDelay(client)) {
		return Check_Ammo(client);
	}
	return Plugin_Continue;
}

/**
 * Make sure that the client ammo check can be executed, and set an attack
 * delay. This is so that calling the check_ammo command will have a small
 * penalty for using the command. This is not called by the post-reload check.
 *
 * @param client	Client number
 */
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
	SetEntDataFloat(ActiveWeapon, g_flNextPrimaryAttack, flDelay);
	SetEntDataFloat(ActiveWeapon, g_flNextSecondaryAttack, flDelay);
	g_flAttackDelay[client] = flDelay;
	return flDelay;
}

/**
 * Do the actual check and display result to client.
 *
 * @param client	Client number
 */
public Action:Check_Ammo(client) {
	if (!GetConVarBool(cvarEnabled)) {
		KillReloadTimer(client);
		return Plugin_Handled;
	}
	// Don't run if no active weapon
	new ActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (ActiveWeapon < 0) {
		KillReloadTimer(client);
		return Plugin_Handled;
	}

	// Don't run if the active weapon doesn't match the timer
	if ((g_iReloadTimer[client]) && (g_iReloadTimer[client] != ActiveWeapon)) {
		KillReloadTimer(client);
		return Plugin_Handled;
	}
	new maxammo = Ins_GetWeaponGetMaxClip1(ActiveWeapon);
	new ammo = GetEntProp(ActiveWeapon, Prop_Send, "m_iClip1", 1);
	//Don't do it if we have a small magazine, usually means single shot weapon
	if (maxammo <= 2) {
		KillReloadTimer(client);
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
	KillReloadTimer(client);
	return Plugin_Handled;
}

public OnClientPutInServer(client) {
	SDKHook(client, SDKHook_WeaponEquip, Weapon_Equip);
}

public Action:Weapon_Equip(client, weapon) {
	Check_Ammo(client);
	return Plugin_Continue;
}
