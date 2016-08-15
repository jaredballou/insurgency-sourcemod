#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_DESCRIPTION "CVAR and command list dumper"
#define PLUGIN_NAME "CVAR List"
#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_WORKING "1"
#define PLUGIN_FILE "cvarlist"
#define PLUGIN_LOG_PREFIX "CVARLIST"
#include <myinfo>


public OnPluginStart()
{
	RegAdminCmd("sm_cvarlist", Command_Mycvarlist, ADMFLAG_CONVARS);
	RegAdminCmd("sm_cmdlist",  Command_Mycmdlist, ADMFLAG_CONVARS);
}

public Action:Command_Mycvarlist(client, args)
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
