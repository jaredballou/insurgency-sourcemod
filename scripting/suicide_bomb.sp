//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#include <updater>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#pragma unused cvarVersion

#define PLUGIN_VERSION "0.0.3"
#define PLUGIN_DESCRIPTION "Adds suicide bomb for bots"
#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-suicide_bomb.txt"

new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
new Handle:cvarExplodeArmed = INVALID_HANDLE;
new Handle:cvarDeathChance = INVALID_HANDLE;

new String:g_client_last_classstring[MAXPLAYERS+1][64];
new bool:bEnabled = false;

public Plugin:myinfo = {
	name= "[INS] Suicide Bombers",
	author  = "Jared Ballou (jballou)",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com/"
};

public OnPluginStart()
{
	PrintToServer("[SUICIDE] Starting");
	cvarVersion = CreateConVar("sm_suicidebomb_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_suicidebomb_enabled", "0", "sets whether suicide bombs are enabled", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarExplodeArmed = CreateConVar("sm_suicidebomb_explode_armed", "0", "Explode when killed if C4 or IED is in hand", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarDeathChance = CreateConVar("sm_suicidebomb_death_chance", "0.1", "Chance as a fraction of 1 that a bomber will explode when killed", FCVAR_NOTIFY | FCVAR_PLUGIN, true, 0.0, true, 1.0);

	HookConVarChange(cvarEnabled,ConVarChanged);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_pick_squad", Event_PlayerPickSquad);
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
public ConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == cvarEnabled)
		bEnabled = bool:StringToInt(newVal);
}
public Event_PlayerPickSquad(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToServer("[SUICIDE] Running Event_PlayerPickSquad");
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	decl String:class_template[64];
	GetEventString(event, "class_template",class_template,sizeof(class_template));
	if( client) {
		g_client_last_classstring[client] = class_template;
	}
	return;
}
public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	return Plugin_Continue;
}
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	//PrintToServer("[SUICIDE] Running Event_PlayerDeath");
	if (!bEnabled)
	{
		return Plugin_Continue;
	}
	new victimId = GetEventInt(event, "userid");
	PrintToServer("[SUICIDE] Victim ID is %d",victimId);
	if (victimId > 0)
	{
		new victim = GetClientOfUserId(victimId);
		CheckExplode(victim);
	}
	return Plugin_Continue;
}
public CheckExplode(client) {
	new m_iSquad = GetEntProp(client, Prop_Send, "m_iSquad");
	new m_iSquadSlot = GetEntProp(client, Prop_Send, "m_iSquadSlot");
	new bool:bExplodeArmed = GetConVarBool(cvarExplodeArmed);
	new Float:fDeathChance = GetConVarFloat(cvarDeathChance);

	PrintToServer("[SUICIDE] Running CheckExplode for client %d name %N squad %d squadslot %d",client,client,m_iSquad,m_iSquadSlot);
	if (!bEnabled)
	{
		return;
	}
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return;
	}
	if ((!(StrContains(g_client_last_classstring[client], "bomber") > -1)) && (!(StrContains(g_client_last_classstring[client], "sapper") > -1)) && (!(StrContains(g_client_last_classstring[client], "suicide") > -1)))
	{
		return;
	}
	//Assign random variable first
	new Float:fRandom = GetRandomFloat(0.0, 1.0);
	new String:shotWeapName[32];
	GetClientWeapon(client, shotWeapName, sizeof(shotWeapName));
	if (
		((StrContains(shotWeapName,"weapon_ied") > -1)
		|| (StrContains(shotWeapName,"weapon_c4") > -1))
		&& bExplodeArmed
	) {
		fRandom = 0.0;
	}
	if (fRandom > fDeathChance)
	{
		return;
	}
	PrintToServer("[SUICIDE] Blowing Up %N with class %s!",client,g_client_last_classstring[client]);
	new Float:vecOrigin[3],Float:vecAngles[3];
	GetClientEyePosition(client, vecOrigin);

	new ent = CreateEntityByName("grenade_ied");
	if(IsValidEntity(ent))
	{
		PrintToServer("[SUICIDE] Created IED entity");
		vecAngles[0] = vecAngles[1] = vecAngles[2] = 0.0;
		TeleportEntity(ent, vecOrigin, vecAngles, vecAngles);
		SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
		SetEntProp(ent, Prop_Data, "m_nNextThinkTick", 1); //for smoke
		SetEntProp(ent, Prop_Data, "m_takedamage", 2);
		SetEntProp(ent, Prop_Data, "m_iHealth", 1);
		if (DispatchSpawn(ent)) {
			PrintToServer("[SUICIDE] Detonating IED entity");
			DealDamage(ent,1000,client,DMG_BLAST,"weapon_ied");
		}
	}
}
DealDamage(victim,damage,attacker=0,dmg_type=DMG_GENERIC,String:weapon[]="")
{
	if(victim>0 && IsValidEdict(victim) && damage>0)
	{
		new String:dmg_str[16];
		IntToString(damage,dmg_str,16);
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		new pointHurt=CreateEntityByName("point_hurt");
		if(pointHurt)
		{
			DispatchKeyValue(victim,"targetname","hurtme");
			DispatchKeyValue(pointHurt,"DamageTarget","hurtme");
			DispatchKeyValue(pointHurt,"Damage",dmg_str);
			DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
			if(!StrEqual(weapon,""))
			{
				DispatchKeyValue(pointHurt,"classname",weapon);
			}
			DispatchSpawn(pointHurt);
			AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
			DispatchKeyValue(pointHurt,"classname","point_hurt");
			DispatchKeyValue(victim,"targetname","donthurtme");
			RemoveEdict(pointHurt);
		}
	}
}
