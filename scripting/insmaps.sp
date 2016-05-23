/*******************************************************************************
  Insurgency Map Picker
*******************************************************************************/

#include <sourcemod>
#include <sdktools>
#include <insurgency>

new Handle:g_aMaps = INVALID_HANDLE;
new Handle:g_aMapList = INVALID_HANDLE;
new Handle:g_aGameModes = INVALID_HANDLE;

#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_DESCRIPTION "Lists all maps and modes available"
#define PLUGIN_NAME "[INS] Map List"
#define PLUGIN_URL "http://jballou.com/insurgency"
#define PLUGIN_VERSION "1.4.1"
#define PLUGIN_WORKING 0

public Plugin:myinfo = {
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url		= PLUGIN_URL
};

#define UPDATE_URL "http://ins.jballou.com/sourcemod/update-insmaps.txt"


new Handle:g_version=INVALID_HANDLE;

public OnPluginStart()
{
	g_version = CreateConVar("sm_insmaps_version",PLUGIN_VERSION,"SM Ins Maps Version",FCVAR_NOTIFY);
	SetConVarString(g_version,PLUGIN_VERSION);
}

public OnPluginEnd(){
	CloseHandle(g_version);
}

public OnMapStart(){
	GetMapData();
}
public GetMapData()
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
		PrintToServer("[INSMAPS] Map %s file %s gamemode %s",sMap,sFileName,sGameMode);
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
				if (StrEqual(sFileParts[1], "txt", false)) {
					ReadMapFile(sFilePath,sFileParts[0]);
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
