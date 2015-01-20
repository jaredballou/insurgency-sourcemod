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

#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_DESCRIPTION "Bot spawns"
#define UPDATE_URL    "http://jballou.com/insurgency/sourcemod/update-botspawns.txt"

new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
new Handle:g_hHidingSpots = INVALID_HANDLE;
new g_iHidingSpotCount;
new g_iNumControlPoints, g_nActivePushPointIndex, g_nTeamOneActiveBattleAttackPointIndex, g_nTeamOneActiveBattleDefendPointIndex, g_nTeamTwoActiveBattleAttackPointIndex, g_nTeamTwoActiveBattleDefendPointIndex, g_iCappingTeam, g_iOwningTeam, g_nInsurgentCount, g_nSecurityCount, g_vCPPositions, g_bSecurityLocked, g_bInsurgentsLocked, g_iObjectType, g_nReinforcementWavesRemaining, g_nRequiredPointIndex;


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
	g_nActivePushPointIndex = FindSendPropOffs("CINSObjectiveResource", "m_nActivePushPointIndex");
	g_nTeamOneActiveBattleAttackPointIndex = FindSendPropOffs("CINSObjectiveResource", "m_nTeamOneActiveBattleAttackPointIndex");
	g_nTeamOneActiveBattleDefendPointIndex = FindSendPropOffs("CINSObjectiveResource", "m_nTeamOneActiveBattleDefendPointIndex");
	g_nTeamTwoActiveBattleAttackPointIndex = FindSendPropOffs("CINSObjectiveResource", "m_nTeamTwoActiveBattleAttackPointIndex");
	g_nTeamTwoActiveBattleDefendPointIndex = FindSendPropOffs("CINSObjectiveResource", "m_nTeamTwoActiveBattleDefendPointIndex");
	g_iCappingTeam = FindSendPropOffs("CINSObjectiveResource", "m_iCappingTeam");
	g_iOwningTeam = FindSendPropOffs("CINSObjectiveResource", "m_iOwningTeam");
	g_nInsurgentCount = FindSendPropOffs("CINSObjectiveResource", "m_nInsurgentCount");
	g_nSecurityCount = FindSendPropOffs("CINSObjectiveResource", "m_nSecurityCount");
	g_vCPPositions = FindSendPropOffs("CINSObjectiveResource", "m_vCPPositions[0]");
	g_bSecurityLocked = FindSendPropOffs("CINSObjectiveResource", "m_bSecurityLocked");
	g_bInsurgentsLocked = FindSendPropOffs("CINSObjectiveResource", "m_bInsurgentsLocked");
	g_iObjectType = FindSendPropOffs("CINSObjectiveResource", "m_iObjectType");
	g_nReinforcementWavesRemaining = FindSendPropOffs("CINSObjectiveResource", "m_nReinforcementWavesRemaining");
	g_nRequiredPointIndex = FindSendPropOffs("CINSObjectiveResource", "m_nRequiredPointIndex");


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
	new ent = -1;
	new m_iNumControlPoints, m_nActivePushPointIndex, m_nTeamOneActiveBattleAttackPointIndex, m_nTeamOneActiveBattleDefendPointIndex, m_nTeamTwoActiveBattleAttackPointIndex, m_nTeamTwoActiveBattleDefendPointIndex, m_iCappingTeam[16], m_iOwningTeam[16], m_nInsurgentCount[16], m_nSecurityCount[16], m_vCPPositions[16][3], m_bSecurityLocked[16], m_bInsurgentsLocked[16], m_iObjectType[16], m_nReinforcementWavesRemaining[2], m_nRequiredPointIndex[16];
	ent = FindEntityByClassname(ent,"logic_checkpoint");
	if (ent)
	{
	}
	ent = FindEntityByClassname(ent,"ins_objective_resource");
	if (ent)
	{
		m_iNumControlPoints = GetEntData(ent, g_iNumControlPoints);
		m_nActivePushPointIndex = GetEntData(ent, g_nActivePushPointIndex);
		m_nTeamOneActiveBattleAttackPointIndex = GetEntData(ent, g_nTeamOneActiveBattleAttackPointIndex);
		m_nTeamOneActiveBattleDefendPointIndex = GetEntData(ent, g_nTeamOneActiveBattleDefendPointIndex);
		m_nTeamTwoActiveBattleAttackPointIndex = GetEntData(ent, g_nTeamTwoActiveBattleAttackPointIndex);
		m_nTeamTwoActiveBattleDefendPointIndex = GetEntData(ent, g_nTeamTwoActiveBattleDefendPointIndex);
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
/*
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
}

public Action:Timer_Spawn(Handle:timer, any:client)
{
	
	//TeleportEntity(client, pSpawn[client], NULL_VECTOR, NULL_VECTOR);
}
