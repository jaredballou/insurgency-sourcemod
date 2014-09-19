/**
 * Sound support for Mapchooser Extended
 * Inspired by QuakeSounds 2.7
 */

#pragma semicolon 1
#include <sourcemod>
#include <mapchooser>
#include "include/mapchooser_extended"
#include <sdktools>

#define VERSION "1.10.1"

#define CONFIG_FILE "configs/mapchooser_extended/sounds.cfg"
#define CONFIG_DIRECTORY "configs/mapchooser_extended/sounds"

#define SET_NAME_MAX_LENGTH 64

// 0-60, even though we don't ever call 0
// Counter-intuitive note: This array has 61 elements, not 60
#define COUNTER_MAX_SIZE 60
// The number of digits in the previous number
#define COUNTER_MAX_SIZE_DIGITS 2

#define NUM_TYPES 5

// CVar Handles
new Handle:g_Cvar_EnableSounds = INVALID_HANDLE;
new Handle:g_Cvar_EnableCounterSounds = INVALID_HANDLE;
new Handle:g_Cvar_SoundSet = INVALID_HANDLE;
new Handle:g_Cvar_DownloadAllSounds = INVALID_HANDLE;

// Data Handles
new Handle:g_TypeNames = INVALID_HANDLE; // Maps SoundEvent enumeration values to KeyValue section names
new Handle:g_SetNames = INVALID_HANDLE;
new Handle:g_SoundFiles = INVALID_HANDLE;
new Handle:g_CurrentSoundSet = INVALID_HANDLE; // Lazy "pointer" to the current sound set.  Updated on cvar change or map change.

//Global variables
new bool:g_DownloadAllSounds;

new bool:g_bNeedsFakePrecache = false;

enum SoundEvent
{
	SoundEvent_Counter = 0,
	SoundEvent_VoteStart = 1,
	SoundEvent_VoteEnd = 2,
	SoundEvent_VoteWarning = 3,
	SoundEvent_RunoffWarning = 4,
}

enum SoundType
{
	SoundType_None,
	SoundType_Sound,
	SoundType_Builtin,
	SoundType_Event
}

enum SoundStore
{
	String:SoundStore_Value[PLATFORM_MAX_PATH],
	SoundType:SoundStore_Type
}

public Plugin:myinfo = 
{
	name = "Mapchooser Extended Sounds",
	author = "Powerlord",
	description = "Sound support for Mapchooser Extended",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=156974"
}

// Map enum values to their named values
// This is used for searching later.
PopulateTypeNamesArray()
{
	if (g_TypeNames == INVALID_HANDLE)
	{
		g_TypeNames = CreateArray(ByteCountToCells(SET_NAME_MAX_LENGTH), NUM_TYPES);
		SetArrayString(g_TypeNames, _:SoundEvent_Counter, "counter");
		SetArrayString(g_TypeNames, _:SoundEvent_VoteStart, "vote start");
		SetArrayString(g_TypeNames, _:SoundEvent_VoteEnd, "vote end");
		SetArrayString(g_TypeNames, _:SoundEvent_VoteWarning, "vote warning");
		SetArrayString(g_TypeNames, _:SoundEvent_RunoffWarning, "runoff warning");
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("GetEngineVersion");
}

public OnPluginStart()
{
	g_Cvar_EnableSounds = CreateConVar("mce_sounds_enablesounds", "1", "Enable this plugin.  Sounds will still be downloaded (if applicable) even if the plugin is disabled this way.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_EnableCounterSounds = CreateConVar("mce_sounds_enablewarningcountersounds", "1", "Enable sounds to be played during warning counter.  If this is disabled, map vote warning, start, and stop sounds still play.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_SoundSet = CreateConVar("mce_sounds_soundset", "tf", "Sound set to use, optimized for TF by default.  Sound sets are defined in addons/sourcemod/configs/mapchooser_extended_sounds.cfg.  Takes effect immediately if sm_mapvote_downloadallsounds is 1, otherwise at map change.", FCVAR_NONE);
	g_Cvar_DownloadAllSounds = CreateConVar("mce_sounds_downloadallsounds", "0", "Force players to download all sound sets, so sets can be dynamically changed during the map. Defaults to off. Takes effect at map change.", FCVAR_NONE, true, 0.0, true, 1.0);
	CreateConVar("mce_sounds_version", VERSION, "Mapchooser Extended Sounds Version", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED);

	AutoExecConfig(true, "mapchooser_extended_sounds");

	RegAdminCmd("mce_sounds_reload", Command_Reload, ADMFLAG_CONVARS, "Reload Mapchooser Sound configuration file.");
	RegAdminCmd("sm_mapvote_reload_sounds", Command_Reload, ADMFLAG_CONVARS, "Deprecated: use mce_sounds_reload");

	RegAdminCmd("mce_sounds_list_soundsets", Command_List_Soundsets, ADMFLAG_CONVARS, "List available Mapchooser Extended sound sets.");
	RegAdminCmd("sm_mapvote_list_soundsets", Command_List_Soundsets, ADMFLAG_CONVARS, "Deprecated: use mce_sounds_list_soundsets");

	PopulateTypeNamesArray();
	// LoadSounds needs to be  executed even if the plugin is "disabled" via the sm_mapvote_enablesounds cvar.

	g_SetNames = CreateArray(ByteCountToCells(PLATFORM_MAX_PATH));
	g_SoundFiles = CreateTrie();
	LoadSounds();
	HookConVarChange(g_Cvar_SoundSet, SoundSetChanged);
	
	new EngineVersion:engVersion = GetEngineVersionCompat();
	if (engVersion == Engine_CSGO || engVersion == Engine_DOTA)
//	if (engVersion == Engine_CSGO)
	{
		g_bNeedsFakePrecache = true;
	}
}

// Not sure this is required, but there were some weird crashes when this plugin was unloaded.  This is an attempt to fix that.
/*
public OnPluginEnd()
{
	CloseSoundArrayHandles();
}
*/

/*
* Moved to OnConfigsExecuted due to cvar requirements
public OnMapStart()
{
	BuildDownloadsTableAll();
}
*/

public OnConfigsExecuted()
{
	g_DownloadAllSounds = GetConVarBool(g_Cvar_DownloadAllSounds);
	
	decl String:soundSet[SET_NAME_MAX_LENGTH];
	
	// Store which sound set is in use
	GetConVarString(g_Cvar_SoundSet, soundSet, sizeof(soundSet));
	
	// Unknown sound set from config file, reset to default
	if (FindStringInArray(g_SetNames, soundSet) == -1 && !StrEqual(soundSet, "tf", true))
	{
		ResetConVar(g_Cvar_SoundSet);
		GetConVarString(g_Cvar_SoundSet, soundSet, sizeof(soundSet));
	}

	SetCurrentSoundSet(soundSet);
	if (g_DownloadAllSounds)
	{
		BuildDownloadsTableAll();
	}
	else
	{
		BuildDownloadsTable(g_CurrentSoundSet);
	}
}

public SoundSetChanged(Handle:cvar, String:oldValue[], String:newValue[])
{
	if (FindStringInArray(g_SetNames, newValue) == -1)
	{
		LogError("New sound set not found: %s", newValue);
		SetConVarString(cvar, oldValue);
	}
	else if (g_DownloadAllSounds)
	{
		SetCurrentSoundSet(newValue);
	}
}

public OnMapVoteStarted()
{
	PlaySound(SoundEvent_VoteStart);
}

public OnMapVoteEnd(const String:map[])
{
	PlaySound(SoundEvent_VoteEnd);
}

public OnMapVoteWarningStart()
{
	PlaySound(SoundEvent_VoteWarning);
}

public OnMapVoteRunnoffWarningStart()
{
	PlaySound(SoundEvent_RunoffWarning);
}

public OnMapVoteWarningTick(time)
{
	if (GetConVarBool(g_Cvar_EnableSounds) && GetConVarBool(g_Cvar_EnableCounterSounds)) {
		decl String:currentType[SET_NAME_MAX_LENGTH];
		decl Handle:counterTrie;
		
		if (g_CurrentSoundSet != INVALID_HANDLE)
		{
			if (GetArrayString(g_TypeNames, _:SoundEvent_Counter, currentType, sizeof(currentType)) > 0 && GetTrieValue(g_CurrentSoundSet, currentType, counterTrie))
			{
				new String:key[5];
				IntToString(time, key, sizeof(key));
				
				new soundData[SoundStore];
				if (!GetTrieArray(counterTrie, key, soundData[0], sizeof(soundData)))
				{
					return;
				}
				
				if (soundData[SoundStore_Type] == SoundType_Event)
				{
					new Handle:broadcastEvent = CreateEvent("teamplay_broadcast_audio");
					if (broadcastEvent == INVALID_HANDLE)
					{
						#if defined DEBUG
						LogError("Could not create teamplay_broadcast_event. This may be because there are no players connected.");
						#endif
						return;
					}
					SetEventInt(broadcastEvent, "team", -1);
					SetEventString(broadcastEvent, "sound", soundData[SoundStore_Value]);
					FireEvent(broadcastEvent);
				}
				else
				{
					EmitSoundToAll(soundData[SoundStore_Value]);
				}
			}
		}
	}
}

public Action:Command_Reload(client, args)
{
	LoadSounds();
	ReplyToCommand(client, "[MCES] Reloaded sound configuration.");
	return Plugin_Handled;
}

public Action:Command_List_Soundsets(client, args)
{
	new setCount = GetArraySize(g_SetNames);
	ReplyToCommand(client, "[SM] The following %d sound sets are installed:", setCount);
	for (new i = 0; i < setCount; i++)
	{
		decl String:setName[SET_NAME_MAX_LENGTH];
		GetArrayString(g_SetNames, i, setName, sizeof(setName));
		ReplyToCommand(client, "[SM] %s", setName);
	}
}

PlaySound(SoundEvent:event)
{
	if (GetConVarBool(g_Cvar_EnableSounds))
	{
		if (g_CurrentSoundSet != INVALID_HANDLE)
		{
			decl String:currentType[SET_NAME_MAX_LENGTH];
			
			if (GetArrayString(g_TypeNames, _:event, currentType, sizeof(currentType)) > 0)
			{
				new soundData[SoundStore];
				GetTrieArray(g_CurrentSoundSet, currentType, soundData[0], sizeof(soundData));
				if (soundData[SoundStore_Type] == SoundType_Event)
				{
					new Handle:broadcastEvent = CreateEvent("teamplay_broadcast_audio");
					if (broadcastEvent == INVALID_HANDLE)
					{
						#if defined DEBUG
						LogError("Could not create teamplay_broadcast_event. This may be because there are no players connected.");
						#endif
						return;
					}
					SetEventInt(broadcastEvent, "team", -1);
					SetEventString(broadcastEvent, "sound", soundData[SoundStore_Value]);
					FireEvent(broadcastEvent);
				}
				else
				{
					EmitSoundToAll(soundData[SoundStore_Value]);
				}
			}
		}
	}

}

SetCurrentSoundSet(String:soundSet[])
{
	// Save a reference to the Trie for the current sound set, for use in the forwards below.
	// Also do error checking to make sure the set exists.
	if (!GetTrieValue(g_SoundFiles, soundSet, g_CurrentSoundSet))
	{
		SetFailState("Could not load sound set");
	}
	
}

// Load the list of sounds sounds from the configuration file
// This should be done on plugin load.
// This looks really complicated, but it really isn't.
LoadSounds()
{
	CloseSoundArrayHandles();
	
	decl String:directoryPath[PLATFORM_MAX_PATH];
	decl String:modName[SET_NAME_MAX_LENGTH];
	
	GetGameFolderName(modName, sizeof(modName));
	
	BuildPath(Path_SM, directoryPath, sizeof(directoryPath), CONFIG_DIRECTORY);

	new Handle:directory = OpenDirectory(directoryPath);
	if (directory != INVALID_HANDLE)
	{
		decl String:dirEntry[PLATFORM_MAX_PATH];
		while (ReadDirEntry(directory, dirEntry, sizeof(dirEntry)))
		{
			new Handle:soundsKV = CreateKeyValues("MapchooserSoundsList");
			decl String:filePath[PLATFORM_MAX_PATH];
			
			Format(filePath, sizeof(filePath), "%s/%s", directoryPath, dirEntry);
			
			if (!DirExists(filePath))
			{
				FileToKeyValues(soundsKV, filePath);
				
				if (KvGotoFirstSubKey(soundsKV))
				{
					// Iterate through the sets
					do
					{
						new Handle:setTrie = CreateTrie();
						decl String:currentSet[SET_NAME_MAX_LENGTH];
						new bool:builtinSet = false;
						
						KvGetSectionName(soundsKV, currentSet, sizeof(currentSet));
						
						if (FindStringInArray(g_SetNames, currentSet) == -1)
						{
							// Add to the list of sound sets
							PushArrayString(g_SetNames, currentSet);
						}
						else
						{
							SetFailState("Duplicate sound set: %s", currentSet);
						}
						
						if (StrEqual(currentSet, modName, false))
						{
							builtinSet = true;
						}
						
						if (KvGotoFirstSubKey(soundsKV)) {
							// Iterate through each sound in the set
							do
							{
								decl String:currentType[SET_NAME_MAX_LENGTH];
								KvGetSectionName(soundsKV, currentType, sizeof(currentType));
								// Type to enum mapping
								new typeKey = FindStringInArray(g_TypeNames, currentType);
								
								switch(typeKey)
								{
									case SoundEvent_Counter:
									{
										// Counter is special, as it has multiple values
										new Handle:counterTrie = CreateTrie();
										
										if (KvGotoFirstSubKey(soundsKV))
										{
											do
											{
												// Get the current key
												decl String:time[COUNTER_MAX_SIZE_DIGITS + 1];
												
												KvGetSectionName(soundsKV, time, sizeof(time));
												
												new soundData[SoundStore];
												
												// new key = StringToInt(time);
												
												soundData[SoundStore_Type] =  RetrieveSound(soundsKV, builtinSet, soundData[SoundStore_Value], PLATFORM_MAX_PATH);
												if (soundData[SoundStore_Type] == SoundType_None)
												{
													continue;
												}
												
												// This seems wrong, but this is documented on the forums here: https://forums.alliedmods.net/showthread.php?t=151942
												SetTrieArray(counterTrie, time, soundData[0], sizeof(soundData));
												
												//SetArrayString(counterArray, key, soundFile);
											} while (KvGotoNextKey(soundsKV));
											KvGoBack(soundsKV);
										}
										
										SetTrieValue(setTrie, currentType, _:counterTrie);
										
									}
									
									// Set the sounds directly for other types
									default:
									{
										new soundData[SoundStore];
										
										soundData[SoundStore_Type] = RetrieveSound(soundsKV, builtinSet, soundData[SoundStore_Value], PLATFORM_MAX_PATH);
										
										if (soundData[SoundStore_Type] == SoundType_None)
										{
											continue;
										}
										
										SetTrieArray(setTrie, currentType, soundData[0], sizeof(soundData));
									}
								}
							} while (KvGotoNextKey(soundsKV));
							KvGoBack(soundsKV);
						}
						SetTrieValue(g_SoundFiles, currentSet, setTrie);
					} while (KvGotoNextKey(soundsKV));
				}
			}
			CloseHandle(soundsKV);
		}
		CloseHandle(directory);
	}
	
	if (GetArraySize(g_SetNames) == 0)
	{
		SetFailState("Could not locate any sound sets.");
	}
}

// Internal LoadSounds function to get sound and type 
SoundType:RetrieveSound(Handle:soundsKV, bool:builtin, String:soundFile[], soundFileSize)
{
	if (builtin)
	{
		// event is considered before builtin, as it has related game data and should always be used in preference to builtin
		KvGetString(soundsKV, "event", soundFile,soundFileSize);
		
		if (!StrEqual(soundFile, ""))
		{
			return SoundType_Event;
		}
		
		KvGetString(soundsKV, "builtin", soundFile, soundFileSize);
		if (!StrEqual(soundFile, ""))
		{
			return SoundType_Builtin;
		}
	}
	
	KvGetString(soundsKV, "sound", soundFile, soundFileSize);

	if (!StrEqual(soundFile, ""))
	{
		return SoundType_Sound;
	}
	
	// Whoops, didn't find this sound
	return SoundType_None;
}

// Preload all sounds in a set
BuildDownloadsTable(Handle:currentSoundSet)
{
	if (currentSoundSet != INVALID_HANDLE)
	{
		for (new i = 0; i < GetArraySize(g_TypeNames); i++)
		{
			decl String:currentType[SET_NAME_MAX_LENGTH];
			GetArrayString(g_TypeNames, i, currentType, sizeof(currentType));

			switch(i)
			{
				case SoundEvent_Counter:
				{
					decl Handle:counterTrie;
					if (GetTrieValue(currentSoundSet, currentType, counterTrie))
					{
						// Skip value 0
						for (new j = 1; j <= COUNTER_MAX_SIZE; ++j)
						{
							new String:key[5];
							IntToString(j, key, sizeof(key));
							
							new soundData[SoundStore];
							GetTrieArray(counterTrie, key, soundData[0], sizeof(soundData));
							if (soundData[SoundStore_Type] != SoundType_Event)
							{
								CacheSound(soundData);
							}
						}
					}
				}
				
				default:
				{
					new soundData[SoundStore];
					GetTrieArray(currentSoundSet, currentType, soundData[0], sizeof(soundData));
					
					if (soundData[SoundStore_Type] != SoundType_Event)
					{
						CacheSound(soundData);
					}
				}
			}
		}
	}
}

// Load each set and build its download table
stock BuildDownloadsTableAll()
{
	for (new i = 0; i < GetArraySize(g_SetNames); i++)
	{
		decl String:currentSet[SET_NAME_MAX_LENGTH];
		decl Handle:currentSoundSet;
		GetArrayString(g_SetNames, i, currentSet, sizeof(currentSet));
		
		if (GetTrieValue(g_SoundFiles, currentSet, currentSoundSet))
		{
			BuildDownloadsTable(currentSoundSet);
		}
	}
}

// Found myself repeating this code, so I pulled it into a separate function
CacheSound(soundData[SoundStore])
{
	if (soundData[SoundStore_Type] == SoundType_Builtin)
	{
		PrecacheSoundAny(soundData[SoundStore_Value]);
	}
	else if (soundData[SoundStore_Type] == SoundType_Sound)
	{
		if (PrecacheSoundAny(soundData[SoundStore_Value]))
		{
			decl String:downloadLocation[PLATFORM_MAX_PATH];
			Format(downloadLocation, sizeof(downloadLocation), "sound/%s", soundData[SoundStore_Value]);
			AddFileToDownloadsTable(downloadLocation);
		} else {
			LogMessage("Failed to load sound: %s", soundData[SoundStore_Value]);
		}
	}
}

// Close all the handles that are children and grandchildren of the g_SoundFiles trie.
stock CloseSoundArrayHandles()
{
	// Close all open handles in the sound set
	for (new i = 0; i < GetArraySize(g_SetNames); i++)
	{
		decl String:currentSet[SET_NAME_MAX_LENGTH];
		decl Handle:trieHandle;
		decl Handle:arrayHandle;
		
		GetArrayString(g_SetNames, i, currentSet, sizeof(currentSet));
		GetTrieValue(g_SoundFiles, currentSet, trieHandle);
		// "counter" is an adt_trie, close that too
		GetTrieValue(trieHandle, "counter", arrayHandle);
		CloseHandle(arrayHandle);
		CloseHandle(trieHandle);
	}
	ClearTrie(g_SoundFiles);
	ClearArray(g_SetNames);
}

stock bool:PrecacheSoundAny( const String:szPath[] )
{
	if (g_bNeedsFakePrecache)
	{
		return FakePrecacheSoundEx(szPath);
	}
	else
	{
		return PrecacheSound(szPath);
	}
}

stock bool:FakePrecacheSoundEx( const String:szPath[] )
{
	decl String:szPathStar[PLATFORM_MAX_PATH];
	Format(szPathStar, sizeof(szPathStar), "*%s", szPath);
	
	AddToStringTable( FindStringTable( "soundprecache" ), szPathStar );
	return true;
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
