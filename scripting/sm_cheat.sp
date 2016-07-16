#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"


public Plugin:myinfo = 
{
	name = "Cheat commands",
	author = "EHG",
	description = "Use commands requiring sv_cheats",
	version = PLUGIN_VERSION,
	url = "epichatguy@gmail.com"
};
public OnPluginStart()
{
	CreateConVar("sm_cheat_version", PLUGIN_VERSION, "Cheat commands version",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);	
	RegAdminCmd("sm_cheat", Command_cheat_command, ADMFLAG_ROOT);
}


public Action:Command_cheat_command(client, args)
{
	decl String:cmd[65];
	GetCmdArgString(cmd, sizeof(cmd));
	PerformCheatCommand(client, cmd);
	return Plugin_Handled;
}

stock PerformCheatCommand(client, String:cmd[])
{
	new Handle:cvar = FindConVar("sv_cheats"), bool:enabled = GetConVarBool(cvar), flags = GetConVarFlags(cvar);
	if(!enabled) {
		SetConVarFlags(cvar, flags^(FCVAR_NOTIFY|FCVAR_REPLICATED));
		SetConVarBool(cvar, true);
	}
	FakeClientCommand(client, "%s", cmd);
	if(!enabled) {
		SetConVarBool(cvar, false);
		SetConVarFlags(cvar, flags);
    }
	CreateTimer(0.1, ExecDelay, 0);
}

public Action:ExecDelay(Handle:timer)
{
	ServerCommand("exec sm_cheat_cvars.cfg");
}
