#include <sourcemod>
#include <regex>
#include <sdktools>
#include <insurgency>
#undef REQUIRE_PLUGIN
#include <updater>

#pragma unused cvarVersion

#define INS
new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
new Handle:cvarCheckpointCounterattackCapture = INVALID_HANDLE;
new Handle:cvarCheckpointCapturePlayerRatio = INVALID_HANDLE;
new Handle:g_weap_array = INVALID_HANDLE;
new Handle:hGameConf = INVALID_HANDLE;
new g_iObjResEntity, g_iLogicEntity, g_iPlayerManagerEntity;
new String:g_classes[Teams][MAX_SQUADS][SQUAD_SIZE][MAX_CLASS_LEN];
new g_round_stats[MAXPLAYERS+1][RoundStatFields];
new g_client_last_weapon[MAXPLAYERS+1] = {-1, ...};
new String:g_client_last_weaponstring[MAXPLAYERS+1][64];
new String:g_client_hurt_weaponstring[MAXPLAYERS+1][64];
new String:g_client_last_classstring[MAXPLAYERS+1][64];
new g_weapon_stats[MAXPLAYERS+1][MAX_DEFINABLE_WEAPONS][WeaponStatFields];

#define KILL_REGEX_PATTERN "^\"(.+(?:<[^>]*>))\" killed \"(.+(?:<[^>]*>))\" with \"([^\"]*)\" at (.*)"
#define SUICIDE_REGEX_PATTERN "^\"(.+(?:<[^>]*>))\" committed suicide with \"([^\"]*)\""
new Handle:kill_regex = INVALID_HANDLE;
new Handle:suicide_regex = INVALID_HANDLE;

//============================================================================================================
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_DESCRIPTION "Provides functions to support Insurgency and fixes logging"
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
	CreateNative("Ins_GetWeaponGetMaxClip1", Native_Weapon_GetMaxClip1);
        CreateNative("Ins_GetWeaponName", Native_Weapon_GetWeaponName);
        CreateNative("Ins_GetWeaponId", Native_Weapon_GetWeaponId);

        CreateNative("Ins_ObjectiveResource_GetProp", Native_ObjectiveResource_GetProp);
        CreateNative("Ins_ObjectiveResource_GetPropFloat", Native_ObjectiveResource_GetPropFloat);
        CreateNative("Ins_ObjectiveResource_GetPropEnt", Native_ObjectiveResource_GetPropEnt);
        CreateNative("Ins_ObjectiveResource_GetPropBool", Native_ObjectiveResource_GetPropBool);
        CreateNative("Ins_ObjectiveResource_GetPropVector", Native_ObjectiveResource_GetPropVector);
        CreateNative("Ins_ObjectiveResource_GetPropString", Native_ObjectiveResource_GetPropString);

        CreateNative("Ins_InCounterAttack", Native_InCounterAttack);

        CreateNative("Ins_GetPlayerScore", Native_GetPlayerScore);
        CreateNative("Ins_GetPlayerClass", Native_GetPlayerClass);
	return APLRes_Success;
}

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_insurgency_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_inslogger_enabled", "1", "sets whether log fixing is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarCheckpointCapturePlayerRatio = CreateConVar("sm_insurgency_checkpoint_capture_player_ratio", "0.5", "Fraction of living players required to capture in Checkpoint", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarCheckpointCounterattackCapture = CreateConVar("sm_insurgency_checkpoint_counterattack_capture", "0", "Enable counterattack by bots to capture points in Checkpoint", FCVAR_NOTIFY | FCVAR_PLUGIN);
	PrintToServer("[INSLIB] Starting");
/*
	AddFolderToDownloadTable("materials/overviews");
	AddFolderToDownloadTable("materials/vgui/backgrounds/maps");
	AddFolderToDownloadTable("materials/vgui/endroundlobby/maps");
*/
	kill_regex = CompileRegex(KILL_REGEX_PATTERN);
	suicide_regex = CompileRegex(SUICIDE_REGEX_PATTERN);
	
	//Begin HookEvents
	hook_wstats();
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("weapon_fire", Event_WeaponFired);
	
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_pick_squad", Event_PlayerPickSquad);
//jballou - new events
	HookEvent("player_suppressed", Event_PlayerSuppressed);
	HookEvent("player_avenged_teammate", Event_PlayerAvengedTeammate);
	HookEvent("grenade_thrown", Event_GrenadeThrown);
	HookEvent("grenade_detonate", Event_GrenadeDetonate);
	HookEvent("game_end", Event_GameEnd);
	HookEvent("game_newmap", Event_GameNewMap);
	HookEvent("game_start", Event_GameStart);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_begin", Event_RoundBegin);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_level_advanced", Event_RoundLevelAdvanced);

	HookEvent("missile_launched", Event_MissileLaunched);
	HookEvent("missile_detonate", Event_MissileDetonate);

	HookEvent("object_destroyed", Event_ObjectDestroyed);
	HookEvent("controlpoint_captured", Event_ControlPointCaptured);
	HookEvent("controlpoint_neutralized", Event_ControlPointNeutralized);
	HookEvent("controlpoint_starttouch", Event_ControlPointStartTouch);
	HookEvent("controlpoint_endtouch", Event_ControlPointEndTouch);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	hGameConf = LoadGameConfigFile("insurgency.games");

	//Begin Engine LogHooks
	AddGameLogHook(LogEvent);
	
	GetTeams(false);
//	LoadTranslations("insurgency.phrases.txt");

	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}
public OnPluginEnd()
{
	WstatsDumpAll();
	g_weap_array = INVALID_HANDLE;
}
public OnMapStart()
{
	GetObjResEnt();
	GetWeaponData();
	GetTeams(false);
}


public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}
OnPlayerDisconnect(client)
{
	if(client > 0 && IsClientInGame(client))
	{
		dump_player_stats(client);
		reset_player_stats(client);
	}
}



//=====================================================================================================
hook_wstats()
{
	HookEvent("player_first_spawn", Event_PlayerSpawn);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
}

public UpdateClassName(team,squad,squad_slot,String:raw_class_template[])
{
	decl String:class_template[MAX_CLASS_LEN];
	Format(class_template,MAX_CLASS_LEN,"%s",raw_class_template);
	ReplaceString(class_template,sizeof(class_template),"template_","",false);
	ReplaceString(class_template,sizeof(class_template),"_training","",false);
	ReplaceString(class_template,sizeof(class_template),"_coop","",false);
	ReplaceString(class_template,sizeof(class_template),"_security","",false);
	ReplaceString(class_template,sizeof(class_template),"_insurgent","",false);
	ReplaceString(class_template,sizeof(class_template),"_survival","",false);
	if(!StrEqual(g_classes[team][squad][squad_slot],class_template))
	{
		PrintToServer("[INSLIB] team: %d squad: %d squad_slot: %d class_template: %s",team,squad,squad_slot,class_template);
		Format(g_classes[team][squad][squad_slot],MAX_CLASS_LEN,"%s",class_template);
	}
}
public GetObjResEnt()
{
	if ((g_iObjResEntity < 1) || !IsValidEntity(g_iObjResEntity))
	{
		g_iObjResEntity = FindEntityByClassname(0,"ins_objective_resource");
	}
}
GetLogicEnt() {
	if ((g_iLogicEntity < 1) || !IsValidEntity(g_iLogicEntity))
	{
		new String:sGameMode[32],String:sLogicEnt[64];
		GetConVarString(FindConVar("mp_gamemode"), sGameMode, sizeof(sGameMode));
		Format (sLogicEnt,sizeof(sLogicEnt),"logic_%s",sGameMode);
		if (!StrEqual(sGameMode,"checkpoint")) return;
		g_iLogicEntity = FindEntityByClassname(-1,sLogicEnt);
	}
}
public GetWeaponData()
{
	if (g_weap_array == INVALID_HANDLE)
	{
		g_weap_array = CreateArray(MAX_DEFINABLE_WEAPONS);
		for (new i;i<MAX_DEFINABLE_WEAPONS;i++)
		{
			PushArrayString(g_weap_array, "");
		}
		PrintToServer("[INSLIB] starting LoadValues");
		new String:name[32];
		for(new i=0;i<= GetMaxEntities() ;i++){
			if(!IsValidEntity(i))
				continue;
			if(GetEdictClassname(i, name, sizeof(name))){
				if (StrContains(name,"weapon_") == 0) {
					GetWeaponId(i);
				}
			}
		}
	}
}
GetPlayerManagerEnt() {
	if ((g_iPlayerManagerEntity < 1) || !IsValidEntity(g_iPlayerManagerEntity))
	{
		g_iPlayerManagerEntity = FindEntityByClassname(-1,"ins_player_manager");
	}
}

reset_round_stats(client)
{
	if (IsValidClient(client))
	{
		PrintToServer("[INSLIB] Running reset_round_stats for %N",client);
	}
	for (new i = 1; i < 13; i++)
	{
		g_round_stats[client][i] = 0;
	}
	g_round_stats[client][STAT_SCORE] = Ins_GetPlayerScore(client);
}
DoRoundAwards()
{
	PrintToServer("[INSLIB] Running DoRoundAwards");
	new iHighPlayer[RoundStatFields],iLowPlayer[RoundStatFields],iHighScore[RoundStatFields],iLowScore[RoundStatFields];
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			new m_iPlayerScore = Ins_GetPlayerScore(i);
			g_round_stats[i][STAT_SCORE] = (m_iPlayerScore - g_round_stats[i][STAT_SCORE]);
			g_round_stats[i][STAT_ACCURACY] = RoundToFloor((Float:g_round_stats[i][STAT_HITS] / Float:g_round_stats[i][STAT_SHOTS]) * 100.0);
			for (new s;s<sizeof(iHighPlayer);s++)
			{
				if ((g_round_stats[i][s] > iHighScore[s]) || (iHighPlayer[s] < 1))
				{
					iHighPlayer[s] = i;
					iHighScore[s] = g_round_stats[i][s];
				}
				if ((g_round_stats[i][s] < iLowScore[s]) || (iLowPlayer[s] < 1))
				{
					iLowPlayer[s] = i;
					iLowScore[s] = g_round_stats[i][s];
				}
			}
			PrintToServer("[INSLIB] Client %N KILLS %d, DEATHS %d, SHOTS %d, HITS %d, GRENADES %d, CAPTURES %d, CACHES %d, DMG_GIVEN %d, DMG_TAKEN %d, TEAMKILLS %d SCORE %d (total %d) SUPPRESSIONS %d",i,g_round_stats[i][STAT_KILLS],g_round_stats[i][STAT_DEATHS],g_round_stats[i][STAT_SHOTS],g_round_stats[i][STAT_HITS],g_round_stats[i][STAT_GRENADES],g_round_stats[i][STAT_CAPTURES],g_round_stats[i][STAT_CACHES],g_round_stats[i][STAT_DMG_GIVEN],g_round_stats[i][STAT_DMG_TAKEN],g_round_stats[i][STAT_TEAMKILLS],g_round_stats[i][STAT_SCORE],m_iPlayerScore,g_round_stats[i][STAT_SUPPRESSIONS]);
		}
		reset_round_stats(i);
	}
	LogPlayerEvent(iHighPlayer[STAT_SCORE], "triggered", "round_mvp");
	LogPlayerEvent(iHighPlayer[STAT_KILLS], "triggered", "round_kills");
	LogPlayerEvent(iLowPlayer[STAT_DEATHS], "triggered", "round_deaths");
	LogPlayerEvent(iHighPlayer[STAT_SHOTS], "triggered", "round_shots");
	LogPlayerEvent(iHighPlayer[STAT_HITS], "triggered", "round_hits");
	LogPlayerEvent(iHighPlayer[STAT_ACCURACY], "triggered", "round_accuracy");
	LogPlayerEvent(iHighPlayer[STAT_GRENADES], "triggered", "round_grenades");
	LogPlayerEvent(iHighPlayer[STAT_CAPTURES], "triggered", "round_captures");
	LogPlayerEvent(iHighPlayer[STAT_CACHES], "triggered", "round_caches");
	LogPlayerEvent(iHighPlayer[STAT_DMG_GIVEN], "triggered", "round_dmg_given");
	LogPlayerEvent(iLowPlayer[STAT_DMG_TAKEN], "triggered", "round_dmg_taken");
	LogPlayerEvent(iHighPlayer[STAT_SUPPRESSIONS], "triggered", "round_suppressions");
}
stock bool:IsValidClient(client) {

  return (client > 0 && client <= MaxClients &&
    IsClientConnected(client) && IsClientInGame(client) &&
    !IsClientReplay(client) && !IsClientSourceTV(client));

}



GetWeaponId(i)
{
	new m_hWeaponDefinitionHandle = GetEntProp(i, Prop_Send, "m_hWeaponDefinitionHandle");
	new String:name[32];
	GetEdictClassname(i, name, sizeof(name));
	decl String:strBuf[32];
	GetArrayString(g_weap_array, m_hWeaponDefinitionHandle, strBuf, sizeof(strBuf));
	if(!StrEqual(name, strBuf))
	{
		SetArrayString(g_weap_array, m_hWeaponDefinitionHandle, name);
		PrintToServer("[INSLIB] Weapons %s not in trie, added as index %d", name,m_hWeaponDefinitionHandle);
	}
	return m_hWeaponDefinitionHandle;
}

dump_player_stats(client)
{
	if (IsClientInGame(client) && IsClientConnected(client))
	{
		decl String: player_authid[64];
		if (!GetClientAuthId(client, AuthId_Steam2, player_authid, sizeof(player_authid)))
		{
			strcopy(player_authid, sizeof(player_authid), "UNKNOWN");
		}
		new player_team_index = GetClientTeam(client);
		new player_userid = GetClientUserId(client);

		new is_logged;
		//for (new i = 0; (i < MAX_LOG_WEAPONS); i++)
		//DYNAMIC POPULATE
		//for (new i = 0; i < GetArraySize(g_weap_array); i++)
		for (new i = 0; i < MAX_DEFINABLE_WEAPONS; i++)
		{
			decl String:strBuf[32];
			Ins_GetWeaponName(i, strBuf, sizeof(strBuf));
			
			#if defined INS
			if (g_weapon_stats[client][i][LOG_HIT_HITS] > 0)
			{
				LogToGame("\"%N<%d><%s><%s>\" triggered \"weaponstats\" (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", 
				client, 
				player_userid, 
				player_authid, 
				g_team_list[player_team_index], 
				strBuf,	//g_weapon_list[i], 
				g_weapon_stats[client][i][LOG_HIT_SHOTS], 
				g_weapon_stats[client][i][LOG_HIT_HITS], 
				g_weapon_stats[client][i][LOG_HIT_KILLS], 
				g_weapon_stats[client][i][LOG_HIT_HEADSHOTS], 
				g_weapon_stats[client][i][LOG_HIT_TEAMKILLS], 
				g_weapon_stats[client][i][LOG_HIT_DAMAGE], 
				g_weapon_stats[client][i][LOG_HIT_DEATHS]); 
				
				LogToGame("\"%N<%d><%s><%s>\" triggered \"weaponstats2\" (weapon \"%s\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\")", 
				client, 
				player_userid, 
				player_authid, 
				g_team_list[player_team_index], 
				strBuf,	//g_weapon_list[i], 
				g_weapon_stats[client][i][LOG_HIT_HEAD], 
				g_weapon_stats[client][i][LOG_HIT_CHEST], 
				g_weapon_stats[client][i][LOG_HIT_STOMACH], 
				g_weapon_stats[client][i][LOG_HIT_LEFTARM], 
				g_weapon_stats[client][i][LOG_HIT_RIGHTARM], 
				g_weapon_stats[client][i][LOG_HIT_LEFTLEG], 
				g_weapon_stats[client][i][LOG_HIT_RIGHTLEG]);
			#else
			if (g_weapon_stats[client][i][LOG_HIT_SHOTS] > 0)
			{
				#if defined GES
				LogToGame("\"%N<%d><%s><%s>\" triggered \"weaponstats\" (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", 
				client, 
				player_userid, 
				player_authid, 
				g_team_list[player_team_index], 
				g_weapon_loglist[i], 
				g_weapon_stats[client][i][LOG_HIT_SHOTS], 
				g_weapon_stats[client][i][LOG_HIT_HITS], 
				g_weapon_stats[client][i][LOG_HIT_KILLS], 
				g_weapon_stats[client][i][LOG_HIT_HEADSHOTS], 
				g_weapon_stats[client][i][LOG_HIT_TEAMKILLS], 
				g_weapon_stats[client][i][LOG_HIT_DAMAGE], 
				g_weapon_stats[client][i][LOG_HIT_DEATHS]); 
				
				LogToGame("\"%N<%d><%s><%s>\" triggered \"weaponstats2\" (weapon \"%s\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\")", 
				client, 
				player_userid, 
				player_authid, 
				g_team_list[player_team_index], 
				g_weapon_loglist[i], 
				g_weapon_stats[client][i][LOG_HIT_HEAD], 
				g_weapon_stats[client][i][LOG_HIT_CHEST], 
				g_weapon_stats[client][i][LOG_HIT_STOMACH], 
				g_weapon_stats[client][i][LOG_HIT_LEFTARM], 
				g_weapon_stats[client][i][LOG_HIT_RIGHTARM], 
				g_weapon_stats[client][i][LOG_HIT_LEFTLEG], 
				g_weapon_stats[client][i][LOG_HIT_RIGHTLEG]); 
				#else
				LogToGame("\"%N<%d><%s><%s>\" triggered \"weaponstats\" (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\")", 
				client, 
				player_userid, 
				player_authid, 
				g_team_list[player_team_index], 
				strBuf, //g_weapon_list[i], 
				g_weapon_stats[client][i][LOG_HIT_SHOTS], 
				g_weapon_stats[client][i][LOG_HIT_HITS], 
				g_weapon_stats[client][i][LOG_HIT_KILLS], 
				g_weapon_stats[client][i][LOG_HIT_HEADSHOTS], 
				g_weapon_stats[client][i][LOG_HIT_TEAMKILLS], 
				g_weapon_stats[client][i][LOG_HIT_DAMAGE], 
				g_weapon_stats[client][i][LOG_HIT_DEATHS]);
				
				LogToGame("\"%N<%d><%s><%s>\" triggered \"weaponstats2\" (weapon \"%s\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\")", 
				client, 
				player_userid, 
				player_authid, 
				g_team_list[player_team_index], 
				strBuf, //g_weapon_list[i], 
				g_weapon_stats[client][i][LOG_HIT_HEAD],
				g_weapon_stats[client][i][LOG_HIT_CHEST], 
				g_weapon_stats[client][i][LOG_HIT_STOMACH], 
				g_weapon_stats[client][i][LOG_HIT_LEFTARM], 
				g_weapon_stats[client][i][LOG_HIT_RIGHTARM], 
				g_weapon_stats[client][i][LOG_HIT_LEFTLEG], 
				g_weapon_stats[client][i][LOG_HIT_RIGHTLEG]);
				#endif
			#endif
				is_logged++;
			}
		}
		if (is_logged > 0)
		{
			reset_player_stats(client);
		}
	}
}

reset_player_stats(client)
{
	//for (new i = 0; (i < MAX_LOG_WEAPONS); i++)
	//DYNAMIC POPULATE
	//for( new i = 0; i < GetArraySize(g_weap_array); i++)
	for( new i = 0; i < MAX_DEFINABLE_WEAPONS; i++)
	{
		g_weapon_stats[client][i][LOG_HIT_SHOTS]     = 0;
		g_weapon_stats[client][i][LOG_HIT_HITS]      = 0;
		g_weapon_stats[client][i][LOG_HIT_KILLS]     = 0;
		g_weapon_stats[client][i][LOG_HIT_HEADSHOTS] = 0;
		g_weapon_stats[client][i][LOG_HIT_TEAMKILLS] = 0;
		g_weapon_stats[client][i][LOG_HIT_DAMAGE]    = 0;
		g_weapon_stats[client][i][LOG_HIT_DEATHS]    = 0;
		g_weapon_stats[client][i][LOG_HIT_GENERIC]   = 0;
		g_weapon_stats[client][i][LOG_HIT_HEAD]      = 0;
		g_weapon_stats[client][i][LOG_HIT_CHEST]     = 0;
		g_weapon_stats[client][i][LOG_HIT_STOMACH]   = 0;
		g_weapon_stats[client][i][LOG_HIT_LEFTARM]   = 0;
		g_weapon_stats[client][i][LOG_HIT_RIGHTARM]  = 0;
		g_weapon_stats[client][i][LOG_HIT_LEFTLEG]   = 0;
		g_weapon_stats[client][i][LOG_HIT_RIGHTLEG]  = 0;
	}
}

WstatsDumpAll()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		dump_player_stats(i);
	}
}




















//=====================================================================================================
public Native_GetPlayerScore(Handle:plugin, numParams)
{
	GetPlayerManagerEnt();
	new client = GetNativeCell(1);
	new retval = -1;
	if ((IsValidClient(client)) && (g_iPlayerManagerEntity > 0))
	{
		retval = GetEntData(g_iPlayerManagerEntity, FindSendPropOffs("CINSPlayerResource", "m_iPlayerScore") + (4 * client));
		//PrintToServer("[INSLIB] Client %N m_iPlayerScore %d",client,retval);
	}
	return retval;
}
public Native_GetPlayerClass(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if (IsValidClient(client))
	{
		new maxlen = GetNativeCell(3);
		SetNativeString(2, g_client_last_classstring[client], maxlen+1);
	}
	return;
}
public Native_InCounterAttack(Handle:plugin, numParams)
{
	GetLogicEnt();
	new bool:retval;
	if (g_iLogicEntity > 0)
	{
		retval = bool:GetEntData(g_iLogicEntity, FindSendPropOffs("CLogicCheckpoint", "m_bCounterAttack"));
	}
	return _:retval;
}

public Native_Weapon_GetWeaponId(Handle:plugin, numParams)
{
	new len;
	GetNativeStringLength(1, len);
	if (len <= 0)
	{
	  return false;
	}
	new String:weapon_name[len+1];
	decl String:strBuf[32];
	GetNativeString(1, weapon_name, len+1);
	GetWeaponData();
	new iEntity = FindEntityByClassname(-1,weapon_name);
	if (iEntity)
	{
		return GetWeaponId(iEntity);
	}
	else
	{
		for(new i = 0; i < MAX_DEFINABLE_WEAPONS; i++)
		{
			GetArrayString(g_weap_array, i, strBuf, sizeof(strBuf));
			if(StrEqual(weapon_name, strBuf)) return i;
		}
	}
	return -1;
}
public Native_Weapon_GetWeaponName(Handle:plugin, numParams)
{
	new weaponid = GetNativeCell(1);
	decl String:strBuf[32];
	GetWeaponData();
	GetArrayString(g_weap_array, weaponid, strBuf, sizeof(strBuf));
	new maxlen = GetNativeCell(3);
	SetNativeString(2, strBuf, maxlen+1);
}

public Native_Weapon_GetMaxClip1(Handle:plugin, numParams)
{
	new weapon = GetNativeCell(1);
	StartPrepSDKCall(SDKCall_Entity);
	if(!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "GetMaxClip1")) 
	{
		SetFailState("PrepSDKCall_SetFromConf false, nothing found"); 
	}
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	new Handle:hCall = EndPrepSDKCall();
	new value = SDKCall(hCall, weapon);
	CloseHandle(hCall);
	return value;
}
public Native_ObjectiveResource_GetProp(Handle:plugin, numParams)
{
	new len;
	GetNativeStringLength(1, len);
	if (len <= 0)
	{
	  return false;
	}
	new String:prop[len+1],retval=-1;
	GetNativeString(1, prop, len+1);
	new size = GetNativeCell(2);
	new element = GetNativeCell(3);
	GetObjResEnt();
	if (g_iObjResEntity > 0)
	{
		retval = GetEntData(g_iObjResEntity, FindSendPropOffs("CINSObjectiveResource", prop) + (size * element));
	}
	return retval;
}
public Native_ObjectiveResource_GetPropFloat(Handle:plugin, numParams)
{
	new len;
	GetNativeStringLength(1, len);
	if (len <= 0)
	{
	  return false;
	}
	new String:prop[len+1],Float:retval=-1.0;
	GetNativeString(1, prop, len+1);
	new size = GetNativeCell(2);
	new element = GetNativeCell(3);
	GetObjResEnt();
	if (g_iObjResEntity > 0)
	{
		retval = Float:GetEntData(g_iObjResEntity, FindSendPropOffs("CINSObjectiveResource", prop) + (size * element));
	}
	return _:retval;
}
public Native_ObjectiveResource_GetPropEnt(Handle:plugin, numParams)
{
	new len;
	GetNativeStringLength(1, len);
	if (len <= 0)
	{
	  return false;
	}
	new String:prop[len+1],retval=-1;
	GetNativeString(1, prop, len+1);
	new element = GetNativeCell(2);
	GetObjResEnt();
	if (g_iObjResEntity > 0)
	{
		retval = GetEntData(g_iObjResEntity, FindSendPropOffs("CINSObjectiveResource", prop) + (4 * element));
	}
	return retval;
}
public Native_ObjectiveResource_GetPropBool(Handle:plugin, numParams)
{
	new len;
	GetNativeStringLength(1, len);
	if (len <= 0)
	{
	  return false;
	}
	new String:prop[len+1],retval=-1;
	GetNativeString(1, prop, len+1);
	new element = GetNativeCell(2);
	GetObjResEnt();
	if (g_iObjResEntity > 0)
	{
		retval = bool:GetEntData(g_iObjResEntity, FindSendPropOffs("CINSObjectiveResource", prop) + (element));
	}
	return _:retval;
}
public Native_ObjectiveResource_GetPropVector(Handle:plugin, numParams)
{
	new len;
	GetNativeStringLength(1, len);
	if (len <= 0)
	{
	  return false;
	}
	new String:prop[len+1],retval=-1;
	GetNativeString(1, prop, len+1);
	new size = GetNativeCell(2);
	new element = GetNativeCell(3);
	GetObjResEnt();
	if (g_iObjResEntity > 0)
	{
		new Float:result[3];
		retval = GetEntDataVector(g_iObjResEntity, FindSendPropOffs("CINSObjectiveResource", prop) + (size * element), result);
		SetNativeArray(2, result, 3);
	}
	return retval;
}
public Native_ObjectiveResource_GetPropString(Handle:plugin, numParams)
{
	new len;
	GetNativeStringLength(1, len);
	if (len <= 0)
	{
	  return false;
	}
	new String:prop[len+1],retval=-1;
	GetNativeString(1, prop, len+1);
/*
	new maxlen = GetNativeCell(3);
	GetObjResEnt();
	if (g_iObjResEntity > 0)
	{
		//SetNativeString(2, buffer, maxlen+1);
		//GetEntData(g_iObjResEntity, FindSendPropOffs("CINSObjectiveResource", prop) + (size * element));
	}
*/
	return retval;
}























//=====================================================================================================
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
	decl String:cappers[256],String:cpname[64];
	//new priority = GetEventInt(event, "priority");
	new cp = GetEventInt(event, "cp");
	GetEventString(event, "cappers", cappers, sizeof(cappers));
	GetEventString(event, "cpname", cpname, sizeof(cpname));
	new team = GetEventInt(event, "team");
	new capperlen = GetCharBytes(cappers);
	PrintToServer("[INSLIB] Event_ControlPointCaptured cp %d capperlen %d cpname %s team %d", cp,capperlen,cpname,team);

	//"cp" "byte" - for naming, currently not needed
	for (new i = 0; i < strlen(cappers); i++)
	{
		new client = cappers[i];
		PrintToServer("[INSLIB] Event_ControlPointCaptured parsing capper id %d client %d",i,client);
		if(client > 0 && client <= MaxClients && IsClientInGame(client))
		{
			decl String:player_authid[64];
			if (!GetClientAuthId(client, AuthId_Steam2, player_authid, sizeof(player_authid)))
			{
				strcopy(player_authid, sizeof(player_authid), "UNKNOWN");
			}
			new player_userid = GetClientUserId(client);
			new player_team_index = GetClientTeam(client);
			g_round_stats[client][STAT_CAPTURES]++;
			LogToGame("\"%N<%d><%s><%s>\" triggered \"ins_cp_captured\"", client, player_userid, player_authid, g_team_list[player_team_index]);
		}
	}
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
	decl String:cappers[256],String:cpname[64];
	//new priority = GetEventInt(event, "priority");
	//new cp = GetEventInt(event, "cp");
	GetEventString(event, "cappers", cappers, sizeof(cappers));
	GetEventString(event, "cpname", cpname, sizeof(cpname));
	//new team = GetEventInt(event, "team");

	//new capperlen = GetCharBytes(cappers);
	//PrintToServer("[INSLIB] Event_ControlPointNeutralized priority %d cp %d capperlen %d cpname %s team %d", priority,cp,capperlen,cpname,team);

	//"cp" "byte" - for naming, currently not needed
	GetEventString(event, "cappers", cappers, sizeof(cappers));
	for (new i = 0 ; i < strlen(cappers); i++)
	{
		new client = cappers[i];
		if(client > 0 && client <= MaxClients && IsClientInGame(client))
		{
			decl String:player_authid[64];
			if (!GetClientAuthId(client, AuthId_Steam2, player_authid, sizeof(player_authid)))
			{
				strcopy(player_authid, sizeof(player_authid), "UNKNOWN");
			}
			new player_userid = GetClientUserId(client);
			new player_team_index = GetClientTeam(client);

			LogToGame("\"%N<%d><%s><%s>\" triggered \"ins_cp_neutralized\"", client, player_userid, player_authid, g_team_list[player_team_index]);
		}
	}
	return Plugin_Continue;
}
public Action:Event_ControlPointStartTouch(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	new area = GetEventInt(event, "area");
	new m_iObject = GetEventInt(event, "object");
	new player = GetEventInt(event, "player");
	new team = GetEventInt(event, "team");
	new owner = GetEventInt(event, "owner");
	new type = GetEventInt(event, "type");
	PrintToServer("[INSLIB] Event_ControlPointStartTouch: player %N area %d object %d player %d team %d owner %d type %d",player,area,m_iObject,player,team,owner,type);
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

	//PrintToServer("[INSLIB] Event_ControlPointEndTouch: player %N area %d player %d team %d owner %d",player,area,player,team,owner);
	return Plugin_Continue;
}

public Action:Event_ObjectDestroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	decl String:attacker_authid[64],String:assister_authid[64],String:classname[64];
	//"team" "byte"
	//"attacker" "byte"
	//"cp" "short"
	//"index" "short"
	//"type" "byte"
	//"weapon" "string"
	//"weaponid" "short"
	//"assister" "byte"
	//"attackerteam" "byte"
	new team = GetEventInt(event, "team");
	new attacker = GetEventInt(event, "attacker");
	new attackerteam = GetEventInt(event, "attackerteam");
	new cp = GetEventInt(event, "cp");
	new index = GetEventInt(event, "index");
	new type = GetEventInt(event, "type");
	new weaponid = GetEventInt(event, "weaponid");
	new assister = GetEventInt(event, "assister");
	new assister_userid = -1;
	new attacker_userid = -1;
	new assisterteam = -1;
	if (index)
	{
		GetEdictClassname(index, classname, sizeof(classname));
	}
	if ((assister) && (assister != attacker))
	{
		assister_userid = GetClientUserId(assister);
		if (assister_userid)
		{
			assisterteam = GetClientTeam(assister);
			if (!GetClientAuthId(assister, AuthId_Steam2, assister_authid, sizeof(assister_authid)))
			{
				strcopy(assister_authid, sizeof(assister_authid), "UNKNOWN");
			}
			g_round_stats[assister][STAT_CACHES]++;

			LogToGame("\"%N<%d><%s><%s>\" triggered \"ins_cp_destroyed\"", assister, assister_userid, assister_authid, g_team_list[assisterteam]);
		}
	}

	if (attacker)
	{
		attacker_userid = GetClientUserId(attacker);
		if (!GetClientAuthId(attacker, AuthId_Steam2, attacker_authid, sizeof(attacker_authid)))
		{
			strcopy(attacker_authid, sizeof(attacker_authid), "UNKNOWN");
		}
		g_round_stats[attacker][STAT_CACHES]++;
		LogToGame("\"%N<%d><%s><%s>\" triggered \"ins_cp_destroyed\"", attacker, attacker_userid, attacker_authid, g_team_list[attackerteam]);
	}
	PrintToServer("[INSLIB] Event_ObjectDestroyed: team %d attacker %d attacker_userid %d cp %d classname %s index %d type %d weaponid %d assister %d assister_userid %d attackerteam %d",team,attacker,attacker_userid,cp,classname,index,type,weaponid,assister,assister_userid,attackerteam);
	return Plugin_Continue;
}
public Action:Event_WeaponFired(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	//"weaponid" "short"
	//"userid" "short"
	//"shots" "byte"
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:shotWeapName[32];
	GetClientWeapon(client, shotWeapName, sizeof(shotWeapName));
	//Game WeaponId is not consistent with our list, we cannot assume it to be the same, thus the requirement for iteration. it's slow but it'll do
	new weapon_index = Ins_GetWeaponId(shotWeapName);
	//PrintToChatAll("WeapFired: %s", shotWeapName);
	//PrintToServer("WeaponIndex: %d - %s", weapon_index, shotWeapName);
	
	if (weapon_index > -1)
	{
		g_weapon_stats[client][weapon_index][LOG_HIT_SHOTS]++;
		g_round_stats[client][STAT_SHOTS]++;
		g_client_last_weapon[client] = weapon_index;
		g_client_last_weaponstring[client] = shotWeapName;
	}
	return Plugin_Continue;
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	OnPlayerDisconnect(client);
	return Plugin_Continue;
}

public Action:Event_PlayerDeathPre(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	LogKillLoc(GetClientOfUserId(GetEventInt(event, "attacker")), GetClientOfUserId(GetEventInt(event, "userid")));
	return Plugin_Continue;
}
public Action:Event_PlayerSuppressed( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"attacker" "short"
	//"victim" "short"
	new victim   = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (attacker == 0 || victim == 0 || attacker == victim)
	{
		return Plugin_Continue;
	}
	g_round_stats[attacker][STAT_SUPPRESSIONS]++;
	LogPlyrPlyrEvent(attacker, victim, "triggered", "suppressed");
	return Plugin_Continue;
}
public Action:Event_PlayerAvengedTeammate( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"avenger_id" "short"
	//"avenged_player_id" "short"
	new attacker = GetClientOfUserId(GetEventInt(event, "avenger_id"));
	if (attacker == 0)
	{
		return Plugin_Continue;
	}
	LogPlayerEvent(attacker, "triggered", "avenged");
	return Plugin_Continue;
}
public Action:Event_GrenadeThrown( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"entityid" "long"
	//"userid" "short"
	//"id" "short"
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_round_stats[client][STAT_GRENADES]++;
	return Plugin_Continue;
}
public Action:Event_GrenadeDetonate( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"userid" "short"
	//"effectedEnemies" "short"
	//"y" "float"
	//"x" "float"
	//"entityid" "long"
	//"z" "float"
	//"id" "short"
	return Plugin_Continue;
}
public Action:Event_GameStart( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"priority" "short"
	new priority = GetEventInt( event, "priority");
	LogToGame("World triggered \"Game_Start\" (priority \"%d\")",priority);
	return Plugin_Continue;
}
public Action:Event_GameNewMap( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"mapname" "string"
	decl String:mapname[255];
	GetEventString(event, "mapname",mapname,sizeof(mapname));
	LogToGame("World triggered \"Game_NewMap\" (mapname \"%s\")",mapname);
	return Plugin_Continue;
}
public Action:Event_RoundLevelAdvanced( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"level" "short"
	new level = GetEventInt( event, "level");
	for (new client=1; client<=MaxClients; client++)
	{
		if(client > 0 && client <= MaxClients && IsClientInGame(client))
		{
			decl String:player_authid[64];
			if (!GetClientAuthId(client, AuthId_Steam2, player_authid, sizeof(player_authid)))
			{
				strcopy(player_authid, sizeof(player_authid), "UNKNOWN");
			}
			new player_userid = GetClientUserId(client);
			new player_team_index = GetClientTeam(client);

			LogToGame("\"%N<%d><%s><%s>\" triggered \"round_level_advanced\" (level \"%d\")", client, player_userid, player_authid, g_team_list[player_team_index],level);
		}
	}
	LogToGame("World triggered \"Round_LevelAdvanced\" (level \"%d\")",level);
	return Plugin_Continue;
}
public Action:Event_GameEnd( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"team2_score" "short"
	//"winner" "byte"
	//"team1_score" "short"
	new winner = GetEventInt( event, "winner");
	new team1_score = GetEventInt( event, "team1_score");
	new team2_score = GetEventInt( event, "team2_score");
	LogToGame("World triggered \"Game_End\" (winner \"%d\") (team1_score \"%d\") (team2_score \"%d\")", winner,team1_score,team2_score);
	return Plugin_Continue;
}
public Action:Event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"priority" "short"
	//"timelimit" "short"
	//"lives" "short"
	//"gametype" "short"
	new priority = GetEventInt( event, "priority");
	new timelimit = GetEventInt( event, "timelimit");
	new lives = GetEventInt( event, "lives");
	new gametype = GetEventInt( event, "gametype");
	LogToGame("World triggered \"Round_Start\" (priority \"%d) (timelimit \"%d\") (lives \"%d\") (gametype \"%d\")",priority,timelimit,lives,gametype);
	return Plugin_Continue;
}
public Action:Event_RoundBegin( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"priority" "short"
	//"timelimit" "short"
	//"lives" "short"
	//"gametype" "short"
	new priority = GetEventInt( event, "priority");
	new timelimit = GetEventInt( event, "timelimit");
	new lives = GetEventInt( event, "lives");
	new gametype = GetEventInt( event, "gametype");
	LogToGame("World triggered \"Round_Begin\" (priority \"%d\") (timelimit \"%d\") (lives \"%d\") (gametype \"%d\")",priority,timelimit,lives,gametype);
	return Plugin_Continue;
}
public Action:Event_MissileLaunched( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"entityid" "long"
	//"userid" "short"
	//"id" "short"
	return Plugin_Continue;
}
public Action:Event_MissileDetonate( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"userid" "short"
	//"y" "float"
	//"x" "float"
	//"entityid" "long"
	//"z" "float"
	//"id" "short"
	return Plugin_Continue;
}


public Action:Event_PlayerSpawn( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	if( client == 0 || !IsClientInGame(client) )
		return Plugin_Continue;	
	reset_player_stats(client);
	//reset_round_stats(client);
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

	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	decl String:weapon[32];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	//new weaponid = GetEventInt(event, "weaponid");

	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	if (assister) {
		LogPlayerEvent(assister, "triggered", "kill assist");
	}

	new weapon_index = g_client_last_weapon[attacker];
	if (weapon_index < 0)
	{
		return Plugin_Continue;
	}
	//PrintToServer("[INSLIB] from event (weaponid: %d weapon: %s) from last (g_client_hurt_weaponstring: %s weapon_index: %d strLastWeapon: %s)", weaponid, weapon, g_client_hurt_weaponstring[victim], weapon_index, strLastWeapon);
	
	if (attacker == 0 || victim == 0 || attacker == victim)
	{
		return Plugin_Continue;
	}	
	g_weapon_stats[attacker][weapon_index][LOG_HIT_KILLS]++;
	g_weapon_stats[victim][weapon_index][LOG_HIT_DEATHS]++;
	g_round_stats[attacker][STAT_KILLS]++;
	g_round_stats[victim][STAT_DEATHS]++;
	if (GetClientTeam(attacker) == GetClientTeam(victim))
	{
		g_weapon_stats[attacker][weapon_index][LOG_HIT_TEAMKILLS]++;
		g_round_stats[attacker][STAT_TEAMKILLS]++;
	}
	
	//PrintToChat(attacker, "Kills: %d", g_weapon_stats[attacker][weapon_index][LOG_HIT_KILLS]);
	dump_player_stats(victim);
	return Plugin_Continue;
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	//"userid" "short"
	//"weapon" "string"
	//"hitgroup" "short"
	//"priority" "short"
	//"attacker" "short"
	//"dmg_health" "short"
	//"health" "byte"
	decl String:weapon[MAX_WEAPON_LEN];
	new attacker  = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	if (StrEqual(weapon,"player")) {
		g_client_hurt_weaponstring[victim] = weapon;
	} else {
		if(StrContains(weapon, "grenade_") > -1 || StrContains(weapon, "rocket_") > -1) {
			ReplaceString(weapon, sizeof(weapon), "grenade_c4", "weapon_c4_clicker", false);
			ReplaceString(weapon, sizeof(weapon), "grenade_ied", "weapon_c4_ied", false);
			ReplaceString(weapon, sizeof(weapon), "grenade_", "weapon_", false);
			ReplaceString(weapon, sizeof(weapon), "rocket_", "weapon_", false);
		}
		g_client_hurt_weaponstring[victim] = weapon;
	}
	//PrintToServer("[INSLIB] PlayerHurt attacher %d victim %d weapon %s ghws: %s", attacker, victim, weapon,g_client_hurt_weaponstring[victim]);
	if (attacker > 0 && attacker != victim)
	{
		new hitgroup  = GetEventInt(event, "hitgroup");
		if (hitgroup < 8)
		{
			hitgroup += LOG_HIT_OFFSET;
		}
		
		
		decl String:clientname[64];
		GetClientName(attacker, clientname, sizeof(clientname));
		

		//new weapon_index = Ins_GetWeaponId(weapon, -1 ,false);
		//PrintToChatAll("idx: %d - weapon: %s", weapon_index, weapon);
		new weapon_index = Ins_GetWeaponId(weapon);

		if (weapon_index > -1)  {
			g_weapon_stats[attacker][weapon_index][LOG_HIT_HITS]++;
			g_round_stats[attacker][STAT_HITS]++;
			g_round_stats[attacker][STAT_DMG_GIVEN] += GetEventInt(event, "dmg_health");
			g_round_stats[victim][STAT_DMG_TAKEN] += GetEventInt(event, "dmg_health");
			g_weapon_stats[attacker][weapon_index][LOG_HIT_DAMAGE] += GetEventInt(event, "dmg_health");
			g_weapon_stats[attacker][weapon_index][hitgroup]++;
			
			if (hitgroup == (_:HITGROUP_HEAD+LOG_HIT_OFFSET))
			{
				g_weapon_stats[attacker][weapon_index][LOG_HIT_HEADSHOTS]++;
			}
			g_client_last_weapon[attacker] = weapon_index;
			g_client_last_weaponstring[attacker] = weapon;
		}
		
		if (hitgroup == (_:HITGROUP_HEAD+LOG_HIT_OFFSET))
		{
			LogPlayerEvent(attacker, "triggered", "headshot");
		}
	}
	return Plugin_Continue;
}

public Action:LogEvent(const String:message[])
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	if(StrContains(message, "killed") > -1 &&
	StrContains(message, "with") > -1 &&
	StrContains(message, "at") > -1)
	{
		new bool:found_weap = false;
		new String:strReassembledKillMsg[512];
		new String:strBuffer[256];
		
		//strings to hold various info
		new String:strWeapName[64];
		new String:strRegexKillerNameFull[64];
		new String:strRegexVictimNameFull[64];
		new String:strRegexKillParameters[256];
		
		//perform dissection of message
		if(kill_regex != INVALID_HANDLE)
		{
			//Get Number of SubStrings
			new numSubStr = MatchRegex(kill_regex, message);
			//PrintToChatAll("[REGEX] Substrings: %d", numSubStr);
			
			if(numSubStr != 5)
			{					
				return Plugin_Continue;
			}

			//Regex SHOULD have 1+4 substrings, but first we need to check that victims/killers are appropriately placed
			
			//SUBSTRING 1: KILLER
			GetRegexSubString(kill_regex, 1, strBuffer, sizeof(strBuffer));
			Format(strRegexKillerNameFull, sizeof(strRegexKillerNameFull), "%s", strBuffer);
			//PrintToChatAll("[REGEX] SubStr1: %s", strRegexKillerNameFull);
			//RETRIEVE KILLER'S WEAPON HERE!
			//SUBSTRING 2: VICTIM
			GetRegexSubString(kill_regex, 2, strBuffer, sizeof(strBuffer));
			Format(strRegexVictimNameFull, sizeof(strRegexVictimNameFull), "%s", strBuffer);
			
			//SUBSTRING 3: WEAPON NAME
			//No need to do anything with weapon name, we are going to replace it

			//Load client last hurt weapon
			for (new v=1; v<=MaxClients; v++)
			{
				if(IsClientInGame(v) && IsClientConnected(v))
				{
					GetClientName(v, strBuffer, sizeof(strBuffer));
					if(StrContains(strRegexVictimNameFull, strBuffer) > -1)
					{
						strWeapName = g_client_hurt_weaponstring[v];
						found_weap = true;
						break;
					}
				}
			}
			
			//SUBSTRING 4: PARAMETERS
			GetRegexSubString(kill_regex, 4, strBuffer, sizeof(strBuffer));
			Format(strRegexKillParameters, sizeof(strRegexKillParameters), "%s", strBuffer);
			
			//ASSEMBLE MESSAGE
			if(found_weap)
			{
				Format(strReassembledKillMsg, sizeof(strReassembledKillMsg), "\"%s\" killed \"%s\" with \"%s\" at %s", strRegexKillerNameFull, strRegexVictimNameFull, strWeapName, strRegexKillParameters);
			}
			else
			{
				/*
				GetRegexSubString(kill_regex, 3, strBuffer, sizeof(strBuffer));
				Format(strReassembledKillMsg, sizeof(strReassembledKillMsg), "\"%s\" killed \"%s\" with \"%s\" at %s", strRegexKillerNameFull, strRegexVictimNameFull, strBuffer, strRegexKillParameters);
				*/
				return Plugin_Continue;
			}
			//PrintToChatAll("[REGEX] Reassembled: %s", strReassembledKillMsg);
			LogToGame("%s", strReassembledKillMsg);
			
			return Plugin_Handled;
		}
		else
		{
			PrintToChatAll("[INSLIB] Regex Pattern Failure!");
		}
	}
	else if(StrContains(message, "committed suicide") > -1)
	{
		//perform dissection of message
		if(suicide_regex != INVALID_HANDLE)
		{
			new String:strBuffer[256];
			new String:strWeapName[64];
			new String:strReassembledMsg[512];
			new String:strRegexSuiciderNameFull[64];		
			new bool:found_weap = false;
			//Get Number of SubStrings
			new numSubStr = MatchRegex(suicide_regex, message);
			
			if(numSubStr != 3)
			{		
				return Plugin_Continue;
			}
			
			//SUBSTR 1: Name of the stupid guy who shot himself
			GetRegexSubString(suicide_regex, 1, strBuffer, sizeof(strBuffer));
			Format(strRegexSuiciderNameFull, sizeof(strRegexSuiciderNameFull), "%s", strBuffer);
			
			for (new k=1; k<=MaxClients; k++)
			{
				if(IsClientInGame(k) && IsClientConnected(k))
				{
					GetClientName(k, strBuffer, sizeof(strBuffer));
					if(StrContains(strRegexSuiciderNameFull, strBuffer) > -1)
					{
						strWeapName = g_client_hurt_weaponstring[k];//g_client_last_weaponstring[k];
						found_weap = true;
						break;
					}
				}
			}
			
			//SUBSTR 2: WEAPON (WE NEED TO REPLACE THIS!);
			if(found_weap)
			{
				Format(strReassembledMsg, sizeof(strReassembledMsg), "\"%s\" commited suicide with \"%s\"", strRegexSuiciderNameFull, strWeapName);
			}
			else
			{
				return Plugin_Continue;
			}
			
			LogToGame("%s", strReassembledMsg);
			
			return Plugin_Handled;
		}
		else
		{
			PrintToChatAll("[INSLIB] Regex Pattern Failure");
		}
	}
	else if(StrContains(message, "obj_captured") > -1) return Plugin_Handled;
	else if(StrContains(message, "obj_destroyed") > -1) return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action:Event_RoundEnd( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"reason" "byte"
	//"winner" "byte"
	//"message" "string"
	//"message_string" "string"
	new winner = GetEventInt( event, "winner");
	new reason = GetEventInt( event, "reason");
	decl String:message[255],String:message_string[255];
	GetEventString(event, "message",message,sizeof(message));
	GetEventString(event, "message_string",message_string,sizeof(message_string));
	LogToGame("World triggered \"Round_End\" (winner \"%d\") (reason \"%d\") (message \"%s\") (message_string \"%s\")",winner,reason,message,message_string);
	DoRoundAwards();
	WstatsDumpAll();
	GetObjResEnt();
	return Plugin_Continue;
}


public Action:Event_PlayerPickSquad(Handle:event, const String:name[], bool:dontBroadcast)
{
	//"squad_slot" "byte"
	//"squad" "byte"
	//"userid" "short"
	//"class_template" "string"
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new squad = GetEventInt( event, "squad" );
	new squad_slot = GetEventInt( event, "squad_slot" );
	new team = GetClientTeam(client);
	decl String:class_template[MAX_CLASS_LEN];
	GetEventString(event, "class_template",class_template,sizeof(class_template));
	ReplaceString(class_template,sizeof(class_template),"template_","",false);
	ReplaceString(class_template,sizeof(class_template),"_training","",false);
	ReplaceString(class_template,sizeof(class_template),"_coop","",false);
	ReplaceString(class_template,sizeof(class_template),"coop_","",false);
	ReplaceString(class_template,sizeof(class_template),"_security","",false);
	ReplaceString(class_template,sizeof(class_template),"_insurgent","",false);
	ReplaceString(class_template,sizeof(class_template),"_survival","",false);
	UpdateClassName(team,squad,squad_slot,class_template);

	if( client == 0)
		return Plugin_Continue;
	if(!StrEqual(g_client_last_classstring[client],class_template)) {
		LogRoleChange( client, class_template );
		g_client_last_classstring[client] = class_template;
	}
	return Plugin_Continue;
}
