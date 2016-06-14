#include <sourcemod>
#include <sdktools>

new Handle:g_hSdkCall;
public Plugin:myinfo = 
{
	name = "Dynamic SetMaxPlayers",
	author = "Afronanny",
	description = "Set the maxplayers dynamically",
	version = "1.0",
	url = "http://jewgle.org/"
}

public OnPluginStart()
{
	RegServerCmd("setmaxplayers", Command_SetMaxPlayers);
	
	new Handle:hGameConf = LoadGameConfigFile("maxplayers");
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "SetupMaxPlayers");
	PrepSDKCall_AddParameter(SDKType_PlainOldData,SDKPass_Plain);
	g_hSdkCall = EndPrepSDKCall();
	
	
}

public Action:Command_SetMaxPlayers(arg)
{
	decl String:arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	SDKCall(g_hSdkCall, StringToInt(arg1));
	return Plugin_Handled;
}

