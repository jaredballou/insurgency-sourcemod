#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_DESCRIPTION "Upholder of the [BFG], modified by Jared Ballou (jballou)"
#define PLUGIN_NAME "[INS] CVAR List"
#define PLUGIN_URL "http://jballou.com/insurgency"
#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_WORKING 1

public Plugin:myinfo = {
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url		= PLUGIN_URL
};

#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-cvarlist.txt"


public OnPluginStart()
{
	RegAdminCmd("sm_cvarlist", Command_Mycvrlist, ADMFLAG_CONVARS);
	RegAdminCmd("sm_cmdlist",  Command_Mycmdlist, ADMFLAG_CONVARS);
}

public Action:Command_Mycvrlist(client, args)
{
	decl Handle:iter;
	decl String:value[256], String:buffer[256], flags, bool:isCommand;
	new  count = 1;
	ConVar hCvar;
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM,path,PLATFORM_MAX_PATH,"cvarlist.txt");
	new Handle:fileHandle=OpenFile(path,"a");
	iter = FindFirstConCommand(buffer, sizeof(buffer), isCommand, flags);
	do
	{
		if (!isCommand)
		{
			hCvar = FindConVar(buffer);
			hCvar.GetString(value,256);
			WriteFileLine(fileHandle, "%s %s", buffer, value);
			ReplyToCommand(client, "%s %s", buffer, value);
			count += 1;
		}
	}
	while (FindNextConCommand(iter, buffer, sizeof(buffer), isCommand, flags));
	CloseHandle(fileHandle);
	ReplyToCommand(client, "Total ConVars: %d", count);

	CloseHandle(iter);
	
	return Plugin_Handled;
}

public Action:Command_Mycmdlist(client, args)
{
	decl Handle:iter;
	decl String:buffer[256], flags, bool:isCommand;
	new  count = 1;

	iter = FindFirstConCommand(buffer, sizeof(buffer), isCommand, flags);
	
	do
	{
		if (isCommand)
		{
			ReplyToCommand(client, "%s (%d)", buffer, flags);
			count += 1;
		}
	}
	while (FindNextConCommand(iter, buffer, sizeof(buffer), isCommand, flags));
	ReplyToCommand(client, "Total Commands: %d", count);

	CloseHandle(iter);
	
	return Plugin_Handled;
}
