//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#pragma unused cvarVersion

#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_DESCRIPTION "Adds suicide bomb for bots"
new Handle:cvarVersion; // version cvar!
new Handle:cvarEnabled; // are we enabled?

new String:g_client_last_classstring[MAXPLAYERS+1][64];
	


public Plugin:myinfo = {
	name= "[INS] Suicide Bombers",
	author  = "Jared Ballou (jballou)",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com/"
};

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_suicidebomb_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_suicidebomb_enabled", "0", "sets whether suicide bombs are enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_pick_squad", Event_PlayerPickSquad);
}
public Event_PlayerPickSquad(Handle:event, const String:name[], bool:dontBroadcast)
{
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
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	new victimId = GetEventInt(event, "victim");
	if (victimId > 0)
	{
		new victim = GetClientOfUserId(victimId);
		CheckExplode(victim);
	}
	return Plugin_Continue;
}
public CheckExplode(client) {
	PrintToServer("[SUICIDE] Running CheckExplode");
	if (!GetConVarBool(cvarEnabled))
	{
		return;
	}
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return;
	}		
	if ((!(StrContains(g_client_last_classstring[client], "bomber") > -1)) && (!(StrContains(g_client_last_classstring[client], "suicide") > -1)))
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
	if(victim>0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim) && damage>0)
	{
		new String:dmg_str[16];
		IntToString(damage,dmg_str,16);
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		new pointHurt=CreateEntityByName("point_hurt");
		if(pointHurt)
		{
			DispatchKeyValue(victim,"targetname","war3_hurtme");
			DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
			DispatchKeyValue(pointHurt,"Damage",dmg_str);
			DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
			if(!StrEqual(weapon,""))
			{
				DispatchKeyValue(pointHurt,"classname",weapon);
			}
			DispatchSpawn(pointHurt);
			AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
			DispatchKeyValue(pointHurt,"classname","point_hurt");
			DispatchKeyValue(victim,"targetname","war3_donthurtme");
			RemoveEdict(pointHurt);
		}
	}
}
