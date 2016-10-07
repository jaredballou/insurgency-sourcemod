#pragma semicolon 1 
#include <sourcemod> 
#if !defined FCVAR_DEVELOPMENTONLY 
#define FCVAR_DEVELOPMENTONLY (1<<1) 
#endif 

#define PLUGIN_DESCRIPTION "CVAR and command list dumper"
#define PLUGIN_AUTHOR "Jared Ballou <insurgency@jballou.com>"
#define PLUGIN_NAME "CVAR List"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_WORKING "1"
#define PLUGIN_FILE "cvarlist"
#define PLUGIN_LOG_PREFIX "CVARLIST"
#define PLUGIN_URL "http://jballou.com/insurgency"

public Plugin:myinfo = {
        name            = PLUGIN_NAME,
        author          = PLUGIN_AUTHOR,
        description     = PLUGIN_DESCRIPTION,
        version         = PLUGIN_VERSION,
        url             = PLUGIN_URL
};


public OnPluginStart() { 
	RegAdminCmd("sm_cvarlist", Command_cvarlist, ADMFLAG_CONVARS); 
	RegAdminCmd("sm_cmdlist", Command_cmdlist, ADMFLAG_CONVARS); 
} 
public Action:Command_cvarlist(client, args) { 
	decl String:name[64], String:value[64]; 
	new Handle:cvar, bool:isCommand, flags; 
	cvar = FindFirstConCommand(name, sizeof(name), isCommand, flags); 
	if(cvar==INVALID_HANDLE) { 
		PrintToConsole(client, "Could not load cvar list"); 
		return Plugin_Handled; 
	} 
	do { 
		if(isCommand || !(flags & FCVAR_DEVELOPMENTONLY)) { 
			continue; 
		} 
		GetConVarString(FindConVar(name), value, sizeof(value)); 
		PrintToConsole(client, "\"%s\" \"%s\"", name, value); 
	} while(FindNextConCommand(cvar, name, sizeof(name), isCommand, flags)); 
	return Plugin_Handled; 
} 
public Action:Command_cmdlist(client, args) { 
	decl String:name[64]; 
	new Handle:cvar, bool:isCommand, flags; 
	cvar = FindFirstConCommand(name, sizeof(name), isCommand, flags); 
	if(cvar==INVALID_HANDLE) { 
		PrintToConsole(client, "Could not load cvar list"); 
		return Plugin_Handled; 
	} 
	do { 
		if(!isCommand || !(flags & FCVAR_DEVELOPMENTONLY)) { 
			continue; 
		} 
		PrintToConsole(client, "%s", name); 
		flags &= ~FCVAR_DEVELOPMENTONLY; 
		SetCommandFlags(name, flags); 
	} while(FindNextConCommand(cvar, name, sizeof(name), isCommand, flags)); 
	return Plugin_Handled; 
}
