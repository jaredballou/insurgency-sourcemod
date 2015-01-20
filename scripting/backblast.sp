//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <updater>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_DESCRIPTION "Adds backblast to rocket based weapons"
#define UPDATE_URL    "http://jballou.com/insurgency/sourcemod/update-backblast.txt"

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
public Action:Event_WeaponFired(Handle:event, const String:name[], bool:dontBroadcast)
{
        if (!GetConVarBool(cvarEnabled))
        {
                return Plugin_Continue;
        }
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        new String:shotWeapName[32];
        GetClientWeapon(client, shotWeapName, sizeof(shotWeapName));
	if (
		(StrContains(shotWeapName,"weapon_at4") > -1)
		|| (StrContains(shotWeapName,"weapon_rpg") > -1)
	) {
				DoBackblast(client);
	}
	
	return Plugin_Continue;
}
public DoBackblast(client)
{
	new Float:senderOrigin[3];
	GetClientEyePosition(client, senderOrigin);

	new Float:targetOrigin[3];
	new Float:distance;
	new Float:dist;
	new Float:vecPoints[3];
	new Float:vecAngles[3];
	new Float:senderAngles[3];
	new String:name[32];

	GetClientAbsAngles(client, senderAngles);
	for(new target=0;target<= GetMaxEntities() ;target++)
	{
		if(!IsValidEntity(target))
		{
			continue;
		}
		if(GetEdictClassname(target, name, sizeof(name)))
		{
			if (StrContains(name,"player") > -1)
			{
				if (!IsFakeClient(target))
				{

				GetClientAbsOrigin(target, targetOrigin);
				distance = GetVectorDistance(targetOrigin, senderOrigin);
				dist = distance * 0.01905;
				MakeVectorFromPoints(senderOrigin, targetOrigin, vecPoints);
				GetVectorAngles(vecPoints, vecAngles);
				new Float:diff = senderAngles[1] - vecAngles[1];
				if (diff < -180)
				{
					diff = 360 + diff;
				}
				if (diff > 180)
				{
					diff = 360 - diff;
				}
				PrintToServer("[BACKBLAST] Player %N backblast found %N distance %f dist %f direction %f",client,target,distance,dist,diff);
				if (diff >= 112.5 || diff < -112.5)
				{
					PrintToServer("[BACKBLAST] whoa this should be good");
				}
				}
			}
		}
	}
}
