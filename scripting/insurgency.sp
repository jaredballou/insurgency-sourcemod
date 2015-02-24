#include <sourcemod>
#include <regex>
#include <sdktools>
#include <insurgency>
#undef REQUIRE_PLUGIN
#include <updater>

#pragma unused cvarVersion

#define MAX_DEFINABLE_WEAPONS 100
#define MAX_WEAPON_LEN 32
#define MAX_CONTROLPOINTS 32
#define PREFIX_LEN 7
#define MAX_SQUADS 8
#define SQUAD_SIZE 8

#define INS
new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
new NumWeaponsDefined = 0;
new Handle:g_weap_array = INVALID_HANDLE;
new Handle:g_role_array = INVALID_HANDLE;
new g_iNumControlPoints, g_nActivePushPointIndex, g_nTeamOneActiveBattleAttackPointIndex, g_nTeamOneActiveBattleDefendPointIndex, g_nTeamTwoActiveBattleAttackPointIndex, g_nTeamTwoActiveBattleDefendPointIndex, g_iCappingTeam, g_iOwningTeam, g_nInsurgentCount, g_nSecurityCount, g_vCPPositions, g_bSecurityLocked, g_bInsurgentsLocked, g_iObjectType, g_nReinforcementWavesRemaining, g_nRequiredPointIndex, g_bCounterAttack;
new m_iNumControlPoints, m_nActivePushPointIndex, m_nTeamOneActiveBattleAttackPointIndex, m_nTeamOneActiveBattleDefendPointIndex, m_nTeamTwoActiveBattleAttackPointIndex, m_nTeamTwoActiveBattleDefendPointIndex, m_iCappingTeam[16], m_iOwningTeam[16], m_nInsurgentCount[16], m_nSecurityCount[16], Float:m_vCPPositions[16][3], m_bSecurityLocked[16], m_bInsurgentsLocked[16], m_iObjectType[16], m_nReinforcementWavesRemaining[2], m_nRequiredPointIndex[16], bool:m_bCounterAttack;
/*
enum {
	m_iNumControlPoints = 0,
	m_nActivePushPointIndex,
	m_nTeamOneActiveBattleAttackPointIndex,
	m_nTeamOneActiveBattleDefendPointIndex,
	m_nTeamTwoActiveBattleAttackPointIndex,
	m_nTeamTwoActiveBattleDefendPointIndex,
	m_iCappingTeam,
	m_iOwningTeam,
	m_nInsurgentCount,
	m_nSecurityCount,
	m_vCPPositions,
	m_bSecurityLocked,
	m_bInsurgentsLocked,
	m_iObjectType,
	m_nReinforcementWavesRemaining,
	m_nRequiredPointIndex,
	m_bCounterAttack,
}
*/
//============================================================================================================
#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_DESCRIPTION "Provides functions to support Insurgency"
#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-insurgency.txt"

public Plugin:myinfo =
{
	name = "[INS] Insurgency Support Library",
	author = "Jared Ballou",
	version = PLUGIN_VERSION,
	description = PLUGIN_DESCRIPTION,
	url = "http://jballou.com"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("insurgency");
	
//	MarkNativeAsOptional("GetUserMessageType");
	CreateNative("Ins_GetWeaponIndex", Native_GetWeaponIndex);
//	CreateNative("Ins_GetTemplate", Native_);
	return APLRes_Success;
}

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_insurgency_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_inslogger_enabled", "1", "sets whether log fixing is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);
	PrintToServer("[INSURGENCY] Starting");
/*
	AddFolderToDownloadTable("materials/overviews");
	AddFolderToDownloadTable("materials/vgui/backgrounds/maps");
	AddFolderToDownloadTable("materials/vgui/endroundlobby/maps");
*/
	HookEvent("player_pick_squad", Event_PlayerPickSquad);
//	LoadTranslations("insurgency.phrases.txt");
	g_iNumControlPoints = FindSendPropOffs("CINSObjectiveResource", "m_iNumControlPoints");
	g_nActivePushPointIndex = FindSendPropOffs("CINSObjectiveResource", "m_nActivePushPointIndex");
	g_nTeamOneActiveBattleAttackPointIndex = FindSendPropOffs("CINSObjectiveResource", "m_nTeamOneActiveBattleAttackPointIndex");
	g_nTeamOneActiveBattleDefendPointIndex = FindSendPropOffs("CINSObjectiveResource", "m_nTeamOneActiveBattleDefendPointIndex");
	g_nTeamTwoActiveBattleAttackPointIndex = FindSendPropOffs("CINSObjectiveResource", "m_nTeamTwoActiveBattleAttackPointIndex");
	g_nTeamTwoActiveBattleDefendPointIndex = FindSendPropOffs("CINSObjectiveResource", "m_nTeamTwoActiveBattleDefendPointIndex");
	g_iCappingTeam = FindSendPropOffs("CINSObjectiveResource", "m_iCappingTeam");
	g_iOwningTeam = FindSendPropOffs("CINSObjectiveResource", "m_iOwningTeam");
	g_nInsurgentCount = FindSendPropOffs("CINSObjectiveResource", "m_nInsurgentCount");
	g_nSecurityCount = FindSendPropOffs("CINSObjectiveResource", "m_nSecurityCount");
	g_vCPPositions = FindSendPropOffs("CINSObjectiveResource", "m_vCPPositions");
	g_bSecurityLocked = FindSendPropOffs("CINSObjectiveResource", "m_bSecurityLocked");
	g_bInsurgentsLocked = FindSendPropOffs("CINSObjectiveResource", "m_bInsurgentsLocked");
	g_iObjectType = FindSendPropOffs("CINSObjectiveResource", "m_iObjectType");
	g_nReinforcementWavesRemaining = FindSendPropOffs("CINSObjectiveResource", "m_nReinforcementWavesRemaining");
	g_nRequiredPointIndex = FindSendPropOffs("CINSObjectiveResource", "m_nRequiredPointIndex");
	g_bCounterAttack = FindSendPropOffs("CLogicCheckpoint", "m_bCounterAttack");
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("game_end", Event_GameEnd);
	HookEvent("game_newmap", Event_GameNewMap);
	HookEvent("game_start", Event_GameStart);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_begin", Event_RoundBegin);
	HookEvent("round_level_advanced", Event_RoundLevelAdvanced);
	HookEvent("object_destroyed", Event_ObjectDestroyed);
	HookEvent("controlpoint_captured", Event_ControlPointCaptured);
	HookEvent("controlpoint_neutralized", Event_ControlPointNeutralized);
	HookEvent("controlpoint_starttouch", Event_ControlPointStartTouch);
	HookEvent("controlpoint_endtouch", Event_ControlPointEndTouch);

        CreateNative("Insurgency_GetObjectiveResource", Native_GetObjectiveResource);
        CreateNative("Insurgency_InCounterAttack", Native_InCounterAttack);
}
public Native_GetObjectiveResource(Handle:plugin, numParams) {
        return 1;
}
public Native_InCounterAttack(Handle:plugin, numParams) {
        return m_bCounterAttack;
}
public Action:Event_ControlPointCaptured(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	//"priority" "short"
	//"cp" "byte"
	//"cappers" "string"
	//"cpname" "string"
	//"team" "byte"
	UpdateGameRules();
	return Plugin_Continue;
}
public Action:Event_ControlPointNeutralized(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	//"priority" "short"
	//"cp" "byte"
	//"cappers" "string"
	//"cpname" "string"
	//"team" "byte"
	UpdateGameRules();
	return Plugin_Continue;
}
public Action:Event_ControlPointStartTouch(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	//new area = GetEventInt(event, "area");
	//new object = GetEventInt(event, "object");
	//new player = GetEventInt(event, "player");
	//new team = GetEventInt(event, "team");
	//new owner = GetEventInt(event, "owner");
	//new type = GetEventInt(event, "type");
	//PrintToServer("[LOGGER] Event_ControlPointStartTouch: player %N area %d object %d player %d team %d owner %d type %d",player,area,object,player,team,owner,type);
	UpdateGameRules();
	return Plugin_Continue;
}
public Action:Event_ControlPointEndTouch(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	//"owner" "short"
	//"player" "short"
	//"team" "short"
	//"area" "byte"
	//new owner = GetEventInt(event, "owner");
	//new player = GetEventInt(event, "player");
	//new team = GetEventInt(event, "team");
	//new area = GetEventInt(event, "area");

	//PrintToServer("[LOGGER] Event_ControlPointEndTouch: player %N area %d player %d team %d owner %d",player,area,player,team,owner);
	UpdateGameRules();
	return Plugin_Continue;
}

public Action:Event_ObjectDestroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	//decl String:attacker_authid[64],String:assister_authid[64],String:classname[64];
	//"team" "byte"
	//"attacker" "byte"
	//"cp" "short"
	//"index" "short"
	//"type" "byte"
	//"weapon" "string"
	//"weaponid" "short"
	//"assister" "byte"
	//"attackerteam" "byte"
	UpdateGameRules();
	return Plugin_Continue;
}
public Action:Event_GameStart( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"priority" "short"
	UpdateGameRules();
	return Plugin_Continue;
}
public Action:Event_GameNewMap( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"mapname" "string"
	UpdateGameRules();
	return Plugin_Continue;
}
public Action:Event_RoundLevelAdvanced( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"level" "short"
	UpdateGameRules();
	return Plugin_Continue;
}
public Action:Event_GameEnd( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"team2_score" "short"
	//"winner" "byte"
	//"team1_score" "short"
	UpdateGameRules();
	return Plugin_Continue;
}
public Action:Event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"priority" "short"
	//"timelimit" "short"
	//"lives" "short"
	//"gametype" "short"
	UpdateGameRules();
	return Plugin_Continue;
}
public Action:Event_RoundBegin( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"priority" "short"
	//"timelimit" "short"
	//"lives" "short"
	//"gametype" "short"
	UpdateGameRules();
	return Plugin_Continue;
}
public Action:Event_RoundEnd( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"reason" "byte"
	//"winner" "byte"
	//"message" "string"
	//"message_string" "string"
	UpdateGameRules();
	return Plugin_Continue;
}

public Action:Event_PlayerSpawn( Handle:event, const String:name[], bool:dontBroadcast )
{
	//new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	UpdateGameRules();
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	//"deathflags" "short"
	//"attacker" "short"
	//"customkill" "short"
	//"lives" "short"
	//"attackerteam" "short"
	//"damagebits" "short"
	//"weapon" "string"
	//"weaponid" "short"
	//"userid" "short"
	//"priority" "short"
	//"team" "short"
	//"y" "float"
	//"x" "float"
	//"z" "float"
	//"assister" "short"
	UpdateGameRules();
	return Plugin_Continue;
}


public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

//jballou - LogRole support
public Action:Event_PlayerPickSquad(Handle:event, const String:name[], bool:dontBroadcast)
{
	//"squad_slot" "byte"
	//"squad" "byte"
	//"userid" "short"
	//"class_template" "string"
	//new client = GetClientOfUserId( GetEventInt( event, "userid" ) );

	new squad = GetEventInt( event, "squad" );
	new squad_slot = GetEventInt( event, "squad_slot" );
	decl String:class_template[64];
	GetEventString(event, "class_template",class_template,sizeof(class_template));
	UpdateRoleName(squad,squad_slot,class_template);
	UpdateGameRules();
	return Plugin_Continue;
}
public UpdateRoleName(squad,squad_slot,String:class_template[])
{
/*
	if (g_role_array == INVALID_HANDLE)
		g_role_array = CreateArray(MAX_SQUADS*SQUAD_SIZE);
	ReplaceString(class_template,sizeof(class_template),"template_","",false);
	ReplaceString(class_template,sizeof(class_template),"_training","",false);
	ReplaceString(class_template,sizeof(class_template),"_coop","",false);
	ReplaceString(class_template,sizeof(class_template),"_security","",false);
	ReplaceString(class_template,sizeof(class_template),"_insurgent","",false);
	ReplaceString(class_template,sizeof(class_template),"_survival","",false);
	new idx=(squad*SQUAD_SIZE)+squad_slot;
	SetArrayString(g_role_array,idx,class_template);
*/
}
public OnMapStart()
{
	PopulateWeaponNames();
	UpdateGameRules();
//	GetTeams();
}
public UpdateGameRules()
{
	//PrintToServer("[INSURGENCY] UpdateGameRules");
	new ent = -1;
	ent = FindEntityByClassname(ent,"ins_objective_resource");
	if (ent > 0)
	{
		//PrintToServer("[INSURGENCY] ins_objective_resource index %d",ent);

		m_iNumControlPoints = GetEntData(ent, g_iNumControlPoints);
		m_nActivePushPointIndex = GetEntData(ent, g_nActivePushPointIndex);
		m_nTeamOneActiveBattleAttackPointIndex = GetEntData(ent, g_nTeamOneActiveBattleAttackPointIndex);
		m_nTeamOneActiveBattleDefendPointIndex = GetEntData(ent, g_nTeamOneActiveBattleDefendPointIndex);
		m_nTeamTwoActiveBattleAttackPointIndex = GetEntData(ent, g_nTeamTwoActiveBattleAttackPointIndex);
		m_nTeamTwoActiveBattleDefendPointIndex = GetEntData(ent, g_nTeamTwoActiveBattleDefendPointIndex);
		//PrintToServer("[INSURGENCY] m_iNumControlPoints %d m_nActivePushPointIndex %d m_nTeamOneActiveBattleAttackPointIndex %d m_nTeamOneActiveBattleDefendPointIndex %d m_nTeamTwoActiveBattleAttackPointIndex %d m_nTeamTwoActiveBattleDefendPointIndex %d",m_iNumControlPoints,m_nActivePushPointIndex,m_nTeamOneActiveBattleAttackPointIndex,m_nTeamOneActiveBattleDefendPointIndex,m_nTeamTwoActiveBattleAttackPointIndex,m_nTeamTwoActiveBattleDefendPointIndex);
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
				//PrintToServer("[INSURGENCY] m_nReinforcementWavesRemaining[%d] %d",i,m_nReinforcementWavesRemaining[i]);
			}
			m_nRequiredPointIndex[i] = GetEntData(ent, g_nRequiredPointIndex+(i*4));
			//PrintToServer("[INSURGENCY] index %d m_iCappingTeam %d m_iOwningTeam %d m_nInsurgentCount %d m_nSecurityCount %d m_vCPPositions %f,%f,%f m_bSecurityLocked %d m_bInsurgentsLocked %d m_iObjectType %d m_nRequiredPointIndex %d",i,m_iCappingTeam[i],m_iOwningTeam[i],m_nInsurgentCount[i],m_nSecurityCount[i],m_vCPPositions[i][0],m_vCPPositions[i][1],m_vCPPositions[i][2],m_bSecurityLocked[i],m_bInsurgentsLocked[i],m_iObjectType[i],m_nRequiredPointIndex[i]);
		}

	}
	new String:sGameMode[32],String:sLogicEnt[64];
	GetConVarString(FindConVar("mp_gamemode"), sGameMode, sizeof(sGameMode));
	Format (sLogicEnt,sizeof(sLogicEnt),"logic_%s",sGameMode);
	if (!StrEqual(sGameMode,"checkpoint")) return;
	ent = FindEntityByClassname(ent,sLogicEnt);
	if (ent > 0)
	{
		if (m_bCounterAttack != GetEntData(ent, g_bCounterAttack))
		{
			m_bCounterAttack = GetEntData(ent, g_bCounterAttack);
			PrintToServer("[INSURGENCY] m_bCounterAttack %b",m_bCounterAttack);
		}
	}
}
public PopulateWeaponNames()
{
	PrintToServer("[INSURGENCY] starting PopulateWeaponNames");
/*
	if (g_weap_array == INVALID_HANDLE)
		g_weap_array = CreateArray(MAX_DEFINABLE_WEAPONS);
	new String:name[32];
	for(new i=0;i<= GetMaxEntities() ;i++)
	{
		if(!IsValidEntity(i))
		{
			continue;
		}
		if(GetEdictClassname(i, name, sizeof(name)))
		{
			if (StrContains(name,"weapon_") > -1)
			{
				GetWeaponIndex(name);
			}
		}
	}
	PrintToServer("[INSURGENCY] Weapons found: %d", NumWeaponsDefined);
*/
}
/*
public Native_GetClientRole(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	//m_iSquadSlot
}
*/
public Native_GetWeaponIndex(Handle:plugin, numParams)
{
	new len;
	GetNativeStringLength(1, len);
	if (len <= 0)
		return -1;
	new String:str[len + 1];
	GetNativeString(1, str, len + 1);
	return GetWeaponIndex(str);
}

public GetWeaponIndex(String:weapon_name[])
{
	decl String:strBuf[32];
	for(new i = 0; i < NumWeaponsDefined; i++)
	{
		GetArrayString(g_weap_array, i, strBuf, sizeof(strBuf));
		if(StrEqual(weapon_name, strBuf)) return i;
	}
	//jballou: Adding weapon to trie if it's not here
	PushArrayString(g_weap_array, weapon_name);
	NumWeaponsDefined++;
	PrintToServer("[INSURGENCY] Weapons %s not in trie, added as index %d", weapon_name,NumWeaponsDefined);
	return (NumWeaponsDefined-1);
}
