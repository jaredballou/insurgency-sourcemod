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
#include <smlib/entities>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_DESCRIPTION "Adjusts behavior of RPG rounds"
#define PLUGIN_NAME "[INS] RPG Adjustments"
#define PLUGIN_URL "http://jballou.com/insurgency"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_WORKING 1

public Plugin:myinfo = {
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url		= PLUGIN_URL
};


new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
new Handle:cvarAmount = INVALID_HANDLE;
new Handle:cvarChance = INVALID_HANDLE;
new Handle:cvarAlwaysBots = INVALID_HANDLE;

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_rpgdrift_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_rpgdrift_enabled", "1", "Sets whether RPG drifting is enabled", FCVAR_NOTIFY);
	cvarAmount = CreateConVar("sm_rpgdrift_amount", "2.0", "Sets RPG drift max change per tick", FCVAR_NOTIFY);
	cvarChance = CreateConVar("sm_rpgdrift_chance", "0.25", "Chance as a fraction of 1 that a player-fired rocket will be affected", FCVAR_NOTIFY);
	cvarAlwaysBots = CreateConVar("sm_rpgdrift_always_bots", "1", "Always affect bot-fired rockets", FCVAR_NOTIFY);
	HookEvent("missile_launched", Event_MissileLaunched);
	HookUpdater();
}

public OnLibraryAdded(const String:name[]) {
	HookUpdater();
}

public Action:Event_MissileLaunched(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return;
	}
	//PrintToServer("[RPGDRIFT] Event_MissileLaunched!");
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
