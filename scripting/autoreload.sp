
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

new Handle:filenames = INVALID_HANDLE;
new Handle:filestamps = INVALID_HANDLE;
new String:prefix[PLATFORM_MAX_PATH];

public Plugin:myinfo = {
	name = "Autoreload",
	author = "Timiditas",
	description = "Autoreloads plugins whose file timestamp has changed, for development",
	version = PLUGIN_VERSION,
	url = "ht"
};

public OnPluginStart()
{
	BuildPath(Path_SM,prefix,sizeof(prefix),"plugins/");
	new String:myFile[PLATFORM_MAX_PATH];
	GetPluginFilename(INVALID_HANDLE, myFile, sizeof(myFile));
	new arraySize = ByteCountToCells(PLATFORM_MAX_PATH);
	filenames = CreateArray(arraySize);
	filestamps = CreateArray();
	new Handle:dir = OpenDirectory(prefix);
	decl String:PluginFile[PLATFORM_MAX_PATH];
	new FileType:fileType;
	while (ReadDirEntry(dir, PluginFile, sizeof(PluginFile), fileType))
	{
		if(!StrEqual(PluginFile, myFile, false))
		{
			if (fileType == FileType_File)
			{
				new String:tPath[PLATFORM_MAX_PATH];
				new FileTimeMode:stupid = FileTime_LastChange;
				strcopy(tPath, sizeof(tPath), prefix);
				StrCat(tPath, sizeof(tPath), PluginFile);
				PushArrayString(filenames, PluginFile);
				new tStamp = GetFileTime(tPath, stupid);
				PushArrayCell(filestamps, tStamp);
			}
		}
	}
	CloseHandle(dir);
	PrintToServer("Found %i plugin files, excluding myself.", GetArraySize(filenames));
	CreateTimer(2.0, Regeneration, _, TIMER_REPEAT);
}

public Action:Regeneration(Handle:timer)
{
	new FCount = 	GetArraySize(filenames);
	for(new i = 0; i < FCount; i++)
	{
		new FileTimeMode:stupid = FileTime_LastChange, String:fFilename[PLATFORM_MAX_PATH], String:tPath[PLATFORM_MAX_PATH];
		new fStamp = GetArrayCell(filestamps, i);
		GetArrayString(filenames, i, fFilename, PLATFORM_MAX_PATH); 
		strcopy(tPath, sizeof(tPath), prefix);
		StrCat(tPath, sizeof(tPath), fFilename);
		new fStampnew = GetFileTime(tPath, stupid);
		//PrintToServer("Path: '%s' OldStamp: %i NewStamp: %i", tPath, fStamp, fStampnew);
		if(fStamp != fStampnew)
		{
			SetArrayCell(filestamps, i, fStampnew);
			PrintToServer("%s has changed timestamp. Reloading...", fFilename);
			ServerCommand("sm plugins reload %s", fFilename);
		}
	}
}
