//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>
#include <navmesh>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_DESCRIPTION "Bot spawns"
new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
new Handle:g_hHidingSpots = INVALID_HANDLE;
new g_iHidingSpotCount;


public Plugin:myinfo = {
	name= "[INS] Bot spawns",
	author  = "Jared Ballou (jballou)",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://jballou.com/"
};

public OnPluginStart()
{
	PrintToServer("[BOTSPAWNS] Starting up");
	cvarVersion = CreateConVar("sm_botspawns_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_botspawns_enabled", "1", "sets whether objective removal is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);
	OnMapStart();
	HookEvent("player_spawn", Event_Spawn);
}
public OnMapStart()
{
	new String:name[32];
	for(new i=0;i<= GetMaxEntities() ;i++){
		if(!IsValidEntity(i))
			continue;
		if(GetEdictClassname(i, name, sizeof(name))){
			if(
(StrContains(name, "obj_weapon_cache") > -1)
 || (StrContains(name, "point_controlpoint") > -1)
 || (StrContains(name, "trigger_capture_zone") > -1)
) {
//				PrintToServer("[TEST] Found %s",name);
				new String:m_iName[64],String:m_iszWeaponName[64],String:m_iClassname[64],String:m_iGlobalname[64],String:m_iszScriptId[64],Float:m_vecOrigin[3];
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", m_vecOrigin);
				GetEntPropString(i, Prop_Data, "m_iClassname", m_iClassname, sizeof(m_iClassname));
				GetEntPropString(i, Prop_Data, "m_iGlobalname", m_iGlobalname, sizeof(m_iGlobalname));
				GetEntPropString(i, Prop_Data, "m_iName", m_iName, sizeof(m_iName));
				PrintToServer("[TEST] Found %s at (%f,%f,%f) m_iClassname %s, m_iGlobalname %s, m_iName %s", name, m_vecOrigin[0], m_vecOrigin[1], m_vecOrigin[2], m_iClassname, m_iGlobalname, m_iName);

			}
		}
	}
	return;
	if (!NavMesh_Exists()) return;
	if (g_hHidingSpots == INVALID_HANDLE) g_hHidingSpots = NavMesh_GetHidingSpots();
	if (g_hHidingSpots == INVALID_HANDLE) return;
	g_iHidingSpotCount = GetArraySize(g_hHidingSpots);
	if (g_iHidingSpotCount)
	{
		for (new iIndex = 0, iSize = g_iHidingSpotCount; iIndex < iSize; iIndex++)
		{
			new Float:flHidingSpotX, Float:flHidingSpotY, Float:flHidingSpotZ,iHidingSpotFlags;
			flHidingSpotX = GetArrayCell(g_hHidingSpots, iIndex, NavMeshHidingSpot_X);
			flHidingSpotY = GetArrayCell(g_hHidingSpots, iIndex, NavMeshHidingSpot_Y);
			flHidingSpotZ = GetArrayCell(g_hHidingSpots, iIndex, NavMeshHidingSpot_Z);
			iHidingSpotFlags = GetArrayCell(g_hHidingSpots, iIndex, NavMeshHidingSpot_Flags);
			PrintToServer("[BOTSPAWNS] Found hiding spot %d at %f,%f,%f flags %d",iIndex,flHidingSpotX,flHidingSpotY,flHidingSpotZ,iHidingSpotFlags);
		}
	}
	return;
}

public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return true;
	}
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsFakeClient(client))
	{
		CreateTimer(0.1, Timer_Spawn, client);
	}
}

public Action:Timer_Spawn(Handle:timer, any:client)
{
	
	//TeleportEntity(client, pSpawn[client], NULL_VECTOR, NULL_VECTOR);
}
