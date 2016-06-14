#pragma semicolon 1

#include <sourcemod>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#include <steamtools>

#define PLUGIN_VERSION "0.8.3"

public Plugin:myinfo = {
	name        = "SteamTools Tester",
	author      = "Asher Baker (asherkin)",
	description = "Plugin for testing the SteamTools extension.",
	version     = PLUGIN_VERSION,
	url         = "http://limetech.org/"
};

new ReplySource:Async_GroupStatus_Reply;
new ReplySource:Async_ServerReputation_Reply;

new Async_GroupStatus_Client;
new Async_ServerReputation_Client;

new bool:HaveStats[MAXPLAYERS+1];

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	RegAdminCmd("sm_groupstatus", Command_GroupStatus, ADMFLAG_ROOT, "Requests a client's membership status in a Steam Community Group.");
	RegAdminCmd("sm_printserverreputation", Command_ServerReputation, ADMFLAG_ROOT, "Requests a server's reputation from the Steam Master Servers.");
	RegAdminCmd("sm_forceheartbeat", Command_Heartbeat, ADMFLAG_ROOT, "Sends a heartbeat to the Steam Master Servers.");
	RegAdminCmd("sm_printvacstatus", Command_VACStatus, ADMFLAG_ROOT, "Shows the current VAC status.");
	RegAdminCmd("sm_printconnectionstatus", Command_ConnectionStatus, ADMFLAG_ROOT, "Shows the current Steam connection status.");
	RegAdminCmd("sm_printip", Command_PrintIP, ADMFLAG_ROOT, "Shows the server's current external IP address.");

	RegAdminCmd("sm_setrule", Command_SetRule, ADMFLAG_ROOT, "Sets (and adds if missing) the value of an entry in the Master Server Rules response.");
	RegAdminCmd("sm_clearrules", Command_ClearRules, ADMFLAG_ROOT, "Removes all the entries in the Master Server Rules response.");

	RegAdminCmd("sm_setgamedescription", Command_SetGameDescription, ADMFLAG_ROOT, "Sets the game description shown in the server browser.");

	RegAdminCmd("sm_printstat", Command_PrintStat, ADMFLAG_ROOT, "Prints the value of a stat for a client.");
	RegAdminCmd("sm_printachievement", Command_PrintAchievement, ADMFLAG_ROOT, "Prints whether or not a client has earned an achievement.");

	RegAdminCmd("sm_printsubscription", Command_PrintSubscription, ADMFLAG_ROOT, "Shows the Subscription ID of the Steam Subscription that contains the client's game.");
	RegAdminCmd("sm_printdlc", Command_PrintDLC, ADMFLAG_ROOT, "Shows the App IDs of the DLCs that are associated with the client's game.");
}

public OnClientAuthorized(client, const String:auth[])
{
	if (!IsFakeClient(client))
	{
		Steam_RequestStats(client);
	}
}

public OnClientDisconnect(client)
{
	HaveStats[client] = false;
}

public Steam_StatsReceived(client)
{
	HaveStats[client] = true;
	return;
}

public Steam_StatsUnloaded(client)
{
	if (client == -1) // We'll get a Steam_StatsUnloaded after a client has left.
		return;

	HaveStats[client] = false;
	return;
}

public Action:Command_GroupStatus(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_groupstatus <client> <group>");
		return Plugin_Handled;
	}

	new String:arg1[32];
	new String:arg2[32];

	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
 
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_IMMUNITY,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	new bool:didLastRequestWork = false;
 
	for (new i = 0; i < target_count; i++)
	{
		didLastRequestWork = Steam_RequestGroupStatus(target_list[i], StringToInt(arg2));
	}

	ReplyToCommand(client, "[SM] %s.", didLastRequestWork?"Group status requested":"Error in requesting group status, not connected to Steam");

	Async_GroupStatus_Client = client;
	Async_GroupStatus_Reply = GetCmdReplySource();

	return Plugin_Handled;
}

public Action:Command_ServerReputation(client, args)
{
	Steam_RequestServerReputation();
	ReplyToCommand(client, "[SM] Server Reputation Requested.");

	Async_ServerReputation_Client = client;
	Async_ServerReputation_Reply = GetCmdReplySource();

	return Plugin_Handled;
}

public Action:Command_Heartbeat(client, args)
{
	Steam_ForceHeartbeat();
	ReplyToCommand(client, "[SM] Heartbeat Sent.");
	return Plugin_Handled;
}

public Action:Command_VACStatus(client, args)
{
	ReplyToCommand(client, "[SM] VAC is %s.", Steam_IsVACEnabled()?"active":"not active");
	return Plugin_Handled;
}

public Action:Command_ConnectionStatus(client, args)
{
	ReplyToCommand(client, "[SM] %s to Steam servers.", Steam_IsConnected()?"Connected":"Not connected");
	return Plugin_Handled;
}

public Action:Command_PrintIP(client, args)
{
	new octets[4];
	Steam_GetPublicIP(octets);
	ReplyToCommand(client, "[SM] Server IP Address: %d.%d.%d.%d", octets[0], octets[1], octets[2], octets[3]);
	return Plugin_Handled;
}

public Action:Command_SetRule(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setrule <key> <value>");
		return Plugin_Handled;
	}

	new String:arg1[32];
	new String:arg2[32];

	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
 
	Steam_SetRule(arg1, arg2);
	ReplyToCommand(client, "[SM] Rule Set.");

	return Plugin_Handled;
}

public Action:Command_ClearRules(client, args)
{
	Steam_ClearRules();
	ReplyToCommand(client, "[SM] Rules Cleared.");

	return Plugin_Handled;
}

public Action:Command_SetGameDescription(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setgamedescription <description>");
		return Plugin_Handled;
	}

	new String:arg1[32];

	GetCmdArg(1, arg1, sizeof(arg1));
 
	Steam_SetGameDescription(arg1);
	ReplyToCommand(client, "[SM] Game Description Set.");

	return Plugin_Handled;
}

public Action:Command_PrintStat(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_printstat <client> <stat>");
		return Plugin_Handled;
	}

	new String:arg1[32];
	new String:arg2[32];

	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
 
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_IMMUNITY,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
		if (HaveStats[client])
			ReplyToCommand(client, "[SM] Stat '%s' = %d for %N.", arg2, Steam_GetStat(target_list[i], arg2), target_list[i]);
		else
			ReplyToCommand(client, "[SM] Stats for %N not received yet.", target_list[i]);
	}

	return Plugin_Handled;
}

public Action:Command_PrintAchievement(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_printachievement <client> <achievement>");
		return Plugin_Handled;
	}

	new String:arg1[32];
	new String:arg2[32];

	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
 
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_IMMUNITY,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
		if (HaveStats[client])
			ReplyToCommand(client, "[SM] %N %s earned achievement %s.", target_list[i], Steam_IsAchieved(target_list[i], arg2)?"has":"has not", arg2);
		else
			ReplyToCommand(client, "[SM] Stats for %N not received yet.", target_list[i]);
	}

	return Plugin_Handled;
}

public Action:Command_PrintSubscription(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_printsubscription <client>");
		return Plugin_Handled;
	}

	new String:arg1[32];
	new String:arg2[32];

	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
 
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_IMMUNITY,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
		new subCount = Steam_GetNumClientSubscriptions(target_list[i]);
		for (new x = 0; x < subCount; x++)
		{
			ReplyToCommand(client, "[SM] Client purchased this game as part of subscription %d.", Steam_GetClientSubscription(target_list[i], x));
		}
	}

	return Plugin_Handled;
}

public Action:Command_PrintDLC(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_printdlc <client>");
		return Plugin_Handled;
	}

	new String:arg1[32];
	new String:arg2[32];

	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
 
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_IMMUNITY,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
		new subCount = Steam_GetNumClientDLCs(target_list[i]);
		for (new x = 0; x < subCount; x++)
		{
			ReplyToCommand(client, "[SM] Client has DLC %d.", Steam_GetClientDLC(target_list[i], x));
		}
	}

	return Plugin_Handled;
}

public Steam_GroupStatusResult(client, groupAccountID, bool:groupMember, bool:groupOfficer)
{
	SetCmdReplySource(Async_GroupStatus_Reply);
	ReplyToCommand(Async_GroupStatus_Client, "[SM] %N is %s in group %d.", client, groupMember?(groupOfficer?"an officer":"a member"):"not a member", groupAccountID);
	Async_GroupStatus_Reply = SM_REPLY_TO_CONSOLE;
	Async_GroupStatus_Client = 0;
	return;
}

public Steam_Reputation(reputationScore, bool:banned, bannedIP, bannedPort, bannedGameID, banExpires)
{
	SetCmdReplySource(Async_ServerReputation_Reply);
	ReplyToCommand(Async_ServerReputation_Client, "[SM] Reputation Score: %d. Banned: %s.", reputationScore, banned?"true":"false");
	Async_ServerReputation_Reply = SM_REPLY_TO_CONSOLE;
	Async_ServerReputation_Client = 0;
	return;
}

public Action:Steam_RestartRequested()
{
	PrintToServer("[SM] Server needs to be restarted due to an update.");
	return Plugin_Continue;
}

public Steam_SteamServersConnected()
{
	PrintToChatAll("[SM] Connection to Steam servers established.");
	return;
}

public Steam_SteamServersDisconnected()
{
	PrintToChatAll("[SM] Lost connection to Steam servers.");
	return;
}
