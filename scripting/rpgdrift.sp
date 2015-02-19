//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#include <updater>
#include <smlib/entities>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "0.0.2"
#define PLUGIN_DESCRIPTION "Adjusts behavior of RPG rounds"
#define UPDATE_URL "http://ins.jballou.com/sourcemod/update-rpgdrift.txt"

new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
new Handle:cvarAmount = INVALID_HANDLE;
new Handle:cvarChance = INVALID_HANDLE;
new Handle:cvarAlwaysBots = INVALID_HANDLE;

public Plugin:myinfo = {
	name= "[INS] RPG Adjustments",
	author  = "Jared Ballou (jballou)",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com/"
};

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_rpgdrift_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_rpgdrift_enabled", "1", "Sets whether RPG drifting is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarAmount = CreateConVar("sm_rpgdrift_amount", "2.0", "Sets RPG drift max change per tick", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarChance = CreateConVar("sm_rpgdrift_chance", "0.25", "Chance as a fraction of 1 that a player-fired rocket will be affected", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarAlwaysBots = CreateConVar("sm_rpgdrift_always_bots", "1", "Always affect bot-fired rockets", FCVAR_NOTIFY | FCVAR_PLUGIN);
	HookEvent("missile_launched", Event_MissileLaunched);
	
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
public Action:Event_MissileLaunched(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return;
	}
	PrintToServer("[RPGDRIFT] Event_MissileLaunched!");
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new entity = GetEventInt(event, "entityid");
	new String:classname[32];
	GetEdictClassname(entity,classname,sizeof(classname));
	if(StrEqual(classname, "rocket_rpg7"))
	{
		new Float:fRandom = GetRandomFloat(0.0,1.0);
		if (GetConVarBool(cvarAlwaysBots) && IsFakeClient(client))
		{
			fRandom = 0.0;
		}
		if (fRandom > GetConVarFloat(cvarChance))
		{
			return;
		}
		PrintToServer("[RPGDRIFT] Rocket entity %d owner %N fRandom %f applying RocketThinkHook",entity,client,fRandom);
		SDKHook(entity, SDKHook_Think, RocketThinkHook);
	}
}
public RocketThinkHook(entity)
{
	if (Entity_HasEFlags(entity,EFL_IN_SKYBOX))
	{
		PrintToServer("[RPGDRIFT] Rocket entity %d touched skybox, removing!",entity);
		RemoveEdict(entity);
	}
	decl Float:m_angRotation[3];
	new Float:fAmountDelta = GetConVarFloat(cvarAmount);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", m_angRotation);
//	PrintToServer("[RPGDRIFT] Rocket entity %d m_angRotation %f %f %f",entity,m_angRotation[0],m_angRotation[1],m_angRotation[2]);
	m_angRotation[0]+= GetRandomFloat((0.0-fAmountDelta), fAmountDelta);
	m_angRotation[1]+= GetRandomFloat((0.0-fAmountDelta), fAmountDelta);
	m_angRotation[2]+= GetRandomFloat((0.0-fAmountDelta), fAmountDelta);
//	PrintToServer("[RPGDRIFT] Rocket entity %d m_angRotation %f %f %f",entity,m_angRotation[0],m_angRotation[1],m_angRotation[2]);

	TeleportEntity(entity, NULL_VECTOR, m_angRotation, NULL_VECTOR);
/*
m_vecAngVelocity
m_angAbsRotation (Save)(12 Bytes)
m_angRotation (Save)(12 Bytes)
*/
}
