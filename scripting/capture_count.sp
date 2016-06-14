//(C) 2014 Jared Ballou <sourcemod@jballou.com>
//Released under GPLv3

#pragma semicolon 1
#pragma unused cvarVersion
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <insurgency>
#undef REQUIRE_PLUGIN
#include <updater>

#define PLUGIN_AUTHOR "Jared Ballou (jballou)"
#define PLUGIN_DESCRIPTION "Adds a timer that displays the captured points count for each team for competitive mode"
#define PLUGIN_NAME "[INS] Captire Count"
#define PLUGIN_URL "http://jballou.com/"
#define PLUGIN_VERSION "0.0.2"
#define PLUGIN_WORKING 1

public Plugin:myinfo = {
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url		= PLUGIN_URL
};


#define UPDATE_URL    "http://ins.jballou.com/sourcemod/update-capture_count.txt"

new Handle:cvarVersion = INVALID_HANDLE; // version cvar!
new Handle:cvarEnabled = INVALID_HANDLE; // are we enabled?
new g_iCaptures[4],g_iCaches[4];

public OnPluginStart()
{
	cvarVersion = CreateConVar("sm_capture_count_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_capture_count_enabled", "0", "sets whether plugin is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);
	RegConsoleCmd("check_captures", Command_Check_Captures);
	RegConsoleCmd("capture_count", Command_Check_Captures);
	RegConsoleCmd("check_capture", Command_Check_Captures);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_begin", Event_RoundBegin);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("object_destroyed", Event_ObjectDestroyed);
	HookEvent("controlpoint_captured", Event_ControlPointCaptured);
	PrintToServer("[CAPTURES] Started!");
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}
public ResetRoundStats()
{
	for (new i=0; i<4; i++)
	{
		g_iCaptures[i] = 0;
		g_iCaches[i] = 0;
	}
}

public Action:Event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"priority" "short"
	//"timelimit" "short"
	//"lives" "short"
	//"gametype" "short"
	ResetRoundStats();
	return Plugin_Continue;
}
public Action:Event_RoundBegin( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"priority" "short"
	//"timelimit" "short"
	//"lives" "short"
	//"gametype" "short"
	ResetRoundStats();
	return Plugin_Continue;
}
public Action:Event_RoundEnd( Handle:event, const String:name[], bool:dontBroadcast )
{
	//"reason" "byte"
	//"winner" "byte"
	//"message" "string"
	//"message_string" "string"
	//new winner = GetEventInt( event, "winner");
	//new reason = GetEventInt( event, "reason");
	//decl String:message[255],String:message_string[255];
	//GetEventString(event, "message",message,sizeof(message));
	//GetEventString(event, "message_string",message_string,sizeof(message_string));
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			Check_Captures(i);
		}
	}	
	return Plugin_Continue;
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public Action:Command_Check_Captures(client, args)
{
	return Check_Captures(client);
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2) {}

public Action:Check_Captures(client)
{
	//PrintToServer("[CAPTURES] Check_Captures!");
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Handled;
	}
	new Handle:panel = CreatePanel();
	decl String:buffer[128];

	SetPanelTitle(panel, "Round Stats");
	DrawPanelItem(panel, "", ITEMDRAW_SPACER);
	DrawPanelText(panel, "Security");
	Format(buffer, sizeof(buffer), " Captures: %d", g_iCaptures[TEAM_SECURITY]);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), " Caches: %d", g_iCaches[TEAM_SECURITY]);
	DrawPanelText(panel, buffer);
	DrawPanelItem(panel, "", ITEMDRAW_SPACER);
	DrawPanelText(panel, "Insurgents");
	Format(buffer, sizeof(buffer), " Captures: %d", g_iCaptures[TEAM_INSURGENTS]);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), " Caches: %d", g_iCaches[TEAM_INSURGENTS]);
	DrawPanelText(panel, buffer);

	SetPanelCurrentKey(panel, 10);
	SendPanelToClient(panel, client, Handler_DoNothing, 20);
	CloseHandle(panel);
	return Plugin_Continue;
}
public Action:Event_ObjectDestroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	//decl String:attacker_authid[64],String:assister_authid[64],String:classname[64];
	//"team" "byte"
	//"attacker" "byte"
	//"cp" "short"
	//"index" "short"
	//"type" "byte"
	//"weapon" "string"
	//"weaponid" "short"
	//"assister" "byte"
	//"attackerteam" "byte"
	//new team = GetEventInt(event, "team");
	new attacker = GetEventInt(event, "attacker");
	new attackerteam = GetEventInt(event, "attackerteam");
	//new cp = GetEventInt(event, "cp");
	//new index = GetEventInt(event, "index");
	//new type = GetEventInt(event, "type");
	//new weaponid = GetEventInt(event, "weaponid");
	//new assister = GetEventInt(event, "assister");
	//new assister_userid = -1;
	//new attacker_userid = -1;
	//new assisterteam = -1;
	if (attacker)
	{
		g_iCaches[attackerteam]++;
	}
	//PrintToServer("[CAPTURES] Event_ObjectDestroyed: team %d attacker %d attacker_userid %d cp %d classname %s index %d type %d weaponid %d assister %d assister_userid %d attackerteam %d",team,attacker,attacker_userid,cp,classname,index,type,weaponid,assister,assister_userid,attackerteam);
	return Plugin_Continue;
}
public Action:Event_ControlPointCaptured(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}
	//"priority" "short"
	//"cp" "byte"
	//"cappers" "string"
	//"cpname" "string"
	//"team" "byte"
	decl String:cappers[256],String:cpname[64];
	//new priority = GetEventInt(event, "priority");
	new cp = GetEventInt(event, "cp");
	GetEventString(event, "cappers", cappers, sizeof(cappers));
	GetEventString(event, "cpname", cpname, sizeof(cpname));
	new team = GetEventInt(event, "team");
	new capperlen = GetCharBytes(cappers);
	PrintToServer("[CAPTURES] Event_ControlPointCaptured cp %d capperlen %d cpname %s team %d", cp,capperlen,cpname,team);
	//"cp" "byte" - for naming, currently not needed
	g_iCaptures[team]++;
	return Plugin_Continue;
}
