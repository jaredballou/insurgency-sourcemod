//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>
#include <navmesh>
#undef REQUIRE_PLUGIN
#include <updater>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "0.0.2"
#define PLUGIN_DESCRIPTION "Bot spawns"
#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-botspawns.txt"

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
public OnMapStart()
{
	new String:sGameMode[32],String:sLogicEnt[64];
	GetConVarString(FindConVar("mp_gamemode"), sGameMode, sizeof(sGameMode));
	Format (sLogicEnt,sizeof(sLogicEnt),"logic_%s",sGameMode);
	PrintToServer("[BOTSPAWNS] gamemode %s logicent %s",sGameMode,sLogicEnt);
	if (!StrEqual(sGameMode,"checkpoint")) return;
	if (!NavMesh_Exists()) return;
	if (g_hHidingSpots == INVALID_HANDLE) g_hHidingSpots = NavMesh_GetHidingSpots();
	g_iHidingSpotCount = GetArraySize(g_hHidingSpots);
	return;
}
/*
	new m_iNumControlPoints, m_nActivePushPointIndex, m_nTeamOneActiveBattleAttackPointIndex, m_nTeamOneActiveBattleDefendPointIndex, m_nTeamTwoActiveBattleAttackPointIndex, m_nTeamTwoActiveBattleDefendPointIndex, m_iCappingTeam[16], m_iOwningTeam[16], m_nInsurgentCount[16], m_nSecurityCount[16], m_vCPPositions[16][3], m_bSecurityLocked[16], m_bInsurgentsLocked[16], m_iObjectType[16], m_nReinforcementWavesRemaining[2], m_nRequiredPointIndex[16];
	new ent = FindEntityByClassname(0,sLogicEnt);
	if (ent)
	{
		m_iNumControlPoints = GetEntData(ent, g_iNumControlPoints);
		m_nActivePushPointIndex = GetEntData(ent, g_nActivePushPointIndex);
		m_nTeamOneActiveBattleAttackPointIndex = GetEntData(ent, g_nTeamOneActiveBattleAttackPointIndex);
		m_nTeamOneActiveBattleDefendPointIndex = GetEntData(ent, g_nTeamOneActiveBattleDefendPointIndex);
		m_nTeamTwoActiveBattleAttackPointIndex = GetEntData(ent, g_nTeamTwoActiveBattleAttackPointIndex);
		m_nTeamTwoActiveBattleDefendPointIndex = GetEntData(ent, g_nTeamTwoActiveBattleDefendPointIndex);
		PrintToServer("[BOTSPAWNS] m_iNumControlPoints %d m_nActivePushPointIndex %d m_nTeamOneActiveBattleAttackPointIndex %d m_nTeamOneActiveBattleDefendPointIndex %d m_nTeamTwoActiveBattleAttackPointIndex %d m_nTeamTwoActiveBattleDefendPointIndex %d",m_iNumControlPoints,m_nActivePushPointIndex,m_nTeamOneActiveBattleAttackPointIndex,m_nTeamOneActiveBattleDefendPointIndex,m_nTeamTwoActiveBattleAttackPointIndex,m_nTeamTwoActiveBattleDefendPointIndex);
		for (new i=0;i<16;i++)
		{
			m_iCappingTeam[i] = GetEntData(ent, g_iCappingTeam+(i*4));
			m_iOwningTeam[i] = GetEntData(ent, g_iOwningTeam+(i*4));
			m_nInsurgentCount[i] = GetEntData(ent, g_nInsurgentCount+(i*4));
			m_nSecurityCount[i] = GetEntData(ent, g_nSecurityCount+(i*4));
			GetEntDataVector(ent, g_vCPPositions+(i*4), m_vCPPositions[i]);
			m_bSecurityLocked[i] = GetEntData(ent, g_bSecurityLocked+i);
			m_bInsurgentsLocked[i] = GetEntData(ent, g_bInsurgentsLocked+i);
			m_iObjectType[i] = GetEntData(ent, g_iObjectType+(i*4));
			if (i < 2)
			{
				m_nReinforcementWavesRemaining[i] = GetEntData(ent, g_nReinforcementWavesRemaining+(i*4));
			}
			m_nRequiredPointIndex[i] = GetEntData(ent, g_nRequiredPointIndex+(i*4));
		}
	}
}
	GetEntPropString(i, Prop_Data, "m_iClassname", m_iClassname, sizeof(m_iClassname));
	GetEntPropString(i, Prop_Data, "m_iGlobalname", m_iGlobalname, sizeof(m_iGlobalname));
	GetEntPropString(i, Prop_Data, "m_iName", m_iName, sizeof(m_iName));
	new String:name[32], String:m_iName[64],String:m_iszWeaponName[64],String:m_iClassname[64],String:m_iGlobalname[64],String:m_iszScriptId[64],Float:m_vecOrigin[3];
	for(new i=0;i<= GetMaxEntities() ;i++){
		if(!IsValidEntity(i))
			continue;
		if(GetEdictClassname(i, name, sizeof(name))){
			if(
(StrContains(name, "obj_weapon_cache") > -1)
 || (StrContains(name, "point_controlpoint") > -1)
 || (StrContains(name, "trigger_capture_zone") > -1)
) {
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", m_vecOrigin);
				PrintToServer("[BOTSPAWNS] Found %s at %f,%f,%f",name, m_vecOrigin[0], m_vecOrigin[1], m_vecOrigin[2]);
			}
			if(
(StrContains(name, "obj_weapon_cache") > -1)
 || (StrContains(name, "point_controlpoint") > -1)
 || (StrContains(name, "trigger_capture_zone") > -1)
 || (StrContains(name, "logic_") > -1)
 || (StrContains(name, "spawn") > -1)
 || (StrContains(name, "ins") > -1)
) {
				GetEntPropString(i, Prop_Data, "m_iClassname", m_iClassname, sizeof(m_iClassname));
				GetEntPropString(i, Prop_Data, "m_iGlobalname", m_iGlobalname, sizeof(m_iGlobalname));
				GetEntPropString(i, Prop_Data, "m_iName", m_iName, sizeof(m_iName));
				PrintToServer("[BOTSPAWNS] Found %s m_iClassname %s, m_iGlobalname %s, m_iName %s", name, m_iClassname, m_iGlobalname, m_iName);

			}
		}
	}
	return;
*/

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
	return Plugin_Continue;
}

public Action:Timer_Spawn(Handle:timer, any:client)
{
	if (g_hHidingSpots == INVALID_HANDLE) return;
	if (g_iHidingSpotCount)
	{
/*
		for (new iIndex = 0, iSize = g_iHidingSpotCount; iIndex < iSize; iIndex++)
		{
			new Float:flHidingSpot[3];//, iHidingSpotFlags;
			flHidingSpot[0] = GetArrayCell(g_hHidingSpots, iIndex, NavMeshHidingSpot_X);
			flHidingSpot[1] = GetArrayCell(g_hHidingSpots, iIndex, NavMeshHidingSpot_Y);
			flHidingSpot[2] = GetArrayCell(g_hHidingSpots, iIndex, NavMeshHidingSpot_Z);
			iHidingSpotFlags = GetArrayCell(g_hHidingSpots, iIndex, NavMeshHidingSpot_Flags);
			PrintToServer("[BOTSPAWNS] Found hiding spot %d at %f,%f,%f flags %d",iIndex,flHidingSpot[0],flHidingSpotY,flHidingSpotZ,iHidingSpotFlags);
		}
*/
	}
//	TeleportEntity(client, flHidingSpot, NULL_VECTOR, NULL_VECTOR);
}
