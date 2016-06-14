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

#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_DESCRIPTION "Adds a number of new ways to get score, or remove score for players"
#define PLUGIN_NAME "[INS] Score Modifiers"
#define PLUGIN_URL "http://jballou.com/insurgency"
#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_WORKING 1

public Plugin:myinfo = {
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url		= PLUGIN_URL
};


#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-score.txt"

#pragma unused cvarEnabled

new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_score_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_score_enabled", "1", "sets whether score modifier is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);
	RegConsoleCmd("check_score", Command_check_score);
	HookEvent("weapon_reload", Event_WeaponReload,  EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	PrintToServer("[score] Started!");
	LoadTranslations("common.phrases");
	LoadTranslations("score.phrases");
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
/*
	new victimId = GetEventInt(event, "victim");
	if (victimId > 0)
	{
		new victim = GetClientOfUserId(victimId);
	}
*/
	return Plugin_Continue;
}
public OnMapStart()
{
}
public OnClientDisconnect(client)
{
}
public Action:Event_WeaponReload(Handle:event, const String:name[], bool:dontBroadcast)
{
/*
	//PrintToServer("[score] Event_WeaponReload! name %s",name);
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsClientInGame(client))
		return Plugin_Continue;
	new ActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (ActiveWeapon < 0)
		return Plugin_Continue;
	CreateAmmoTimer(client,ActiveWeapon);
*/
	return Plugin_Continue;
}

public Action:Command_check_score(client, args)
{
	new iPlayerManager, String:iPlayerManagerNetClass[32];
	iPlayerManager = FindEntityByClassname(0,"ins_player_manager");
	GetEntityNetClass(iPlayerManager, iPlayerManagerNetClass, sizeof(iPlayerManagerNetClass));
	if (iPlayerManager < 1)
	{
		PrintToServer("[SCORE] Unable to find ins_player_manager");
		return Plugin_Stop;
	}
	
	PrintToServer("[SCORE] iPlayerManagerNetClass %s",iPlayerManagerNetClass);
	new m_iPlayerScore = FindSendPropOffs(iPlayerManagerNetClass, "m_iPlayerScore");
	if (m_iPlayerScore < 1) {
		PrintToServer("[SCORE] Unable to find ins_player_manager property m_iPlayerScore");
		return Plugin_Stop;
	}
	new iScore;
	for (new i=0;i<24;i++) {
		iScore = GetEntData(iPlayerManager, m_iPlayerScore + (16 * i));
		PrintToServer("[SCORE] player %d score %d",i,iScore);
	}
// = GetEntPropEnt(iPlayerManager, Prop_Data, "m_iPlayerScore");
//GetEntData(iPlayerManager, FindSendPropOffs(iPlayerManagerNetClass, prop) + (size * element));
	return Plugin_Stop;
}

public OnClientPutInServer(client)
{
//	SDKHook(client, SDKHook_WeaponEquip, Weapon_Equip);
}

public Action:Weapon_Equip(client, weapon)
{
	//PrintToServer("[score] Weapon_Equip!");
//	check_score(client);
	return Plugin_Continue;
}
