//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_DESCRIPTION "Adds backblast to rocket based weapons"
new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
new Handle:cvarKillRange = INVALID_HANDLE;
new Handle:cvarMaxRange = INVALID_HANDLE;
new Handle:cvarConeAngle = INVALID_HANDLE;
new Handle:cvarWallDamage = INVALID_HANDLE;
new Handle:cvarWallDistance = INVALID_HANDLE;
//new Handle: = INVALID_HANDLE;

public Plugin:myinfo = {
	name= "[INS] Backblast",
	author  = "Jared Ballou (jballou)",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com/"
};

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_backblast_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_backblast_enabled", "1", "sets whether bot naming is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarKillRange = CreateConVar("sm_backblast_killrange", "15", "Distance in meters from firing to kill players in backblast", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarMaxRange = CreateConVar("sm_backblast_maxrange", "25", "Max range for backblast to affect players", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarConeAngle = CreateConVar("sm_backblast_cone_angle", "90", "Angle behind firing to include in backblast effect", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarWallDamage = CreateConVar("sm_backblast_wall_damage", "80", "Damage to player when firing too close to a wall", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarWallDistance = CreateConVar("sm_backblast_wall_distance", "5", "Distance in meters to wall where player will be hurt", FCVAR_NOTIFY | FCVAR_PLUGIN);

        HookEvent("weapon_fire", Event_WeaponFired);
}
public Action:Event_WeaponFired(Handle:event, const String:name[], bool:dontBroadcast)
{
        if (!GetConVarBool(cvarEnabled))
        {
                return Plugin_Continue;
        }
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        new String:shotWeapName[32];
        GetClientWeapon(client, shotWeapName, sizeof(shotWeapName));
	
	return Plugin_Continue;
}
