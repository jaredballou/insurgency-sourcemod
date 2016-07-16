/**
 * vim: set ts=4 :
 * =============================================================================
 * AFK Manager
 * Handles AFK Players
 *
 * SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 */

#pragma semicolon							1
#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#tryinclude <colors>
#if !defined _colors_included
	#if SOURCEMOD_V_MAJOR == 1
		#if SOURCEMOD_V_MINOR >= 5
			#tryinclude <morecolors>
		#endif
	#elseif SOURCEMOD_V_MAJOR > 1
		#tryinclude <morecolors>
	#endif
#endif
#tryinclude <autoupdate>
#tryinclude <updater>
#define REQUIRE_PLUGIN

// Arena Check Code from controlpoints.inc made by Powerlord

// These correspond to tf_gamerules m_nGameType netprop
enum
{
	TF2_GameType_Unknown,
	TF2_GameType_CTF = 1,
	TF2_GameType_CP = 2,
	TF2_GameType_PL = 3,
	TF2_GameType_Arena = 4,
}

enum TF2_GameMode
{
	TF2_GameMode_Unknown,
	TF2_GameMode_CTF,
	TF2_GameMode_5CP,
	TF2_GameMode_PL,
	TF2_GameMode_Arena,
	TF2_GameMode_ADCP,
	TF2_GameMode_TC,
	TF2_GameMode_PLR,
	TF2_GameMode_KOTH,
	TF2_GameMode_SD,
	TF2_GameMode_MvM,
	TF2_GameMode_Training,
	TF2_GameMode_ItemTest,
}

stock TF2_GameMode:TF2_DetectGameMode()
{
	
	// Netprops didn't help, lets check the game type
	new gameType = GameRules_GetProp("m_nGameType");
	
	switch (gameType)
	{
		case TF2_GameType_Arena:
		{
			return TF2_GameMode_Arena;
		}
	}
	return TF2_GameMode_Unknown;
}

#if SOURCEMOD_V_MAJOR == 1
	#if SOURCEMOD_V_MINOR >= 5
		#define NEW_ENGINE_DETECTION
	#endif
#elseif SOURCEMOD_V_MAJOR > 1
	#define NEW_ENGINE_DETECTION
#endif

#if defined _updater_included
#define UPDATE_URL							"http://afkmanager.dawgclan.net/updatefile.txt"
#endif

// To Do?
// Sound
// AFK Menu
// Chat/Notification Options
// Fix AFK in Class Menu (State 3?)
// Check both Eye Angles and Location
// Fix Spectator Mode (Random Spec)
// Fix Long AFK Timer over new rounds?
// Check Spectator Mode when Unassigned
// Add Notification Flexibility Options, Client Only, All etc


#define AFKM_VERSION						"3.5.3"

#define AFK_CHECK_INTERVAL					5.0

// Change this to enable debug
// 0 = No Logging
// 1 = Minimal Logging
// 2 = Maximum Logging
#define _DEBUG 								0 // set to 1 to enable debug or 3 to enable full debug
#define _DEBUG_MODE							3 // 1 = Log to File, 2 = Log to Game Logs, 3 Print to Chat


// SHOULD NOT NEED TO EDIT BELOW THIS LINE
// Event Defines
#define EVENT_PLAYER_TEAM					0
#define EVENT_PLAYER_SPAWN					1
#define EVENT_PLAYER_DEATH					2
#define EVENT_TEAMPLAY_ROUND_START			3
#define EVENT_ARENA_ROUND_START				4
#define EVENT_ROUND_STALEMATE				5

// Event Array
new bool:bEventIsHooked[6] =				{ false, ...};

// ConVar Defines
#define CONVAR_VERSION						0
#define CONVAR_ENABLED						1
#define CONVAR_WARNINGS						2
#define CONVAR_EXCLUDEBOTS					3
#define CONVAR_MOD_AFK						4
#define CONVAR_TF2_ARENAMODE				5

#if !defined MAX_MESSAGE_LENGTH
	#define MAX_MESSAGE_LENGTH				250
#endif

// ConVar Array
new bool:bCvarIsHooked[6] =					{ false, ...};


// Global Variables
// Log File Array
new String:AFKM_LogFile[PLATFORM_MAX_PATH];

new Float:fAFKTime[MAXPLAYERS+1] =			{0.0, ...};

new Float:fEyePosition[MAXPLAYERS+1][3]; // X = Vertical, Y = Height, Z = Horizontal
new Float:fMapPosition[MAXPLAYERS+1][3];
new Float:fSpawnPosition[MAXPLAYERS+1][3];

new bool:bAFKSpawn[MAXPLAYERS+1] =			{false, ...};

new iSpecMode[MAXPLAYERS+1] =				{0, ...};
new iSpecTarget[MAXPLAYERS+1] =				{0, ...};

new iPlayerTeam[MAXPLAYERS+1] =				{-1, ...};
new iTeamPlayers[MAXPLAYERS+1] =			{0, ...};

new bool:bJoinedTeam[MAXPLAYERS+1] =		{false, ...};

// Variables
new bool:bLogWarnings =						false;
new bool:bExcludeBots = 					false;

new iNumPlayers =							0;

new g_TF2_WFP_StartTime =					0;

new g_Spec_FL_Mode =						0;
new g_sTeam_Index =							1;

new bool:bTF2Arena =						false;
new bool:bWaitRound =						false;

new bool:bMovePlayers =						true;
new bool:bKickPlayers =						true;


// Handles
// AFK Manager Console Variables
new Handle:hCvarVersion =					INVALID_HANDLE;
new Handle:hCvarEnabled =					INVALID_HANDLE;
new Handle:hCvarAutoUpdate =				INVALID_HANDLE;
new Handle:hCvarPrefixShort =				INVALID_HANDLE;
#if defined _colors_included
new Handle:hCvarPrefixColor =				INVALID_HANDLE;
#endif
new Handle:hCvarLanguage =					INVALID_HANDLE;
new Handle:hCvarLogWarnings =				INVALID_HANDLE;
new Handle:hCvarLogMoves =					INVALID_HANDLE;
new Handle:hCvarLogKicks =					INVALID_HANDLE;
new Handle:hCvarLogDays =					INVALID_HANDLE;
new Handle:hCvarMinPlayersMove =			INVALID_HANDLE;
new Handle:hCvarMinPlayersKick =			INVALID_HANDLE;
new Handle:hCvarAdminsImmune =				INVALID_HANDLE;
new Handle:hCvarAdminsFlag =				INVALID_HANDLE;
new Handle:hCvarMoveSpec =					INVALID_HANDLE;
new Handle:hCvarSpecCheckTarget =			INVALID_HANDLE;
new Handle:hCvarTimeToMove =				INVALID_HANDLE;
new Handle:hCvarWarnTimeToMove =			INVALID_HANDLE;
new Handle:hCvarKickPlayers =				INVALID_HANDLE;
new Handle:hCvarTimeToKick =				INVALID_HANDLE;
new Handle:hCvarWarnTimeToKick =			INVALID_HANDLE;
new Handle:hCvarSpawnTime =					INVALID_HANDLE;
new Handle:hCvarWarnSpawnTime =				INVALID_HANDLE;
new Handle:hCvarExcludeBots =				INVALID_HANDLE;
new Handle:hCvarExcludeDead =				INVALID_HANDLE;
new Handle:hCvarLocationThreshold =			INVALID_HANDLE;
new Handle:hCvarWarnUnassigned =			INVALID_HANDLE;

// AFK Manager Timer Array
new Handle:hAFKTimers[MAXPLAYERS+1] =		{INVALID_HANDLE, ...};

// AFK Manager Menu Array
//new Handle:hAFKMenu[MAXPLAYERS+1] =			{INVALID_HANDLE, ...};

// Mod Based Console Variables
new Handle:hCvarAFK =						INVALID_HANDLE;
new Handle:hCvarTF2Arena =					INVALID_HANDLE;
new Handle:hCvarTF2WFPTime =				INVALID_HANDLE;


// Mod Detection Variables
new bool:Synergy =							false;
new bool:TF2 =								false;
new bool:CSTRIKE =							false;
//new bool:L4D =								false;


// General Defines
#define MOVE								0
#define KICK								1

#define TF2_TEAM_RED						2
#define TF2_TEAM_BLUE						3



// Plugin Information
public Plugin:myinfo =
{
    name = "AFK Manager",
    author = "Rothgar",
    description = "Handles AFK Players",
    version = AFKM_VERSION,
    url = "http://www.dawgclan.net"
};

// Log Functions
// Build Log File System Path & Call Log Purge
BuildLogFilePath()
{
	// Check if SourceMod Log Folder Exists Otherwise Create One
	new String:sLogPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sLogPath, sizeof(sLogPath), "logs");

	if ( !DirExists(sLogPath) )
	{
		CreateDirectory(sLogPath, 511);
	}

	decl String:cTime[64];
	FormatTime(cTime, sizeof(cTime), "logs/afkm_%Y%m%d.log");

	new String:sLogFile[PLATFORM_MAX_PATH];
	sLogFile = AFKM_LogFile;

	BuildPath(Path_SM, AFKM_LogFile, sizeof(AFKM_LogFile), cTime);

#if _DEBUG
	LogDebug(false, "BuildLogFilePath - AFK Log Path: %s", AFKM_LogFile);
#endif

	if (!StrEqual(AFKM_LogFile, sLogFile))
	{
		LogAction(0, -1, "[AFK Manager] Log File: %s", AFKM_LogFile);

#if _DEBUG
		LogDebug(false, "BuildLogFilePath - Log file has been rotated");
#endif
		if (hCvarLogDays != INVALID_HANDLE)
		{
			if (GetConVarInt(hCvarLogDays) > 0)
			{
#if _DEBUG
				LogDebug(false, "BuildLogFilePath - Purging Old Log Files");
#endif
				PurgeOldLogs();
			}
		}
	}
}

// Purge Old Log Files
PurgeOldLogs()
{
#if _DEBUG
	LogDebug(false, "PurgeOldLogs - Purging Old Log Files");
#endif
	new String:sLogPath[PLATFORM_MAX_PATH];
	new String:buffer[256];
	new Handle:hDirectory = INVALID_HANDLE;
	new FileType:type = FileType_Unknown;

	BuildPath(Path_SM, sLogPath, sizeof(sLogPath), "logs");

#if _DEBUG
	LogDebug(false, "PurgeOldLogs - Purging Old Log Files from: %s", sLogPath);
#endif
	if ( DirExists(sLogPath) )
	{
		hDirectory = OpenDirectory(sLogPath);
		if (hDirectory != INVALID_HANDLE)
		{
			while ( ReadDirEntry(hDirectory, buffer, sizeof(buffer), type) )
			{
				if (type == FileType_File)
				{
					if (StrContains(buffer, "afkm_", false) != -1)
					{
						decl String:file[PLATFORM_MAX_PATH];
						Format(file, sizeof(file), "%s/%s", sLogPath, buffer);
#if _DEBUG
						LogDebug(false, "PurgeOldLogs - Checking file: %s", buffer);
#endif
						if ( GetFileTime(file, FileTime_LastChange) < (GetTime() - (60 * 60 * 24 * GetConVarInt(hCvarLogDays)) + 30) )
						{
							// Log file is old
#if _DEBUG
							LogDebug(false, "PurgeOldLogs - Log File Should be Deleted: %s", buffer);
#endif
							if (DeleteFile(file))
							{
								LogAction(0, -1, "[AFK Manager] Deleted Old Log File: %s", file);
							}
						}
					}
				}
			}
		}
	}

	if (hDirectory != INVALID_HANDLE)
	{
		CloseHandle(hDirectory);
		hDirectory = INVALID_HANDLE;
	}
}


AFK_PrintToChat(client, const String:szMessage[], any:...)
{
	decl String:szBuffer[MAX_MESSAGE_LENGTH];
	VFormat(szBuffer, sizeof(szBuffer), szMessage, 3);
#if defined _colors_included
	if (GetConVarBool(hCvarPrefixShort))
	{
		if (GetConVarBool(hCvarPrefixColor))
			CPrintToChat(client, "{olive}[{green}AFK{olive}] {default}%s", szBuffer);
		else
			PrintToChat(client, "[AFK] %s", szBuffer);
	}
	else
	{
		if (GetConVarBool(hCvarPrefixColor))
			CPrintToChat(client, "{olive}[{green}AFK Manager{olive}] {default}%s", szBuffer);
		else
			PrintToChat(client, "[AFK Manager] %s", szBuffer);
	}
#else
	if (GetConVarBool(hCvarPrefixShort))
	{
		PrintToChat(client, "[AFK] %s", szBuffer);
	}
	else
	{
		PrintToChat(client, "[AFK Manager] %s", szBuffer);
	}
#endif
}

AFK_PrintToChatAll(const String:szMessage[], any:...)
{
	decl String:szBuffer[MAX_MESSAGE_LENGTH];
	VFormat(szBuffer, sizeof(szBuffer), szMessage, 2);
#if defined _colors_included
	if (GetConVarBool(hCvarPrefixShort))
	{
		if (GetConVarBool(hCvarPrefixColor))
			CPrintToChatAll("{olive}[{green}AFK{olive}] {default}%s", szBuffer);
		else
			PrintToChatAll("[AFK] %s", szBuffer);
	}
	else
	{
		if (GetConVarBool(hCvarPrefixColor))
			CPrintToChatAll("{olive}[{green}AFK Manager{olive}] {default}%s", szBuffer);
		else
			PrintToChatAll("[AFK Manager] %s", szBuffer);
	}
#else
	if (GetConVarBool(hCvarPrefixShort))
	{
		PrintToChatAll("[AFK] %s", szBuffer);
	}
	else
	{
		PrintToChatAll("[AFK Manager] %s", szBuffer);
	}
#endif
}

// Debug Functions
// Debug Log Function
#if _DEBUG
LogDebug(bool:Translation, String:text[], any:...)
{
	new String:message[255];
	if (Translation)
		VFormat(message, sizeof(message), "%T", 2);
	else
		if (strlen(text) > 0)
			VFormat(message, sizeof(message), text, 3);
		else
			return;

#if _DEBUG_MODE == 1
	LogToFile(AFKM_LogFile, "%s", message);
#elseif _DEBUG_MODE == 2
	LogToGame("[AFK Manager] %s", message);
#elseif _DEBUG_MODE == 3
	PrintToChatAll("[AFK Manager] %s", message);
#endif
}
#endif


// Custom Functions
// Check If A Client ID Is Valid
stock bool:IsValidClient(client, bool:nobots = true)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
    {
#if _DEBUG > 2
		LogDebug(false, "IsValidClient - Client: %i is invalid? Connected: %b FakeClient: %b", client, IsClientConnected(client), (nobots && IsFakeClient(client)));
#endif
        return false; 
    }
#if _DEBUG > 2
		LogDebug(false, "IsValidClient - Client: %i should be valid", client);
#endif
    return IsClientInGame(client); 
}

AFK_GetClientCount(bool:ExcludeBots, bool:inGameOnly = true)
{
#if _DEBUG > 1
		LogDebug(false, "AFK_GetClientCount - ExcludeBots: %i InGameOnly: %i", ExcludeBots, inGameOnly);
#endif
	new clients = 0;
	if (!ExcludeBots) {
		clients = GetClientCount(inGameOnly);
	}
	else {
		for (new i = 1; i <= GetMaxClients(); i++) {	
			if( ( ( inGameOnly ) ? IsClientInGame( i ) : IsClientConnected( i ) ) && !IsFakeClient( i ) ) {
				clients++;
			}
		}
	}
	return clients;
}

bool:CheckPlayerCount(type)
{
	decl MinPlayers;
	new bool:EnableMode = false;
	new String:strType[8] = "";

	switch (type)
	{
		case MOVE:
		{
			MinPlayers = GetConVarInt(hCvarMinPlayersMove);
			EnableMode = bMovePlayers;
			strType = "move";
		}
		case KICK:
		{
			MinPlayers = GetConVarInt(hCvarMinPlayersKick);
			EnableMode = bKickPlayers;
			strType = "kick";
		}
	}

#if _DEBUG > 1
		LogDebug(false, "CheckPlayerCount - Minimum player count for AFK %s is: %i Current Players: %i", strType, MinPlayers, iNumPlayers);
#endif

	if (iNumPlayers >= MinPlayers)
	{
		// Minimum player count required to enable AFK features has been reached.
		if (!EnableMode)
		{
#if _DEBUG > 1
			LogDebug(false, "CheckPlayerCount - Minimum player count for AFK %s is reached, feature is now enabled: sm_afk_%s_min_players = %i Current Players = %i", strType, strType, MinPlayers, iNumPlayers);
#endif
			if (bLogWarnings)
			{
				LogToFile(AFKM_LogFile, "Minimum player count for AFK %s is reached, feature is now enabled: sm_afk_%s_min_players = %i Current Players = %i", strType, strType, MinPlayers, iNumPlayers);
			}
		}
		EnableMode = true;
	}
	else
	{
		// Not enough players to enable AFK features.
		if (EnableMode)
		{
#if _DEBUG > 1
			LogDebug(false, "CheckPlayerCount - Minimum player count for AFK %s has not been reached, feature is now disabled: sm_afk_%s_min_players = %i Current Players = %i", strType, strType, MinPlayers, iNumPlayers);
#endif
			if (bLogWarnings)
			{
				LogToFile(AFKM_LogFile, "Minimum player count for AFK %s has not been reached, feature is now disabled: sm_afk_%s_min_players = %i Current Players = %i", strType, strType, MinPlayers, iNumPlayers);
			}
		}
		EnableMode = false;
	}

	return EnableMode;
}




// Main SourceMod Functions
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
#if defined _colors_included
    MarkNativeAsOptional("GetUserMessageType");
#endif
	MarkNativeAsOptional("GetEngineVersion");
	return APLRes_Success;
}


public OnPluginStart()
{
	BuildLogFilePath();

#if _DEBUG
	LogDebug(false, "AFK Plugin Started!");
#endif

	LoadTranslations("common.phrases");
	LoadTranslations("afk_manager.phrases");

	// Engine Detection
#if defined NEW_ENGINE_DETECTION
	if ( CanTestFeatures() && (GetFeatureStatus(FeatureType_Native, "GetEngineVersion") == FeatureStatus_Available) )
	{
		new EngineVersion:g_EngineVersion = Engine_Unknown;

		g_EngineVersion = GetEngineVersion();

		switch (g_EngineVersion)
		{
			/**< Could not determine the engine version */
			case Engine_Unknown:
				g_Spec_FL_Mode = 6;
			/**< Original Source Engine (used by The Ship) */
			case Engine_Original:
				g_Spec_FL_Mode = 5;
			/**< Episode 1 Source Engine (second major SDK) */
			case Engine_SourceSDK2006:
				g_Spec_FL_Mode = 5;
			/**< Orange Box Source Engine (third major SDK) */
			case Engine_SourceSDK2007:
				g_Spec_FL_Mode = 6;
			/**< Left 4 Dead */
			case Engine_Left4Dead:
				g_Spec_FL_Mode = 6;
			/**< Dark Messiah Multiplayer (based on original engine) */
			case Engine_DarkMessiah:
				g_Spec_FL_Mode = 5;
			/**< Left 4 Dead 2 */
			case Engine_Left4Dead2:
				g_Spec_FL_Mode = 6;
			/**< Alien Swarm (and Alien Swarm SDK) */
			case Engine_AlienSwarm:
				g_Spec_FL_Mode = 6;
			/**< Bloody Good Time */
			case Engine_BloodyGoodTime:
				g_Spec_FL_Mode = 6;
			/**< E.Y.E Divine Cybermancy */
			case Engine_EYE:
				g_Spec_FL_Mode = 6;
			/**< Portal 2 */
			case Engine_Portal2:
				g_Spec_FL_Mode = 6;
			/**< Counter-Strike: Global Offensive */
			case Engine_CSGO:
				g_Spec_FL_Mode = 6;
			/**< Counter-Strike: Source */
			case Engine_CSS:
				g_Spec_FL_Mode = 6;
			/**< Dota 2 */
			case Engine_DOTA:
				g_Spec_FL_Mode = 6;
			/**< Half-Life 2 Deathmatch */
			case Engine_HL2DM:
				g_Spec_FL_Mode = 6;
			/**< Day of Defeat: Source */
			case Engine_DODS:
				g_Spec_FL_Mode = 6;
			/**< Team Fortress 2 */
			case Engine_TF2:
				g_Spec_FL_Mode = 6;
			/**< Nuclear Dawn */
			case Engine_NuclearDawn:
				g_Spec_FL_Mode = 6;
			default:
			{
				g_Spec_FL_Mode = 6;
			}
		}
	}
#else
	new SDKEngine =	SOURCE_SDK_UNKNOWN;

	SDKEngine = GuessSDKVersion();

	if (SDKEngine > SOURCE_SDK_EPISODE2VALVE)
	{
		// Left 4 Dead
		g_Spec_FL_Mode = 6;
	}
	else if (SDKEngine > SOURCE_SDK_EPISODE1)
	{
		// OrangeBox
		g_Spec_FL_Mode = 6;
	}
	else
	{
		// Source/Other
		g_Spec_FL_Mode = 5;
	}
#endif


	// Check Game Mod
	new String:game_mod[32];
	GetGameFolderName(game_mod, sizeof(game_mod));

	if (strcmp(game_mod, "synergy", false) == 0)
	{
		LogAction(0, -1, "[AFK Manager] %T", "Synergy", LANG_SERVER);
		Synergy = true;
	}
	else if (strcmp(game_mod, "tf", false) == 0)
	{
		LogAction(0, -1, "[AFK Manager] %T", "TF2", LANG_SERVER);
		TF2 = true;

		// Hook AFK Convar
		hCvarAFK = FindConVar("mp_idledealmethod");
		hCvarTF2Arena = FindConVar("tf_gamemode_arena");
		hCvarTF2WFPTime = FindConVar("mp_waitingforplayers_time");
	}
	else if ( (strcmp(game_mod, "cstrike", false) == 0) || (strcmp(game_mod, "csgo", false) == 0) )
	{
		LogAction(0, -1, "[AFK Manager] %T", "CSTRIKE", LANG_SERVER);
		CSTRIKE = true;

		// Hook AFK Convar
		hCvarAFK = FindConVar("mp_autokick");
	}
/*
	else if (strcmp(game_mod, "left4dead", false) == 0)
	{
		LogAction(0, -1, "[AFK Manager] %T", "L4D", LANG_SERVER);
		L4D = true;
	}
*/


	// Register Cvars
	RegisterCvars();
	SetConVarInt(hCvarLogWarnings, 0);
	SetConVarInt(hCvarEnabled, 0);

	// Register Hooks
	RegisterHooks();

	AutoExecConfig(true, "afk_manager");

	// Register Commands
	RegisterCmds();

	// Purge Old Log Files
	if (hCvarLogDays != INVALID_HANDLE)
	{
		if (GetConVarInt(hCvarLogDays) > 0)
		{
			PurgeOldLogs();
		}
	}
}

public OnAllPluginsLoaded() {
#if defined _updater_included
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
#elseif defined _autoupdate_included
	if (LibraryExists("pluginautoupdate"))
	{
		AutoUpdate_AddPlugin("afkmanager.dawgclan.net", "/update.xml", AFKM_VERSION);
	}
#endif
}

public OnLibraryAdded(const String:name[])
{
#if defined _updater_included
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
#endif
}

public OnPluginEnd() {
#if defined _autoupdate_included
	if (LibraryExists("pluginautoupdate"))
	{
		AutoUpdate_RemovePlugin();
	}
#endif
}


// Auto Update Functions
#if defined _updater_included
public Action:Updater_OnPluginChecking()
{
	if (!GetConVarBool(hCvarAutoUpdate))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Updater_OnPluginUpdated()
{
	LogToFile(AFKM_LogFile, "AFK Manager has just been updated to a new version");
	ReloadPlugin();
}
#endif


// Cvar Registrations
RegisterCvars()
{
#if _DEBUG
	LogDebug(false, "Running RegisterCvars()");
#endif
	hCvarVersion = CreateConVar("sm_afkm_version", AFKM_VERSION, "Current version of the AFK Manager",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	SetConVarString(hCvarVersion, AFKM_VERSION);
	hCvarEnabled = CreateConVar("sm_afk_enable", "1", "Is the AFK Manager enabled or disabled? [0 = FALSE, 1 = TRUE, DEFAULT: 1]", 0, true, 0.0, true, 1.0);
	hCvarAutoUpdate = CreateConVar("sm_afk_autoupdate", "1", "Is the AFK Manager automatic plugin update enabled or disabled? (Requires SourceMod Autoupdate plugin) [0 = FALSE, 1 = TRUE]", 0, true, 0.0, true, 1.0);
	hCvarPrefixShort = CreateConVar("sm_afk_prefix_short", "0", "Should the AFK Manager use a short prefix? [0 = FALSE, 1 = TRUE, DEFAULT: 0]", 0, true, 0.0, true, 1.0);
#if defined _colors_included
	hCvarPrefixColor = CreateConVar("sm_afk_prefix_color", "1", "Should the AFK Manager use color for the prefix tag? [0 = DISABLED, 1 = ENABLED, DEFAULT: 1]", 0, true, 0.0, true, 1.0);
#endif
	hCvarLanguage = CreateConVar("sm_afk_force_language", "0", "Should the AFK Manager force all message language to the server default? [0 = DISABLED, 1 = ENABLED, DEFAULT: 0]", 0, true, 0.0, true, 1.0);
	hCvarLogWarnings = CreateConVar("sm_afk_log_warnings", "1", "Should the AFK Manager log plugin warning messages. [0 = FALSE, 1 = TRUE, DEFAULT: 1]", 0, true, 0.0, true, 1.0);
	hCvarLogMoves = CreateConVar("sm_afk_log_moves", "1", "Should the AFK Manager log client moves. [0 = FALSE, 1 = TRUE, DEFAULT: 1]", 0, true, 0.0, true, 1.0);
	hCvarLogKicks = CreateConVar("sm_afk_log_kicks", "1", "Should the AFK Manager log client kicks. [0 = FALSE, 1 = TRUE, DEFAULT: 1]", 0, true, 0.0, true, 1.0);
	hCvarLogDays = CreateConVar("sm_afk_log_days", "0", "How many days should we keep AFK Manager log files. [0 = INFINITE, DEFAULT: 0]");
	hCvarMinPlayersMove = CreateConVar("sm_afk_move_min_players", "2", "Minimum number of connected clients required for AFK move to be enabled. [DEFAULT: 4]");
	hCvarMinPlayersKick = CreateConVar("sm_afk_kick_min_players", "3", "Minimum number of connected clients required for AFK kick to be enabled. [DEFAULT: 6]");
	hCvarAdminsImmune = CreateConVar("sm_afk_admins_immune", "1", "Should admins be immune to the AFK Manager? [0 = DISABLED, 1 = COMPLETE IMMUNITY, 2 = KICK IMMUNITY, 3 = MOVE IMMUNITY]");
	hCvarAdminsFlag = CreateConVar("sm_afk_admins_flag", "", "Admin Flag for immunity? Leave Blank for any flag.");
	hCvarMoveSpec = CreateConVar("sm_afk_move_spec", "1", "Should the AFK Manager move AFK clients to spectator team? [0 = FALSE, 1 = TRUE, DEFAULT: 1]", 0, true, 0.0, true, 1.0);
	hCvarTimeToMove = CreateConVar("sm_afk_move_time", "120.0", "Time in seconds (total) client must be AFK before being moved to spectator. [0 = DISABLED, DEFAULT: 60.0 seconds]");
	hCvarWarnTimeToMove = CreateConVar("sm_afk_move_warn_time", "60.0", "Time in seconds remaining, player should be warned before being moved for AFK. [DEFAULT: 30.0 seconds]");
	hCvarSpecCheckTarget = CreateConVar("sm_afk_spec_check_target", "1", "Should the AFK Manager check spectator target changes? [0 = FALSE, 1 = TRUE, DEFAULT: 1]", 0, true, 0.0, true, 1.0);
	hCvarKickPlayers = CreateConVar("sm_afk_kick_players", "1", "Should the AFK Manager kick AFK clients? [0 = DISABLED, 1 = KICK ALL, 2 = ALL EXCEPT SPECTATORS, 3 = SPECTATORS ONLY]");
	hCvarTimeToKick = CreateConVar("sm_afk_kick_time", "300.0", "Time in seconds (total) client must be AFK before being kicked. [0 = DISABLED, DEFAULT: 120.0 seconds]");
	hCvarWarnTimeToKick = CreateConVar("sm_afk_kick_warn_time", "60.0", "Time in seconds remaining, player should be warned before being kicked for AFK. [DEFAULT: 30.0 seconds]");
	hCvarSpawnTime = CreateConVar("sm_afk_spawn_time", "30.0", "Time in seconds (total) that player should have moved from their spawn position. [0 = DISABLED, DEFAULT: 20.0 seconds]");
	hCvarWarnSpawnTime = CreateConVar("sm_afk_spawn_warn_time", "15.0", "Time in seconds remaining, player should be warned for being AFK in spawn. [DEFAULT: 15.0 seconds]");
	hCvarExcludeBots = CreateConVar("sm_afk_exclude_bots", "1", "Should the AFK Manager exclude counting bots in player counts? [0 = FALSE, 1 = TRUE, DEFAULT: 0]", 0, true, 0.0, true, 1.0);
	hCvarExcludeDead = CreateConVar("sm_afk_exclude_dead", "1", "Should the AFK Manager exclude checking dead players? [0 = FALSE, 1 = TRUE, DEFAULT: 0]", 0, true, 0.0, true, 1.0);
	hCvarLocationThreshold = CreateConVar("sm_afk_location_threshold", "30.0", "Threshold for amount of movement required to mark a player as AFK. [0 = DISABLED, DEFAULT: 30.0]");
	hCvarWarnUnassigned = CreateConVar("sm_afk_move_warn_unassigned", "1", "Should the AFK Manager warn team 0 (Usually unassigned) players? (Disabling may not work for some games) [0 = FALSE, 1 = TRUE, DEFAULT: 1]", 0, true, 0.0, true, 1.0);
}

// Cvar Hook Registrations
RegisterHooks()
{
#if _DEBUG
	LogDebug(false, "Running RegisterHooks()");
#endif
	if (!bCvarIsHooked[CONVAR_VERSION])
	{
		// Hook Enabled Variable
		HookConVarChange(hCvarVersion, CvarChange_Version);
		bCvarIsHooked[CONVAR_VERSION] = true;
#if _DEBUG
		LogDebug(false, "RegisterHooks - Hooked Version variable.");
#endif
	}

	if (!bCvarIsHooked[CONVAR_ENABLED])
	{
		// Hook Enabled Variable
		HookConVarChange(hCvarEnabled, CvarChange_Enabled);
		bCvarIsHooked[CONVAR_ENABLED] = true;
#if _DEBUG
		LogDebug(false, "RegisterHooks - Hooked Enable variable.");
#endif
	}

	if (!bCvarIsHooked[CONVAR_WARNINGS])
	{
		// Hook Enabled Variable
		HookConVarChange(hCvarLogWarnings, CvarChange_Warnings);
		bCvarIsHooked[CONVAR_WARNINGS] = true;
#if _DEBUG
		LogDebug(false, "RegisterHooks - Hooked Warnings variable.");
#endif

		if (GetConVarBool(hCvarLogWarnings))
			bLogWarnings = true;
	}

	if (!bCvarIsHooked[CONVAR_EXCLUDEBOTS])
	{
		// Hook Enabled Variable
		HookConVarChange(hCvarExcludeBots, CvarChange_ExcludeBots);
		bCvarIsHooked[CONVAR_EXCLUDEBOTS] = true;
#if _DEBUG
		LogDebug(false, "RegisterHooks - Hooked Exclude Bots variable.");
#endif

		if (GetConVarBool(hCvarExcludeBots))
			bExcludeBots = true;
	}

	if (hCvarAFK != INVALID_HANDLE)
	{
		if (!bCvarIsHooked[CONVAR_MOD_AFK])
		{
			HookConVarChange(hCvarAFK, CvarChange_AFK);
			bCvarIsHooked[CONVAR_MOD_AFK] = true;
#if _DEBUG
			LogDebug(false, "RegisterHooks - Hooked Mod Based AFK variable.");
#endif
			SetConVarInt(hCvarAFK, 0);
		}
	}

	if (TF2)
	{
		if (hCvarTF2Arena != INVALID_HANDLE)
		{
			if (!bCvarIsHooked[CONVAR_TF2_ARENAMODE])
			{
				HookConVarChange(hCvarTF2Arena, CvarChange_TF2_Arena);
				bCvarIsHooked[CONVAR_TF2_ARENAMODE] = true;
#if _DEBUG
				LogDebug(false, "RegisterHooks - Hooked TF2 Arena variable.");
#endif

				if (GetConVarBool(hCvarTF2Arena))
					bTF2Arena = true;
			}
		}
	}
}

// Command Hook/Registrations
RegisterCmds()
{
#if _DEBUG
	LogDebug(false, "Running RegisterCmds()");
#endif
	// Say Hooks
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");

	RegAdminCmd("sm_afk_spec", Command_Spec, ADMFLAG_KICK, "sm_afk_spec <#userid|name>");

#if _DEBUG
	RegAdminCmd("sm_afk_test", Command_Test, ADMFLAG_ROOT);
#endif
}


// TF2 Arena Round Start Hook
TF2_HookRoundStart(bool:Arena)
{
#if _DEBUG
	LogDebug(false, "TF2_HookRoundStart - Hooking Events");
#endif
	if (Arena)
	{
#if _DEBUG
		LogDebug(false, "TF2_HookRoundStart - Hooking Arena Events");
#endif
		if (bEventIsHooked[EVENT_TEAMPLAY_ROUND_START])
		{
			UnhookEvent("teamplay_round_start", Event_RoundStart);
			bEventIsHooked[EVENT_TEAMPLAY_ROUND_START] = false;
#if _DEBUG
			LogDebug(false, "TF2_HookRoundStart - Unhooked Teamplay Round Start Event.");
#endif
		}
		if (!bEventIsHooked[EVENT_ARENA_ROUND_START])
		{
			HookEvent("arena_round_start", Event_RoundStart);
			bEventIsHooked[EVENT_ARENA_ROUND_START] = true;
#if _DEBUG
			LogDebug(false, "TF2_HookRoundStart - Hooked Arena Round Start Event.");
#endif
		}
	}
	else
	{
#if _DEBUG
		LogDebug(false, "TF2_HookRoundStart - Hooking Teamplay Events");
#endif
		if (bEventIsHooked[EVENT_ARENA_ROUND_START])
		{
			UnhookEvent("arena_round_start", Event_RoundStart);
			bEventIsHooked[EVENT_ARENA_ROUND_START] = false;
#if _DEBUG
			LogDebug(false, "TF2_HookRoundStart - Unhooked Arena Round Start Event.");
#endif
		}
		if (!bEventIsHooked[EVENT_TEAMPLAY_ROUND_START])
		{
			HookEvent("teamplay_round_start", Event_RoundStart);
			bEventIsHooked[EVENT_TEAMPLAY_ROUND_START] = true;
#if _DEBUG
			LogDebug(false, "TF2_HookRoundStart - Hooked Teamplay Round Start Event.");
#endif
		}
	}
}

// Enable Plugin
EnablePlugin()
{
	// Hook Standard Events
	if (!bEventIsHooked[EVENT_PLAYER_TEAM])
	{
		HookEvent("player_team", Event_PlayerTeamPost, EventHookMode_Post);
		bEventIsHooked[EVENT_PLAYER_TEAM] = true;
#if _DEBUG
		LogDebug(false, "EnablePlugin - Hooked Player Team Event.");
#endif
	}
	if (!bEventIsHooked[EVENT_PLAYER_SPAWN])
	{
		HookEvent("player_spawn",Event_PlayerSpawn);
		bEventIsHooked[EVENT_PLAYER_SPAWN] = true;
#if _DEBUG
		LogDebug(false, "EnablePlugin - Hooked Player Spawn Event.");
#endif
	}
	if (!bEventIsHooked[EVENT_PLAYER_DEATH])
	{
		HookEvent("player_death",Event_PlayerDeath);
		bEventIsHooked[EVENT_PLAYER_DEATH] = true;
#if _DEBUG
		LogDebug(false, "EnablePlugin - Hooked Player Death Event.");
#endif
	}

	// Team Fortress 2
	if (TF2)
	{
		TF2_HookRoundStart(bTF2Arena);
		//HookEvent("teamplay_restart_round", Event_RestartRound, EventHookMode_PostNoCopy);
		if (!bEventIsHooked[EVENT_ROUND_STALEMATE])
		{
			HookEvent("teamplay_round_stalemate", Event_StaleMate, EventHookMode_PostNoCopy);
			bEventIsHooked[EVENT_ROUND_STALEMATE] = true;
#if _DEBUG
			LogDebug(false, "EnablePlugin - Hooked Round Stalemate Event.");
#endif
		}
	}

	AFK_Start();
}

DisablePlugin()
{
	if (bEventIsHooked[EVENT_PLAYER_TEAM])
	{
		UnhookEvent("player_team", Event_PlayerTeamPost, EventHookMode_Post);
		bEventIsHooked[EVENT_PLAYER_TEAM] = false;
#if _DEBUG
		LogDebug(false, "DisablePlugin - Unhooked Player Team Event.");
#endif
	}
	if (bEventIsHooked[EVENT_PLAYER_SPAWN])
	{
		UnhookEvent("player_spawn",Event_PlayerSpawn);
		bEventIsHooked[EVENT_PLAYER_SPAWN] = false;
#if _DEBUG
		LogDebug(false, "DisablePlugin - Unhooked Player Spawn Event.");
#endif
	}
	if (bEventIsHooked[EVENT_PLAYER_DEATH])
	{
		UnhookEvent("player_death",Event_PlayerDeath);
		bEventIsHooked[EVENT_PLAYER_DEATH] = false;
#if _DEBUG
		LogDebug(false, "DisablePlugin - Unhooked Player Death Event.");
#endif
	}

	// Team Fortress 2
	if (TF2)
	{
		if (bEventIsHooked[EVENT_TEAMPLAY_ROUND_START])
		{
			UnhookEvent("teamplay_round_start", Event_RoundStart);
			bEventIsHooked[EVENT_TEAMPLAY_ROUND_START] = false;
#if _DEBUG
			LogDebug(false, "TF2_SetArenaMode - Unhooked Teamplay Round Start Event.");
#endif
		}
		if (bEventIsHooked[EVENT_ARENA_ROUND_START])
		{
			UnhookEvent("arena_round_start", Event_RoundStart);
			bEventIsHooked[EVENT_ARENA_ROUND_START] = false;
#if _DEBUG
			LogDebug(false, "TF2_SetArenaMode - Unhooked Arena Round Start Event.");
#endif
		}
		if (bEventIsHooked[EVENT_ROUND_STALEMATE])
		{
			UnhookEvent("teamplay_round_stalemate", Event_StaleMate, EventHookMode_PostNoCopy);
			bEventIsHooked[EVENT_ROUND_STALEMATE] = false;
#if _DEBUG
			LogDebug(false, "DisablePlugin - Unhooked Round Stalemate Event.");
#endif
		}
	}

	AFK_Stop();
}


// Cvar Hook Functions
// Hook Version
public CvarChange_Version(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if ( !StrEqual( newvalue, AFKM_VERSION) )
	{
		SetConVarString(cvar, AFKM_VERSION);
	}
}

// Hook Plugin Status
public CvarChange_Enabled(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
#if _DEBUG
	LogDebug(false, "CvarChange_Enabled - Enable cvar has been changed. Old value: %s New value: %s", oldvalue[0], newvalue[0]);
#endif

	if (!StrEqual(oldvalue, newvalue))
	{
		if (StringToInt(newvalue) == 1)
		{
#if _DEBUG
			LogDebug(false, "CvarChange_Enabled - Enabled (Hooking Events).");
#endif
			EnablePlugin();
		}
		else if (StringToInt(newvalue) == 0)
		{
#if _DEBUG
			LogDebug(false, "CvarChange_Enabled - Disabled (Unhooking Events).");
#endif
			DisablePlugin();
		}
	}
}

// Hook Warning Logging
public CvarChange_Warnings(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
#if _DEBUG
	LogDebug(false, "CvarChange_Warnings - Warnings cvar has been changed. Old value: %s New value: %s", oldvalue[0], newvalue[0]);
#endif

	if (!StrEqual(oldvalue, newvalue))
	{
		if (StringToInt(newvalue) == 1)
		{
#if _DEBUG
			LogDebug(false, "CvarChange_Warnings - Warnings Enabled.");
#endif
			bLogWarnings = true;
		}
		else if (StringToInt(newvalue) == 0)
		{
#if _DEBUG
			LogDebug(false, "CvarChange_Warnings - Warnings Disabled.");
#endif
			bLogWarnings = false;
		}
	}
}

// Hook Exclude Bots Variable
public CvarChange_ExcludeBots(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
#if _DEBUG
	LogDebug(false, "CvarChange_ExcludeBots - Exclude Bots cvar has been changed. Old value: %s New value: %s", oldvalue[0], newvalue[0]);
#endif

	if (!StrEqual(oldvalue, newvalue))
	{
		if (StringToInt(newvalue) == 1)
		{
#if _DEBUG
			LogDebug(false, "CvarChange_ExcludeBots - Exclude Bots Enabled.");
#endif
			bExcludeBots = true;
		}
		else if (StringToInt(newvalue) == 0)
		{
#if _DEBUG
			LogDebug(false, "CvarChange_ExcludeBots - Exclude Bots Disabled.");
#endif
			bExcludeBots = false;
		}
		iNumPlayers = AFK_GetClientCount( bExcludeBots, true );
	}
}

// Disable Mod Based AFK System
public CvarChange_AFK(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
#if _DEBUG
	LogDebug(false, "CvarChange_AFK - AFK cvar has been changed. Old value: %s New value: %s", oldvalue[0], newvalue[0]);
#endif

	if (StringToInt(newvalue) > 0)
	{
#if _DEBUG
			LogDebug(false, "CvarChange_AFK - Disabling Mod AFK handler.");
#endif
			SetConVarInt(cvar, 0);
	}	
}


// Hook TF2 Arena Mode
public CvarChange_TF2_Arena(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
#if _DEBUG
	LogDebug(false, "CvarChange_TF2_Arena - TF2 Arena cvar has been changed. Old value: %s New value: %s", oldvalue[0], newvalue[0]);
#endif

	if (!StrEqual(oldvalue, newvalue))
	{
		if (StringToInt(newvalue))
		{
			bTF2Arena = true;
			TF2_HookRoundStart(bTF2Arena);
		}
		else
		{
			bTF2Arena = false;
			TF2_HookRoundStart(bTF2Arena);
		}
	}
}


// Admin Spectate Move Command
public Action:Command_Spec(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[AFK Manager] Usage: sm_afk_spec <#userid|name>");
		return Plugin_Handled;
	}

	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
#if _DEBUG
		LogDebug(false, "Command_Spec - Moving client: %i to Spectator and killing timer.", target_list[i]);
#endif
		if (MoveAFKClient(target_list[i], false) == Plugin_Stop)
		{
			if (hAFKTimers[target_list[i]] != INVALID_HANDLE)
			{
				CloseHandle(hAFKTimers[target_list[i]]);
				hAFKTimers[target_list[i]] = INVALID_HANDLE;
			}
		}
	}

	if (tn_is_ml)
	{
		if (GetConVarBool(hCvarPrefixShort))
		{
			ShowActivity2(client, "[AFK] ", "%t", "Spectate_Force", target_name);
		}
		else
		{
			ShowActivity2(client, "[AFK Manager] ", "%t", "Spectate_Force", target_name);
		}
		LogToFile(AFKM_LogFile, "%L: %T", client, "Spectate_Force", LANG_SERVER, target_name);
	}
	else
	{
		if (GetConVarBool(hCvarPrefixShort))
			ShowActivity2(client, "[AFK] ", "%t", "Spectate_Force", "_s", target_name);
		else
			ShowActivity2(client, "[AFK Manager] ", "%t", "Spectate_Force", "_s", target_name);
		LogToFile(AFKM_LogFile, "%L: %T", client, "Spectate_Force", LANG_SERVER, "_s", target_name);
	}

	return Plugin_Handled;
}

#if _DEBUG
public Action:Command_Test(client, args)
{
	PrintToChatAll("*************************");
	PrintToServer("RAWR");

	//PrintToChatAll("Client: %i - Player State: %i", client, GetEntProp(client, Prop_Send, "m_iPlayerState"));
	//PrintToChatAll("Client: %i - Player Class: %i", client, GetEntProp(client, Prop_Send, "m_iClass"));
	//PrintToChatAll("Client: %i - Player Model: %i", client, GetEntProp(client, Prop_Send, "m_nModelIndex"));

	//PrintToChatAll("Client: %i - Player Carrying Object: %i", client, GetEntProp(client, Prop_Send, "m_bCarryingObject"));
	//PrintToChatAll("Client: %i - Player Carried Object: %i", client, GetEntProp(client, Prop_Send, "m_hCarriedObject"));

	PrintToChatAll("Client: %i - Desired Player Class: %i", client, GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass"));
	PrintToChatAll("Client: %i - Arena Spectator: %i", client, GetEntProp(client, Prop_Send, "m_bArenaSpectator"));
	PrintToChatAll("Client: %i - Life State: %i", client, GetEntProp(client, Prop_Send, "m_lifeState"));

	//PrintToChatAll("Current Players GetClientCount: %i", GetClientCount(true));

	//PrintToChatAll("Current Players: %i", iNumPlayers);
	//PrintToChatAll("Current Team 0 Players: %i", iTeamPlayers[0]);
	//PrintToChatAll("Current Team 1 Players: %i", iTeamPlayers[1]);
	//PrintToChatAll("Current Team 2 Players: %i", iTeamPlayers[2]);
	//PrintToChatAll("Current Team 3 Players: %i", iTeamPlayers[3]);
	//PrintToChatAll("Current Team: %i", iPlayerTeam[client]);

	//PrintToChat(client, "*************************");
	//PrintToChat(client, "Unrelated test");
	//PrintToChat(client, "[AFK Manager] %t", "MoveKick_Announce", "Move_Announce", "Test", "Kick_Announce", "Test");
	//PrintToChat(client, "*************************");

	//PrintToChatAll("Client: %i - Team Number: %i", client, GetEntProp(client, Prop_Send, "m_iTeamNum"));
	//PrintToChatAll("Client: %i - Team Number: %i", client, GetEntProp(client, Prop_Send, "m_nNextThinkTick", -1));
	//PrintToChatAll("Client: %i - Team Number: %i", client, GetEntProp(client, Prop_Send, "m_nSimulationTick"));
	

/*

	new String:classname[128];

	for (new i = 1; i < GetMaxEntities(); i++)
	{
		if (IsValidEdict(i))
		{
			GetEdictClassname(i, classname, sizeof(classname));
			LogAction(0, -1, "ENTITY CLASS: %s", classname);
		}
	}


	new team = FindEntityByClassname(-1, "tf_team");

	while (team != -1)
	{

		decl m_Offset;

		m_Offset = GetEntProp(team, Prop_Send, "m_iTeamNum");
		PrintToChat(client, "Player on Team: %i", m_Offset);

		m_Offset = FindSendPropInfo("CTFTeam", "\"player_array\"");
		PrintToChat(client, "Player Array Offset: %i", m_Offset);
		new ArrayValue[64];

		GetEntDataArray(team, m_Offset, ArrayValue, 64, 1);

		for (new i=0; i <= 63; i++)
		{
			if (ArrayValue[i] != 0)
				PrintToChat(client, "Player: %i ", ArrayValue[i]);
		}

		PrintToChatAll("FOUND TEAM ENT INDEX: %i", team);
		team = FindEntityByClassname(team, "tf_team");
	}


	if (IsClientObserver(client))
	{
		PrintToChatAll("Client: %i - You are an observer", client);
	}
	else
		PrintToChatAll("Client: %i - You are NOT an observer", client);

	new entityObjectiveResource = FindEntityByClassname(-1, "tf_objective_resource");
	PrintToChatAll("OBJECTIVE RESOURCE ENT INDEX: %i",entityObjectiveResource);

	new entityObserverPoint = FindEntityByClassname(-1, "info_observer_point");
	PrintToChatAll("OBSERVER POINT ENT INDEX: %i",entityObserverPoint);

	PrintToChatAll("PLAYER MANAGER ENT INDEX: %i",entityPlayerManager);

	new offsPlayerClass = FindSendPropInfo("CTFPlayerResource", "m_iPlayerClass");
	Value = GetEntData(entityPlayerManager, offsPlayerClass + (client * 4));
	PrintToChatAll("Client: %i - Player Class Resource: %i", client, Value);

	new offsAlive = FindSendPropInfo("CTFPlayerResource", "m_bAlive");
	Value = GetEntData(entityPlayerManager, offsAlive + (client * 4));
	PrintToChatAll("Client: %i - Player Alive Resource: %i", client, Value);

	new offsHealth = FindSendPropInfo("CTFPlayerResource", "m_iHealth");
	Value = GetEntData(entityPlayerManager, offsHealth + (client * 4));
	PrintToChatAll("Client: %i - Player Health Resource: %i", client, Value);

	Value = GetEntData(entityPlayerManager, offsArenaSpectators + client);
	PrintToChatAll("Client: %i - Arena Spectator Resource: %i", client, Value);

	Value = GetEntData(entityPlayerManager, offsTF2Team + (client * 4));
	PrintToChatAll("Client: %i - TF2 Team Resource: %i", client, Value);

	Value = GetEntProp(client, Prop_Send, "m_iObserverMode");
	PrintToChatAll("Client: %i - Spectator Mode: %i", client, Value);

	Value = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	PrintToChatAll("Client: %i - Spectator Target: %i", client, Value);

	Value = GetEntProp(client, Prop_Send, "m_nPlayerState");
	PrintToChatAll("Client: %i - Player State: %i", client, Value);

	Value = GetEntProp(client, Prop_Send, "m_nPlayerCond");
	PrintToChatAll("Client: %i - Player Condition: %i", client, Value);

	Value = GetEntProp(client, Prop_Send, "m_nArenaNumChanges");
	PrintToChatAll("Client: %i - Arena Num Changes?: %i", client, Value);

	Value = GetEntProp(client, Prop_Send, "m_iSpawnCounter");
	PrintToChatAll("Client: %i - Spawn Counter?: %i", client, Value);

	new offsObserver = FindDataMapOffs(client,"m_bForcedObserverMode");
	Value = GetEntData(client, offsObserver);
	PrintToChatAll("Client: %i - Forced Observer?: %i", client, Value);

	new entityGameRules = FindEntityByClassname(-1, "tf_gamerules");

	PrintToChatAll("GAME RULES ENT INDEX: %i",entityGameRules);

	new offsReady = FindSendPropInfo("CTeamplayRoundBasedRulesProxy", "m_bTeamReady");
	offsReady = FindSendPropInfo("CTFPlayerResource", "m_bArenaSpectator");
	Value = GetEntData(entityGameRules, offsReady + client);
	PrintToChatAll("Client: %i - Ready?: %i", client, Value);
*/
	PrintToChatAll("*************************");

	return Plugin_Handled;
}
#endif




public OnMapStart()
{
#if _DEBUG
	LogDebug(false, "OnMapStart - Event Fired");
#endif
	BuildLogFilePath();

	if (GetConVarBool(hCvarAutoUpdate))
	{
#if defined _autoupdate_included
		if (LibraryExists("pluginautoupdate") && !GetConVarBool(FindConVar("sv_lan")))
		{
			ServerCommand("sm_autoupdate_download afk_manager");
		}
#elseif defined _updater_included
		if (LibraryExists("updater") && !GetConVarBool(FindConVar("sv_lan")))
		{
			Updater_ForceUpdate();
		}
#endif
	}

	// Execute Config
	AutoExecConfig(true, "afk_manager");

	// Check Game Mode
	if (TF2)
	{
		if (TF2_GameMode:TF2_DetectGameMode() == TF2_GameMode_Arena)
		{
#if _DEBUG
			LogDebug(false, "OnMapStart - Detected TF2 Arena Game Mode");
#endif
			bTF2Arena = true;
		}

		if (bTF2Arena)
		{
			// Set No Waiting for players
			g_TF2_WFP_StartTime = 0;
			bWaitRound = false;

			if (hCvarTF2WFPTime != INVALID_HANDLE)
			{
				if ((GetConVarFloat(hCvarTF2WFPTime) - 1.0) > 0.0)
				{
	#if _DEBUG
					LogDebug(false, "OnMapStart - Waiting for players event started");
	#endif
					// Waiting for players
					g_TF2_WFP_StartTime = GetTime();
					bWaitRound = true;
				}
			}
		}
		else
		{
			// No Waiting for players
			g_TF2_WFP_StartTime = 0;
			bWaitRound = false;
		}
	}
	else
	{
		// No Waiting for players
		g_TF2_WFP_StartTime = 0;
		bWaitRound = false;
	}
}

public OnMapEnd()
{
	// Pause Plugin During Map Transitions?
	bWaitRound = true;
}


// Player Resetting/Initialization/Uninitialization Functions
ResetSpawn(index)
{
	// Reset Spawn Values
	bAFKSpawn[index] = false;
	fSpawnPosition[index] = Float:{0.0,0.0,0.0};
}

ResetPlayer(index)
{
	// Reset Player Values
#if _DEBUG > 1
	LogDebug(false, "ResetPlayer - Reseting arrays for client: %i", index);
#endif

	fAFKTime[index] = 0.0;

	fEyePosition[index] = Float:{0.0,0.0,0.0};
	//fMapPosition[index] = Float:{0.0,0.0,0.0};

	iSpecMode[index] = 0;
	iSpecTarget[index] = 0;

	ResetSpawn(index);
}

InitializePlayer(index)
{
	bJoinedTeam[index] = false;

	if (!IsFakeClient(index))
	{
#if _DEBUG > 1
		LogDebug(false, "InitializePlayer - Initializing client: %i", index);
#endif

		// Check Timers and Destroy Them?
		if (hAFKTimers[index] != INVALID_HANDLE)
		{
#if _DEBUG > 1
			LogDebug(false, "InitializePlayer - Closing Old AFK timer for client: %i", index);
#endif

			CloseHandle(hAFKTimers[index]);
			hAFKTimers[index] = INVALID_HANDLE;
		}

		// Check Admin immunity
		new bool:FullImmunity = false;

		if (GetConVarInt(hCvarAdminsImmune) == 1)
			if (CheckAdminImmunity(index))
				FullImmunity = true;
		if (!FullImmunity)
		{
			// Create AFK Timer
#if _DEBUG > 1
			LogDebug(false, "InitializePlayer - Creating AFK timer for client: %i", index);
#endif
			hAFKTimers[index] = CreateTimer(AFK_CHECK_INTERVAL, Timer_CheckPlayer, index, TIMER_REPEAT);

			ResetPlayer(index);
		}
		else
		{
#if _DEBUG > 1
			LogDebug(false, "InitializePlayer - Not creating AFK timer for client: %i due to admin immunity?", index);
#endif
		}
	}
}

UnInitializePlayer(index)
{
	bJoinedTeam[index] = false;

	// Check for timers and destroy them?
	if (hAFKTimers[index] != INVALID_HANDLE)
	{
#if _DEBUG > 1
		LogDebug(false, "UnInitializePlayer - Closing AFK timer for client: %i", index);
#endif

		CloseHandle(hAFKTimers[index]);
		hAFKTimers[index] = INVALID_HANDLE;
	}
	ResetPlayer(index);
}

AFK_Start()
{
#if _DEBUG
	LogDebug(false, "AFK_Start - AFK Plugin Starting!");
#endif

	// Reset Player Count
	iNumPlayers = AFK_GetClientCount( bExcludeBots, true );

	// Make sure timers are reset for all players.
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			if (IsClientInGame(i))
			{
#if _DEBUG
				LogDebug(false, "AFK_Start - Client: %d is in the game.", i);
#endif
				if (iPlayerTeam[i] == -1)
				{
					iPlayerTeam[i] = GetClientTeam(i);
					iTeamPlayers[iPlayerTeam[i]]++;
				}

				InitializePlayer(i);
			}
		}
	}

	// Check we have enough minimum players for move
	bMovePlayers = CheckPlayerCount(MOVE);

	// Check we have enough minimum players for kick
	bKickPlayers = CheckPlayerCount(KICK);

#if _DEBUG
	LogDebug(false, "AFK_Start - Finished Reseting Clients!");	
#endif
}

AFK_Stop()
{
#if _DEBUG
	LogDebug(false, "AFK_Stop - AFK Plugin Halting!");
#endif

	// Reset Player Count
	iNumPlayers = 0;

	// Make sure timers are stopped for all players.
	for(new i = 1; i <= MaxClients; i++)
	{
		UnInitializePlayer(i);

		if (IsClientConnected(i))
		{
			if (IsClientInGame(i))
			{
				if (iPlayerTeam[i] != -1)
				{
					iTeamPlayers[iPlayerTeam[i]]--;
					iPlayerTeam[i] = -1;
				}
			}
		}
	}

#if _DEBUG
	LogDebug(false, "AFK_Stop - Finished Reseting Clients!");	
#endif
}


public OnClientPutInServer(client)
{
#if _DEBUG
	LogDebug(false, "OnClientPutInServer - Client put in server: %i", client);
#endif
	// Increment Player Count
	if (GetConVarBool(hCvarEnabled))
	{
		iNumPlayers = AFK_GetClientCount( bExcludeBots, true );
#if _DEBUG
	LogDebug(false, "OnClientPutInServer - Players: %i", iNumPlayers);
#endif
		iPlayerTeam[client] = GetClientTeam(client);
		iTeamPlayers[iPlayerTeam[client]]++;
#if _DEBUG
	LogDebug(false, "OnClientPutInServer - Team: %i", iPlayerTeam[client]);
#endif
		bMovePlayers = CheckPlayerCount(MOVE);
		bKickPlayers = CheckPlayerCount(KICK);
	}
}

public OnClientPostAdminCheck(client)
{
	if (GetConVarBool(hCvarEnabled))
	{
		// Initialize Player once they are put in the server and post-connection authorizations have been performed.
		//FakeClientCommandEx(client,"jointeam %i", g_sTeam_Index);
		InitializePlayer(client);
	}
}

public OnClientDisconnect(client)
{
#if _DEBUG
	LogDebug(false, "OnClientDisconnect - Client disconnected: %i", client);
#endif
	if (GetConVarBool(hCvarEnabled))
	{
		// UnInitializePlayer since they are leaving the server.
		UnInitializePlayer(client);
	}
}

public OnClientDisconnect_Post(client)
{
#if _DEBUG
	LogDebug(false, "OnClientDisconnect_Post - Client disconnected: %i", client);
#endif
	if (GetConVarBool(hCvarEnabled))
	{
		// Reset Player Counts
		iNumPlayers = AFK_GetClientCount( bExcludeBots, true );
#if _DEBUG
	LogDebug(false, "OnClientDisconnect_Post - Players: %i", iNumPlayers);
#endif

#if _DEBUG
	LogDebug(false, "OnClientDisconnect_Post - Old Team: %i", iPlayerTeam[client]);
#endif

		if (iPlayerTeam[client] != -1)
		{
			iTeamPlayers[iPlayerTeam[client]]--;
			iPlayerTeam[client] = -1;
		}

		bMovePlayers = CheckPlayerCount(MOVE);
		bKickPlayers = CheckPlayerCount(KICK);
	}
}




/*
TF2_RegisterArenaHooks()
{
#if _DEBUG
	LogDebug(false, "TF2_RegisterArenaHooks - Registering Arena Hooks");
#endif
	HookEvent("teamplay_broadcast_audio", Event_BroadcastAudio, EventHookMode_Post);
	HookEvent("teamplay_waiting_begins", Event_WaitBegins, EventHookMode_PostNoCopy);
	HookEvent("teamplay_waiting_ends", Event_WaitEnds, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", Event_WaitEnds, EventHookMode_PostNoCopy);
	HookEvent("arena_win_panel", Event_WaitBegins, EventHookMode_PostNoCopy);
	HookEvent("teamplay_update_timer", Event_WaitEnds, EventHookMode_PostNoCopy);
	//HookEvent("game_message", Event_WaitEnds, EventHookMode_PostNoCopy);
	//arena_player_notification
	//HookEvent("teamplay_round_win", Event_WaitBegins, EventHookMode_PostNoCopy);
}

TF2_UnregisterArenaHooks()
{
#if _DEBUG
	LogDebug(false, "TF2_UnregisterArenaHooks - Unregistering Arena Hooks");
#endif
	UnhookEvent("teamplay_broadcast_audio", Event_BroadcastAudio, EventHookMode_Post);
	UnhookEvent("teamplay_waiting_begins", Event_WaitBegins, EventHookMode_PostNoCopy);
	UnhookEvent("teamplay_waiting_ends", Event_WaitEnds, EventHookMode_PostNoCopy);
	UnhookEvent("arena_round_start", Event_WaitEnds, EventHookMode_PostNoCopy);
	UnhookEvent("arena_win_panel", Event_WaitBegins, EventHookMode_PostNoCopy);
	UnhookEvent("teamplay_update_timer", Event_WaitEnds, EventHookMode_PostNoCopy);
	//HookEvent("game_message", Event_WaitEnds, EventHookMode_PostNoCopy);
	//arena_player_notification
	//HookEvent("teamplay_round_win", Event_WaitBegins, EventHookMode_PostNoCopy);
}

TF2_StartArenaMode()
{
#if _DEBUG
	LogDebug(false, "TF2_StartArenaMode - TF2 Arena Mode Starting");
#endif
	g_TF2ArenaStarted = false;
	bWaitRound = true;

	TF2_RegisterArenaHooks();
}

TF2_EndArenaMode()
{
#if _DEBUG
	LogDebug(false, "TF2_EndArenaMode - TF2 Arena Mode Ending");
#endif
	g_TF2ArenaStarted = false;
	bWaitRound = false;

	TF2_UnregisterArenaHooks();
}

public Action:Event_BroadcastAudio(Handle:event, const String:name[], bool:dontBroadcast)
{
	// TF2 Broadcast Sound
	decl String:sound[64];
	GetEventString(event, "sound", sound, sizeof(sound));

	if (StrEqual(sound,"Announcer.AM_RoundStartRandom"))
	{
#if _DEBUG
		LogDebug(false, "Event_BroadcastAudio - Round Started");
#endif
		g_TF2ArenaStarted = true;
		bWaitRound = false;
	}
	return Plugin_Continue;
}

public Action:Event_WaitBegins(Handle:event, const String:name[], bool:dontBroadcast)
{
	// TF2 Wait for players begins?
#if _DEBUG
	LogDebug(false, "Event_WaitBegins - %s - Waiting for players Started", name);
#endif

	g_TF2ArenaStarted = false;
	bWaitRound = true;
	return Plugin_Continue;
}

public Action:Event_WaitEnds(Handle:event, const String:name[], bool:dontBroadcast)
{
	// TF2 Wait for players ends?
#if _DEBUG
	LogDebug(false, "Event_WaitEnds - %s - Waiting for players Ended", name);
#endif

	g_TF2ArenaStarted = true;
	bWaitRound = false;
	return Plugin_Continue;
}
*/


// Game Events
public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// Check the client is not console/world?
	if (client > 0)
	{
		// Check client is not a bot or otherwise fake player.
		if (!IsFakeClient(client))
		{
			// Lincoln is fucking up
			// Fix for Valve deciding to fire player_spawn on Spectator team!?!?
			// IsClientObserver() IsPlayerAlive() and GetClientHealth() do not fix this bug?
			if (CSTRIKE)
			{
				if (GetClientTeam(client) == 0)
				{
					// Unassigned Team?
					return Plugin_Continue;
				}	
			}

			if (!IsClientObserver(client))
			{
#if _DEBUG > 2
				LogDebug(false, "Event_PlayerSpawn - Client Spawned and is not an Observer");
#endif
				// Fix for Valve causing Unassigned to not be detected as an Observer in CSS?
				if (IsPlayerAlive(client))
				{
#if _DEBUG > 2
					LogDebug(false, "Event_PlayerSpawn - Client Spawned and is alive?");
#endif
					// Fix for Valve causing Unassigned to be alive?
					if (GetClientHealth(client) > 0)
					{
#if _DEBUG > 2
						LogDebug(false, "Event_PlayerSpawn - Client Spawned and has health? Health: %i", GetClientHealth(client));
#endif
						// Check if Spawn AFK is enabled.
						if (GetConVarFloat(hCvarSpawnTime) > 0.0)
						{
							// Re-Create timer to align it with spawn time.
							InitializePlayer(client);

							// Get Player Spawn Eye Angles
							GetClientEyeAngles(client, fSpawnPosition[client]);
#if _DEBUG > 2
							LogDebug(false, "Event_PlayerSpawn - Client Spawn Position: %f %f %f", fSpawnPosition[client][0], fSpawnPosition[client][1], fSpawnPosition[client][2]);
#endif
							// Get Player Spawn Origin
							//GetClientAbsOrigin(client, fSpawnPosition[client]);

							bAFKSpawn[client] = true;
						}
						else
						{
							// Reset AFK timer because they spawned.
							ResetPlayer(client);
						}
#if _DEBUG > 2
						LogDebug(false, "Event_PlayerSpawn - Client spawned: %i", client);
#endif
				}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_PlayerTeamPost(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

#if _DEBUG
	LogDebug(false, "Event_PlayerTeamPost - Client: %i", client);
#endif

	// Check the client is not console/world?
	if (client > 0)
	{
		new team = GetEventInt(event, "team");

		if (TF2)
		{
			if (!bTF2Arena)
			{
				if ((team == TF2_TEAM_RED) || (team == TF2_TEAM_BLUE))
				{
#if _DEBUG
					LogDebug(false, "Event_PlayerTeamPost - BEFORE - Red Team Players: %d Blue Team players: %d", iTeamPlayers[TF2_TEAM_RED], iTeamPlayers[TF2_TEAM_BLUE]);
#endif
					if ((iTeamPlayers[TF2_TEAM_RED] == 0) && (iTeamPlayers[TF2_TEAM_BLUE] == 0))
					{
#if _DEBUG
						LogDebug(false, "Event_PlayerTeamPost - First player joined a team");
#endif
						// This is the first player joining a team? Waiting for players starts?

						// Set No Waiting for players
						g_TF2_WFP_StartTime = 0;
						bWaitRound = false;

						if (hCvarTF2WFPTime != INVALID_HANDLE)
						{
							if ((GetConVarFloat(hCvarTF2WFPTime) - 1.0) > 0.0)
							{
#if _DEBUG
								LogDebug(false, "Event_PlayerTeamPost - Waiting for players event started");
#endif
								// Waiting for players
								g_TF2_WFP_StartTime = GetTime();
								bWaitRound = true;
							}
						}
					}
				}
			}
		}

		// Update Player Team Details
#if _DEBUG
		LogDebug(false, "Event_PlayerTeamPost - Client: %d is changing team", client);
		LogDebug(false, "Event_PlayerTeamPost - Client: %d previous team: %d", client, iPlayerTeam[client]);
		LogDebug(false, "Event_PlayerTeamPost - Client: %d previous team: %d previous team players: %d", client, iPlayerTeam[client], iTeamPlayers[iPlayerTeam[client]]);
#endif
		iTeamPlayers[iPlayerTeam[client]]--;
		iPlayerTeam[client] = team;
		iTeamPlayers[iPlayerTeam[client]]++;

#if _DEBUG
		if (TF2)
		{
			LogDebug(false, "Event_PlayerTeamPost - AFTER - Red Team Players: %d Blue Team players: %d", iTeamPlayers[TF2_TEAM_RED], iTeamPlayers[TF2_TEAM_BLUE]);
		}
#endif

		// Player Joined a Team
		bJoinedTeam[client] = true;

		// Check client is not a bot or otherwise fake player.
		if (!IsFakeClient(client))
		{
			// Check if player is joining a non spectator team.
			if(team != g_sTeam_Index)
			{
#if _DEBUG > 2
				LogDebug(false, "Event_PlayerTeamPost - Client: %d joined team: %d", client, team);
#endif

				// Check if the player already has a valid timer.
				if (hAFKTimers[client] == INVALID_HANDLE)
				{
#if _DEBUG > 2
					LogDebug(false, "Event_PlayerTeamPost - Client: %d joined a team and does not have a valid timer? Re-Initializing client", client);
#endif
					InitializePlayer(client);
				}
				else
				{
					// Reset AFK timer because they joined a team.
					ResetPlayer(client);
				}
			}
			else
			{
				// Player joined or was moved to spectator team?
#if _DEBUG > 2
				LogDebug(false, "Event_PlayerTeamPost - Client: %d joined spectator team", client);
#endif
				// Set new AFK details to ensure timer continues
				// Get New Player Eye Angles
				GetClientEyeAngles(client, fEyePosition[client]);

				// Get New Player Map Origin
				//GetClientAbsOrigin(client, fMapPosition[client]);

				iSpecMode[client] = GetEntProp(client, Prop_Send, "m_iObserverMode");
				iSpecTarget[client] = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));

	// Reset attackers timer when he kills someone.
	ResetPlayer(attacker);

	return Plugin_Continue;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Round Started
#if _DEBUG
	LogDebug(false, "Event_RoundStart - Round Started Text: %s", name);
#endif

	new bool:FullReset = GetEventBool(event, "full_reset");

	if (FullReset)
	{
#if _DEBUG
		LogDebug(false, "Event_RoundStart - Round Started and is FULL RESET");
#endif
	}

	// Waiting for Players should now be over?

	// Un-pause Plugin After Map Transition?
	if (bWaitRound)
	{
		if (g_TF2_WFP_StartTime > 0)
		{
			if (hCvarTF2WFPTime != INVALID_HANDLE)
			{
				if ( (GetTime() - g_TF2_WFP_StartTime) > (GetConVarFloat(hCvarTF2WFPTime) - 1.0) )
				{
					// Waiting for players is now over?
#if _DEBUG
					LogDebug(false, "Event_RoundStart - Waiting for players event ended");
#endif
					g_TF2_WFP_StartTime = 0;
					bWaitRound = false;
				}
				else
				{
#if _DEBUG
					LogDebug(false, "Event_RoundStart - Round Started but waiting for players is still active.");
#endif
				}
			}
		}
		else
		{
#if _DEBUG
			LogDebug(false, "Event_RoundStart - Round Started and waiting for players is now over.");
#endif
			bWaitRound = false;
		}

		// Initialize Settings
		//if (GetConVarBool(hCvarEnabled))
		//{
		//	AFK_Initialize();
		//}
	}
	return Plugin_Continue;
}

public Action:Event_StaleMate(Handle:event, const String:name[], bool:dontBroadcast)
{
	// TF2 Stalemate?
#if _DEBUG
	LogDebug(false, "Event_StaleMate - StaleMate Started");
#endif

	bWaitRound = true;
	return Plugin_Continue;
}


// Player Chat
public Action:Command_Say(client, const String:command[], args)
{
	if (GetConVarBool(hCvarEnabled))
	{
		// Reset timers once player has said something in chat.
		ResetPlayer(client);
	}
	return Plugin_Continue;
}


/*
// Menu Functions
CreateAFKMenu(client)
{
	if (hAFKMenu[client] != INVALID_HANDLE)
	{
		CancelClientMenu(client);
		hAFKMenu[client] = INVALID_HANDLE;
	}

	hAFKMenu[client] = CreateMenu(AFKMenuSelected);
	SetMenuTitle(menu,"[AFK Manager] %T", "Menu_Title");

	//PrintToConsole(attacker, "[Anti-TK] %t", "TK_Message_TKer", victimName);
	//PrintToChat(attacker, "%c[Anti-TK]%c %t", ANTITK_COLOR, 1, "TK_Message_TKer", victimName);

	// Disable Exit
	SetMenuExitButton(hAFKMenu[client], false);

	decl String:MenuItem[128];

	Format(MenuItem, sizeof(MenuItem),"%T", "Menu_AFK", victim);
	AddMenuItem(hAFKMenu[client],"1",MenuItem);

	//"You are currently AFK"

#if _DEBUG
	LogDebug(false, "Displaying AFK menu to client: %d", client);
#endif
	DisplayMenu(hAFKMenu[client],client,MENU_TIME_FOREVER);
}

public AFKMenuSelected(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;

	decl String:tmp[32], pMenuItemSelected;
	GetMenuItem(menu, param2, tmp, sizeof(tmp));
	pMenuItemSelected = StringToInt(tmp);

	switch (action)
	{
		case MenuAction_Select:
		{
			switch (pMenuItemSelected)
			{
				default:
				{
#if _DEBUG
					LogDebug(false, "AFKMenuSelected - Client: %d has selected item: %i", client, pMenuItemSelected);
#endif
					ResetPlayer(client);
				}
			}
		}

		case MenuAction_Cancel:
		{
#if _DEBUG
			LogDebug(false, "AFKMenuSelected - Client: %d has cancelled the AFK Menu", client);
#endif
		}

		case MenuAction_End:
		{
#if _DEBUG
			LogDebug(false, "AFKMenuSelected - Ended menu for Client: %d", client);
#endif
			CloseHandle(menu);
		}
	}
}
*/


// AFK Timer
public Action:Timer_CheckPlayer(Handle:Timer, any:client)
{
#if _DEBUG >= 2
	LogDebug(false, "Timer_CheckPlayer - Executing Timer Check on Client: %d", client);
#endif
	// Is the AFK Manager Enabled
	if(GetConVarBool(hCvarEnabled))
	{
		// Are we waiting for the round to start
		if (bWaitRound)
			return Plugin_Continue;

		// Do we have enough players to start any checks
		if ( ((bMovePlayers = CheckPlayerCount(MOVE)) == false) && ((bKickPlayers = CheckPlayerCount(KICK)) == false) )
		{
			// Not enough players to enable plugin.
			return Plugin_Continue;
		}

		// Is this player actually in the game?
		if (IsClientInGame(client))
		{
#if _DEBUG > 2
			LogDebug(false, "Timer_CheckPlayer - Checking if Client is AFK.");
#endif
			new Action:timer_result = CheckForAFK(client);
			if (timer_result != Plugin_Stop)
				return timer_result;
		}
		else
			return Plugin_Continue;
	}

	hAFKTimers[client] = INVALID_HANDLE;
	return Plugin_Stop;
}


// AFK Observer/Spectator Check
bool:CheckObserverAFK(client)
{
	if ((!Synergy) && (bJoinedTeam[client] == false))
	{
#if _DEBUG
		LogDebug(false, "Client: %i has not joined team", client);
#endif
		return true;
	}

	if (TF2)
	{
		// TF2 Arena Checks
		if (bTF2Arena)
		{
			// Player is Observing but not a proper spectator? Side note this will I guess stop dead player checks?
			if (GetEntProp(client, Prop_Send, "m_bArenaSpectator") == 0)
			{
#if _DEBUG > 2
				LogDebug(false, "CheckObserverAFK - Observer if waiting to play TF2 Arena? Client: %i", client);
#endif
				return false;
			}
		}
	}

	// Store Last Spec Mode
	new g_Last_Mode = iSpecMode[client];

	// Check Current Spectator Mode
	iSpecMode[client] = GetEntProp(client, Prop_Send, "m_iObserverMode");

	if (g_Last_Mode > 0)
	{
		// Check if Spectator Mode Changed
		if (iSpecMode[client] != g_Last_Mode)
		{
#if _DEBUG > 2
			LogDebug(false, "CheckObserverAFK - Observer has changed modes? Old: %i New: %i Not AFK?", g_Last_Mode, iSpecMode[client]);
#endif
			return false;
		}
	}

	// Store Previous Map Location Values
	decl Float:f_Map_Loc[3];
	f_Map_Loc = fMapPosition[client];

	// Store Previous Eye Angle/Origin Values
	decl Float:f_Eye_Loc[3];
	f_Eye_Loc = fEyePosition[client];



	// Check if player is in Free Look Mode
	if (iSpecMode[client] == g_Spec_FL_Mode)
	{
		// Get New Player Eye Angles
		GetClientEyeAngles(client, fEyePosition[client]);

		// Get New Player Map Origin
		//GetClientAbsOrigin(client, fMapPosition[client]);
	}
	else
	{
		// Check Spectator Target
		new g_Last_Spec = iSpecTarget[client];

		iSpecTarget[client] = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");

		// Check if player was just moved to Spectator? We have now stored new values.
		if ((g_Last_Mode == 0) && (g_Last_Spec == 0))
		{
			return true;
		}
		else if (g_Last_Spec > 0)
		{
			if (GetConVarBool(hCvarSpecCheckTarget))
			{
				// Check if we are spectating the same player.
				if (iSpecTarget[client] != g_Last_Spec)
				{
#if _DEBUG > 1
					LogDebug(false, "CheckObserverAFK - Observer looking at new target? Old: %i New: %i", g_Last_Spec, iSpecTarget[client]);
#endif
					// Old target died and is no longer valid.
					if (IsValidClient(g_Last_Spec, false))
					{
#if _DEBUG > 2
						LogDebug(false, "CheckObserverAFK - Observer old target is a valid client? Old: %i", g_Last_Spec);
#endif
						if (!IsPlayerAlive(g_Last_Spec))
						{
#if _DEBUG > 1
							LogDebug(false, "CheckObserverAFK - Observer old target is valid but they are now dead? Old: %i", g_Last_Spec);
#endif
							return true;
						}
						else
						{
#if _DEBUG > 2
							LogDebug(false, "CheckObserverAFK - Observer old target is still alive? Probably switched players? Old: %i", g_Last_Spec);
#endif
							return false;
						}
					}
					else
					{
#if _DEBUG > 2
						LogDebug(false, "CheckObserverAFK - Observer old target is not a valid player? Probably disconnected? Old: %i", g_Last_Spec);
#endif
						return false;
					}
				}
			}
		}
	}

	// Check if we are in the same position and looking at the same place.
	// Check Position
	if ((fMapPosition[client][0] == f_Map_Loc[0]) &&
		(fMapPosition[client][1] == f_Map_Loc[1]) &&
		(fMapPosition[client][2] == f_Map_Loc[2]))
	{
		// Check Eye Angles
		if ((fEyePosition[client][0] == f_Eye_Loc[0]) &&
			(fEyePosition[client][1] == f_Eye_Loc[1]) &&
			(fEyePosition[client][2] == f_Eye_Loc[2]))
		{
			return true;
		}
	}
#if _DEBUG > 2
	LogDebug(false, "CheckObserverAFK - Observer is not AFK?");
#endif
	return false;
}


// Check Player Position & Eye Angle Values
bool:CheckSamePosition(client)
{
	// Store Previous Eye Angle/Origin Values
	decl Float:f_Eye_Loc[3];
	f_Eye_Loc = fEyePosition[client];

	// Store Previous Map Location Values
	decl Float:f_Map_Loc[3];
	f_Map_Loc = fMapPosition[client];


	// Get New Player Eye Angles
	GetClientEyeAngles(client, fEyePosition[client]);
#if _DEBUG > 2
	LogDebug(false, "CheckSamePosition - Player Eye Angles: Client: %d New Angle: %f %f %f", client, fEyePosition[client][0], fEyePosition[client][1], fEyePosition[client][2]);
#endif

	// Get New Player Map Origin
	GetClientAbsOrigin(client, fMapPosition[client]);

	// Check if player is frozen?
	if(GetEntityFlags(client) & FL_FROZEN)
	{
#if _DEBUG > 2
		LogDebug(false, "CheckSamePosition - Client: %d is frozen.", client);
#endif
		return false;
	}

	// Check if the player has just spawned.
	if (bAFKSpawn[client])
	{
		// This function could probably be cleaned up.
		// Check if player is looking at the same spawn position.
		if ((fEyePosition[client][0] == fSpawnPosition[client][0]) &&
			(fEyePosition[client][1] == fSpawnPosition[client][1]) &&
			(fEyePosition[client][2] == fSpawnPosition[client][2]))
		{
#if _DEBUG > 2
			LogDebug(false, "CheckSamePosition - Client: %i eyes are in Spawn Position", client);
#endif
			return true;
		}
		else
		{
#if _DEBUG > 2
			LogDebug(false, "CheckSamePosition - Client: %i eyes are no longer in Spawn Position", client);
#endif
			ResetSpawn(client);	
		}
	}
/*
	else
	{
		// Check if player is in the same spawn position.
		if ((fMapPosition[client][0] == fSpawnPosition[client][0]) &&
			(fMapPosition[client][1] == fSpawnPosition[client][1]) &&
			(fMapPosition[client][2] == fSpawnPosition[client][2]))
		{
#if _DEBUG > 2
			LogDebug(false, "CheckSamePosition - Client: %i is in Spawn Position", client);
#endif
			return true;
		}
		else
		{
#if _DEBUG > 2
			LogDebug(false, "CheckSamePosition - Client: %i is no longer in Spawn Position", client);
#endif
			ResetSpawn(client);	
		}
	}
*/

#if _DEBUG > 2
	LogDebug(false, "CheckSamePosition - Checking Player Eye Angles: Client: %d Old Angle: %f %f %f New Angle: %f %f %f", client, f_Eye_Loc[0], f_Eye_Loc[1], f_Eye_Loc[2], fEyePosition[client][0], fEyePosition[client][1], fEyePosition[client][2]);
	LogDebug(false, "CheckSamePosition - Checking Player Position: Client: %d Old Position: %f %f %f New Position: %f %f %f", client, f_Map_Loc[0], f_Map_Loc[1], f_Map_Loc[2], fMapPosition[client][0], fMapPosition[client][1], fMapPosition[client][2]);
#endif
	
	new Float:Threshold = GetConVarFloat(hCvarLocationThreshold);
	// Check Location (Origin) now including thresholds.
	if ((FloatAbs(fMapPosition[client][0] - f_Map_Loc[0]) < Threshold) &&
		(FloatAbs(fMapPosition[client][1] - f_Map_Loc[1]) < Threshold) &&
		(FloatAbs(fMapPosition[client][2] - f_Map_Loc[2]) < Threshold))
	{

		if (Synergy)
		{
			// Check if player is using a device like a turret?
			decl UseEntity;
			UseEntity = GetEntPropEnt(client, Prop_Send, "m_hUseEntity");

			if (UseEntity != -1)
			{
				// Check viewing angles?
#if _DEBUG > 2
				LogDebug(false, "CheckSamePosition - Checking Player Turret Angles");
#endif
				GetEntPropVector(UseEntity, Prop_Send, "m_angRotation", fEyePosition[3]);
#if _DEBUG > 2
				LogDebug(false, "CheckSamePosition - Turret Angles: %f %f %f", fEyePosition[client][0], fEyePosition[client][1], fEyePosition[client][2]);
#endif
			}
		}

		// Check Eye Angles
		if ((fEyePosition[client][0] == f_Eye_Loc[0]) &&
			(fEyePosition[client][1] == f_Eye_Loc[1]) &&
			(fEyePosition[client][2] == f_Eye_Loc[2]))
		{
/*
			if (Insurgency)
			{
				if (!IsPlayerAlive(client))
				{
					// Check Re-Inforcements
					new waves = FindSendPropInfo("CPlayTeam", "numwaves");
#if _DEBUG > 2
					LogDebug(false, "CheckSamePosition - Checking Waves? %i", waves);
					new time = GetEntPropEnt(client, Prop_Send, "m_flDeathTime");
					LogDebug(false, "CheckSamePosition - Checking Death Time? %i", time);
#endif
					if (waves <= 0)
						return false;
				}
				else
					return true;
			}
			else
*/
				return true;
		}
	}
	return false;
}


// Check if a player is AFK
Action:CheckForAFK(client)
{
#if _DEBUG > 2
	LogDebug(false, "CheckForAFK - CHECKING CLIENT: %i FOR AFK", client);
#endif
	new g_TeamNum = GetClientTeam(client);

	// Unassigned, Spectator or Dead Player
	if (IsClientObserver(client))
	{
		if ((Synergy) || (g_TeamNum > 0))
		{
			// Check Excluding Dead Players?
			if (!IsPlayerAlive(client))
			{
				// Make sure player is not a spectator (Which is dead)
				if (g_TeamNum != g_sTeam_Index)
					if (GetConVarBool(hCvarExcludeDead))
						return Plugin_Continue;
			}
		}

		if (CheckObserverAFK(client))
			fAFKTime[client] = (fAFKTime[client] + AFK_CHECK_INTERVAL);
		else
			fAFKTime[client] = 0.0;
	}
	else
	{
		// Normal player
		if (CheckSamePosition(client))
			fAFKTime[client] = (fAFKTime[client] + AFK_CHECK_INTERVAL);
		else
			fAFKTime[client] = 0.0;
	}

	new AdminsImmune = GetConVarInt(hCvarAdminsImmune);

	if (fAFKTime[client] > 0.0)
	{
		// Check if AFK Move is enabled
		if (GetConVarBool(hCvarMoveSpec))
		{
			// Check we are not moving from Spectator team to Spectator team
			if (g_TeamNum != g_sTeam_Index)
			{
				// Check we have enough minimum players
				if (bMovePlayers == true)
				{
					// Check Admin Immunity
					if ( (AdminsImmune == 0) || (AdminsImmune == 2) || (!CheckAdminImmunity(client)) )
					{
						// Spawn AFK Check
						if (bAFKSpawn[client])
						{
							new Float:afk_spawn_timeleft = (GetConVarFloat(hCvarSpawnTime) - fAFKTime[client]);
#if _DEBUG > 2
							LogDebug(false, "Spawn Time: %f AFK Time: %f AFK Spawn Timeleft: %f AFK Warn Time: %f", GetConVarFloat(hCvarSpawnTime), fAFKTime[client], afk_spawn_timeleft, GetConVarFloat(hCvarWarnSpawnTime));
#endif

							// Are we supposed to be warning the client?
							if ( afk_spawn_timeleft <= GetConVarFloat(hCvarWarnSpawnTime) )
							{
								// Is there still time to warn the client?
								if (afk_spawn_timeleft > 0.0)
								{
									// Warn the player they are being flagged as AFK.
#if _DEBUG > 2
									LogDebug(false, "CheckForAFK - Checking AFK Spawn Time (Move): Client: %d Timeleft: %f", client, afk_spawn_timeleft);
#endif
									if (GetConVarBool(hCvarLanguage))
										AFK_PrintToChat(client, "%t", "Spawn_Move_Warning", LANG_SERVER, RoundToFloor(afk_spawn_timeleft));
									else
										AFK_PrintToChat(client, "%t", "Spawn_Move_Warning", RoundToFloor(afk_spawn_timeleft));
									return Plugin_Continue;
								}
								else
								{
#if _DEBUG > 2
									LogDebug(false, "CheckForAFK - Moving AFK Client: %i to Spectator for Spawn AFK.", client);
#endif

									// Are we moving player from the Unassigned team AKA team 0?
									if (g_TeamNum == 0)
									{
										bAFKSpawn[client] = false; // Mark player as not AFK in spawn so they are not kicked instantly after move.
										return MoveAFKClient(client, GetConVarBool(hCvarWarnUnassigned)); // Are we warning unassigned players?
									}
									else
									{
										bAFKSpawn[client] = false; // Mark player as not AFK in spawn so they are not kicked instantly after move.
										return MoveAFKClient(client);
									}
								}
							}
						}

						new Float:afk_move_time = GetConVarFloat(hCvarTimeToMove);

						// Is the AFK Move time greater than 0 seconds?
						if (afk_move_time > 0.0)
						{
							new Float:afk_move_timeleft = (afk_move_time - fAFKTime[client]);

#if _DEBUG > 2
							LogDebug(false, "Move Time: %f AFK Time: %f AFK Timeleft: %f AFK Warn Time: %f", GetConVarFloat(hCvarTimeToMove), fAFKTime[client], afk_move_timeleft, GetConVarFloat(hCvarWarnTimeToMove));
#endif
							if ( afk_move_timeleft <= GetConVarFloat(hCvarWarnTimeToMove) )
							{
								// Is there still time to warn the client?
								if (afk_move_timeleft > 0.0)
								{
									// Warn the player they are being flagged as AFK.
#if _DEBUG > 2
									LogDebug(false, "CheckForAFK - Checking AFK Time (Move): Client: %d Timeleft: %f", client, afk_move_timeleft);
#endif
									if (GetConVarBool(hCvarLanguage))
										AFK_PrintToChat(client, "%t", "Move_Warning", LANG_SERVER, RoundToFloor(afk_move_timeleft));
									else
										AFK_PrintToChat(client, "%t", "Move_Warning", RoundToFloor(afk_move_timeleft));
									return Plugin_Continue;
								}
								else
								{
#if _DEBUG > 2
									LogDebug(false, "CheckForAFK - Moving AFK Client: %i to Spectator for General AFK.", client);
#endif

									// Are we moving player from the Unassigned team AKA team 0?
									if (g_TeamNum == 0)
										return MoveAFKClient(client, GetConVarBool(hCvarWarnUnassigned)); // Are we warning unassigned players?
									else
										return MoveAFKClient(client);
								}
							}
							else
								return Plugin_Continue;
						}
						else
						{
							// AFK Move is enabled but move time is 0 seconds?
#if _DEBUG > 2
							LogDebug(false, "CheckForAFK - Not Checking General AFK Move as move time is less than or equal to 0?");
#endif
							return Plugin_Continue;
						}
					}
				}
				else
				{
#if _DEBUG > 2
					LogDebug(false, "CheckForAFK - Not Checking General AFK Move as minimum players is not met?");
#endif
				}
			}
			else
			{
#if _DEBUG > 2
				LogDebug(false, "CheckForAFK - Not Checking General AFK Move as player is already on the spectator team?");
#endif
			}
		}
		else
		{
#if _DEBUG > 2
			LogDebug(false, "CheckForAFK - Not Checking General AFK Move as move is disabled?");
#endif
		}

		new KickPlayers = GetConVarInt(hCvarKickPlayers);

		// Check if AFK Kick is enabled
		if (KickPlayers > 0)
		{
			// Check we have enough minimum players
			if (bKickPlayers == true)
			{
				if ((KickPlayers == 2) && (g_TeamNum == g_sTeam_Index))
				{
					// Kicking is set to exclude spectators.
					// Player is on the spectator team. Spectators should not be kicked.
#if _DEBUG > 2
					LogDebug(false, "Not Checking General AFK Kick as Client: %d is on the spectator team and we are excluding spectators.", client);
#endif
					return Plugin_Continue;
				}
				else if ((KickPlayers == 3) && (g_TeamNum != g_sTeam_Index))
				{
					// Kicking is set to spectator only.
					// Player is not on the spectator team? Spectators should only be kicked? This should not happen and would be an error.
#if _DEBUG > 2
					LogDebug(false, "CheckForAFK - ERROR: Client: %s has an active timer but should not be moved or kicked? This should probably not happen.", client);
#endif
					return Plugin_Continue;
				}
				else
				{
					// Check Admin Immunity
					if ( (AdminsImmune == 0) || (AdminsImmune == 3) || (!CheckAdminImmunity(client)) )
					{
						// Spawn AFK Check
						if (bAFKSpawn[client])
						{
							new Float:afk_spawn_timeleft = (GetConVarFloat(hCvarSpawnTime) - fAFKTime[client]);

							// Are we supposed to be warning the client?
							if ( afk_spawn_timeleft <= GetConVarFloat(hCvarWarnSpawnTime) )
							{
								// Is there still time to warn the client?
								if (afk_spawn_timeleft > 0.0)
								{
									// Warn the player they are being flagged as AFK.
#if _DEBUG > 2
									LogDebug(false, "CheckForAFK - Checking AFK Spawn Time (Kick): Client: %d Timeleft: %f", client, afk_spawn_timeleft);
#endif
									if (GetConVarBool(hCvarLanguage))
										AFK_PrintToChat(client, "%t", "Spawn_Kick_Warning", LANG_SERVER, RoundToFloor(afk_spawn_timeleft));
									else
										AFK_PrintToChat(client, "%t", "Spawn_Kick_Warning", RoundToFloor(afk_spawn_timeleft));
									return Plugin_Continue;
								}
								else
									return KickAFKClient(client);
							}
						}

						new Float:afk_kick_time = GetConVarFloat(hCvarTimeToKick);

						// Is the AFK Kick time greater than 0 seconds?
						if (afk_kick_time > 0.0)
						{
							new Float:afk_kick_timeleft = (afk_kick_time - fAFKTime[client]);

#if _DEBUG > 2
							LogDebug(false, "Kick Time: %f AFK Time: %f AFK Timeleft: %f AFK Warn Time: %f", GetConVarFloat(hCvarTimeToKick), fAFKTime[client], afk_kick_timeleft, GetConVarFloat(hCvarWarnTimeToKick));
#endif

							// Are we supposed to be warning the client?
							if ( afk_kick_timeleft <= GetConVarFloat(hCvarWarnTimeToKick) )
							{
								// Is there still time to warn the client?
								if (afk_kick_timeleft > 0.0)
								{
									// Warn the player they are being flagged as AFK.
#if _DEBUG > 2
									LogDebug(false, "CheckForAFK - Checking AFK Time (Kick): Client: %d Timeleft: %f", client, afk_kick_timeleft);
#endif
									if (GetConVarBool(hCvarLanguage))
										AFK_PrintToChat(client, "%t", "Kick_Warning", LANG_SERVER, RoundToFloor(afk_kick_timeleft));
									else
										AFK_PrintToChat(client, "%t", "Kick_Warning", RoundToFloor(afk_kick_timeleft));
									return Plugin_Continue;
								}
								else
									return KickAFKClient(client);
							}
						}
						else
						{
							// AFK Kick is enabled but kick time is 0 seconds?
#if _DEBUG > 2
							LogDebug(false, "CheckForAFK - Not Checking General AFK Kick as kick time is less than or equal to 0?");
#endif
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}


// Move AFK Client to Spectator Team
Action:MoveAFKClient(client, bool:Advertise=true)
{
#if _DEBUG
	LogDebug(false, "MoveAFKClient - Client: %i has been moved to Spectator.", client);
#endif
	decl String:f_Name[MAX_NAME_LENGTH];
	GetClientName(client, f_Name, sizeof(f_Name));

	// Are we announcing the move to everyone?
	if (Advertise)
	{
		if (GetConVarBool(hCvarLanguage))
			AFK_PrintToChatAll("%t", "Move_Announce", LANG_SERVER, f_Name);
		else
			AFK_PrintToChatAll("%t", "Move_Announce", f_Name);
	}
	else
	{
		if (GetConVarBool(hCvarLanguage))
			AFK_PrintToChat(client, "%t", "Move_Announce", LANG_SERVER, f_Name);
		else
			AFK_PrintToChat(client, "%t", "Move_Announce", f_Name);
	}

	if (GetConVarBool(hCvarLogMoves))
		LogToFile(AFKM_LogFile, "%T", "Move_Log", LANG_SERVER, client);

	// Kill Player so round ends properly, this is Valve's normal method.
	if (CSTRIKE)
		ForcePlayerSuicide(client);

	if (TF2)
	{
		// Fix for Intelligence
		new iEnt = -1;
		while ((iEnt = FindEntityByClassname(iEnt, "item_teamflag")) > -1) {
			if (IsValidEntity(iEnt))
			{
				if (GetEntPropEnt(iEnt, Prop_Data, "m_hMoveParent") == client)
				{
					AcceptEntityInput(iEnt, "ForceDrop");
				}
			}
		}

		if (bTF2Arena)
		{
			// Arena Spectator Fix by Rothgar
			//SetEntProp(client, Prop_Send, "m_nNextThinkTick", -1);
			//SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", 0);
			//SetEntProp(client, Prop_Send, "m_bArenaSpectator", 1);
			ForcePlayerSuicide(client);
			if (GetConVarBool(FindConVar("tf_arena_use_queue")))
				FakeClientCommand(client,"jointeam %d", "spectatearena");
			else
				FakeClientCommand(client,"jointeam %d", g_sTeam_Index);
		} else {
			ForcePlayerSuicide(client);
			// Move AFK Player to Spectator
			ChangeClientTeam(client, g_sTeam_Index);
		}
	} else {
		// Move AFK Player to Spectator
		ChangeClientTeam(client, g_sTeam_Index);
	}

/*
	if (Insurgency)
	{
		// If player is alive in Insurgency they need to be killed by running a kill command.
		if (IsPlayerAlive(client))
			ClientCommand(client, "kill");
	}
*/

/*
	// Check if spectators are supposed to be kicked.
	new KickPlayers = GetConVarInt(hCvarKickPlayers);
	if( (KickPlayers == 0) || (KickPlayers == 2) )
	{
#if _DEBUG
		LogDebug(false, "Spectators should not be kicked due to settings? Stop Timer?");
#endif

		ResetPlayer(client); // Reset Client Variables because timer will halt?
		return Plugin_Stop;
	}
	else
*/
	return Plugin_Continue;
}


// Kick AFK Client
Action:KickAFKClient(client)
{
	decl String:f_Name[MAX_NAME_LENGTH];
	GetClientName(client, f_Name, sizeof(f_Name));

	if (GetConVarBool(hCvarLanguage))
		AFK_PrintToChatAll("%t", "Kick_Announce", LANG_SERVER, f_Name);
	else
		AFK_PrintToChatAll("%t", "Kick_Announce", f_Name);

	if (GetConVarBool(hCvarLogKicks))
		LogToFile(AFKM_LogFile, "%T", "Kick_Log", LANG_SERVER, client);

	// Kick AFK Player
#if _DEBUG
	LogDebug(false, "KickAFKClient - Kicking player %s for being AFK.", f_Name);
#endif
	if (GetConVarBool(hCvarPrefixShort))
	{
		if (GetConVarBool(hCvarLanguage))
			KickClient(client, "[AFK] %t", "Kick_Message", LANG_SERVER);
		else
			KickClient(client, "[AFK] %t", "Kick_Message");
	}
	else
	{
		if (GetConVarBool(hCvarLanguage))
			KickClient(client, "[AFK Manager] %t", "Kick_Message", LANG_SERVER);
		else
			KickClient(client, "[AFK Manager] %t", "Kick_Message");
	}
	return Plugin_Continue;
}


// Check Admin Immunity
bool:CheckAdminImmunity(client)
{
#if _DEBUG > 1
	LogDebug(false, "CheckAdminImmunity - Checking client: %i for admin immunity.", client);
#endif

	decl String:name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	new AdminId:admin = GetUserAdmin(client);

	// Check if player is an admin.
	if(admin != INVALID_ADMIN_ID)
	{
		decl String:flags[8];
		decl AdminFlag:flag;

		GetConVarString(hCvarAdminsFlag, flags, sizeof(flags));

		// Are we checking for specific admin flags?
		if (!StrEqual(flags, "", false))
		{
			// Is the admin flag we are checking valid?
			if (!FindFlagByChar(flags[0], flag))
			{
#if _DEBUG > 1
				LogDebug(false, "CheckAdminImmunity - ERROR: Admin Immunity flag is not valid? %s", flags[0]);
#endif
			}
			else
			{
				// Check if the admin has the correct immunity flag.
				if (!GetAdminFlag(admin, flag))
				{
#if _DEBUG > 1
					LogDebug(false, "CheckAdminImmunity - Client: %s has a valid Admin ID but does NOT have required immunity flag %s admin is NOT immune.", name, flags[0]);
#endif
				}
				else
				{
#if _DEBUG > 1
					LogDebug(false, "CheckAdminImmunity - Client: %s has required immunity flag %s admin is immune.", name, flags[0]);
#endif
					return true;
				}
			}
		}
		else
		{
			// Player is an admin, we don't care about flags.
#if _DEBUG > 1
			LogDebug(false, "CheckAdminImmunity - Client: %s is a valid Admin and is immune.", name);
#endif
			return true;
		}
	}
	else
	{
#if _DEBUG > 1
		LogDebug(false, "CheckAdminImmunity - Client: %s has an invalid Admin ID.", name);
#endif
	}

	return false;
}
