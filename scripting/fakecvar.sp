//Includes:
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"


public Plugin:myinfo = 

{
	name = "Fake cvar",
	author = "EHG",
	description = "Send fake cvar value to clients",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=92289"
};

public OnPluginStart()
{
	CreateConVar("sm_fcvar_version", PLUGIN_VERSION, "Fake cvar Version",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_fcvar", Command_fcvar, ADMFLAG_CUSTOM1, "Usage: sm_fcvar <name/#userid> <cvar> <value>");
}

public Action:Command_fcvar(client, args)
{
	
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fcvar <name/#userid> <cvar> <value>");
		return Plugin_Handled;
	}
	
	
	new String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	
	decl String:arg2[20];
	GetCmdArg(2, arg2, sizeof(arg2));
	
	decl String:arg3[64];
	GetCmdArg(3, arg3, sizeof(arg3));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		SendConVarValue(target_list[i], FindConVar(arg2), arg3);
	}
	ReplyToCommand(client, "[SM] Sent %s = %s to %s.", arg2, arg3, target_name);
	
	
	return Plugin_Handled;
}
