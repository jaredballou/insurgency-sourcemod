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

#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_DESCRIPTION "Adjusts behavior of RPG rounds"
#define UPDATE_URL "http://ins.jballou.com/sourcemod/update-rpgdrift.txt"

new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?

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
	cvarEnabled = CreateConVar("sm_rpgdrift_enabled", "1", "sets whether RPG drifting is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);
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
public OnEntityCreated(entity, const String:classname[])
{
	if (!GetConVarBool(cvarEnabled))
	{
		return;
	}
	if(StrEqual(classname, "rocket_rpg7"))
	{
		SDKHook(entity, SDKHook_Think, RocketThinkHook);
	}
}
public RocketThinkHook(entity)
{
	decl Float:m_angRotation[3];
	GetEntPropVector(entity, Prop_Send, "m_angRotation", m_angRotation);
//	PrintToServer("[RPGDRIFT] Rocket entity %d m_angRotation %f %f %f",entity,m_angRotation[0],m_angRotation[1],m_angRotation[2]);
	m_angRotation[0]+= GetRandomFloat(-1.0, 1.0);
	m_angRotation[1]+= GetRandomFloat(-1.0, 1.0);
	m_angRotation[2]+= GetRandomFloat(-1.0, 1.0);
//	PrintToServer("[RPGDRIFT] Rocket entity %d m_angRotation %f %f %f",entity,m_angRotation[0],m_angRotation[1],m_angRotation[2]);

	TeleportEntity(entity, NULL_VECTOR, m_angRotation, NULL_VECTOR);
/*
m_vecAngVelocity
m_angAbsRotation (Save)(12 Bytes)
m_angRotation (Save)(12 Bytes)
*/
}
