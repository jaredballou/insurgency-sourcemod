//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#include <updater>
#include <smlib>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "0.0.2"
#define PLUGIN_DESCRIPTION "Adjusts behavior of 40mm grenade rounds"
#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-40mm.txt"

new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?

public Plugin:myinfo = {
	name= "[INS] 40mm Adjustments",
	author  = "Jared Ballou (jballou)",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com/"
};

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_40mm_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_40mm_enabled", "1", "sets whether bot naming is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
//	HookEvent("missile_launched", Event_MissileLaunched);
	HookEvent("grenade_detonate", Event_GrenadeDetonate, EventHookMode_Pre);
	HookEvent("missile_detonate", Event_MissileDetonate, EventHookMode_Pre);
}
public Event_GrenadeDetonate( Handle:event, const String:name[], bool:dontBroadcast )
{
	PrintToServer("[40MM] Called Event_GrenadeDetonate");
	//"userid" "short"
	//"effectedEnemies" "short"
	//"y" "float"
	//"x" "float"
	//"entityid" "long"
	//"z" "float"
	//"id" "short"
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	new entity = GetEventInt(event, "entityid");
	if (Entity_HasEFlags(entity,EFL_IN_SKYBOX))
	{
		PrintToServer("[40MM] Grenade entity %d touched skybox, removing!",entity);
		RemoveEdict(entity);
	}
	return Plugin_Continue;
}
public Event_MissileDetonate( Handle:event, const String:name[], bool:dontBroadcast )
{
	PrintToServer("[40MM] Called Event_MissileDetonate");
	//"userid" "short"
	//"y" "float"
	//"x" "float"
	//"entityid" "long"
	//"z" "float"
	//"id" "short"
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	new entity = GetEventInt(event, "entityid");
	if (Entity_HasEFlags(entity,EFL_IN_SKYBOX))
	{
		PrintToServer("[40MM] Grenade entity %d touched skybox, removing!",entity);
		RemoveEdict(entity);
	}
	return Plugin_Continue;
}
/*
public Action:Event_MissileLaunched(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return;
	}
	PrintToServer("[40MM] Event_MissileLaunched!");
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new entity = GetEventInt(event, "entityid");
	new String:classname[32];
	GetEdictClassname(entity,classname,sizeof(classname));
	if(StrContains(classname, "grenade_m203") > -1 || StrContains(classname, "grenade_m203") > -1) {
		PrintToServer("[40MM] entity %d owner %N",entity,client);
		SDKHook(entity, SDKHook_Think, GrenadeThinkHook);
	}
}
public GrenadeThinkHook(entity)
{
	if (Entity_HasEFlags(entity,EFL_IN_SKYBOX))
	{
		PrintToServer("[40MM] Grenade entity %d touched skybox, removing!",entity);
		RemoveEdict(entity);
	}
}
*/
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}
/*
public OnEntityCreated(entity, const String:classname[])
{
	if (!GetConVarBool(cvarEnabled))
	{
		return;
	}
	if ((StrContains(classname,"grenade_m203") > -1) || (StrContains(classname,"grenade_gp25") > -1))
	{
		new String:szClassname[64];
		GetEntityClassname(entity,szClassname,sizeof(szClassname));
		SDKHook(entity, SDKHook_StartTouch, OnStartTouch);
		PrintToServer("[40MM] Added SDK hook to entity %d classname %s szClassname %s",entity,classname,szClassname);
	}
}
public Action:OnStartTouch(entity, other)
{
	PrintToServer("[40MM] Called OnStartTouch with entity %d and other %d",entity,other);
	if(other > 0 && other <= MaxClients)
	{
		SDKHook(entity, SDKHook_Touch, OnTouch);
	}
	return Plugin_Handled;
}
public Action:OnTouch(entity, other)
{
	PrintToServer("[40MM] Called OnTouch with entity %d and other %d",entity,other);
	if(other > 0 && other <= MaxClients)
	{
		new m_hOwnerEntity = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		new m_hOwner = GetEntPropEnt(entity, Prop_Send, "m_hOwner");
		PrintToServer("[40MM] m_hOwnerEntity %d hit %d m_hOwner %d",m_hOwnerEntity,entity,m_hOwner);
		new Float:damage = 60.0;
		SDKHooks_TakeDamage(other, m_hOwnerEntity, m_hOwnerEntity, damage);
//		AcceptEntityInput(entity, "Kill");
	}
	SDKUnhook(entity, SDKHook_Touch, OnTouch);
	return Plugin_Handled;
}
*/
