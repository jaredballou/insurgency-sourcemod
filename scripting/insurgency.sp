#define PLUGIN_DESCRIPTION "Provides functions to support Insurgency. Includes logging, round statistics, weapon names, player class names, and more."
#define PLUGIN_NAME "[INS] Insurgency Support Library"
#define PLUGIN_VERSION "1.4.0"
#define PLUGIN_WORKING "1"
#define PLUGIN_LOG_PREFIX "INSLIB"
#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_URL "http://jballou.com/insurgency"

public Plugin:myinfo = {
        name            = PLUGIN_NAME,
        author          = PLUGIN_AUTHOR,
        description     = PLUGIN_DESCRIPTION,
        version         = PLUGIN_VERSION,
        url             = PLUGIN_URL
};
#include <sourcemod>
#include <regex>
#include <sdktools>
#include <insurgency>
#include <loghelper>
#undef REQUIRE_PLUGIN
#include <updater>
#pragma unused cvarVersion


#define INS

new Handle:cvarVersion = INVALID_HANDLE; // version cvar
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
new Handle:cvarCheckpointCounterattackCapture = INVALID_HANDLE;
new Handle:cvarCheckpointCapturePlayerRatio = INVALID_HANDLE;
new Handle:cvarInfiniteAmmo = INVALID_HANDLE; // Infinite ammo (still needs reloads)
new Handle:cvarInfiniteMagazine = INVALID_HANDLE; // Infinite magazine (never need to reload)
new Handle:cvarDisableSliding = INVALID_HANDLE; // Disable Sliding
new Handle:cvarLogLevel = INVALID_HANDLE; // Log level
new Handle:cvarClassStripWords = INVALID_HANDLE;

new Handle:g_weap_array = INVALID_HANDLE;
new Handle:hGameConf = INVALID_HANDLE;

new g_iObjResEntity, String:g_iObjResEntityNetClass[32];
new g_iLogicEntity, String:g_iLogicEntityNetClass[32]
new g_iPlayerManagerEntity, String:g_iPlayerManagerEntityNetClass[32];

new String:g_classes[Teams][MAX_SQUADS][SQUAD_SIZE][MAX_CLASS_LEN];

new g_weapon_stats[MAXPLAYERS+1][MAX_DEFINABLE_WEAPONS][WeaponStatFields];
new g_round_stats[MAXPLAYERS+1][RoundStatFields];
new g_client_last_weapon[MAXPLAYERS+1] = {-1, ...};
new String:g_client_last_weaponstring[MAXPLAYERS+1][64];
new String:g_client_hurt_weaponstring[MAXPLAYERS+1][64];
new String:g_client_last_classstring[MAXPLAYERS+1][64];

#define KILL_REGEX_PATTERN "^\"(.+(?:<[^>]*>))\" killed \"(.+(?:<[^>]*>))\" with \"([^\"]*)\" at (.*)"
#define SUICIDE_REGEX_PATTERN "^\"(.+(?:<[^>]*>))\" committed suicide with \"([^\"]*)\""

new Handle:kill_regex = INVALID_HANDLE;
new Handle:suicide_regex = INVALID_HANDLE;

#define MAX_STRIP_LEN 32
#define MAX_STRIP_COUNT 16
//new String:ServerName[100];// Stores the server name.
//new String:Version[100];    // Stores the update version number
//new String:IP_Port[100];    // Stores the IP address & port number
//new String:SteamID[100];    // Stores the steam server ID
//new String:Account[100];    // Stores the account logged into the server.
//new String:Map[100];// Stores the current map name
//new String:Players[100];    // Stores the total number of players & bots active
//new String:Edicts[100];    // Stores total number of edicts used
//============================================================================================================

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	RegPluginLibrary("insurgency");	
	CreateNative("Ins_GetWeaponGetMaxClip1", Native_Weapon_GetMaxClip1);
	CreateNative("Ins_GetMaxClip1", Native_Weapon_GetMaxClip1);
	CreateNative("Ins_GetDefaultClip1", Native_Weapon_GetDefaultClip1);
	CreateNative("Ins_GetWeaponName", Native_Weapon_GetWeaponName);
	CreateNative("Ins_GetWeaponId", Native_Weapon_GetWeaponId);

	CreateNative("Ins_ObjectiveResource_GetProp", Native_ObjectiveResource_GetProp);
	CreateNative("Ins_ObjectiveResource_GetPropFloat", Native_ObjectiveResource_GetPropFloat);
	CreateNative("Ins_ObjectiveResource_GetPropEnt", Native_ObjectiveResource_GetPropEnt);
	CreateNative("Ins_ObjectiveResource_GetPropBool", Native_ObjectiveResource_GetPropBool);
	CreateNative("Ins_ObjectiveResource_GetPropVector", Native_ObjectiveResource_GetPropVector);
	CreateNative("Ins_ObjectiveResource_GetPropString", Native_ObjectiveResource_GetPropString);

	CreateNative("Ins_InCounterAttack", Native_InCounterAttack);
	CreateNative("Ins_Log", Native_Log);

	CreateNative("Ins_GetPlayerScore", Native_GetPlayerScore);
	CreateNative("Ins_GetPlayerClass", Native_GetPlayerClass);
	return APLRes_Success;
}

public OnPluginStart() {
	cvarVersion = CreateConVar("sm_insurgency_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_insurgency_enabled", PLUGIN_WORKING, "sets whether log fixing is enabled", FCVAR_NOTIFY);
	cvarCheckpointCapturePlayerRatio = CreateConVar("sm_insurgency_checkpoint_capture_player_ratio", "0.5", "Fraction of living players required to capture in Checkpoint", FCVAR_NOTIFY);
	cvarCheckpointCounterattackCapture = CreateConVar("sm_insurgency_checkpoint_counterattack_capture", "0", "Enable counterattack by bots to capture points in Checkpoint", FCVAR_NOTIFY);
	cvarInfiniteAmmo = CreateConVar("sm_insurgency_infinite_ammo", "0", "Infinite ammo, still uses magazines and needs to reload", FCVAR_NOTIFY);
	cvarInfiniteMagazine = CreateConVar("sm_insurgency_infinite_magazine", "0", "Infinite magazine, will never need reloading.", FCVAR_NOTIFY);
	cvarDisableSliding = CreateConVar("sm_insurgency_disable_sliding", "0", "0: do nothing, 1: disable for everyone, 2: disable for Security, 3: disable for Insurgents", FCVAR_NOTIFY);
	cvarLogLevel = CreateConVar("sm_insurgency_log_level", "error", "Logging level, values can be: all, trace, debug, info, warn, error", FCVAR_NOTIFY);
	cvarClassStripWords = CreateConVar("sm_insurgency_class_strip_words", "template training coop security insurgent survival", "Strings to strip out of player class (squad slot) names", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookConVarChange(cvarLogLevel,OnCvarLogLevelChange);

	InsLog(DEFAULT,"Starting");

	kill_regex = CompileRegex(KILL_REGEX_PATTERN);
	suicide_regex = CompileRegex(SUICIDE_REGEX_PATTERN);
	
	//Begin HookEvents
	hook_wstats();

	// Hook events
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("weapon_firemode", Event_WeaponFireMode);
	HookEvent("weapon_reload", Event_WeaponReload);
	HookEvent("weapon_deploy", Event_WeaponDeploy);
	
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_pick_squad", Event_PlayerPickSquad);
	HookEvent("player_suppressed", Event_PlayerSuppressed);
	HookEvent("player_avenged_teammate", Event_PlayerAvengedTeammate);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);

	HookEvent("grenade_thrown", Event_GrenadeThrown);
	HookEvent("grenade_detonate", Event_GrenadeDetonate);

	HookEvent("game_end", Event_GameEnd);
	HookEvent("game_end", Event_GameEndPre, EventHookMode_Pre);
	HookEvent("game_newmap", Event_GameNewMap);
	HookEvent("game_start", Event_GameStart);

	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_begin", Event_RoundBegin);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_end", Event_RoundEndPre, EventHookMode_Pre);
	HookEvent("round_level_advanced", Event_RoundLevelAdvanced);

	HookEvent("missile_launched", Event_MissileLaunched);
	HookEvent("missile_detonate", Event_MissileDetonate);

	HookEvent("object_destroyed", Event_ObjectDestroyed);
	HookEvent("controlpoint_captured", Event_ControlPointCaptured);
	HookEvent("controlpoint_captured", Event_ControlPointCapturedPre, EventHookMode_Pre);
	HookEvent("controlpoint_neutralized", Event_ControlPointNeutralized);
	HookEvent("controlpoint_starttouch", Event_ControlPointStartTouchPre, EventHookMode_Pre);
	HookEvent("controlpoint_starttouch", Event_ControlPointStartTouch);
	HookEvent("controlpoint_endtouch", Event_ControlPointEndTouch);

	HookEvent("enter_spawnzone", Event_EnterSpawnZone);
	HookEvent("exit_spawnzone", Event_ExitSpawnZone);

	hGameConf = LoadGameConfigFile("insurgency.games");

	//Begin Engine LogHooks
	AddGameLogHook(LogEvent);

//	LoadTranslations("insurgency.phrases");

	//UpdateAllDataSources();
	HookUpdater();
}
public OnCvarLogLevelChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	// If nothing has changed, exit
	if (strcmp(oldVal,newVal,false) == 0)
		return;
	for (new i=0; i<sizeof(g_sLogLevel); i++)
	{
		if (strcmp(newVal,g_sLogLevel[i],false) == 0)
		{
			g_iLogLevel = LOG_LEVEL:i;
			InsLog(DEBUG,"New log level is %s (%d), g_iLogLevel %d, old was %s",newVal,i,g_iLogLevel,oldVal);
		}
	}
}

public OnPluginEnd()
{
	WstatsDumpAll();
	g_weap_array = INVALID_HANDLE;
	g_iLogicEntity = -1;
	g_iObjResEntity = -1;
	g_iPlayerManagerEntity = -1;
}

public OnMapStart()
{
	UpdateAllDataSources();
}
public UpdateAllDataSources()
{
	InsLog(DEBUG,"Starting UpdateAllDataSources");
	GetObjResEnt(1);
	GetLogicEnt(1);
	GetPlayerManagerEnt(1);
	GetWeaponData();
	GetTeams(false);
	GetStatus();
//CreateTimer(4.5, GetStatus);
}

public GetStatus()
//Action:GetStatus(Handle:Timer)
{
	InsLog(DEBUG,"Starting GetStatus");
	// Grab status output.
	// 600 characters is enough,
//	decl String:Output[600];
//	ServerCommandEx(Output, 600, "version");
	// Grab the first 8 lines out only
//	decl String:Derp[8][100];
//	ExplodeString(Output, "\n", Derp, 8, 100);
//	ServerName = Derp[0];	// Server name
//	Version = Derp[1];	// Version number
//	InsLog(DEBUG,"Derp %s Version %s",Derp,Version);
//	IP_Port = Derp[2];	// Port & IP
//	SteamID = Derp[3];	// Server steam ID
//	Account = Derp[4];	// Steam account logged in
//	Map = Derp[5];		// Map name
//	Players = Derp[6];	// Players & bots
//	Edicts = Derp[7];	// Edict count
//new Handle:fileHandle=OpenFile(path,"r"); // Opens addons/sourcemod/blank.txt to read from (and only reading)
//while(!IsEndOfFile(fileHandle)&&ReadFileLine(fileHandle,line,sizeof(line)))
//{
//  InsLog(DEBUG,"line %s",line);
//}
//CloseHandle(fileHandle);
}
public OnLibraryAdded(const String:name[]) {
	HookUpdater();
}
OnPlayerDisconnect(client)
{
	if(client > 0 && IsClientInGame(client))
	{
		dump_player_stats(client);
		reset_player_stats(client);
		reset_round_stats(client);
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
	FormatPlayerClassName(class_template,sizeof(class_template),raw_class_template);
	if(!StrEqual(g_classes[team][squad][squad_slot],class_template))
	{
		InsLog(DEBUG,"team: %d squad: %d squad_slot: %d class_template: %s",team,squad,squad_slot,class_template);
		Format(g_classes[team][squad][squad_slot],MAX_CLASS_LEN,"%s",class_template);
	}
}
GetObjResEnt(always=0)
{
	if (((g_iObjResEntity < 1) || !IsValidEntity(g_iObjResEntity)) || (always))
	{
		g_iObjResEntity = FindEntityByClassname(0,"ins_objective_resource");
		GetEntityNetClass(g_iObjResEntity, g_iObjResEntityNetClass, sizeof(g_iObjResEntityNetClass));
		InsLog(DEBUG,"g_iObjResEntityNetClass %s",g_iObjResEntityNetClass);
	}
	if (g_iObjResEntity)
		return g_iObjResEntity;
	InsLog(WARN,"GetObjResEnt failed!");
	return -1;
}
GetLogicEnt(always=0) {
	if (((g_iLogicEntity < 1) || !IsValidEntity(g_iLogicEntity)) || (always))
	{
		new String:sGameMode[32],String:sLogicEnt[64];
		GetConVarString(FindConVar("mp_gamemode"), sGameMode, sizeof(sGameMode));
		Format (sLogicEnt,sizeof(sLogicEnt),"logic_%s",sGameMode);
		if (!StrEqual(sGameMode,"checkpoint")) return -1;
		g_iLogicEntity = FindEntityByClassname(-1,sLogicEnt);
		GetEntityNetClass(g_iLogicEntity, g_iLogicEntityNetClass, sizeof(g_iLogicEntityNetClass));
		InsLog(DEBUG,"g_iLogicEntityNetClass %s",g_iLogicEntityNetClass);
	}
	if (g_iLogicEntity)
		return g_iLogicEntity;
	InsLog(WARN,"GetLogicEnt failed!");
	return -1;
}
GetPlayerManagerEnt(always=0) {
	if (((g_iPlayerManagerEntity < 1) || !IsValidEntity(g_iPlayerManagerEntity)) || (always))
	{
		g_iPlayerManagerEntity = FindEntityByClassname(-1,"ins_player_manager");
		GetEntityNetClass(g_iPlayerManagerEntity, g_iPlayerManagerEntityNetClass, sizeof(g_iPlayerManagerEntityNetClass));
		InsLog(DEBUG,"g_iPlayerManagerEntityNetClass %s",g_iPlayerManagerEntityNetClass);
	}
	if (g_iPlayerManagerEntity)
		return g_iPlayerManagerEntity;
	InsLog(WARN,"GetPlayerManagerEnt failed!");
	return -1;
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
		InsLog(DEBUG,"starting LoadValues");
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

reset_round_stats(client)
{
	for (new i = 1; i < sizeof(g_round_stats[]); i++)
	{
		g_round_stats[client][i] = 0;
	}
	if (IsValidClient(client))
	{
		InsLog(DEBUG,"Running reset_round_stats for %N",client);
		g_round_stats[client][STAT_SCORE] = Ins_GetPlayerScore(client);
	}
	else
	{
		g_round_stats[client][STAT_SCORE] = 0;
	}
}
reset_round_stats_all()
{
	for (new i = 1; i < MaxClients; i++)
	{
		reset_round_stats(i);
	}
}
GetWeaponId(i)
{
	if (i < 0) {
		return -1;
	}
	new m_hWeaponDefinitionHandle = GetEntProp(i, Prop_Send, "m_hWeaponDefinitionHandle");
	new String:name[32];
	GetEdictClassname(i, name, sizeof(name));
	decl String:strBuf[32];
	GetArrayString(g_weap_array, m_hWeaponDefinitionHandle, strBuf, sizeof(strBuf));
	if(!StrEqual(name, strBuf)) {
		SetArrayString(g_weap_array, m_hWeaponDefinitionHandle, name);
		InsLog(DEBUG,"Weapon %s not in trie, added as index %d", name,m_hWeaponDefinitionHandle);
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

GetPlayerScore(client)
{
	GetPlayerManagerEnt();
	new retval = -1;
	if ((IsValidClient(client)) && (g_iPlayerManagerEntity > 0))
	{
		retval = GetEntData(g_iPlayerManagerEntity, FindSendPropInfo(g_iPlayerManagerEntityNetClass, "m_iPlayerScore") + (4 * client));
		InsLog(DEBUG,"Client %N m_iPlayerScore %d",client,retval);
	}
	return retval;
}
public Native_Log(Handle:plugin, numParams)
{
	new LOG_LEVEL:level = GetNativeCell(1);
	decl String:buffer[1024];
	FormatNativeString(0, 2, 3, sizeof(buffer), _,buffer);
	InsLog(level,buffer);
	return 0;
}

public Native_GetPlayerScore(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return GetPlayerScore(client);
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
bool:InCounterAttack()
{
	GetLogicEnt();
	new bool:retval;
	if (g_iLogicEntity > 0)
	{
		retval = bool:GetEntData(g_iLogicEntity, FindSendPropInfo(g_iLogicEntityNetClass, "m_bCounterAttack"));
	}
	return retval;
}
public Native_InCounterAttack(Handle:plugin, numParams)
{
	return InCounterAttack();
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

Weapon_GetMaxClip1(weapon) {
	StartPrepSDKCall(SDKCall_Entity);
	if(!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "GetMaxClip1")) {
		SetFailState("PrepSDKCall_SetFromConf GetMaxClip1 failed"); 
	}
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	new Handle:hCall = EndPrepSDKCall();
	new value = SDKCall(hCall, weapon);
	CloseHandle(hCall);
	return value;
}
Weapon_GetDefaultClip1(weapon) {
	StartPrepSDKCall(SDKCall_Entity);
	if(!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "GetDefaultClip1")) {
		SetFailState("PrepSDKCall_SetFromConf GetDefaultClip1 failed"); 
	}
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	new Handle:hCall = EndPrepSDKCall();
	new value = SDKCall(hCall, weapon);
	CloseHandle(hCall);
	return value;
}

public Native_Weapon_GetMaxClip1(Handle:plugin, numParams) {
	new weapon = GetNativeCell(1);
	return Weapon_GetMaxClip1(weapon);
}

public Native_Weapon_GetDefaultClip1(Handle:plugin, numParams) {
	new weapon = GetNativeCell(1);
	return Weapon_GetDefaultClip1(weapon);
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
		retval = GetEntData(g_iObjResEntity, FindSendPropInfo(g_iObjResEntityNetClass, prop) + (size * element));
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
		retval = Float:GetEntData(g_iObjResEntity, FindSendPropInfo(g_iObjResEntityNetClass, prop) + (size * element));
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
		retval = GetEntData(g_iObjResEntity, FindSendPropInfo(g_iObjResEntityNetClass, prop) + (4 * element));
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
		retval = bool:GetEntData(g_iObjResEntity, FindSendPropInfo(g_iObjResEntityNetClass, prop) + (element));
	}
	return _:retval;
}
public Native_ObjectiveResource_GetPropVector(Handle:plugin, numParams) {
	new len;
	GetNativeStringLength(1, len);
	if (len <= 0)
	{
	  return false;
	}
	new String:prop[len+1], retval=-1;
	GetNativeString(1, prop, len+1);
	new size = 12;
	new element = GetNativeCell(3);
	GetObjResEnt();
	new Float:result[3];
	if (g_iObjResEntity > 0)
	{
		retval = GetEntDataVector(g_iObjResEntity, FindSendPropInfo(g_iObjResEntityNetClass, prop) + (size * element), result);
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
		//GetEntData(g_iObjResEntity, FindSendPropInfo(g_iObjResEntityNetClass, prop) + (size * element));
	}
*/
	return retval;
}

public CheckInfiniteAmmo(client)
{
	if (GetConVarBool(cvarInfiniteAmmo))
	{
		new weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		new m_iPrimaryAmmoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
		new m_iClip1 = GetEntProp(weapon, Prop_Send, "m_iClip1"); // weapon clip amount bullets
		new m_iAmmo_prim = GetEntProp(client, Prop_Send, "m_iAmmo", _, m_iPrimaryAmmoType); // Player ammunition for this weapon ammo type
		new m_iPrimaryAmmoCount = -1;//GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoCount");
		InsLog(DEBUG,"weapon %d m_iPrimaryAmmoType %d m_iClip1 %d m_iAmmo_prim %d m_iPrimaryAmmoCount %d",weapon,m_iPrimaryAmmoType,m_iClip1,m_iAmmo_prim,m_iPrimaryAmmoCount);
		SetEntProp(client, Prop_Send, "m_iAmmo", 99, _, m_iPrimaryAmmoType); // Set player ammunition of this weapon primary ammo type

		//new ammo = GetEntProp(ActiveWeapon, Prop_Send, "m_iClip1", 1);
	}
	if (GetConVarBool(cvarInfiniteMagazine))
	{
		new ActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		new maxammo = Ins_GetMaxClip1(ActiveWeapon);
		SetEntProp(ActiveWeapon, Prop_Send, "m_iClip1", maxammo);
	}
}

//=====================================================================================================
// Disable sliding
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if ((GetConVarInt(cvarDisableSliding) == 1) || (GetClientTeam(client) == GetConVarInt(cvarDisableSliding)))
	{
		if (buttons & IN_ATTACK || buttons & IN_ATTACK2)
		{
			if (GetEntProp(client, Prop_Send, "m_bWasSliding") == 1)
				return Plugin_Handled;
		}	
	}	
	return Plugin_Continue;
}
public Action:Event_ControlPointCapturedPre(Handle:event, const String:name[], bool:dontBroadcast)
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
	decl String:cappers[256];
	//new priority = GetEventInt(event, "priority");
	GetEventString(event, "cappers", cappers, sizeof(cappers));
	new team = GetEventInt(event, "team");
	new capperlen = GetCharBytes(cappers);

	if ((InCounterAttack()) && (team == 3) && (!GetConVarBool(cvarCheckpointCounterattackCapture)))
	{
		InsLog(DEBUG,"Event_ControlPointCaptured: Want to block CounterAttack Capture!");
		//return Plugin_Stop;
	}
	new Float:ratio = (Float:capperlen / Float:Team_CountAlivePlayers(team));
	new Float:goalratio = GetConVarFloat(cvarCheckpointCapturePlayerRatio);
	//InsLog(DEBUG,"Event_ControlPointCaptured ratio %0.2f (%d of %d) goalratio %0.2f",ratio,capperlen,Team_CountAlivePlayers(team),goalratio);
	if (ratio < goalratio)
	{
		InsLog(DEBUG,"Event_ControlPointCaptured Blocking due to insufficient friendly players!");
		//return Plugin_Stop;
	}
	return Plugin_Continue;
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
	decl String:cappers[256],String:cpname[64];
	//new priority = GetEventInt(event, "priority");
	new cp = GetEventInt(event, "cp");
	GetEventString(event, "cappers", cappers, sizeof(cappers));
	GetEventString(event, "cpname", cpname, sizeof(cpname));
	new team = GetEventInt(event, "team");
	new capperlen = GetCharBytes(cappers);
	InsLog(DEBUG,"Event_ControlPointCaptured cp %d capperlen %d cpname %s team %d", cp,capperlen,cpname,team);
	//"cp" "byte" - for naming, currently not needed
	for (new i = 0; i < strlen(cappers); i++)
	{
		new client = cappers[i];
		//InsLog(DEBUG,"Event_ControlPointCaptured parsing capper id %d client %d",i,client);
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
	//InsLog(DEBUG,"Event_ControlPointNeutralized priority %d cp %d capperlen %d cpname %s team %d", priority,cp,capperlen,cpname,team);

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
public Action:Event_ControlPointStartTouchPre(Handle:event, const String:name[], bool:dontBroadcast)
{
	return Plugin_Continue;
}
public Action:Event_ControlPointStartTouch(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	new String:sGameMode[32];
	GetConVarString(FindConVar("mp_gamemode"), sGameMode, sizeof(sGameMode));
	if (!StrEqual(sGameMode,"checkpoint")) return Plugin_Continue;
	for (new i = 0; i < 16; i++)
	{
		new m_nSecurityCount = Ins_ObjectiveResource_GetProp("m_nSecurityCount",4,i);
		new m_nInsurgentCount = Ins_ObjectiveResource_GetProp("m_nInsurgentCount",4,i);
		if (m_nSecurityCount || m_nInsurgentCount)
		{
			//InsLog(DEBUG,"Area %d m_nSecurityCount %d m_nInsurgentCount %d",i,m_nSecurityCount,m_nInsurgentCount);
		}
	}
/*
	new area = GetEventInt(event, "area");
	new m_iObject = GetEventInt(event, "object");
	new player = GetEventInt(event, "player");
	new team = GetEventInt(event, "team");
	new owner = GetEventInt(event, "owner");
	new type = GetEventInt(event, "type");
	new Float:m_flCaptureTime = Ins_ObjectiveResource_GetPropFloat("m_flCaptureTime",4,area);
	new Float:m_flDeteriorateTime = Ins_ObjectiveResource_GetPropFloat("m_flDeteriorateTime",4,area);
	new Float:m_flLazyCapPerc = Ins_ObjectiveResource_GetPropFloat("m_flLazyCapPerc",4,area);
	new m_nTeamBlocking = Ins_ObjectiveResource_GetProp("m_nTeamBlocking",4,area);
	new Float:m_flCapPercentages = 0.0;//Ins_ObjectiveResource_GetPropFloat("m_flCapPercentages",4,area);
	new bool:m_bSecurityLocked = Ins_ObjectiveResource_GetPropBool("m_bSecurityLocked",area);
	new bool:m_bInsurgentsLocked = Ins_ObjectiveResource_GetPropBool("m_bInsurgentsLocked",area);
	new m_nSecurityCount = Ins_ObjectiveResource_GetProp("m_nSecurityCount",4,area);
	new m_nInsurgentCount = Ins_ObjectiveResource_GetProp("m_nInsurgentCount",4,area);
	new m_nActivePushPointIndex = Ins_ObjectiveResource_GetProp("m_nActivePushPointIndex");
	InsLog(DEBUG,"Event_ControlPointStartTouch: player %N area %d m_nActivePushPointIndex %d m_nSecurityCount %d m_nInsurgentCount %d m_flCaptureTime %f m_flDeteriorateTime %f m_flLazyCapPerc %f m_nTeamBlocking %d m_flCapPercentages %f m_bSecurityLocked %b m_bInsurgentsLocked %b object %d player %d team %d owner %d type %d", player, area, m_nActivePushPointIndex, m_nSecurityCount, m_nInsurgentCount, m_flCaptureTime, m_flDeteriorateTime, m_flLazyCapPerc, m_nTeamBlocking, m_flCapPercentages, m_bSecurityLocked, m_bInsurgentsLocked, m_iObject, player, team, owner, type);
*/
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

	//InsLog(DEBUG,"Event_ControlPointEndTouch: player %N area %d player %d team %d owner %d",player,area,player,team,owner);
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
	InsLog(DEBUG,"Event_ObjectDestroyed: team %d attacker %d attacker_userid %d cp %d classname %s index %d type %d weaponid %d assister %d assister_userid %d attackerteam %d",team,attacker,attacker_userid,cp,classname,index,type,weaponid,assister,assister_userid,attackerteam);
	return Plugin_Continue;
}
public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
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
	//InsLog(DEBUG,"WeaponIndex: %d - %s", weapon_index, shotWeapName);
	
	if (weapon_index > -1)
	{
		g_weapon_stats[client][weapon_index][LOG_HIT_SHOTS]++;
		g_round_stats[client][STAT_SHOTS]++;
		g_client_last_weapon[client] = weapon_index;
		g_client_last_weaponstring[client] = shotWeapName;
	}
	CheckInfiniteAmmo(client);
	return Plugin_Continue;
}
public Action:Event_WeaponFireMode(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//new weaponid = GetEventInt(event, "weaponid");
	//new firemode = GetEventInt(event, "firemode");
	return Plugin_Continue;
}
public Action:Event_EnterSpawnZone(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));
	return Plugin_Continue;
}
public Action:Event_ExitSpawnZone(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	//new client = GetClientOfUserId(GetEventInt(event, "userid"));
	return Plugin_Continue;
}
public Action:Event_WeaponReload(Handle:event, const String:name[], bool:dontBroadcast)
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
	//InsLog(DEBUG,"WeaponIndex: %d - %s", weapon_index, shotWeapName);
	
	if (weapon_index > -1)
	{
		g_weapon_stats[client][weapon_index][LOG_HIT_SHOTS]++;
		g_round_stats[client][STAT_SHOTS]++;
		g_client_last_weapon[client] = weapon_index;
		g_client_last_weaponstring[client] = shotWeapName;
	}
	CheckInfiniteAmmo(client);
	return Plugin_Continue;
}
public Action:Event_WeaponDeploy(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userId = GetEventInt(event, "userid");
	if (userId > 0)
	{
		new user = GetClientOfUserId(userId);
		if (user)
		{
			CheckInfiniteAmmo(user);
		}
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
	int victim_team = GetClientTeam(victim);
	int attacker_team = GetClientTeam(attacker);
	// If attacker or victim is invalid, attacker is victim, or same team, do not reward
	if (attacker <= 0 || victim <= 0 || attacker == victim || victim_team == attacker_team)
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
public Action:Event_GameEndPre( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"team2_score" "short"
	//"winner" "byte"
	//"team1_score" "short"
	//new winner = GetEventInt( event, "winner");
	//new team1_score = GetEventInt( event, "team1_score");
	//new team2_score = GetEventInt( event, "team2_score");
	//LogToGame("World triggered \"Game_End\" (winner \"%d\") (team1_score \"%d\") (team2_score \"%d\")", winner,team1_score,team2_score);
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
	reset_round_stats_all();
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
	//InsLog(DEBUG,"from event (weaponid: %d weapon: %s) from last (g_client_hurt_weaponstring: %s weapon_index: %d strLastWeapon: %s)", weaponid, weapon, g_client_hurt_weaponstring[victim], weapon_index, strLastWeapon);
	
	if (attacker == 0 || victim == 0 || attacker == victim)
	{
		return Plugin_Continue;
	}	
	g_weapon_stats[attacker][weapon_index][LOG_HIT_KILLS]++;
	g_weapon_stats[victim][weapon_index][LOG_HIT_DEATHS]++;
	g_round_stats[attacker][STAT_KILLS]++;
	g_round_stats[victim][STAT_DEATHS]++;
	if (GetClientTeam(attacker) == GetClientTeam(victim)) {
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
	//InsLog(DEBUG,"PlayerHurt attacher %d victim %d weapon %s ghws: %s", attacker, victim, weapon,g_client_hurt_weaponstring[victim]);
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
			InsLog(DEBUG,"Regex Pattern Failure!");
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
			InsLog(DEBUG,"Regex Pattern Failure");
		}
	}
	else if(StrContains(message, "obj_captured") > -1) return Plugin_Handled;
	else if(StrContains(message, "obj_destroyed") > -1) return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action:Event_RoundEndPre( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"reason" "byte"
	//"winner" "byte"
	//"message" "string"
	//"message_string" "string"
	decl String:message[255];
	GetEventString(event, "message",message,sizeof(message));
	if (StrEqual(message,"#game_team_winner_obj_checkpoint_regain"))
	{
		if (!GetConVarBool(cvarCheckpointCounterattackCapture))
		{
			InsLog(DEBUG,"Event_RoundEnd: Blocking due to checkpoint recapture disabled!");
			//return Plugin_Stop;
		}
	}
// jballou 10MAR2016 - Disabling until I can fix these. Will likely break out into a new plugin.
//	DoRoundAwards();
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
	WstatsDumpAll();
	GetObjResEnt();
	return Plugin_Continue;
}

// This adds the player class name (without some bits we don't want) to the list
// TODO: Handle the "unwanted" bits better, perhaps read strings from theater/game translations?
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
	decl String:sClassName[MAX_CLASS_LEN];
	GetEventString(event, "class_template",class_template,sizeof(class_template));
	FormatPlayerClassName(sClassName,sizeof(sClassName),class_template);
	UpdateClassName(team,squad,squad_slot,sClassName);

	if( client == 0)
		return Plugin_Continue;
	if(!StrEqual(g_client_last_classstring[client],sClassName)) {
		LogRoleChange( client, sClassName );
		g_client_last_classstring[client] = sClassName;
	}
	return Plugin_Continue;
}
FormatPlayerClassName(String:sClassName[],iSize,const String:class_template[]) {
	// Check player class
	new String:sTmp[256],String:sReplace[MAX_STRIP_LEN+1];
	new String:sStripWords[MAX_STRIP_COUNT][MAX_STRIP_LEN];
	Format(sClassName,iSize,"%s",class_template);
	GetConVarString(cvarClassStripWords, sTmp, sizeof(sTmp));
	ExplodeString(sTmp, " ", sStripWords, MAX_STRIP_COUNT, MAX_STRIP_LEN);
	for (new i=0;i<MAX_STRIP_COUNT;i++) {
		if (StrEqual(sStripWords[i],"") || StrEqual(sStripWords[i],"\0")) {
		} else {
			Format(sReplace,sizeof(sReplace),"_%s",sStripWords[i]);
			ReplaceString(sClassName,iSize,sReplace,"",false);
			Format(sReplace,sizeof(sReplace),"%s_",sStripWords[i]);
			ReplaceString(sClassName,iSize,sReplace,"",false);
		}
	}
}
