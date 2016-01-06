/*
* Crashed Map Recovery (c) 2009 Jonah Hirsch
* 
* 
* Loads the map the server was on before it crashed when server restarts
* 
*  
* Changelog								
* ------------		
* 1.5
*  - Messages are now logged to logs/CMR.log
*  - crashmap.txt is now generated automatically
* 1.4.3
*  - Fixed compile warnings
*  - Backs up and restores nextmap on crash + recover (test feature!)
* 1.4.2
*  - Autoconfig added. cfg/sourcemod/plugin.crashmap.cfg
* 1.4.1
*  - Added FCVAR_DONTRECORD to version cvar
* 1.4
*  - Added sm_crashmap_maxrestarts
*  - Added support for checking if the map being changed to crashes the server
* 1.3
*  - Changed method of enabling/disabling recover time to improve performance
*  - Added sm_crashmap_interval
* 1.2
*  - Added timelimit recovery
*  - Added sm_crashmap_recovertime
* 1.1
*  - Added log message when map is recoevered on restart
* 1.0									
*  - Initial Release			
* 
* 		
*/

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.5"

static String:FileLoc[128];
new String:logPath[PLATFORM_MAX_PATH]
new Handle:logFileHandle = INVALID_HANDLE
new Handle:dataFileHandle = INVALID_HANDLE
new Handle:sm_crashmap_enabled = INVALID_HANDLE
new Handle:sm_crashmap_recovertime = INVALID_HANDLE
new Handle:sm_crashmap_interval = INVALID_HANDLE
new Handle:sm_crashmap_maxrestarts = INVALID_HANDLE
new Handle:TimeleftHandle = INVALID_HANDLE
new bool:Recovered = false
new bool:TimelimitChanged = false
new bool:Overwrite = false
new newTimelimit


public Plugin:myinfo = 
{
	name = "Crashed Map Recovery",
	author = "Crazydog",
	description = "Reloads map that was being played before server crash",
	version = PLUGIN_VERSION,
	url = "http://theelders.net"
}

public OnPluginStart(){
	CreateConVar("sm_crashmap_version", PLUGIN_VERSION, "Crashed Map Recovery Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	sm_crashmap_enabled = CreateConVar("sm_crashmap_enabled", "1", "Enable Crashed Map Recovery? (1=yes 0=no)", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	sm_crashmap_recovertime = CreateConVar("sm_crashmap_recovertime", "0", "Recover timelimit? (1=yes 0=no)", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	sm_crashmap_interval = CreateConVar("sm_crashmap_interval", "20", "Interval between timeleft updates (in seconds)", FCVAR_NOTIFY, true, 1.0)
	sm_crashmap_maxrestarts = CreateConVar("sm_crashmap_maxrestarts", "5", "How many consecutive crashes until server loads the default map", FCVAR_NOTIFY, true, 3.0)
	AutoExecConfig(true, "plugin.crashmap")
	HookConVarChange(sm_crashmap_recovertime, TimerState)
	HookConVarChange(sm_crashmap_interval, IntervalChange)
	
	if(GetConVarInt(sm_crashmap_recovertime) == 1){
		TimeleftHandle = CreateTimer(GetConVarFloat(sm_crashmap_interval), SaveTimeleft, _, TIMER_REPEAT)
	}
	BuildPath(Path_SM, FileLoc, 128, "data/crashmap.txt")
	if(!FileExists(FileLoc)){
		dataFileHandle = OpenFile(FileLoc,"a");
		WriteFileLine(dataFileHandle,"SavedMap");
		WriteFileLine(dataFileHandle,"{");
		WriteFileLine(dataFileHandle,"}");
		CloseHandle(dataFileHandle);
	}
	
	BuildPath(Path_SM, logPath, PLATFORM_MAX_PATH, "/logs/CMR.log")
	if(!FileExists(logPath)){
		logFileHandle = OpenFile(logPath, "a")
		CloseHandle(logFileHandle)
	}
}



public OnMapStart(){
	if(GetConVarInt(sm_crashmap_enabled) == 0){
		return
	}
	if(Recovered){
		new String:CurrentMap[256];
		GetCurrentMap(CurrentMap, sizeof(CurrentMap))
		decl Handle:SavedMap
		SavedMap = CreateKeyValues("SavedMap")
		FileToKeyValues(SavedMap, FileLoc)
		KvJumpToKey(SavedMap, "Map", true)
		KvSetString(SavedMap, "Map", CurrentMap)
		KvRewind(SavedMap)
		KeyValuesToFile(SavedMap, FileLoc)
		CloseHandle(SavedMap)
		return
	}
	if(!Recovered){
		new String:MapToLoad[256], String:nextmap[256], timeleft, restarts
		decl Handle:SavedMap
		SavedMap = CreateKeyValues("SavedMap")
		FileToKeyValues(SavedMap, FileLoc)
		KvJumpToKey(SavedMap, "Map", true)
		KvGetString(SavedMap, "Map", MapToLoad, sizeof(MapToLoad))
		restarts = KvGetNum(SavedMap, "restarts", 0)
		//LogToFile(logPath, "[CMR] Server restarted, restarts is %i", restarts)
		restarts++
		//LogToFile(logPath, "[CMR] Restarts incremented, restarts is %i", restarts)
		LogToFile(logPath, "Restarts is %i", restarts)
		KvSetNum(SavedMap, "restarts", restarts)
		timeleft = KvGetNum(SavedMap, "Timeleft", 30)
		KvGetString(SavedMap, "Nextmap", nextmap, sizeof(nextmap))
		SetNextMap(nextmap)
		newTimelimit = timeleft/60
		Recovered = true
		if(restarts > GetConVarInt(sm_crashmap_maxrestarts)){
			LogToFile(logPath, "[CMR] Error! %s is causing the server to crash. Please fix!", MapToLoad)
			KvSetNum(SavedMap, "restarts", 0)
			KvRewind(SavedMap)
			KeyValuesToFile(SavedMap, FileLoc)
			CloseHandle(SavedMap)
			return
		}
		KvRewind(SavedMap)
		KeyValuesToFile(SavedMap, FileLoc)
		CloseHandle(SavedMap)
		if(GetConVarInt(sm_crashmap_recovertime) == 1){
			LogToFile(logPath, "[CMR] %s loaded after server crash. Timelimit set to %i", MapToLoad, timeleft/60)
		}else{
			LogToFile(logPath, "[CMR] %s loaded after server crash.", MapToLoad)
		}
		ForceChangeLevel(MapToLoad, "Crashed Map Recovery")
		return
	}
}



public OnMapEnd(){
}

public Action:SaveTimeleft(Handle:timer){
	if(Overwrite){
		new timeleft
		if(!GetMapTimeLeft(timeleft)){
			if(!GetMapTimeLimit(timeleft)){
				timeleft = 30
			}
		}
		new String:nextmap[256]
		GetNextMap(nextmap, sizeof(nextmap))
		decl Handle:SavedMap
		SavedMap = CreateKeyValues("SavedMap")
		FileToKeyValues(SavedMap, FileLoc)
		KvJumpToKey(SavedMap, "Map", true)
		KvSetNum(SavedMap, "Timeleft", timeleft)
		KvSetString(SavedMap, "Nextmap", nextmap) 
		KvRewind(SavedMap)
		KeyValuesToFile(SavedMap, FileLoc)
		CloseHandle(SavedMap)
	}
}

public OnClientAuthorized(client){
	decl Handle:SavedMap
	SavedMap = CreateKeyValues("SavedMap")
	FileToKeyValues(SavedMap, FileLoc)
	KvJumpToKey(SavedMap, "Map", true)
	KvSetNum(SavedMap, "restarts", 0)
	KvRewind(SavedMap)
	KeyValuesToFile(SavedMap, FileLoc)
	CloseHandle(SavedMap)
	if(!TimelimitChanged && GetConVarInt(sm_crashmap_recovertime) == 1){
		ServerCommand("mp_timelimit %i", newTimelimit)
		TimelimitChanged = true
		Overwrite = true
	}
}

public TimerState(Handle:convar, const String:oldValue[], const String:newValue[]){
	if(GetConVarInt(sm_crashmap_recovertime) < 1){
		if(TimeleftHandle != INVALID_HANDLE){
			KillTimer(TimeleftHandle)
			TimeleftHandle = INVALID_HANDLE
		}
	}
	if(GetConVarInt(sm_crashmap_recovertime) > 0){
		new Float:newTime = GetConVarFloat(sm_crashmap_interval)
		TimeleftHandle = CreateTimer(newTime, SaveTimeleft, _, TIMER_REPEAT)
		Overwrite = true
	}
}

public IntervalChange(Handle:convar, const String:oldValue[], const String:newValue[]){
	if(TimeleftHandle != INVALID_HANDLE){
		new Float:newTime = StringToFloat(newValue)
		KillTimer(TimeleftHandle)
		TimeleftHandle = INVALID_HANDLE
		TimeleftHandle = CreateTimer(newTime, SaveTimeleft, _, TIMER_REPEAT)
	}
}