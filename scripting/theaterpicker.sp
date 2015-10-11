/*******************************************************************************
  Insurgency Theater Picker
*******************************************************************************/

#include <sourcemod>
#include <sdktools>
#include <insurgency>

new Handle:g_aMaps = INVALID_HANDLE;
new Handle:g_aMapList = INVALID_HANDLE;
new Handle:g_aGameModes = INVALID_HANDLE;

#define PLUGIN_VERSION		"0.0.1"
#define UPDATE_URL "http://ins.jballou.com/sourcemod/update-theaterpicker.txt"


new Handle:g_version=INVALID_HANDLE;
new Handle:g_theaterfile=INVALID_HANDLE;
new Handle:g_config=INVALID_HANDLE;
//new Handle:g_=INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Theater Picker",
	author = "jballou",
	description = "Allows admins to set theater, and clients to vote",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	g_version = CreateConVar("sm_theaterpicker_version",PLUGIN_VERSION,"Theater picker version",FCVAR_NOTIFY);
	g_theaterfile = CreateConVar("sm_theaterpicker_file",PLUGIN_VERSION,"Custom theater file name",FCVAR_NOTIFY);
	g_config = CreateConVar("sm_theaterpicker_config",PLUGIN_VERSION,"Custom theater file name",FCVAR_NOTIFY);
	SetConVarString(g_version,PLUGIN_VERSION);
}

public OnPluginEnd(){
	CloseHandle(g_version);
}

public OnMapStart(){
	GetTheaterList();
}

//GetTheaterList - Get listing of all theater files available on server
public GetTheaterList()
{
        if (g_aMaps == INVALID_HANDLE)
        {
                g_aMaps = CreateArray(MAX_MAPS);
		if (g_aMapList == INVALID_HANDLE)
	                g_aMapList = CreateArray(MAX_MAPS*MAX_GAMEMODES);
		if (g_aGameModes == INVALID_HANDLE)
	                g_aGameModes = CreateArray(MAX_GAMEMODES);
		ReadFileFolder("maps");
        }
}

//UpdateConfigFile - Write the new g_theaterfile setting to the config, execute it
UpdateConfigFile() {
}

//SelectTheaterFile - Show menu to a player to select a theater
SelectTheaterFile() {
}

ReadTheater(String:sFileName[],String:sMap[]){
}
ReadMapFile(String:sFileName[],String:sMap[]){
	new Handle:kv  = INVALID_HANDLE;
	decl String:sGameMode[32], String:sBuffer[64];
	kv = CreateKeyValues("cpsetup.txt");
	if(!(FileExists(sFileName))) {
		return;
	}
	if (!FileToKeyValues(kv, sFileName)) {
		return;
	}
	if (!(KvGotoFirstSubKey(kv))) {
		return;
	}
	if (!(KvGetSectionName(kv, sGameMode, sizeof(sGameMode)))) {
		return;
	}

	PushArrayString(g_aMaps, sMap);
	do
	{
		KvGetSectionName(kv, sGameMode, sizeof(sGameMode));
		Format(sBuffer, sizeof(sBuffer), "%s %s",sMap,sGameMode);
		PushArrayString(g_aMapList,sBuffer);
		PrintToServer("[IND-TP] Map %s file %s gamemode %s",sMap,sFileName,sGameMode);
	}
	while(KvGotoNextKey(kv))
}

ReadFileFolder(String:sPath[],bool:bRecurse=false){
	new Handle:hDir = INVALID_HANDLE;
	new String:sFileName[256];
	new String:sFilePath[256];
	new FileType:type = FileType_Unknown;
	new len;
	
	len = strlen(sPath);
	if (sPath[len-1] == '\n')
		sPath[--len] = '\0';

	TrimString(sPath);
	
	if(DirExists(sPath)){
		hDir = OpenDirectory(sPath);
		while(ReadDirEntry(hDir,sFileName,sizeof(sFileName),type)){
			len = strlen(sFileName);
			if (sFileName[len-1] == '\n')
				sFileName[--len] = '\0';
			TrimString(sFileName);

			if (!StrEqual(sFileName,"",false) && !StrEqual(sFileName,".",false) && !StrEqual(sFileName,"..",false)){
				strcopy(sFilePath,255,sPath);
				StrCat(sFilePath,255,"/");
				StrCat(sFilePath,255,sFileName);
				decl String:sFileParts[2][256];
				ExplodeString(sFileName, ".", sFileParts, 2, 256,true);
				if (StrEqual(sFileParts[1], "theater", false)) {
					ReadTheater(sFilePath,sFileParts[0]);
				}
				
				if(type == FileType_File){
					//Parse file if text
				}
				else{
					if (bRecurse)
						ReadFileFolder(sFilePath,bRecurse);
				}
			}
		}
	}
	if(hDir != INVALID_HANDLE){
		CloseHandle(hDir);
	}
}
