/**
 * vim: set ts=4 :
 * =============================================================================
 * MapChooser Extended
 * Creates a map vote at appropriate times, setting sm_nextmap to the winning
 * vote.  Includes extra options not present in the SourceMod MapChooser
 *
 * MapChooser Extended (C)2011-2013 Powerlord (Ross Bemrose)
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
 * Version: $Id$
 */

//#define DEBUG

#if defined DEBUG
	#define assert(%1) if (!(%1)) ThrowError("Debug Assertion Failed");
	#define assert_msg(%1,%2) if (!(%1)) ThrowError(%2);
#else
	#define assert(%1)
	#define assert_msg(%1,%2)
#endif

#pragma semicolon 1
#include <sourcemod>
#include <mapchooser>
#include "include/mapchooser_extended"
#include <nextmap>
#include <sdktools>
#include <colors>

#undef REQUIRE_PLUGIN
#include <nativevotes>

#define MCE_VERSION "1.10.2"

#define NV "nativevotes"

enum RoundCounting
{
	RoundCounting_Standard = 0,
	RoundCounting_MvM,
	RoundCounting_ArmsRace,
}

// CSGO requires two cvars to get the game type
enum
{
	GameType_Classic	= 0,
	GameType_GunGame	= 1,
	GameType_Training	= 2,
	GameType_Custom		= 3,
}

enum
{
	GunGameMode_ArmsRace	= 0,
	GunGameMode_Demolition	= 1,
	GunGameMode_DeathMatch	= 2,
}

public Plugin:myinfo =
{
	name = "MapChooser Extended",
	author = "Powerlord, Zuko, and AlliedModders LLC",
	description = "Automated Map Voting with Extensions",
	version = MCE_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=156974"
};

/* Valve ConVars */
new Handle:g_Cvar_Winlimit = INVALID_HANDLE;
new Handle:g_Cvar_Maxrounds = INVALID_HANDLE;
new Handle:g_Cvar_Fraglimit = INVALID_HANDLE;
new Handle:g_Cvar_Bonusroundtime = INVALID_HANDLE;
new Handle:g_Cvar_MatchClinch = INVALID_HANDLE;
new Handle:g_Cvar_VoteNextLevel = INVALID_HANDLE;
new Handle:g_Cvar_GameType = INVALID_HANDLE;
new Handle:g_Cvar_GameMode = INVALID_HANDLE;

/* Plugin ConVars */
new Handle:g_Cvar_StartTime = INVALID_HANDLE;
new Handle:g_Cvar_StartRounds = INVALID_HANDLE;
new Handle:g_Cvar_StartFrags = INVALID_HANDLE;
new Handle:g_Cvar_ExtendTimeStep = INVALID_HANDLE;
new Handle:g_Cvar_ExtendRoundStep = INVALID_HANDLE;
new Handle:g_Cvar_ExtendFragStep = INVALID_HANDLE;
new Handle:g_Cvar_ExcludeMaps = INVALID_HANDLE;
new Handle:g_Cvar_IncludeMaps = INVALID_HANDLE;
new Handle:g_Cvar_NoVoteMode = INVALID_HANDLE;
new Handle:g_Cvar_Extend = INVALID_HANDLE;
new Handle:g_Cvar_DontChange = INVALID_HANDLE;
new Handle:g_Cvar_EndOfMapVote = INVALID_HANDLE;
new Handle:g_Cvar_VoteDuration = INVALID_HANDLE;

new Handle:g_VoteTimer = INVALID_HANDLE;
new Handle:g_RetryTimer = INVALID_HANDLE;
new Handle:g_WarningTimer = INVALID_HANDLE;

/* Data Handles */
new Handle:g_MapList = INVALID_HANDLE;
new Handle:g_NominateList = INVALID_HANDLE;
new Handle:g_NominateOwners = INVALID_HANDLE;
new Handle:g_OldMapList = INVALID_HANDLE;
new Handle:g_NextMapList = INVALID_HANDLE;
new Handle:g_VoteMenu = INVALID_HANDLE;

new g_Extends;
new g_TotalRounds;
new bool:g_HasVoteStarted;
new bool:g_WaitingForVote;
new bool:g_MapVoteCompleted;
new bool:g_ChangeMapAtRoundEnd;
new bool:g_ChangeMapInProgress;
new bool:g_HasIntermissionStarted = false;
new g_mapFileSerial = -1;

new g_NominateCount = 0;
new MapChange:g_ChangeTime;

new Handle:g_NominationsResetForward = INVALID_HANDLE;
new Handle:g_MapVoteStartedForward = INVALID_HANDLE;

/* Mapchooser Extended Plugin ConVars */

new Handle:g_Cvar_RunOff = INVALID_HANDLE;
new Handle:g_Cvar_RunOffPercent = INVALID_HANDLE;
new Handle:g_Cvar_BlockSlots = INVALID_HANDLE;
new Handle:g_Cvar_MaxRunOffs = INVALID_HANDLE;
new Handle:g_Cvar_StartTimePercent = INVALID_HANDLE;
new Handle:g_Cvar_StartTimePercentEnable = INVALID_HANDLE;
new Handle:g_Cvar_WarningTime = INVALID_HANDLE;
new Handle:g_Cvar_RunOffWarningTime = INVALID_HANDLE;
new Handle:g_Cvar_MenuStyle = INVALID_HANDLE;
new Handle:g_Cvar_TimerLocation = INVALID_HANDLE;
new Handle:g_Cvar_ExtendPosition = INVALID_HANDLE;
new Handle:g_Cvar_MarkCustomMaps = INVALID_HANDLE;
new Handle:g_Cvar_RandomizeNominations = INVALID_HANDLE;
new Handle:g_Cvar_HideTimer = INVALID_HANDLE;
new Handle:g_Cvar_NoVoteOption = INVALID_HANDLE;

/* Mapchooser Extended Data Handles */
new Handle:g_OfficialList = INVALID_HANDLE;

/* Mapchooser Extended Forwards */
new Handle:g_MapVoteWarningStartForward = INVALID_HANDLE;
new Handle:g_MapVoteWarningTickForward = INVALID_HANDLE;
new Handle:g_MapVoteStartForward = INVALID_HANDLE;
new Handle:g_MapVoteEndForward = INVALID_HANDLE;
new Handle:g_MapVoteRunoffStartForward = INVALID_HANDLE;

/* Mapchooser Extended Globals */
new g_RunoffCount = 0;
new g_mapOfficialFileSerial = -1;
new bool:g_NativeVotes = false;
new String:g_GameModName[64];
new bool:g_WarningInProgress = false;
new bool:g_AddNoVote = false;

new RoundCounting:g_RoundCounting = RoundCounting_Standard;

/* Upper bound of how many team there could be */
#define MAXTEAMS 10
new g_winCount[MAXTEAMS];

new bool:g_BlockedSlots = false;
new g_ObjectiveEnt = -1;

enum TimerLocation
{
	TimerLocation_Hint = 0,
	TimerLocation_Center = 1,
	TimerLocation_Chat = 2,
}

enum WarningType
{
	WarningType_Vote,
	WarningType_Revote,
}

#define VOTE_EXTEND "##extend##"
#define VOTE_DONTCHANGE "##dontchange##"

/* Mapchooser Extended Defines */
#define LINE_ONE "##lineone##"
#define LINE_TWO "##linetwo##"
#define LINE_SPACER "##linespacer##"
#define FAILURE_TIMER_LENGTH 5

public OnPluginStart()
{
	LoadTranslations("mapchooser_extended.phrases");
	LoadTranslations("basevotes.phrases");
	LoadTranslations("common.phrases");
	
	new arraySize = ByteCountToCells(PLATFORM_MAX_PATH);
	g_MapList = CreateArray(arraySize);
	g_NominateList = CreateArray(arraySize);
	g_NominateOwners = CreateArray(1);
	g_OldMapList = CreateArray(arraySize);
	g_NextMapList = CreateArray(arraySize);
	g_OfficialList = CreateArray(arraySize);
	
	GetGameFolderName(g_GameModName, sizeof(g_GameModName));
	
	g_Cvar_EndOfMapVote = CreateConVar("mce_endvote", "1", "Specifies if MapChooser should run an end of map vote", _, true, 0.0, true, 1.0);

	g_Cvar_StartTime = CreateConVar("mce_starttime", "10.0", "Specifies when to start the vote based on time remaining.", _, true, 1.0);
	g_Cvar_StartRounds = CreateConVar("mce_startround", "2.0", "Specifies when to start the vote based on rounds remaining. Use 0 on DoD:S, CS:S, and TF2 to start vote during bonus round time", _, true, 0.0);
	g_Cvar_StartFrags = CreateConVar("mce_startfrags", "5.0", "Specifies when to start the vote base on frags remaining.", _, true, 1.0);
	g_Cvar_ExtendTimeStep = CreateConVar("mce_extend_timestep", "15", "Specifies how much many more minutes each extension makes", _, true, 5.0);
	g_Cvar_ExtendRoundStep = CreateConVar("mce_extend_roundstep", "5", "Specifies how many more rounds each extension makes", _, true, 1.0);
	g_Cvar_ExtendFragStep = CreateConVar("mce_extend_fragstep", "10", "Specifies how many more frags are allowed when map is extended.", _, true, 5.0);	
	g_Cvar_ExcludeMaps = CreateConVar("mce_exclude", "5", "Specifies how many past maps to exclude from the vote.", _, true, 0.0);
	g_Cvar_IncludeMaps = CreateConVar("mce_include", "5", "Specifies how many maps to include in the vote.", _, true, 2.0, true, 6.0);
	g_Cvar_NoVoteMode = CreateConVar("mce_novote", "1", "Specifies whether or not MapChooser should pick a map if no votes are received.", _, true, 0.0, true, 1.0);
	g_Cvar_Extend = CreateConVar("mce_extend", "0", "Number of extensions allowed each map.", _, true, 0.0);
	g_Cvar_DontChange = CreateConVar("mce_dontchange", "1", "Specifies if a 'Don't Change' option should be added to early votes", _, true, 0.0);
	g_Cvar_VoteDuration = CreateConVar("mce_voteduration", "20", "Specifies how long the mapvote should be available for.", _, true, 5.0);

	// MapChooser Extended cvars
	CreateConVar("mce_version", MCE_VERSION, "MapChooser Extended Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_Cvar_RunOff = CreateConVar("mce_runoff", "1", "Hold run off votes if winning choice has less than a certain percentage of votes", _, true, 0.0, true, 1.0);
	g_Cvar_RunOffPercent = CreateConVar("mce_runoffpercent", "50", "If winning choice has less than this percent of votes, hold a runoff", _, true, 0.0, true, 100.0);
	g_Cvar_BlockSlots = CreateConVar("mce_blockslots", "1", "Block slots to prevent accidental votes.  Only applies when Voice Command style menus are in use.", _, true, 0.0, true, 1.0);
	//g_Cvar_BlockSlotsCount = CreateConVar("mce_blockslots_count", "2", "Number of slots to block.", _, true, 1.0, true, 3.0);
	g_Cvar_MaxRunOffs = CreateConVar("mce_maxrunoffs", "1", "Number of run off votes allowed each map.", _, true, 0.0);
	g_Cvar_StartTimePercent = CreateConVar("mce_start_percent", "35.0", "Specifies when to start the vote based on percents.", _, true, 0.0, true, 100.0);
	g_Cvar_StartTimePercentEnable = CreateConVar("mce_start_percent_enable", "0", "Enable or Disable percentage calculations when to start vote.", _, true, 0.0, true, 1.0);
	g_Cvar_WarningTime = CreateConVar("mce_warningtime", "15.0", "Warning time in seconds.", _, true, 0.0, true, 60.0);
	g_Cvar_RunOffWarningTime = CreateConVar("mce_runoffvotewarningtime", "5.0", "Warning time for runoff vote in seconds.", _, true, 0.0, true, 30.0);
	g_Cvar_MenuStyle = CreateConVar("mce_menustyle", "0", "Menu Style.  0 is the game's default, 1 is the older Valve style that requires you to press Escape to see the menu, 2 is the newer 1-9 button Voice Command style, unavailable in some games. Ignored on TF2 if NativeVotes Plugin is loaded.", _, true, 0.0, true, 2.0);
	g_Cvar_TimerLocation = CreateConVar("mce_warningtimerlocation", "0", "Location for the warning timer text. 0 is HintBox, 1 is Center text, 2 is Chat.  Defaults to HintBox.", _, true, 0.0, true, 2.0);
	g_Cvar_MarkCustomMaps = CreateConVar("mce_markcustommaps", "1", "Mark custom maps in the vote list. 0 = Disabled, 1 = Mark with *, 2 = Mark with phrase.", _, true, 0.0, true, 2.0);
	g_Cvar_ExtendPosition = CreateConVar("mce_extendposition", "0", "Position of Extend/Don't Change options. 0 = at end, 1 = at start.", _, true, 0.0, true, 1.0);
	g_Cvar_RandomizeNominations = CreateConVar("mce_randomizeorder", "0", "Randomize map order?", _, true, 0.0, true, 1.0);
	g_Cvar_HideTimer = CreateConVar("mce_hidetimer", "0", "Hide the MapChooser Extended warning timer", _, true, 0.0, true, 1.0);
	g_Cvar_NoVoteOption = CreateConVar("mce_addnovote", "1", "Add \"No Vote\" to vote menu?", _, true, 0.0, true, 1.0);

	RegAdminCmd("sm_mapvote", Command_Mapvote, ADMFLAG_CHANGEMAP, "sm_mapvote - Forces MapChooser to attempt to run a map vote now.");
	RegAdminCmd("sm_setnextmap", Command_SetNextmap, ADMFLAG_CHANGEMAP, "sm_setnextmap <map>");
	
	// Mapchooser Extended Commands
	RegAdminCmd("mce_reload_maplist", Command_ReloadMaps, ADMFLAG_CHANGEMAP, "mce_reload_maplist - Reload the Official Maplist file.");

	g_Cvar_Winlimit = FindConVar("mp_winlimit");
	g_Cvar_Maxrounds = FindConVar("mp_maxrounds");
	g_Cvar_Fraglimit = FindConVar("mp_fraglimit");
	
	new EngineVersion:version = GetEngineVersionCompat();
	
	decl String:mapListPath[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, mapListPath, PLATFORM_MAX_PATH, "configs/mapchooser_extended/maps/%s.txt", g_GameModName);
	SetMapListCompatBind("official", mapListPath);

	switch (version)
	{
		case Engine_TF2:
		{
			g_Cvar_VoteNextLevel = FindConVar("sv_vote_issue_nextlevel_allowed");
			g_Cvar_Bonusroundtime = FindConVar("mp_bonusroundtime");			
		}
		
		case Engine_CSGO:
		{
			g_Cvar_VoteNextLevel = FindConVar("mp_endmatch_votenextmap");
			g_Cvar_GameType = FindConVar("game_type");
			g_Cvar_GameMode = FindConVar("game_mode");
			g_Cvar_Bonusroundtime = FindConVar("mp_round_restart_delay");
		}
		
		case Engine_DODS:
		{
			g_Cvar_Bonusroundtime = FindConVar("dod_bonusroundtime");
		}
		
		case Engine_CSS:
		{
			g_Cvar_Bonusroundtime = FindConVar("mp_round_restart_delay");
		}
		
		default:
		{
			g_Cvar_Bonusroundtime = FindConVar("mp_bonusroundtime");			
		}
	}

	if (g_Cvar_Winlimit != INVALID_HANDLE || g_Cvar_Maxrounds != INVALID_HANDLE)
	{
		switch (version)
		{
			case Engine_TF2:
			{
				HookEvent("teamplay_win_panel", Event_TeamPlayWinPanel);
				HookEvent("teamplay_restart_round", Event_TFRestartRound);
				HookEvent("arena_win_panel", Event_TeamPlayWinPanel);
				HookEvent("pve_win_panel", Event_MvMWinPanel);
			}
			
			case Engine_NuclearDawn:
			{
				HookEvent("round_win", Event_RoundEnd);
			}
			
			case Engine_CSGO:
			{
				HookEvent("round_end", Event_RoundEnd);
				HookEvent("cs_intermission", Event_Intermission);
				HookEvent("announce_phase_end", Event_PhaseEnd);
				g_Cvar_MatchClinch = FindConVar("mp_match_can_clinch");
			}
			
			case Engine_DODS:
			{
				HookEvent("dod_round_win", Event_RoundEnd);
			}
			
			default:
			{
				HookEvent("round_end", Event_RoundEnd);
			}
		}
	}
	
	if (g_Cvar_Fraglimit != INVALID_HANDLE)
	{
		HookEvent("player_death", Event_PlayerDeath);		
	}
	
	AutoExecConfig(true, "mapchooser_extended");
	
	//Change the mp_bonusroundtime max so that we have time to display the vote
	//If you display a vote during bonus time good defaults are 17 vote duration and 19 mp_bonustime
	if (g_Cvar_Bonusroundtime != INVALID_HANDLE)
	{
		SetConVarBounds(g_Cvar_Bonusroundtime, ConVarBound_Upper, true, 30.0);		
	}
	
	g_NominationsResetForward = CreateGlobalForward("OnNominationRemoved", ET_Ignore, Param_String, Param_Cell);
	g_MapVoteStartedForward = CreateGlobalForward("OnMapVoteStarted", ET_Ignore);

	//MapChooser Extended Forwards
	g_MapVoteStartForward = CreateGlobalForward("OnMapVoteStart", ET_Ignore); // Deprecated
	g_MapVoteEndForward = CreateGlobalForward("OnMapVoteEnd", ET_Ignore, Param_String);
	g_MapVoteWarningStartForward = CreateGlobalForward("OnMapVoteWarningStart", ET_Ignore);
	g_MapVoteWarningTickForward = CreateGlobalForward("OnMapVoteWarningTick", ET_Ignore, Param_Cell);
	g_MapVoteRunoffStartForward = CreateGlobalForward("OnMapVoteRunnoffWarningStart", ET_Ignore);

}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (LibraryExists("mapchooser"))
	{
		strcopy(error, err_max, "MapChooser already loaded, aborting.");
		return APLRes_Failure;
	}
	
	RegPluginLibrary("mapchooser");	
	
	MarkNativeAsOptional("GetEngineVersion");

	CreateNative("NominateMap", Native_NominateMap);
	CreateNative("RemoveNominationByMap", Native_RemoveNominationByMap);
	CreateNative("RemoveNominationByOwner", Native_RemoveNominationByOwner);
	CreateNative("InitiateMapChooserVote", Native_InitiateVote);
	CreateNative("CanMapChooserStartVote", Native_CanVoteStart);
	CreateNative("HasEndOfMapVoteFinished", Native_CheckVoteDone);
	CreateNative("GetExcludeMapList", Native_GetExcludeMapList);
	CreateNative("GetNominatedMapList", Native_GetNominatedMapList);
	CreateNative("EndOfMapVoteEnabled", Native_EndOfMapVoteEnabled);
	
	// MapChooser Extended natives
	CreateNative("IsMapOfficial", Native_IsMapOfficial);
	CreateNative("CanNominate", Native_CanNominate);
	
	return APLRes_Success;
}

public OnAllPluginsLoaded()
{
	g_NativeVotes = LibraryExists(NV) && NativeVotes_IsVoteTypeSupported(NativeVotesType_NextLevelMult);
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, NV) && NativeVotes_IsVoteTypeSupported(NativeVotesType_NextLevelMult))
	{
		g_NativeVotes = true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, NV))
	{
		g_NativeVotes = false;
	}
}

public OnMapStart()
{
	decl String:folder[64];
	GetGameFolderName(folder, sizeof(folder));
	
	g_RoundCounting = RoundCounting_Standard;
	g_ObjectiveEnt = -1;
	
	if (strcmp(folder, "tf") == 0 && GameRules_GetProp("m_bPlayingMannVsMachine"))
	{
		g_RoundCounting = RoundCounting_MvM;
		g_ObjectiveEnt = EntIndexToEntRef(FindEntityByClassname(-1, "tf_objective_resource"));
	}
	else if (strcmp(folder, "csgo") == 0 && GetConVarInt(g_Cvar_GameType) == GameType_GunGame &&
		GetConVarInt(g_Cvar_GameMode) == GunGameMode_ArmsRace)
	{
		g_RoundCounting = RoundCounting_ArmsRace;
	}
}

public OnConfigsExecuted()
{
	if (ReadMapList(g_MapList,
					 g_mapFileSerial, 
					 "mapchooser",
					 MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_MAPSFOLDER)
		!= INVALID_HANDLE)
		
	{
		if (g_mapFileSerial == -1)
		{
			LogError("Unable to create a valid map list.");
		}
	}
	
	// Disable the next level vote in TF2 and CS:GO
	// In TF2, this has two effects: 1. Stop the next level vote (which overlaps rtv functionality).
	// 2. Stop the built-in end level vote.  This is the only thing that happens in CS:GO
	if (g_Cvar_VoteNextLevel != INVALID_HANDLE)
	{
		SetConVarBool(g_Cvar_VoteNextLevel, false);
	}
	
	CreateNextVote();
	SetupTimeleftTimer();
	
	g_TotalRounds = 0;
	
	g_Extends = 0;
	
	g_MapVoteCompleted = false;
	
	g_NominateCount = 0;
	ClearArray(g_NominateList);
	ClearArray(g_NominateOwners);
	
	for (new i=0; i<MAXTEAMS; i++)
	{
		g_winCount[i] = 0;	
	}

	/* Check if mapchooser will attempt to start mapvote during bonus round time */
	if ((g_Cvar_Bonusroundtime != INVALID_HANDLE) && !GetConVarInt(g_Cvar_StartRounds))
	{
		if (!GetConVarInt(g_Cvar_StartTime) && GetConVarFloat(g_Cvar_Bonusroundtime) <= GetConVarFloat(g_Cvar_VoteDuration))
		{
			LogError("Warning - Bonus Round Time shorter than Vote Time. Votes during bonus round may not have time to complete");
		}
	}
	
	InitializeOfficialMapList();
}

public OnMapEnd()
{
	g_HasVoteStarted = false;
	g_WaitingForVote = false;
	g_ChangeMapAtRoundEnd = false;
	g_ChangeMapInProgress = false;
	g_HasIntermissionStarted = false;
	
	g_VoteTimer = INVALID_HANDLE;
	g_RetryTimer = INVALID_HANDLE;
	g_WarningTimer = INVALID_HANDLE;
	g_RunoffCount = 0;
	
	decl String:map[PLATFORM_MAX_PATH];
	GetCurrentMap(map, PLATFORM_MAX_PATH);
	PushArrayString(g_OldMapList, map);
				
	if (GetArraySize(g_OldMapList) > GetConVarInt(g_Cvar_ExcludeMaps))
	{
		RemoveFromArray(g_OldMapList, 0);
	}	
}

public OnClientDisconnect(client)
{
	new index = FindValueInArray(g_NominateOwners, client);
	
	if (index == -1)
	{
		return;
	}
	
	new String:oldmap[PLATFORM_MAX_PATH];
	GetArrayString(g_NominateList, index, oldmap, PLATFORM_MAX_PATH);
	Call_StartForward(g_NominationsResetForward);
	Call_PushString(oldmap);
	Call_PushCell(GetArrayCell(g_NominateOwners, index));
	Call_Finish();
	
	RemoveFromArray(g_NominateOwners, index);
	RemoveFromArray(g_NominateList, index);
	g_NominateCount--;
}

public Action:Command_SetNextmap(client, args)
{
	if (args < 1)
	{
		CReplyToCommand(client, "[MCE] Usage: sm_setnextmap <map>");
		return Plugin_Handled;
	}

	decl String:map[PLATFORM_MAX_PATH];
	GetCmdArg(1, map, PLATFORM_MAX_PATH);

	if (!IsMapValid(map))
	{
		CReplyToCommand(client, "[MCE] %t", "Map was not found", map);
		return Plugin_Handled;
	}

	ShowActivity(client, "%t", "Changed Next Map", map);
	LogAction(client, -1, "\"%L\" changed nextmap to \"%s\"", client, map);

	SetNextMap(map);
	g_MapVoteCompleted = true;

	return Plugin_Handled;
}

public Action:Command_ReloadMaps(client, args)
{
	InitializeOfficialMapList();
}

public OnMapTimeLeftChanged()
{
	if (GetArraySize(g_MapList))
	{
		SetupTimeleftTimer();
	}
}

SetupTimeleftTimer()
{
	new time;
	if (GetMapTimeLeft(time) && time > 0)
	{
		new startTime;
		if (GetConVarBool(g_Cvar_StartTimePercentEnable))
		{
			new timeLimit;
			if (GetMapTimeLimit(timeLimit) && timeLimit > 0)
			{
				startTime = GetConVarInt(g_Cvar_StartTimePercent) * (timeLimit * 60) / 100;
			}
		}
		else
		{
			startTime = GetConVarInt(g_Cvar_StartTime) * 60;
		}
		
		if (time - startTime < 0 && GetConVarBool(g_Cvar_EndOfMapVote) && !g_MapVoteCompleted && !g_HasVoteStarted)
		{
			SetupWarningTimer(WarningType_Vote);
		}
		else
		{
			if (g_WarningTimer == INVALID_HANDLE)
			{
				if (g_VoteTimer != INVALID_HANDLE)
				{
					KillTimer(g_VoteTimer);
					g_VoteTimer = INVALID_HANDLE;
				}	
				
				//g_VoteTimer = CreateTimer(float(time - startTime), Timer_StartMapVoteTimer_StartMapVote, _, TIMER_FLAG_NO_MAPCHANGE);
				g_VoteTimer = CreateTimer(float(time - startTime), Timer_StartWarningTimer, _, TIMER_FLAG_NO_MAPCHANGE);
			}
		}		
	}
}

public Action:Timer_StartWarningTimer(Handle:timer)
{
	g_VoteTimer = INVALID_HANDLE;
	
	if (!g_WarningInProgress || g_WarningTimer == INVALID_HANDLE)
	{
		SetupWarningTimer(WarningType_Vote);
	}
}

public Action:Timer_StartMapVote(Handle:timer, Handle:data)
{
	static timePassed;

	// This is still necessary because InitiateVote still calls this directly via the retry timer
	if (!GetArraySize(g_MapList) || !GetConVarBool(g_Cvar_EndOfMapVote) || g_MapVoteCompleted || g_HasVoteStarted)
	{
		g_WarningTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}

	ResetPack(data);
	new warningMaxTime = ReadPackCell(data);
	new warningTimeRemaining = warningMaxTime - timePassed;

	new String:warningPhrase[32];
	ReadPackString(data, warningPhrase, sizeof(warningPhrase));
	
	// Tick timer for external plugins
	Call_StartForward(g_MapVoteWarningTickForward);
	Call_PushCell(warningTimeRemaining);
	Call_Finish();

	if (timePassed == 0 || !GetConVarBool(g_Cvar_HideTimer))
	{
		new TimerLocation:timerLocation = TimerLocation:GetConVarInt(g_Cvar_TimerLocation);
		
		switch(timerLocation)
		{
			case TimerLocation_Center:
			{
				PrintCenterTextAll("%t", warningPhrase, warningTimeRemaining);
			}
			
			case TimerLocation_Chat:
			{
				PrintToChatAll("%t", warningPhrase, warningTimeRemaining);
			}
			
			default:
			{
				PrintHintTextToAll("%t", warningPhrase, warningTimeRemaining);
			}
		}
	}

	if (timePassed++ >= warningMaxTime)
	{
		if (timer == g_RetryTimer)
		{
			g_WaitingForVote = false;
			g_RetryTimer = INVALID_HANDLE;
		}
		else
		{
			g_WarningTimer = INVALID_HANDLE;
		}
	
		timePassed = 0;
		new MapChange:mapChange = MapChange:ReadPackCell(data);
		new Handle:hndl = Handle:ReadPackCell(data);
		
		InitiateVote(mapChange, hndl);
		
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Event_TFRestartRound(Handle:event, const String:name[], bool:dontBroadcast)
{
	/* Game got restarted - reset our round count tracking */
	g_TotalRounds = 0;	
}

public Event_TeamPlayWinPanel(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_ChangeMapAtRoundEnd)
	{
		g_ChangeMapAtRoundEnd = false;
		CreateTimer(2.0, Timer_ChangeMap, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
		g_ChangeMapInProgress = true;
	}
	
	new bluescore = GetEventInt(event, "blue_score");
	new redscore = GetEventInt(event, "red_score");
		
	if(GetEventInt(event, "round_complete") == 1 || StrEqual(name, "arena_win_panel"))
	{
		g_TotalRounds++;
		
		if (!GetArraySize(g_MapList) || g_HasVoteStarted || g_MapVoteCompleted || !GetConVarBool(g_Cvar_EndOfMapVote))
		{
			return;
		}
		
		CheckMaxRounds(g_TotalRounds);
		
		switch(GetEventInt(event, "winning_team"))
		{
			case 3:
			{
				CheckWinLimit(bluescore);
			}
			case 2:
			{
				CheckWinLimit(redscore);				
			}			
			//We need to do nothing on winning_team == 0 this indicates stalemate.
			default:
			{
				return;
			}			
		}
	}
}

public Event_MvMWinPanel(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventInt(event, "winning_team") == 2)
	{
		new objectiveEnt = EntRefToEntIndex(g_ObjectiveEnt);
		if (objectiveEnt != INVALID_ENT_REFERENCE)
		{
			g_TotalRounds = GetEntProp(g_ObjectiveEnt, Prop_Send, "m_nMannVsMachineWaveCount");
			CheckMaxRounds(g_TotalRounds);
		}
	}
}

public Event_Intermission(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_HasIntermissionStarted = true;
}

public Event_PhaseEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	/* announce_phase_end fires for both half time and the end of the map, but intermission fires first for end of the map. */
	if (g_HasIntermissionStarted)
	{
		return;
	}

	/* No intermission yet, so this must be half time. Swap the score counters. */
	new t_score = g_winCount[2];
	g_winCount[2] =  g_winCount[3];
	g_winCount[3] = t_score;
}
 
public Event_WeaponRank(Handle:event, const String:name[], bool:dontBroadcast)
{
	new rank = GetEventInt(event, "weaponrank");
	if (rank > g_TotalRounds)
	{
		g_TotalRounds = rank;
		CheckMaxRounds(g_TotalRounds);
	}
}

/* You ask, why don't you just use team_score event? And I answer... Because CSS doesn't. */
public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_RoundCounting == RoundCounting_ArmsRace)
	{
		return;
	}
	
	if (g_ChangeMapAtRoundEnd)
	{
		g_ChangeMapAtRoundEnd = false;
		CreateTimer(2.0, Timer_ChangeMap, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
		g_ChangeMapInProgress = true;
	}
	
	new winner;
	if (strcmp(name, "round_win") == 0 || strcmp(name, "dod_round_win") == 0)
	{
		// Nuclear Dawn & DoD:S
		winner = GetEventInt(event, "team");
	}
	else
	{
		winner = GetEventInt(event, "winner");
	}
	
	if (winner == 0 || winner == 1 || !GetConVarBool(g_Cvar_EndOfMapVote))
	{
		return;
	}
	
	if (winner >= MAXTEAMS)
	{
		SetFailState("Mod exceed maximum team count - Please file a bug report.");	
	}

	g_TotalRounds++;
	
	g_winCount[winner]++;
	
	if (!GetArraySize(g_MapList) || g_HasVoteStarted || g_MapVoteCompleted)
	{
		return;
	}
	
	CheckWinLimit(g_winCount[winner]);
	CheckMaxRounds(g_TotalRounds);
}

public CheckWinLimit(winner_score)
{	
	if (g_Cvar_Winlimit != INVALID_HANDLE)
	{
		new winlimit = GetConVarInt(g_Cvar_Winlimit);
		if (winlimit)
		{			
			if (winner_score >= (winlimit - GetConVarInt(g_Cvar_StartRounds)))
			{
				if (!g_WarningInProgress || g_WarningTimer == INVALID_HANDLE)
				{
					SetupWarningTimer(WarningType_Vote, MapChange_MapEnd);
					//InitiateVote(MapChange_MapEnd, INVALID_HANDLE);
				}
			}
		}
	}
	
	if (g_Cvar_MatchClinch != INVALID_HANDLE && g_Cvar_Maxrounds != INVALID_HANDLE)
	{
		new bool:clinch = GetConVarBool(g_Cvar_MatchClinch);
		
		if (clinch)
		{
			new maxrounds = GetConVarInt(g_Cvar_Maxrounds);
			new winlimit = RoundFloat(maxrounds / 2.0);
			
			if(winner_score == winlimit - 1)
			{
				if (!g_WarningInProgress || g_WarningTimer == INVALID_HANDLE)
				{
					SetupWarningTimer(WarningType_Vote, MapChange_MapEnd);
					//InitiateVote(MapChange_MapEnd, INVALID_HANDLE);
				}
			}
		}
	}
}

public CheckMaxRounds(roundcount)
{
	new maxrounds = 0;
	
	if (g_RoundCounting == RoundCounting_ArmsRace)
	{
		maxrounds = GameRules_GetProp("m_iNumGunGameProgressiveWeaponsCT");
	}
	else if (g_RoundCounting == RoundCounting_MvM)
	{
		maxrounds = GetEntProp(g_ObjectiveEnt, Prop_Send, "m_nMannVsMachineMaxWaveCount");
	}
	else if (g_Cvar_Maxrounds != INVALID_HANDLE)
	{
		maxrounds = GetConVarInt(g_Cvar_Maxrounds);
	}
	else
	{
		return;
	}
	
	if (maxrounds)
	{
		if (roundcount >= (maxrounds - GetConVarInt(g_Cvar_StartRounds)))
		{
			if (!g_WarningInProgress || g_WarningTimer == INVALID_HANDLE)
			{
				SetupWarningTimer(WarningType_Vote, MapChange_MapEnd);
				//InitiateVote(MapChange_MapEnd, INVALID_HANDLE);
			}
		}
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetArraySize(g_MapList) || g_Cvar_Fraglimit == INVALID_HANDLE || g_HasVoteStarted)
	{
		return;
	}
	
	if (!GetConVarInt(g_Cvar_Fraglimit) || !GetConVarBool(g_Cvar_EndOfMapVote))
	{
		return;
	}

	if (g_MapVoteCompleted)
	{
		return;
	}

	new fragger = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!fragger)
	{
		return;
	}

	if (GetClientFrags(fragger) >= (GetConVarInt(g_Cvar_Fraglimit) - GetConVarInt(g_Cvar_StartFrags)))
	{
		if (!g_WarningInProgress || g_WarningTimer == INVALID_HANDLE)
		{
			SetupWarningTimer(WarningType_Vote, MapChange_MapEnd);
			//InitiateVote(MapChange_MapEnd, INVALID_HANDLE);
		}
	}
}

public Action:Command_Mapvote(client, args)
{
	ShowActivity2(client, "[MCE] ", "%t", "Initiated Vote Map");

	SetupWarningTimer(WarningType_Vote, MapChange_MapEnd, INVALID_HANDLE, true);

	//InitiateVote(MapChange_MapEnd, INVALID_HANDLE);

	return Plugin_Handled;	
}

/**
 * Starts a new map vote
 *
 * @param when			When the resulting map change should occur.
 * @param inputlist		Optional list of maps to use for the vote, otherwise an internal list of nominations + random maps will be used.
 */
InitiateVote(MapChange:when, Handle:inputlist=INVALID_HANDLE)
{
	g_WaitingForVote = true;
	g_WarningInProgress = false;
 
	// Check if a nativevotes vots is in progress first
	// NativeVotes running at the same time as a regular vote can cause hintbox problems,
	// so always check for a standard vote
	if (IsVoteInProgress() || (g_NativeVotes && NativeVotes_IsVoteInProgress()))
	{
		// Can't start a vote, try again in 5 seconds.
		//g_RetryTimer = CreateTimer(5.0, Timer_StartMapVote, _, TIMER_FLAG_NO_MAPCHANGE);
		
		CPrintToChatAll("[MCE] %t", "Cannot Start Vote", FAILURE_TIMER_LENGTH);
		new Handle:data;
		g_RetryTimer = CreateDataTimer(1.0, Timer_StartMapVote, data, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
		
		/* Mapchooser Extended */
		WritePackCell(data, FAILURE_TIMER_LENGTH);

		if (GetConVarBool(g_Cvar_RunOff) && g_RunoffCount > 0)
		{
			WritePackString(data, "Revote Warning");
		} else {
			WritePackString(data, "Vote Warning");
		}
		/* End Mapchooser Extended */

		WritePackCell(data, _:when);
		WritePackCell(data, _:inputlist);
		ResetPack(data);
		return;
	}
	
	/* If the main map vote has completed (and chosen result) and its currently changing (not a delayed change) we block further attempts */
	if (g_MapVoteCompleted && g_ChangeMapInProgress)
	{
		return;
	}
	
	g_ChangeTime = when;
	
	g_WaitingForVote = false;
		
	g_HasVoteStarted = true;
	
	if (g_NativeVotes)
	{
		g_VoteMenu = NativeVotes_Create(Handler_MapVoteMenu, NativeVotesType_NextLevelMult, MenuAction_End | MenuAction_VoteCancel | MenuAction_Display | MenuAction_DisplayItem);
		NativeVotes_SetResultCallback(g_VoteMenu, Handler_NativeVoteFinished);
	}
	else
	{
		new Handle:menuStyle = GetMenuStyleHandle(MenuStyle:GetConVarInt(g_Cvar_MenuStyle));
		
		if (menuStyle != INVALID_HANDLE)
		{
			g_VoteMenu = CreateMenuEx(menuStyle, Handler_MapVoteMenu, MenuAction_End | MenuAction_Display | MenuAction_DisplayItem | MenuAction_VoteCancel);
		}
		else
		{
			// You chose... poorly
			g_VoteMenu = CreateMenu(Handler_MapVoteMenu, MenuAction_End | MenuAction_Display | MenuAction_DisplayItem | MenuAction_VoteCancel);
		}

		g_AddNoVote = GetConVarBool(g_Cvar_NoVoteOption);
		
		// Block Vote Slots
		if (GetConVarBool(g_Cvar_BlockSlots))
		{
			new Handle:radioStyle = GetMenuStyleHandle(MenuStyle_Radio);
			
			if (GetMenuStyle(g_VoteMenu) == radioStyle)
			{
				g_BlockedSlots = true;
				AddMenuItem(g_VoteMenu, LINE_ONE, "Choose something...", ITEMDRAW_DISABLED);
				AddMenuItem(g_VoteMenu, LINE_TWO, "...will ya?", ITEMDRAW_DISABLED);
				if (!g_AddNoVote)
				{
					AddMenuItem(g_VoteMenu, LINE_SPACER, "", ITEMDRAW_SPACER);
				}
			} else {
				g_BlockedSlots = false;
			}
		}
		
		if (g_AddNoVote)
		{
			SetMenuOptionFlags(g_VoteMenu, MENUFLAG_BUTTON_NOVOTE);
		}
		
		SetMenuTitle(g_VoteMenu, "Vote Nextmap");
		SetVoteResultCallback(g_VoteMenu, Handler_MapVoteFinished);
	}

	/* Call OnMapVoteStarted() Forward */
//	Call_StartForward(g_MapVoteStartedForward);
//	Call_Finish();

	/**
	 * TODO: Make a proper decision on when to clear the nominations list.
	 * Currently it clears when used, and stays if an external list is provided.
	 * Is this the right thing to do? External lists will probably come from places
	 * like sm_mapvote from the adminmenu in the future.
	 */
	 
	decl String:map[PLATFORM_MAX_PATH];
	
	/* No input given - User our internal nominations and maplist */
	if (inputlist == INVALID_HANDLE)
	{
		new Handle:randomizeList = INVALID_HANDLE;
		if (GetConVarBool(g_Cvar_RandomizeNominations))
		{
			randomizeList = CloneArray(g_NominateList);
		}
		
		new nominateCount = GetArraySize(g_NominateList);
		
		new voteSize = GetVoteSize();
		
		// The if and else if could be combined, but it looks extremely messy
		// This is a hack to lower the vote menu size by 1 when Don't Change or Extend Map should appear
		if (g_NativeVotes)
		{
			if ((when == MapChange_Instant || when == MapChange_RoundEnd) && GetConVarBool(g_Cvar_DontChange))
			{
				voteSize--;
			}
			else if (GetConVarBool(g_Cvar_Extend) && g_Extends < GetConVarInt(g_Cvar_Extend))
			{
				voteSize--;
			}
		}
		
		/* Smaller of the two - It should be impossible for nominations to exceed the size though (cvar changed mid-map?) */
		new nominationsToAdd = nominateCount >= voteSize ? voteSize : nominateCount;
		
		new bool:extendFirst = GetConVarBool(g_Cvar_ExtendPosition);
		
		if (extendFirst)
		{
			AddExtendToMenu(g_VoteMenu, when);
		}
		
		for (new i=0; i<nominationsToAdd; i++)
		{
			GetArrayString(g_NominateList, i, map, PLATFORM_MAX_PATH);
			
			if (randomizeList == INVALID_HANDLE)
			{
				AddMapItem(map);
			}
			RemoveStringFromArray(g_NextMapList, map);
			
			/* Notify Nominations that this map is now free */
			Call_StartForward(g_NominationsResetForward);
			Call_PushString(map);
			Call_PushCell(GetArrayCell(g_NominateOwners, i));
			Call_Finish();
		}
		
		/* Clear out the rest of the nominations array */
		for (new i=nominationsToAdd; i<nominateCount; i++)
		{
			GetArrayString(g_NominateList, i, map, PLATFORM_MAX_PATH);
			/* These maps shouldn't be excluded from the vote as they weren't really nominated at all */
			
			/* Notify Nominations that this map is now free */
			Call_StartForward(g_NominationsResetForward);
			Call_PushString(map);
			Call_PushCell(GetArrayCell(g_NominateOwners, i));
			Call_Finish();
		}
		
		/* There should currently be 'nominationsToAdd' unique maps in the vote */
		
		new i = nominationsToAdd;
		new count = 0;
		new availableMaps = GetArraySize(g_NextMapList);
		
		if (i < voteSize && availableMaps == 0)
		{
			if (i == 0)
			{
				LogError("No maps available for vote.");
				return;
			}
			else
			{
				LogMessage("Not enough maps to fill map list, reducing map count. Adjust mce_include and mce_exclude to avoid this warning.");
				voteSize = i;
			}
		}
		
		while (i < voteSize)
		{
			GetArrayString(g_NextMapList, count, map, PLATFORM_MAX_PATH);
			count++;
			
			if (randomizeList == INVALID_HANDLE)
			{
				/* Insert the map and increment our count */
				AddMapItem(map);
			}
			else
			{
				PushArrayString(randomizeList, map);
			}
			i++;
			
			if (count >= availableMaps)
			{
				//Run out of maps, this will have to do.
				break;	
			}
		}
		
		if (randomizeList != INVALID_HANDLE)
		{
			// Fisher-Yates Shuffle
			for (new j = GetArraySize(randomizeList) - 1; j >= 1; j--)
			{
				new k = GetRandomInt(0, j);
				SwapArrayItems(randomizeList, j, k);
			}
			
			for (new j = 0; j < GetArraySize(randomizeList); j++)
			{
				GetArrayString(randomizeList, j, map, PLATFORM_MAX_PATH);
				AddMapItem(map);
			}
			
			CloseHandle(randomizeList);
			randomizeList = INVALID_HANDLE;
		}
		
		/* Wipe out our nominations list - Nominations have already been informed of this */
		g_NominateCount = 0;
		ClearArray(g_NominateOwners);
		ClearArray(g_NominateList);
		
		if (!extendFirst)
		{
			AddExtendToMenu(g_VoteMenu, when);
		}
	}
	else //We were given a list of maps to start the vote with
	{
		new size = GetArraySize(inputlist);
		
		for (new i=0; i<size; i++)
		{
			GetArrayString(inputlist, i, map, PLATFORM_MAX_PATH);
			
			if (IsMapValid(map))
			{
				AddMapItem(map);
			}
			// New in Mapchooser Extended
			else if (StrEqual(map, VOTE_DONTCHANGE))
			{
				if (g_NativeVotes)
				{
					NativeVotes_AddItem(g_VoteMenu, VOTE_DONTCHANGE, "Don't Change");
				}
				else
				{
					AddMenuItem(g_VoteMenu, VOTE_DONTCHANGE, "Don't Change");
				}
			}
			else if (StrEqual(map, VOTE_EXTEND))
			{
				if (g_NativeVotes)
				{
					NativeVotes_AddItem(g_VoteMenu, VOTE_EXTEND, "Extend Map");
				}
				else
				{
					AddMenuItem(g_VoteMenu, VOTE_EXTEND, "Extend Map");
				}
			}
		}
		CloseHandle(inputlist);
	}
	
	new voteDuration = GetConVarInt(g_Cvar_VoteDuration);

	if (g_NativeVotes)
	{
		NativeVotes_DisplayToAll(g_VoteMenu, voteDuration);
	}
	else
	{
		//SetMenuExitButton(g_VoteMenu, false);
		
		if (GetVoteSize() <= GetMaxPageItems(GetMenuStyle(g_VoteMenu)))
		{
			//This is necessary to get items 9 and 0 as usable voting items
			SetMenuPagination(g_VoteMenu, MENU_NO_PAGINATION);
		}
		
		VoteMenuToAll(g_VoteMenu, voteDuration);
	}

	/* Call OnMapVoteStarted() Forward */
	Call_StartForward(g_MapVoteStartForward); // Deprecated
	Call_Finish();

	Call_StartForward(g_MapVoteStartedForward);
	Call_Finish();

	LogAction(-1, -1, "Voting for next map has started.");
	CPrintToChatAll("[MCE] %t", "Nextmap Voting Started");
}

public Handler_NativeVoteFinished(Handle:vote,
							num_votes, 
							num_clients,
							const client_indexes[],
							const client_votes[],
							num_items,
							const item_indexes[],
							const item_votes[])
{
	new client_info[num_clients][2];
	new item_info[num_items][2];
	
	NativeVotes_FixResults(num_clients, client_indexes, client_votes, num_items, item_indexes, item_votes, client_info, item_info);
	Handler_MapVoteFinished(vote, num_votes, num_clients, client_info, num_items, item_info);
}


public Handler_VoteFinishedGeneric(Handle:menu,
						   num_votes, 
						   num_clients,
						   const client_info[][2], 
						   num_items,
						   const item_info[][2])
{
	decl String:map[PLATFORM_MAX_PATH];
	GetMapItem(menu, item_info[0][VOTEINFO_ITEM_INDEX], map, PLATFORM_MAX_PATH);

	Call_StartForward(g_MapVoteEndForward);
	Call_PushString(map);
	Call_Finish();

	if (strcmp(map, VOTE_EXTEND, false) == 0)
	{
		g_Extends++;
		
		new time;
		if (GetMapTimeLimit(time))
		{
			if (time > 0)
			{
				ExtendMapTimeLimit(GetConVarInt(g_Cvar_ExtendTimeStep)*60);						
			}
		}
		
		if (g_Cvar_Winlimit != INVALID_HANDLE)
		{
			new winlimit = GetConVarInt(g_Cvar_Winlimit);
			if (winlimit)
			{
				SetConVarInt(g_Cvar_Winlimit, winlimit + GetConVarInt(g_Cvar_ExtendRoundStep));
			}					
		}
		
		if (g_Cvar_Maxrounds != INVALID_HANDLE)
		{
			new maxrounds = GetConVarInt(g_Cvar_Maxrounds);
			if (maxrounds)
			{
				SetConVarInt(g_Cvar_Maxrounds, maxrounds + GetConVarInt(g_Cvar_ExtendRoundStep));
			}
		}
		
		if (g_Cvar_Fraglimit != INVALID_HANDLE)
		{
			new fraglimit = GetConVarInt(g_Cvar_Fraglimit);
			if (fraglimit)
			{
				SetConVarInt(g_Cvar_Fraglimit, fraglimit + GetConVarInt(g_Cvar_ExtendFragStep));						
			}
		}

		if (g_NativeVotes)
		{
			NativeVotes_DisplayPassEx(menu, NativeVotesPass_Extend);
		}
		
		CPrintToChatAll("[MCE] %t", "Current Map Extended", RoundToFloor(float(item_info[0][VOTEINFO_ITEM_VOTES])/float(num_votes)*100), num_votes);
		LogAction(-1, -1, "Voting for next map has finished. The current map has been extended.");
		
		// We extended, so we'll have to vote again.
		g_HasVoteStarted = false;
		CreateNextVote();
		SetupTimeleftTimer();

	}
	else if (strcmp(map, VOTE_DONTCHANGE, false) == 0)
	{
		if (g_NativeVotes)
		{
			NativeVotes_DisplayPassEx(menu, NativeVotesPass_Extend);
		}
		
		CPrintToChatAll("[MCE] %t", "Current Map Stays", RoundToFloor(float(item_info[0][VOTEINFO_ITEM_VOTES])/float(num_votes)*100), num_votes);
		LogAction(-1, -1, "Voting for next map has finished. 'No Change' was the winner");
		
		g_HasVoteStarted = false;
		CreateNextVote();
		SetupTimeleftTimer();
	}
	else
	{
		if (g_ChangeTime == MapChange_MapEnd)
		{
			SetNextMap(map);
			if (g_NativeVotes)
			{
				NativeVotes_DisplayPass(menu, map);
			}
		}
		else if (g_ChangeTime == MapChange_Instant)
		{
			new Handle:data;
			CreateDataTimer(4.0, Timer_ChangeMap, data);
			WritePackString(data, map);
			g_ChangeMapInProgress = false;
			if (g_NativeVotes)
			{
				NativeVotes_DisplayPassEx(menu, NativeVotesPass_ChgLevel, map);
			}
		}
		else // MapChange_RoundEnd
		{
			SetNextMap(map);
			g_ChangeMapAtRoundEnd = true;
			
			if (g_NativeVotes)
			{
				NativeVotes_DisplayPass(menu, map);
			}
		}
		
		g_HasVoteStarted = false;
		g_MapVoteCompleted = true;
		
		CPrintToChatAll("[MCE] %t", "Nextmap Voting Finished", map, RoundToFloor(float(item_info[0][VOTEINFO_ITEM_VOTES])/float(num_votes)*100), num_votes);
		LogAction(-1, -1, "Voting for next map has finished. Nextmap: %s.", map);
	}	
}

public Handler_MapVoteFinished(Handle:menu,
						   num_votes, 
						   num_clients,
						   const client_info[][2], 
						   num_items,
						   const item_info[][2])
{
	// Implement revote logic - Only run this` block if revotes are enabled and this isn't the last revote
	if (GetConVarBool(g_Cvar_RunOff) && num_items > 1 && g_RunoffCount < GetConVarInt(g_Cvar_MaxRunOffs))
	{
		g_RunoffCount++;
		new highest_votes = item_info[0][VOTEINFO_ITEM_VOTES];
		new required_percent = GetConVarInt(g_Cvar_RunOffPercent);
		new required_votes = RoundToCeil(float(num_votes) * float(required_percent) / 100);
		
		if (highest_votes == item_info[1][VOTEINFO_ITEM_VOTES])
		{
			g_HasVoteStarted = false;
			
			//Revote is needed
			new arraySize = ByteCountToCells(PLATFORM_MAX_PATH);
			new Handle:mapList = CreateArray(arraySize);

			for (new i = 0; i < num_items; i++)
			{
				if (item_info[i][VOTEINFO_ITEM_VOTES] == highest_votes)
				{
					decl String:map[PLATFORM_MAX_PATH];
					
					GetMapItem(menu, item_info[i][VOTEINFO_ITEM_INDEX], map, PLATFORM_MAX_PATH);
					PushArrayString(mapList, map);
				}
				else
				{
					break;
				}
			}

			if (g_NativeVotes)
			{
				NativeVotes_DisplayFail(menu, NativeVotesFail_NotEnoughVotes);
			}
			
			CPrintToChatAll("[MCE] %t", "Tie Vote", GetArraySize(mapList));
			SetupWarningTimer(WarningType_Revote, MapChange:g_ChangeTime, mapList);
			return;
		}
		else if (highest_votes < required_votes)
		{
			g_HasVoteStarted = false;
			
			//Revote is needed
			new arraySize = ByteCountToCells(PLATFORM_MAX_PATH);
			new Handle:mapList = CreateArray(arraySize);

			decl String:map1[PLATFORM_MAX_PATH];
			GetMapItem(menu, item_info[0][VOTEINFO_ITEM_INDEX], map1, PLATFORM_MAX_PATH);

			PushArrayString(mapList, map1);

			// We allow more than two maps for a revote if they are tied
			for (new i = 1; i < num_items; i++)
			{
				if (GetArraySize(mapList) < 2 || item_info[i][VOTEINFO_ITEM_VOTES] == item_info[i - 1][VOTEINFO_ITEM_VOTES])
				{
					decl String:map[PLATFORM_MAX_PATH];
					GetMapItem(menu, item_info[i][VOTEINFO_ITEM_INDEX], map, PLATFORM_MAX_PATH);
					PushArrayString(mapList, map);
				}
				else
				{
					break;
				}
			}
			
			if (g_NativeVotes)
			{
				NativeVotes_DisplayFail(menu, NativeVotesFail_NotEnoughVotes);
			}
			
			CPrintToChatAll("[MCE] %t", "Revote Is Needed", required_percent);
			SetupWarningTimer(WarningType_Revote, MapChange:g_ChangeTime, mapList);
			return;
		}
	}
	
	// No revote needed, continue as normal.
	Handler_VoteFinishedGeneric(menu, num_votes, num_clients, client_info, num_items, item_info);
}

// This is shared by NativeVotes now, but NV doesn't support Display or DisplayItem
public Handler_MapVoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			g_VoteMenu = INVALID_HANDLE;
			if (g_NativeVotes)
			{
				NativeVotes_Close(menu);
			}
			else
			{
				CloseHandle(menu);
			}
		}
		
		case MenuAction_Display:
		{
			// NativeVotes uses the standard TF2/CSGO vote screen
			if (!g_NativeVotes)
			{
				decl String:buffer[255];
				Format(buffer, sizeof(buffer), "%T", "Vote Nextmap", param1);
				new Handle:panel = Handle:param2;
				SetPanelTitle(panel, buffer);
			}
		}
		
		case MenuAction_DisplayItem:
		{
			new String:map[PLATFORM_MAX_PATH];
			new String:buffer[255];
			new mark = GetConVarInt(g_Cvar_MarkCustomMaps);
			
			if (g_NativeVotes)
			{
				NativeVotes_GetItem(menu, param2, map, PLATFORM_MAX_PATH);
			}
			else
			{
				GetMenuItem(menu, param2, map, PLATFORM_MAX_PATH);
			}
			
			if (StrEqual(map, VOTE_EXTEND, false))
			{
				Format(buffer, sizeof(buffer), "%T", "Extend Map", param1);
			}
			else if (StrEqual(map, VOTE_DONTCHANGE, false))
			{
				Format(buffer, sizeof(buffer), "%T", "Dont Change", param1);
			}
			// Mapchooser Extended
			else if (StrEqual(map, LINE_ONE, false))
			{
				Format(buffer, sizeof(buffer),"%T", "Line One", param1);
			}
			else if (StrEqual(map, LINE_TWO, false))
			{
				Format(buffer, sizeof(buffer),"%T", "Line Two", param1);
			}
			// Note that the first part is to discard the spacer line
			else if (!StrEqual(map, LINE_SPACER, false))
			{
				if (mark == 1 && !InternalIsMapOfficial(map))
				{
					Format(buffer, sizeof(buffer), "%T", "Custom Marked", param1, map);
				}
				else if (mark == 2 && !InternalIsMapOfficial(map))
				{
					Format(buffer, sizeof(buffer), "%T", "Custom", param1, map);
				}
			}
			
			if (buffer[0] != '\0')
			{
				if (g_NativeVotes)
				{
					NativeVotes_RedrawVoteItem(buffer);
					return _:Plugin_Continue;
				}
				else
				{
					return RedrawMenuItem(buffer);
				}
			}
			// End Mapchooser Extended
		}		
	
		case MenuAction_VoteCancel:
		{
			// If we receive 0 votes, pick at random.
			if (param1 == VoteCancel_NoVotes && GetConVarBool(g_Cvar_NoVoteMode))
			{
				new count;
				if (g_NativeVotes)
				{
					count = NativeVotes_GetItemCount(menu);
				}
				else
				{
					count = GetMenuItemCount(menu);
				}
				
				decl item;
				decl String:map[PLATFORM_MAX_PATH];
				
				do
				{
					new startInt = 0;
					if (!g_NativeVotes && g_BlockedSlots)
					{
						if (g_AddNoVote)
						{
							startInt = 2;
						}
						else
						{
							startInt = 3;
						}
					}
					item = GetRandomInt(startInt, count - 1);
					if (g_NativeVotes)
					{
						NativeVotes_GetItem(menu, item, map, PLATFORM_MAX_PATH);
					}
					else
					{
						GetMenuItem(menu, item, map, PLATFORM_MAX_PATH);
					}
				}
				while (strcmp(map, VOTE_EXTEND, false) == 0);
				
				SetNextMap(map);
				g_MapVoteCompleted = true;
				
				if (g_NativeVotes)
				{
					NativeVotes_DisplayPass(menu, map);
				}
			}
			else if (g_NativeVotes)
			{
				new NativeVotesFailType:reason = NativeVotesFail_Generic;
				if (param1 == VoteCancel_NoVotes)
				{
					reason = NativeVotesFail_NotEnoughVotes;
				}
				
				NativeVotes_DisplayFail(menu, reason);
			}
			else
			{
				// We were actually cancelled. I guess we do nothing.
			}
			
			g_HasVoteStarted = false;
		}
	}
	
	return 0;
}

public Action:Timer_ChangeMap(Handle:hTimer, Handle:dp)
{
	g_ChangeMapInProgress = false;
	
	new String:map[PLATFORM_MAX_PATH];
	
	if (dp == INVALID_HANDLE)
	{
		if (!GetNextMap(map, PLATFORM_MAX_PATH))
		{
			//No passed map and no set nextmap. fail!
			return Plugin_Stop;	
		}
	}
	else
	{
		ResetPack(dp);
		ReadPackString(dp, map, PLATFORM_MAX_PATH);
	}
	
	ForceChangeLevel(map, "Map Vote");
	
	return Plugin_Stop;
}

bool:RemoveStringFromArray(Handle:array, String:str[])
{
	new index = FindStringInArray(array, str);
	if (index != -1)
	{
		RemoveFromArray(array, index);
		return true;
	}
	
	return false;
}

CreateNextVote()
{
	assert(g_NextMapList)
	ClearArray(g_NextMapList);
	
	decl String:map[PLATFORM_MAX_PATH];
	new Handle:tempMaps  = CloneArray(g_MapList);
	
	GetCurrentMap(map, PLATFORM_MAX_PATH);
	RemoveStringFromArray(tempMaps, map);
	
	if (GetConVarInt(g_Cvar_ExcludeMaps) && GetArraySize(tempMaps) > GetConVarInt(g_Cvar_ExcludeMaps))
	{
		for (new i = 0; i < GetArraySize(g_OldMapList); i++)
		{
			GetArrayString(g_OldMapList, i, map, PLATFORM_MAX_PATH);
			RemoveStringFromArray(tempMaps, map);
		}	
	}

	new voteSize = GetVoteSize();
	new limit = (voteSize < GetArraySize(tempMaps) ? voteSize : GetArraySize(tempMaps));
	
	for (new i = 0; i < limit; i++)
	{
		new b = GetRandomInt(0, GetArraySize(tempMaps) - 1);
		GetArrayString(tempMaps, b, map, PLATFORM_MAX_PATH);
		PushArrayString(g_NextMapList, map);
		RemoveFromArray(tempMaps, b);
	}
	
	CloseHandle(tempMaps);
}

bool:CanVoteStart()
{
	if (g_WaitingForVote || g_HasVoteStarted)
	{
		return false;	
	}
	
	return true;
}

NominateResult:InternalNominateMap(String:map[], bool:force, owner)
{
	if (!IsMapValid(map))
	{
		return Nominate_InvalidMap;
	}
	
	/* Map already in the vote */
	if (FindStringInArray(g_NominateList, map) != -1)
	{
		return Nominate_AlreadyInVote;	
	}
	
	new index;

	/* Look to replace an existing nomination by this client - Nominations made with owner = 0 aren't replaced */
	if (owner && ((index = FindValueInArray(g_NominateOwners, owner)) != -1))
	{
		new String:oldmap[PLATFORM_MAX_PATH];
		GetArrayString(g_NominateList, index, oldmap, PLATFORM_MAX_PATH);
		Call_StartForward(g_NominationsResetForward);
		Call_PushString(oldmap);
		Call_PushCell(owner);
		Call_Finish();
		
		SetArrayString(g_NominateList, index, map);
		return Nominate_Replaced;
	}
	
	/* Too many nominated maps. */
	if (g_NominateCount >= GetVoteSize() && !force)
	{
		return Nominate_VoteFull;
	}
	
	PushArrayString(g_NominateList, map);
	PushArrayCell(g_NominateOwners, owner);
	g_NominateCount++;
	
	while (GetArraySize(g_NominateList) > GetVoteSize())
	{
		new String:oldmap[PLATFORM_MAX_PATH];
		GetArrayString(g_NominateList, 0, oldmap, PLATFORM_MAX_PATH);
		Call_StartForward(g_NominationsResetForward);
		Call_PushString(oldmap);
		Call_PushCell(GetArrayCell(g_NominateOwners, 0));
		Call_Finish();
		
		RemoveFromArray(g_NominateList, 0);
		RemoveFromArray(g_NominateOwners, 0);
	}
	
	return Nominate_Added;
}

/* Add natives to allow nominate and initiate vote to be call */

/* native  bool:NominateMap(const String:map[], bool:force, &NominateError:error); */
public Native_NominateMap(Handle:plugin, numParams)
{
	new len;
	GetNativeStringLength(1, len);
	
	if (len <= 0)
	{
	  return false;
	}
	
	new String:map[len+1];
	GetNativeString(1, map, len+1);
	
	return _:InternalNominateMap(map, GetNativeCell(2), GetNativeCell(3));
}

bool:InternalRemoveNominationByMap(String:map[])
{	
	for (new i = 0; i < GetArraySize(g_NominateList); i++)
	{
		new String:oldmap[PLATFORM_MAX_PATH];
		GetArrayString(g_NominateList, i, oldmap, PLATFORM_MAX_PATH);

		if(strcmp(map, oldmap, false) == 0)
		{
			Call_StartForward(g_NominationsResetForward);
			Call_PushString(oldmap);
			Call_PushCell(GetArrayCell(g_NominateOwners, i));
			Call_Finish();

			RemoveFromArray(g_NominateList, i);
			RemoveFromArray(g_NominateOwners, i);
			g_NominateCount--;

			return true;
		}
	}
	
	return false;
}

/* native  bool:RemoveNominationByMap(const String:map[]); */
public Native_RemoveNominationByMap(Handle:plugin, numParams)
{
	new len;
	GetNativeStringLength(1, len);
	
	if (len <= 0)
	{
	  return false;
	}
	
	new String:map[len+1];
	GetNativeString(1, map, len+1);
	
	return _:InternalRemoveNominationByMap(map);
}

bool:InternalRemoveNominationByOwner(owner)
{	
	new index;

	if (owner && ((index = FindValueInArray(g_NominateOwners, owner)) != -1))
	{
		new String:oldmap[PLATFORM_MAX_PATH];
		GetArrayString(g_NominateList, index, oldmap, PLATFORM_MAX_PATH);

		Call_StartForward(g_NominationsResetForward);
		Call_PushString(oldmap);
		Call_PushCell(owner);
		Call_Finish();

		RemoveFromArray(g_NominateList, index);
		RemoveFromArray(g_NominateOwners, index);
		g_NominateCount--;

		return true;
	}
	
	return false;
}

/* native  bool:RemoveNominationByOwner(owner); */
public Native_RemoveNominationByOwner(Handle:plugin, numParams)
{	
	return _:InternalRemoveNominationByOwner(GetNativeCell(1));
}

/* native InitiateMapChooserVote(); */
public Native_InitiateVote(Handle:plugin, numParams)
{
	new MapChange:when = MapChange:GetNativeCell(1);
	new Handle:inputarray = Handle:GetNativeCell(2);
	
	LogAction(-1, -1, "Starting map vote because outside request");

	SetupWarningTimer(WarningType_Vote, when, inputarray);
	//InitiateVote(when, inputarray);
}

public Native_CanVoteStart(Handle:plugin, numParams)
{
	return CanVoteStart();	
}

public Native_CheckVoteDone(Handle:plugin, numParams)
{
	return g_MapVoteCompleted;
}

public Native_EndOfMapVoteEnabled(Handle:plugin, numParams)
{
	return GetConVarBool(g_Cvar_EndOfMapVote);
}

public Native_GetExcludeMapList(Handle:plugin, numParams)
{
	new Handle:array = Handle:GetNativeCell(1);
	
	if (array == INVALID_HANDLE)
	{
		return;	
	}
	new size = GetArraySize(g_OldMapList);
	decl String:map[PLATFORM_MAX_PATH];
	
	for (new i=0; i<size; i++)
	{
		GetArrayString(g_OldMapList, i, map, PLATFORM_MAX_PATH);
		PushArrayString(array, map);	
	}
	
	return;
}

public Native_GetNominatedMapList(Handle:plugin, numParams)
{
	new Handle:maparray = Handle:GetNativeCell(1);
	new Handle:ownerarray = Handle:GetNativeCell(2);
	
	if (maparray == INVALID_HANDLE)
		return;

	decl String:map[PLATFORM_MAX_PATH];

	for (new i = 0; i < GetArraySize(g_NominateList); i++)
	{
		GetArrayString(g_NominateList, i, map, PLATFORM_MAX_PATH);
		PushArrayString(maparray, map);

		// If the optional parameter for an owner list was passed, then we need to fill that out as well
		if(ownerarray != INVALID_HANDLE)
		{
			new index = GetArrayCell(g_NominateOwners, i);
			PushArrayCell(ownerarray, index);
		}
	}

	return;
}

// Functions new to Mapchooser Extended

/*
SetupWarningTimer(MapChange:when=MapChange_MapEnd, Handle:mapList=INVALID_HANDLE)
{
	if (!IsMapEndVoteAllowed())
	{
		return;
	}

	Call_StartForward(g_MapVoteWarningStartForward);
	Call_Finish();

	new Handle:data;
	g_WarningTimer = CreateDataTimer(1.0, Timer_StartMapVote, data, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	WritePackCell(data, GetConVarInt(g_Cvar_WarningTime));
	WritePackString(data, "Vote Warning");
	WritePackCell(data, _:when);
	WritePackCell(data, _:mapList);
}

SetupRunoffTimer(MapChange:when, Handle:mapList)
{
	if (!IsMapEndVoteAllowed())
	{
		return;
	}

	Call_StartForward(g_MapVoteRunoffStartForward);
	Call_Finish();

	new Handle:data;
	g_WarningTimer = CreateDataTimer(1.0, Timer_StartMapVote, data, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	WritePackCell(data, GetConVarInt(g_Cvar_RunOffWarningTime));
	WritePackString(data, "Revote Warning");
	WritePackCell(data, _:when);
	WritePackCell(data, _:mapList);
}
*/

stock SetupWarningTimer(WarningType:type, MapChange:when=MapChange_MapEnd, Handle:mapList=INVALID_HANDLE, bool:force=false)
{
	if (!GetArraySize(g_MapList) || g_ChangeMapInProgress || g_HasVoteStarted || (!force && ((when == MapChange_MapEnd && !GetConVarBool(g_Cvar_EndOfMapVote)) || g_MapVoteCompleted)))
	{
		return;
	}
	
	new bool:interrupted = false;
	if (g_WarningInProgress && g_WarningTimer != INVALID_HANDLE)
	{
		interrupted = true;
		KillTimer(g_WarningTimer);
	}
	
	g_WarningInProgress = true;
	
	decl Handle:forwardVote;
	decl Handle:cvarTime;
	decl String:translationKey[64];
	
	switch (type)
	{
		case WarningType_Vote:
		{
			forwardVote = g_MapVoteWarningStartForward;
			cvarTime = g_Cvar_WarningTime;
			strcopy(translationKey, sizeof(translationKey), "Vote Warning");
			
		}
		
		case WarningType_Revote:
		{
			forwardVote = g_MapVoteRunoffStartForward;
			cvarTime = g_Cvar_RunOffWarningTime;
			strcopy(translationKey, sizeof(translationKey), "Revote Warning");
			
		}
	}

	if (!interrupted)
	{
		Call_StartForward(forwardVote);
		Call_Finish();
	}

	new Handle:data;
	g_WarningTimer = CreateDataTimer(1.0, Timer_StartMapVote, data, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	WritePackCell(data, GetConVarInt(cvarTime));
	WritePackString(data, translationKey);
	WritePackCell(data, _:when);
	WritePackCell(data, _:mapList);
	ResetPack(data);
}

stock InitializeOfficialMapList()
{
	// If this fails, we want it to have an empty adt_array
	if (ReadMapList(g_OfficialList,
		g_mapOfficialFileSerial,
		"official",
		MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_NO_DEFAULT)
		!= INVALID_HANDLE)
	{
		LogMessage("Loaded map list for %s.", g_GameModName);
	}
	// Check if the map list was ever loaded
	else if (g_mapOfficialFileSerial == -1)
	{
		LogMessage("No official map list found for %s. Consider submitting one!", g_GameModName);
	}
}

stock bool:IsMapEndVoteAllowed()
{
	if (!GetConVarBool(g_Cvar_EndOfMapVote) || g_MapVoteCompleted || g_HasVoteStarted)
	{
		return false;
	}
	else
	{
		return true;
	}
}

public Native_IsMapOfficial(Handle:plugin, numParams)
{
	new len;
	GetNativeStringLength(1, len);
	
	if (len <= 0)
	{
	  return false;
	}
	
	new String:map[len+1];
	GetNativeString(1, map, len+1);
	
	return InternalIsMapOfficial(map);
}

bool:InternalIsMapOfficial(const String:mapname[])
{
	new officialMapIndex = FindStringInArray(g_OfficialList, mapname);
	return (officialMapIndex > -1);
}

public Native_IsWarningTimer(Handle:plugin, numParams)
{
	return g_WarningInProgress;
}

public Native_CanNominate(Handle:plugin, numParams)
{
	if (g_HasVoteStarted)
	{
		return _:CanNominate_No_VoteInProgress;
	}
	
	if (g_MapVoteCompleted)
	{
		return _:CanNominate_No_VoteComplete;
	}
	
	if (g_NominateCount >= GetVoteSize())
	{
		return _:CanNominate_No_VoteFull;
	}
	
	return _:CanNominate_Yes;
}


stock AddMapItem(const String:map[])
{
	if (g_NativeVotes)
	{
		NativeVotes_AddItem(g_VoteMenu, map, map);
	}
	else
	{
		AddMenuItem(g_VoteMenu, map, map);
	}
}

stock GetMapItem(Handle:menu, position, String:map[], mapLen)
{
	if (g_NativeVotes)
	{
		NativeVotes_GetItem(menu, position, map, mapLen);
	}
	else
	{
		GetMenuItem(menu, position, map, mapLen);
	}
}

stock AddExtendToMenu(Handle:menu, MapChange:when)
{
	/* Do we add any special items? */
	// Moved for Mapchooser Extended

	if ((when == MapChange_Instant || when == MapChange_RoundEnd) && GetConVarBool(g_Cvar_DontChange))
	{
		if (g_NativeVotes)
		{
			// Built-in votes don't have "Don't Change", send Extend instead
			NativeVotes_AddItem(menu, VOTE_DONTCHANGE, "Don't Change");
		}
		else
		{
			AddMenuItem(menu, VOTE_DONTCHANGE, "Don't Change");
		}
	}
	else if (GetConVarBool(g_Cvar_Extend) && g_Extends < GetConVarInt(g_Cvar_Extend))
	{
		if (g_NativeVotes)
		{
			NativeVotes_AddItem(menu, VOTE_EXTEND, "Extend Map");
		}
		else
		{
			AddMenuItem(menu, VOTE_EXTEND, "Extend Map");
		}
	}
}

// Using this stock REQUIRES you to add the following to AskPluginLoad2:
// MarkNativeAsOptional("GetEngineVersion");
stock EngineVersion:GetEngineVersionCompat()
{
	new EngineVersion:version;
	if (GetFeatureStatus(FeatureType_Native, "GetEngineVersion") != FeatureStatus_Available)
	{
		new sdkVersion = GuessSDKVersion();
		switch (sdkVersion)
		{
			case SOURCE_SDK_ORIGINAL:
			{
				version = Engine_Original;
			}
			
			case SOURCE_SDK_DARKMESSIAH:
			{
				version = Engine_DarkMessiah;
			}
			
			case SOURCE_SDK_EPISODE1:
			{
				version = Engine_SourceSDK2006;
			}
			
			case SOURCE_SDK_EPISODE2:
			{
				version = Engine_SourceSDK2007;
			}
			
			case SOURCE_SDK_BLOODYGOODTIME:
			{
				version = Engine_BloodyGoodTime;
			}
			
			case SOURCE_SDK_EYE:
			{
				version = Engine_EYE;
			}
			
			case SOURCE_SDK_CSS:
			{
				version = Engine_CSS;
			}
			
			case SOURCE_SDK_EPISODE2VALVE:
			{
				decl String:gameFolder[PLATFORM_MAX_PATH];
				GetGameFolderName(gameFolder, PLATFORM_MAX_PATH);
				if (StrEqual(gameFolder, "dod", false))
				{
					version = Engine_DODS;
				}
				else if (StrEqual(gameFolder, "hl2mp", false))
				{
					version = Engine_HL2DM;
				}
				else
				{
					version = Engine_TF2;
				}
			}
			
			case SOURCE_SDK_LEFT4DEAD:
			{
				version = Engine_Left4Dead;
			}
			
			case SOURCE_SDK_LEFT4DEAD2:
			{
				decl String:gameFolder[PLATFORM_MAX_PATH];
				GetGameFolderName(gameFolder, PLATFORM_MAX_PATH);
				if (StrEqual(gameFolder, "nd", false))
				{
					version = Engine_NuclearDawn;
				}
				else
				{
					version = Engine_Left4Dead2;
				}
			}
			
			case SOURCE_SDK_ALIENSWARM:
			{
				version = Engine_AlienSwarm;
			}
			
			case SOURCE_SDK_CSGO:
			{
				version = Engine_CSGO;
			}
			
			default:
			{
				version = Engine_Unknown;
			}
		}
	}
	else
	{
		version = GetEngineVersion();
	}
	
	return version;
}

GetVoteSize()
{
	new voteSize = GetConVarInt(g_Cvar_IncludeMaps);
	
	// New in 1.9.5 to let us bump up the included maps count
	if (g_NativeVotes)
	{
		new max = NativeVotes_GetMaxItems();
		
		if (max < voteSize)
		{
			voteSize = max;
		}
	}
	
	return voteSize;
}