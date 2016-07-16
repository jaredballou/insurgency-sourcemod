/*
#############################################################################################################
#                                               Anti-TK 1.1.3                                               #
#############################################################################################################
*
* Author:
*	-> Rothgar
*
* Description:
*	Anti-TK script scripted for SourceMod. This script was created as a basic Anti-TK script alternative
*	to ATAC, most of the punishment functions have been taken from the funcommands plugin, or slightly
*	modified versions of the fun commands plugin functions. This ensures the script should be efficient
*	and makes for cleaner code. This has also been modified to support ZPS (Zombie Panic Source) infections
*	so infected players are not counted as TK's.
*
*
* Credits:
*	-> Rawr					> For providing an alternate slay function which kills players instantly.
*							ZPS has a delayed death function... which causes problems.
*	-> CustomFactor Server	> Being a test bed for the script
*	-> NADES Ins Server		> NADES and Admins helping test Insurgency Support.
*	-> sfPlayer				> Helping with adt arrays & suggestions
*	-> Tramp				> Allowing use of his CS Server for testing.
*	-> Milo|				> Finding bug in Purge Timer
*	-> Pimpinjuice			> providing a better way of hooking events.
*
*
* Required Files (Case Sensitive?):
*
*	-> These files can be downloaded from http://www.dawgclan.net
*
*
* Usage:
*
*	-> Change the compile variables below to enable/disable punishments and remove their code. This is currently based off the funcommands method. Otherwise use the cvar's.
*
*
* Version history:
*	v1.1.3:
*	- fixed:
*		- Error with no forgive internal notify error.
*		- Fixed some wrong death checks where round protection TK Menu's would not show and karma calculations would not work.
*
*	v1.1.2:
*	- fixed:
*		- Slap Mirror Damage Hook Issue.
*		- Slap Mirror Damage Percentage Bugs.
*
*	v1.1.1:
*	- added:
*		- Burn Punishments.
*		- Mirror Damage Percent.
*		- Stealing of Player Resources.
*	- fixed:
*		- Some errors due to players leaving the server before punishments had been made.
*
*	v1.1.0:
*	- fixed:
*		- Error with Stat TK log message when TK'er had left the game.
*		- Error hooking round start protection properly.
*		- Error detecting round protection incorrectly for early mirror damage.
*		- Menu items not using correct values. Punishments were wrong for No Forgive.
*		- Bug where Mirror Damage would be disabled after disabling round start protection.
*	- added:
*		- Added slay message for Mirror Damage attacker Slaying.
*		- Resource punishment removal.
*		- Added slap option for Mirror Damage.
*
*	v1.0.13: (Spawn Protection)
*	- fixed:
*		- Hooking wrong spawn protection cvar
*		- Mirror damage for Counter-Strike
*	- added:
*		- New CS Mod based TK hooking.
*
*	v1.0.12: (Admin immunity)
*	- fixed:
*		- Admin immunity cvars being incorrect.
*		- No longer checking "world" or "console" in player_hurt
*	- added:
*		- No Forgive Option if everything is disabled.
*	- changed:
*		- Menu code to be more dynamic.
*		- Translation messages to "team attack" instead of "team kill"
*
*	v1.0.11: (Timebomb)
*	- fixed:
*		- Fixed blind Maximum values.
*	- added:
*		- Time Bomb Punishment.
*		- Special Slay.
*		- Admin Immunity.
*	- changed:
*		- Fixed Debug log file message printing when Debug was not enabled.
*
*	v1.0.10: (Translation Changes)
*	- changed:
*		- Changes translations to be more consistent and not rely on plugin tag in Translation file.
*
*	v1.0.9: (Round Start Protection)
*	- fixed:
*		- A few log messages saying the wrong plugin source.
*		- Issue with Killing Timers
*	- added:
*		- Round Spawn Protection.
*		- Freeze Bomb Punishment.
*		- Automatic Configuration file.
*		- TK forgive stat log function modified from psychonic's Log Helper.
*		- SourceBans support.
*		- Mirror Damage.
*	- changed:
*		- Re-imported funcommands.
*		- Separated Anti-TK log file.
*		- Event Hooking method.
*		- Debug logging to have different levels.
*
*	v1.0.8: (Player Stat Storage)
*	- fixed:
*		- Slay not working/crashing some mods?
*	- added:
*		- Translation file for langauges.
*	- changed:
*		- Optimized a few variables.
*
*	v1.0.7: (Player Stat Storage)
*	- fixed:
*		- TK File Purging
*		- Purge Timer
*	- added:
*		- More Debug messages
*	- changed:
*		- Nothing
*
*	v1.0.6: (Player Stat Storage)
*	- fixed:
*		- Nothing
*	- added:
*		- Purging of stats
*	- changed:
*		- Nothing
*
*	v1.0.5: (Insurgency Slay work-around)
*	- fixed:
*		- Insurgency Slay causes server crash, used client kill command instead.
*		- Bantime description being seconds instead of minutes.
*		- Misc bugs
*	- added:
*		- TK user storage functions.
*	- changed:
*		- Debug functions.
*
*	v1.0.4: (Tidy up code)
*	- fixed:
*		- Errors when disabling options
*	- added:
*		- Debug option and cvars
*	- changed:
*		- Moved all funcommands functions into an include script.
*
*	v1.0.3: (Initial Public release)
*	- fixed:
*		- Nothing
*	- added:
*		- Entire plugin
*	- changed:
*		- Nothing
*/

#pragma semicolon 						1

#include <sourcemod>
#include <sdktools>

// SourceBans
#tryinclude <sourcebans>


// Enable Punishments (based off funcommands.sp)
// Disabling these will remove un-necessary code as opposed to using cvars
#define BEACON							1
#define FIRE							1
#define ICE								1
#define GRAVITY							1
#define BLIND							1
#define DRUG							1
#define SLAP							1
#define SLAY							1
#define TIMEBOMB						1

// Change this to enable debug
// 0 = No Logging
// 1 = Minimal Logging
// 2 = Maximum Logging
#define _DEBUG							0
#define _DEBUG_MODE						1 // 1 = Log to File, 2 = Log to Game Logs, 3 Print to Chat

#if _DEBUG
new String:AntiTK_LogFile[PLATFORM_MAX_PATH];
#endif

// Shouldn't need to edit anything below this line.

#define VERSION							"1.1.3"

// 4 == Usually Green?
// 1 == Normal Color?
#define ANTITK_COLOR					4

#define MAX_NETWORKID_LENGTH			64

// ZPS Related Variables
#define TEAM_ZPS_ZOMBIE					2
#define TEAM_ZPS_SURVIVOR				1
#define TEAM_ZPS_SPECTATOR				3
#define TEAM_ZPS_OBSERVER				4


// Player Array Settings
#define STAT_KARMA						0
#define STAT_KILLS						1
#define STAT_TEAM_KILLS					2
#define STAT_LAST_TKER					3
#define STAT_TKER_RESOURCES				4


new RoundStartTime =					0;
new bool:RoundProtect =					false;
new bool:MirrorDamageSlap =				false;

new arrayPlayerStats[MAXPLAYERS + 1][5];
new Handle:arrayPlayerPunishments[MAXPLAYERS + 1] =					{INVALID_HANDLE, ...};
new String:arrayPlayerName[MAXPLAYERS + 1][MAX_NAME_LENGTH];
new String:arrayPlayerTKerName[MAXPLAYERS + 1][MAX_NAME_LENGTH];
new arrayPlayerSpawnTime[MAXPLAYERS + 1] =							{ 0, ...};

// Event Array Variables
#define EVENT_ENABLED					0
#define EVENT_ROUND_START				1
#define EVENT_PLAYER_SPAWN				2
#define EVENT_PLAYER_HURT				3
#define EVENT_PLAYER_DEATH				4
#define EVENT_ROUND_END					5

new bool:bEventIsHooked[6] =			{ false, ...};

// ConVar Array Variables
#define CONVAR_ENABLED					0
#define CONVAR_MOD_ATK					1
#define CONVAR_MOD_TKPUNISH				2
#define CONVAR_MOD_SPAWNPROTECT			3
#define CONVAR_ROUND_START_PROTECT		4
#define CONVAR_PURGE_TIME				5
#define CONVAR_MIRROR_DAMAGE			6
#define CONVAR_MIRROR_DAMAGE_SLAP		7

new bool:bCvarIsHooked[8] =				{ false, ...};

#define ATK_PUNISHMENTS					13
#define ATK_NOFORGIVE					100

#define ATK_FORGIVE						0
#define ATK_SLAY						1
#define ATK_SLAP						2
#define ATK_BEACON						3
#define ATK_BURN						4
#define ATK_FIREBOMB					5
#define ATK_FREEZE						6
#define ATK_FREEZEBOMB					7
#define ATK_SLOW						8
#define ATK_BLIND						9
#define ATK_DRUG						10
#define ATK_TIMEBOMB					11
#define ATK_RESOURCES					12

new String:arrayPunishmentText[ATK_PUNISHMENTS][16] =
{
	"Forgive",
	"Slay",
	"Slap",
	"Beacon",
	"Burn",
	"FireBomb",
	"Freeze",
	"FreezeBomb",
	"Slow",
	"Blind",
	"Drug",
	"TimeBomb",
	"Resources"
};

new g_Player_MaxHealth[MAXPLAYERS+1] =	{0, ...};

new Handle:g_Purge_Timer =				INVALID_HANDLE;
new Handle:g_Enable_Timer =				INVALID_HANDLE;

// Include Key Value Functions
#include "antitk/keyvalues.sp"



// Create console variables
new Handle:g_Cvar_Enabled =				INVALID_HANDLE;
new Handle:g_Cvar_AdminsImmune =		INVALID_HANDLE;
new Handle:g_Cvar_AdminsFlag =			INVALID_HANDLE;
new Handle:g_Cvar_RoundStartTime =		INVALID_HANDLE;
new Handle:g_Cvar_RoundStartType =		INVALID_HANDLE;
new Handle:g_Cvar_RoundStartExclude =	INVALID_HANDLE;
new Handle:g_Cvar_MaxTKs =				INVALID_HANDLE;
new Handle:g_Cvar_KarmaKills =			INVALID_HANDLE;
new Handle:g_Cvar_AntiTKType =			INVALID_HANDLE;
new Handle:g_Cvar_BanTime =				INVALID_HANDLE;
new Handle:g_Cvar_PurgeTime =			INVALID_HANDLE;
new Handle:g_Cvar_MirrorDamage =		INVALID_HANDLE;
new Handle:g_Cvar_MirrorDamagePercent =	INVALID_HANDLE;
new Handle:g_Cvar_MirrorDamageSlap =	INVALID_HANDLE;
#if BEACON
new Handle:g_Cvar_Beacon =				INVALID_HANDLE;
new Handle:g_Cvar_BeaconRadius =		INVALID_HANDLE;
#endif
#if FIRE
new Handle:g_Cvar_Burn =				INVALID_HANDLE;
new Handle:g_Cvar_BurnDuration =		INVALID_HANDLE;
new Handle:g_Cvar_FireBomb =			INVALID_HANDLE;
new Handle:g_Cvar_FireBombTicks =		INVALID_HANDLE;
new Handle:g_Cvar_FireBombRadius =		INVALID_HANDLE;
new Handle:g_Cvar_FireBombMode =		INVALID_HANDLE;
#endif
#if ICE
new Handle:g_Cvar_Freeze =				INVALID_HANDLE;
new Handle:g_Cvar_FreezeDuration =		INVALID_HANDLE;
new Handle:g_Cvar_FreezeBomb =			INVALID_HANDLE;
new Handle:g_Cvar_FreezeBombTicks =		INVALID_HANDLE;
new Handle:g_Cvar_FreezeBombRadius =	INVALID_HANDLE;
new Handle:g_Cvar_FreezeBombMode =		INVALID_HANDLE;
#endif
#if GRAVITY
new Handle:g_Cvar_Slow =				INVALID_HANDLE;
new Handle:g_Cvar_SlowSpeed =			INVALID_HANDLE;
new Handle:g_Cvar_SlowGravity =			INVALID_HANDLE;
#endif
#if BLIND
new Handle:g_Cvar_Blind =				INVALID_HANDLE;
new Handle:g_Cvar_BlindAmount =			INVALID_HANDLE;
#endif
#if DRUG
new Handle:g_Cvar_Drug =				INVALID_HANDLE;
#endif
#if SLAP
new Handle:g_Cvar_Slap =				INVALID_HANDLE;
new Handle:g_Cvar_SlapDamage =			INVALID_HANDLE;
#endif
#if SLAY
new Handle:g_Cvar_Slay =				INVALID_HANDLE;
new Handle:g_Cvar_SpecialSlay =			INVALID_HANDLE;
#endif
#if TIMEBOMB
new Handle:g_Cvar_TimeBomb =			INVALID_HANDLE;
new Handle:g_Cvar_TimeBombTicks =		INVALID_HANDLE;
new Handle:g_Cvar_TimeBombRadius =		INVALID_HANDLE;
new Handle:g_Cvar_TimeBombMode =		INVALID_HANDLE;
#endif
new Handle:g_Cvar_Resources =			INVALID_HANDLE;
new Handle:g_Cvar_ResourceSteal =		INVALID_HANDLE;
new Handle:g_Cvar_ResourceAmount =		INVALID_HANDLE;

// Mods
new g_GameEngine = SOURCE_SDK_UNKNOWN;

new bool:Insurgency =					false;
new bool:ZombiePanic =					false;
new bool:CounterStrike =				false;
new bool:TF2 =							false;
new bool:PVKII =						false;

// Mod Protection Cvars
new Handle:g_Cvar_ATK =					INVALID_HANDLE;
new Handle:g_Cvar_TKPunish =			INVALID_HANDLE;
new Handle:g_Cvar_SpawnProtect = 		INVALID_HANDLE;

// Offsets
new offsInfected =						-1;
new offsResourceAmount =				-1;

// Team List (Log Helper)
new String: g_team_list[16][64];

// SourceBans
new bool:g_bSBAvailable =				false;

// Include Extracted Funcommands Functions
#include "antitk/funcommands.sp"

#if SLAY
new g_Lightning;
#define SOUND_SLAY						"weapons/hegrenade/explode3.wav"
#endif


public Plugin:myinfo =
{
	name = "Anti-TK",
	author = "Rothgar",
	description = "Anti-TK Script",
	version = VERSION,
	url = "http://www.dawgclan.net"
};

#if _DEBUG
BuildLogFilePath()
{
	// Build Log File Path
	decl String:cTime[64];
	FormatTime(cTime, sizeof(cTime), "logs/antitk_%Y%m%d.log");
	BuildPath(Path_SM, AntiTK_LogFile, sizeof(AntiTK_LogFile), cTime);
	LogAction(0, -1, "[Anti-TK Manager] Log File: %s", AntiTK_LogFile);
}
#endif

LogDebug(bool:Translation, String:text[], any:...)
{
	decl String:message[255];
	if (Translation)
		VFormat(message, sizeof(message), "%T", 2);
	else
		if (strlen(text) > 0)
			VFormat(message, sizeof(message), text, 3);
		else
			return false;
#if _DEBUG
#if _DEBUG_MODE == 1
	LogToFile(AntiTK_LogFile, "[Anti-TK Manager] %s", message);
#elseif _DEBUG_MODE == 2
	LogToGame("[Anti-TK Manager] %s", message);
#elseif _DEBUG_MODE == 3
	PrintToChatAll("[Anti-TK Manager] %s", message);
#endif
	return true;
#else
	return false;
#endif
}


public OnPluginStart()
{
#if _DEBUG
	BuildLogFilePath();
#endif
	BuildKeyValuePath();
	LogDebug(false, "Anti-TK Plugin Started! Version: %s", VERSION);

	LoadTranslations("common.phrases");
	LoadTranslations("funcommands.phrases");
	LoadTranslations("antitk.phrases");

	// Check Engine
	g_GameEngine = GuessSDKVersion();

	if (g_GameEngine > SOURCE_SDK_EPISODE2VALVE)
		LogDebug(false, "Detected Game Engine Left 4 Dead");
	else if (g_GameEngine > SOURCE_SDK_EPISODE1)
		LogDebug(false, "Detected Game Engine Orange Box");
	else if (g_GameEngine == SOURCE_SDK_EPISODE1)
		LogDebug(false, "Detected Game Engine Episode 1");
	else if (g_GameEngine == SOURCE_SDK_ORIGINAL)
		LogDebug(false, "Detected Game Engine Original Source");
	else if (g_GameEngine == SOURCE_SDK_UNKNOWN)
		LogDebug(false, "Detected unknown Game Engine");
	else
		LogDebug(false, "Detected Game Engine Other");
	

	// Check Mods
	decl String:game_mod[32];
	GetGameFolderName(game_mod, sizeof(game_mod));
	if (strcmp(game_mod, "insurgency", false) == 0)
	{
		LogAction(0, -1, "[Anti-TK] %T", "Insurgency", LANG_SERVER);
		Insurgency = true;
	}
	else if (strcmp(game_mod, "cstrike", false) == 0)
	{
		LogAction(0, -1, "[Anti-TK] %T", "CS", LANG_SERVER);
		CounterStrike = true;
	}
	else if (strcmp(game_mod, "ZPS", false) == 0)
	{
		LogAction(0, -1, "[Anti-TK] %T", "ZPS", LANG_SERVER);
		ZombiePanic = true;
	}
	else if (strcmp(game_mod, "tf", false) == 0)
	{
		LogAction(0, -1, "[Anti-TK] %T", "TF2", LANG_SERVER);
		TF2 = true;
	}
	else if (strcmp(game_mod, "pvkii", false) == 0)
	{
		LogAction(0, -1, "[Anti-TK] %T", "PVKII", LANG_SERVER);
		PVKII = true;
	}


	if (CounterStrike)
	{
		offsResourceAmount = FindSendPropInfo("CCSPlayer", "m_iAccount");

		// Hook ATK Convars
		g_Cvar_ATK = FindConVar("mp_autokick");
		g_Cvar_TKPunish = FindConVar("mp_tkpunish");
		// Hook Spawn Protect Convar
		g_Cvar_SpawnProtect = FindConVar("mp_spawnprotectiontime");
	}

	// Find Game Offsets
	if (ZombiePanic)
		offsInfected = FindSendPropInfo("CHL2MP_Player", "m_IsInfected");

	// Set UserMessageId for Fade. (based off funcommands.sp)
#if DRUG || BLIND
	g_FadeUserMsgId = GetUserMessageId("Fade");
#endif

	// Register Cvars
	RegisterCvars();
	SetConVarInt(g_Cvar_Enabled, 0);

	// Hook Events
	RegisterHooks();

	AutoExecConfig(true, "antitk");

	// Load TKers from Key Values File
	ReadTKers();

	// Initialize Player Arrays
	antitk_Initialize();

#if _DEBUG
	RegAdminCmd("sm_antitk_test", Command_Test, ADMFLAG_ROOT);
#endif
}

/*
OnPluginEnd()
{
	// Plugin Unloading
}
*/

public OnAllPluginsLoaded()
{
	if (LibraryExists("sourcebans"))
	{
		g_bSBAvailable = true;
		LogDebug(false, "OnAllPluginsLoaded - SourceBans Plugin Detected.");
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "sourcebans"))
	{
		g_bSBAvailable = true;
		LogDebug(false, "OnAllPluginsLoaded - SourceBans Plugin Added.");
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "sourcebans"))
	{
		g_bSBAvailable = false;
		LogDebug(false, "OnAllPluginsLoaded - SourceBans Plugin Removed.");
	}
}


public OnConfigsExecuted()
{
	LogDebug(false, "OnConfigsExecuted - Anti-TK Plugin - All Configs have been executed.");
	// Handle Plugin load Hooks
	//if (GetConVarBool(g_Cvar_Enabled))
	//{
	//	SetConVarInt(g_Cvar_Enabled, 1);
	//}

	if (!bCvarIsHooked[CONVAR_PURGE_TIME])
	{
		HookConVarChange(g_Cvar_PurgeTime, CvarChange_PurgeTime);
		bCvarIsHooked[CONVAR_PURGE_TIME] = true;
		LogDebug(false, "OnConfigsExecuted - Hooked Purge Time variable.");
	}
	if (!bCvarIsHooked[CONVAR_MIRROR_DAMAGE])
	{
		HookConVarChange(g_Cvar_MirrorDamage, CvarChange_MirrorDamage);
		bCvarIsHooked[CONVAR_MIRROR_DAMAGE] = true;
		LogDebug(false, "OnConfigsExecuted - Hooked Mirror Damage variable.");
	}
}

EnablePlugin()
{
	if (GetConVarFloat(g_Cvar_RoundStartTime) > 0.0)
	{
		LogDebug(false, "EnablePlugin - Round Start Protection time is enabled. Running Enable_RoundStartProtection.");
		Enable_RoundStartProtection();
	}

	if (!bEventIsHooked[EVENT_ROUND_END])
	{
		if (ZombiePanic)
			HookEvent("ambient_play", Event_RoundEnd, EventHookMode_PostNoCopy);
		else if (TF2)
		{
			//teamplay_round_start teamplay_restart_round
		}
		else
			HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);

		bEventIsHooked[EVENT_ROUND_END] = true;
		LogDebug(false, "EnablePlugin - Hooked Round End Event.");
	}

	if (!bEventIsHooked[EVENT_PLAYER_DEATH])
	{
		HookEvent("player_death",Event_PlayerDeath);
		bEventIsHooked[EVENT_PLAYER_DEATH] = true;
		LogDebug(false, "EnablePlugin - Hooked Player Death Event.");
	}
	if (!bEventIsHooked[EVENT_PLAYER_SPAWN])
	{
		HookEvent("player_spawn",Event_PlayerSpawn);
		bEventIsHooked[EVENT_PLAYER_SPAWN] = true;
		LogDebug(false, "EnablePlugin - Hooked Player Spawn Event.");
	}
	if (!bEventIsHooked[EVENT_PLAYER_HURT])
	{
		HookEvent("player_hurt",Event_PlayerHurt);
		bEventIsHooked[EVENT_PLAYER_HURT] = true;
		LogDebug(false, "EnablePlugin - Hooked Player Hurt Event.");
	}
}

DisablePlugin()
{
	if (GetConVarFloat(g_Cvar_RoundStartTime) > 0.0)
		Disable_RoundStartProtection();

	if (bEventIsHooked[EVENT_ROUND_END])
	{
		if (ZombiePanic)
			UnhookEvent("ambient_play", Event_RoundEnd, EventHookMode_PostNoCopy);
		else if (TF2)
		{
			//teamplay_round_start teamplay_restart_round
		}
		else
			UnhookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);

		bEventIsHooked[EVENT_ROUND_END] = false;
		LogDebug(false, "DisablePlugin - Unhooked Round End Event.");
	}

	if (bEventIsHooked[EVENT_PLAYER_DEATH])
	{
		UnhookEvent("player_death",Event_PlayerDeath);
		bEventIsHooked[EVENT_PLAYER_DEATH] = false;
		LogDebug(false, "DisablePlugin - Unhooked Player Death Event.");
	}
	if (bEventIsHooked[EVENT_PLAYER_SPAWN])
	{
		UnhookEvent("player_spawn",Event_PlayerSpawn);
		bEventIsHooked[EVENT_PLAYER_SPAWN] = false;
		LogDebug(false, "DisablePlugin - Unhooked Player Spawn Event.");
	}
	if (bEventIsHooked[EVENT_PLAYER_HURT])
	{
		UnhookEvent("player_hurt",Event_PlayerHurt);
		bEventIsHooked[EVENT_PLAYER_HURT] = false;
		LogDebug(false, "DisablePlugin - Unhooked Player Hurt Event.");
	}	
}

public CvarChange_Enabled(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	LogDebug(false, "CvarChange_Enabled - Anti-TK Plugin Enabled cvar has been changed. Old value: %s New value: %s", oldvalue[0], newvalue[0]);

	if (!StrEqual(oldvalue, newvalue))
		if (StringToInt(newvalue) == 1)
		{
			LogDebug(false, "CvarChange_Enabled - Enabled (Hooking Events).");
			EnablePlugin();
		}
		else if (StringToInt(newvalue) == 0)
		{
			LogDebug(false, "CvarChange_Enabled - Disabled (Unhooking Events).");
			DisablePlugin();
		}
}

// Disable Mod Based ATK System
public CvarChange_ATK(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
#if _DEBUG
	LogDebug(false, "CvarChange_ATK - Anti TK cvar has been changed. Old value: %s New value: %s", oldvalue[0], newvalue[0]);
#endif

	if (StringToInt(newvalue) > 0)
	{
#if _DEBUG
			LogDebug(false, "CvarChange_ATK - Disabling Mod Anti TK handler.");
#endif
			SetConVarInt(cvar, 0);
	}	
}

public CvarChange_TKPunish(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
#if _DEBUG
	LogDebug(false, "CvarChange_TKPunish - TK Punish cvar has been changed. Old value: %s New value: %s", oldvalue[0], newvalue[0]);
#endif

	if (StringToInt(newvalue) > 0)
	{
#if _DEBUG
			LogDebug(false, "CvarChange_TKPunish - Disabling Mod TK Punish handler.");
#endif
			SetConVarInt(cvar, 0);
	}	
}

public CvarChange_SpawnProtect(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
#if _DEBUG
	LogDebug(false, "CvarChange_SpawnProtect - Spawn Protect cvar has been changed. Old value: %s New value: %s", oldvalue[0], newvalue[0]);
#endif

	if (StringToInt(newvalue) > 0)
	{
#if _DEBUG
			LogDebug(false, "CvarChange_SpawnProtect - Disabling Mod Spawn Protect handler.");
#endif
			SetConVarInt(cvar, 0);
	}	
}


Enable_RoundStartProtection()
{
	if (!bEventIsHooked[EVENT_ROUND_START])
	{
		if (ZombiePanic)
			HookEvent("game_round_restart", Event_RoundStart, EventHookMode_PostNoCopy);
		else
			HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

		bEventIsHooked[EVENT_ROUND_START] = true;
	}

	if (!bEventIsHooked[EVENT_PLAYER_HURT])
	{
		HookEvent("player_hurt", Event_PlayerHurt);
		bEventIsHooked[EVENT_PLAYER_HURT] = true;
	}
}

Disable_RoundStartProtection()
{
	if (bEventIsHooked[EVENT_ROUND_START])
	{
		if (ZombiePanic)
			UnhookEvent("game_round_restart", Event_RoundStart, EventHookMode_PostNoCopy);
		else
			UnhookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

		bEventIsHooked[EVENT_ROUND_START] = false;
	}

	if (GetConVarInt(g_Cvar_MirrorDamage) <= 0)
	{
		if (bEventIsHooked[EVENT_PLAYER_HURT])
		{
			if (GetConVarInt(g_Cvar_MirrorDamage) > 0)
			{
				UnhookEvent("player_hurt", Event_PlayerHurt);
				bEventIsHooked[EVENT_PLAYER_HURT] = false;
			}
		}
	}
}

public CvarChange_RoundStartProtection(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	LogDebug(false, "CvarChange_RoundStartProtection - Round Start Protection cvar has been changed. Old value: %s New value: %s", oldvalue[0], newvalue[0]);

	if (!StrEqual(oldvalue, newvalue))
		if (StringToInt(newvalue) > 0)
		{
			if (GetConVarBool(g_Cvar_Enabled))
			{
				LogDebug(false, "CvarChange_RoundStartProtection - Enabled (Hooking Events).");
				Enable_RoundStartProtection();
			}
		}
		else
		{
			if (GetConVarBool(g_Cvar_Enabled))
			{
				LogDebug(false, "CvarChange_RoundStartProtection - Disabled (Unhooking Events).");
				Disable_RoundStartProtection();
			}
		}
}


public CvarChange_MirrorDamage(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	LogDebug(false, "CvarChange_MirrorDamage - Mirror Damage cvar has been changed. Old value: %s New value: %s", oldvalue[0], newvalue[0]);

	if (!StrEqual(oldvalue, newvalue))
		if (StringToInt(newvalue) > 0)
		{
			if (GetConVarBool(g_Cvar_Enabled))
			{
				if (!bEventIsHooked[EVENT_PLAYER_HURT])
				{
					HookEvent("player_hurt", Event_PlayerHurt);
					bEventIsHooked[EVENT_PLAYER_HURT] = true;
				}
			}
		}
		else
		{
			if (GetConVarBool(g_Cvar_Enabled))
			{
				if (bEventIsHooked[EVENT_PLAYER_HURT])
				{
					if (GetConVarFloat(g_Cvar_RoundStartTime) == 0.0)
					{
						UnhookEvent("player_hurt", Event_PlayerHurt);
						bEventIsHooked[EVENT_PLAYER_HURT] = false;
					}
				}
			}
		}
}

public CvarChange_MirrorDamageSlap(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	LogDebug(false, "CvarChange_MirrorDamageSlap - Mirror Damage Slap cvar has been changed. Old value: %s New value: %s", oldvalue[0], newvalue[0]);

	if (!StrEqual(oldvalue, newvalue))
		if (StringToInt(newvalue) > 0)
			MirrorDamageSlap = true;
		else
			MirrorDamageSlap = false;
}


RegisterHooks()
{
	LogDebug(false, "Running RegisterHooks()");
	if (!bCvarIsHooked[CONVAR_ENABLED])
	{
		HookConVarChange(g_Cvar_Enabled, CvarChange_Enabled);
		bCvarIsHooked[CONVAR_ENABLED] = true;
		LogDebug(false, "RegisterHooks - Hooked Enable variable.");
	}

	if (!bCvarIsHooked[CONVAR_ROUND_START_PROTECT])
	{
		HookConVarChange(g_Cvar_RoundStartTime, CvarChange_RoundStartProtection);
		bCvarIsHooked[CONVAR_ROUND_START_PROTECT] = true;
		LogDebug(false, "RegisterHooks - Hooked Round Start Protection variable.");
	}

	if (g_Cvar_ATK != INVALID_HANDLE)
	{
		if (!bCvarIsHooked[CONVAR_MOD_ATK])
		{
			HookConVarChange(g_Cvar_ATK, CvarChange_ATK);
			bCvarIsHooked[CONVAR_MOD_ATK] = true;
#if _DEBUG
			LogDebug(false, "RegisterHooks - Hooked Mod Based ATK variable.");
#endif
			SetConVarInt(g_Cvar_ATK, 0);
		}
	}

	if (g_Cvar_TKPunish != INVALID_HANDLE)
	{
		if (!bCvarIsHooked[CONVAR_MOD_TKPUNISH])
		{
			HookConVarChange(g_Cvar_TKPunish, CvarChange_TKPunish);
			bCvarIsHooked[CONVAR_MOD_TKPUNISH] = true;
#if _DEBUG
			LogDebug(false, "RegisterHooks - Hooked Mod Based TK Punish variable.");
#endif
			SetConVarInt(g_Cvar_TKPunish, 0);
		}
	}

	if (g_Cvar_SpawnProtect != INVALID_HANDLE)
	{
		if (!bCvarIsHooked[CONVAR_MOD_SPAWNPROTECT])
		{
			HookConVarChange(g_Cvar_SpawnProtect, CvarChange_SpawnProtect);
			bCvarIsHooked[CONVAR_MOD_SPAWNPROTECT] = true;
#if _DEBUG
			LogDebug(false, "RegisterHooks - Hooked Mod Based Spawn Protection variable.");
#endif
			SetConVarInt(g_Cvar_SpawnProtect, 0);
		}
	}

	if (g_Cvar_MirrorDamageSlap != INVALID_HANDLE)
	{
		if (!bCvarIsHooked[CONVAR_MIRROR_DAMAGE_SLAP])
		{
			HookConVarChange(g_Cvar_MirrorDamageSlap, CvarChange_MirrorDamageSlap);
			bCvarIsHooked[CONVAR_MIRROR_DAMAGE_SLAP] = true;
#if _DEBUG
			LogDebug(false, "RegisterHooks - Hooked Mirror Damage Slap variable.");
#endif
		}
	}
}

RegisterCvars()
{
	// Register all console variables
	LogDebug(false, "Running RegisterCvars()");

	CreateConVar("sm_antitk_version", VERSION, "Anti-TK management plugin",FCVAR_SPONLY|FCVAR_UNLOGGED| FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvar_Enabled = CreateConVar("sm_antitk_enable", "1", "Is the Anti-TK Manager enabled or disabled? [0 = FALSE, 1 = TRUE]", 0, true, 0.0, true, 1.0);
	g_Cvar_AdminsImmune = CreateConVar("sm_antitk_admins_immune", "0", "Are Admins immune to the Anti-TK Manager? [0 = FALSE, 1 = TRUE]", 0, true, 0.0, true, 1.0);
	g_Cvar_AdminsFlag = CreateConVar("sm_antitk_admins_flag", "", "Admin Flag for immunity? Leave Blank for any flag.");
	g_Cvar_RoundStartTime = CreateConVar("sm_antitk_round_start_protect_time", "0.0", "Time in seconds the Anti-TK Manager Round Start Protection should take effect. [0 = DISABLED]");
	g_Cvar_RoundStartType = CreateConVar("sm_antitk_round_start_type", "0", "Type of action that is taken during the Round Start Protection? [0 = FORGIVE, 1 = SLAY, 2 = SLAP, 3 = BEACON, 4 = BURN, 5 = FIRE BOMB, 6 = FREEZE, 7 = FREEZE BOMB, 8 = SLOW, 9 = BLIND, 10 = DRUG, 11 = TIME BOMB, 12 = RESOURCES, 100 = NO FORGIVE]");
	g_Cvar_RoundStartExclude = CreateConVar("sm_antitk_round_start_exclude", "1", "Should we exclude TK's from being tracked during the Round Start Protection? [0 = FALSE, 1 = TRUE]", 0, true, 0.0, true, 1.0);
	g_Cvar_MaxTKs = CreateConVar("sm_antitk_max", "0", "Maximum number of TK's allowed before Kick/Ban action occurs.");
	g_Cvar_KarmaKills = CreateConVar("sm_antitk_karma_kills", "10", "Number of enemy kills required to remove a TK point. [DEFAULT: 10]");
	g_Cvar_AntiTKType = CreateConVar("sm_antitk_type", "0", "Type of action that is taken once the TK limit has been exceeded? [0 = NOTHING, 1 = KICK, 2 = BAN]", 0, true, 0.0, true, 2.0);
	g_Cvar_BanTime = CreateConVar("sm_antitk_ban_time", "60", "Time in minutes player should be banned for excessive TK's. [DEFAULT: 60 minutes]");
	g_Cvar_PurgeTime = CreateConVar("sm_antitk_purge_time", "1800.0", "Time in seconds TKer data should be kept before purging. [DEFAULT: 30 minutes]");
	g_Cvar_MirrorDamage = CreateConVar("sm_antitk_mirror_type", "0", "Type of mirrored damage for when a player is attacked by team player? [0 = NONE, 1 = ATTACKER, 2 = ATTACKER + RETURN HEALTH]", 0, true, 0.0, true, 2.0);
	g_Cvar_MirrorDamagePercent = CreateConVar("sm_antitk_mirror_percent", "100", "Mirror damage percent that is returned to attacker? [DEFAULT: 100 Percent]", 0, true, 0.0, true, 100.0);
	g_Cvar_MirrorDamageSlap = CreateConVar("sm_antitk_mirror_slap", "0", "Should we slap the attacker when mirroring damage? [0 = FALSE, 1 = TRUE]", 0, true, 0.0, true, 1.0);
#if BEACON
	g_Cvar_Beacon = CreateConVar("sm_antitk_beacon", "1", "Is the Anti-TK Manager Beacon option enabled or disabled? [0 = FALSE, 1 = TRUE]", 0, true, 0.0, true, 1.0);
	g_Cvar_BeaconRadius = CreateConVar("sm_antitk_beacon_radius", "375.0", "Anti-TK Manager radius for beacon's light rings. [DEFAULT: 375]", 0, true, 50.0, true, 1500.0);
#endif
#if FIRE
	g_Cvar_Burn = CreateConVar("sm_antitk_burn", "1", "Is the Anti-TK Manager Burn option enabled or disabled? [0 = FALSE, 1 = TRUE]", 0, true, 0.0, true, 1.0);
	g_Cvar_BurnDuration = CreateConVar("sm_antitk_burn_duration", "20", "Anti-TK Manager Burn Duration. [DEFAULT: 20 seconds]", 0, true, 0.5, true, 20.0);
	g_Cvar_FireBomb = CreateConVar("sm_antitk_firebomb", "1", "Is the Anti-TK Manager FireBomb option enabled or disabled? [0 = FALSE, 1 = TRUE]", 0, true, 0.0, true, 1.0);
	g_Cvar_FireBombTicks = CreateConVar("sm_antitk_firebomb_fuse", "10.0", "Anti-TK Manager FireBomb fuse length. [DEFAULT: 10 seconds]", 0, true, 5.0, true, 120.0);
	g_Cvar_FireBombRadius = CreateConVar("sm_antitk_firebomb_radius", "600", "Anti-TK Manager FireBomb blast radius. [DEFAULT: 600]", 0, true, 50.0, true, 3000.0);
	g_Cvar_FireBombMode = CreateConVar("sm_antitk_firebomb_mode", "0", "Who is targeted by the Anti-TK Manager FireBomb? [0 = ATTACKER, 1 = TEAM, 2 = EVERYONE]", 0, true, 0.0, true, 2.0);
#endif
#if ICE
	g_Cvar_Freeze = CreateConVar("sm_antitk_freeze", "1", "Is the Anti-TK Manager Freeze option enabled or disabled? [0 = FALSE, 1 = TRUE]", 0, true, 0.0, true, 1.0);
	g_Cvar_FreezeDuration = CreateConVar("sm_antitk_freeze_duration", "10", "Anti-TK Manager Freeze Duration. [DEFAULT: 10 seconds]", 0, true, 1.0, true, 120.0);
	g_Cvar_FreezeBomb = CreateConVar("sm_antitk_freezebomb", "1", "Is the Anti-TK Manager FreezeBomb option enabled or disabled? [0 = FALSE, 1 = TRUE]", 0, true, 0.0, true, 1.0);
	g_Cvar_FreezeBombTicks = CreateConVar("sm_antitk_freezebomb_fuse", "10.0", "Anti-TK Manager FreezeBomb fuse length. [DEFAULT: 10 seconds]", 0, true, 5.0, true, 120.0);
	g_Cvar_FreezeBombRadius = CreateConVar("sm_antitk_freezebomb_radius", "600", "Anti-TK Manager FreezeBomb blast radius. [DEFAULT: 600]", 0, true, 50.0, true, 3000.0);
	g_Cvar_FreezeBombMode = CreateConVar("sm_antitk_freezebomb_mode", "0", "Who is targeted by the Anti-TK Manager FreezeBomb? [0 = ATTACKER, 1 = TEAM, 2 = EVERYONE]", 0, true, 0.0, true, 2.0);
#endif
#if TIMEBOMB
	g_Cvar_TimeBomb = CreateConVar("sm_antitk_timebomb", "1", "Is the Anti-TK Manager TimeBomb option enabled or disabled? [0 = FALSE, 1 = TRUE]", 0, true, 0.0, true, 1.0);
	g_Cvar_TimeBombTicks = CreateConVar("sm_antitk_timebomb_fuse", "10.0", "Anti-TK Manager TimeBomb fuse length. [DEFAULT: 10 seconds]", 0, true, 5.0, true, 120.0);
	g_Cvar_TimeBombRadius = CreateConVar("sm_antitk_timebomb_radius", "600", "Anti-TK Manager TimeBomb blast radius. [DEFAULT: 600]", 0, true, 50.0, true, 3000.0);
	g_Cvar_TimeBombMode = CreateConVar("sm_antitk_timebomb_mode", "0", "Who is targeted by the Anti-TK Manager TimeBomb? [0 = ATTACKER, 1 = TEAM, 2 = EVERYONE]", 0, true, 0.0, true, 2.0);
#endif
#if GRAVITY
	g_Cvar_Slow = CreateConVar("sm_antitk_slow", "1", "Is the Anti-TK Manager Slow option enabled or disabled? [0 = FALSE, 1 = TRUE]", 0, true, 0.0, true, 1.0);
	g_Cvar_SlowSpeed = CreateConVar("sm_antitk_slow_speed", "0.4", "Anti-TK Manager Slow Speed Multiplier. [DEFAULT: 0.4]");
	g_Cvar_SlowGravity = CreateConVar("sm_antitk_slow_gravity", "1.4", "Anti-TK Manager Slow Gravity Multiplier. [DEFAULT: 1.4]");
#endif
#if BLIND
	g_Cvar_Blind = CreateConVar("sm_antitk_blind", "1", "Is the Anti-TK Manager Blind option enabled or disabled? [0 = FALSE, 1 = TRUE]", 0, true, 0.0, true, 1.0);
	g_Cvar_BlindAmount = CreateConVar("sm_antitk_blind_amount", "230", "Anti-TK Manager Blind Amount. [DEFAULT: 230]", 0, true, 0.0, true, 255.0);
#endif
#if DRUG
	g_Cvar_Drug = CreateConVar("sm_antitk_drug", "1", "Is the Anti-TK Manager Drug option enabled or disabled? [0 = FALSE, 1 = TRUE]", 0, true, 0.0, true, 1.0);
#endif
#if SLAP
	g_Cvar_Slap = CreateConVar("sm_antitk_slap", "1", "Is the Anti-TK Manager Slap option enabled or disabled? [0 = FALSE, 1 = TRUE]", 0, true, 0.0, true, 1.0);
	g_Cvar_SlapDamage = CreateConVar("sm_antitk_slap_damage", "50", "Anti-TK Manager Slap Damage. [DEFAULT: 50 health]", 0, true, 0.0, true, 100.0);
#endif
#if SLAY
	g_Cvar_Slay = CreateConVar("sm_antitk_slay", "1", "Is the Anti-TK Manager Slay option enabled or disabled? [0 = FALSE, 1 = TRUE]", 0, true, 0.0, true, 1.0);
	g_Cvar_SpecialSlay = CreateConVar("sm_antitk_special_slay", "0", "Should we use a special version of the slay? (May not work with all mods) [0 = FALSE, 1 = TRUE]", 0, true, 0.0, true, 1.0);
#endif
	g_Cvar_Resources = CreateConVar("sm_antitk_resources", "0", "Is the Anti-TK Manager resource remove option enabled or disabled? [0 = FALSE, 1 = TRUE]", 0, true, 0.0, true, 1.0);
	g_Cvar_ResourceSteal = CreateConVar("sm_antitk_resource_steal", "1", "Should the Anti-TK resource option give resources to the victim? [0 = FALSE, 1 = TRUE]", 0, true, 0.0, true, 1.0);
	g_Cvar_ResourceAmount = CreateConVar("sm_antitk_resource_amount", "0.2", "Anti-TK Manager resource removal amount. (0.0-1.0 equates to a percentage, otherwise it's an amount) [DEFAULT: 0.20 (20%)]");
}

public Action:Command_Test(client, args)
{
	PrintToChat(client, "*************************");
	PrintToChat(client, "Health: %i", GetClientHealth(client));
	PrintToChat(client, "MaxHealth: %i", g_Player_MaxHealth[client]);
	SetEntityHealth(client, 70);
	PrintToChat(client, "*************************");
}

public Action:Timer_EnableAntiTK(Handle:timer, any:client)
{
	LogDebug(false, "Timer_EnableAntiTK - Re-Enabling Anti-TK");

	SetConVarInt(g_Cvar_Enabled, 1);

	g_Enable_Timer = INVALID_HANDLE;
	return Plugin_Stop;
}

public CvarChange_PurgeTime(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	LogDebug(false, "CvarChange_PurgeTime - Purge time has been changed, updating timer. Old interval: %s New interval: %s", oldvalue, newvalue);

	if (g_Purge_Timer != INVALID_HANDLE)
	{
		CloseHandle(g_Purge_Timer);
		g_Purge_Timer = INVALID_HANDLE;
	}

	g_Purge_Timer = CreateTimer(StringToFloat(newvalue), Timer_PurgeTKerData, _, TIMER_REPEAT);
}

// Function from Log Helper made by psychonic
// http://forums.alliedmods.net/showthread.php?t=100084

stock GetTeams(bool:insmod = false)
{
	if (!insmod)
	{
		new max_teams_count = GetTeamCount();
		for (new team_index = 0; (team_index < max_teams_count); team_index++)
		{
			decl String: team_name[64];
			GetTeamName(team_index, team_name, sizeof(team_name));

			if (strcmp(team_name, "") != 0)
			{
				g_team_list[team_index] = team_name;
			}
		}
	}
	else
	{
		// they really need to get their act together... GetTeamName() would be awesome since they can't even keep their team indexes consistent
		decl String:mapname[64];
		GetCurrentMap(mapname, sizeof(mapname));
		if (strcmp(mapname, "ins_karam") == 0 || strcmp(mapname, "ins_baghdad") == 0)
		{
			g_team_list[1] = "Iraqi Insurgents";
			g_team_list[2] = "U.S. Marines";
		}
		else
		{
			g_team_list[1] = "U.S. Marines";
			g_team_list[2] = "Iraqi Insurgents";
		}
		g_team_list[0] = "Unassigned";
		g_team_list[3] = "SPECTATOR";
	}
}

ResetPlayer(index, bool:FromDatabase = false)
{
	// Last TKer name
	arrayPlayerTKerName[index] = "";

	if (!FromDatabase)
	{
#if _DEBUG >= 2
		LogDebug(false, "Reseting arrays for index: %d", index);
#endif
		// Reset Player Values
		arrayPlayerStats[index][STAT_KARMA] = 0;
		arrayPlayerStats[index][STAT_KILLS] = 0;
		arrayPlayerStats[index][STAT_TEAM_KILLS] = 0;
		arrayPlayerStats[index][STAT_LAST_TKER] = 0;
		arrayPlayerStats[index][STAT_TKER_RESOURCES] = 0;

		arrayPlayerSpawnTime[index] = 0;
	}
	else
	{
		// Retrieve TKer Data
		if (RetrieveTKer(index))
		{
#if _DEBUG >= 2
			LogDebug(false, "TKer data retrieved from file for index: %i", index);
#endif
		}
		else
		{
#if _DEBUG >= 2
			LogDebug(false, "Could not find TKer data in file for index: %i", index);
			LogDebug(false, "Reseting arrays for index: %d", index);
#endif
			// Initialize Player Stats
			arrayPlayerStats[index][STAT_KARMA] = 0;
			arrayPlayerStats[index][STAT_KILLS] = 0;
			arrayPlayerStats[index][STAT_TEAM_KILLS] = 0;
		}
		arrayPlayerStats[index][STAT_LAST_TKER] = 0;
		arrayPlayerStats[index][STAT_TKER_RESOURCES] = 0;

		arrayPlayerSpawnTime[index] = 0;
	}

	if (arrayPlayerPunishments[index] != INVALID_HANDLE)
	{
		// Punishment Array already exists clear it?
#if _DEBUG >= 2
		LogDebug(false, "Clearing Old Punishments Array?: %i", arrayPlayerPunishments[index]);
#endif
		ClearArray(arrayPlayerPunishments[index]);
	}
	else
	{
		// Create Array for Punishment queue
#if _DEBUG >= 2
		LogDebug(false, "Creating New Punishments Array For Client: %i", index);
#endif
		arrayPlayerPunishments[index] = CreateArray(1);
	}

	// Reset Max Player Health
	g_Player_MaxHealth[index] = 0;
}

// Player initialize functions
InitializePlayer(index, bool:FromDatabase = false)
{
#if _DEBUG >= 2
	LogDebug(false, "Running InitializePlayer() on player: %d", index);
#endif

	if (!IsFakeClient(index))
		ResetPlayer(index, FromDatabase);

/*
	if (arrayPlayerStats[index] != INVALID_HANDLE)
	{
		// Stats Array already exists clear it?
		LogDebug("Clearing Old Stats Array?: %i", arrayPlayerStats[index]);
		ClearArray(arrayPlayerStats[index]);
	}
	else
	{
		// Create Array for Stats
		LogDebug("Creating New Stats Array For Client: %i", index);
		arrayPlayerStats[index] = CreateArray(1);
	}

	// Retrieve Old Player Settings?

	// Initialize New Player

	// Karma
	PushArrayCell(arrayPlayerStats[index], 0);
	// Kills
	PushArrayCell(arrayPlayerStats[index], 0);
	// Team Kills
	PushArrayCell(arrayPlayerStats[index], 0);
	// Last TKer player index
	PushArrayCell(arrayPlayerStats[index], 0);


	LogDebug("TEST TK COUNT???: %i CLIENT: %d", GetArrayCell(arrayPlayerStats[index], STAT_TEAM_KILLS), index);
*/
}

antitk_Initialize()
{
	LogDebug(false, "antitk_Initialize - Anti-TK Plugin Initializing!");

	if (GetConVarBool(g_Cvar_Enabled))
	{
		LogDebug(false, "antitk_Initialize - Plugin Enabled! Running EnablePlugin.");
		EnablePlugin();
	}

	new players = GetMaxClients();

	for (new i = 1; i <= players; i++)
	{
		if (IsClientInGame(i))
		{
			// Initialize Player Settings
			InitializePlayer(i, true);
		}
	}

	if (g_Purge_Timer == INVALID_HANDLE)
	{
		LogDebug(false, "antitk_Initialize - Creating Purge timer.");
		g_Purge_Timer = CreateTimer(GetConVarFloat(g_Cvar_PurgeTime), Timer_PurgeTKerData, _, TIMER_REPEAT);
	}
	else
		LogDebug(false, "antitk_Initialize - ERROR: Purge timer already exists? This should not happen?");

	// Run Initial Purge
	PurgeTKerData(0, false);
}

public Action:Timer_PurgeTKerData(Handle:Timer)
{
#if _DEBUG >= 2
	LogDebug(false, "Timer_PurgeTKerData - Timer is executing... Interval: %f", GetConVarFloat(g_Cvar_PurgeTime));
#endif
	new Float:PurgeTime = GetConVarFloat(g_Cvar_PurgeTime);
	PurgeTKerData(RoundToFloor(PurgeTime), true);
#if _DEBUG >= 2
	LogDebug(false, "Timer_PurgeTKerData - Timer has finished, waiting for next interval.");
#endif
	return Plugin_Continue;
}


// Reset punishment effects
KillPunishments(index = 0)
{
	LogDebug(false, "KillPunishments - Resetting all punishments.");

	// Kill Punishments (based off funcommands.sp)
	if (index == 0)
	{
#if BEACON
	KillAllBeacons();
#endif
#if FIRE
	KillAllFireBombs();
#endif
#if ICE
	KillAllFreezes();
#endif
#if TIMEBOMB
	KillAllTimeBombs();
#endif
#if DRUG
	KillAllDrugs();
#endif
	}
	else
	{
#if BEACON
	KillBeacon(index);
#endif
#if FIRE
	KillFireBomb(index);
#endif
#if ICE
	UnfreezeClient(index);
#endif
#if TIMEBOMB
	KillTimeBomb(index);
#endif
#if DRUG
	KillDrug(index);
#endif	
	}
}


// Events
public OnMapStart()
{
#if _DEBUG
	BuildLogFilePath();
#endif

	// Precache Sounds (based off funcommands.sp)
	PrecacheSound(SOUND_BLIP, true);
	PrecacheSound(SOUND_BEEP, true);
	PrecacheSound(SOUND_FINAL, true);
	PrecacheSound(SOUND_BOOM, true);
	PrecacheSound(SOUND_FREEZE, true);

#if SLAY
	PrecacheSound(SOUND_SLAY, true);
#endif

	// Precache Models & Index (based off funcommands.sp)
#if BEACON || TIMEBOMB || FIRE || ICE
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
#endif
#if ICE || TIMEBOMB
	g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
#endif
#if ICE
	g_GlowSprite = PrecacheModel("sprites/blueglow2.vmt");
	g_BeamSprite2 = PrecacheModel("sprites/bluelight1.vmt");
#endif
#if SLAY
	g_Lightning = PrecacheModel("sprites/lgtning.vmt");
#endif

	AutoExecConfig(true, "antitk");

	// Load TKers from Key Values
	ReadTKers();

	// Cache Team Names for Log Events (Log Helper)
	GetTeams(Insurgency);
}

public OnMapEnd()
{
	LogDebug(false, "Map Ended - Resetting all punishments.");

	// Kill Punishments
	KillPunishments();

	// Save TKer Data
	SaveTKers();
}

public OnClientPostAdminCheck(index)
{
#if _DEBUG >= 2
	LogDebug(false, "OnClientPostAdminCheck - Client: %d", index);
#endif
	InitializePlayer(index, true);

	// Store player name in case they leave the server.
	GetClientName(index, arrayPlayerName[index], MAX_NAME_LENGTH);
}

public OnClientDisconnect(index)
{
#if _DEBUG >= 2
	LogDebug(false, "OnClientDisconnected - Client: %d", index);
#endif
	// Store Player Stats History
	if (!IsFakeClient(index))
	{
		SaveTKer(index);
		ResetPlayer(index, false);
	}
	// Kill Punishments?
	//KillPunishments(index);
}

public Action:Event_RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	LogDebug(false, "Round Started - Checking Round Protection.");

	if (GetConVarBool(g_Cvar_Enabled))
	{
		new Float:ProtectTime = GetConVarFloat(g_Cvar_RoundStartTime);

		if (GetConVarFloat(g_Cvar_RoundStartTime) > 0.0)
		{
			LogDebug(false, "Event_RoundStart - Round Protection Enabled.");

			if (ProtectTime > 0)
			{
				LogDebug(false, "Event_RoundStart - Round Start Time set to %f seconds.", ProtectTime);

				RoundStartTime = GetTime();
				RoundProtect = true;
				//PrintToChatAll("%t", "Eject_Announce_Kick", tkerName);
			}
		}
		else
		{
			LogDebug(false, "Event_RoundStart - Round Protection Disabled.");

			if (ProtectTime > 0)
			{
				LogDebug(false, "Event_RoundStart - Round Start Time set to %i seconds. Disabling Plugin.");
				SetConVarInt(g_Cvar_Enabled, 0);

				if (g_Enable_Timer != INVALID_HANDLE)
				{
					CloseHandle(g_Enable_Timer);
					g_Enable_Timer = INVALID_HANDLE;
				}

				g_Enable_Timer = CreateTimer(ProtectTime, Timer_EnableAntiTK);
				//PrintToChatAll("%t", "Eject_Announce_Kick", tkerName);
			}
		}
	}

	return Plugin_Handled;
}

public Action:Event_RoundEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
	LogDebug(false, "Round Ended - Resetting all punishments.");

	// Kill Punishments
	KillPunishments();

	return Plugin_Handled;
}

Action:CheckTKDetails(victim, attacker, bool:PlayerDeath=true)
{
	decl String:attacker_name[MAX_NAME_LENGTH];

	if(attacker != 0 && victim != 0 && IsClientConnected(attacker) && IsClientConnected(victim) && victim != attacker)
	{
		if (GetConVarBool(g_Cvar_AdminsImmune))
		{
			if (CheckAdminImmunity(attacker))
				return 	Plugin_Continue;
		}

		new victimTeam = GetClientTeam(victim);
		new attackerTeam = GetClientTeam(attacker);

		if(victimTeam == attackerTeam)
		{
			GetClientName(attacker, attacker_name, sizeof(attacker_name));

			// Handle TK Event
			LogDebug(false, "Player TK event triggered: Victim Team: %i Attacker Team: %i", victimTeam, attackerTeam);

			// ZPS Related Check
			if (ZombiePanic)
			{
				if (offsInfected > 0)
				{
					new infected = GetEntDataEnt2(victim, offsInfected);

					if (infected && (victimTeam == TEAM_ZPS_SURVIVOR))
					{
						LogDebug(false, "TK'd Infected Human, Legitimate?");
						return Plugin_Continue;
					}
				}
			}

			// Store Victim's last Tk'er details
			arrayPlayerStats[victim][STAT_LAST_TKER] = attacker;
			arrayPlayerTKerName[victim] = attacker_name;

			LogDebug(false, "WARNING: Attackers name: %s",attacker_name);

			if (RoundProtect)
			{
				new curTime = GetTime();
				new ProtectTime = GetConVarInt(g_Cvar_RoundStartTime);

				if ((curTime - RoundStartTime) > ProtectTime)
				{
					RoundProtect = false;

					if (PlayerDeath)
					{
						// Show TK Punishment menu to Victim
						LogDebug(false, "Creating TK Menu to victim for player: %s",attacker_name);
						CreateTKMenu(victim);
					}
				}
				else
				{
					LogDebug(false, "Round protection event");

					new ProtectType = GetConVarInt(g_Cvar_RoundStartType);

					if (ProtectType == 0)
						ForgivePlayer(victim, attacker);
					else
						PunishPlayer(victim, attacker, ProtectType);
				}
			}
			else
			{
				// Show TK Punishment menu to Victim
				LogDebug(false, "Creating TK Menu for player: %s",attacker_name);
				CreateTKMenu(victim);
			}
		}
		else
		{
			if (PlayerDeath)
			{
				GetClientName(attacker, attacker_name, sizeof(attacker_name));

				// Handle Karma
				new karma_kills = GetConVarInt(g_Cvar_KarmaKills);
				if (karma_kills)
				{
					arrayPlayerStats[attacker][STAT_KILLS]++;
					LogDebug(false, "Calculating Karma for player: %s Kills: %d Required: %d",attacker_name, arrayPlayerStats[attacker][STAT_KILLS], karma_kills);
					if (arrayPlayerStats[attacker][STAT_KILLS] >= karma_kills)
						if (arrayPlayerStats[attacker][STAT_TEAM_KILLS] > 0)
						{
							arrayPlayerStats[attacker][STAT_TEAM_KILLS]--;
							arrayPlayerStats[attacker][STAT_KILLS] = 0;
							LogDebug(false, "Player: %s has received Karma New TK Count: %d",attacker_name, arrayPlayerStats[attacker][STAT_TEAM_KILLS]);
						}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast){
	if (GetConVarBool(g_Cvar_Enabled))
	{
		new victim = GetClientOfUserId(GetEventInt(event,"userid"));
		new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));

		LogDebug(false, "Event_PlayerHurt - Attacker: %i Victim: %i", attacker, victim);
		if(attacker != 0)
		{
			if (GetConVarBool(g_Cvar_AdminsImmune))
			{
				if (CheckAdminImmunity(attacker))
					return 	Plugin_Continue;
			}

			if (RoundProtect)
			{
				new curTime = GetTime();
				new ProtectTime = GetConVarInt(g_Cvar_RoundStartTime);

				if ((curTime - RoundStartTime) > ProtectTime)
				{
					RoundProtect = false;
				}
				else
				{
					LogDebug(false, "Event_PlayerHurt - Round Protection");
					return CheckTKDetails(victim, attacker, false);
				}
			}

			if (GetConVarInt(g_Cvar_MirrorDamage) > 0)
			{
				new Float:mirror_percent = GetConVarFloat(g_Cvar_MirrorDamagePercent);
				if (mirror_percent > 0.0)
				{
					if( ( (attacker > 0) && (victim > 0) ) && (victim != attacker) )
					{
						if ( GetClientTeam(attacker) == GetClientTeam(victim) )
						{
							LogDebug(false, "Event_PlayerHurt - Mirror Damage enabled. Attacker and Victim are on the same team and valid players.");
							//new bool:spawnAttack = ((GetTime() - SpawnTime[victim]) <= GetConVarInt(g_CvarSpawnProtect));
							new damage_armor = 0;
							decl damage_health;

							if (PVKII)
							{
								damage_health = GetEventInt(event,"health");
							}
							else if (CounterStrike)
							{
								damage_health = GetEventInt(event,"dmg_health");
							}
							else
							{
								damage_health = GetEventInt(event,"health");
								damage_armor = 0;
							}
							LogDebug(false, "Event_PlayerHurt - Damage done to health: %i armor: %i", damage_health, damage_armor);

							if ( IsClientInGame(attacker) && IsPlayerAlive(attacker) )
							{
								LogDebug(false, "Event_PlayerHurt - Attackers Health: %i", GetClientHealth(attacker));
								LogDebug(false, "Event_PlayerHurt - Mirror Damage Percent: %f", mirror_percent);
								new mirror_damage_health = RoundFloat(damage_health * (mirror_percent / 100.0));
								LogDebug(false, "Event_PlayerHurt - Mirror Damage Health: %i Armor: %i", mirror_damage_health, RoundFloat(damage_armor * (mirror_percent / 100.0)));
								new attackerHealth = GetClientHealth(attacker) - mirror_damage_health;
								new attackerArmor = GetClientArmor(attacker) - RoundFloat(damage_armor * (mirror_percent / 100.0));
								LogDebug(false, "Event_PlayerHurt - Attackers health will become: %i", attackerHealth);
								LogDebug(false, "Event_PlayerHurt - Attackers armor will become: %i", attackerArmor);

								if(attackerHealth <= 0)
								{
									LogDebug(false, "Event_PlayerHurt - New health kills the attacker, will slay attacker: %i", attacker);
									PunishPlayer(victim, attacker, ATK_SLAY, false);
								}
								else
								{
									if (attackerArmor < 0)
										attackerArmor = 0;

									//Set Armor?

									// Remove Attacker Health (Set new health)
									if (MirrorDamageSlap)
									{
										InformTKClients(victim, attacker, ATK_SLAP, true);
										SlapPlayer(attacker, mirror_damage_health, true);
									}
									else
										SetEntityHealth(attacker, attackerHealth);
									LogDebug(false, "Event_PlayerHurt - Finished setting attackers new health.");
								}
								LogDebug(false, "Event_PlayerHurt - Mirrored damage to attacker: %i", attacker);
							}

							if (IsClientInGame(victim))
							{
								if (IsPlayerAlive(victim))
								{
									if (GetConVarInt(g_Cvar_MirrorDamage) == 2)
									{
										new victimHealth = GetClientHealth(victim) + damage_health;

										if(victimHealth > g_Player_MaxHealth[victim])
											SetEntityHealth(victim, g_Player_MaxHealth[victim]);
										else
											SetEntityHealth(victim, victimHealth);
										LogDebug(false, "Event_PlayerHurt - Returned damage to victim: %i", victim);
									}
								}
								else
								{

								}
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast){
	if (GetConVarBool(g_Cvar_Enabled))
	{
		new victim = GetClientOfUserId(GetEventInt(event,"userid"));
		new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));

		return CheckTKDetails(victim, attacker);
	}
	return Plugin_Continue;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (client > 0)
	{
		if (GetConVarBool(g_Cvar_Enabled))
		{
			g_Player_MaxHealth[client] = GetClientHealth(client);

			if (!IsFakeClient(client))
			{
				arrayPlayerSpawnTime[client] = GetTime();

				SetEntityGravity(client, 1.0);

				// Check Punishment Queue
				new arrPunishmentSize = GetArraySize(arrayPlayerPunishments[client]);
				decl arrVictimIndex, arrPunishmentIndex, victim, type;

				// Quick check if array is damaged?
				if (FloatFraction(arrPunishmentSize / 2.0) == 0.0)
				{
					if (arrPunishmentSize > 0)
					{
						LogDebug(false, "TKer Client: %d spawned and has queued punishments?", client);

						// Array Indexes
						arrVictimIndex = arrPunishmentSize - 2;
						arrPunishmentIndex = arrPunishmentSize - 1;

						// Array Values
						victim = GetArrayCell(arrayPlayerPunishments[client],arrVictimIndex);
						type = GetArrayCell(arrayPlayerPunishments[client],arrPunishmentIndex);

						LogDebug(false, "TKer Client: %d Victim: %d Punishment type: %d", client, victim, type);

						// Remove Punishment from Array
						RemoveFromArray(arrayPlayerPunishments[client],arrPunishmentIndex);
						RemoveFromArray(arrayPlayerPunishments[client],arrVictimIndex);

						// Punish TK'er
						PunishPlayer(victim, client, type, false);
					}
				}
				else
					LogDebug(false, "Punishment array was damaged? Size: %d", arrPunishmentSize);
			}
		}
	}
}


// Menu Functions
CreateTKMenu(victim)
{
	decl String:victimName[MAX_NAME_LENGTH];

	GetClientName(victim,victimName,sizeof(victimName));
	new attacker = arrayPlayerStats[victim][STAT_LAST_TKER];

	PrintToConsole(victim, "[Anti-TK] %t", "TK_Message_Victim", arrayPlayerTKerName[victim]);
	PrintToChat(victim, "%c[Anti-TK]%c %t", ANTITK_COLOR, 1, "TK_Message_Victim", arrayPlayerTKerName[victim]);

	PrintToConsole(attacker, "[Anti-TK] %t", "TK_Message_TKer", victimName);
	PrintToChat(attacker, "%c[Anti-TK]%c %t", ANTITK_COLOR, 1, "TK_Message_TKer", victimName);

	new Handle:menu = CreateMenu(PunishmentMenuSelected);
	SetMenuTitle(menu,"[Anti-TK] %T", "Menu_Title", victim, arrayPlayerTKerName[victim]);

	// Disable Exit
	SetMenuExitButton(menu,false);

	decl String:MenuItem[128];
	new String:iStr[4];

	for (new i = 0; i < ATK_PUNISHMENTS; i++)
	{
		IntToString(i, iStr, sizeof(iStr));

		switch (i)
		{
			case ATK_FORGIVE:
			{
				Format(MenuItem, sizeof(MenuItem),"%T", "Menu_Forgive", victim);
				AddMenuItem(menu,iStr,MenuItem);
			}
			case ATK_SLAY:
			{
#if SLAY
				if (GetConVarBool(g_Cvar_Slay))
				{
					Format(MenuItem, sizeof(MenuItem),"%T", "Menu_Slay", victim);
					AddMenuItem(menu,iStr,MenuItem);
				}
#endif
			}
			case ATK_SLAP:
			{
#if SLAP
				if (GetConVarBool(g_Cvar_Slap))
				{
					Format(MenuItem, sizeof(MenuItem),"%T", "Menu_Slap", victim, GetConVarInt(g_Cvar_SlapDamage));
					AddMenuItem(menu,iStr,MenuItem);
				}
#endif
			}
			case ATK_BEACON:
			{
#if BEACON
				if (GetConVarBool(g_Cvar_Beacon))
				{
					Format(MenuItem, sizeof(MenuItem),"%T", "Menu_Beacon", victim);
					AddMenuItem(menu,iStr,MenuItem);
				}
#endif
			}
			case ATK_BURN:
			{
#if FIRE
				if (GetConVarBool(g_Cvar_Burn))
				{
					Format(MenuItem, sizeof(MenuItem),"%T", "Menu_Burn", victim, GetConVarInt(g_Cvar_BurnDuration));
					AddMenuItem(menu,iStr,MenuItem);
				}
#endif
			}
			case ATK_FIREBOMB:
			{
#if FIRE
				if (GetConVarBool(g_Cvar_FireBomb))
				{
					Format(MenuItem, sizeof(MenuItem),"%T", "Menu_FireBomb", victim, GetConVarInt(g_Cvar_BurnDuration));
					AddMenuItem(menu,iStr,MenuItem);
				}
#endif
			}
			case ATK_FREEZE:
			{
#if ICE
				if (GetConVarBool(g_Cvar_Freeze))
				{
					Format(MenuItem, sizeof(MenuItem),"%T", "Menu_Freeze", victim, GetConVarInt(g_Cvar_FreezeDuration));
					AddMenuItem(menu,iStr,MenuItem);
				}
#endif
			}
			case ATK_FREEZEBOMB:
			{
#if ICE
				if (GetConVarBool(g_Cvar_FreezeBomb))
				{
					Format(MenuItem, sizeof(MenuItem),"%T", "Menu_FreezeBomb", victim, GetConVarInt(g_Cvar_FreezeDuration));
					AddMenuItem(menu,iStr,MenuItem);
				}
#endif
			}
			case ATK_SLOW:
			{
#if GRAVITY
				if (GetConVarBool(g_Cvar_Slow))
				{
					Format(MenuItem, sizeof(MenuItem),"%T", "Menu_Slow", victim);
					AddMenuItem(menu,iStr,MenuItem);
				}
#endif
			}
			case ATK_BLIND:
			{
#if BLIND
				if (GetConVarBool(g_Cvar_Blind))
				{
					Format(MenuItem, sizeof(MenuItem),"%T", "Menu_Blind", victim);
					AddMenuItem(menu,iStr,MenuItem);
				}
#endif
			}
			case ATK_DRUG:
			{
#if DRUG
				// Drug Crashes Insurgency
				if (!Insurgency)
					if (GetConVarBool(g_Cvar_Drug))
					{
						Format(MenuItem, sizeof(MenuItem),"%T", "Menu_Drug", victim);
						AddMenuItem(menu,iStr,MenuItem);
					}
#endif
			}
			case ATK_TIMEBOMB:
			{
#if TIMEBOMB
				if (GetConVarBool(g_Cvar_TimeBomb))
				{
					Format(MenuItem, sizeof(MenuItem),"%T", "Menu_TimeBomb", victim, GetConVarInt(g_Cvar_TimeBombTicks));
					AddMenuItem(menu,iStr,MenuItem);
				}
#endif
			}
			case ATK_RESOURCES:
			{
				if (GetConVarBool(g_Cvar_Resources))
				{
					if (offsResourceAmount > 0)
					{
						new Float:amount = GetConVarFloat(g_Cvar_ResourceAmount);
						decl Float:resources;
	
						if (amount > 0.0)
						{
							resources = amount;
							if (amount <= 1.0)
							{
								LogDebug(false, "Player: %s has %i resources", arrayPlayerTKerName[victim], GetEntData(attacker, offsResourceAmount));
								resources = GetEntData(attacker, offsResourceAmount) * amount;
								LogDebug(false, "Resource punishment should remove %f resources", resources);
							}
							
							arrayPlayerStats[victim][STAT_TKER_RESOURCES] = (RoundFloat(resources) * -1);
							Format(MenuItem, sizeof(MenuItem),"%T", "Menu_Resources", victim, RoundFloat(resources));
							AddMenuItem(menu,iStr,MenuItem);
						}
					}
				}
			}
		}
	}

	if (GetMenuItemCount(menu) < 2)
	{
		IntToString(ATK_NOFORGIVE, iStr, sizeof(iStr));

		Format(MenuItem, sizeof(MenuItem),"%T", "Menu_NoForgive", victim);
		AddMenuItem(menu,iStr,MenuItem);
	}

	LogDebug(false, "Displaying Punishment menu to Victim: %d TKer: %d", victim, attacker);
	DisplayMenu(menu,victim,MENU_TIME_FOREVER);
}

public PunishmentMenuSelected(Handle:menu, MenuAction:action, param1, param2)
{
	new victim = param1;
	new tker = 0;

	if (victim > 0)
	{
		tker = arrayPlayerStats[victim][STAT_LAST_TKER];
	}

	decl String:tmp[32], pMenuItemSelected;
	GetMenuItem(menu, param2, tmp, sizeof(tmp));
	pMenuItemSelected = StringToInt(tmp);

	switch (action)
	{
		case MenuAction_Select:
		{
			if (victim > 0)
			{
				switch (pMenuItemSelected)
				{
					case ATK_FORGIVE:
					{
						ForgivePlayer(victim,tker);
					}
					case ATK_RESOURCES:
					{
						PunishPlayer(victim, tker, pMenuItemSelected);
					}
					default:
					{
						arrayPlayerStats[victim][STAT_TKER_RESOURCES] = 0;
						PunishPlayer(victim, tker, pMenuItemSelected);
					}
				}
/*
					for (new attacker=1; attacker <= PlayerSlots; ++attacker)
					{
						if(IsClientConnected(attacker) && IsClientInGame(attacker) && killed[attacker][param1] && attacker != 0)
						{
							killed[attacker][param1] = false;

							TextOutput(1,attacker,param1,"Forgiven");
							if(hlxEnabled)
							{
								decl String:attackerSteamID[64];
								GetClientName(attacker,attackerName,64);
								GetClientAuthString(attacker, attackerSteamID, 64);
								LogToGame("\"%s<%d><%s><ATAC>\" triggered \"Forgiven_For_TeamKill\"",attackerName,GetClientUserId(attacker),attackerSteamID);
							}
						}
					}

					new tkCount = GetConVarInt(cvarATACTKCount);
					for(new attacker = 1; attacker <= PlayerSlots; ++attacker){
						if(IsClientConnected(attacker) && IsClientInGame(attacker) && killed[attacker][param1] && attacker != 0){
							GetClientName(attacker,attackerName,64);
							tkCounter[attacker]++;
							if(tkCount > 0 && tkCounter[attacker] >= tkCount){
								if(TKAction(attacker,param1)){
									return;
								}
								tkCounter[attacker] = 0;
								killed[attacker][param1] = false;
							}else{
								killed[attacker][param1] = false;
							}
		
							TextOutput2(attacker,param1,"Not Forgiven",tkCounter[attacker],tkCount);
							if(hlxEnabled){
								decl String:attackerSteamID[64];
								GetClientName(attacker,attackerName,64);
								GetClientAuthString(attacker, attackerSteamID, 64);
								LogToGame("\"%s<%d><%s><ATAC>\" triggered \"Punished_For_TeamKill\"",attackerName,GetClientUserId(attacker),attackerSteamID);
							}
						}
					}

					new Handle:ATAC_Menu = Handle:StringToInt(SelectionInfo);
					if(ATAC_Menu != INVALID_HANDLE){
						for(new attacker = 1; attacker <= PlayerSlots; ++attacker){
							if(IsClientConnected(attacker) && IsClientInGame(attacker) && killed[attacker][param1] && attacker != 0){
								Call_StartForward(ATAC_Menu);
								Call_PushCell(param1);
								Call_PushCell(attacker);
								Call_Finish();
								if(hlxEnabled){
									decl String:attackerSteamID[64];
									GetClientName(attacker,attackerName,64);
									GetClientAuthString(attacker, attackerSteamID, 64);
									LogToGame("\"%s<%d><%s><ATAC>\" triggered \"Punished_For_TeamKill\"",attackerName,GetClientUserId(attacker),attackerSteamID);
								}
								killed[attacker][param1] = false;
							}
						}
					}
*/
			}
		}

		case MenuAction_Cancel:
		{
			// Will not work because sometimes param1 is 0?
			if ((victim > 0) && (tker > 0))
			{
				LogDebug(false, "Punishment Menu was Cancelled? Forgive Tker? Victim: %d Tker: %d", victim, tker);
				ForgivePlayer(victim,tker);
			}
		}

		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}



ForgivePlayer(victim,tker)
{
	// Forgive Player
	LogDebug(false, "Victim: %d forgave TK'er: %d", victim, tker);
	new String: tker_authid[32] = "UNKNOWN";
	new String: victim_authid[32] = "UNKNOWN";
	new Float:tker_origin[3] = {0.0,0.0,0.0};
	new Float:victim_origin[3] = {0.0,0.0,0.0};
	new tker_clientid = 0;
	new victim_clientid = 0;

	GetClientAuthString(victim, victim_authid, sizeof(victim_authid));


	GetClientAbsOrigin(victim, victim_origin);
	victim_clientid = GetClientUserId(victim);

	new victim_team = GetClientTeam(victim); // Teams should be the same because it's a TK?

	if (IsClientInGame(tker))
	{
		GetClientAuthString(tker, tker_authid, sizeof(tker_authid));

		GetClientAbsOrigin(tker, tker_origin);
		tker_clientid = GetClientUserId(tker);

		if (IsPlayerAlive(tker))
			InformTKClients(victim, tker, 0, true);
		else
			InformTKClients(victim, tker, 0, false);

		// Log Stats Based Forgive Log Message
		LogToGame("\"%N<%d><%s><%s>\" %s \"%s\" against \"%N<%d><%s><%s>\" (position \"%d %d %d\") (victim_position \"%d %d %d\")", tker, tker_clientid, tker_authid, g_team_list[victim_team], "triggered", "Forgiven_For_Teamkill", victim, victim_clientid, victim_authid, g_team_list[victim_team], RoundFloat(tker_origin[0]), RoundFloat(tker_origin[1]), RoundFloat(tker_origin[2]), RoundFloat(victim_origin[0]), RoundFloat(victim_origin[1]), RoundFloat(victim_origin[2])); 
	}
	else
	{
		InformTKClients(victim, tker, 0, false);

		// Log Stats Based Forgive Log Message
		LogToGame("\"%N<%d><%s><%s>\" %s \"%s\" against \"%N<%d><%s><%s>\" (position \"%d %d %d\") (victim_position \"%d %d %d\")", arrayPlayerTKerName, tker_clientid, tker_authid, g_team_list[victim_team], "triggered", "Forgiven_For_Teamkill", victim, victim_clientid, victim_authid, g_team_list[victim_team], RoundFloat(tker_origin[0]), RoundFloat(tker_origin[1]), RoundFloat(tker_origin[2]), RoundFloat(victim_origin[0]), RoundFloat(victim_origin[1]), RoundFloat(victim_origin[2])); 	
	}
}

KillPlayer(index)
{
	if (IsClientInGame(index) && IsPlayerAlive(index))
	{
		if (Insurgency)
			ForcePlayerSuicide(index);
		else if (ZombiePanic)
		{
			// Slay Custom Function from Rawr of the Vortex ZPS server (Fix for instant death in ZPS)
			decl String:dName[32], Entity;
			Format(dName, sizeof(dName), "pd_%d", index);

			Entity = CreateEntityByName("env_entity_dissolver");

			if (Entity)
			{
				DispatchKeyValue(index, "targetname", dName);
				DispatchKeyValue(Entity, "target", dName);
				AcceptEntityInput(Entity, "Dissolve");
				AcceptEntityInput(Entity, "kill");
			}
		}
		else
		{
			if (GetConVarBool(g_Cvar_SpecialSlay))
			{
				new Float:vec[3];
				new Float:pos[3];
				new Float:end[3];
				GetClientAbsOrigin(index, pos);
				new Float:dir[3] = {0.0, 0.0, 0.0};
				TE_SetupSparks(pos, dir, 500, 100);
				TE_SendToAll();
				end = pos;
				end[2] += 500;
				new color[4] = {255, 255, 255, 255};
				TE_SetupBeamPoints(pos, end, g_Lightning, 0, 0, 5, 1.0, 10.0, 10.0, 1, 0.0, color, 64);
				TE_SendToAll();
				GetClientEyePosition(index, vec);
				EmitAmbientSound(SOUND_SLAY, vec, index, SNDLEVEL_RAIDSIREN);
			}
			ForcePlayerSuicide(index);
		}
	}
}

// Remove TK'er from server
public Action:EjectTKer(tker, victim)
{
	decl String:tkerName[MAX_NAME_LENGTH], String:type[32];

	GetClientName(tker, tkerName, sizeof(tkerName));

	new method = GetConVarInt(g_Cvar_AntiTKType);

	LogDebug(false, "EjectTKer - Using eject mode: %i on client %s on behalf of victim %i", method, tkerName, victim);
	switch (method)
	{
		case 0:
		{
			LogDebug(false, "WARNING: sm_antitk_type is set to 0 and sm_antitk_max has been defined?");
			return Plugin_Continue;
		}
		case 1:
		{
			type = "kicked";
			KickClient(tker, "[Anti-TK] %t", "Eject_Message_Kick_TKer");

			PrintToChat(victim, "%c[Anti-TK]%c %t", ANTITK_COLOR, 1, "Eject_Message_Victim_Kick", tkerName);
			PrintToConsole(victim, "[Anti-TK] %t", "Eject_Message_Victim_Kick", tkerName);

			PrintToChatAll("%c[Anti-TK]%c %t", ANTITK_COLOR, 1, "Eject_Announce_Kick", tkerName);
		}
		case 2:
		{
			type = "banned";
			new bantime = GetConVarInt(g_Cvar_BanTime);

			LogAction(0, -1, "[Anti-TK] %T", "Ban_Log", LANG_SERVER, tker);
			decl String:ban_message[128];
			Format(ban_message, sizeof(ban_message), "[Anti-TK] %T", "Eject_Message_Ban_TKer", tker);

			if (g_bSBAvailable)
			{
#if defined _sourcebans_included
				SBBanPlayer(0, tker, bantime, ban_message);
				LogDebug(false, "EjectTKer - Banned Player via SourceBans.");
#else
				LogDebug(false, "WARNING: SourceBans is loaded but plugin was not compiled with SourceBans Include file.");
				LogDebug(false, "WARNING: Banning player without using SourceBans!");	
				BanClient(tker,bantime, BANFLAG_AUTO, ban_message, ban_message, "sm_ban", tker);
#endif
			}
			else
				BanClient(tker,bantime, BANFLAG_AUTO, ban_message, ban_message, "sm_ban", tker);

			PrintToChat(victim, "%c[Anti-TK]%c %t", ANTITK_COLOR, 1, "Eject_Message_Victim_Ban", tkerName);
			PrintToConsole(victim, "[Anti-TK] %t", "Eject_Message_Victim_Ban", tkerName);

			PrintToChatAll("%c[Anti-TK]%c %t", ANTITK_COLOR, 1, "Eject_Announce_Ban", tkerName);
		}
		default:
		{
			// Could be useful as a log message
			LogDebug(false, "ERROR: sm_antitk_type is invalid and sm_antitk_max has been defined?");
			return Plugin_Continue;
		}
	}
	LogDebug(false, "%s has been %s for exceeding the TK limit.", tkerName, type);
	return Plugin_Handled;
}


// Punishment queue function for if TK'er is dead
QueuePunishment(victim, tker, type)
{
	LogDebug(false, "Punishment queued victim: %d", victim);
	LogDebug(false, "Punishment array size: %d", GetArraySize(arrayPlayerPunishments[tker]));

	PushArrayCell(arrayPlayerPunishments[tker], victim);
	PushArrayCell(arrayPlayerPunishments[tker], type);

	LogDebug(false, "New punishment queue size: %d", GetArraySize(arrayPlayerPunishments[tker]));
}


// Inform players punishment is being taken
InformTKClients(victim, tker, type, bool:now=false)
{
	decl String:victimName[MAX_NAME_LENGTH];

	if (IsClientInGame(victim))
	{
		GetClientName(victim, victimName, sizeof(victimName));
	}
	else
	{
		victimName = arrayPlayerName[victim];
	}

	decl String:tker_msg_type[64], String:victim_msg_type[64];

	if (now)
	{
		if (type < ATK_PUNISHMENTS)
		{
			Format(tker_msg_type, sizeof(tker_msg_type), "Inform_Message_TKer_%s_Now", arrayPunishmentText[type]);
			Format(victim_msg_type, sizeof(victim_msg_type), "Inform_Message_Victim_%s_Now", arrayPunishmentText[type]);
		}
		else if (type == ATK_NOFORGIVE)
		{
			Format(tker_msg_type, sizeof(tker_msg_type), "Inform_Message_TKer_NoForgive_Now");
			Format(victim_msg_type, sizeof(victim_msg_type), "Inform_Message_Victim_NoForgive_Now");
		}
	}
	else
	{
		if (type < ATK_PUNISHMENTS)
		{
			Format(tker_msg_type, sizeof(tker_msg_type), "Inform_Message_TKer_%s_Spawn", arrayPunishmentText[type]);
			Format(victim_msg_type, sizeof(victim_msg_type), "Inform_Message_Victim_%s_Spawn", arrayPunishmentText[type]);
		}
		else if (type == ATK_NOFORGIVE)
		{
			Format(tker_msg_type, sizeof(tker_msg_type), "Inform_Message_TKer_NoForgive_Spawn");
			Format(victim_msg_type, sizeof(victim_msg_type), "Inform_Message_Victim_NoForgive_Spawn");
		}
	}

	if(IsClientInGame(tker))
	{
		PrintToConsole(tker, "[Anti-TK] %t", tker_msg_type, victimName);
		PrintToChat(tker, "%c[Anti-TK]%c %t", ANTITK_COLOR, 1, tker_msg_type, victimName);
	}
	if (IsClientInGame(victim))
	{
		PrintToConsole(victim, "[Anti-TK] %t", victim_msg_type, arrayPlayerTKerName[victim]);
		PrintToChat(victim, "%c[Anti-TK]%c %t", ANTITK_COLOR, 1, victim_msg_type, arrayPlayerTKerName[victim]);
	}
	return true;
}


// Punishment Function
PunishPlayer(victim, tker, type, bool:CountTK=true)
{
	if (IsClientInGame(tker))
	{
		if (CountTK)
		{
			if ( !( (RoundProtect) && (GetConVarBool(g_Cvar_RoundStartExclude)) ) )
			{
				// Retrieve TK stats
				new maxtks = GetConVarInt(g_Cvar_MaxTKs);
				new numtk = arrayPlayerStats[tker][STAT_TEAM_KILLS];
				LogDebug(false, "TEST TK NUMBER: %d CLIENT: %d", numtk, tker);

				// Increment TK Counter
				numtk++;
				LogDebug(false, "TEST TK2 NUMBER: %d CLIENT: %d", numtk, tker);

				// Store TK count
				arrayPlayerStats[tker][STAT_TEAM_KILLS] = numtk;

				// Check TK count
				if (maxtks > 0)
				{
					LogDebug(false, "TKer: %d has TKed: %d players.",tker, numtk);
					if (numtk >= maxtks)
					{
						LogDebug(false, "TKer: %d is being ejected from the server for exceeding the TK limit: %d", tker, maxtks);

						EjectTKer(tker, victim);
						return;
					}
				}
			}
			else
				LogDebug(false, "Round Protection & TK Exclusion are Enabled, player: %d is being excluded from TK count", tker);
		}

		if (IsPlayerAlive(tker))
		{
			// Inform Client that TK action is being taken...
			InformTKClients(victim, tker, type, true);

			// Punish Player
			switch (type)
			{
				case ATK_FORGIVE:
				{
					// Forgive
					// Could be useful as a log message
					LogDebug(false, "ERROR: Victim: %d forgave TK'er: %d - Player should have already been forgiven previously?",victim,tker);
				}
				case ATK_SLAY:
				{
					// Slay Player
					LogDebug(false, "TKer: %d is being slayed for TKing", tker);
					KillPlayer(tker);
				}
				case ATK_SLAP:
				{
					// Slap Player
#if SLAP
					LogDebug(false, "TKer: %d is being slapped for TKing", tker);
					SlapPlayer(tker, GetConVarInt(g_Cvar_SlapDamage), true);
#endif
				}
				case ATK_BEACON:
				{
					// Beacon Player
#if BEACON
					LogDebug(false, "TKer: %d is being beaconed for TKing", tker);

					if (g_BeaconSerial[tker] == 0)
					{
						CreateBeacon(tker);
					}
#endif
				}
				case ATK_BURN:
				{
					LogDebug(false, "TKer: %d is being burned for TKing", tker);
#if FIRE
					IgniteEntity(tker, GetConVarFloat(g_Cvar_BurnDuration));
#endif
				}
				case ATK_FIREBOMB:
				{
#if FIRE
					LogDebug(false, "TKer: %d is being firebombed for TKing", tker);
					if (g_FireBombSerial[tker] == 0)
					{
						CreateFireBomb(tker);
					}
#endif
				}
				case ATK_FREEZE:
				{
					// Freeze Player
#if ICE
					LogDebug(false, "TKer: %d is being frozen for TKing", tker);

					if (g_FreezeSerial[tker] == 0)
					{
						FreezeClient(tker, GetConVarInt(g_Cvar_FreezeDuration));
					}
#endif
				}
				case ATK_FREEZEBOMB:
				{
					//FreezeBomb Player
#if ICE
					LogDebug(false, "TKer: %d is being freezebombed for TKing", tker);
					if (g_FreezeBombSerial[tker] == 0)
					{
						CreateFreezeBomb(tker);
					}
#endif
				}
				case ATK_SLOW:
				{
					// Slow Player
#if GRAVITY
					LogDebug(false, "TKer: %d is being slowed for TKing", tker);

					SetEntityGravity(tker, GetConVarFloat(g_Cvar_SlowGravity));
					if (Insurgency)
					{
						SetEntPropFloat(tker, Prop_Send, "m_flLaggedMovementValue", GetConVarFloat(g_Cvar_SlowSpeed));
					}
					else
						SetEntPropFloat(tker, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(g_Cvar_SlowSpeed));
#endif
				}
				case ATK_BLIND:
				{
					// Blind Player
#if BLIND
					LogDebug(false, "TKer: %d is being blinded for TKing", tker);
					PerformBlind(tker, GetConVarInt(g_Cvar_BlindAmount));
#endif
				}
				case ATK_DRUG:
				{
					// Drug Player
#if DRUG
					LogDebug(false, "TKer: %d is being drugged for TKing", tker);

					if (g_DrugTimers[tker] == INVALID_HANDLE)
					{
						CreateDrug(tker);
					}
#endif
				}
				case ATK_TIMEBOMB:
				{
					// TimeBomb Player
#if TIMEBOMB
					LogDebug(false, "TKer: %d is being timebombed for TKing", tker);

					if (g_TimeBombSerial[tker] == 0)
					{
						CreateTimeBomb(tker);
					}
#endif	
				}
				case ATK_RESOURCES:
				{
					// Remove Player Resources
					LogDebug(false, "TKer: %d is having resources removed for TKing", tker);
					if (offsResourceAmount > 0)
					{
						if (arrayPlayerStats[victim][STAT_TKER_RESOURCES] != 0)
						{
							LogDebug(false, "TKer: %d currently has %i resources", tker, GetEntData(tker, offsResourceAmount));
							new attacker_resources = GetEntData(tker, offsResourceAmount) + arrayPlayerStats[victim][STAT_TKER_RESOURCES];

							if (attacker_resources < 0)
								attacker_resources = 0;

							LogDebug(false, "TKer: %d will end up with %i resources", tker, attacker_resources);
							SetEntData(tker, offsResourceAmount, attacker_resources);

							if (GetConVarBool(g_Cvar_ResourceSteal))
							{
								new victim_resources = GetEntData(victim, offsResourceAmount) + (arrayPlayerStats[victim][STAT_TKER_RESOURCES] * -1);
								SetEntData(victim, offsResourceAmount, victim_resources);
							}
							arrayPlayerStats[victim][STAT_TKER_RESOURCES] = 0;
							LogDebug(false, "TKer: %d now has %i resources", tker, GetEntData(tker, offsResourceAmount));
						}
					}
				}
				case ATK_NOFORGIVE:
				{
					// Do Not Forgive Player
					LogDebug(false, "TKer: %d has not been forgiven for TKing", tker);
				}
				default:
				{
					// Could be useful as a log message
					LogDebug(false, "ERROR: TK type not defined: %d", type);
				}
			}
		}
		else
		{
			// Inform Client that TK action will be taken...
			InformTKClients(victim, tker, type, false);

			// Queue Punishment
			QueuePunishment(victim, tker, type);
		}
	}
}

bool:CheckAdminImmunity(client)
{
#if _DEBUG
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

		GetConVarString(g_Cvar_AdminsFlag, flags, sizeof(flags));

		// Are we checking for specific admin flags?
		if (!StrEqual(flags, "", false))
		{
			// Is the admin flag we are checking valid?
			if (!FindFlagByChar(flags[0], flag))
			{
#if _DEBUG
				LogDebug(false, "CheckAdminImmunity - ERROR: Admin Immunity flag is not valid? %s", flags[0]);
#endif
			}
			else
			{
				// Check if the admin has the correct immunity flag.
				if (!GetAdminFlag(admin, flag))
				{
#if _DEBUG
					LogDebug(false, "CheckAdminImmunity - Client %s has a valid Admin ID but does NOT have required immunity flag %s admin is NOT immune.", name, flags[0]);
#endif
				}
				else
				{
#if _DEBUG
					LogDebug(false, "CheckAdminImmunity - Client %s has required immunity flag %s admin is immune.", name, flags[0]);
#endif
					return true;
				}
			}
		}
		else
		{
			// Player is an admin, we don't care about flags.
#if _DEBUG
			LogDebug(false, "CheckAdminImmunity - Client %s is a valid Admin and is immune.", name);
#endif
			return true;
		}
	}
	else
	{
#if _DEBUG
		LogDebug(false, "CheckAdminImmunity - Client %s has an invalid Admin ID.", name);
#endif
	}

	return false;
}
