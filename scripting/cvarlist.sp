#pragma semicolon 1
#include <sourcemod>

public Plugin:myinfo =
{
	name = "All Command and ConVar Lister",
	author = "Upholder of the [BFG]",
	description = "A plugin to list all cvars and commands",
	version = "1.0",
	url = "http://www.sourcemod.net/"
}

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
	iter = FindFirstConCommand(buffer, sizeof(buffer), isCommand, flags);
	do
	{
		if (!isCommand)
		{
			hCvar = FindConVar(buffer);
			hCvar.GetString(value,256);
			ReplyToCommand(client, "%s %s", buffer, value);
			count += 1;
		}
	}
	while (FindNextConCommand(iter, buffer, sizeof(buffer), isCommand, flags));
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
