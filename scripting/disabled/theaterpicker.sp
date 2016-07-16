/*******************************************************************************
  Insurgency Theater Picker
*******************************************************************************/

#include <sourcemod>
#include <sdktools>
#include <insurgency>
#include <smjansson>

new Handle:g_aMaps = INVALID_HANDLE;
new Handle:g_aMapList = INVALID_HANDLE;
new Handle:g_aGameModes = INVALID_HANDLE;

#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_DESCRIPTION "Allows admins to set theater, and clients to vote"
#define PLUGIN_NAME "[INS] Theater Picker"
#define PLUGIN_URL "http://jballou.com/insurgency"
#define PLUGIN_VERSION "0.0.4"
#define PLUGIN_WORKING 1

public Plugin:myinfo = {
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url		= PLUGIN_URL
};


#define UPDATE_URL "http://ins.jballou.com/sourcemod/update-theaterpicker.txt"


new Handle:g_version=INVALID_HANDLE;
new Handle:g_theaterfile=INVALID_HANDLE;
new Handle:g_config=INVALID_HANDLE;
//new Handle:g_=INVALID_HANDLE;

public OnPluginStart()
{
	g_version = CreateConVar("sm_theaterpicker_version",PLUGIN_VERSION,"Theater picker version",FCVAR_NOTIFY);
	g_theaterfile = CreateConVar("sm_theaterpicker_file",PLUGIN_VERSION,"Custom theater file name",FCVAR_NOTIFY);
	g_config = CreateConVar("sm_theaterpicker_config",PLUGIN_VERSION,"Custom theater file name",FCVAR_NOTIFY);
	SetConVarString(g_version,PLUGIN_VERSION);
//	ParseTheater();
}

public OnPluginEnd(){
	CloseHandle(g_version);
}

public OnMapStart(){
	GetTheaterList();
}

public ParseTheater()
{
//decl String:path[PLATFORM_MAX_PATH];
//OpenFile(path,"r");
//CloseHandle(fileHandle);

	PrintToServer("[THEATERPICKER] Starting ParseTheater");
	new String:sGameMode[32],String:sTheaterOverride[32];
	decl String:sTheaterPath[PLATFORM_MAX_PATH];
	GetConVarString(FindConVar("mp_gamemode"), sGameMode, sizeof(sGameMode));
	//Try to load override theater first
	GetConVarString(FindConVar("mp_theater_override"), sTheaterOverride, sizeof(sTheaterOverride));
	Format(sTheaterPath, sizeof(sTheaterPath), "scripts/theaters/%s.theater", sTheaterOverride);
	//If it does not exist, load normal theater from data directory.
	if (!FileExists(sTheaterPath)) {
		Format(sTheaterPath, sizeof(sTheaterPath), "insurgency-data/theaters/%s/default_%s.theater", "1.7.2.3",sGameMode);
	}

//	BuildPath(Path_SM,sTheaterPath,PLATFORM_MAX_PATH,
	if (!FileExists(sTheaterPath)) {
		PrintToServer("[THEATERPICKER] Cannot find theater %s",sTheaterPath);
		return false;
	}
	PrintToServer("[THEATERPICKER] Loading theater %s",sTheaterPath);
	new Handle:g_hTheater = CreateKeyValues("theater");
	FileToKeyValues(g_hTheater,sTheaterPath);
//	BrowseKeyValues(g_hTheater);
       	// Convert it to JSON
	KvRewind(g_hTheater);
	KeyValuesToFile(g_hTheater,"theater.kv.txt");
       	new Handle:hObj = KeyValuesToJSON(g_hTheater);

       	// And finally save the JSON object to a file
       	// with indenting set to 2.
//       	Format(sPath, sizeof(sPath), "theater.json");
       	json_dump_file(hObj, "theater.json", 2);

       	// Close the Handle to the JSON object, i.e. free it's memory
       	// and free the Handle.
       	CloseHandle(hObj);
	return true;
}
stock Handle:KeyValuesToJSON(Handle:kv) {
	new Handle:hObj = json_object();

	//Traverse the keyvalues structure
	IterateKeyValues(kv, hObj);

	//return output
	return hObj;
}

IterateKeyValues(&Handle:kv, &Handle:hObj) {
	do {
		new String:sSection[255];
		KvGetSectionName(kv, sSection, sizeof(sSection));

		new String:sValue[255];
		KvGetString(kv, "", sValue, sizeof(sValue));

		new bool:bIsSubSection = ((KvNodesInStack(kv) == 0) || (KvGetDataType(kv, "") == KvData_None && KvNodesInStack(kv) > 0));

		//new KvDataTypes:type = KvGetDataType(kv, "");
		//LogMessage("Section: %s, Value: %s, Type: %d", sSection, sValue, type);

		if(!bIsSubSection) {
		//if(type != KvData_None) {
			json_object_set_new(hObj, sSection, json_string(sValue));
		} else {
			//We have no value, this must be another section
			new Handle:hChild = json_object();

			if (KvGotoFirstSubKey(kv, false)) {
				IterateKeyValues(kv, hChild);
				KvGoBack(kv);
			}

			json_object_set_new(hObj, sSection, hChild);
		}

	} while (KvGotoNextKey(kv, false));
}

BrowseKeyValues(Handle:kv)
{
	new String:buffer[255];
	do
	{
		// You can read the section/key name by using KvGetSectionName here.
		KvGetSectionName(kv, buffer, sizeof(buffer));
		PrintToServer("[THEATERPICKER] Section name is %s",buffer);
		if (KvGotoFirstSubKey(kv, false))
		{
			// Current key is a section. Browse it recursively.
			BrowseKeyValues(kv);
			KvGoBack(kv);
		}
		else
		{
			// Current key is a regular key, or an empty section.
			if (KvGetDataType(kv, NULL_STRING) != KvData_None)
			{
				KvGetString(kv, NULL_STRING, buffer, sizeof(buffer));
				PrintToServer("[THEATERPICKER] Value is %s",buffer);
				// Read value of key here (use NULL_STRING as key name). You can
				// also get the key name by using KvGetSectionName here.
			}
			else
			{
				// Found an empty sub section. It can be handled here if necessary.
			}
		}
	} while (KvGotoNextKey(kv, false));
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
